#!/bin/bash
# Big DockLocker health check.
#
# Read-only and idempotent: it never writes or changes anything. Exit 0 = healthy,
# 1 = something needs attention.
#
# For a paste-ready bundle, run scripts/collect-diagnostics.sh instead.
# See CLAUDE.md "Observability".

set -uo pipefail

LOG_DIR="$HOME/Library/Logs/BigDockLocker"
SUBSYSTEM="com.danielvm.BigDockLocker"
STATUS=0

HEARTBEAT=$(find "$LOG_DIR" -maxdepth 1 -name 'heartbeat-*.log' 2>/dev/null | LC_ALL=C sort | tail -1)
EVENTS=$(find "$LOG_DIR" -maxdepth 1 -name 'events-*.log' 2>/dev/null | LC_ALL=C sort | tail -1)

count_matches() {
    local count
    count=$(grep -c -- "$1" "$2" 2>/dev/null)
    printf '%s' "${count:-0}"
}

echo "== Big DockLocker health check =="

# 1. Is the app running?
if pgrep -x BigDockLocker >/dev/null 2>&1; then
    echo "process:        running (pid $(pgrep -x BigDockLocker | tr '\n' ' '))"
else
    echo "process:        NOT running"
    STATUS=1
fi

# 2. Did the last session end cleanly?
if [ -f "$LOG_DIR/session.open" ]; then
    echo "last session:   UNCLEAN — $(cat "$LOG_DIR/session.open") (crash or kill)"
    STATUS=1
else
    echo "last session:   clean, or none recorded"
fi

if [ -z "${HEARTBEAT:-}" ]; then
    echo "heartbeat:      no file yet ($LOG_DIR)"
    STATUS=1
else
    echo "heartbeat file: $HEARTBEAT"
    # Columns: 1 ts | 2 up | 3 pid | 4 tap | 5 ax | 6 lock | 7 secure | 8 dsleep
    #          9 nscr | 10 dock | 11 mouse | 12 nev | 13 nb | 14 cbmax | 15 cpu | 16 rss
    grep -v '^#' "$HEARTBEAT" | tail -1 | awk -F'|' '{
        printf "last sample:    %s  tap=%s ax=%s lock=%s secure=%s dock_disp=%s nev=%s cbmax=%sus cpu=%sms rss=%sMB\n",
            $1, $4, $5, $6, $7, $10, $12, $14, $15, $16
        if ($4 == 0) print "   ^^ TAP IS DISABLED: protection is dead right now"
        if ($5 == 0) print "   ^^ ACCESSIBILITY DENIED: macOS is not delivering events"
        if ($7 != 0) print "   ^^ SECURE INPUT ACTIVE (pid " $7 "): session taps receive nothing"
        if ($6 == 1) print "   ^^ SCREEN LOCKED"
    }'

    LAST_ROW=$(grep -v '^#' "$HEARTBEAT" | tail -1)
    CUTOFF=$(date -u -v-1H +"%Y-%m-%dT%H:%M:%S")
    echo "last hour:      $(echo "$LAST_ROW" | awk -F'|' -v c="$CUTOFF" '{
        if (substr($1,1,19) < c) print "no sample in the last hour — the app is not sampling";
        else if ($4 == 0) print "samples arriving, TAP DISABLED (protection off)";
        else print "samples arriving, tap enabled";
    }')"
fi

# 3. Did the Dock ever land on the wrong display?
if [ -n "${EVENTS:-}" ]; then
    echo "wrong display:  $(count_matches 'DOCK_WRONG_DISPLAY' "$EVENTS") events in $(basename "$EVENTS")"
    echo "gaps:           $(count_matches ' GAP ' "$EVENTS") events in $(basename "$EVENTS")"
    echo ""
    echo "last events:"
    grep -v MSG "$EVENTS" 2>/dev/null | tail -5 | sed 's/^/                /'
fi

echo ""
echo "live tail:   tail -f $LOG_DIR/events-$(date +%Y-%m-%d).log"
echo "bundle:      ./scripts/collect-diagnostics.sh"
echo "unified log: log stream --predicate 'subsystem == \"$SUBSYSTEM\"' --info"

if [ "$STATUS" -eq 0 ]; then
    echo "result: HEALTHY"
else
    echo "result: NEEDS ATTENTION"
fi

exit "$STATUS"
