# Release Plan - Gatekeeper Malware Warning Fix

## Context
The application triggers a "malware" warning on macOS because it uses suspicious entitlements (`allow-jit`, `allow-unsigned-executable-memory`) and a deprecated signing algorithm (`sha1`). This plan removes those entitlements and modernizes the signing process to reduce Gatekeeper friction.

## User Stories

### Story 1: Modernize Signing and Entitlements
As a user, I want to download and run DockLock without a scary malware warning so that I can trust the application.

**Implementation Steps:**

1. Clean up `Entitlements.plist` by removing JIT and unsigned memory entitlements → verify: `grep -E "allow-jit|allow-unsigned-executable-memory" Entitlements.plist` returns nothing.
2. Update `scripts/build-app.sh` to use only `sha256` and remove `--deep` from the initial signing (keeping it for verification) → verify: `./scripts/build-app.sh` does not output SHA1 deprecation warnings.
3. Verify the final app bundle signature integrity → verify: `codesign -vvv --deep DockLock.app` returns "valid on disk" and "satisfies its Designated Requirement".
4. Re-create the DMG to ensure it remains unsigned and mounts correctly → verify: `./scripts/create-dmg.sh && codesign -dvvv DockLock.dmg` fails with "code object is not signed at all".
5. Run automated tests to ensure core logic is unaffected → verify: `swift test`

## Out of Scope
- Obtaining a paid Apple Developer ID for notarization.
- Automated UI testing of the Gatekeeper dialog itself.

## Risks
- Removing `--deep` might miss nested components if they are added in the future, but current structure is flat.
- macOS Gatekeeper behavior is opaque and may still show a warning (unidentified developer), but it should no longer mention "malware" as prominently if the signature is "cleaner".
