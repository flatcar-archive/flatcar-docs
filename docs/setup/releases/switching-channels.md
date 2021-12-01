---
title: Switching release channels
description: How to switch to a different release channel.
weight: 10
aliases:
    - ../../os/switching-channels
    - ../../clusters/management/switching-channels
---

Flatcar Container Linux is designed to be updated automatically with different schedules per channel. You can [disable this feature](update-strategies), although we don't recommend it. Read the [release notes](https://flatcar-linux.org/releases) for specific features and bug fixes.

![Update Timeline](../../img/update-timeline.png)

## Customizing channel configuration

The update engine sources its configuration from `/usr/share/flatcar/update.conf` and `/etc/flatcar/update.conf`.
The former file contains the default hardcoded configuration from the running OS version. Its values cannot be edited, but they can be overridden by the ones in the latter file.

To switch a machine to a different channel, specify the new channel group in `/etc/flatcar/update.conf`:

```ini
GROUP=beta
```

The machine should check for an update within an hour.

The public Nebraska update service does not offer downgrades.
If you're switching from a channel with a higher Flatcar Container Linux version than the new channel, your machine won't be updated again until the new channel contains a higher version number.
To force an update, use the `flatcar-update` tool (see below) or overwrite your current version.

If you don't use `flatcar-update`, overwrite your version with these steps to force a downgrade:

```shell
sudo rm -f /tmp/release
sudo umount /usr/share/coreos/release || true
cp /usr/share/coreos/release /tmp/release
sed -E -i "s/(COREOS_RELEASE_VERSION=)(.*)/\10.0.0/" /tmp/release
sudo mount --bind /tmp/release /usr/share/coreos/release
```

**Note:** After the update is downloaded and the system is ready to reboot, remove the `GROUP` entry again from `/etc/flatcar/update.conf` because the new update has it as default and there is no need to hardcode it there.

## Jump to another channel with `flatcar-update`

With the `flatcar-update` tool you can jump to any release, also from other channels, making you effectively switch the channel. It's worth checking that you didn't hardcode a particular channel as `GROUP` in `/etc/flatcar/update.conf`.

```shell
$ # In case another channel is set as GROUP, first remove it so that in the future the channel from the new release gets used:
$ sudo sed -i "/GROUP=.*/d" /etc/flatcar/update.conf
$ # Set the channel you want to jump to:
$ CHANNEL=beta
$ VER=$(curl -fsSL "https://$CHANNEL.release.flatcar-linux.net/amd64-usr/current/version.txt" | grep FLATCAR_VERSION= | cut -d = -f 2)
$ sudo flatcar-update --to-version "$VER"
```

## Debugging

The live status of updates checking can queried via:

```shell
update_engine_client --status
```

The update engine logs all update attempts, which can inspected in the system journal:

```shell
journalctl -f -u update-engine
```

For reference, the OS version and channel for a running system can be determined via:

```shell
cat /usr/share/flatcar/os-release
cat /usr/share/flatcar/update.conf
```

Note: while a manual channel switch is in progress, `/usr/share/flatcar/update.conf` shows the channel for the current OS while `/etc/flatcar/update.conf` shows the one for the next update.
