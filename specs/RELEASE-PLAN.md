# Release Plan - Gatekeeper Malware Warning Fix

## Context
The application triggers a "malware" warning on macOS because it uses suspicious entitlements (`allow-jit`, `allow-unsigned-executable-memory`) and a deprecated signing algorithm (`sha1`). This plan removes those entitlements and modernizes the signing process to reduce Gatekeeper friction.

## User Stories

### Story 1: Modernize Signing and Entitlements
As a user, I want to download and run DockLock without a scary malware warning so that I can trust the application.

**Implementation Steps:**

1. [x] Clean up `Entitlements.plist` by removing JIT and unsigned memory entitlements → verify: `grep -E "allow-jit|allow-unsigned-executable-memory" Entitlements.plist` returns nothing.
2. [x] Update `scripts/build-app.sh` to use only `sha256` and remove `--deep` from the initial signing (keeping it for verification) → verify: `./scripts/build-app.sh` does not output SHA1 deprecation warnings.
3. [x] Verify the final app bundle signature integrity → verify: `codesign -vvv --deep DockLock.app` returns "valid on disk" and "satisfies its Designated Requirement".
4. [x] Re-create the DMG to ensure it remains unsigned and mounts correctly → verify: `./scripts/create-dmg.sh && codesign -dvvv DockLock.dmg` fails with "code object is not signed at all".
5. [x] Run automated tests to ensure core logic is unaffected → verify: `swift test`

## Out of Scope
- Obtaining a paid Apple Developer ID for notarization.
- Automated UI testing of the Gatekeeper dialog itself.

## Risks
- Removing `--deep` might miss nested components if they are added in the future, but current structure is flat.
- macOS Gatekeeper behavior is opaque and may still show a warning (unidentified developer), but it should no longer mention "malware" as prominently if the signature is "cleaner".

---

## Existing Roadmap Status

### Story 5.5: Audit and minimize codesign entitlements
Status: [x] Done
**Context**: Handled in the Gatekeeper Malware Warning Fix. All 5 suspicious entitlements removed.

### Story 5.6: Modernize codesign invocation
Status: [x] Done
**Context**: Handled in the Gatekeeper Malware Warning Fix. Switched to `sha256` and removed `--deep`.

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
