---
title: Flatcar Container Linux startup process
linktitle: Boot process overview
weight: 10
aliases:
    - ../../ignition/boot-process
---

The Flatcar Container Linux startup process is built on the standard [Linux startup process][linux-startup]. Since this process is already well documented and generally well understood, this document will focus on aspects specific to booting Flatcar Container Linux.

## Bootloader

[GRUB][grub] is the first program executed when a Flatcar Container Linux system boots. The Flatcar Container Linux [GRUB config][grub-config] has several roles.

First, the GRUB config [specifies which `usr` partition to use][gptprio.next] from the two `usr` partitions Flatcar Container Linux uses to provide atomic upgrades and rollbacks.

Second, GRUB [checks for a file called `flatcar/first_boot` in the EFI System Partition][check-file] to determine if this is the first time a machine has booted (or it checks for `coreos/first_boot` if the machine was updated from CoreOS CL). If that file is found, GRUB sets the `flatcar.first_boot=detected` Linux kernel command line parameter. This parameter is used in later stages of the boot process.

Finally, GRUB [searches for the initial disk GUID][search-guid] (00000000-0000-0000-0000-000000000001) built into Flatcar Container Linux images. This GUID is randomized later in the boot process so that individual disks may be uniquely identified. If GRUB finds this GUID it sets another Linux kernel command line parameter, `flatcar.randomize_guid=00000000-0000-0000-0000-000000000001`.

## Early user space

After GRUB, the Flatcar Container Linux startup process moves into the initial RAM file system. The initramfs mounts the root filesystem, randomizes the disk GUID, and runs Ignition.

If the `flatcar.randomize_guid` kernel parameter is provided, the disk with the specified GUID is given a new, random GUID.

If the `flatcar.first_boot` kernel parameter is provided and non-zero, Ignition and networkd are started. networkd will use DHCP to set up temporary IP addresses and routes so that Ignition can fetch its configuration from the network.

### Ignition

When Ignition runs on Flatcar Container Linux, it reads the Linux command line, looking for `flatcar.oem.id`. Ignition uses this identifier to determine where to read the user-provided configuration and which provider-specific configuration to combine with the user's. This provider-specific configuration performs basic machine setup, and may include enabling `coreos-metadata-sshkeys@.service` (covered in more detail below).

After Ignition runs successfully, if `flatcar.first_boot` was set to the special value `detected`, Ignition mounts the EFI System Partition and deletes the `flatcar/first_boot` file (or `coreos/first_boot` if the machine was updated from CoreOS CL).

## User space

After all of the tasks in the initramfs complete, the machine pivots into user space. It is at this point that systemd begins starting units, including, if it was enabled, `coreos-metadata-sshkeys@core.service`.

### SSH keys

`coreos-metadata-sshkeys@core.service` is responsible for fetching SSH keys from the machine's environment. The keys are written to `~core/.ssh/authorized_keys.d/coreos-metadata` and `update-ssh-keys` is run to update `~core/.ssh/authorized_keys`. On cloud platforms, the keys are read from the provider's metadata service. This service is not supported on all platforms and is enabled by Ignition *only* on those which are supported.

### Reprovisioning

To trigger a new Ignition run, either manually set `flatcar.first_boot=1` as temporary kernel command line parameter in GRUB or create the flag file `touch /boot/flatcar/first_boot` (or `/boot/coreos/first_boot` if the machine was updated from CoreOS CL).

Be aware that if you changed the Ignition config in the mean time, old files not known to the new Ignition config will be kept, and any other runtime data, too.
Systemd service presets are also not reevaluated automatically. This means that newly declared service units won't be enabled unless you also create the symlinks for their targets.

Here is an example config with an additional `link` entry that ensures that the new service unit is enabled if this config is used for reprovisioning:

```
{
  "ignition": {
    "version": "2.2.0"
  },
  "systemd": {
     "units": [
       {
         "name": "my.service",
         "enabled": true,
         "contents": "[Service]\nType=oneshot\nExecStart=/usr/bin/echo Hello World\n\n[Install]\nWantedBy=multi-user.target"
       }
     ]
   },
   "storage": {
     "links": [
       {
         "filesystem": "root",
         "path": "/etc/systemd/system/multi-user.target.wants/my.service",
         "target": "/etc/systemd/system/my.service"
       }
     ]
   }
}
```

[check-file]: https://github.com/flatcar-linux/scripts/blob/9e1c23f3f44d2751076e770f43f7a6db05d49652/build_library/grub.cfg#L68-L71
[gptprio.next]: https://github.com/flatcar-linux/scripts/blob/9e1c23f3f44d2751076e770f43f7a6db05d49652/build_library/grub.cfg#L132
[grub]: https://www.gnu.org/software/grub/
[grub-config]: https://github.com/flatcar-linux/scripts/blob/9e1c23f3f44d2751076e770f43f7a6db05d49652/build_library/grub.cfg
[linux-startup]: https://en.wikipedia.org/wiki/Linux_startup_process
[search-guid]: https://github.com/flatcar-linux/scripts/blob/9e1c23f3f44d2751076e770f43f7a6db05d49652/build_library/grub.cfg#L73-L78
