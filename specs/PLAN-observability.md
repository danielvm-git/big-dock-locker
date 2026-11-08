# PLAN — Observability for "Dock jumps again after a few hours"

> **Superseded for log format by `specs/PLAN-flight-recorder.md`** (v1 kept
> everything in one 2 MB rotating file — too short a history for multi-week failures).

## Problem
Big DockLocker works after launch but, after several hours, the Dock starts
jumping between monitors again. There was no logging, so the cause was invisible.

## Diagnosis
The engine installs a `CGEventTap` (`.cgSessionEventTap`) to catch `mouseMoved`
events and bounce the cursor off the bottom edge of non-locked displays.

macOS **silently disables** an event tap when the tap callback is slow to return
or the system is under load / waking from sleep. It notifies the callback with a
special event type (`kCGEventTapDisabledByTimeout` / `kCGEventTapDisabledByUserInput`).

The previous callback ignored those event types and never re-enabled the tap, so
once macOS disabled it, protection stopped permanently until the app restarted —
exactly the "works, then jumps again after hours" symptom. The per-event callback
also does `NSScreen.screens` + coordinate math on every mouse move, which is the
kind of slow callback that triggers the timeout in the first place.

## Changes (minimum scope: observability + the natural remediation)
1. **`DockLog.swift` (new):** unified logging (`os.Logger`, subsystem
   `com.danielvm.BigDockLocker`) **and** a plain-text file at
   `~/Library/Logs/BigDockLocker/BigDockLocker.log` (2 MB rotation, one backup).
2. **`BigDockLockerEngine.swift`:**
   - Detect `tapDisabledByTimeout` / `tapDisabledByUserInput` in the callback,
     **log the reason** (the smoking gun) and **re-enable the tap**.
   - Heartbeat (every 60s, driven off the ViewModel's existing main-thread timer)
     logging tap-enabled state, event/bounce counts, and screen count — so the log
     pinpoints the moment the tap goes enabled → disabled. Includes a defensive
     self-heal if the tap is ever found dormant.
   - Counters + start/stop logging. **No logging in the per-event hot path.**
3. **`BigDockLockerViewModel.swift`:** log launch, engine start/stop, permission
   changes, locked-display changes, and **display reconfigurations** (sleep/wake /
   arrangement changes — the other common jump trigger).

## How to read the logs
- Live file tail: `tail -f ~/Library/Logs/BigDockLocker/BigDockLocker.log`
- Unified log (last 6h):
  `log show --last 6h --predicate 'subsystem == "com.danielvm.BigDockLocker"' --info`

## Verify
- `swift build` (compile) and `swift test` (coordinate-math tests unchanged).
- Run for a few hours; when the Dock would previously have started jumping, the
  log will now show a `⚠️ Event tap was DISABLED ... Re-enabling` line and the
  Dock keeps working.
