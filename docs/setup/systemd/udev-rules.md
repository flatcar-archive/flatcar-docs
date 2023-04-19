---
title: Using systemd and udev rules
description: How to run units when specific udev events trigger.
weight: 35
aliases:
    - ../../os/using-systemd-and-udev-rules
    - ../../clusters/management/using-systemd-and-udev-rules
---

In our example we will use libvirt VM with Flatcar Container Linux and run systemd unit on disk attach event. First of all we have to create systemd unit file `/etc/systemd/system/device-attach.service`:

```ini
[Service]
Type=oneshot
ExecStart=/usr/bin/echo 'device has been attached'
```

This unit file will be triggered by our udev rule.

Then we have to start `udevadm monitor --environment` to monitor kernel events.

Once you've attached virtio libvirt device (i.e. `virsh attach-disk coreos /dev/VG/test vdc`) you'll see similar `udevadm` output:

```text
UDEV  [545.954641] add      /devices/pci0000:00/0000:00:18.0/virtio4/block/vdb (block)
.ID_FS_TYPE_NEW=
ACTION=add
DEVNAME=/dev/vdb
DEVPATH=/devices/pci0000:00/0000:00:18.0/virtio4/block/vdb
DEVTYPE=disk
ID_FS_TYPE=
MAJOR=254
MINOR=16
SEQNUM=1327
SUBSYSTEM=block
USEC_INITIALIZED=545954447
```

According to text above udev generates event which contains directives (ACTION=add and SUBSYSTEM=block) we will use in our rule. It should look this way:

```text
ACTION=="add", SUBSYSTEM=="block", TAG+="systemd", ENV{SYSTEMD_WANTS}="device-attach.service"
```

That rule means that udev will trigger `device-attach.service` systemd unit on any block device attachment. Now when we use this command `virsh attach-disk coreos /dev/VG/test vdc` on host machine, we should see `device has been attached` message in Flatcar Container Linux node's journal. This example should be similar to USB/SAS/SATA device attach.

## Butane Config example

To use the unit and udev rule with a Container Linux Config, modify this example as needed:

```yaml
variant: flatcar
version: 1.0.0
storage:
  files:
    - path: /etc/udev/rules.d/01-block.rules
      mode: 0644
      contents:
        inline: |
          ACTION=="add", SUBSYSTEM=="block", TAG+="systemd", ENV{SYSTEMD_WANTS}="device-attach.service"
systemd:
  units:
    - name: device-attach.service
      contents: |
        [Unit]
        Description=Notify about attached device

        [Service]
        Type=oneshot
        ExecStart=/usr/bin/echo 'device has been attached'
```

## More systemd examples

For more systemd examples, check out these documents:

 * [Customizing Docker][customizing-docker]
 * [Customizing the SSH Daemon][customizing-sshd]
 * [Using systemd Drop-In Units][drop-in]

[drop-in]: drop-in-units
[customizing-sshd]: ../security/customizing-sshd#changing-the-sshd-port
[customizing-docker]: ../../container-runtimes/customizing-docker#using-a-dockercfg-file-for-authentication

## More information

<a class="btn btn-default" href="http://www.freedesktop.org/software/systemd/man/systemd.service.html">systemd.service Docs</a>
<a class="btn btn-default" href="http://www.freedesktop.org/software/systemd/man/systemd.unit.html">systemd.unit Docs</a>
<a class="btn btn-default" href="http://www.freedesktop.org/software/systemd/man/systemd.target.html">systemd.target Docs</a>
<a class="btn btn-default" href="http://www.freedesktop.org/software/systemd/man/udev.html">udev Docs</a>
