---
title: Systemd-sysext
description: Extending the base OS with systemd-sysext images
weight: 39
---

Flatcar Container Linux bundles various software components with fixed versions together into one release.
For users that require a particular version of a software component this means that the software needs to be supplied out of band and overwrite the built-in software copy.
In the past Torcx was introduced as a way to switch between Docker versions.
Another approach we recommended was to [store binaries in `/opt/bin`](../container-runtimes/use-a-custom-docker-or-containerd-version/) and prefer them in the `PATH`.

The systemd project announced the portable services feature to address deploying custom services.
However, since it only covered the service itself without making the client binaries available on the user, it didn't really fit the use case fully.
The systemd-sysext feature finally provides a way to extend the base OS with a `/usr` overlay, thereby making custom binaries available to the user.
While systemd-sysext images are not really meant to also include systemd units, Flatcar ships `ensure-sysext.service` as workaround to automatically load the image's services.
Systemd-sysext is supported in Flatcar versions ≥ 3185.0.0 for user provided sysext images.

## Torcx deprecation

Since systemd-sysext is a more generic and maintained solution than Torcx, it will replace Torcx and Torcx is scheduled for removal from Flatcar at some point in the future (no date or major release version yet).
Starting from Flatcar version 3185.0.0 we encourage you to migrate any Torcx usage and convert your Torcx image with the `convert_torcx_image.sh` helper script from the [`sysext-bakery`](https://github.com/flatcar/sysext-bakery) repository, mentioned later in this document.

## The sysext format

Sysext images can be disk image files or simple folders (details in [`man systemd-sysext`](https://www.freedesktop.org/software/systemd/man/systemd-sysext.html)).
They get loaded by `systemd-sysext.service` which looks for them in `/etc/extensions/` or `/var/lib/extensions` among others.
An image must be named `NAME.raw` while a plain folder just uses `NAME` as name.
The image can be a plain ext4 or btrfs filesystem image but squashfs images are a useful format to consider because besides the compression it offers, the `mksquashfs` tool simply takes a directory as input and doesn't need loop devices and mounting of an image file.

Inside the image or folder structure there must be a file `usr/lib/extension-release.d/extension-release.NAME` with metadata used for version matching.
The basic matching that has to be there is `ID=flatcar` plus one of `VERSION` or `SYSEXT_LEVEL`.
If your binaries link against Flatcar's binaries under `/usr`, you must couple your sysext image to the Flatcar version by specyfing `VERSION=MAJOR.MINOR.PATH` to match the `/etc/os-release` version.
This means that the sysext image won't be loaded anymore after an OS update.
Therefore, it is recommended that you try to use static binaries which lifts the requirement of having to couple the versions.
In this case you can specify `SYSEXT_LEVEL=1.0` instead of `VERSION`.
The matching semantics for `SYSEXT_LEVEL` are limited at the moment and the use case for bumping the version are not there yet.
In summary, this is what you will normally write to the metadata file:

```
ID=flatcar
SYSEXT_LEVEL=1.0
```

Then place your binaries under `usr/bin/` and your systemd units under `usr/lib/systemd/system/`.
To enable systemd units you can include the symlinks it would generate when enabling the units, e.g., `sockets.target.wants/my.socket` → `../my.socket`.

## Supplying your sysext image from Ignition

The following Container Linux Config (CLC YAML) can be be transpiled to Ignition JSON and will download a custom Docker+containerd sysext image on first boot.
It also takes care of disabling Torcx and future built-in Docker and containerd sysext images we plan to ship in Flatcar.

```yaml
storage:
  files:
    - path: /etc/extensions/mydocker.raw
      filesystem: root
      mode: 0644
      contents:
        remote:
          url: https://myserver.net/mydocker.raw
    - path: /etc/systemd/system-generators/torcx-generator
  directories:
    - path: /etc/extensions/docker-flatcar
    - path: /etc/extensions/containerd-flatcar
```

After boot you can see it loaded in the output of the `systemd-sysext` command:

```
HIERARCHY EXTENSIONS SINCE
/opt      none       -
/usr      mydocker   Wed 2022-03-23 14:16:37 UTC
```

You can reload the sysext images at runtime by executing `systemctl restart systemd-sysext`.
This triggers `ensure-sysext.service` to reevaluate `multi-user.target`, `sockets.target`, and `timers.target`, making sure your enabled systemd units run.
A manual `systemd-sysext refresh` is not recommended.

## Creating custom sysext images

The [`sysext-bakery`](https://github.com/flatcar/sysext-bakery) repository under the Flatcar GitHub organization serves as a central point for sysext building tools.
Please reach out if your use case isn't covered and work with us to include it there.

### Upstream Docker sysext images

The Docker releases publish static binaries including containerd and the only missing piece are the systemd units.
To ease the process, the [`create_docker_sysext.sh`](https://raw.githubusercontent.com/flatcar-linux/sysext-bakery/main/create_docker_sysext.sh) helper script takes care of downloading the release binaries and adding the systemd unit files, and creates a combined Docker+containerd sysext image:

```
./create_docker_sysext.sh 20.10.13 mydocker
[… writes mydocker.raw into current directory …]
```

## Converting a Torcx image

In case you have an existing Torcx image you can convert it with the [`convert_torcx_image.sh`](https://raw.githubusercontent.com/flatcar-linux/sysext-bakery/main/convert_torcx_image.sh) helper script (Currently only Torcx tar balls are supported and the conversion is done on best effort):

```
./convert_torcx_image.sh TORCXTAR SYSEXTNAME
[… writes SYSEXTNAME.raw into the current directory …]
```

Please make also sure that your don't have a `containerd.service` drop in file under `/etc` that uses Torcx paths.

## Updating custom sysext images

Future systemd versions will provide the `systemd-sysupdate` tool that covers the task of downloading newer versions of your sysext image at runtime from a location you specify.
At the moment you have to download it manually and either reboot or reload the sysext images.
