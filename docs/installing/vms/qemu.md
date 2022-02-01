---
title: Running Flatcar Container Linux on QEMU
title: Running on QEMU
weight: 30
aliases:
    - ../../os/booting-with-qemu
    - ../../cloud-providers/booting-with-qemu
---

These instructions will bring up a single Flatcar Container Linux instance under QEMU, the small Swiss Army knife of virtual machine and CPU emulators. If you need to do more such as [configuring networks][qemunet] definitely refer to the [QEMU Wiki][qemuwiki] and [User Documentation][qemudoc].

You can direct questions to the [IRC channel][irc] or [mailing list][flatcar-dev].

[qemunet]: http://wiki.qemu.org/Documentation/Networking
[qemuwiki]: http://wiki.qemu.org/Manual
[qemudoc]: http://qemu.weilnetz.de/qemu-doc.html

## Install QEMU

In addition to Linux it can be run on Windows and OS X but works best on Linux. It should be available on just about any distro.

### Debian or Ubuntu

Documentation for [Debian][qemudeb] has more details but to get started all you need is:

```shell
sudo apt-get install qemu-system-x86 qemu-utils
```

[qemudeb]: https://wiki.debian.org/QEMU

### Fedora or RedHat

The Fedora wiki has a [quick howto][qemufed] but the basic install is easy:

```shell
sudo yum install qemu-system-x86 qemu-img
```

[qemufed]: https://fedoraproject.org/wiki/How_to_use_qemu

### Arch

This is all you need to get started:

```shell
sudo pacman -S qemu
```

More details can be found on [Arch's QEMU wiki page](https://wiki.archlinux.org/index.php/Qemu).

### Gentoo

As to be expected, Gentoo can be a little more complicated but all the required kernel options and USE flags are covered in the [Gentoo Wiki][qemugen]. Usually this should be sufficient:

```shell
echo app-emulation/qemu qemu_softmmu_targets_x86_64 virtfs xattr >> /etc/portage/package.use
emerge -av app-emulation/qemu
```

[qemugen]: http://wiki.gentoo.org/wiki/QEMU
## Startup Flatcar Container Linux

Once QEMU is installed you can download and start the latest Flatcar Container Linux image.

### Choosing a channel

Flatcar Container Linux is designed to be updated automatically with different schedules per channel. You can [disable this feature][update-strategies], although we don't recommend it. Read the [release notes][release-notes] for specific features and bug fixes.

<div id="qemu-images">
  <ul class="nav nav-tabs">
    <li class="active"><a href="#stable" data-toggle="tab">Stable Channel</a></li>
    <li><a href="#beta" data-toggle="tab">Beta Channel</a></li>
    <li><a href="#alpha" data-toggle="tab">Alpha Channel</a></li>
    <li><a href="#edge" data-toggle="tab">Edge Channel</a></li>
  </ul>
  <div class="tab-content coreos-docs-image-table">
    <div class="tab-pane active" id="stable">
      <div class="channel-info">
        <p>The Stable channel should be used by production clusters. Versions of Flatcar Container Linux are battle-tested within the Beta and Alpha channels before being promoted. The current version is Flatcar Container Linux {{< param stable_channel >}}.</p>
       </div>
      <p>There are two files you need: the disk image (provided in qcow2
      format) and the wrapper shell script to start QEMU.</p>
      <pre>mkdir flatcar; cd flatcar
wget https://stable.release.flatcar-linux.net/amd64-usr/current/flatcar_production_qemu.sh
wget https://stable.release.flatcar-linux.net/amd64-usr/current/flatcar_production_qemu.sh.sig
wget https://stable.release.flatcar-linux.net/amd64-usr/current/flatcar_production_qemu_image.img.bz2
wget https://stable.release.flatcar-linux.net/amd64-usr/current/flatcar_production_qemu_image.img.bz2.sig
gpg --verify flatcar_production_qemu.sh.sig
gpg --verify flatcar_production_qemu_image.img.bz2.sig
bzip2 -d flatcar_production_qemu_image.img.bz2
chmod +x flatcar_production_qemu.sh</pre>
    </div>
    <div class="tab-pane" id="alpha">
      <div class="channel-info">
        <p>The Alpha channel closely tracks master and is released frequently. The newest versions of system libraries and utilities will be available for testing. The current version is Flatcar Container Linux {{< param alpha_channel >}}.</p>
      </div>
      <p>There are two files you need: the disk image (provided in qcow2
      format) and the wrapper shell script to start QEMU.</p>
      <pre>mkdir flatcar; cd flatcar
wget https://alpha.release.flatcar-linux.net/amd64-usr/current/flatcar_production_qemu.sh
wget https://alpha.release.flatcar-linux.net/amd64-usr/current/flatcar_production_qemu.sh.sig
wget https://alpha.release.flatcar-linux.net/amd64-usr/current/flatcar_production_qemu_image.img.bz2
wget https://alpha.release.flatcar-linux.net/amd64-usr/current/flatcar_production_qemu_image.img.bz2.sig
gpg --verify flatcar_production_qemu.sh.sig
gpg --verify flatcar_production_qemu_image.img.bz2.sig
bzip2 -d flatcar_production_qemu_image.img.bz2
chmod +x flatcar_production_qemu.sh</pre>
    </div>
    <div class="tab-pane" id="beta">
      <div class="channel-info">
        <p>The Beta channel consists of promoted Alpha releases. The current version is Flatcar Container Linux {{< param beta_channel >}}.</p>
      </div>
      <p>There are two files you need: the disk image (provided in qcow2
      format) and the wrapper shell script to start QEMU.</p>
      <pre>mkdir flatcar; cd flatcar
wget https://beta.release.flatcar-linux.net/amd64-usr/current/flatcar_production_qemu.sh
wget https://beta.release.flatcar-linux.net/amd64-usr/current/flatcar_production_qemu.sh.sig
wget https://beta.release.flatcar-linux.net/amd64-usr/current/flatcar_production_qemu_image.img.bz2
wget https://beta.release.flatcar-linux.net/amd64-usr/current/flatcar_production_qemu_image.img.bz2.sig
gpg --verify flatcar_production_qemu.sh.sig
gpg --verify flatcar_production_qemu_image.img.bz2.sig
bzip2 -d flatcar_production_qemu_image.img.bz2
chmod +x flatcar_production_qemu.sh</pre>
    </div>
    <div class="tab-pane" id="edge">
      <div class="channel-info">
        <p>The Edge channel includes bleeding-edge features with the newest versions of the Linux kernel, systemd and other core packages. Can be highly unstable. The current version is Flatcar Container Linux {{< param edge_channel >}}.</p>
      </div>
      <p>There are two files you need: the disk image (provided in qcow2
      format) and the wrapper shell script to start QEMU.</p>
      <pre>mkdir flatcar; cd flatcar
wget https://edge.release.flatcar-linux.net/amd64-usr/current/flatcar_production_qemu.sh
wget https://edge.release.flatcar-linux.net/amd64-usr/current/flatcar_production_qemu.sh.sig
wget https://edge.release.flatcar-linux.net/amd64-usr/current/flatcar_production_qemu_image.img.bz2
wget https://edge.release.flatcar-linux.net/amd64-usr/current/flatcar_production_qemu_image.img.bz2.sig
gpg --verify flatcar_production_qemu.sh.sig
gpg --verify flatcar_production_qemu_image.img.bz2.sig
bzip2 -d flatcar_production_qemu_image.img.bz2
chmod +x flatcar_production_qemu.sh</pre>
    </div>
  </div>
</div>

Starting is as simple as:

```shell
./flatcar_production_qemu.sh -nographic
```

### SSH keys

In order to log in to the virtual machine you will need to use ssh keys. If you don't already have a ssh key pair you can generate one simply by running the command `ssh-keygen`. The wrapper script will automatically look for public keys in ssh-agent if available and at the default locations `~/.ssh/id_dsa.pub` or `~/.ssh/id_rsa.pub`. If you need to provide an alternate location use the -a option:

```shell
./flatcar_production_qemu.sh -a ~/.ssh/authorized_keys -- -nographic
```

Note: Options such as `-a` for the wrapper script must be specified before any options for QEMU. To make the separation between the two explicit you can use `--` but that isn't required. See `./flatcar_production_qemu.sh -h` for details.

Once the virtual machine has started you can log in via SSH:

```shell
ssh -l core -p 2222 localhost
```

### SSH config

To simplify this and avoid potential host key errors in the future add the following to `~/.ssh/config`:

```shell
Host flatcar
HostName localhost
Port 2222
User core
StrictHostKeyChecking no
UserKnownHostsFile /dev/null
```

Now you can log in to the virtual machine with:

```shell
ssh flatcar
```

### Container Linux Configs

Flatcar Container Linux allows you to configure machine parameters, configure networking, launch systemd units on startup, and more via Container Linux Configs. These configs are then transpiled into Ignition configs and given to booting machines. Head over to the [docs to learn about the supported features][cl-configs]. An Ignition config can be passed to the virtual machine using the QEMU Firmware Configuration Device. The wrapper script provides a method for doing so:

```shell
./flatcar_production_qemu.sh -i config.ign -- -nographic
```

This will pass the contents of `config.ign` through to Ignition, which runs in the virtual machine.

## Using Flatcar Container Linux

Now that you have a machine booted it is time to play around. Check out the [Flatcar Container Linux Quickstart][quickstart] guide or dig into [more specific topics][doc-index].

[update-strategies]: ../../setup/releases/update-strategies
[release-notes]: https://flatcar-linux.org/releases
[quickstart]: ../
[doc-index]: ../../
[flatcar-dev]: https://groups.google.com/forum/#!forum/flatcar-linux-dev
[irc]: irc://irc.freenode.org:6667/#flatcar
[cl-configs]: ../../provisioning/cl-config
