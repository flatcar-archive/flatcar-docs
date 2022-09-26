---
title: Installing Flatcar Container Linux to disk
linktitle: Using flatcar-install script
description: >
  How to use the flatcar-install script to install Flatcar from
  a running system.
weight: 10
aliases:
    - ../../os/installing-to-disk
    - ../../bare-metal/installing-to-disk
---
## Required Dependencies
If you want to use the `flatcar-install` script on some other environment than Flatcar Container Linux, ensure that the following binaries are present:
```
bash
lbzip2 or bzip2 
mount, lsblk  (often found in the util-linux packaage)
wget
grep
cp, dd, mkfifo, mkdir, rm, tee (often found in the GNU coreutils package or as part of busybox)
udevadm (found in systemd-udev package, or for Alpine images in eudev)
gpg, gpg2 (found in gnupg2)
gawk (often found in GNU gawk package) 
```


## Install script

There is a simple installer that will destroy everything on the given target disk and install Flatcar Container Linux. Essentially it downloads an image, verifies it with gpg, and then copies it bit for bit to disk. An installation requires at least 8 GB of usable space on the device.

The script is self-contained and located [on GitHub here][flatcar-install] and can be run from any Linux distribution. You cannot normally install Flatcar Container Linux to the same device that is currently booted. However, the [Flatcar Container Linux ISO][flatcar-iso] or any Linux liveCD will allow Flatcar Container Linux to install to a non-active device.

If you boot Flatcar Container Linux via PXE, the install script is already installed. By default the install script will attempt to install the same version and channel that was PXE-booted:

```shell
flatcar-install -d /dev/sda -i ignition.json
```

`ignition.json` should include user information (especially an SSH key) generated from a [Butane Config][butane-section], or you will not be able to log into your Flatcar Container Linux instance.

If you are installing on VMware, pass `-o vmware_raw` to install the VMware-specific image:

```shell
flatcar-install -d /dev/sda -i ignition.json -o vmware_raw
```

## Choose a channel

Flatcar Container Linux is designed to be [updated automatically][update-strategies] with different schedules per channel. You can [disable this feature][update-strategies], although we don't recommend it. Read the [release notes][release-notes] for specific features and bug fixes.

<div id="install">
  <ul class="nav nav-tabs">
    <li class="active"><a href="#stable-create" data-toggle="tab">Stable Channel</a></li>
    <li><a href="#beta-create" data-toggle="tab">Beta Channel</a></li>
    <li><a href="#alpha-create" data-toggle="tab">Alpha Channel</a></li>
  </ul>
  <div class="tab-content coreos-docs-image-table">
    <div class="tab-pane" id="alpha-create">
      <p>The Alpha channel closely tracks master and is released frequently. The newest versions of system libraries and utilities will be available for testing. The current version is Flatcar Container Linux {{< param alpha_channel >}}.</p>
      <p>If you want to ensure you are installing the latest alpha version, use the <code>-C</code> option:</p>
      <pre>flatcar-install -d /dev/sda -C alpha</pre>
    </div>
    <div class="tab-pane" id="beta-create">
      <p>The Beta channel consists of promoted Alpha releases. The current version is Flatcar Container Linux {{< param beta_channel >}}.</p>
      <p>If you want to ensure you are installing the latest beta version, use the <code>-C</code> option:</p>
      <pre>flatcar-install -d /dev/sda -C beta</pre>
    </div>
    <div class="tab-pane active" id="stable-create">
      <p>The Stable channel should be used by production clusters. Versions of Flatcar Container Linux are battle-tested within the Beta and Alpha channels before being promoted. The current version is Flatcar Container Linux {{< param stable_channel >}}.</p>
      <p>If you want to ensure you are installing the latest stable version, use the <code>-C</code> option:</p>
      <pre>flatcar-install -d /dev/sda -C stable</pre>
    </div>
  </div>
</div>

For reference here are the rest of the `flatcar-install` options:

```shell
-d DEVICE   Install Flatcar Container Linux to the given device.
-s          EXPERIMENTAL: Install Flatcar Container Linux to the smallest unmounted disk found
            (min. size 10GB). It is recommended to use it with -e or -I to filter the
            block devices by their major numbers. E.g., -e 7 to exclude loop devices
            or -I 8,259 for certain disk types. Read more about the numbers here:
            https://www.kernel.org/doc/Documentation/admin-guide/devices.txt.
-V VERSION  Version to install (e.g. current, or current-2022 for the LTS 2022 stream)
-B BOARD    Flatcar Container Linux board to use
-C CHANNEL  Release channel to use (e.g. beta)
-I|e <M,..> EXPERIMENTAL (used with -s): List of major device numbers to in-/exclude
            when finding the smallest disk.
-o OEM      OEM type to install (e.g. ami), using flatcar_production_<OEM>_image.bin.bz2
-c CLOUD    Insert a cloud-init config to be executed on boot.
-i IGNITION Insert an Ignition config to be executed on boot.
-b BASEURL  URL to the image mirror (overrides BOARD and CHANNEL)
-k KEYFILE  Override default GPG key for verifying image signature
-f IMAGE    Install unverified local image file to disk instead of fetching
-n          Copy generated network units to the root partition.
-v          Super verbose, for debugging.
```

## Butane Configs

By default there isn't a password or any other way to log into a fresh Flatcar Container Linux system. The easiest way to configure accounts, add systemd units, and more is via Butane Configs. Jump over to the [docs to learn about the supported features][butane-configs].

After using the [Butane][butane] to produce an Ignition config, the installation script will process your `ignition.json` file specified with the `-i` flag and use it when the installation is booted.

A Butane Config YAML that specifies an SSH key for the `core` user but doesn't use any other parameters looks like:

```yaml
variant: flatcar
version: 1.0.0
passwd:
  users:
    - name: core
      ssh_authorized_keys:
        - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDGdByTgSVHq.......
```

Transpile it to Ignition JSON:

```shell
cat cl.yaml | docker run --rm -i quay.io/coreos/butane:latest > ignition.json
```

To start the installation script with a reference to our Ignition config, run:

```shell
flatcar-install -d /dev/sda -C stable -i ~/ignition.json
```

### Advanced Butane Config example

This Butane YAML example will configure Flatcar Container Linux to run an NGINX Docker container.

```yaml
variant: flatcar
version: 1.0.0
passwd:
  users:
    - name: core
      ssh_authorized_keys:
        - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDGdByTgSVHq.......
systemd:
  units:
    - name: nginx.service
      enabled: true
      contents: |
        [Unit]
        Description=NGINX example
        After=docker.service
        Requires=docker.service
        [Service]
        TimeoutStartSec=0
        ExecStartPre=-/usr/bin/docker rm --force nginx1
        ExecStart=/usr/bin/docker run --name nginx1 --pull always --net host docker.io/nginx:1
        ExecStop=/usr/bin/docker stop nginx1
        Restart=always
        RestartSec=5s
        [Install]
        WantedBy=multi-user.target
```

Transpile it to Ignition JSON:

```shell
cat cl.yaml | docker run --rm -i quay.io/coreos/butane:latest > ignition.json
```

## Using Flatcar Container Linux

Now that you have a machine booted it is time to play around. Check out the [Flatcar Container Linux Quickstart][quickstart] guide or dig into [more specific topics][docs-root].

[quickstart]: ../
[docs-root]: ../../
[update-strategies]: ../../setup/releases/update-strategies
[release-notes]: https://flatcar-linux.org/releases
[flatcar-iso]: booting-with-iso
[butane-section]: #butane-configs
[flatcar-install]: https://raw.githubusercontent.com/flatcar-linux/init/flatcar-master/bin/flatcar-install
[cl-configs]: ../../provisioning/cl-config
[butane-configs]: ../../provisioning/config-transpiler
[butane]: ../../provisioning/config-transpiler
