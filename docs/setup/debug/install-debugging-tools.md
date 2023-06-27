---
title: Debugging tools on Flatcar Container Linux
linktitle: Debugging tools
description: How to use the Flatcar "toolbox" to debug problems.
weight: 10
aliases:
    - ../../os/install-debugging-tools
    - ../../clusters/debug/install-debugging-tools
---

You can use common debugging tools like tcpdump or strace with Toolbox. Using the filesystem of a specified Docker container Toolbox will launch a container with full system privileges including access to system PIDs, network interfaces and other global information. Inside of the toolbox, the machine's filesystem is mounted to `/media/root`.

## Quick debugging

By default, Toolbox uses the stock Fedora Docker container. To start using it, simply run:

```shell
/usr/bin/toolbox
```

_NOTE_: For Fedora, it's recommended to use at least 2048 MB RAM to avoid the following `dnf` operation being killed by the OOM manager.

You're now in the namespace of Fedora and can install any software you'd like via `dnf`. For example, if you'd like to use `tcpdump`:

```shell
[root@srv-3qy0p ~]# dnf -y install tcpdump
[root@srv-3qy0p ~]# tcpdump -i ens3
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on ens3, link-type EN10MB (Ethernet), capture size 65535 bytes
```

### Specify a custom Docker image

Create a `.toolboxrc` in the user's home folder to use a specific Docker image:

```shell
$ cat .toolboxrc
TOOLBOX_DOCKER_IMAGE=index.example.com/debug
TOOLBOX_USER=root
$ /usr/bin/toolbox
Pulling repository index.example.com/debug
...
```

You can also specify this in a Butane Config:

```yaml
variant: flatcar
version: 1.0.0
storage:
  files:
    - path: /home/core/.toolboxrc
      mode: 0644
      contents:
        inline: |
          TOOLBOX_DOCKER_IMAGE=index.example.com/debug
          TOOLBOX_DOCKER_TAG=v1
          TOOLBOX_USER=root
```

## Under the hood

Behind the scenes, `toolbox` downloads, prepares and exports the container
image you specify (or the default `fedora` image), then creates a container
from that extracted image by calling `systemd-nspawn`.  The exported
image is retained in
`/var/lib/toolbox/[username]-[image name]-[image tag]`, e.g. the default
image run by the `core` user is at `/var/lib/toolbox/core-fedora-latest`.  

This means two important things:

* Changes made inside the container will persist between sessions
* The container filesystem will take up space on disk (a few hundred MiB
for the default `fedora` container)

## Spawn a toolbox with tmux in the background

Since `toolbox` can only be started once it is not straightforward to use `tmux`
for long-running jobs or sharing a debugging session with someone else.

To keep user processes running in the background after logging out with SSH,
you need to start them via `systemd-run` because _process lingering_ is disabled
by default in logind and all non-service user processes are killed on logout.
Spawn a user service to persist the toolbox container with the `tmux` process
even when you log out with SSH.
The following command line will ensure `tmux`, `strace` and `pidof` are installed
in the container, then create a new `tmux` session to which you can later attach,
and keep the service active by waiting with `strace` until the `tmux` process exits.

```shell
systemd-run --user toolbox sh -c 'dnf install -y tmux strace procps-ng; TERM=tmux tmux new-session -d -s sharedsession; strace -p "$(pidof tmux)"'
```

With `-d` we tell `tmux` to not allocate a TTY now (needed for `systemd-run`) but run a
new session in the background.
Because `tmux` forks away, we cannot use `wait` in the shell to wait for children but need
to use `strace` to have a foreground process running that prevents `toolbox` from quitting.

Once this is running you can can attach to the `tmux` session as often as you want from any SSH connection.

```shell
sudo nsenter -t "$(pidof tmux | cut -d ' ' -f 1)" -a tmux a
```

As usual with `tmux` you can attach and detach to the session as many times as you want because detaching
still keeps `tmux` running in the background. But keep in mind that if you exit the session, the process
started with `systemd-run` will terminate and you'll have to start the service again with `systemd-run`.

## SSH directly into a toolbox

Advanced users can SSH directly into a toolbox by setting up an `/etc/passwd` entry:

```shell
useradd bob -m -p '*' -s /usr/bin/toolbox -U -G sudo,docker,rkt
```

To test, SSH as bob:

```shell
ssh bob@hostname.example.com
Flatcar Container Linux by Kinvolk alpha (2671.0.0)
Downloading sha256:ee7e8933710 [=============================] 63.4 MB / 63.4 MB
Spawning container bob-fedora-latest on /var/lib/toolbox/bob-fedora-latest.
Press ^] three times within 1s to kill container.
[root@srv-3qy0p ~]# dnf -y install emacs-nox
[root@srv-3qy0p ~]# emacs /media/root/etc/systemd/system/newapp.service
```
