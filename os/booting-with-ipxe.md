# Booting Flatcar Container Linux via iPXE

These instructions will walk you through booting Flatcar Container Linux via iPXE on real or virtual hardware. By default, this will run Flatcar Container Linux completely out of RAM. Flatcar Container Linux can also be [installed to disk](installing-to-disk.md).

A minimum of 3 GB of RAM is required to boot Flatcar Container Linux via PXE.

## Configuring iPXE

iPXE can be used on any platform that can boot an ISO image.
This includes many cloud providers and physical hardware.

To illustrate iPXE in action we will use qemu-kvm in this guide.

### Setting up iPXE boot script

When configuring the Flatcar Container Linux iPXE boot script there are a few kernel options that may be useful but all are optional.

- **rootfstype=tmpfs**: Use tmpfs for the writable root filesystem. This is the default behavior.
- **rootfstype=btrfs**: Use btrfs in RAM for the writable root filesystem. The filesystem will consume more RAM as it grows, up to a max of 50%. The limit isn't currently configurable.
- **root**: Use a local filesystem for root instead of one of two in-ram options above. The filesystem must be formatted (perhaps using Ignition) but may be completely blank; it will be initialized on boot. The filesystem may be specified by any of the usual ways including device, label, or UUID; e.g: `root=/dev/sda1`, `root=LABEL=ROOT` or `root=UUID=2c618316-d17a-4688-b43b-aa19d97ea821`.
- **sshkey**: Add the given SSH public key to the `core` user's authorized_keys file. Replace the example key below with your own (it is usually in `~/.ssh/id_rsa.pub`)
- **console**: Enable kernel output and a login prompt on a given tty. The default, `tty0`, generally maps to VGA. Can be used multiple times, e.g. `console=tty0 console=ttyS0`
- **flatcar.autologin**: Drop directly to a shell on a given console without prompting for a password. Useful for troubleshooting but use with caution. For any console that doesn't normally get a login prompt by default be sure to combine with the `console` option, e.g. `console=tty0 console=ttyS0 flatcar.autologin=tty1 flatcar.autologin=ttyS0`. Without any argument it enables access on all consoles. Note that for the VGA console the login prompts are on virtual terminals (`tty1`, `tty2`, etc), not the VGA console itself (`tty0`).
- **flatcar.first_boot=1**: Download an Ignition config and use it to provision your booted system. Ignition configs are generated from Container Linux Configs. See the [config transpiler documentation][cl-configs] for more information. If a local filesystem is used for the root partition, pass this parameter only on the first boot.
- **ignition.config.url**: Download the Ignition config from the specified URL. `http`, `https`, `s3`, and `tftp` schemes are supported.

### Choose a Channel

Flatcar Container Linux is designed to be updated automatically with different schedules per channel. You can [disable this feature](update-strategies.md), although we don't recommend it. Read the [release notes](https://flatcar-linux.org/releases) for specific features and bug fixes.

### Setting up the Boot Script

<div id="ipxe-create">
  <ul class="nav nav-tabs">
    <li class="active"><a href="#stable-create" data-toggle="tab">Stable Channel</a></li>
    <li><a href="#beta-create" data-toggle="tab">Beta Channel</a></li>
    <li><a href="#alpha-create" data-toggle="tab">Alpha Channel</a></li>
    <li><a href="#edge-create" data-toggle="tab">Edge Channel</a></li>
  </ul>
  <div class="tab-content coreos-docs-image-table">
    <div class="tab-pane" id="alpha-create">
      <p>The Alpha channel closely tracks master and is released frequently. The newest versions of system libraries and utilities will be available for testing. The current version is Flatcar Container Linux {{site.alpha-channel}}.</p>
      <p>iPXE downloads a boot script from a publicly available URL. You will need to host this URL somewhere public and replace the example SSH key with your own. You can also run a <a href="https://github.com/kelseyhightower/coreos-ipxe-server">custom iPXE server</a>.</p>
      <pre>
#!ipxe

set base-url http://alpha.release.flatcar-linux.net/amd64-usr/current
kernel ${base-url}/flatcar_production_pxe.vmlinuz initrd=flatcar_production_pxe_image.cpio.gz flatcar.first_boot=1 ignition.config.url=https://example.com/pxe-config.ign
initrd ${base-url}/flatcar_production_pxe_image.cpio.gz
boot</pre>
    </div>
    <div class="tab-pane" id="beta-create">
      <p>The Beta channel consists of promoted Alpha releases. The current version is Flatcar Container Linux {{site.beta-channel}}.</p>
      <p>iPXE downloads a boot script from a publicly available URL. You will need to host this URL somewhere public and replace the example SSH key with your own. You can also run a <a href="https://github.com/kelseyhightower/coreos-ipxe-server">custom iPXE server</a>.</p>
      <pre>
#!ipxe

set base-url http://beta.release.flatcar-linux.net/amd64-usr/current
kernel ${base-url}/flatcar_production_pxe.vmlinuz initrd=flatcar_production_pxe_image.cpio.gz flatcar.first_boot=1 ignition.config.url=https://example.com/pxe-config.ign
initrd ${base-url}/flatcar_production_pxe_image.cpio.gz
boot</pre>
    </div>
    <div class="tab-pane" id="edge-create">
      <p>The Edge channel includes bleeding-edge features with the newest versions of the Linux kernel, systemd and other core packages. Can be highly unstable. The current version is Flatcar Container Linux {{site.edge-channel}}.</p>
      <p>iPXE downloads a boot script from a publicly available URL. You will need to host this URL somewhere public and replace the example SSH key with your own. You can also run a <a href="https://github.com/kelseyhightower/coreos-ipxe-server">custom iPXE server</a>.</p>
      <pre>
#!ipxe

set base-url http://edge.release.flatcar-linux.net/amd64-usr/current
kernel ${base-url}/flatcar_production_pxe.vmlinuz initrd=flatcar_production_pxe_image.cpio.gz flatcar.first_boot=1 ignition.config.url=https://example.com/pxe-config.ign
initrd ${base-url}/flatcar_production_pxe_image.cpio.gz
boot</pre>
    </div>
    <div class="tab-pane active" id="stable-create">
      <p>The Stable channel should be used by production clusters. Versions of Flatcar Container Linux are battle-tested within the Beta and Alpha channels before being promoted. The current version is Flatcar Container Linux {{site.stable-channel}}.</p>
      <p>iPXE downloads a boot script from a publicly available URL. You will need to host this URL somewhere public and replace the example SSH key with your own. You can also run a <a href="https://github.com/kelseyhightower/coreos-ipxe-server">custom iPXE server</a>.</p>
      <pre>
#!ipxe

set base-url http://stable.release.flatcar-linux.net/amd64-usr/current
kernel ${base-url}/flatcar_production_pxe.vmlinuz initrd=flatcar_production_pxe_image.cpio.gz flatcar.first_boot=1 ignition.config.url=https://example.com/pxe-config.ign
initrd ${base-url}/flatcar_production_pxe_image.cpio.gz
boot</pre>
    </div>
  </div>
</div>

An easy place to host this boot script is on [http://pastie.org](http://pastie.org). Be sure to reference the "raw" version of script, which is accessed by clicking on the clipboard in the top right.


### Booting iPXE

First, download and boot the iPXE image.
We will use `qemu-kvm` in this guide but use whatever process you normally use for booting an ISO on your platform.

```sh
wget http://boot.ipxe.org/ipxe.iso
qemu-kvm -m 1024 ipxe.iso --curses
```

Next press Ctrl+B to get to the iPXE prompt and type in the following commands:

```sh
iPXE> dhcp
iPXE> chain http://${YOUR_BOOT_URL}
```

Immediately iPXE should download your boot script URL and start grabbing the images from the Flatcar Container Linux storage site:

```sh
${YOUR_BOOT_URL}... ok
http://alpha.release.flatcar-linux.net/amd64-usr/current/flatcar_production_pxe.vmlinuz... 98%
```

After a few moments of downloading Flatcar Container Linux should boot normally.

## Update process

Since Flatcar Container Linux's upgrade process requires a disk, this image does not have the option to update itself. Instead, the box simply needs to be rebooted and will be running the latest version, assuming that the image served by the PXE server is regularly updated.

## Installation

Flatcar Container Linux can be completely installed on disk or run from RAM but store user data on disk. Read more in our [Installing Flatcar Container Linux guide](booting-with-pxe.md#installation).

## Adding a custom OEM

Similar to the [OEM partition][oem] in Flatcar Container Linux disk images, iPXE images can be customized with an [Ignition config][ignition] bundled in the initramfs. You can view the [instructions on the PXE docs](booting-with-pxe.md#adding-a-custom-oem).

[oem]: notes-for-distributors.md#image-customization

## Using Flatcar Container Linux

Now that you have a machine booted it is time to play around. Check out the [Flatcar Container Linux Quickstart](quickstart.md) guide or dig into [more specific topics](https://docs.flatcar-linux.org).

[cl-configs]: provisioning.md
[ignition]: https://coreos.com/ignition/docs/latest
