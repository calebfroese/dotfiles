#!/bin/bash
# Monitors tmux window bell flags and updates AnyBar accordingly.
# Polls every 50ms. Sends 'orange' if any bell, 'hollow' if none.

ANYBAR_PORT=1738
POLL_INTERVAL=0.05
PIDFILE="/tmp/anybar-bell-monitor.pid"

# Kill any existing instance (silently)
if [[ -f "$PIDFILE" ]]; then
    oldpid=$(cat "$PIDFILE" 2>/dev/null)
    if [[ -n "$oldpid" && "$oldpid" != "$$" ]] && kill -0 "$oldpid" 2>/dev/null; then
        kill "$oldpid" 2>/dev/null
        wait "$oldpid" 2>/dev/null
    fi
fi

echo $$ > "$PIDFILE"
trap 'rm -f "$PIDFILE"' EXIT

last_state=""

while true; do
    if tmux list-windows -F '#{window_bell_flag}' 2>/dev/null | grep -q 1; then
        state="orange"
    else
        state="hollow"
    fi

    if [[ "$state" != "$last_state" ]]; then
        printf '%s' "$state" | nc -4u -w0 localhost "$ANYBAR_PORT"
        last_state="$state"
    fi

    sleep "$POLL_INTERVAL"
done
