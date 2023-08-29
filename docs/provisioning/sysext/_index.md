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
While systemd-sysext images are not really good yet at including systemd units, Flatcar ships `ensure-sysext.service` as workaround to automatically load the image's services.
Systemd-sysext is supported in Flatcar versions ≥ 3185.0.0 for user provided sysext images.

## Torcx deprecation

Since systemd-sysext is a more generic and maintained solution than Torcx, it will replace Torcx and Torcx is scheduled for removal from Flatcar at some point in the future (no date or major release version yet).
Starting from Flatcar version 3185.0.0 we encourage you to migrate any Torcx usage and convert your Torcx image with the `convert_torcx_image.sh` helper script from the [`sysext-bakery`][sysext-bakery] repository, mentioned later in this document.

## The sysext format

Sysext images can be disk image files or simple folders (details in [`man systemd-sysext`](https://www.freedesktop.org/software/systemd/man/systemd-sysext.html)).
They get loaded by `systemd-sysext.service` which looks for them in `/etc/extensions/` or `/var/lib/extensions` among others.
An image must be named `NAME.raw` while a plain folder just uses `NAME` as name.
The image can be a plain ext4 or btrfs filesystem image but squashfs images are a useful format to consider because besides the compression it offers, the `mksquashfs` tool simply takes a directory as input and doesn't need loop devices and mounting of an image file.

Inside the image or folder structure there must be a file `usr/lib/extension-release.d/extension-release.NAME` with metadata used for version matching.
The basic matching that needs to be there is `ID=flatcar` plus one of `VERSION_ID` or `SYSEXT_LEVEL`.
If your binaries link against Flatcar's binaries under `/usr`, you must couple your sysext image to the Flatcar version by specyfing `VERSION_ID=MAJOR.MINOR.PATCH` in `extension-release.NAME` to match the `VERSION_ID` field from `/etc/os-release`.
This means that the sysext image won't be loaded anymore after an OS update.
Therefore, it is recommended that you try to use static binaries which lifts the requirement of having to couple the versions.
In this case you can specify `SYSEXT_LEVEL=1.0` instead of `VERSION_ID`.
The matching semantics for `SYSEXT_LEVEL` are limited at the moment and the use case for bumping the version are not there yet.
In summary, this is what you will normally write to the metadata file:

```
ID=flatcar
SYSEXT_LEVEL=1.0
```

Then place your binaries under `usr/bin/` and your systemd units under `usr/lib/systemd/system/`.
While Flatcar currently allows you to enable systemd units by including the symlinks it would generate when enabling the units, e.g., `sockets.target.wants/my.socket` → `../my.socket`, this is not recommended.
The recommended way is to ship drop-ins for the target units that start your unit, e.g., `usr/lib/systemd/system/sockets.target.d/10-docker-socket.conf` with the following content (similar for `multi-user.target` and a `.service` unit):

```ini
[Unit]
Upholds=docker.socket
```

## Supplying your sysext image from Ignition

The following Butane Config YAML can be be transpiled to Ignition JSON and will download a custom Docker+containerd sysext image on first boot.
It also takes care of disabling Torcx and future built-in Docker and containerd sysext images we plan to ship in Flatcar (to revert this, you can find the original target of the symlinks in `/usr/share/flatcar/etc/extensions/` - as said, this is not yet shipped).

```yaml
variant: flatcar
version: 1.0.0
storage:
  files:
    - path: /etc/extensions/mydocker.raw
      mode: 0644
      contents:
        source: https://myserver.net/mydocker.raw
    - path: /etc/systemd/system-generators/torcx-generator
  links:
    - path: /etc/extensions/docker-flatcar.raw
      target: /dev/null
      overwrite: true
    - path: /etc/extensions/containerd-flatcar.raw
      target: /dev/null
      overwrite: true
```

After boot you can see it loaded in the output of the `systemd-sysext` command:

```
HIERARCHY EXTENSIONS SINCE
/opt      none       -
/usr      mydocker   Wed 2022-03-23 14:16:37 UTC
```

You can reload the sysext images at runtime by executing `systemctl restart systemd-sysext`.
In Flatcar this also triggers `ensure-sysext.service` to reload the unit files from disk (in the future this may be covered by `systemd-sysext` itself).
As an additional workaround, Flatcar currently also reevaluates `multi-user.target`, `sockets.target`, and `timers.target`, to make sure your enabled systemd units run, but for units started by `Upholds=` drop-ins that wouldn't be needed.
A manual `systemd-sysext refresh` is not recommended.

## Creating custom sysext images

The [`sysext-bakery`][sysext-bakery] repository under the Flatcar GitHub organization serves as a central point for sysext building tools.
Please reach out if your use case isn't covered and work with us to include it there.

### Upstream Docker sysext images

The Docker releases publish static binaries including containerd and the only missing piece are the systemd units.
To ease the process, the [`create_docker_sysext.sh`](https://raw.githubusercontent.com/flatcar/sysext-bakery/main/create_docker_sysext.sh) helper script takes care of downloading the release binaries and adding the systemd unit files, and creates a combined Docker+containerd sysext image:

```
./create_docker_sysext.sh 20.10.13 mydocker
[… writes mydocker.raw into current directory …]
```

## Converting a Torcx image

In case you have an existing Torcx image you can convert it with the [`convert_torcx_image.sh`](https://raw.githubusercontent.com/flatcar/sysext-bakery/main/convert_torcx_image.sh) helper script (Currently only Torcx tar balls are supported and the conversion is done on best effort):

```
./convert_torcx_image.sh TORCXTAR SYSEXTNAME
[… writes SYSEXTNAME.raw into the current directory …]
```

Please make also sure that your don't have a `containerd.service` drop in file under `/etc` that uses Torcx paths.

## Updating custom sysext images

From Flatcar 3510.2.0, it is possible to use the `systemd-sysupdate` tool that covers the task of downloading newer versions of your sysext image at runtime from a location you specify.

Here is an example using Butane:
```yaml
# butane < config.yaml > config.json
# ./flatcar_production_qemu.sh -i ./config.json
variant: flatcar
version: 1.0.0
storage:
  links:
    - path: /etc/extensions/docker.raw
      target: /opt/extensions/docker/docker-24.0.5.raw
      hard: false
    - path: /etc/extensions/docker-flatcar.raw
      target: /dev/null
      overwrite: true
    - path: /etc/extensions/containerd-flatcar.raw
      target: /dev/null
      overwrite: true
  files:
    - path: /opt/extensions/docker/docker-24.0.5.raw
      contents:
        source: https://github.com/flatcar/sysext-bakery/releases/download/20230803/docker-24.0.5.raw
    - path: /etc/systemd/system-generators/torcx-generator
    - path: /etc/sysupdate.d/noop.conf
      contents:
        inline: |
          [Source]
          Type=regular-file
          Path=/
          MatchPattern=invalid@v.raw
          [Target]
          Type=regular-file
          Path=/
    - path: /etc/sysupdate.docker.d/docker.conf
      contents:
        inline: |
          [Transfer]
          Verify=false

          [Source]
          Type=url-file
          Path=https://github.com/flatcar/sysext-bakery/releases/latest/download/
          MatchPattern=docker-@v.raw

          [Target]
          InstancesMax=3
          Type=regular-file
          Path=/opt/extensions/docker
          CurrentSymlink=/etc/extensions/docker.raw
systemd:
  units:
    - name: systemd-sysupdate.timer
      enabled: true
    - name: systemd-sysupdate.service
      dropins:
        - name: docker.conf
          contents: |
            [Service]
            ExecStartPre=/usr/lib/systemd/systemd-sysupdate -C docker update
        - name: sysext.conf
          contents: |
            [Service]
            ExecStartPost=systemctl restart systemd-sysext
```

This configuration will enable the `systemd-sysupdate.timer` unit that will check every 2-6 hours for a new Docker sysext image available from the latest release of [`sysext-bakery`][sysext-bakery].

[sysext-bakery]: https://github.com/flatcar/sysext-bakery
