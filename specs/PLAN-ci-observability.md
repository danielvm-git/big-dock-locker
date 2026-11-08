# PLAN — Wire CI + finish Observability

Skills: `wire-ci`, `wire-observability`.

## State found

| Check | Result |
|-------|--------|
| Forge (`origin`) | GitHub → `danielvm-git/big-dock-locker` |
| Stack | Swift (SwiftPM, `Package.swift`, macOS-only) |
| Bundled CI template | **None** — wire-ci ships Rust/Node/Python/Go only → workflow written by hand |
| Existing CI | `.github/workflows/release.yml` only (semantic-release, **no test/build gate**) |
| `swift build` | **FAILS** — `DockLog.loggers` not concurrency-safe under Swift 6 |
| `swiftlint --strict` | **15 violations** (line length, colon, opening brace, `fm` identifier) |
| Structured logging | Present (`DockLog`, os.Logger + rotating file) |
| Observability commands in CLAUDE.md | **Missing** |
| Idempotent setup / health script | **Missing** |

A CI gate is worthless while the baseline is red, so step 1 is repairing the build
and lint. No behaviour change in the engine's logic.

## Changes

1. **`DockLog.swift` — make it compile under Swift 6 strict concurrency.**
   `Category` gains `Sendable`; cosmetic lint fixes (colon spacing, brace spacing,
   `fm` → `fileManager`). Log output format unchanged.
2. **Long log lines (engine + viewmodel)** split with string concatenation so the
   120-column limit holds. Message text is byte-identical.
3. **`.github/workflows/test-build-release.yml`** — `lint → test → build → release`
   as one `needs:` chain on `macos-latest`. Release job carries the existing
   semantic-release steps verbatim and only runs on `push` to `main`.
4. **`.github/workflows/release.yml` deleted** — its job moved into the chain, so
   releases cannot happen when lint/tests fail, and semantic-release cannot run twice.
5. **`specs/forge.yaml`** — pins `forge: github` for future `wire-ci` runs.
6. **CLAUDE.md → Observability section** — log tail, unified-log query, health check.
7. **`scripts/health-check.sh`** — read-only, idempotent status probe (running?,
   log path, last log lines, event-tap disables in the last hour).

## Verify

```bash
swift build && swift test && swiftlint --strict     # must be exit 0
bash scripts/health-check.sh && bash scripts/health-check.sh   # twice, no error
ruby -ryaml -e 'YAML.load_file(".github/workflows/test-build-release.yml")'
actionlint .github/workflows/*.yml                  # if installed
```

`act` cannot run `macos-latest` jobs (no Docker macOS runner), so the dry-run
gate is: YAML parse + `actionlint` locally, then `gh run watch` on the first push.

## Out of scope

- Code signing / notarization of the DMGs (release stays ad-hoc signed, as today).
- Deploy workflow (desktop app — the release job is terminal).
