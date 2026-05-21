# Big DockLocker — Gemini CLI

Read CONVENTIONS.md before any GitHub or git operation.

## Project
A native Swift dashboard application focused exclusively on anti-jumping logic for the macOS Dock, with a roadmap for full Big DockLocker Pro features.
Stack: Swift / SwiftUI / macOS native

## Commands
| Action | Command |
|--------|---------|
| Run    | `swift run` |
| Test   | `swift test` |
| Build  | `swift build` |
| Lint   | `swiftlint` |

## Architecture
Background monitoring agent using macOS Accessibility and CoreGraphics APIs to lock the Dock, coupled with a SwiftUI Dashboard for configuration and status.

## Conventions
- Standard Swift naming conventions (PascalCase for types, camelCase for variables).
- MVVM architecture for the dashboard UI.
- Strict separation between monitoring logic and UI layers.
- Follow bigpowers principles.

## Never
- Violate bigpowers principles.
- Use private APIs that could jeopardize system stability.

## Agent Rules
- **Workflow Mandate:** You MUST use the bigpowers skills (e.g. `plan-work`, `develop-tdd`, `orchestrate-project`) to perform tasks. DO NOT write code directly in response to a user prompt like "build this feature".
- Read specs/ before writing code.
- All planning and specifications MUST be written to `specs/` (e.g. `specs/PLAN.md`) before any code is generated.
- Write the minimum code that solves the stated problem. Nothing extra.
- Never refactor, rename, or reorganize code outside the task scope.
- Run tests after every change. Show evidence before declaring done.
- One clarifying question beats a wrong assumption baked into 200 lines.
