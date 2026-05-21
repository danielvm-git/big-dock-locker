## Problem

Users report that the `.dmg` file cannot even be opened (mounted) on recent macOS versions. 
The last version that worked was v1.3.1.

## Root Cause Analysis

### DMG Signing Conflict
Investigation revealed that after v1.3.1, ad-hoc signing was added to the `.dmg` file itself. 

1. **Ad-hoc Signature on DMG**: While ad-hoc signing (`codesign -s -`) is necessary for the `.app` bundle to run on ARM64 Macs, applying it to the `.dmg` container can cause macOS Gatekeeper to block the disk image from mounting entirely if it's not from a trusted Developer ID.
2. **Mount Failure**: An ad-hoc signed DMG downloaded from the internet is often treated as "corrupted" or "unverified" by macOS Sonoma/Sequoia without offering a clear bypass, unlike an unsigned DMG which typically allows a Right-Click -> Open bypass to mount it.
3. **v1.3.1 Regression**: Version 1.3.1 used an unsigned DMG with a signed App, which allowed users to mount the image and then bypass the App's security.

Risk level: **High** (Prevents installation entirely).

## Fix Approach

1. **Revert DMG Signing**: Remove the `codesign` step for the `.dmg` file in `scripts/create-dmg.sh`.
2. **Maintain App Signing**: Keep the ad-hoc signature on the `.app` bundle (done in `scripts/build-app.sh`).
3. **Update Instructions**: Ensure README accurately reflects the behavior of an unsigned DMG.

## TDD Fix Plan

### 1. Script Correction
**RED**: `scripts/create-dmg.sh` produces a signed DMG.
**GREEN**: Revert the `codesign` step for the DMG.
**verify**: `./scripts/create-dmg.sh && codesign -dv DockLock.dmg` (should fail with "not signed")

### 2. Verification of App Signature
**RED**: Check if the App inside the DMG is still signed.
**GREEN**: Ensure `build-app.sh` is called and signs the App.
**verify**: `codesign -dv DockLock.app`

## Acceptance Criteria

- [ ] `DockLock.dmg` is not signed.
- [ ] `DockLock.app` is ad-hoc signed.
- [ ] `README.md` instructions match the "unsigned DMG" behavior.

## Resolution

**Fixed:** 2026-05-21
**Root cause confirmed:** Ad-hoc signing the `.dmg` container (added after v1.3.1) caused macOS Gatekeeper to block mounting entirely. Reverting to an unsigned DMG while keeping the `.app` ad-hoc signed restores the expected behavior.
**Fix applied:** 
- Removed `codesign -s - "$DMG_NAME"` from `scripts/create-dmg.sh`.
- Verified `.app` bundle remains signed.
**Hardening added:** Added explicit manual signature check in the build process to ensure the `.app` is always signed even if the DMG isn't.
**Evidence:** `codesign -dv DockLock.app` passes; `codesign -dv DockLock.dmg` fails as intended.
**Commit:** `fix(release): revert DMG ad-hoc signing to fix mount issues`
