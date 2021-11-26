---
title: Reboot strategies on updates
description: How to configure when you Flatcar instances should reboot.
weight: 30
aliases:
    - ../../os/update-strategies
    - ../../clusters/creation/update-strategies
---

The overarching goal of Flatcar Container Linux is to secure the Internet's backend infrastructure. We believe that automatically updating the operating system is one of the best tools to achieve this goal.

We realize that each Flatcar Container Linux cluster has a unique tolerance for risk and the operational needs of your applications are complex. In order to meet everyone's needs, there are three update strategies that we have developed based on feedback during our alpha period.

It's important to note that updates are always downloaded to the passive partition when they become available. A reboot is the last step of the update, where the active and passive partitions are swapped ([rollback instructions][rollback]). These strategies control how that reboot occurs:

| Strategy      | Description                                                         |
|---------------|---------------------------------------------------------------------|
| `etcd-lock`   | Reboot after first taking a distributed lock in etcd                |
| `reboot`      | Reboot immediately after an update is applied                       |
| `off`         | Do not reboot after updates are applied                             |

## Reboot strategy options

The reboot strategy can be set with a Container Linux Config:

```yaml
locksmith:
  reboot_strategy: "etcd-lock"
```

### etcd-lock

The `etcd-lock` strategy mandates that each machine acquire and hold a reboot lock before it is allowed to reboot. The main goal behind this strategy is to allow for an update to be applied to a cluster quickly, without losing the quorum membership in etcd or rapidly reducing capacity for the services running on the cluster. The reboot lock is held until the machine releases it after a successful update.

The number of machines allowed to reboot simultaneously is configurable via a command line utility:

```shell
$ locksmithctl set-max 4
Old: 1
New: 4
```

This setting is stored in etcd so it won't have to be configured for subsequent machines.

To view the number of available slots and find out which machines in the cluster are holding locks, run:

```shell
$ locksmithctl status
Available: 0
Max: 1

MACHINE ID
69d27b356a94476da859461d3a3bc6fd
```

If needed, you can manually clear a lock by providing the machine ID:

```shell
locksmithctl unlock 69d27b356a94476da859461d3a3bc6fd
```

### Reboot immediately

The `reboot` strategy works exactly like it sounds: the machine is rebooted as soon as the update has been installed to the passive partition. If the applications running on your cluster are highly resilient, this strategy was made for you.

### Off

The `off` strategy is also straightforward. The update will be installed onto the passive partition and await a reboot command to complete the update. We don't recommend this strategy unless you reboot frequently as part of your normal operations workflow.

## Updating PXE/iPXE machines

PXE/iPXE machines download a new copy of Flatcar Container Linux every time they are started thus are dependent on the version of Flatcar Container Linux they are served. If you don't automatically load new Flatcar Container Linux images into your PXE/iPXE server, your machines will never have new features or security updates.

An easy solution to this problem is to use iPXE and reference images [directly from the Flatcar Container Linux storage site][ipxe-boot-script]. The `alpha` URL is automatically pointed to the new version of Flatcar Container Linux as it is released.

## Disable Automatic Updates

If for a short time frame you want to temporarily disable update reboots, run `sudo systemctl stop update-engine locksmithd`, and when done, `sudo systemctl start update-engine locksmithd`.

In case when you want to permanently disable automatic updates, it's not recommended to mask the services because it makes it harder to manually apply updates.
It's rather recommended to overwrite the `SERVER` variable in the update configuration to an invalid value.

You can configure this with a Container Linux Config (needs to be [transpiled][transpiler] to Ignition JSON):

```yaml
storage:
  files:
    - path: /etc/flatcar/update.conf
      mode: 0644
      contents:
        inline: |
          SERVER=disabled
```

To manually run updates, remove the file and run `update_engine_client -update` or wait for the update to happen.
After update-engine applied the update to the passive partition, you can already create the file again to disable automatic updates.
Wait for the reboot to happen or invoke it manually.

As alternative you could mask the update-engine and locksmithd services as follows (but read the warning below):

```
systemd:
  units:
    - name: update-engine.service
      mask: true
    - name: locksmithd.service
      mask: true
```

**Note:** As said, it's not recommended to mask the services but if you want to manually trigger an update after having masked `update-engine`,
you'll need to unmask the service, start `update-engine` to trigger an update, and
**keep the service unmasked** until the next reboot is completed and `update-engine` started
and marked the updated partition as successful.
Otherwise, the update will be considered unsuccessful and in all following reboots GRUB will use the
old partition again because `update-engine` never marked the new partition to be successfully booted.

To check that you can stop and mask `update-engine` after the reboot, run these commands to see that
the partition was marked as successful. This will happen after the service ran for about 1 minute:

```shell
$ sudo cgpt show "$(rootdev -s /usr)" | grep successful=1
                                  Attr: priority=1 tries=0 successful=1
```

## Updating behind a proxy

Public Internet access is required to contact CoreUpdate and download new versions of Flatcar Container Linux. If direct access is not available the `update-engine` service may be configured to use a HTTP or SOCKS proxy using curl-compatible environment variables, such as `HTTPS_PROXY` or `ALL_PROXY`.
See [curl's documentation](http://curl.haxx.se/docs/manpage.html#ALLPROXY) for details.

```yaml
systemd:
  units:
    - name: update-engine.service
      dropins:
        - name: 50-proxy.conf
          contents: |
            [Service]
            Environment=ALL_PROXY=http://proxy.example.com:3128
```

Proxy environment variables can also be set [system-wide][systemd-env-vars].

## Manually triggering an update

Each machine should check in about 10 minutes after boot and roughly every hour after that. If you'd like to see it sooner, you can force an update check, which will skip any rate-limiting settings that are configured in CoreUpdate.

```shell
$ update_engine_client -check_for_update
[0123/220706:INFO:update_engine_client.cc(245)] Initiating update check and install.
```

### Double update workaround

If you have disabled automatic reboots, and your host has already applied an update then your flatcar host will not apply a _newer_ update until it has rebooted into the prior-applied update.
( i.e. Host is in `UPDATE_STATUS_UPDATED_NEED_REBOOT` state).
To work around this intermediate reboot, one can call:

```shell
update_engine_client -reset_status
update_engine_client -check_for_update
```

## Auto-updates with a maintenance window

Locksmith supports maintenance windows in addition to the reboot strategies mentioned earlier. Maintenance windows define a window of time during which a reboot can occur. These operate in addition to reboot strategies, so if the machine has a maintenance window and requires a reboot lock, the machine will only reboot when it has the lock during that window.

Windows are defined by a start time and a length. In this example, the window is defined to be every Thursday between 04:00 and 05:00:

```yaml
locksmith:
  reboot_strategy: reboot
  window_start: Thu 04:00
  window_length: 1h
```

This will configure a Flatcar Container Linux machine to follow the `reboot` strategy, and thus when an update is ready it will simply reboot instead of attempting to grab a lock in etcd. This machine however has also been configured to only reboot between 04:00 and 05:00 on Thursdays, so if an update occurs outside of this window the machine will then wait until it is inside of this window to reboot.

For more information about the supported syntax, refer to the [Locksmith documentation][reboot-windows].

[ipxe-boot-script]: ../../installing/bare-metal/booting-with-ipxe#setting-up-ipxe-boot-script
[rollback]: ../debug/manual-rollbacks
[reboot-windows]: https://github.com/kinvolk/locksmith#reboot-windows
[systemd-env-vars]: ../systemd/environment-variables/#system-wide-environment-variables
[transpiler]: ../../provisioning/config-transpiler/
