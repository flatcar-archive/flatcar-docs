---
title: Using systemd drop-in units
linktitle: Drop-In Units
description: How to customize the running system by using drop-in units.
weight: 20
aliases:
    - ../../os/using-systemd-drop-in-units
    - ../../clusters/customization/using-systemd-drop-in-units
---

There are two methods of overriding default Flatcar Container Linux settings in unit files: copying the unit file from `/usr/lib64/systemd/system` to `/etc/systemd/system` and modifying the chosen settings. Alternatively, one can create a directory named `unit.d` within `/etc/systemd/system` and place a drop-in file `name.conf` there that only changes the specific settings one is interested in. Note that multiple such drop-in files are read if present.

The advantage of the first method is that one easily overrides the complete unit, the default Flatcar Container Linux unit is not parsed at all anymore. It has the disadvantage that improvements to the unit file supplied by Flatcar Container Linux are not automatically incorporated on updates.

The advantage of the second method is that one only overrides the settings one specifically wants, where updates to the original Flatcar Container Linux unit automatically apply. This has the disadvantage that some future Flatcar Container Linux updates might be incompatible with the local changes, but the risk is much lower.

Note that for drop-in files, if one wants to remove entries from a setting that is parsed as a list (and is not a dependency), such as `ConditionPathExists=` (or e.g. `ExecStart=` in service units), one needs to first clear the list before re-adding all entries except the one that is to be removed. See below for an example.

This also applies for user instances of systemd, but with different locations for the unit files. See the section on unit load paths in [official systemd doc](http://www.freedesktop.org/software/systemd/man/systemd.unit.html) for further details.

## Example: customizing locksmithd.service

Let's review `/usr/lib64/systemd/system/locksmithd.service` unit (you can find it using this command: `systemctl list-units | grep locksmithd`) with the following contents:

```ini
[Unit]
Description=Cluster reboot manager
After=update-engine.service
ConditionVirtualization=!container
ConditionPathExists=!/usr/.noupdate

[Service]
CPUShares=16
MemoryLimit=32M
PrivateDevices=true
Environment=GOMAXPROCS=1
EnvironmentFile=-/usr/share/flatcar/update.conf
EnvironmentFile=-/etc/flatcar/update.conf
ExecStart=/usr/lib/locksmith/locksmithd
Restart=on-failure
RestartSec=10s

[Install]
WantedBy=multi-user.target
```

Let's walk through increasing the `RestartSec` parameter via both methods:

### Override only specific option

You can create a drop-in file `/etc/systemd/system/locksmithd.service.d/10-restart_60s.conf` with the following contents:

```ini
[Service]
RestartSec=60s
```

Then reload systemd, scanning for new or changed units:

```shell
systemctl daemon-reload

```

And restart modified service if necessary (in our example we have changed only `RestartSec` option, but if you want to change environment variables, `ExecStart` or other run options you have to restart service):

```shell
systemctl restart locksmithd.service
```

Here is how that could be implemented within a Butane Config:

```yaml
variant: flatcar
version: 1.0.0
systemd:
  units:
    - name: locksmithd.service
      enabled: true
      dropins:
        - name: 10-restart_60s.conf
          contents: |
            [Service]
            RestartSec=60s
```

This change is small and targeted. It is the easiest way to tweak unit's parameters.

### Override the whole unit file

Another way is to override whole systemd unit. Copy default unit file `/usr/lib64/systemd/system/locksmithd.service` to `/etc/systemd/system/locksmithd.service` and change the chosen settings:

```ini
[Unit]
Description=Cluster reboot manager
After=update-engine.service
ConditionVirtualization=!container
ConditionPathExists=!/usr/.noupdate

[Service]
CPUShares=16
MemoryLimit=32M
PrivateDevices=true
Environment=GOMAXPROCS=1
EnvironmentFile=-/usr/share/flatcar/update.conf
EnvironmentFile=-/etc/flatcar/update.conf
ExecStart=/usr/lib/locksmith/locksmithd
Restart=on-failure
RestartSec=60s

[Install]
WantedBy=multi-user.target
```

Butane Config example:

```yaml
variant: flatcar
version: 1.0.0
systemd:
  units:
    - name: locksmithd.service
      enabled: true
      contents: |
        [Unit]
        Description=Cluster reboot manager
        After=update-engine.service
        ConditionVirtualization=!container
        ConditionPathExists=!/usr/.noupdate

        [Service]
        CPUShares=16
        MemoryLimit=32M
        PrivateDevices=true
        Environment=GOMAXPROCS=1
        EnvironmentFile=-/usr/share/flatcar/update.conf
        EnvironmentFile=-/etc/flatcar/update.conf
        ExecStart=/usr/lib/locksmith/locksmithd
        Restart=on-failure
        RestartSec=60s

        [Install]
        WantedBy=multi-user.target
```

### List drop-ins

To see all runtime drop-in changes for system units run the command below:

```shell
systemd-delta --type=extended
```

## Other systemd examples

For more examples using systemd customization, check out these documents:

 * [Customizing Docker](../../container-runtimes/customizing-docker#using-a-dockercfg-file-for-authentication)
 * [Customizing the SSH Daemon](../security/customizing-sshd#changing-the-sshd-port)
 * [Using Environment Variables in systemd Units](using-environment-variables-in-systemd-units)

## More Information

<a class="btn btn-default" href="http://www.freedesktop.org/software/systemd/man/systemd.service.html">systemd.service Docs</a>
<a class="btn btn-default" href="http://www.freedesktop.org/software/systemd/man/systemd.unit.html">systemd.unit Docs</a>
<a class="btn btn-default" href="http://www.freedesktop.org/software/systemd/man/systemd.target.html">systemd.target Docs</a>
