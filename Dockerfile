FROM jlesage/baseimage-gui:debian-13-v4.14.0

# Wine development builds: 11.0 hides the systray whenever Wine's taskbar is shown,
# which is fixed from 11.2. Must stay >= the version that last updated the prefix.
ARG WINE_VERSION=11.20~trixie-1
# The version Wine expects, from MONO_VERSION in dlls/appwiz.cpl/addons.c.
ARG WINE_MONO_VERSION=11.3.0

RUN . /opt/base/bin/cmn-pkg \
    && init_env \
    && dpkg --add-architecture i386 \
    && apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl gnupg procps xz-utils \
    && mkdir -pm755 /etc/apt/keyrings \
    && curl -fsSL https://dl.winehq.org/wine-builds/winehq.key \
        | gpg --dearmor -o /etc/apt/keyrings/winehq-archive.key \
    && curl -fsSL -o /etc/apt/sources.list.d/winehq-trixie.sources \
        https://dl.winehq.org/wine-builds/debian/dists/trixie/winehq-trixie.sources \
    && apt-get update \
    && apt-get install -y --install-recommends \
        winehq-devel="$WINE_VERSION" \
        wine-devel="$WINE_VERSION" \
        wine-devel-amd64="$WINE_VERSION" \
        wine-devel-i386:i386="$WINE_VERSION" \
    && mkdir -p /opt/wine-devel/share/wine/mono \
    && curl -fsSL "https://dl.winehq.org/wine/wine-mono/$WINE_MONO_VERSION/wine-mono-$WINE_MONO_VERSION-x86.tar.xz" \
        | tar -xJ -C /opt/wine-devel/share/wine/mono \
    && apt-get purge -y gnupg \
    && apt-get autoremove -y \
    && cleanup_env \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://www.sync.com/install \
    | grep -oE 'https://www10\.sync\.com/download/ult/win/sync-installer-2\.[0-9.]+\.exe' \
    | head -1 \
    | xargs curl -fsSL -o /opt/sync-installer.exe

ENV WINEPREFIX=/config/wine \
    WINEDEBUG=fixme-all \
    KEEP_APP_RUNNING=1

COPY rootfs/ /
COPY startapp.sh /startapp.sh
COPY healthcheck.sh /healthcheck.sh
RUN chmod +x /startapp.sh /healthcheck.sh \
    && set-cont-env APP_NAME "Sync.com"

HEALTHCHECK --interval=5m --timeout=30s --start-period=10m --retries=2 CMD /healthcheck.sh
