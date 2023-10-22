# Docker-Wine-SyncCom

This is an attempt to get sync.com client to run on linux. It uses xfce4, frame buffer (Xvfb), x11vnc and noVNC to provide remote desktop over a webpage to configure the application. It also uses supervisor to start the applications.

It only works on X86 and X86_64 Linux systems as alpine wine does not support other architectures.

You can then configure your application via noVNC exposed on 6080.
