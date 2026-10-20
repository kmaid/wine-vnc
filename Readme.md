![Github License](https://img.shields.io/github/license/kmaid/sync-wine-container?style=flat-square)
![Maintenance](https://img.shields.io/maintenance/yes/2026?style=flat-square)
![GitHub last commit](https://img.shields.io/github/last-commit/kmaid/sync-wine-container?style=flat-square)

# Sync.com Wine Community Container

This Docker container runs the official [Sync.com](https://www.sync.com) 64-bit desktop client via [WINE](https://www.winehq.org) on Linux, packaged using [jlesage/baseimage-gui](https://github.com/jlesage/docker-baseimage-gui).

It runs the Sync.com client inside a lightweight graphical environment with an integrated system tray panel ([tint2](https://gitlab.com/o9000/tint2)), allowing you to interact with the Sync desktop interface directly from any web browser or VNC client.

⚠️ *This project is a community effort and is not officially affiliated with Sync.com Inc.* ⚠️

---

## Table of Contents

- [Project Status](#project-status)
- [Architecture & Components](#architecture--components)
  - [Content](#content)
  - [Platforms](#platforms)
- [Environment Variables](#environment-variables)
- [Ports & Networking](#ports--networking)
- [Volumes & Storage](#volumes--storage)
- [Accessing the GUI](#accessing-the-gui)
- [Security & Authentication](#security--authentication)
- [Installation Guide](#installation-guide)
  - [Docker Compose](#docker-compose)
  - [Portainer Stack](#portainer-stack)
- [Health Monitoring & Autoheal](#health-monitoring--autoheal)
- [Troubleshooting](#troubleshooting)
  - [WebUtil.registerWebApp is not a function](#webutilregisterwebapp-is-not-a-function)
  - [White Square on Black Screen (System Tray)](#white-square-on-black-screen-system-tray)
  - [File Descriptor Exhaustion (ulimits)](#file-descriptor-exhaustion-ulimits)
- [Credits](#credits)

---

## Project Status

This container is actively maintained and designed for continuous 24/7 background operation on Linux servers, NAS appliances, and unRAID hosts (for example, keeping a local replica for Immich, Jellyfin, or local backup).

---

## Architecture & Components

### Content

The image is based on Debian 12 (Bookworm) via `jlesage/baseimage-gui` and bundles:
- **[jlesage/baseimage-gui]**: Minimalist container base image providing an automated web desktop stack.
- **[WINE]** (WineHQ Stable 11.0.x): 64-bit Windows compatibility layer with `i386` multi-arch support.
- **[Openbox]**: Fast, ultra-lightweight X11 window manager.
- **[tint2]**: Lightweight taskbar providing a FreeDesktop-compliant system tray (`_NET_SYSTEM_TRAY_S0`) for Wine notification icons.
- **[TigerVNC / Xvnc]**: High-performance X virtual framebuffer and RFB server.
- **[noVNC]**: HTML5 canvas VNC client for clientless browser access.
- **[NGINX]**: Embedded web server serving the noVNC frontend and handling WebSocket proxying.
- **Process Supervisor**: Automatic monitoring and restarts via `KEEP_APP_RUNNING=1` with orphan process cleanup (`wineserver -k`).

[jlesage/baseimage-gui]: https://github.com/jlesage/docker-baseimage-gui
[WINE]: https://www.winehq.org/
[Openbox]: http://openbox.org
[tint2]: https://gitlab.com/o9000/tint2
[TigerVNC / Xvnc]: https://tigervnc.org/
[noVNC]: https://github.com/novnc/noVNC
[NGINX]: https://www.nginx.com/

### Platforms

| Platform | Support |
| --- | --- |
| `linux/amd64` | **Fully supported** (requires x86_64 host for Wine / Sync.com 64-bit) |
| `linux/arm64` | Not supported (Sync.com does not build ARM Windows binaries) |

---

## Environment Variables

| Variable | Description | Default |
| --- | --- | --- |
| `USER_ID` | UID for the application process (set to `0` to match root prefix) | `0` |
| `GROUP_ID` | GID for the application process (set to `0` to match root prefix) | `0` |
| `TZ` | Timezone for the container system clock | `UTC` |
| `VNC_PASSWORD` | Password required to access the web/VNC interface (max 8 characters) | *(empty)* |
| `WEB_AUTHENTICATION` | Enable basic HTTP authentication in front of the web UI (`1` to enable) | `0` |
| `WEB_AUTHENTICATION_USERNAME` | Username for basic HTTP auth | *(empty)* |
| `WEB_AUTHENTICATION_PASSWORD` | Password for basic HTTP auth | *(empty)* |
| `WEB_AUTHENTICATION_ALLOW_INSECURE` | Allow basic auth over plain HTTP (when TLS is terminated by a reverse proxy) | `1` |

---

## Ports & Networking

| Port | Protocol | Description |
| --- | --- | --- |
| `5800` | HTTP / WebSocket | Main web interface (noVNC client) |
| `5900` | TCP (RFB) | Standard VNC port (optional, for standalone VNC clients) |

---

## Volumes & Storage

| Host Mount | Container Path | Description |
| --- | --- | --- |
| Named Volume `synccom_synccom_data` | `/config/wine` | WINE prefix containing Wine registry, login credentials, and the SQLite `state.db`. |
| `${DATA_ROOT}/Sync` | `/config/wine/drive_c/users/root/Sync` | Host storage directory holding all synchronized cloud files. |

> [!IMPORTANT]
> The named volume `synccom_synccom_data` is explicitly pinned in `docker-compose.yml`. Changing stack or folder names will not cause Docker Compose to allocate a blank volume, preserving your login session and local index.

---

## Accessing the GUI

1. Open your browser and navigate to:
   - Direct: `http://<server-ip>:5800`
   - Via Reverse Proxy: `https://sync.<your-domain>/`
2. Enter your `VNC_PASSWORD` when prompted by the viewer.
3. The Sync desktop will load. The **tint2 taskbar** at the bottom of the screen displays the Sync status icon in the notification area. Clicking or right-clicking the tray icon opens the Sync preferences and status dialogs.

---

## Security & Authentication

- **Viewer Protection**: Set `VNC_PASSWORD` to prevent unauthorized desktop interaction.
- **Web UI Auth**: If exposing the container without an upstream proxy, set `WEB_AUTHENTICATION=1` with `WEB_AUTHENTICATION_USERNAME` and `WEB_AUTHENTICATION_PASSWORD`.
- **Reverse Proxy**: When running behind Traefik, Caddy, or Nginx Proxy Manager, route traffic to port `5800` with WebSocket support enabled.

---

## Installation Guide

### Docker Compose

Create a `docker-compose.yml`:

```yaml
services:
  sync:
    build: .
    pull_policy: build
    container_name: sync
    restart: unless-stopped
    stop_grace_period: 30s
    ulimits:
      nofile:
        soft: 524288
        hard: 524288
    environment:
      - USER_ID=0
      - GROUP_ID=0
      - TZ=${TZ:-UTC}
      - VNC_PASSWORD=${VNC_PASSWORD}
      - WEB_AUTHENTICATION=${WEB_AUTHENTICATION:-0}
      - WEB_AUTHENTICATION_ALLOW_INSECURE=1
      - WEB_AUTHENTICATION_USERNAME=${WEB_AUTHENTICATION_USERNAME}
      - WEB_AUTHENTICATION_PASSWORD=${WEB_AUTHENTICATION_PASSWORD}
    volumes:
      - synccom_data:/config/wine
      - ${DATA_ROOT}/Sync:/config/wine/drive_c/users/root/Sync
    ports:
      - "5800:5800"
    labels:
      - com.centurylinklabs.watchtower.enable=false
      - autoheal.stop.timeout=30

volumes:
  synccom_data:
    name: synccom_synccom_data
```

Start the container:

```bash
docker compose up -d
```

---

## Health Monitoring & Autoheal

The image includes a built-in Docker `HEALTHCHECK` configured as:

```dockerfile
HEALTHCHECK --interval=5m --timeout=30s --start-period=10m --retries=2 CMD /healthcheck.sh
```

The script monitors three failure vectors:
1. Process vitality: confirms `sync-taskbar.exe` and `sync-worker.exe` are running.
2. File exhaustion: verifies no `Too many open files` errors are logged in `sync-worker.log`.
3. Database locking: detects `unable to open database file` exceptions in SQLite.

When paired with a container like `willfarrell/autoheal`, unhealthy containers are automatically restarted before silent synchronization lockups can persist.

---

## Troubleshooting

### WebUtil.registerWebApp is not a function
- **Cause**: Browser cache holding an older version of `webutil.js` from an earlier noVNC deployment.
- **Fix**: Perform a hard refresh (**`Cmd + Shift + R`** on Mac or **`Ctrl + F5`** on Windows/Linux) or test in an Incognito window.

### White Square on Black Screen (System Tray)
- **Cause**: Wine applications minimizing to the system tray will display an orphaned floating window if no FreeDesktop system tray manager is present.
- **Fix**: The container includes `tint2` to manage the tray. If the bar is missing, ensure `startapp.sh` launches `tint2 &`.

### File Descriptor Exhaustion (ulimits)
- **Cause**: Wine and Sync.com hold open thousands of file handles for large folders. Default Docker limits (1024) will crash the client.
- **Fix**: Ensure `ulimits.nofile` is set to `524288` (or higher) in your Docker Compose or run command.

---

## Credits

- Based on the excellent base image architecture created by [@jlesage](https://github.com/jlesage/docker-baseimage-gui).
- Inspired by community Wine containers such as [@JonathanTreffler's backblaze-personal-wine-container](https://github.com/JonathanTreffler/backblaze-personal-wine-container).
- Sync.com name, logos, and Windows installer are property of Sync.com Inc.
