import Foundation
import CoreGraphics
import AppKit

public class BigDockLockerEngine {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    /// Timestamp of the last heartbeat we emitted. The heartbeat is driven by
    /// the ViewModel's existing main-thread refresh timer (see
    /// `logHeartbeatIfDue()`) so we don't add another timer or risk capturing
    /// this non-Sendable engine in a `@Sendable` timer closure.
    private var lastHeartbeat = Date()
    private let heartbeatInterval: TimeInterval = 60

    // Diagnostic counters. These are only mutated from the event-tap callback
    // and the heartbeat timer, both of which run on the same run loop that
    // `start()` was called from, so no locking is required.
    private var eventsHandled: UInt64 = 0
    private var bouncesApplied: UInt64 = 0
    private var tapDisableCount: UInt64 = 0
    private var eventsSinceHeartbeat: UInt64 = 0
    private var bouncesSinceHeartbeat: UInt64 = 0

    /// Slowest tap callback since the last heartbeat, in microseconds. macOS kills
    /// a tap whose callback takes too long, so this is the *predictor* of the death.
    private var callbackMaxMicros: UInt64 = 0

    /// Cumulative process CPU at the previous heartbeat, to report a delta.
    private var lastCPUMillis: UInt64 = 0

    /// Last display index the Dock window was seen on (-1 = unknown).
    private var lastDockDisplay = -1

    /// Last Dock probe outcome, so only changes are logged.
    private var lastProbeKey = ""

    public var lockedDisplayID: CGDirectDisplayID?

    public init() {
        // Default to locking to the primary display
        self.lockedDisplayID = CGMainDisplayID()
    }

    public func start() throws {
        guard eventTap == nil else {
            DockLog.info(.engine, "start() called but engine is already running; ignoring.")
            return
        }

        let granted = PermissionManager.isAccessibilityGranted()
        DockLog.info(
            .engine,
            "Starting engine. Accessibility: \(granted ? "TRUSTED" : "NOT TRUSTED"). " +
            "Locked display: \(lockedDisplayID.map(String.init) ?? "none"). " +
            "Logs: \(DockLog.directory.path)"
        )

        let mask = (1 << CGEventType.mouseMoved.rawValue)

        let callback: CGEventTapCallBack = { (_, type, event, refcon) -> Unmanaged<CGEvent>? in
            guard let refcon = refcon else { return Unmanaged.passUnretained(event) }
            let engine = Unmanaged<BigDockLockerEngine>.fromOpaque(refcon).takeUnretainedValue()

            // macOS notifies us here (regardless of the event mask) when it
            // disables the tap. This is the event we were previously missing —
            // it's why the Dock "starts jumping again after a few hours".
            if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                engine.handleTapDisabled(type)
                return nil
            }

            return engine.handleMouseEvent(event)
        }

        let refcon = Unmanaged.passUnretained(self).toOpaque()

        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(mask),
            callback: callback,
            userInfo: refcon
        )

        guard let tap = eventTap else {
            let message = "Failed to create event tap. Accessibility: \(granted ? "TRUSTED" : "NOT TRUSTED")."
            DockLog.error(.engine, message)
            DockLog.event(.engine, "TAP_CREATE", ["ok=0", "trusted=\(granted ? 1 : 0)"])
            print(message)
            throw NSError(domain: "BigDockLockerEngine", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
        }

        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        let enabled = CGEvent.tapIsEnabled(tap: tap)
        DockLog.notice(.engine, "Event tap created and enabled: \(enabled).")
        DockLog.event(.engine, "ENGINE_START", ["session=\(DockLog.sessionID)"])
        DockLog.event(.engine, "TAP_CREATE", ["ok=1", "enabled=\(enabled ? 1 : 0)", "trusted=\(granted ? 1 : 0)"])

        lastHeartbeat = Date()
    }

    public func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            if let source = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
            }
            eventTap = nil
            runLoopSource = nil
            DockLog.notice(
                .engine,
                "Engine stopped. Totals — events: \(eventsHandled), bounces: \(bouncesApplied), " +
                "tap-disable events: \(tapDisableCount)."
            )
            DockLog.event(.engine, "ENGINE_STOP", [
                "events=\(eventsHandled)",
                "bounces=\(bouncesApplied)",
                "disables=\(tapDisableCount)"
            ])
        } else {
            DockLog.info(.engine, "stop() called but engine was not running.")
        }
    }

    // MARK: - Tap health

    /// Called when macOS disables our event tap. We log the reason (this is the
    /// root cause of the "Dock jumps again after hours" symptom) and re-enable
    /// the tap so protection resumes automatically.
    private func handleTapDisabled(_ type: CGEventType) {
        tapDisableCount += 1
        let reason = (type == .tapDisabledByTimeout)
            ? "TIMEOUT (our callback ran too slowly, or the system was under load / waking from sleep)"
            : "USER_INPUT (interrupted by user input timeout)"
        DockLog.warning(
            .engine,
            "⚠️ Event tap was DISABLED by macOS — reason: \(reason). " +
            "This is why Dock protection stopped. Re-enabling (disable #\(tapDisableCount))."
        )
        DockLog.event(.engine, "TAP_DISABLED", ["disables=\(tapDisableCount)", "reason=\(reasonName(type))"])

        guard let tap = eventTap else {
            DockLog.error(.engine, "Cannot re-enable event tap: tap reference is nil.")
            return
        }
        CGEvent.tapEnable(tap: tap, enable: true)
        let nowEnabled = CGEvent.tapIsEnabled(tap: tap)
        DockLog.event(.engine, "TAP_REENABLE", ["ok=\(nowEnabled ? 1 : 0)"])
        if nowEnabled {
            DockLog.notice(.engine, "✅ Event tap re-enabled successfully. Dock protection resumed.")
        } else {
            DockLog.error(.engine, "Re-enable attempt did NOT take — tap still reports disabled.")
        }
    }

    /// Emit a heartbeat if at least `heartbeatInterval` seconds have passed.
    /// Call this from a recurring main-thread timer (the ViewModel does this).
    /// Does nothing while the engine is stopped.
    public func logHeartbeatIfDue(force: Bool = false) {
        guard eventTap != nil else { return }
        guard force || Date().timeIntervalSince(lastHeartbeat) >= heartbeatInterval else { return }
        lastHeartbeat = Date()
        emitHeartbeat()
    }

    private func emitHeartbeat() {
        let snapshot = SystemProbe.snapshot()
        let enabled = eventTap.map { CGEvent.tapIsEnabled(tap: $0) } ?? false
        let probe = SystemProbe.dockProbe()
        let dockDisplay = probe.displayIndex

        let cpuDelta = snapshot.cpuMillisTotal >= lastCPUMillis
            ? snapshot.cpuMillisTotal - lastCPUMillis
            : 0
        lastCPUMillis = snapshot.cpuMillisTotal

        let sample = HeartbeatSample(
            timestamp: Date(),
            uptimeSeconds: Int(ProcessInfo.processInfo.systemUptime),
            pid: getpid(),
            tapEnabled: enabled,
            accessibilityTrusted: PermissionManager.isAccessibilityGranted(),
            screenLocked: snapshot.screenLocked,
            secureInputPID: snapshot.secureInputPID,
            mainDisplayAsleep: snapshot.mainDisplayAsleep,
            screenCount: NSScreen.screens.count,
            dockDisplay: dockDisplay,
            mouseDisplay: SystemProbe.mouseDisplayIndex(),
            eventsSeen: eventsHandled,
            bouncesApplied: bouncesApplied,
            callbackMaxMicros: callbackMaxMicros,
            cpuMillis: cpuDelta,
            residentMegabytes: snapshot.residentMegabytes
        )
        DockLog.heartbeat(sample)
        logDockChange(dockDisplay: dockDisplay)
        logDockProbe(probe)

        eventsSinceHeartbeat = 0
        bouncesSinceHeartbeat = 0
        callbackMaxMicros = 0

        // Defensive self-heal: if the tap somehow went dormant without us
        // seeing a disable event, bring it back and record it.
        if let tap = eventTap, enabled == false {
            DockLog.warning(.engine, "Heartbeat found the tap DISABLED. Re-enabling.")
            CGEvent.tapEnable(tap: tap, enable: true)
            DockLog.event(.engine, "TAP_REENABLE", [
                "ok=\(CGEvent.tapIsEnabled(tap: tap) ? 1 : 0)",
                "source=heartbeat"
            ])
        }
    }

    private func handleMouseEvent(_ event: CGEvent) -> Unmanaged<CGEvent>? {
        let started = DispatchTime.now().uptimeNanoseconds
        defer { recordCallback(since: started) }

        eventsHandled += 1
        eventsSinceHeartbeat += 1

        let location = event.location
        let screens = NSScreen.screens

        // Find which screen the mouse is currently on
        // NSScreen.screens are ordered: [0] is primary.
        // Screen coords: (0,0) is bottom-left of primary.
        // CGEvent coords: (0,0) is top-left of primary.

        for screen in screens {
            let frame = screen.frame

            // Convert NSScreen frame to CG (top-left origin)
            // CG origin.y = PrimaryScreen.Height - Frame.Origin.Y - Frame.Height
            let primaryHeight = screens[0].frame.height
            let cgFrameY = primaryHeight - frame.origin.y - frame.size.height
            let cgFrame = CGRect(x: frame.origin.x, y: cgFrameY, width: frame.size.width, height: frame.size.height)

            // Check if mouse is in this screen
            if cgFrame.contains(location) {
                // If this is NOT the locked screen, check for bottom edge
                let displayID =
                    screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")]
                        as? CGDirectDisplayID ?? 0

                if let lockedID = lockedDisplayID, displayID != lockedID {
                    let bottomEdge = cgFrame.origin.y + cgFrame.size.height

                    // Danger Zone: bottom 2 pixels
                    if location.y >= (bottomEdge - 2) {
                        var newLocation = location
                        newLocation.y = bottomEdge - 3 // Bounce back up
                        event.location = newLocation
                        bouncesApplied += 1
                        bouncesSinceHeartbeat += 1
                        return Unmanaged.passRetained(event)
                    }
                }
                break
            }
        }

        return Unmanaged.passRetained(event)
    }

    // MARK: - Instrumentation

    /// Records why the Dock probe succeeded or failed, whenever the answer changes.
    /// Without this the H8 detector can be dead and the log would look healthy.
    private func logDockProbe(_ probe: SystemProbe.DockProbe) {
        let key = "\(probe.displayIndex)|\(probe.childCount)|\(probe.errorCode)"
        guard key != lastProbeKey else { return }
        lastProbeKey = key
        DockLog.event(.dock, probe.displayIndex >= 0 ? "DOCK_PROBE" : "DOCK_PROBE_FAILED", [
            "display=\(probe.displayIndex)",
            "children=\(probe.childCount)",
            "ax_error=\(probe.errorCode)",
            "roles=\(probe.rolesDescription)"
        ])
    }

    /// The only direct detector of the user-visible symptom: the Dock is sitting on
    /// a display that is not the locked one.
    private func logDockChange(dockDisplay: Int) {
        guard dockDisplay != lastDockDisplay else { return }
        let lockedIndex = lockedDisplayID.map(SystemProbe.displayIndex(for:)) ?? -1
        var fields = [
            "dock_disp=\(dockDisplay)",
            "locked_disp=\(lockedIndex)",
            "prev_dock_disp=\(lastDockDisplay)"
        ]
        let wrong = dockDisplay >= 0 && lockedIndex >= 0 && dockDisplay != lockedIndex
        if wrong { fields.append("autohide=1") }
        if wrong {
            DockLog.event(.dock, "DOCK_WRONG_DISPLAY", fields)
        } else if lastDockDisplay >= 0 {
            DockLog.event(.dock, "DOCK_MOVED", fields)
        }
        // A first successful reading is not a move — it is just the baseline.
        lastDockDisplay = dockDisplay
    }

    private func recordCallback(since start: UInt64) {
        let micros = (DispatchTime.now().uptimeNanoseconds - start) / 1000
        if micros > callbackMaxMicros { callbackMaxMicros = micros }
    }

    private func reasonName(_ type: CGEventType) -> String {
        type == .tapDisabledByTimeout ? "timeout" : "user_input"
    }
}
