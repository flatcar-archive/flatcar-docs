---
title: Flatcar Container Linux disk layout
weight: 10
aliases:
    - ../../os/sdk-disk-partitions
---

Flatcar Container Linux is designed to be reliably updated via a continuous stream of updates. The operating system has 9 different disk partitions, utilizing a subset of those to make each update safe and enable a roll-back to a previous version if anything goes wrong.

## Partition table

| Number | Label      | Description                                                       | Partition Type        |
|:------:|------------|-------------------------------------------------------------------|-----------------------|
| 1      | EFI-SYSTEM | Contains the bootloader                                           | FAT32                 |
| 2      | BIOS-BOOT  | Contains the second stages of GRUB for use when booting from BIOS | grub core.img         |
| 3      | USR-A      | One of two active/passive partitions holding Flatcar Container Linux      | EXT2                  |
| 4      | USR-B      | One of two active/passive partitions holding Flatcar Container Linux      | (empty on first boot) |
| 5      | ROOT-C     | This partition is reserved for future use                         | (none)                |
| 6      | OEM        | Stores configuration data specific to an [OEM platform][OEM docs] | BTRFS                 |
| 7      | OEM-CONFIG | Optional storage for an OEM                                       | (defined by OEM)      |
| 8      | (unused)   | This partition is reserved for future use                         | (none)                |
| 9      | ROOT       | Stateful partition for storing persistent data                    | EXT4, BTRFS, or XFS   |

For more information, [read more about the disk layout][chromium disk format] used by Chromium and ChromeOS, which inspired the layout used by Flatcar Container Linux.

[OEM docs]: ../../installing/community-platforms/notes-for-distributors
[chromium disk format]: https://chromium.googlesource.com/chromiumos/docs/+/HEAD/disk_format.md

## Mounted filesystems

Flatcar Container Linux is divided into two main filesystems, a read-only `/usr` and a stateful read/write `/`.

### Read-only /usr

The `USR-A` or `USR-B` partitions are interchangeable and one of the two is mounted as a read-only filesystem at `/usr`. After an update, Flatcar Container Linux will re-configure the GPT priority attribute, instructing the bootloader to boot from the passive (newly updated) partition. Here's an example of the priority flags set on an Amazon EC2 machine:

```shell
$ sudo cgpt show /dev/xvda
       start        size    part  contents
      270336     2097152       3  Label: "USR-A"
                                  Type: Alias for coreos-rootfs
                                  UUID: 7130C94A-213A-4E5A-8E26-6CCE9662F132
                                  Attr: priority=1 tries=0 successful=1
```

Flatcar Container Linux images ship with the `USR-B` partition empty to reduce the image filesize. The first Flatcar Container Linux update will populate it and start the normal active/passive scheme.

The OEM partition is mounted at `/usr/share/oem`.

### Stateful root

All stateful data, including container images, is stored within the read/write filesystem mounted at `/`. On first boot, the ROOT partition and filesystem will expand to fill any remaining free space at the end of the drive.

The data stored on the root partition isn't manipulated by the update process. In return, we do our best to prevent you from modifying the data in /usr.

Due to the unique disk layout of Flatcar Container Linux, an `rm -rf --one-file-system --no-preserve-root /` is an unsupported but valid operation to purge any OS data. On the next boot, the machine should just start from a clean state.

To [re-provision][provisioning] the node after such cleanup, use `touch /boot/flatcar/first_boot` to trigger Ignition [to run once][boot process] again on the next boot (if the machine was updated from CoreOS Container Linux, you need to use `/boot/coreos/first_boot`).

[provisioning]: ../../provisioning
[boot process]: ../../provisioning/ignition/boot-process
