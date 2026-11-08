# Big DockLocker — Claude Code

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
| Lint   | `swiftlint --strict` |
| Health check | `bash scripts/health-check.sh` |
| Diagnostics bundle | `bash scripts/collect-diagnostics.sh` |

## Observability
This app is a flight recorder (see `specs/PLAN-flight-recorder.md`). Three destinations:

1. **Unified log** — subsystem `com.danielvm.BigDockLocker`.
2. **`~/Library/Logs/BigDockLocker/events-YYYY-MM-DD.log`** — rare, structured incidents
   (`TAP_DISABLED`, `TAP_REENABLE`, `SLEEP`, `WAKE`, `LOCK`, `GAP`, `DOCK_WRONG_DISPLAY`).
3. **`~/Library/Logs/BigDockLocker/heartbeat-YYYY-MM.log`** — one pipe-delimited line per
   minute (16 columns, ~140 KB/month). Retention is 30 days **by age**; never by size.

| What | Command |
|------|---------|
| Health check (read-only, idempotent) | `bash scripts/health-check.sh` |
| Paste-ready bundle after a failure | `bash scripts/collect-diagnostics.sh` |
| Tail incidents | `tail -f ~/Library/Logs/BigDockLocker/events-$(date +%Y-%m-%d).log` |
| Unified log, live | `log stream --predicate 'subsystem == "com.danielvm.BigDockLocker"' --info` |
| Unified log, last 6h | `log show --last 6h --predicate 'subsystem == "com.danielvm.BigDockLocker"' --info` |
| Why protection died | `grep -E 'TAP_DISABLED|TAP_REENABLE|GAP|DOCK_WRONG' ~/Library/Logs/BigDockLocker/events-*.log` |

`DockLog` (Sources/BigDockLocker/DockLog.swift) is the only logging entry point. Never log
in the per-event hot path — a slow tap callback is itself what makes macOS kill the tap.
The heartbeat carries `cbmax_us` for exactly that: it is the kill predictor.

## CI
`.github/workflows/test-build-release.yml` is the gate: `lint -> test -> build (arm64 +
x86_64) -> release`. The release job runs `semantic-release` only on `push` to `main`
and only after all prior jobs pass. Never publish from a separate workflow.
SwiftLint is pinned to `0.63.2` in the workflow's `env`. Do not swap it for an
unpinned `brew install`: that is how a newly released rule blocks a release over
code nobody touched.

Before pushing a workflow change, run locally:

```bash
swiftlint --strict && swift build && swift test && actionlint .github/workflows/*.yml
```

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
