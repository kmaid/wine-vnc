#!/bin/sh
set -u

# Wine names the profile directory after $USER; the existing prefix uses "root".
export USER=root

SYNC_DIR="$WINEPREFIX/drive_c/Program Files (x86)/Sync"
WORKER_LOG="$WINEPREFIX/drive_c/users/root/AppData/Local/Sync.Logs/sync-worker.log"
FD_RESTART_PERCENT="${FD_RESTART_PERCENT:-50}"

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

# Wine's taskbar is light, and without this Sync draws a white tray icon on it.
wine reg add 'HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' \
    /v SystemUsesLightTheme /t REG_DWORD /d 1 /f > /dev/null 2>&1

# The healthcheck only inspects worker log lines written after this point.
if [ -f "$WORKER_LOG" ]; then
    wc -l < "$WORKER_LOG" > /tmp/sync-worker.log.start
else
    echo 0 > /tmp/sync-worker.log.start
fi

# Run inside a Wine virtual desktop with Wine's own taskbar. Tray icons docked into an
# X11 tray never receive mouse clicks under Wine, so Sync's menu is only usable here.
wine explorer /desktop=shell,1920x1080 'C:\Program Files (x86)\Sync\sync-taskbar.exe' &
sleep 30

# wineserver never closes a file descriptor while another handle holds a lock on the
# same file, and Sync reopens its locked worker.lock and state.db constantly, so the
# count only grows. Restart well before it reaches the open-file limit.
while pgrep -f 'sync-taskbar\.exe' > /dev/null; do
    server=$(pgrep -x wineserver)
    if [ -n "$server" ]; then
        fds=$(ls "/proc/$server/fd" | wc -l)
        limit=$(awk '/Max open files/ { print $4 }' "/proc/$server/limits")
        if [ "$fds" -ge $((limit * FD_RESTART_PERCENT / 100)) ]; then
            echo "wineserver holds $fds of $limit file descriptors, restarting Sync"
            wineserver -k
            exit 0
        fi
    fi
    sleep 60
done

echo "sync-taskbar.exe exited, restarting"
