---
title: Customizing a Flatcar image
weight: 30
---

While [Ignition][ignition] cloud instance userdata is the preferred way of customizing an installation, it can be limiting when the customization concerns the kernel boot arguments or when no cloud instance userdata mechanism is in place.
The partition with the OS `/usr` filesystem can't be modified because it is signed and gets auto-updated.
Other partitions like the boot partition, the OEM partition, or even the root partition are open for customization.
The boot partition can hold an additional EFI boot loader, the OEM partition can hold a GRUB file for the kernel arguments and possibly a default and/or base Ignition configuration, the root partition can hold the OS configuration and additional binaries.
**Note:** Important is that you never boot the image because the first-boot initialization would make all your instances identical, causing problems with the update server, skips the regeneration of SSH host keys, and prevents Ignition from running. In case you have to do so for running Packer and/or Ansible, see the last section for common problems.

## Mounting a partition for customization

The generic Flatcar Container Linux [image](https://stable.release.flatcar-linux.net/amd64-usr/current/flatcar_production_image.bin.bz2) (`.bin`) can be directly attached as loop device on a Linux host and mounted after decompression with `bunzip2` or `lbunzip2`. The partition to modify needs to be specified by its number:

```shell
# PART can be 1 (boot), 6 (OEM), 9 (ROOT)
PART=1
LOOP=$(sudo losetup --partscan --find --show flatcar_production_image.bin)
TARGET=$(sudo mktemp -d -p /mnt --suffix -flatcar)
sudo mount "${LOOP}p${PART}" "$TARGET"
# Now do your changes on "$TARGET"...
# Cleanup:
sudo umount "${TARGET}"
sudo rmdir "${TARGET}"
sudo losetup -d "${LOOP}"
```

If you need to modify the QEMU `qcow2` image or an `vmdk` image, you need to either convert it first to a raw image:

```shell
qemu-img convert -f qcow2 -O raw flatcar_production_qemu_image.img flatcar_production_qemu_image.bin
```

Or you need to use the `guestmount` utility (from [libguestfs](https://libguestfs.org/)), it can run as regular user:

```
# PART can be 1 (boot), 6 (OEM), 9 (ROOT)
PART=1
TARGET=$(mktemp -d -p /tmp --suffix -flatcar)
guestmount -m "/dev/sda${PART}" -a flatcar_production_qemu_image.img "$TARGET"
# Now do your changes on "$TARGET"...
guestunmount "$TARGET"
rmdir "${TARGET}"
```

In case you converted the raw image for regular loop device mounting, you can also convert it back to qcow2 with `qemu-img convert -O qcow2 INPUT OUTPUT`.

### Example for legacy cgroup AMIs

An example script that generates CGroup V1 AWS EC2 images to be uploaded as AMIs can be found [here](https://raw.githubusercontent.com/kinvolk/flatcar-docs/main/create_cgroupv1_ami.sh).

### Customizing the boot partition

Using the above command the boot partition with the EFI binaries can be mounted to place additional firmware on it, e.g., [Raspberry Pi 4 UEFI Firmware](https://github.com/pftf/RPi4/releases/) or similar.

### Customizing the OEM partition

The OEM partition is the most common place for modifications, it also is what makes the various offered Flatcar cloud images different because it can hold mandatory and/or fallback Ignition configurations, and the `grub.cfg` file for kernel arguments.

The OEM partition is also useful to force a particular Ignition configuration to be used.
For example, `flatcar-install` offers to write a `config.ign` Ignition file to the OEM partition through the `-i` flag.
This file is used as preferred Ignition configuration even when Ignition cloud instance userdata is present. With the special `oem:///` file URL the config can copy files from the OEM Partition to the root filesystem (note: in case you have many binaries, the OEM partition may be too small and you have to either host them somewhere or place them directly on the root filesystem, see the next section).

As done on most offered Flatcar cloud images, two additional Ignition files can be placed on the OEM partition and have broader purpose, independent of whether a `config.ign` Ignition file is used, the Ignition kernel command line URL, or Ignition cloud instance userdata.
The first is `base/base.ign` which is always executed as basic mandatory setup.
The second file `base/default.ign` has a special fallback function and gets executed only if the found instance userdata is not Ignition JSON.
The common content of the file is to define a systemd service via Ignition that runs `coreos-cloudinit` to process the instance userdata later.
Good examples are [`base/base.ign`](https://github.com/flatcar-linux/coreos-overlay/blob/ad9c06df2c34be3c6d50ffb80f886bdae10b4809/coreos-base/oem-packet/files/base/base.ign) and [`base/default.ign`](https://github.com/flatcar-linux/coreos-overlay/blob/ad9c06df2c34be3c6d50ffb80f886bdae10b4809/coreos-base/oem-packet/files/base/default.ign) files used for Equinix Metal images as they also make use of the `oem:///` source URL to refer to a file placed on the OEM partition.

The `grub.cfg` file gets sourced by GRUB to set up the OEM ID which is used by systemd units to be started conditionally, or to set up kernel parameters like the Ignition config URL (`ignition.config.url`, to fetch the preferred config remotely), or settings required for the hardware.
Again, a good example is the [`grub.cfg` file](https://github.com/flatcar-linux/coreos-overlay/blob/ad9c06df2c34be3c6d50ffb80f886bdae10b4809/coreos-base/oem-packet/files/grub.cfg) used for Equinix Metal images to set the OEM ID and the kernel parameter `flatcar.autologin` to be able to use the serial console without having to configure a user password.

### Customizing the root partition

To pre-configure the OS you can place binaries and configuration files directly on the root filesystem.
The recommended way, however, is to use a `base/base.ign` or `config.ign` Ignition file in the OEM partition.
The advantage is that a `base/base.ign` file even works when the user has the root filesystem recreation option specified in Ignition which reformats the root filesystem and discards any changes placed there directly.

When modifying the root filesystem you should make sure that you only copy files over that are safe to copy, e.g., you can place binaries into `/opt/bin` or configuration files under `/etc` but you shouldn't initialize the root filesystem by booting it, even with a chroot (and calling `systemctl` there or even booting it up as container because this leads to the traps described in the next section, be aware).
When you place systemd services under `/etc/systemd/system/my.service` and they have `WantedBy=multi-user.target` in the `[Install]` section you can pre-enable them with a symlink from `/etc/systemd/system/multi-user.target.wants/my.service` to `/etc/systemd/system/my.service`.

You can even pre-populate the container image story by copying the folders `/var/lib/docker` and `/var/lib/containerd` over from a booted Flatcar instance.

## Customization through booting with Packer, VMware base VMs, or chroot/systemd-nspawn

This section serves as a big warning. If you use a booted image, even if it was only booted by being a chroot or a systemd-nspawn container, you will get a lot of problems.
Please check the OEM and the root partition section above for a saner way of pre-configuring the image.
If you try to use Packer to customize the image, or want to use a once booted VMware base VM, or even just accidentially booted the image once for testing, you created an OS state that is hard to get rid off.
It causes security issues and difficult to debug behavior changes, please use the above mechanisms to modify the image through mounting and copying because this is easier, safer, and faster.

If you still want to continue with customization through booting, here are some common traps, but there can be more depending on the software components that are involved and if you are not an expert on the software components and their respective state files, you should reconsider your choice.
The first and easiest problem is that the `/boot/flatcar/first_boot` flag file is lost which normally triggers Ignition to run on first boot. You would have to recreate this file.
More tricky is the `/etc/machine-id` file which you have to delete, not only truncate, because this file is used not only for the identification of the instance but also to trigger systemd first-boot semantics which take care of enabling services through presets. The machine ID must also be unique for the update server to work correctly, otherwise it will not hand out updates to your instance.
Another problem are the generated SSH host keys which you have to delete, otherwise each instance base on this image will have the same host keys and once the image is accessible everyone can impersonate your servers.
More problems come with weak account credentials used for the setup, e.g., when you have a dummy account with a password you have to remove the account again, and if you set up dummy SSH keys for the `core` user as common with Vagrant, you have to remove them, too. If for bootstrapping you used a `config.ign` file in the OEM partition, this, too, has to be removed.
You can have a look at the [`image-builder`](https://github.com/kubernetes-sigs/image-builder) Packer and Ansible configuration which avoids most of the common pitfalls but, again, this is not a complete list because it depends on the software components you interact with.

[ignition]: ../../provisioning/ignition
