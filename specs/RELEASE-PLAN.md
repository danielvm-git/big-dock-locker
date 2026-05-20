# DockLock Release Plan

## Epic 1: Foundation & Core Logic
Priority: P1 | Value: High | Effort: M | WSJF: 5.4

### Story 1.1: As a user, I want the app to detect my monitors so that I can choose which one to lock.
Status: [ ] Not started

Acceptance Criteria:
  Feature: Monitor Detection
    Scenario: App identifies all connected displays
      Given multiple monitors are connected
      When the app starts
      Then it retrieves a list of all display IDs and names

**Context**: This story implements the foundational display detection logic using CoreGraphics. It allows the app to know what screens are available so the user can eventually pick one to lock the Dock to.

## Steps
1. Define `DisplayInfo` model and `DisplayManager` protocol/class → verify: `swift build`
2. Implement `DisplayManager.getAllDisplays()` using `NSScreen` and `CGDisplay` APIs → verify: `swift test --filter DisplayManagerTests`
3. Add a temporary CLI flag `--list-displays` to `DockLock` to output detected screens → verify: `swift run DockLock --list-displays`

## Out of scope
- UI representation of displays (covered in Epic 2).
- Persistence of selected display (covered in Epic 3).

## Risks
- No monitors detected (edge case): Need to handle empty display list gracefully.
- Permissions: Some display info might require Screen Recording permissions on modern macOS (though `NSScreen` usually doesn't for basic info).

### Story 1.2: As a user, I want to prevent the Dock from jumping to other monitors.
Status: [ ] Not started

Acceptance Criteria:
  Feature: Anti-Jumping Logic
    Scenario: Mouse gesture at bottom of non-locked screen is ignored
      Given the Dock is locked to Monitor A
      When the mouse cursor stays at the bottom of Monitor B
      Then the Dock remains on Monitor A

**Context**: This story implements the core mechanism of DockLock: a CGEventTap that monitors mouse movements and prevents the cursor from triggering the Dock's monitor-jump gesture on non-selected displays.

## Steps
1. Create `DockLockEngine` class and `PermissionManager` to check/request Accessibility access → verify: `swift run DockLock --check-permissions`
2. Implement `CGEventTap` callback in `DockLockEngine` to detect mouse at screen edges → verify: `swift build`
3. Implement "bouncing" logic to keep mouse 2 pixels away from the bottom edge of non-locked displays → verify: Manual test (requires permissions)

## Out of scope
- Permanent background service (handled in Epic 3).
- Fine-grained control over "bounce" distance.

## Risks
- Accessibility Permissions: The app must be granted permissions by the user. If denied, the logic won't work.
- Performance: Mouse event taps run for every movement; logic must be O(1) and extremely fast.
- Multiple Monitors Setup: Complex topologies might require careful coordinate math.

## Epic 2: Menu Bar & Dashboard UI
Priority: P1 | Value: High | Effort: S | WSJF: 6.0

### Story 2.1: As a user, I want to access DockLock from the Menu Bar.
Status: [ ] Not started

Acceptance Criteria:
  Feature: Menu Bar Integration
    Scenario: Menu Bar icon is visible
      When the app launches
      Then a DockLock icon appears in the macOS Menu Bar

**Context**: This story transitions the app from a CLI tool to a resident Menu Bar application. It sets up the system tray presence and basic application lifecycle.

## Steps
1. Refactor `DockLock.swift` to a SwiftUI `App` and implement `MenuBarController` → verify: `swift build`
2. Add "Dashboard" and "Quit" menu items to the `NSStatusItem` → verify: `swift run` and check the menu bar

### Story 2.2: As a user, I want a Dashboard UI to select the locked monitor.
Status: [ ] Not started

Acceptance Criteria:
  Feature: Dashboard UI
    Scenario: Select a monitor from the list
      Given the Dashboard is open
      When I click on a monitor representation
      Then that monitor becomes the 'Locked' display

**Context**: This story provides the "face" of the application—a SwiftUI dashboard where users can see their monitor layout and choose which screen should hold the Dock.

## Steps
1. Create `DockLockViewModel` to manage app state (monitors, permissions, locking) → verify: `swift test --filter ViewModelTests` (if implemented)
2. Implement `DashboardView` with a list of displays and "Lock" toggles → verify: `swift build`
3. Integrate `DashboardView` into the `MenuBarController` as a popover or window → verify: `swift run` and click "Dashboard"

## Out of scope
- Custom monitor layout visualization (simple list for now).
- Dark/Light mode specific asset optimization (use SF Symbols).

## Risks
- App Sandbox: If the app is sandboxed, some display info might be limited (but we are currently not sandboxed).
- UI Blocking: Ensure the `CGEventTap` doesn't block the main thread.

## Epic 3: Persistence & Automation
Priority: P2 | Value: Med | Effort: S | WSJF: 5.5

### Story 3.1: As a user, I want my locked monitor preference to be saved.
Status: [ ] Not started

Acceptance Criteria:
  Feature: Settings Persistence
    Scenario: Locked monitor choice persists after restart
      Given I have locked the Dock to Monitor A
      When I restart the app
      Then the Dock remains locked to Monitor A

**Context**: This story ensures the user's configuration is saved. We'll use `UserDefaults` to store the ID of the locked monitor so the app can automatically resume its state on launch.

## Steps
1. Create `SettingsManager` class to handle `UserDefaults` operations → verify: `swift test --filter SettingsManagerTests`
2. Integrate `SettingsManager` into `DockLockViewModel` to load state on init and save on change → verify: `swift build`

### Story 3.2: As a user, I want DockLock to start at login.
Status: [ ] Not started

Acceptance Criteria:
  Feature: Start at Login
    Scenario: Enable start at login
      Given the 'Start at Login' setting is enabled
      When the system reboots
      Then DockLock launches automatically

**Context**: For a system utility like this, starting at login is essential. We'll implement this using `SMAppService` for modern macOS versions.

## Steps
1. Implement `LoginItemManager` using `SMAppService` to register the main app as a login item → verify: `swift build`
2. Add "Launch at Login" toggle to `DashboardView` and bind it to `LoginItemManager` → verify: `swift run` and check toggle functionality

## Out of scope
- iCloud sync for settings.
- Complex login item management (e.g. helper apps).

## Risks
- SMAppService availability: Requires macOS 13+. We are targeting macOS 14, so it should be fine.
- Sandbox constraints: If enabled, login items require specific entitlements.
