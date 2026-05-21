## Problem

Three issues have been reported following the recent 1.3.0 release:
1. **Version Mismatch**: Local builds and the distributed app show the wrong version (v1.2.0 or v1.1.0) on the screen even when 1.3.0 is expected.
2. **DMG Failure**: The downloaded `DockLock.dmg` does not open or is reported as corrupted.
3. **README Out of Sync**: The `README.md` file still refers to version 1.1 or 1.2 and is not updated during the automated release process.

## Root Cause Analysis

### Bug 1: Version Mismatch
The `.github/workflows/release.yml` performs the "Build and Package" step *before* `npx semantic-release` runs.
`semantic-release` is responsible for calculating the next version and updating `Info.plist` (via `scripts/update-version.sh`). 
Because the app is built before this update, the binary and the `.app` bundle packaged into the DMG contain the old version metadata.

### Bug 2: DMG Failure
The DMG creation in CI uses `npx create-dmg DockLock.app || true`. The `|| true` suppresses errors, potentially resulting in an incomplete or corrupted DMG being uploaded. 
Furthermore, the app is ad-hoc signed (`codesign -s -`), which is often blocked by macOS Gatekeeper when downloaded from the internet. 
The rename command `mv DockLock*.dmg DockLock.dmg` might also be failing if multiple DMGs exist or if the pattern doesn't match.

### Bug 3: README Out of Sync
The `README.md` file contains a hardcoded version string ("v1.1 Signature Edition") and is not included in the `@semantic-release/git` assets list, nor is there a script to update its content during the release.

Risk level: **Medium** (Impacts distribution and user perception).

## TDD Fix Plan

### 1. Unified Versioning & Documentation
**RED**: Write a test/script that checks if `README.md` and `Info.plist` contain the expected version string.
**GREEN**: Update `scripts/update-version.sh` to also perform a regex replacement in `README.md`. Update `.releaserc.json` to include `README.md` in the git assets.
**verify**: `./scripts/update-version.sh 9.9.9 && grep "9.9.9" README.md`

### 2. Correct Build Sequencing
**RED**: (CI Simulation) Verify that a build triggered *after* version bump contains the new version in its `Info.plist`.
**GREEN**: Create a `scripts/build-app.sh` that encapsulates building, packaging, and signing. Call this script from the `prepare` step of `semantic-release` *after* `update-version.sh`.
**verify**: `ls DockLock.app/Contents/Info.plist`

### 3. Robust DMG Creation
**RED**: Fail the build if `create-dmg` fails.
**GREEN**: Update the packaging script to remove `|| true` and add explicit checks for the existence of `DockLock.app` and its contents before DMG creation.
**verify**: `./scripts/create-dmg.sh` (locally)

### 4. CI Workflow Optimization
**RED**: Check `release.yml` and identify that `Build and Package` happens too early.
**GREEN**: Remove the manual `Build and Package` step from `release.yml` and let `semantic-release` handle it via `prepareCmd`.
**verify**: Review `release.yml` structure.

## Acceptance Criteria

- [ ] `Info.plist` version matches the released version tag.
- [ ] `README.md` version string is updated automatically during release.
- [ ] Distributed DMG contains a functional `.app` with the correct version.
- [ ] CI pipeline fails if the DMG cannot be created successfully.
- [ ] `DashboardView.swift` correctly displays the version from the bundle.

## Resolution
<!-- filled in by validate-fix -->
