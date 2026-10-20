#!/bin/sh
set -u

# Wine names the profile directory after $USER; the existing prefix uses "root".
export USER=root

SYNC_DIR="$WINEPREFIX/drive_c/Program Files (x86)/Sync"
WORKER_LOG="$WINEPREFIX/drive_c/users/root/AppData/Local/Sync.Logs/sync-worker.log"

# Clear out Wine processes left behind by a previous run (e.g. an orphaned sync-worker.exe).
wineserver -k 2>/dev/null
wineserver -w 2>/dev/null

if [ ! -f "$SYNC_DIR/sync-taskbar.exe" ]; then
    echo "Sync is not installed in $WINEPREFIX, running the installer"
    wine /opt/sync-installer.exe
    wineserver -w
    if [ ! -f "$SYNC_DIR/sync-taskbar.exe" ]; then
        echo "Installer finished but sync-taskbar.exe is missing"
        exit 1
    fi
fi

# The healthcheck only inspects worker log lines written after this point.
if [ -f "$WORKER_LOG" ]; then
    wc -l < "$WORKER_LOG" > /tmp/sync-worker.log.start
else
    echo 0 > /tmp/sync-worker.log.start
fi

# Start tint2 panel in the background so Wine has a system tray to dock tray icons into.
if command -v tint2 >/dev/null 2>&1 && ! pgrep -f 'tint2' >/dev/null 2>&1; then
    tint2 &
fi

wine "$SYNC_DIR/sync-taskbar.exe"

# The taskbar may re-launch itself (e.g. after an update), so only exit once it is really gone.
while pgrep -f 'sync-taskbar\.exe' > /dev/null; do
    sleep 30
done

echo "sync-taskbar.exe exited, restarting"
