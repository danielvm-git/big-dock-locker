## Target
"Big DockLocker" (Application name, Swift module, Target name, and related symbols)

## Dependents (89 occurrences)
- `Package.swift`: Defines the module and target names.
- `Sources/BigDockLocker/`: Directory containing all source code.
- `Tests/BigDockLockerTests/`: Directory containing all tests.
- `Info.plist`: Defines the bundle identifier and display name.
- `scripts/*.sh`: Build and distribution scripts.
- `specs/*.md`: Documentation and implementation plans.
- `README.md`, `GEMINI.md`, `CLAUDE.md`: Project documentation.
- `DashboardView.swift`, `BigDockLocker.swift`, `BigDockLockerEngine.swift`, `BigDockLockerViewModel.swift`: UI and core logic.
- `.releaserc.json`: Release configuration.

## Affected Stories
- All existing functionality is affected as it relies on the module name and file structure.

## Test Coverage
- `Tests/BigDockLockerTests/`: Covers core logic and display management.
- Gap: UI string verification is mostly manual.

## Risk: High
Renaming the main module and targets is a breaking change that affects the entire build system, file structure, and source code. Failure to update all references will lead to compilation errors or broken scripts.

## Recommended action
Proceed with a systematic rename using a detailed plan in `specs/RELEASE-PLAN.md`. Use `sed` or similar for bulk text replacement and `mv` for directory/file renaming.
