import Foundation
import Combine
import CoreGraphics
import AppKit

@MainActor
public class BigDockLockerViewModel: ObservableObject {
    @Published public var displays: [DisplayInfo] = []
    @Published public var lockedDisplayID: CGDirectDisplayID?
    @Published public var isGranted: Bool = false
    @Published public var isRunning: Bool = false

    @Published public var launchAtLogin: Bool = false

    private let displayManager = DisplayManager()
    private let engine = BigDockLockerEngine()
    private var cancellables = Set<AnyCancellable>()

    /// Last observed set of display IDs, so we can log reconfigurations
    /// (monitor sleep/wake, resolution/arrangement changes) — another common
    /// trigger for the Dock jumping.
    private var lastDisplayIDs: [CGDirectDisplayID] = []

    public init() {
        DockLog.notice(.lifecycle, "Big DockLocker launching. Logs: \(DockLog.directory.path)")
        self.lockedDisplayID = SettingsManager.shared.lockedDisplayID
        self.launchAtLogin = LoginItemManager.shared.isEnabled
        engine.lockedDisplayID = self.lockedDisplayID
        refresh()

        // Start engine automatically if permissions are granted
        if PermissionManager.isAccessibilityGranted() {
            startEngine()
        } else {
            DockLog.warning(
                .permission,
                "Accessibility NOT granted at launch — engine will not start until permission is enabled."
            )
        }

        // Sleep, wake, lock and session switches are the usual suspects for a tap
        // that stops delivering events without ever reporting a disable.
        observeSystemEvents()

        // Timer to refresh displays periodically or on demand
        Timer.publish(every: 5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.refresh()
                // Drive the engine heartbeat off this existing main-thread timer.
                self?.engine.logHeartbeatIfDue()
            }
            .store(in: &cancellables)
    }

    public func refresh() {        let wasGranted = isGranted
        isGranted = PermissionManager.isAccessibilityGranted()
        if wasGranted != isGranted {
            DockLog.notice(.permission, "Accessibility permission changed: \(isGranted ? "GRANTED" : "REVOKED").")
        }

        do {
            displays = try displayManager.getAllDisplays()
            let ids = displays.map { $0.id }
            if ids != lastDisplayIDs {
                DockLog.notice(
                    .display,
                    "Display configuration changed. Now \(displays.count) display(s): " +
                    "\(displays.map { "\($0.name)#\($0.id)" }.joined(separator: ", "))."
                )
                DockLog.event(.display, "DISPLAYS_CHANGED", [
                    "count=\(displays.count)",
                    "ids=\(ids.map(String.init).joined(separator: ","))"
                ])
                lastDisplayIDs = ids
            }
        } catch {
            DockLog.error(.display, "Failed to fetch displays: \(error.localizedDescription)")
            print("Failed to fetch displays: \(error)")
        }
    }

    public func toggleLock(for displayID: CGDirectDisplayID) {
        if lockedDisplayID == displayID {
            lockedDisplayID = nil
            engine.lockedDisplayID = nil
        } else {
            lockedDisplayID = displayID
            engine.lockedDisplayID = displayID
        }
        SettingsManager.shared.lockedDisplayID = lockedDisplayID
        DockLog.notice(.lifecycle, "Locked display set to: \(lockedDisplayID.map(String.init) ?? "none").")
    }

    public func toggleLaunchAtLogin() {
        LoginItemManager.shared.toggle()
        launchAtLogin = LoginItemManager.shared.isEnabled
    }

    public func startEngine() {
        do {
            try engine.start()
            isRunning = true
            DockLog.notice(.lifecycle, "Engine started via ViewModel.")
        } catch {
            isRunning = false
            DockLog.error(.lifecycle, "Engine failed to start: \(error.localizedDescription)")
            print("Engine failed to start: \(error)")
        }
    }

    public func stopEngine() {
        engine.stop()
        isRunning = false
        DockLog.notice(.lifecycle, "Engine stopped via ViewModel.")
    }

    public func requestPermissions() {
        PermissionManager.requestAccessibility()
    }

    public func openSettings() {
        PermissionManager.openAccessibilitySettings()
    }

    /// Records the lifecycle transitions that can silently kill a session event tap.
    private func observeSystemEvents() {
        let workspace = NSWorkspace.shared.notificationCenter
        workspace.addObserver(forName: NSWorkspace.willSleepNotification, object: nil, queue: .main) { _ in
            DockLog.event(.lifecycle, "SLEEP")
        }
        workspace.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { _ in
            DockLog.event(.lifecycle, "WAKE", [
                "uptime=\(Int(ProcessInfo.processInfo.systemUptime))"
            ])
            // Sample straight away instead of waiting for the next minute.
            MainActor.assumeIsolated { self.engine.logHeartbeatIfDue(force: true) }
        }
        workspace.addObserver(
            forName: NSWorkspace.sessionDidResignActiveNotification, object: nil, queue: .main
        ) { _ in
            DockLog.event(.lifecycle, "SESSION_RESIGN")
        }
        workspace.addObserver(
            forName: NSWorkspace.sessionDidBecomeActiveNotification, object: nil, queue: .main
        ) { _ in
            DockLog.event(.lifecycle, "SESSION_ACTIVE")
        }

        let distributed = DistributedNotificationCenter.default()
        distributed.addObserver(forName: .init("com.apple.screenIsLocked"), object: nil, queue: .main) { _ in
            DockLog.event(.lifecycle, "LOCK")
        }
        distributed.addObserver(forName: .init("com.apple.screenIsUnlocked"), object: nil, queue: .main) { _ in
            DockLog.event(.lifecycle, "UNLOCK")
        }
    }
}
