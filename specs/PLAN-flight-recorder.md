# PLAN — Flight recorder: log that survives days/weeks and is paste-ready

## Problem

The app works, then stops protecting after days/weeks of uninterrupted uptime.
There is **no data** afterwards:

- The installed release (v1.5.1) contains **no logging at all** — `DockLog.swift` was
  never committed, `~/Library/Logs/BigDockLocker/` doesn't exist, and
  `log show --last 7d --predicate 'subsystem == "com.danielvm.BigDockLocker"'` returns 0 lines.
- The upcoming `DockLog` writes a **human** line per event and a heartbeat every 60 s,
  rotating at **2 MB with one backup**. At ~250 B/heartbeat that is ≈ 8 000 lines
  ≈ **5–6 days** of history. Two backups ≈ 11 days. Weeks-long runs lose the evidence
  exactly when it is needed.
- The current heartbeat records **engine internals only** (`tap enabled`, counters,
  screen count). It cannot distinguish "the tap is installed but the process is being
  starved" from "the tap was killed" from "the session stopped delivering events"
  from "the Dock actually moved".

## Failure hypotheses the format must discriminate

| # | Hypothesis | Signature |
|---|-----------|-----------|
| H1 | Event tap disabled (`kCGEventTapDisabledByTimeout`) and re-enable failed | `tap=0` in heartbeat; `TAP_REENABLE ok=0` event |
| H2 | Tap alive but our callback is starved (App Nap / run-loop stall) | heartbeat rows keep coming, `nev` frozen, `cbmax_us` near/over 1000 ms |
| H3 | Callback too slow → macOS kills tap (chicken-and-egg with H2) | rising `cbmax_us` in the minutes **before** `tap` flips to 0 |
| H4 | Secure input active (password field, 1Password, Terminal) → session tap gets nothing | `secure>0` while `nev` frozen |
| H5 | Screen locked / user switched → session tap gets nothing | `lock=1` while `nev` frozen |
| H6 | System slept / hibernated; tap not re-armed on wake | wall↔uptime divergence + missing rows + `WAKE` event |
| H7 | Process died (crash, OOM, force quit, login item removed) | rows stop, next launch logs `SESSION_START prev=unclean` |
| H8 | Protection "working" but the Dock **did** move to another display | `dock_disp != locked_disp` in heartbeat |

H8 is the only direct detector of the user-visible symptom. Everything else is inference.

## Design

Two appends, daily files, **retention by age (30 days), never by destroying the last copy**.

### 1. `events-YYYY-MM-DD.log` — discrete, human-readable, rare

```
2026-08-03T04:12:33.412Z [S:7b1c9d] ENGINE TAP_DISABLED reason=timeout disables=1
2026-08-03T04:12:33.419Z [S:7b1c9d] ENGINE TAP_REENABLE ok=1
2026-08-03T04:12:33.421Z [S:7b1c9d] DOCK dock_disp=2 locked_disp=1 autohide=1 landed=1  <-- FAILURE
```

Event vocabulary: `SESSION_START` (with `prev=clean|unclean`), `SESSION_END`, `ENGINE_START`,
`ENGINE_STOP`, `TAP_CREATE`, `TAP_DISABLED`, `TAP_REENABLE`, `SLEEP`, `WAKE`, `LOCK`,
`UNLOCK`, `SESSION_RESIGN`, `SESSION_ACTIVE`, `DISPLAYS_CHANGED`, `PERMISSION_GRANTED`,
`PERMISSION_REVOKED`, `DOCK` (position change), `GAP`.

### 2. `heartbeat-YYYY-MM.log` — 1 line/min, pipe-delimited, one header per session

```
# hb2 session=7b1c9d app=1.6.0 mac=15.3 boot=2026-07-28T09:00:12.000Z
# ts|up|pid|tap|ax|lock|secure|dsleep|nscr|dock_disp|mouse_disp|nev|nb|cbmax_us|cpu_ms|rss_mb
2026-08-03T04:12:00Z|518412|913|1|1|0|0|0|2|1|1|4122330|0|840|12|88
```

| Col | Meaning | Reads as |
|-----|---------|----------|
| `ts` | wall clock UTC | — |
| `up` | `ProcessInfo.systemUptime` (monotonic, **stops during sleep**) | with `ts`: sleep vs. clock change |
| `pid` | process id | restart detection |
| `tap` | `CGEvent.tapIsEnabled` | **H1** |
| `ax` | `AXIsProcessTrusted()` | TCC revoked after launch |
| `lock` | `CGSSessionScreenIsLocked` | **H5** |
| `secure` | `kCGSSessionSecureInputPID` (0 = none) | **H4** |
| `dsleep` | `CGDisplayIsAsleep(main)` | display asleep |
| `nscr` | display count | reconfiguration |
| `dock_disp` | display index hosting the Dock window (AX) | **H8** |
| `mouse_disp` | display index under the cursor | **H8** context |
| `nev` | cumulative events seen by the tap | **H2/H3** (frozen = starved) |
| `nb` | cumulative bounce corrections applied | sanity |
| `cbmax_us` | max tap-callback duration in the last minute (µs) | **H3** (kill predictor) |
| `cpu_ms` | process CPU ms in the last minute | starvation evidence |
| `rss_mb` | resident memory | leak evidence |

16 columns, ~95 B/min ≈ **140 KB/month**. 30 days of heartbeats is smaller than a screenshot.

### 3. Gap detection (the part that makes weeks readable)

Before writing a heartbeat, compare `Date()` and `systemUptime` against the previous row:

- wall Δ ≫ uptime Δ → `GAP verdict=system_slept` (sleep duration = difference)
- both Δ large, rows missing → `GAP verdict=suspended_or_killed` (App Nap, OOM, crash)
- wall Δ < 0 → `GAP verdict=clock_changed`

A `GAP` event line is emitted for each of these, so a week of noise collapses into
"three gaps, here are their exact boundaries".

### 4. Session sentinel (crash/kill detection)

`SESSION_START` writes `~/Library/Logs/BigDockLocker/session.open`; clean exit removes it.
Next launch logs `SESSION_START prev=unclean since=<ts>` when the sentinel is found.

### 5. `scripts/collect-diagnostics.sh` — paste-ready bundle

Writes `~/Desktop/BigDockLocker-diagnostics-<ts>.txt` containing, in this order:

1. **Anomaly summary first** (the collector computes it, so I don't need raw weeks):
   gaps, `tap=0` runs with their time windows, `nev`-frozen windows, `secure>0` windows,
   `lock=1` windows, `dock_disp != locked_disp` windows, top-10 `cbmax_us` peaks.
2. Environment: app version, macOS version, arch, uptime, sleep/wake history
   (`pmset -g log` filtered), `pmset -g assertions`.
3. All `events-*.log` lines (≤ 14 days).
4. Heartbeats: last **72 h verbatim**, older **downsampled to 1 row/hour** (weeks fit).
5. `log show --last 7d` warnings/errors for the subsystem, capped at 500 lines.
6. Redaction: `$HOME` → `~`, hostname and username removed.

Exit code 0; never writes to the app's own logs.

## Why not just "log everything"

Verbose logging in the event-tap callback is itself a cause of H1/H3 (slow callback →
macOS disables the tap). The hot path stays allocation-free; only counters are touched.
Aggregation happens once a minute on the heartbeat.

## Implementation slices — DONE (uncommitted)

1. `DockLog` v2 — `events-YYYY-MM-DD.log`, `heartbeat-YYYY-MM.log`, session id,
   sentinel, 30-day age-based pruning (`FlightRecorder.swift` holds the pure parts).
2. Engine — `cbmax_us` via `DispatchTime`, gap detection, `SLEEP`/`WAKE`/`LOCK`/
   `UNLOCK`/`SESSION_*` notifications, Dock watchdog, `TAP_*` events, per-minute
   `DOCK_PROBE` so a broken watchdog cannot lie.
3. `scripts/collect-diagnostics.sh` (paste-ready bundle) + `scripts/health-check.sh`
   rewritten for the new files.
4. Ship, let it run until it fails again, then paste the bundle.

### Two findings from the end-to-end smoke test (real app, real Dock)

- **The Dock exposes no `AXWindows`**: `windows=0, ax_error=0`. Its tile strip is an
  `AXList` **child** (`children=1 roles=AXList`). A probe written against
  `kAXWindowsAttribute` fails *silently with success status* — the exact class of
  bug this plan exists to kill. The probe now logs `DOCK_PROBE_FAILED` with
  `children`/`ax_error`/`roles` so it can never look healthy while blind.
- **Crash sentinel works**: killing the app (`pkill`) produced
  `SESSION_START ... prev_session=b1aaab prev_started=... prev=unclean` on the next
  launch.

## Queued fix (blocked on evidence)

If the log shows `tap=0` persisting after `TAP_REENABLE ok=0`, the remediation is to
tear down and **re-create** the tap (re-enable on the same `CFMachPort` cannot always
succeed), and to hold `ProcessInfo.beginActivity` to stop App Nap throttling the
callback. Both are one-liners; both should be chosen by data, not by guess.

## Verify

- `swift build && swift test && swiftlint --strict` green.
- Unit tests: gap classifier (3 cases), heartbeat line shape (15 fields), retention pruner.
- Manual: `sleep 60` gap → `GAP verdict=system_slept`; `kill -9` → `prev=unclean`.
- Collector on a synthetic 30-day heartbeat dir → output < 300 KB, summary lists the injected anomalies.
