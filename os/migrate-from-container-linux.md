# Migrating from CoreOS Container Linux

While Flatcar is compatible with CoreOS Container Linux there are some naming differences you need to be aware of.

**NOTE:** See [Updating from CoreOS Container Linux](update-from-container-linux.md)
for additional information on updating an existing cluster.

## Installation

_Optional:_ Instead of `coreos-installer` you should use `flatcar-installer`.

## Kernel command line parameters

_Optional:_ Instead of providing the `coreos.first_boot=1` argument via the boot loader you should provide `flatcar.first_boot=1`.
This forces provisioning via Ignition even if the machine (image) was booted already before.

_Optional:_ Instead of providing the `coreos.config.url=SOMEURL` argument via the boot loader you should to provide `ignition.config.url=SOMEURL`
to tell Ignition to download the configuration.
The change to a more generic name was done upstream by the Ignition project. Version 0.33 still supports both names and we
also do this via the analogous `flatcar.config.url` option but we encourage the generic name because future versions of Ignition
will only support `ignition.config.url`.

_Optional:_ Instead of providing the `coreos.oem.id=NAME` argument via the boot loader you should provide `flatcar.oem.id=NAME`.
(A change to the more generic name `ignition.platform.id` was done upstream by the Afterburn project but is not part of Container Linux yet.)

**Recover from or prevent errors with missing OEM settings (e.g., `coreos-metadata-sshkeys@core.service`):** While current releases handle both `coreos.oem` and `flatcar.oem` names, previous releases still required `flatcar.oem.…`.
In that case you need to change the variables in the file `/usr/share/oem/grub.cfg` when you update from CoreOS Container Linux:

```
# GRUB settings
set oem_id="myoemvalue"
set linux_append="$linux flatcar.oem.id=myoemvalue"
```

## Ignition configuration with QEMU

_Optional:_ Instead of using `opt/com.coreos/config` in the `-fw_cfg` name-value argument pair for QEMU/KVM or libvirt you need to use `opt/org.flatcar-linux/config`.
The value in the argument pair specifies the Ignition file to use.

## Ignition configuration with VMware

_Optional:_ Instead of `coreos.config.data` and `coreos.config.data.encoding` for the VMware `guestinfo.VARIABLE` command line options you should use `ignition.config.data` and `ignition.config.data.encoding`.
Same as for the `ignition.config.url` kernel parameter this change was done upstream by the Ignition project.
