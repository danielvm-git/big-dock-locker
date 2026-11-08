#!/usr/bin/env bash
# Big DockLocker diagnostics collector.
#
# Builds ONE paste-ready text file. The anomaly summary comes first, so a failure
# that took two weeks to appear is readable without shipping two weeks of lines.
#
# Usage:
#   ./scripts/collect-diagnostics.sh [log-dir] [output-file]
#
# Read-only with respect to the app's logs. Safe to run repeatedly.

set -uo pipefail

LOG_DIR="${1:-$HOME/Library/Logs/BigDockLocker}"
OUT="${2:-$HOME/Desktop/BigDockLocker-diagnostics-$(date +%Y%m%d-%H%M%S).txt}"

HEARTBEAT_VERBATIM_HOURS=72
EVENT_LINE_LIMIT=4000
LOG_SHOW_LIMIT=500

if [ ! -d "$LOG_DIR" ]; then
    echo "No log directory at $LOG_DIR — has the app run since the logging build?" >&2
    exit 1
fi

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

mkdir -p "$(dirname "$OUT")"
: > "$OUT"

emit() { printf '%s\n' "$@" >> "$OUT"; }
section() {
    emit ""
    emit "=================================================================="
    emit "== $*"
    emit "=================================================================="
}

heartbeat_files() {
    find "$LOG_DIR" -maxdepth 1 -name 'heartbeat-*.log' | LC_ALL=C sort
}

event_files() {
    find "$LOG_DIR" -maxdepth 1 -name 'events-*.log' | LC_ALL=C sort
}

# --------------------------------------------------------------- awk programs
# Shared helpers: ISO-8601 -> epoch without spawning `date` once per row.
cat > "$WORK/lib.awk" <<'AWK'
function days_from_civil(y, m, d,   era, yoe, doy, doe) {
    if (m <= 2) y--
    era = int((y >= 0 ? y : y - 399) / 400)
    yoe = y - era * 400
    doy = int((153 * (m + (m > 2 ? -3 : 9)) + 2) / 5) + d - 1
    doe = yoe * 365 + int(yoe / 4) - int(yoe / 100) + doy
    return era * 146097 + doe - 719468
}
function epoch(ts,   y, m, d, H, M, S) {
    y = substr(ts, 1, 4) + 0; m = substr(ts, 6, 2) + 0; d = substr(ts, 9, 2) + 0
    H = substr(ts, 12, 2) + 0; M = substr(ts, 15, 2) + 0; S = substr(ts, 18, 2) + 0
    return days_from_civil(y, m, d) * 86400 + H * 3600 + M * 60 + S
}
function isrow(line) {
    return (line !~ /^#/ && line ~ /^[0-9][0-9][0-9][0-9]-/)
}
AWK

# One pass over every heartbeat row: the summary the user pastes.
cat > "$WORK/anomaly.awk" <<'PROG'
isrow($0) {
    split($0, f, "|")
    n++
    if (n == 1) { first = f[1] }
    last = f[1]; lastPid = f[3]
    if (prevPid != "" && f[3] != prevPid) {
        print "  RESTART         " f[1] "  pid " prevPid " -> " f[3]
        restarts++
    }
    if (f[4] == 0) { tapOff++; if (!tapOffFirst) tapOffFirst = f[1]; tapOffLast = f[1] }
    if (f[5] == 0) { axOff++; if (!axOffFirst) axOffFirst = f[1]; axOffLast = f[1] }
    if (f[6] == 1) { locked++; if (!lockedFirst) lockedFirst = f[1]; lockedLast = f[1] }
    if (f[7] + 0 > 0) { secure++; if (!secureFirst) secureFirst = f[1]; secureLast = f[1] }
    if (f[8] == 1) asleep++
    if (f[14] + 0 > cbmax) { cbmax = f[14] + 0; cbmaxAt = f[1] }
    if (prevTs != "") {
        wall = epoch(f[1]) - epoch(prevTs)
        up = f[2] - prevUp
        if (wall < 0) {
            print "  CLOCK CHANGED   " prevTs " -> " f[1] "  wall=" wall "s up=" up "s"
            gaps++
        } else if (wall > 180) {
            kind = (wall - up > 120) ? "system_slept" : "process_not_scheduled"
            print "  GAP             " prevTs " -> " f[1] "  wall=" wall "s up=" up "s  " kind
            gaps++
        }
    }
    if (prevNev != "" && f[4] == 1 && f[12] == prevNev && f[13] == prevNb) {
        if (!frozenFirst) frozenFirst = f[1]
        frozenLast = f[1]; frozenRows++
    }
    if (prevDock != "" && f[10] != prevDock) {
        print "  DOCK MOVED      " f[1] "  display " prevDock " -> " f[10]
        dockMoves++
    }
    if (f[15] + 0 > worstCpu) { worstCpu = f[15] + 0; worstCpuAt = f[1] }
    if (f[16] + 0 > worstRss) { worstRss = f[16] + 0; worstRssAt = f[1] }
    prevTs = f[1]; prevUp = f[2]; prevNev = f[12]; prevNb = f[13]; prevDock = f[10]; prevPid = f[3]
}
END {
    printf "rows:            %d  (%s .. %s)\n", n, first, last
    printf "app restarts:    %d  (pid changes; last pid %s)\n", restarts + 0, lastPid
    printf "tap disabled:    %d rows", tapOff + 0
    if (tapOff) printf "  %s .. %s", tapOffFirst, tapOffLast
    printf "\n"
    printf "accessibility:   %d rows with AX denied", axOff + 0
    if (axOff) printf "  %s .. %s", axOffFirst, axOffLast
    printf "\n"
    printf "screen locked:   %d rows", locked + 0
    if (locked) printf "  %s .. %s", lockedFirst, lockedLast
    printf "\n"
    printf "secure input:    %d rows", secure + 0
    if (secure) printf "  %s .. %s", secureFirst, secureLast
    printf "\n"
    printf "display asleep:  %d rows\n", asleep + 0
    printf "gaps:            %d (listed above)\n", gaps + 0
    printf "events frozen:   %d rows at %s .. %s  (tap on, no events = starved)\n", \
        frozenRows + 0, frozenFirst, frozenLast
    printf "dock moves:      %d (listed above)\n", dockMoves + 0
    printf "worst callback:  %d us at %s  (macOS kills the tap near 1000000 us)\n", cbmax + 0, cbmaxAt
    printf "worst cpu/min:   %d ms at %s\n", worstCpu + 0, worstCpuAt
    printf "peak memory:     %d MB at %s\n", worstRss + 0, worstRssAt
}
PROG

cat > "$WORK/slowest.awk" <<'PROG'
isrow($0) { split($0, f, "|"); print f[14] "\t" f[1] "\t" f[12] }
PROG

cat > "$WORK/tail.awk" <<'PROG'
isrow($0) {
    if (substr($0, 1, 19) >= cutoff) { print $0; recent++ }
    else { if (old % 60 == 0) buffer = buffer $0 "\n"; old++ }
}
END {
    print ""
    print "# --- 1 row/hour before " substr(cutoff, 1, 19) " (" old + 0 " rows compressed) ---"
    printf "%s", buffer
    print "# recent rows: " recent + 0
}
PROG

# ------------------------------------------------------------------- preamble
section "BIG DOCKLOCKER DIAGNOSTICS"
emit "collected:      $(date '+%Y-%m-%d %H:%M:%S %Z')"
emit "log directory:  $LOG_DIR"
emit "app version:    $(defaults read /Applications/BigDockLocker.app/Contents/Info.plist \
                                CFBundleShortVersionString 2>/dev/null || echo 'not installed in /Applications')"
emit "macOS:          $(sw_vers -productVersion) ($(sw_vers -buildVersion))"
emit "hardware:       $(sysctl -n machdep.cpu.brand_string 2>/dev/null || uname -m)"
emit "log header:     $(grep -h '^# hb2' $(heartbeat_files) 2>/dev/null | tail -1 | sed 's/^# //')"
emit "uptime:         $(uptime | sed 's/^ *//')"
if [ -f "$LOG_DIR/session.open" ]; then
    emit "session marker: $(cat "$LOG_DIR/session.open")  <-- previous session never ended cleanly"
else
    emit "session marker: none (last session ended cleanly, or none recorded)"
fi
emit ""
emit "files:"
for file in "$LOG_DIR"/*; do
    [ -f "$file" ] || continue
    emit "  $(basename "$file")  $(wc -c < "$file" | tr -d ' ') bytes  $(wc -l < "$file" | tr -d ' ') lines"
done

# ------------------------------------------------------------ anomaly summary
ALL_HEARTBEATS="$WORK/heartbeats.txt"
: > "$ALL_HEARTBEATS"
for file in $(heartbeat_files); do
    cat "$file" >> "$ALL_HEARTBEATS" 2>/dev/null
done

section "ANOMALY SUMMARY (read this first)"

if [ ! -s "$ALL_HEARTBEATS" ]; then
    emit "no heartbeat rows found — the engine never reached its first sample"
else
    awk -f "$WORK/lib.awk" -f "$WORK/anomaly.awk" "$ALL_HEARTBEATS" >> "$OUT"

    section "SLOWEST TAP CALLBACKS (top 10)"
    awk -f "$WORK/lib.awk" -f "$WORK/slowest.awk" "$ALL_HEARTBEATS" \
        | sort -rn | head -10 \
        | awk -F'\t' '{ printf "  %8s us  %s  (nev=%s)\n", $1, $2, $3 }' >> "$OUT"
fi

# ---------------------------------------------------------------- environment
section "SYSTEM SLEEP / WAKE HISTORY (pmset, last 60 entries)"
pmset -g log 2>/dev/null | grep -E '\b(Sleep|Wake|DarkWake)\b' | tail -60 >> "$OUT"

section "POWER ASSERTIONS"
pmset -g assertions 2>/dev/null | head -30 >> "$OUT"

# --------------------------------------------------------------------- events
section "EVENTS (every recorded incident)"
for file in $(event_files); do
    emit "--- $(basename "$file") ($(wc -l < "$file" | tr -d ' ') lines, tail ${EVENT_LINE_LIMIT})"
    tail -n "$EVENT_LINE_LIMIT" "$file" >> "$OUT"
done

# ---------------------------------------------------------------- heartbeats
section "HEARTBEATS — last ${HEARTBEAT_VERBATIM_HOURS}h verbatim, older 1 row/hour"
CUTOFF=$(date -u -v-"${HEARTBEAT_VERBATIM_HOURS}"H +"%Y-%m-%dT%H:%M:%S")
awk -v cutoff="$CUTOFF" -f "$WORK/lib.awk" -f "$WORK/tail.awk" "$ALL_HEARTBEATS" >> "$OUT"

# --------------------------------------------------------------- unified log
section "UNIFIED LOG — warnings and errors, last 7 days"
log show --last 7d --style compact \
    --predicate 'subsystem == "com.danielvm.BigDockLocker"' 2>/dev/null \
    | grep -Ei 'error|warn|disabled|gap|reenable' | tail -"$LOG_SHOW_LIMIT" >> "$OUT"

# ------------------------------------------------------------------ redaction
sed -e "s|$HOME|~|g" -e "s|$(hostname)|<host>|g" "$OUT" > "$WORK/redacted" && mv "$WORK/redacted" "$OUT"

BYTES=$(wc -c < "$OUT" | tr -d ' ')
LINES=$(wc -l < "$OUT" | tr -d ' ')
section "END"
emit "output:  $OUT"
emit "size:    $BYTES bytes, $LINES lines"
emit "paste this whole file into the chat."

echo "wrote $OUT ($BYTES bytes, $LINES lines)"
