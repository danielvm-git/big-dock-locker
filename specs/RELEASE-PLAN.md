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

## Epic 4: Visual Polish & Identity (v1.1 - Current)
Priority: P1 | Value: High | Effort: S | WSJF: 7.0
**Status: [x] Done**
- Apply "Paper & Ink" theme.
- Create official AppIcon.icns.

## Epic 5: Professional Distribution (v1.2 - Next)
Priority: P1 | Value: High | Effort: M | WSJF: 6.5
**Status: [x] Done**

### Story 5.1: As a user, I want a .dmg installer so I can easily drag the app to /Applications.
- **Tasks:**
  - [x] Implement `create-dmg` script to generate a branded Disk Image → verify: `./scripts/create-dmg.sh`
  - [x] Configure GitHub Actions to attach `.dmg` instead of `.zip` to releases → verify: Check GitHub Release assets

---

## Future Roadmap (V2: Advanced UX & Feedback)

### Epic 6: Smart Onboarding & Permissions
- **Story 6.1:** Interactive Onboarding Wizard (Welcome -> Permission -> Choose Anchor).
- **Story 6.2:** Haptic Feedback on intercept (subtle tap on Force Touch trackpads).

### Epic 7: Deep Analytics & Activity
- **Story 7.1:** Prevention Counter (track total "Dock jumps" blocked by the engine).
- **Story 7.2:** Activity Log (Live event stream showing topology changes and intercepts).
- **Story 7.3:** Pause Timer (Quick-pause for 30s/1m via Menu Bar/Dashboard).

### Epic 8: Sidebar Navigation
- **Story 8.1:** Full macOS Sidebar layout as seen in System Design.
- **Story 8.2:** Categorized views (Status, Displays, Behavior, Activity, About).
