#!/bin/bash
# Renice CPU-heavy background workers to keep UI responsive:
#  - chromium renderers
#  - KDE thumbnail workers (kioworker .../kio/thumbnail.so)
while true; do
    for pid in $(pgrep -x chromium 2>/dev/null); do
        [ "$(ps -o ni= -p $pid 2>/dev/null | tr -d ' ')" != "10" ] && renice -n 10 -p $pid 2>/dev/null
    done
    for pid in $(pgrep -f "kio/thumbnail" 2>/dev/null); do
        [ "$(ps -o ni= -p $pid 2>/dev/null | tr -d ' ')" != "10" ] && renice -n 10 -p $pid 2>/dev/null
    done
    sleep 5
done
