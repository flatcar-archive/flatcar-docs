---
title: Booting Flatcar Container Linux via PXE
linktitle: Booting via PXE
weight: 10
aliases:
    - ../../os/booting-with-pxe
    - ../../bare-metal/booting-with-pxe
---

These instructions will walk you through booting Flatcar Container Linux via PXE on real or virtual hardware. By default, this will run Flatcar Container Linux completely out of RAM. Flatcar Container Linux can also be [installed to disk][installing-to-disk].

A minimum of 3 GB of RAM is required to boot Flatcar Container Linux via PXE.

## Configuring pxelinux

This guide assumes you already have a working PXE server using [pxelinux][pxelinux]. If you need suggestions on how to set a server up, check out guides for [Debian][debian-pxe], [Fedora][fedora-pxe] or [Ubuntu][ubuntu-pxe].

[debian-pxe]: https://wiki.debian.org/PXEBootInstall
[ubuntu-pxe]: https://help.ubuntu.com/community/DisklessUbuntuHowto
[fedora-pxe]: http://docs.fedoraproject.org/en-US/Fedora/7/html/Installation_Guide/ap-pxe-server.html
[pxelinux]: http://www.syslinux.org/wiki/index.php/PXELINUX

### Setting up pxelinux.cfg

When configuring the Flatcar Container Linux pxelinux.cfg there are a few kernel options that may be useful but all are optional.

- **rootfstype=tmpfs**: Use tmpfs for the writable root filesystem. This is the default behavior.
- **rootfstype=btrfs**: Use btrfs in RAM for the writable root filesystem. The filesystem will consume more RAM as it grows, up to a max of 50%. The limit isn't currently configurable.
- **root**: Use a local filesystem for root instead of one of two in-ram options above. The filesystem must be formatted (perhaps using Ignition) but may be completely blank; it will be initialized on boot. The filesystem may be specified by any of the usual ways including device, label, or UUID; e.g: `root=/dev/sda1`, `root=LABEL=ROOT` or `root=UUID=2c618316-d17a-4688-b43b-aa19d97ea821`.
- **sshkey**: Add the given SSH public key to the `core` user's authorized_keys file. Replace the example key below with your own (it is usually in `~/.ssh/id_rsa.pub`)
- **console**: Enable kernel output and a login prompt on a given tty. The default, `tty0`, generally maps to VGA. Can be used multiple times, e.g. `console=tty0 console=ttyS0`
- **flatcar.autologin**: Drop directly to a shell on a given console without prompting for a password. Useful for troubleshooting but use with caution. For any console that doesn't normally get a login prompt by default be sure to combine with the `console` option, e.g. `console=tty0 console=ttyS0 flatcar.autologin=tty1 flatcar.autologin=ttyS0`. Without any argument it enables access on all consoles. Note that for the VGA console the login prompts are on virtual terminals (`tty1`, `tty2`, etc), not the VGA console itself (`tty0`).
- **flatcar.first_boot=1**: Download an Ignition config and use it to provision your booted system. Ignition configs are generated from Butane Configs. See the [Butane Config documentation][butane-configs] for more information. If a local filesystem is used for the root partition, pass this parameter only on the first boot.
- **ignition.config.url**: Download the Ignition config from the specified URL. `http`, `https`, `s3`, and `tftp` schemes are supported.
- **ip**: Configure temporary static networking for initramfs. This parameter does not influence the final network configuration of the node and is mostly useful for first-boot provisioning of systems in DHCP-less environments. See [Ignition documentation][ignition-kargs-ip] for the complete syntax.

This is an example pxelinux.cfg file that assumes Flatcar Container Linux is the only option. You should be able to copy this verbatim into `/var/lib/tftpboot/pxelinux.cfg/default` after providing an Ignition config URL:

```shell
default flatcar
prompt 1
timeout 15

display boot.msg

label flatcar
  menu default
  kernel flatcar_production_pxe.vmlinuz
  initrd flatcar_production_pxe_image.cpio.gz
  append flatcar.first_boot=1 ignition.config.url=https://example.com/pxe-config.ign
```

Here's a Butane YAML example that starts and NGINX Docker container. It should be transpiled to Ignition JSON and located at the URL from above:

```yaml
variant: flatcar
version: 1.0.0
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
        ExecStart=/usr/bin/docker run --name nginx1 --pull always --log-driver=journald --net host docker.io/nginx:1
        ExecStop=/usr/bin/docker stop nginx1
        Restart=always
        RestartSec=5s
        [Install]
        WantedBy=multi-user.target
passwd:
  users:
    - name: core
      ssh_authorized_keys:
        - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDGdByTgSVHq...
```

Transpile it to Ignition JSON:

```shell
cat cl.yaml | docker run --rm -i quay.io/coreos/butane:latest > ignition.json
```


### Choose a channel

Flatcar Container Linux is designed to be updated automatically with different schedules per channel. You can [disable this feature][update-strategies], although we don't recommend it. Read the [release notes][release-notes] for specific features and bug fixes.

PXE booted machines cannot currently update themselves when new versions are released to a channel. To update to the latest version of Flatcar Container Linux download/verify these files again and reboot.

<div id="pxe-create">
  <ul class="nav nav-tabs">
    <li class="active"><a href="#stable-create" data-toggle="tab">Stable Channel</a></li>
    <li><a href="#beta-create" data-toggle="tab">Beta Channel</a></li>
    <li><a href="#alpha-create" data-toggle="tab">Alpha Channel</a></li>
  </ul>
  <div class="tab-content coreos-docs-image-table">
    <div class="tab-pane" id="alpha-create">
      <p>The Alpha channel closely tracks master and is released frequently. The newest versions of system libraries and utilities will be available for testing. The current version is Flatcar Container Linux {{< param alpha_channel >}}.</p>
      <p>In the config above you can see that a Kernel image and a initramfs file is needed. Download these two files into your tftp root.</p>
      <p>The <code>flatcar_production_pxe.vmlinuz.sig</code> and <code>flatcar_production_pxe_image.cpio.gz.sig</code> files can be used to <a href="../../community-platforms/notes-for-distributors#importing-images">verify the downloaded files</a>.</p>
      <pre>
cd /var/lib/tftpboot
wget https://alpha.release.flatcar-linux.net/amd64-usr/current/flatcar_production_pxe.vmlinuz
wget https://alpha.release.flatcar-linux.net/amd64-usr/current/flatcar_production_pxe.vmlinuz.sig
wget https://alpha.release.flatcar-linux.net/amd64-usr/current/flatcar_production_pxe_image.cpio.gz
wget https://alpha.release.flatcar-linux.net/amd64-usr/current/flatcar_production_pxe_image.cpio.gz.sig
gpg --verify flatcar_production_pxe.vmlinuz.sig
gpg --verify flatcar_production_pxe_image.cpio.gz.sig
      </pre>
    </div>
    <div class="tab-pane" id="beta-create">
      <p>The Beta channel consists of promoted Alpha releases. The current version is Flatcar Container Linux {{< param beta_channel >}}.</p>
      <p>In the config above you can see that a Kernel image and a initramfs file is needed. Download these two files into your tftp root.</p>
      <p>The <code>flatcar_production_pxe.vmlinuz.sig</code> and <code>flatcar_production_pxe_image.cpio.gz.sig</code> files can be used to <a href="../../community-platforms/notes-for-distributors#importing-images">verify the downloaded files</a>.</p>
      <pre>
cd /var/lib/tftpboot
wget https://beta.release.flatcar-linux.net/amd64-usr/current/flatcar_production_pxe.vmlinuz
wget https://beta.release.flatcar-linux.net/amd64-usr/current/flatcar_production_pxe.vmlinuz.sig
wget https://beta.release.flatcar-linux.net/amd64-usr/current/flatcar_production_pxe_image.cpio.gz
wget https://beta.release.flatcar-linux.net/amd64-usr/current/flatcar_production_pxe_image.cpio.gz.sig
gpg --verify flatcar_production_pxe.vmlinuz.sig
gpg --verify flatcar_production_pxe_image.cpio.gz.sig
      </pre>
    </div>
    <div class="tab-pane active" id="stable-create">
      <p>The Stable channel should be used by production clusters. Versions of Flatcar Container Linux are battle-tested within the Beta and Alpha channels before being promoted. The current version is Flatcar Container Linux {{< param stable_channel >}}.</p>
      <p>In the config above you can see that a Kernel image and a initramfs file is needed. Download these two files into your tftp root.</p>
      <p>The <code>flatcar_production_pxe.vmlinuz.sig</code> and <code>flatcar_production_pxe_image.cpio.gz.sig</code> files can be used to <a href="../../community-platforms/notes-for-distributors#importing-images">verify the downloaded files</a>.</p>
      <pre>
cd /var/lib/tftpboot
wget https://stable.release.flatcar-linux.net/amd64-usr/current/flatcar_production_pxe.vmlinuz
wget https://stable.release.flatcar-linux.net/amd64-usr/current/flatcar_production_pxe.vmlinuz.sig
wget https://stable.release.flatcar-linux.net/amd64-usr/current/flatcar_production_pxe_image.cpio.gz
wget https://stable.release.flatcar-linux.net/amd64-usr/current/flatcar_production_pxe_image.cpio.gz.sig
gpg --verify flatcar_production_pxe.vmlinuz.sig
gpg --verify flatcar_production_pxe_image.cpio.gz.sig
      </pre>
    </div>
  </div>
</div>

## Booting the box

After setting up the PXE server as outlined above you can start the target machine in PXE boot mode. The machine should grab the image from the server and boot into Flatcar Container Linux. If something goes wrong you can direct questions to the [IRC channel][irc] or [mailing list][flatcar-user].

```shell
This is localhost.unknown_domain (Linux x86_64 3.10.10+) 19:53:36
SSH host key: 24:2e:f1:3f:5f:9c:63:e5:8c:17:47:32:f4:09:5d:78 (RSA)
SSH host key: ed:84:4d:05:e3:7d:e3:d0:b9:58:90:58:3b:99:3a:4c (DSA)
ens0: 10.0.2.15 fe80::5054:ff:fe12:3456
localhost login:
```

## Logging in

The IP address for the machine should be printed out to the terminal for convenience. If it doesn't show up immediately, press enter a few times and it should show up. Now you can simply SSH in using public key authentication:

```shell
ssh core@10.0.2.15
```

## Update Process

Since our upgrade process requires a disk, this image does not have the option to update itself. Instead, the box simply needs to be rebooted and will be running the latest version, assuming that the image served by the PXE server is regularly updated.

## Installation

Once booted it is possible to [install Flatcar Container Linux on a local disk][installing-to-disk] or to just use local storage for the writable root filesystem while continuing to boot Flatcar Container Linux itself via PXE.

If you plan on using Docker we recommend using a local ext4 filesystem with overlayfs, however, btrfs is also available to use if needed.

For example, to setup an ext4 root filesystem on `/dev/sda`:

```yaml
storage:
  disks:
  - device: /dev/sda
    wipe_table: true
    partitions:
    - label: ROOT
  filesystems:
  - mount:
      device: /dev/disk/by-partlabel/ROOT
      format: ext4
      wipe_filesystem: true
      label: ROOT
```

And add `root=/dev/sda1` or `root=LABEL=ROOT` to the kernel options as documented above.

Similarly, to setup a btrfs root filesystem on `/dev/sda`:

```yaml
storage:
  disks:
  - device: /dev/sda
    wipe_table: true
    partitions:
    - label: ROOT
  filesystems:
  - mount:
      device: /dev/disk/by-partlabel/ROOT
      format: btrfs
      wipe_filesystem: true
      label: ROOT
```

## Adding a Custom OEM

Similar to the [OEM partition][oem] in Flatcar Container Linux disk images, PXE images can be customized with an [Ignition config][ignition] bundled in the initramfs. Simply create a `./usr/share/oem/` directory, add a `config.ign` file containing the Ignition config, and add the directory tree as an additional initramfs:

```shell
mkdir -p usr/share/oem
cp example.ign ./usr/share/oem/config.ign
find usr | cpio -o -H newc -O oem.cpio
gzip oem.cpio
```

Confirm the archive looks correct and has your config inside of it:

```shell
gzip --stdout --decompress oem.cpio.gz | cpio -it
./
usr
usr/share
usr/share/oem
usr/share/oem/config.ign
```

Add the `oem.cpio.gz` file to your PXE boot directory, then [append it][append-initrd] to the `initrd` line in your `pxelinux.cfg`:

```text
...
initrd flatcar_production_pxe_image.cpio.gz,oem.cpio.gz
kernel flatcar_production_pxe.vmlinuz flatcar.first_boot=1
...
```

## Using Flatcar Container Linux

Now that you have a machine booted it is time to play around. Check out the [Flatcar Container Linux Quickstart][quickstart] guide or dig into [more specific topics][doc-index].

[append-initrd]: http://www.syslinux.org/wiki/index.php?title=SYSLINUX#INITRD_initrd_file
[flatcar-user]: https://groups.google.com/forum/#!forum/flatcar-linux-user
[irc]: irc://irc.freenode.org:6667/#flatcar
[butane-configs]: ../../provisioning/config-transpiler
[ignition]: ../../provisioning/ignition
[ignition-kargs-ip]: ../../provisioning/ignition/network-configuration/#using-static-ip-addresses-with-ignition
[oem]: ../community-platforms/notes-for-distributors#image-customization
[installing-to-disk]: installing-to-disk
[update-strategies]: ../../setup/releases/update-strategies
[release-notes]: https://flatcar-linux.org/releases
[quickstart]: ../
[doc-index]: ../../

