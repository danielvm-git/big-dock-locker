## Problem

Users are reporting that the `.dmg` file itself is being blocked by macOS Gatekeeper with the message:
"Apple could not verify “DockLock-4.dmg” is free of malware that may harm your Mac or compromise your privacy."

This prevents the user from even mounting the disk image to access the application.

## Root Cause Analysis

### DMG Gatekeeper Blocking
On macOS Sonoma and Sequoia, any file downloaded from the internet (with the `com.apple.quarantine` attribute) is subject to Gatekeeper. If the file is not notarized, macOS shows the "Apple could not verify..." warning.

1. **Ad-hoc Signing**: Currently, the `create-dmg.sh` script signs the DMG ad-hoc (`codesign -s -`). While technically a signature, it is not from a trusted developer ID, so it triggers the same warning as an unsigned file.
2. **User Confusion**: Users are accustomed to being able to open DMGs. The strictness of recent macOS versions on ad-hoc signed DMGs might be higher than expected.
3. **Double Blocking**: The user faces two hurdles: first opening the DMG, then opening the App. If the first hurdle fails, they never see the instructions inside or in the README for the second hurdle.

### Contributing Factors
- The `npx create-dmg` tool might be adding metadata that macOS finds suspicious when combined with an ad-hoc signature.
- The `README.md` focuses on bypassing the `.app` block but doesn't explicitly mention that the `.dmg` itself might need a Right-Click -> Open bypass.

Risk level: **Medium** (High impact on user experience/installation).

## Fix Approach

1. **Explicit DMG Instructions**: Update `README.md` to explicitly mention that the DMG itself may need the Right-Click bypass.
2. **Simplified DMG Creation**: Test if an unsigned DMG is "easier" to open or if we should stick with ad-hoc signing but with better instructions.
3. **Improve Security Helper**: Update `fix-quarantine.sh` to optionally handle the DMG path if passed as an argument.

## TDD Fix Plan

### 1. Documentation Update
**RED**: Check if `README.md` mentions the DMG block.
**GREEN**: Add specific instructions for opening the DMG itself (Right-Click -> Open).
**verify**: `grep "Right-Click the DMG" README.md`

### 2. Script Improvement
**RED**: `scripts/create-dmg.sh` signs the DMG without verifying if it's necessary or if it causes more friction.
**GREEN**: Ensure the `.app` is signed, but maybe leave the DMG unsigned or clearly document the behavior. Actually, keep the ad-hoc signature but ensure the instructions are perfect.
**verify**: `./scripts/create-dmg.sh`

### 3. Comprehensive Quarantine Fixer
**RED**: `scripts/fix-quarantine.sh` only targets `/Applications/DockLock.app`.
**GREEN**: Update the script to take an optional path, allowing users to run it on the DMG or the App anywhere.
**verify**: `./scripts/fix-quarantine.sh ~/Downloads/DockLock.dmg` (mock path)

## Acceptance Criteria

- [ ] `README.md` explicitly addresses the DMG blocking message.
- [ ] `README.md` explains the Right-Click bypass for both the DMG and the App.
- [ ] `scripts/fix-quarantine.sh` is more flexible.
- [ ] Instructions are verified to match the exact wording of the macOS error.

## Resolution
<!-- filled in by validate-fix -->
