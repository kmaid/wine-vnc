# Sync.com in Wine

Runs the official [Sync.com](https://www.sync.com) Windows client under [Wine](https://www.winehq.org) so a Linux server keeps a local copy of a Sync folder, for example as an Immich external library.

It is built on [jlesage/baseimage-gui](https://github.com/jlesage/docker-baseimage-gui) (Debian 13) with a pinned WineHQ development release and bundled Wine Mono, and only runs on x86_64 hosts. The desktop is served over the web on port 5800 and over VNC on 5900.

Not affiliated with Sync.com Inc.

## First run

Open the web UI and enter `VNC_PASSWORD`. If Sync isn't installed in the Wine prefix yet, the installer starts automatically. Click through it and log in. On later starts the client launches by itself.

Sync runs inside a Wine virtual desktop that fills the browser window. Wine's taskbar runs along the bottom, and the Sync icon is in its notification area on the right: click it for the status panel, whose gear button leads to the settings. `startapp.sh` sets Windows' `SystemUsesLightTheme` so Sync draws a dark icon that shows up on Wine's light taskbar. Tray icons docked into an X11 tray such as tint2 never receive mouse clicks under Wine, which is why the image uses Wine's own taskbar instead.

## Configuration

| Variable | Description |
| --- | --- |
| `DOMAIN_NAME` | Traefik routes `sync.${DOMAIN_NAME}` to the web UI. |
| `DATA_ROOT` | `${DATA_ROOT}/Sync` on the host holds the synced files. |
| `TZ` | Container timezone. |
| `VNC_PASSWORD` | Password for the web and VNC viewer (max 8 characters). |
| `WEB_AUTHENTICATION` | Set to `1` to put the baseimage's login page in front of the web UI, using `WEB_AUTHENTICATION_USERNAME` and `WEB_AUTHENTICATION_PASSWORD`. |
| `FD_RESTART_PERCENT` | Restart Sync once wineserver holds this percentage of its open-file limit. Default `50`. |

`USER_ID` and `GROUP_ID` are `0` because the existing Wine prefix and synced files are owned by root, and Wine names the profile directory (`drive_c/users/root`) after the user.

## Storage

| Mount | Container path | Contents |
| --- | --- | --- |
| Volume `synccom_synccom_data` | `/config/wine` | Wine prefix: the Sync login and its `state.db` index. |
| `${DATA_ROOT}/Sync` | `/config/wine/drive_c/users/root/Sync` | The synced files. |

The volume name is pinned in `docker-compose.yml`, so renaming the stack doesn't create a blank prefix.

## Reliability

- **File descriptor leak.** wineserver can't close a file descriptor while another handle holds a lock on the same file, and Sync reopens its locked `worker.lock` and `state.db` several times a second. wineserver gains about 30,000 descriptors an hour and would hit the 524288 limit after about 16 hours, at which point Sync fails with `Too many open files`. `startapp.sh` checks the count every minute and restarts Sync at `FD_RESTART_PERCENT` of the limit, roughly every 8 hours.
- **Restarts.** `KEEP_APP_RUNNING=1` restarts `startapp.sh` whenever it exits, and each start kills leftover Wine processes first.
- **Healthcheck.** `healthcheck.sh` runs every 5 minutes and fails if any of these is true:
  - `sync-taskbar.exe` or the `sync-worker.exe` worker isn't running.
  - wineserver holds 90% of its open-file limit.
  - `sync-worker.log` hasn't been written to for 30 minutes. A healthy worker logs a server poll every 5 minutes.
  - The worker logged `Too many open files` or `unable to open database file` since the last start.

  With `autoheal` on the host, an unhealthy container is restarted.
- **Watchtower** is disabled for this container because the image is built locally.

## Deployment

Pushes to `main` run `.github/workflows/on-main.yml`. It validates the compose file, builds the image, and redeploys Portainer stack 25. The repository needs a `PORTAINER_ACCESS` secret holding a Portainer access token.

## Troubleshooting

- **Black screen with no tray icon**: Sync is still starting, or it's restarting after a descriptor-limit restart. Check `docker logs sync`.
- **`WebUtil.registerWebApp is not a function`**: the browser has cached noVNC from the old image. Hard-refresh the page.
