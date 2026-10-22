#!/bin/sh

SYNC_DIR="$WINEPREFIX/drive_c/Program Files (x86)/Sync"
WORKER_LOG="$WINEPREFIX/drive_c/users/root/AppData/Local/Sync.Logs/sync-worker.log"

# Not installed yet: the installer is waiting for someone in the web UI.
[ -f "$SYNC_DIR/sync-taskbar.exe" ] || exit 0

if ! pgrep -f 'sync-taskbar\.exe' > /dev/null; then
    echo "sync-taskbar.exe is not running"
    exit 1
fi
if ! pgrep -f 'sync-worker\.exe sync-worker\.exe' > /dev/null; then
    echo "sync-worker.exe is not running"
    exit 1
fi

server=$(pgrep -x wineserver)
fds=$(ls "/proc/$server/fd" | wc -l)
limit=$(awk '/Max open files/ { print $4 }' "/proc/$server/limits")
if [ "$fds" -ge $((limit * 90 / 100)) ]; then
    echo "wineserver holds $fds of $limit file descriptors"
    exit 1
fi

if [ -f "$WORKER_LOG" ]; then
    # A healthy worker polls the server and logs it every 5 minutes.
    if [ -n "$(find "$WORKER_LOG" -mmin +30)" ]; then
        echo "sync-worker.log has not been written to for over 30 minutes"
        exit 1
    fi

    start=$(cat /tmp/sync-worker.log.start 2>/dev/null || echo 0)
    # A smaller file means the log was rotated since startup.
    [ "$(wc -l < "$WORKER_LOG")" -ge "$start" ] || start=0
    if tail -n +"$((start + 1))" "$WORKER_LOG" | tail -n 200 \
        | grep -qE 'Too many open files|unable to open database file'; then
        echo "sync-worker.log reports file descriptor or database errors"
        exit 1
    fi
fi

echo "ok (wineserver fds $fds/$limit)"
