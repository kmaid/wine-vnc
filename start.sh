#!/bin/sh
set -e

if [ -z "$VNC_PASSWORD" ]; then
    echo "ERROR: VNC_PASSWORD environment variable must be set"
    exit 1
fi

x11vnc -storepasswd "$VNC_PASSWORD" /tmp/x11vnc.passwd

exec /usr/bin/supervisord -c /etc/supervisord.conf
