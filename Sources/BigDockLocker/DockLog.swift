import Foundation
import os

/// Centralized logging for Big DockLocker — the flight recorder.
///
/// Three destinations, each doing a different job:
///
/// 1. **Unified logging** (`os.Logger`, subsystem `com.danielvm.BigDockLocker`) —
///    live and post-mortem with `log stream` / `log show`, kept by the system.
/// 2. **`events-YYYY-MM-DD.log`** — rare, structured, human-readable lines: tap
///    created/disabled/re-enabled, sleep/wake, lock, session start/end, gaps.
/// 3. **`heartbeat-YYYY-MM.log`** — one pipe-delimited line per minute (~95 B,
///    ~140 KB/month). This is the black box: after days of uptime it shows the
///    exact minute protection died and *why*.
///
/// Retention is by **age** (30 days), never by size, so the evidence of a failure
/// that took two weeks to appear is still there. See `specs/PLAN-flight-recorder.md`.
///
/// All file I/O is funneled through one serial queue, so `DockLog` is safe to call
/// from the event-tap callback and from the main thread alike. Nothing here is
/// called from the per-event hot path — only counters are.
public enum DockLog {

    /// Log channels, so entries can be filtered by area of the app.
    public enum Category: String, Sendable {
        case engine
        case lifecycle
        case display
        case permission
        case dock
    }

    /// Short id correlating lines of this run. Also stored in the session sentinel.
    public static let sessionID: String = {
        let raw = UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
        return String(raw.prefix(6))
    }()

    private static let subsystem = "com.danielvm.BigDockLocker"

    /// `~/Library/Logs/BigDockLocker`
    public static let directory: URL = {
        let base = FileManager.default
            .urls(for: .libraryDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library")
        return base
            .appendingPathComponent("Logs", isDirectory: true)
            .appendingPathComponent("BigDockLocker", isDirectory: true)
    }()

    /// Kept for message text and for the health check script.
    public static var eventsFileURL: URL { eventsURL(now: Date()) }
    public static var heartbeatFileURL: URL { heartbeatURL(now: Date()) }

    /// Files older than this are pruned; 30 days covers "it broke after two weeks".
    private static let retentionDays = 30

    // MARK: - Public API (events)

    /// Records the process start and reports whether the previous run ended abnormally.
    public static func beginSession(appVersion: String) {
        let sentinel = SessionSentinel(directory: directory)
        let previous = sentinel.begin(sessionID: sessionID, at: Date())

        var fields = [
            "session=\(sessionID)",
            "app=\(appVersion)",
            "mac=\(operatingSystemVersion)",
            "pid=\(getpid())",
            "uptime=\(Int(ProcessInfo.processInfo.systemUptime))"
        ]
        if let previous {
            fields.append("prev_session=\(previous.sessionID)")
            fields.append("prev_started=\(EventFormatter.timestamp(previous.startedAt))")
            fields.append("prev=unclean")
        } else {
            fields.append("prev=clean")
        }
        event(.lifecycle, "SESSION_START", fields)
    }

    /// Records a clean shutdown and clears the crash sentinel.
    public static func endSession() {
        event(.lifecycle, "SESSION_END", ["session=\(sessionID)"])
        queue.asyncAfter(deadline: .now() + 0.2) {
            SessionSentinel(directory: directory).close()
        }
    }

    /// Appends a structured event line. `fields` are pre-formatted `key=value`.
    public static func event(_ category: Category, _ name: String, _ fields: [String] = []) {
        let event = LogEvent(
            timestamp: Date(),
            sessionID: sessionID,
            category: category.rawValue.uppercased(),
            name: name,
            fields: fields
        )
        loggers[category]?.notice("\(event.line, privacy: .public)")
        queue.async { writeEvent(event) }
    }

    // MARK: - Public API (heartbeat)

    /// Appends one heartbeat line, plus a `GAP` event when the cadence broke.
    static func heartbeat(_ sample: HeartbeatSample) {
        queue.async {
            if let gap = sample.gapEvent(previous: lastSample) {
                writeEvent(
                    LogEvent(
                        timestamp: sample.timestamp,
                        sessionID: sessionID,
                        category: "ENGINE",
                        name: "GAP",
                        fields: [gap]
                    )
                )
                loggers[.engine]?.warning("heartbeat gap: \(gap, privacy: .public)")
            }
            lastSample = sample
            writeHeartbeat(sample)
            // Unified log gets the same line, so a single `log show` is enough when
            // the log directory is missing. Deliberately not written to the file twice.
            loggers[.engine]?.info("hb \(sample.line(), privacy: .public)")
        }
    }

    // MARK: - Human-readable messages (kept for compatibility)

    public static func debug(_ category: Category, _ message: String) { log(.debug, category, message) }
    public static func info(_ category: Category, _ message: String) { log(.info, category, message) }
    public static func notice(_ category: Category, _ message: String) { log(.notice, category, message) }
    public static func warning(_ category: Category, _ message: String) { log(.warning, category, message) }
    public static func error(_ category: Category, _ message: String) { log(.error, category, message) }

    public enum Level: String, Sendable {
        case debug = "DEBUG"
        case info = "INFO"
        case notice = "NOTICE"
        case warning = "WARN"
        case error = "ERROR"
    }

    public static func log(_ level: Level, _ category: Category, _ message: String) {
        let osLogger = loggers[category] ?? Logger(subsystem: subsystem, category: category.rawValue)
        switch level {
        case .debug: osLogger.debug("\(message, privacy: .public)")
        case .info: osLogger.info("\(message, privacy: .public)")
        case .notice: osLogger.notice("\(message, privacy: .public)")
        case .warning: osLogger.warning("\(message, privacy: .public)")
        case .error: osLogger.error("\(message, privacy: .public)")
        }

        let event = LogEvent(
            timestamp: Date(),
            sessionID: sessionID,
            category: category.rawValue.uppercased(),
            name: "MSG",
            fields: ["\(level.rawValue) \(message)"]
        )
        queue.async { writeEvent(event) }
    }

    // MARK: - State (only touched on `queue`)

    private static let queue = DispatchQueue(label: "com.danielvm.BigDockLocker.log")

    private static let loggers: [Category: Logger] = [
        .engine: Logger(subsystem: subsystem, category: Category.engine.rawValue),
        .lifecycle: Logger(subsystem: subsystem, category: Category.lifecycle.rawValue),
        .display: Logger(subsystem: subsystem, category: Category.display.rawValue),
        .permission: Logger(subsystem: subsystem, category: Category.permission.rawValue),
        .dock: Logger(subsystem: subsystem, category: Category.dock.rawValue)
    ]

    private nonisolated(unsafe) static var handles: [String: FileHandle] = [:]
    private nonisolated(unsafe) static var lastSample: HeartbeatSample?
    private nonisolated(unsafe) static var heartbeatHeaderFile: String?
    private nonisolated(unsafe) static var lastPrune = Date.distantPast

    private static let dayFormatter = makeFormatter("yyyy-MM-dd")
    private static let monthFormatter = makeFormatter("yyyy-MM")

    // MARK: - Writing (always on `queue`)

    private static func writeEvent(_ event: LogEvent) {
        let url = eventsURL(now: event.timestamp)
        append(event.line + "\n", to: url)
        pruneIfNeeded(now: event.timestamp)
    }

    private static func writeHeartbeat(_ sample: HeartbeatSample) {
        let url = heartbeatURL(now: sample.timestamp)
        var text = ""
        if heartbeatHeaderFile != url.lastPathComponent {
            heartbeatHeaderFile = url.lastPathComponent
            let boot = Date().addingTimeInterval(-ProcessInfo.processInfo.systemUptime)
            text += "# hb2 session=\(sessionID) app=\(Bundle.main.shortVersion ?? "dev")"
            text += " mac=\(operatingSystemVersion) boot=\(EventFormatter.timestamp(boot))\n"
            text += HeartbeatSample.header + "\n"
        }
        append(text + sample.line() + "\n", to: url)
        pruneIfNeeded(now: sample.timestamp)
    }

    private static func append(_ text: String, to url: URL) {
        guard let data = text.data(using: .utf8) else { return }
        let handle = self.handle(for: url)
        try? handle?.write(contentsOf: data)
    }

    private static func handle(for url: URL) -> FileHandle? {
        if let existing = handles[url.path] { return existing }

        let fileManager = FileManager.default
        try? fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        if !fileManager.fileExists(atPath: url.path) {
            fileManager.createFile(atPath: url.path, contents: nil)
        }
        guard let handle = try? FileHandle(forWritingTo: url) else { return nil }
        _ = try? handle.seekToEnd()
        handles[url.path] = handle
        return handle
    }

    private static func pruneIfNeeded(now: Date) {
        guard now.timeIntervalSince(lastPrune) > 3600 else { return }
        lastPrune = now
        guard let names = try? FileManager.default.contentsOfDirectory(atPath: directory.path) else { return }
        for name in LogRetention.expired(names, retentionDays: retentionDays, now: now) {
            try? FileManager.default.removeItem(at: directory.appendingPathComponent(name))
        }
    }

    // MARK: - Paths

    private static func eventsURL(now: Date) -> URL {
        directory.appendingPathComponent("events-\(dayFormatter.string(from: now)).log")
    }

    private static func heartbeatURL(now: Date) -> URL {
        directory.appendingPathComponent("heartbeat-\(monthFormatter.string(from: now)).log")
    }

    private static func makeFormatter(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = format
        return formatter
    }

    // MARK: - Environment

    private static var operatingSystemVersion: String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
    }
}

extension Bundle {
    /// Marketing version of the running app ("dev" when run from `swift run`).
    var shortVersion: String? {
        object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    }
}
