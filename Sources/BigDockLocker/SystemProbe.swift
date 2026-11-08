import Foundation
import AppKit
import CoreGraphics

/// Everything the heartbeat needs to describe the state of the world.
///
/// Called once per minute — never from the event-tap callback. Every function
/// degrades to a neutral value (-1 / 0 / false) instead of failing, because a
/// probe that throws would hide the very failure it is meant to record.
enum SystemProbe {

    struct Snapshot {
        var screenLocked: Bool
        var secureInputPID: Int32
        var mainDisplayAsleep: Bool
        var cpuMillisTotal: UInt64
        var residentMegabytes: Int
    }

    static func snapshot() -> Snapshot {
        let session = sessionDictionary()
        let locked = (session["CGSSessionScreenIsLocked"] as? Bool) ?? false
        let secureInput = Int32((session["kCGSSessionSecureInputPID"] as? Int) ?? 0)
        let metrics = processMetrics()

        return Snapshot(
            screenLocked: locked,
            secureInputPID: secureInput,
            mainDisplayAsleep: CGDisplayIsAsleep(CGMainDisplayID()) != 0,
            cpuMillisTotal: metrics.cpuMillis,
            residentMegabytes: metrics.residentMegabytes
        )
    }

    /// Outcome of asking the Dock where its window is. The error code and window
    /// count are part of the probe on purpose: a detector that fails silently is
    /// worse than no detector, because the log then says "everything fine".
    struct DockProbe {
        var displayIndex: Int = -1
        var childCount: Int = 0
        var errorCode: Int32 = 0
        /// Roles of the Dock's AX children, so a failed probe explains itself.
        var roles: [String] = []

        var rolesDescription: String {
            roles.isEmpty ? "none" : roles.joined(separator: ",")
        }
    }

    /// Display index hosting the Dock window. This is the only direct detector of
    /// "the Dock jumped to another screen".
    static func dockProbe() -> DockProbe {
        var probe = DockProbe()
        guard let dock = NSRunningApplication
            .runningApplications(withBundleIdentifier: "com.apple.dock").first
        else {
            probe.errorCode = -1 // Dock process not found
            return probe
        }

        let application = AXUIElementCreateApplication(dock.processIdentifier)

        // The Dock exposes no AXWindows at all: its tile strip is an AXList child.
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(application, kAXChildrenAttribute as CFString, &value)
        probe.errorCode = result.rawValue
        guard result == .success else { return probe }

        let children = (value as? [AXUIElement]) ?? []
        probe.childCount = children.count

        var listArea: CGFloat = 0
        var listCentre = CGPoint.zero
        var largestArea: CGFloat = 0
        var largestCentre = CGPoint.zero

        for child in children {
            let role = stringAttribute(child, kAXRoleAttribute) ?? "?"
            if probe.roles.count < 6 { probe.roles.append(role) }
            guard let frame = frame(of: child), !frame.isEmpty else { continue }
            let area = frame.width * frame.height
            if role == "AXList" && area > listArea {
                listArea = area
                listCentre = CGPoint(x: frame.midX, y: frame.midY)
            }
            if area > largestArea {
                largestArea = area
                largestCentre = CGPoint(x: frame.midX, y: frame.midY)
            }
        }

        // Prefer the tile strip; fall back to the largest child that has a frame.
        guard listArea > 0 || largestArea > 0 else { return probe }
        let centre = listArea > 0 ? listCentre : largestCentre
        probe.displayIndex = displayIndex(of: centre)
        return probe
    }

    private static func stringAttribute(_ element: AXUIElement, _ name: String) -> String? {
        guard let value = attribute(element, name) else { return nil }
        return value as? String
    }

    /// Display index under the cursor.
    static func mouseDisplayIndex() -> Int {
        guard let primary = NSScreen.screens.first else { return -1 }
        let location = NSEvent.mouseLocation
        let flipped = CGPoint(x: location.x, y: primary.frame.height - location.y)
        return displayIndex(of: flipped)
    }

    /// Display index for a `CGDirectDisplayID`.
    static func displayIndex(for displayID: CGDirectDisplayID) -> Int {
        let screens = NSScreen.screens
        for (index, screen) in screens.enumerated() {
            let key = NSDeviceDescriptionKey("NSScreenNumber")
            if let number = screen.deviceDescription[key] as? CGDirectDisplayID, number == displayID {
                return index
            }
        }
        return -1
    }

    // MARK: - Geometry

    /// Maps a CoreGraphics global point (top-left origin) to a screen index.
    /// Index 0 is the primary display, matching `NSScreen.screens`.
    static func displayIndex(of cgPoint: CGPoint) -> Int {
        guard let primary = NSScreen.screens.first else { return -1 }
        for (index, screen) in NSScreen.screens.enumerated() {
            let frame = screen.frame
            let cgFrame = CGRect(
                x: frame.origin.x,
                y: primary.frame.height - frame.origin.y - frame.size.height,
                width: frame.size.width,
                height: frame.size.height
            )
            if cgFrame.contains(cgPoint) { return index }
        }
        return -1
    }

    private static func frame(of element: AXUIElement) -> CGRect? {
        guard let origin = pointAttribute(element, kAXPositionAttribute),
              let size = sizeAttribute(element, kAXSizeAttribute)
        else { return nil }
        return CGRect(origin: origin, size: size)
    }

    private static func pointAttribute(_ element: AXUIElement, _ name: String) -> CGPoint? {
        guard let value = axValue(of: element, name) else { return nil }
        var point = CGPoint.zero
        guard AXValueGetValue(value, .cgPoint, &point) else { return nil }
        return point
    }

    private static func sizeAttribute(_ element: AXUIElement, _ name: String) -> CGSize? {
        guard let value = axValue(of: element, name) else { return nil }
        var size = CGSize.zero
        guard AXValueGetValue(value, .cgSize, &size) else { return nil }
        return size
    }

    /// AX values are opaque CF types; the CFTypeID check above the cast proves the
    /// dynamic type, which is exactly what SwiftLint's force_cast rule cannot see.
    private static func axValue(of element: AXUIElement, _ name: String) -> AXValue? {
        guard let raw = attribute(element, name), CFGetTypeID(raw) == AXValueGetTypeID() else { return nil }
        // swiftlint:disable:next force_cast
        return (raw as! AXValue)
    }

    private static func attribute(_ element: AXUIElement, _ name: String) -> CFTypeRef? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success else { return nil }
        return value
    }

    // MARK: - Session and process

    private static func sessionDictionary() -> [String: Any] {
        guard let session = CGSessionCopyCurrentDictionary() as? [String: Any] else { return [:] }
        return session
    }

    /// Cumulative CPU milliseconds and current resident memory of this process.
    private static func processMetrics() -> (cpuMillis: UInt64, residentMegabytes: Int) {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(
            MemoryLayout<mach_task_basic_info>.size / MemoryLayout<natural_t>.size
        )
        let result = withUnsafeMutablePointer(to: &info) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { rebound in
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), rebound, &count)
            }
        }
        guard result == KERN_SUCCESS else { return (0, 0) }

        let seconds = UInt64(info.user_time.seconds) + UInt64(info.system_time.seconds)
        let micros = UInt64(info.user_time.microseconds) + UInt64(info.system_time.microseconds)
        let cpuMillis = seconds * 1000 + micros / 1000
        return (cpuMillis, Int(info.resident_size) / (1024 * 1024))
    }
}
