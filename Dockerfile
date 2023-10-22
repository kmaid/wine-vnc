FROM alpine:latest

ARG DISPLAY=":0"

RUN apk add x11vnc xvfb xfce4 bash supervisor --no-cache

RUN apk add wine --repository=http://dl-cdn.alpinelinux.org/alpine/edge/community/

RUN apk add novnc winetricks --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing/

ADD supervisord.conf /etc/supervisord.conf

EXPOSE 6080

ENTRYPOINT ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
