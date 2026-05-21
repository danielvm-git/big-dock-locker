## Problem

Users report that after mounting the DMG, the `DockLock` app triggers the macOS Gatekeeper warning:
"Apple could not verify “DockLock” is free of malware that may harm your Mac or compromise your privacy."

While the previous fix restored the ability to mount the DMG, the App itself is still blocked. The user expects a more seamless experience or at least a working bypass.

## Root Cause Analysis

### Gatekeeper Block (Malware Warning)
The "free of malware" warning is specifically triggered by signed binaries that have not been **Notarized** by Apple.

1. **Ad-hoc Signing Complexity**: The recent "refinement" in `scripts/build-app.sh` added `--deep` and `--digest-algorithm=sha1,sha256`. 
   - `--deep` is often discouraged and can cause signature invalidation in certain bundle structures.
   - `sha1` is deprecated and triggers a warning in the build logs; it may also be treated as less secure by modern macOS Gatekeeper.
2. **Suspicious Entitlements**: The `Entitlements.plist` includes `allow-jit` and `allow-unsigned-executable-memory`. These are common indicators for malware or JIT-based exploits and are NOT used by DockLock (a native Swift app).
3. **Signature vs. Notarization**: Even with a perfect ad-hoc signature, the warning will appear. However, an "over-privileged" or "deprecated" signature makes the bypass harder or the warning more severe.

Risk level: **Medium**

## TDD Fix Plan

### 1. Entitlement Cleanup
**RED**: `Entitlements.plist` contains `allow-jit` or `allow-unsigned-executable-memory`.
**GREEN**: Remove unused entitlements. Keep only what is necessary (if anything) for a non-sandboxed app.
**verify**: `grep "allow-jit" Entitlements.plist` should return nothing.

### 2. Signing Optimization
**RED**: `scripts/build-app.sh` uses `--deep` and `sha1`.
**GREEN**: Update `codesign` to use only `sha256` and remove `--deep`.
**verify**: `./scripts/build-app.sh` output should not contain SHA1 deprecation warning.

### 3. Signature Verification
**RED**: App signature is rejected by `spctl --assess` (this is expected, but we want to ensure it's a "clean" rejection).
**GREEN**: Ensure `codesign -vvv --deep` (manual check) passes.
**verify**: `codesign -vvv --deep DockLock.app`

## Acceptance Criteria

- [ ] `Entitlements.plist` is minimized (no JIT/unsigned memory).
- [ ] `scripts/build-app.sh` uses modern signing flags (no sha1).
- [ ] Build process no longer emits deprecation warnings.
- [ ] App remains functional (engine can still start).

## Resolution
<!-- filled in by validate-fix -->
