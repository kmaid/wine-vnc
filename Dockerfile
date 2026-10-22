FROM jlesage/baseimage-gui:debian-12-v4.14.0

# Must stay >= the Wine version that created the existing prefix (11.0).
ARG WINE_VERSION=11.0.0.0~bookworm-1

RUN . /opt/base/bin/cmn-pkg \
    && init_env \
    && dpkg --add-architecture i386 \
    && apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl gnupg procps \
    && mkdir -pm755 /etc/apt/keyrings \
    && curl -fsSL https://dl.winehq.org/wine-builds/winehq.key \
        | gpg --dearmor -o /etc/apt/keyrings/winehq-archive.key \
    && curl -fsSL -o /etc/apt/sources.list.d/winehq-bookworm.sources \
        https://dl.winehq.org/wine-builds/debian/dists/bookworm/winehq-bookworm.sources \
    && apt-get update \
    && apt-get install -y --install-recommends \
        winehq-stable="$WINE_VERSION" \
        wine-stable="$WINE_VERSION" \
        wine-stable-amd64="$WINE_VERSION" \
        wine-stable-i386:i386="$WINE_VERSION" \
        tint2 \
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
RUN chmod +x /startapp.sh /healthcheck.sh /etc/services.d/tint2/run \
    && set-cont-env APP_NAME "Sync.com"

HEALTHCHECK --interval=5m --timeout=30s --start-period=10m --retries=2 CMD /healthcheck.sh
