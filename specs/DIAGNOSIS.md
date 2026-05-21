## Problem

A user reported that after downloading the DMG version 1.3.1, they encounter a Gatekeeper warning:
"Apple could not verify “DockLock” is free of malware that may harm your Mac or compromise your privacy."
The user stated they used Right-Click -> Open, which is the standard bypass, but it seems they are still seeing a blocking message or are confused by the scary wording.

## Root Cause Analysis

### Gatekeeper and Ad-hoc Signing
DockLock is currently ad-hoc signed (`codesign -s -`) because it is an open-source project without an Apple Developer Program membership for official notarization.
On modern macOS (especially Sonoma/Sequoia), Gatekeeper is extremely restrictive with ad-hoc signed apps downloaded from the internet.

1. **Scary Wording**: The "Apple could not verify..." message is the standard warning for any app that is not notarized. 
2. **Right-Click Bypass**: While Right-Click -> Open usually provides an "Open" button, some users might still find it intimidating or macOS might require the app to be moved to `/Applications` first for the bypass to stick.
3. **Quarantine Attribute**: Downloaded files have the `com.apple.quarantine` attribute. For ad-hoc apps, this attribute sometimes persists even after the right-click attempt if not done correctly.

### Contributing Factors
- The troubleshooting guide in `README.md` might be too brief.
- Users might be trying to run the app directly from the DMG, which triggers stricter Gatekeeper checks.

Risk level: **Low** (Security feature of macOS, not a bug in DockLock code, but a distribution/UX issue).

## Fix Approach

1. **Enhance Troubleshooting Documentation**: Add a dedicated "Gatekeeper & Security" section to the README with a screenshot (if possible) or very explicit step-by-step instructions.
2. **Add a Security Helper Script**: Provide a simple `open_binary_folder.sh` (already exists but for a different purpose) or a `fix-permissions.sh` that users can run if they are comfortable with the terminal, or simply improve the manual instructions.
3. **Clarify DMG Usage**: Explicitly state that the app MUST be moved to `/Applications` before attempting to open it via right-click.

## TDD Fix Plan

### 1. Documentation Update
**RED**: Check if `README.md` contains explicit instructions for the "Apple could not verify" message.
**GREEN**: Add a detailed "Gatekeeper & Security" section to `README.md` explaining *why* the message appears (ad-hoc signing) and providing the exact 3-step bypass.
**verify**: `grep "Apple could not verify" README.md`

### 2. Improve DMG script
**RED**: Check if `create-dmg.sh` uses any signing on the DMG itself.
**GREEN**: Use `--identity=-` for `create-dmg` if possible, or ensure the `.app` is signed *before* it's put in the DMG (already done, but double check).
**verify**: `./scripts/create-dmg.sh`

## Acceptance Criteria

- [ ] `README.md` has a clear, prominent section for Gatekeeper issues.
- [ ] Instructions explicitly mention the "Apple could not verify" message.
- [ ] Instructions clarify the need to move the app to `/Applications` first.
- [ ] (Optional) A small script to clear the quarantine attribute is provided for power users.

## Resolution
<!-- filled in by validate-fix -->
