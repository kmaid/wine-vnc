#!/bin/sh

SYNC_DIR="$WINEPREFIX/drive_c/Program Files (x86)/Sync"
WORKER_LOG="$WINEPREFIX/drive_c/users/root/AppData/Local/Sync.Logs/sync-worker.log"

# Not installed yet: the installer is waiting for someone in the web UI.
[ -f "$SYNC_DIR/sync-taskbar.exe" ] || exit 0

for exe in sync-taskbar sync-worker; do
    if ! pgrep -f "$exe\.exe" > /dev/null; then
        echo "$exe.exe is not running"
        exit 1
    fi
done

if [ -f "$WORKER_LOG" ]; then
    start=$(cat /tmp/sync-worker.log.start 2>/dev/null || echo 0)
    # A smaller file means the log was rotated since startup.
    [ "$(wc -l < "$WORKER_LOG")" -ge "$start" ] || start=0
    if tail -n +"$((start + 1))" "$WORKER_LOG" | tail -n 200 \
        | grep -qE 'Too many open files|unable to open database file'; then
        echo "sync-worker.log reports file descriptor or database errors"
        exit 1
    fi
fi

echo "ok"
