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

### Story 5.2: Fix Release Versioning and Distribution (v1.3.1)
Status: [x] Done

### Story 5.3: Enhance Security Documentation & Gatekeeper Bypass (v1.3.2 → v1.3.4)
Status: [x] Done

Acceptance Criteria:
  Feature: Clear Security Instructions
    Scenario: User encounters Gatekeeper warning and finds a solution in README
      Given the app is not notarized
      When the user sees "Apple could not verify..."
      Then the README provides a clear, Sequoia-correct bypass guide
      And the README explains the ad-hoc signing situation

**Context**: Addressed in v1.3.4. README now matches the literal Sequoia dialog text and documents the working bypass paths (`xattr -dr` and System Settings → Open Anyway). The right-click trick was removed by Apple in Sequoia for this dialog and is no longer the primary recommendation.

## Out of scope
- Notarization (see Story 5.4).
- Entitlements / codesign audit (see Stories 5.5 and 5.6).

### Story 5.4: Apple Notarization to remove first-launch warning
Status: [ ] Not started
Priority: P2 | Value: High | Effort: M | WSJF: 4.5

Acceptance Criteria:
  Feature: Notarized Distribution
    Scenario: User downloads DockLock from GitHub Releases on a clean Mac
      Given the .dmg comes from GitHub Releases
      When the user double-clicks the installed app
      Then no Gatekeeper warning appears on first launch

**Context**: As long as DockLock is only ad-hoc signed, Sequoia will show "Apple could not verify ... free of malware" on every clean-install first launch. The only way to eliminate the dialog is Apple Notarization.

## Steps
1. Enroll in the Apple Developer Program ($99/yr) and provision a Developer ID Application certificate.
2. Import the cert and notarization credentials into GitHub Actions secrets.
3. Update `scripts/build-app.sh` to sign with the Developer ID identity instead of `-`.
4. Add `xcrun notarytool submit --wait` + `xcrun stapler staple` to the release workflow.
5. Verify on a clean macOS box that the dialog no longer appears.

## Out of scope
- Migrating to a paid Mac App Store distribution.

## Risks
- Cost: ongoing $99/yr.
- CI complexity: notarization can take minutes per release; need timeout/retry handling.

### Story 5.5: Audit and minimize codesign entitlements
Status: [ ] Not started
Priority: P3 | Value: Low-Medium | Effort: S | WSJF: 3.0

Acceptance Criteria:
  Feature: Minimal Entitlements
    Scenario: Build produces an app with only justified entitlements
      Given Entitlements.plist
      When the app is built and signed
      Then every remaining entitlement has a documented reason in a code comment
      And the app still launches and prevents Dock jumps on Apple Silicon and Intel

**Context**: `Entitlements.plist` currently grants five `cs.*` privileged entitlements — `allow-jit`, `allow-unsigned-executable-memory`, `disable-executable-page-protection`, `disable-library-validation`, `allow-dyld-environment-variables` — all added in commit `160a9aa` without a documented rationale. A non-sandboxed SwiftUI app using Accessibility + CGEventTap should need none of these, and they make the binary look like a JIT/exploit vector. They are also not honored under ad-hoc signing, so removing them is unlikely to change runtime behavior — but it must be verified on real hardware.

## Steps
1. Remove all five entitlements and rebuild → verify: `swift build && ./scripts/build-app.sh`
2. Manually smoke-test on Apple Silicon: launch app, grant Accessibility, start engine, confirm Dock jumps are prevented across multiple monitors.
3. If any entitlement is genuinely needed, restore it with a `<!-- justified because: ... -->` XML comment.
4. Repeat smoke test on Intel if available.

## Out of scope
- Codesign flag changes (see Story 5.6).

## Risks
- Apple Silicon hardware required for a real test before merging.

### Story 5.6: Modernize codesign invocation
Status: [ ] Not started
Priority: P3 | Value: Low | Effort: XS | WSJF: 2.0

Acceptance Criteria:
  Feature: Modern Signing
    Scenario: Build script signs without deprecated options
      Given scripts/build-app.sh
      When the app is built
      Then codesign uses sha256 only and no --deep flag
      And the produced bundle passes `codesign -vvv`
      And the app still launches on Apple Silicon and Intel

**Context**: PR #4 added `--deep --digest-algorithm=sha1,sha256` to `scripts/build-app.sh` with the comment "for maximum compatibility / Apple Silicon". DockLock has no nested bundles, frameworks, or dylibs, so `--deep` is a no-op; sha1 has been deprecated by Apple. The reduced form is `codesign --force -s - --entitlements Entitlements.plist DockLock.app`.

## Steps
1. Simplify the codesign call.
2. Run the full build + DMG pipeline.
3. Smoke-test the resulting app on Apple Silicon.

## Out of scope
- Entitlement audit (see Story 5.5).
- Notarization (see Story 5.4).

## Risks
- The PR #4 rationale ("Apple Silicon compatibility") is technically thin, but it just shipped — needs a real-hardware regression test before merging.

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
