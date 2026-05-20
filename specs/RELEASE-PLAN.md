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

Tasks:
  - [ ] Implement `DockLockEngine` using Accessibility APIs to intercept Dock triggers → verify: TBD (Manual verification or UI test)
  - [ ] Implement locking logic to pin Dock to a specific CGDisplay → verify: `swift test --filter DockLockEngineTests`

## Epic 2: Menu Bar & Dashboard UI
Priority: P1 | Value: High | Effort: S | WSJF: 6.0

### Story 2.1: As a user, I want to access DockLock from the Menu Bar.
Status: [ ] Not started

Acceptance Criteria:
  Feature: Menu Bar Integration
    Scenario: Menu Bar icon is visible
      When the app launches
      Then a DockLock icon appears in the macOS Menu Bar

Tasks:
  - [ ] Create `AppDelegate` and `MenuBarController` → verify: `swift run` and check menu bar
  - [ ] Add "Quit" and "Open Dashboard" menu items → verify: Manual test of menu items

### Story 2.2: As a user, I want a Dashboard UI to select the locked monitor.
Status: [ ] Not started

Acceptance Criteria:
  Feature: Dashboard UI
    Scenario: Select a monitor from the list
      Given the Dashboard is open
      When I click on a monitor representation
      Then that monitor becomes the 'Locked' display

Tasks:
  - [ ] Implement `DashboardView` in SwiftUI → verify: `swift run` and open dashboard
  - [ ] Bind `DashboardView` selection to `DockLockEngine` → verify: Selection updates engine state

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

Tasks:
  - [ ] Implement `SettingsManager` using `UserDefaults` → verify: `swift test --filter SettingsManagerTests`
  - [ ] Integrate `SettingsManager` with `DockLockEngine` → verify: Engine loads saved monitor on start

### Story 3.2: As a user, I want DockLock to start at login.
Status: [ ] Not started

Acceptance Criteria:
  Feature: Start at Login
    Scenario: Enable start at login
      Given the 'Start at Login' setting is enabled
      When the system reboots
      Then DockLock launches automatically

Tasks:
  - [ ] Implement login item registration (e.g., using `LaunchServices` or `SMAppService`) → verify: Check system settings for login items
