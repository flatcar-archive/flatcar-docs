---
title: Handle ACPI events
linktitle: ACPI
description: Enable acpid and handle ACPI events
weight: 60
---

## acpid

Beginning with Flatcar major release 3255 `acpid` can be enabled at boot with Ignition.

This can be configured with a [butane][butane] definition:

```yaml
---
variant: flatcar
version: 1.0.0
systemd:
  units:
    - name: acpid.service
      enabled: true
storage:
  files:
    - path: /etc/acpi/events/default
      contents:
        inline: |
          event=.*
          action=/etc/acpi/default.sh %e

    - path: /etc/acpi/default.sh
      contents:
        inline: |
          set $*
          logger "ACPI event handled: $*"
      mode: 0744
```

This simple configuration will only log the handled ACPI events, example with QEMU:

```bash
butane < config.yml > ignition.json
./flatcar_production_qemu.sh -i ./ignition.json -- -qmp tcp:localhost:4444,server,wait=off
```

From another terminal, it's possible to send a shutdown signal for example:
```bash
telnet localhost 4444
{ "execute": "qmp_capabilities" }
{ "execute": "system_powerdown" }
```

From the `acpid` logs, it's possible to see the logger in action:
```bash
$ journalctl --unit acpid.service
May 24 14:29:36 localhost systemd[1]: Started ACPI event daemon.
May 24 14:29:36 localhost acpid[928]: starting up with netlink and the input layer
May 24 14:29:36 localhost acpid[928]: 1 rule loaded
May 24 14:29:36 localhost acpid[928]: waiting for events: event logging is off
May 24 14:30:20 localhost root[1041]: ACPI event handled: button/power PBTN 00000080 00000000
May 24 14:30:20 localhost systemd[1]: Stopping ACPI event daemon...
May 24 14:30:20 localhost acpid[928]: exiting
May 24 14:30:20 localhost systemd[1]: acpid.service: Deactivated successfully.
May 24 14:30:20 localhost systemd[1]: Stopped ACPI event daemon.
```

## qemu-guest-agent

Beginning with Flatcar major release 3402, qemu-guest-agent is part of all images and can handle certain lifecycle operations without acpid. The agent service will automatically be enabled if a virtio-port with the name `org.qemu.guest_agent.0` is detected. For Openstack it is necessary to launch the instance with `hw_qemu_guest_agent=yes` set.

[butane]: ../../provisioning/ignition/specification/#ignition-v3
