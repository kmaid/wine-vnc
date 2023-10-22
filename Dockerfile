FROM alpine:latest

ARG DISPLAY=":0"

RUN apk add x11vnc xvfb xfce4 bash supervisor wget --no-cache

RUN apk add wine --repository=http://dl-cdn.alpinelinux.org/alpine/edge/community/

RUN apk add novnc winetricks wine-mono --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing/

ADD supervisord.conf /etc/supervisord.conf

RUN wget https://www.sync.com/download/legacy/win/sync-installer.exe && \
    wine sync-installer.exe /S && \
    rm sync-installer.exe

EXPOSE 6080

ENTRYPOINT ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
