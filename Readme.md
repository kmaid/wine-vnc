# Docker-Wine

This is a starting point to dockerize a windows GUI application. It uses xfce4, frame buffer (Xvfb), x11vnc and noVNC to provide remote desktop over a webpage to configure the application. It also uses supervisor to start the applications.

It only works on X86 and X86_64 Linux systems as alpine wine does not support other architectures.

## Usage

Extend the Dockerfile to install your application. Add additional scripts to supervisor.d to start your application. eg

```
[program:notepad]
command=wine nodepad.exe
```

You can then configure your application via noVNC exposed on 6080.
