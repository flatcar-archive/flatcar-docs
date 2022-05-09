---
title: Switching release channels
description: How to switch to a different release channel.
weight: 10
aliases:
    - ../../os/switching-channels
    - ../../clusters/management/switching-channels
---

Flatcar Container Linux is designed to be updated automatically with different schedules per channel. You can [disable this feature](update-strategies), although we don't recommend it.
Read the [release notes](https://flatcar-linux.org/releases) for specific features, bug fixes, and changes.
A new major release always starts in the Alpha channel - which is for developers - where it passes multiple feature and bug fix iterations.
Roughly every second major Alpha release is promoted to the Beta channel; the promotion is based on stability and on feature completeness.
The Beta channel is for user consumption, so operators can validate compatibility with user workloads.
In Beta, the release passes additional iterations and eventually fully stabilises, receiving bug fixes addressing issues with user workloads.
Roughly every second major Beta release is promoted to Stable.
Thus, the Stable channel gets no brand new major releases but instead gets the bug fix release of a new major release. It then continues to get bug fix releases.
Any Stable major version remains supported until a new major Stable version is released.
We generally recommend operators to follow releases in the Stable channel, with a few nodes on Beta for workload validation.
Beta is generally considered ready for production.
However, in edge cases new releases may show issues with certain user workloads.
The Beta channel is an opportunity to validate early and to give feedback, so potential issues are fixed before they hit Stable.
For low-maintenance scenarios there is the LTS channel which only gets bug fix releases.
New major releases come out around once per year, marking a new LTS stream, and there is an overlap where the old stream still gets critical security updates.

![Update Timeline](../../img/update-timeline.png)

By default, Flatcar uses the public update server `public.update.flatcar-linux.net`.
It promotes the new releases for each channel at the same time they are published.
If you need more control about the update rollout, you can have a look at the possible [reboot strategies and manual update methods](update-strategies).
The other alternative is running your own update server which allows you to control the update rollout over your fleet and even divide it into groups that have different rollout policies and release versions.
The [Nebraska](nebraska) Open Source project implements the update server and is also used for our public instance.
More on it below and on the Nebraska [docs site](nebraska-docs).

## Customizing channel configuration

An installed image will by default follow the channel it was published in.
The cloud vendor images (e.g., Alpha, Beta, Stable) and the installer option (`flatcar-install -C <channel>`) are the recommended way of selecting the last release of a channel.
The update client `update-engine` sources its configuration from `/usr/share/flatcar/update.conf` (baked into the image) and `/etc/flatcar/update.conf` (for user overwrites).
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

### Freezing an LTS stream

A new LTS major version / stream is released roughly once per year.
Each LTS major release stream has an 18 month support cycle, so there's a 6 month overlap between new major releases.

The public update channel `GROUP=lts` points to the current LTS release stream.
This means that it always provides the latest LTS release and, therefore, by default a major version jump happens when, e.g., the current LTS stream is switched over from `lts-2021` to `lts-2022`.
Since this can be disruptive depending on the customizations and deployed software, the recommendation is to freeze the LTS stream on deployment and manually switch to a newer LTS stream at one's own pace each year.

The entry in `/etc/flatcar/update.conf` to opt-out of major version updates can be added via Ignition or manually (here for only receiving updates for the LTS 2022 stream, i.e., release major version 3033):

```
GROUP=lts-2022
```

An alternative is to manage the update rollout through an own Nebraska update server where your manage your own `lts` group (see below).

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

## Use a personal update server

When setting up your own [Nebraska](nebraska) update server you will be able to point your Flatcar machines to fetch its updates from it.
Nebraska's web interface allows to create custom groups that are used to specify update rollout policies, and custom channels that specify the Flatcar version.
Multiple groups can point to the same channel. The Nebraska web interface also gives an overview about the machines and their update status.

It is recommended to start Nebraska with the `-enable-syncer` flag which keeps the Stable, Beta, Alpha, and LTS channels in sync with the public server.
The default sync interval is one hour but may be shortened (Nebraska option `-sync-interval`). You need to create the `lts-2022` and similar channels if they don't exist on your instance.
To specify a particular Flatcar version you want to deploy, you should not modify the `stable` *channel* because this gets synced with the public server and your changes are lost.
You should rather create a new channel and let the `stable` *group* point to it.
When using your own Nebraska update server, the `lts` group is not switched over to point a new `lts-YEAR` channel when a new channel comes out.
To migrate the machines to the new LTS major release, first create the `lts-YEAR` channel on your instance since it may not exist, wait for the syncing to pick up the latest version for the channel, and then let the `lts` group point to the new channel.
This needs to be done manually in Nebraska and it offers the advantage that the `lts` group which is the default for LTS installations can be kept and no changes on the machines themselves are necessary.

For machines with restricted Internet access the Nebraska `-host-flatcar-packages` option lets Nebraska store the update payloads locally when syncing from the public server, and the machines will get your Nebraska's URL to fetch them.

Here is how to configure a machine through `/etc/flatcar/update.conf` to get updates from your personal Nebraska server:

```
SERVER=http://your.nebraska.host:port/v1/update/
GROUP=myproduction
```

More specifics about Nebraska can be found on its [docs site](nebraska-docs).


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

[nebraska]: https://github.com/kinvolk/nebraska/
[nebraska-docs]: https://kinvolk.io/docs/nebraska/latest
