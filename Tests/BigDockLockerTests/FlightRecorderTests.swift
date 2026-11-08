import Testing
import Foundation
@testable import BigDockLocker

/// Tests for the flight recorder's pure pieces: line formats, gap classification,
/// retention pruning and the crash sentinel. File I/O and AppKit probing are
/// covered by the manual verification in specs/PLAN-flight-recorder.md.
@Suite("FlightRecorder")
struct FlightRecorderTests {

    // MARK: - Helpers

    private static func instant(_ iso: String) -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: iso) else {
            fatalError("bad test fixture: \(iso)")
        }
        return date
    }

    private static func sample(
        at iso: String,
        uptime: Int,
        tap: Bool = true,
        trust: Bool = true,
        locked: Bool = false,
        secure: Int32 = 0,
        asleep: Bool = false,
        screens: Int = 2,
        dock: Int = 1,
        mouse: Int = 1,
        events: UInt64 = 0,
        bounces: UInt64 = 0,
        callbackMax: UInt64 = 0,
        cpu: UInt64 = 0,
        rss: Int = 0
    ) -> HeartbeatSample {
        HeartbeatSample(
            timestamp: instant(iso),
            uptimeSeconds: uptime,
            pid: 913,
            tapEnabled: tap,
            accessibilityTrusted: trust,
            screenLocked: locked,
            secureInputPID: secure,
            mainDisplayAsleep: asleep,
            screenCount: screens,
            dockDisplay: dock,
            mouseDisplay: mouse,
            eventsSeen: events,
            bouncesApplied: bounces,
            callbackMaxMicros: callbackMax,
            cpuMillis: cpu,
            residentMegabytes: rss
        )
    }

    // MARK: - Heartbeat line

    @Test func heartbeatLineHasOneFieldPerColumn() {
        let line = Self.sample(at: "2026-08-03T04:12:00.000Z", uptime: 518412)
            .line()
        #expect(line.split(separator: "|").count == 16)
        #expect(line.split(separator: "|").count == HeartbeatSample.header.split(separator: "|").count)
    }

    @Test func heartbeatLineFormat() {
        let line = Self.sample(
            at: "2026-08-03T04:12:00.000Z",
            uptime: 518412,
            tap: true,
            trust: true,
            locked: false,
            secure: 0,
            asleep: false,
            screens: 2,
            dock: 1,
            mouse: 1,
            events: 4_122_330,
            bounces: 0,
            callbackMax: 840,
            cpu: 12,
            rss: 88
        ).line()
        #expect(line == "2026-08-03T04:12:00Z|518412|913|1|1|0|0|0|2|1|1|4122330|0|840|12|88")
    }

    @Test func heartbeatEncodesTheKillSignatures() {
        let broken = Self.sample(
            at: "2026-08-03T04:13:00.000Z",
            uptime: 518472,
            tap: false,
            trust: true,
            locked: true,
            secure: 1442
        ).line()
        let fields = broken.split(separator: "|", omittingEmptySubsequences: false)
        #expect(fields[3] == "0") // tap disabled  -> H1
        #expect(fields[5] == "1") // lock          -> H5
        #expect(fields[6] == "1442") // secure pid -> H4
    }

    // MARK: - Gap classification

    @Test func noGapForNormalInterval() {
        #expect(GapClassifier.classify(wallDelta: 60, uptimeDelta: 60) == .none)
    }

    @Test func gapForSystemSleep() {
        // Wall clock advanced an hour, the monotonic clock only 2 minutes.
        #expect(GapClassifier.classify(wallDelta: 3600, uptimeDelta: 120) == .systemSlept)
    }

    @Test func gapForStalledProcess() {
        // Both clocks advanced; rows are simply missing => nobody was scheduled.
        #expect(GapClassifier.classify(wallDelta: 600, uptimeDelta: 600) == .suspendedOrKilled)
    }

    @Test func gapForClockChange() {
        #expect(GapClassifier.classify(wallDelta: -30, uptimeDelta: 60) == .clockChanged)
    }

    @Test func gapEventIsOnlyEmittedWhenSomethingWasMissed() {
        let previous = Self.sample(at: "2026-08-03T04:12:00.000Z", uptime: 518412)
        let normal = Self.sample(at: "2026-08-03T04:13:00.000Z", uptime: 518472)
        let slept = Self.sample(at: "2026-08-03T05:12:00.000Z", uptime: 518532)

        #expect(normal.gapEvent(previous: previous) == nil)

        let gap = slept.gapEvent(previous: previous)
        #expect(gap?.contains("verdict=system_slept") == true)
        #expect(gap?.contains("missing=59") == true)
    }

    // MARK: - Event lines

    @Test func eventLineFormat() {
        let event = LogEvent(
            timestamp: Self.instant("2026-08-03T04:12:33.412Z"),
            sessionID: "7b1c9d",
            category: "ENGINE",
            name: "TAP_DISABLED",
            fields: ["reason=timeout", "disables=1"]
        )
        #expect(event.line == "2026-08-03T04:12:33.412Z [S:7b1c9d] ENGINE TAP_DISABLED reason=timeout disables=1")
    }

    @Test func eventLineWithoutFieldsHasNoTrailingSpace() {
        let event = LogEvent(
            timestamp: Self.instant("2026-08-03T04:12:33.412Z"),
            sessionID: "7b1c9d",
            category: "ENGINE",
            name: "TAP_REENABLE"
        )
        #expect(event.line == "2026-08-03T04:12:33.412Z [S:7b1c9d] ENGINE TAP_REENABLE")
    }

    // MARK: - Retention

    @Test func retentionPrunesOnlyExpiredPeriods() {
        let now = Self.instant("2026-08-10T00:00:00.000Z")
        let names = [
            "events-2026-08-09.log",
            "events-2026-07-01.log",   // 40 days old
            "heartbeat-2026-08.log",   // current month
            "heartbeat-2026-01.log",   // old month
            "session.open",
            "notes.txt"
        ]
        let expired = LogRetention.expired(names, retentionDays: 30, now: now)
        #expect(expired == ["events-2026-07-01.log", "heartbeat-2026-01.log"])
    }

    @Test func retentionKeepsPreviousMonthWhileInGrace() {
        // On the 2nd of the month the previous month's file is still young.
        let now = Self.instant("2026-08-02T00:00:00.000Z")
        let expired = LogRetention.expired(["heartbeat-2026-07.log"], retentionDays: 30, now: now)
        #expect(expired.isEmpty)
    }

    // MARK: - Crash sentinel

    @Test func sentinelReportsUncleanSession() throws {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("fd-sentinel-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let sentinel = SessionSentinel(directory: directory)
        let firstStart = Self.instant("2026-08-01T10:00:00.000Z")

        // First ever launch: nothing to report.
        #expect(sentinel.begin(sessionID: "aaaaaa", at: firstStart) == nil)

        // Simulate a crash: the marker is still there on the next launch.
        let previous = sentinel.begin(sessionID: "bbbbbb", at: Self.instant("2026-08-03T04:00:00.000Z"))
        #expect(previous?.sessionID == "aaaaaa")
        #expect(previous?.startedAt == firstStart)

        // A clean shutdown clears the marker.
        sentinel.close()
        #expect(sentinel.begin(sessionID: "cccccc", at: Self.instant("2026-08-04T09:00:00.000Z")) == nil)
    }
}
