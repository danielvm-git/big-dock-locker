import Foundation

// MARK: - Heartbeat sample

/// One line of the flight recorder's heartbeat stream.
///
/// Column order is fixed and documented in `specs/PLAN-flight-recorder.md`.
/// Each column exists to discriminate one silent-death hypothesis: the whole
/// point is that after weeks of uptime a single line says *which* one happened.
struct HeartbeatSample: Equatable, Sendable {
    /// Wall clock (UTC when written).
    var timestamp: Date
    /// `ProcessInfo.systemUptime` — monotonic, stops while the machine sleeps.
    var uptimeSeconds: Int
    var pid: Int32
    /// `CGEvent.tapIsEnabled` — H1.
    var tapEnabled: Bool
    /// `AXIsProcessTrusted()` — TCC can flip long after launch.
    var accessibilityTrusted: Bool
    /// `CGSSessionScreenIsLocked` — H5.
    var screenLocked: Bool
    /// `kCGSSessionSecureInputPID`, 0 when no secure input — H4.
    var secureInputPID: Int32
    /// `CGDisplayIsAsleep(main)`.
    var mainDisplayAsleep: Bool
    var screenCount: Int
    /// Display index hosting the Dock window, -1 when unknown — H8.
    var dockDisplay: Int
    /// Display index under the cursor, -1 when unknown.
    var mouseDisplay: Int
    /// Cumulative events seen by the tap; frozen while the tap is starved — H2.
    var eventsSeen: UInt64
    /// Cumulative bounce corrections applied.
    var bouncesApplied: UInt64
    /// Slowest tap callback in the last interval (µs) — H3, the kill predictor.
    var callbackMaxMicros: UInt64
    /// Process CPU consumed in the last interval.
    var cpuMillis: UInt64
    /// Resident memory.
    var residentMegabytes: Int

    /// Expected spacing between samples; drift beyond 2× is reported as a gap.
    static let interval: TimeInterval = 60

    static let header = "# ts|up|pid|tap|ax|lock|secure|dsleep|nscr"
        + "|dock_disp|mouse_disp|nev|nb|cbmax_us|cpu_ms|rss_mb"

    func line() -> String {
        let fields: [String] = [
            HeartbeatSample.timestampFormatter.string(from: timestamp),
            String(uptimeSeconds),
            String(pid),
            HeartbeatSample.flag(tapEnabled),
            HeartbeatSample.flag(accessibilityTrusted),
            HeartbeatSample.flag(screenLocked),
            String(secureInputPID),
            HeartbeatSample.flag(mainDisplayAsleep),
            String(screenCount),
            String(dockDisplay),
            String(mouseDisplay),
            String(eventsSeen),
            String(bouncesApplied),
            String(callbackMaxMicros),
            String(cpuMillis),
            String(residentMegabytes)
        ]
        return fields.joined(separator: "|")
    }

    /// Describes the hole between `previous` and this sample, or `nil` when the
    /// cadence was kept. The verdict is what turns weeks of noise into a story.
    func gapEvent(previous: HeartbeatSample?) -> String? {
        guard let previous else { return nil }
        let wallDelta = timestamp.timeIntervalSince(previous.timestamp)
        let uptimeDelta = TimeInterval(uptimeSeconds - previous.uptimeSeconds)
        let verdict = GapClassifier.classify(wallDelta: wallDelta, uptimeDelta: uptimeDelta)
        guard verdict != .none else { return nil }

        let missed = max(0, Int((wallDelta / HeartbeatSample.interval).rounded()) - 1)
        return "missing=\(missed) wall_delta=\(Int(wallDelta))"
            + " up_delta=\(Int(uptimeDelta)) verdict=\(verdict.rawValue)"
    }

    private static func flag(_ value: Bool) -> String {
        value ? "1" : "0"
    }

    private nonisolated(unsafe) static let timestampFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
}

// MARK: - Gap classification

enum GapVerdict: String, Sendable {
    case none
    case systemSlept = "system_slept"
    case suspendedOrKilled = "suspended_or_killed"
    case clockChanged = "clock_changed"
}

enum GapClassifier {
    /// Classifies a hole between two heartbeat samples.
    ///
    /// - `clockChanged`: wall clock went backwards (NTP correction, manual change).
    /// - `systemSlept`: the wall clock advanced much further than the monotonic
    ///   clock, which only happens when the machine was asleep.
    /// - `suspendedOrKilled`: both clocks advanced, so time really passed, but no
    ///   sample was written — the process was not scheduled (App Nap, memory
    ///   pressure, debugger stop) or it was suspended and resumed.
    static func classify(wallDelta: TimeInterval, uptimeDelta: TimeInterval) -> GapVerdict {
        if wallDelta < 0 { return .clockChanged }

        // One missed beat is normal timer jitter, not a finding.
        let slack = HeartbeatSample.interval * 2
        if wallDelta <= slack { return .none }
        if wallDelta - uptimeDelta > slack { return .systemSlept }
        return .suspendedOrKilled
    }
}

// MARK: - Event lines

/// A structured, human-readable event line. Fields are pre-formatted `key=value`
/// pairs in the order the call site wants them.
struct LogEvent: Equatable, Sendable {
    var timestamp: Date
    var sessionID: String
    var category: String
    var name: String
    var fields: [String] = []

    var line: String {
        var text = EventFormatter.timestamp(timestamp)
        text += " [S:\(sessionID)] \(category) \(name)"
        if !fields.isEmpty {
            text += " " + fields.joined(separator: " ")
        }
        return text
    }
}

enum EventFormatter {
    static func timestamp(_ date: Date) -> String {
        formatter.string(from: date)
    }

    private nonisolated(unsafe) static let formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
}

// MARK: - Retention

/// Age-based pruning for the flight recorder files.
///
/// Retention is deliberately by *time*, never by "keep the newest N bytes":
/// a size-based rotation is exactly what destroys the evidence of a failure
/// that took two weeks to appear.
enum LogRetention {
    /// Returns the file names (of `names`) whose period is older than
    /// `retentionDays`. Unparseable names are always kept.
    static func expired(_ names: [String], retentionDays: Int, now: Date) -> [String] {
        names.filter { name in
            guard let period = periodStart(of: name) else { return false }
            let graceDays = retentionDays + period.graceDays
            let expiry = period.start.addingTimeInterval(TimeInterval(graceDays) * 86_400)
            return expiry < now
        }
    }

    /// `events-YYYY-MM-DD.log` → daily period; `heartbeat-YYYY-MM.log` → monthly
    /// period with 31 days of grace so the previous month never disappears while
    /// it is still recent.
    private static func periodStart(of name: String) -> (start: Date, graceDays: Int)? {
        let base = name.hasSuffix(".log") ? String(name.dropLast(4)) : name
        let parts = base.split(separator: "-")
        guard parts.count >= 3,
              let year = Int(parts[1]),
              let month = Int(parts[2]),
              (1...12).contains(month)
        else { return nil }

        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1

        switch parts[0] {
        case "events":
            guard parts.count == 4, let day = Int(parts[3]), (1...31).contains(day) else { return nil }
            components.day = day
            guard let start = calendar.date(from: components) else { return nil }
            return (start, 0)
        case "heartbeat":
            guard let start = calendar.date(from: components) else { return nil }
            return (start, 31)
        default:
            return nil
        }
    }

    private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        return calendar
    }()
}

// MARK: - Session sentinel

/// Detects deaths that produce no log line at all (crash, `kill -9`, OOM).
///
/// `begin` leaves a marker on disk; a clean shutdown removes it. Finding the
/// marker on the next launch means the previous session never said goodbye.
struct SessionSentinel {
    let directory: URL

    var url: URL { directory.appendingPathComponent("session.open") }

    /// Records this session start and returns the *previous* session when it did
    /// not close cleanly.
    func begin(sessionID: String, at date: Date) -> (sessionID: String, startedAt: Date)? {
        let previous = read()
        write(sessionID: sessionID, at: date)
        return previous
    }

    /// Marks the session as cleanly finished.
    func close() {
        try? FileManager.default.removeItem(at: url)
    }

    private func read() -> (sessionID: String, startedAt: Date)? {
        guard let text = try? String(contentsOf: url, encoding: .utf8) else { return nil }
        let parts = text.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: "|")
        guard parts.count == 2,
              let startedAt = EventFormatter.parse(String(parts[1]))
        else { return nil }
        return (String(parts[0]), startedAt)
    }

    private func write(sessionID: String, at date: Date) {
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let text = "\(sessionID)|\(EventFormatter.timestamp(date))\n"
        try? text.write(to: url, atomically: true, encoding: .utf8)
    }
}

extension EventFormatter {
    static func parse(_ text: String) -> Date? {
        parser.date(from: text)
    }

    private nonisolated(unsafe) static let parser: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
}
