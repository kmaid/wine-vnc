FROM alpine:latest

ARG DISPLAY=":0"

RUN apk add x11vnc xvfb xfce4 bash supervisor wget --no-cache

RUN apk add wine --repository=http://dl-cdn.alpinelinux.org/alpine/edge/community/

RUN apk add novnc winetricks wine-mono --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing/

ADD supervisord.conf /etc/supervisord.conf
ADD start.sh /start.sh
RUN chmod +x /start.sh

RUN echo "0 3 * * * /usr/bin/supervisorctl restart syncom" >> /etc/crontabs/root

RUN wget https://www10.sync.com/download/ult/win/sync-installer-2.2.53.exe

EXPOSE 6080

ENTRYPOINT ["/start.sh"]
