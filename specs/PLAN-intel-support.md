# Plan: Intel Support (Option B: Separate DMGs)

## Goal
Produce two separate release artifacts: `DockLock-arm64.dmg` and `DockLock-x86_64.dmg` to support both Apple Silicon and Intel Macs natively.

## Implementation Steps

### 1. Parameterize `scripts/build-app.sh` [x]
- Add support for an `--arch` argument (values: `arm64`, `x86_64`). [x]
- Pass `--arch <arch>` to `swift build`. [x]
- Update the app bundle path to include the architecture during the build process to avoid collisions (e.g., `DockLock-arm64.app`). [x]
- Ensure `codesign` is applied to the correct architecture-specific bundle. [x]

### 2. Parameterize `scripts/create-dmg.sh` [x]
- Add support for an architecture argument. [x]
- Output the DMG with a name reflecting the architecture (e.g., `DockLock-arm64.dmg`). [x]
- Use the architecture-specific `.app` bundle created in step 1. [x]

### 3. Update `.releaserc.json` [x]
- Update `prepareCmd` to build and package both architectures sequentially. [x]
- Update the `github` plugin assets to include both `DockLock-arm64.dmg` and `DockLock-x86_64.dmg`. [x]

### 4. Update README.md [x]
- Update the "Installation" section to provide links/instructions for both architectures. [x]
- Clarify which DMG should be used for which Mac type. [x]

### 5. Target macOS 13 for both [x]
- Update `Package.swift` to `.macOS(.v13)`. [x]
- Update README system requirements. [x]

## Verification
- Run `./scripts/build-app.sh --arch arm64` and verify `DockLock-arm64.app` is created.
- Run `./scripts/build-app.sh --arch x86_64` and verify `DockLock-x86_64.app` is created.
- Run `file DockLock-arm64.app/Contents/MacOS/DockLock` to confirm architecture.
- Run `file DockLock-x86_64.app/Contents/MacOS/DockLock` to confirm architecture.
- Verify both DMGs are created with correct names.

## Acceptance Criteria
- [x] Build script produces architecture-specific app bundles.
- [x] DMG script produces architecture-specific DMGs.
- [x] Semantic Release is configured to publish both DMGs.
- [x] README is updated with download guidance for both platforms.
