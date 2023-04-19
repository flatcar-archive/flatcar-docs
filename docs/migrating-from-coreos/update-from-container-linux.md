---
title: Updating from CoreOS Container Linux
linktitle: Updating from CoreOS
weight: 10
aliases:
    - ../os/update-from-container-linux
---

If you already have CoreOS Container Linux clusters and can't or don't want to freshly install Flatcar Container Linux, you can update to Flatcar Container Linux directly from CoreOS Container Linux by performing the following steps.

**NOTE:** General differences when [migrating from CoreOS Container Linux][migrate-from-container-linux] also apply.


## The migration script

The [update-to-flatcar.sh](https://raw.githubusercontent.com/flatcar/flatcar-docs/main/update-to-flatcar.sh) script does all required steps for you:

```shell
# To be run on the node via SSH
core@host ~ $ wget https://raw.githubusercontent.com/flatcar/flatcar-docs/main/update-to-flatcar.sh
core@host ~ $ less update-to-flatcar.sh # Double check the content of the script
core@host ~ $ chmod +x update-to-flatcar.sh
core@host ~ $ ./update-to-flatcar.sh
[…]
Done, please reboot now
core@host ~ $ sudo systemctl reboot
```

If it fails due to SSL connection issues from outdated certificates, you can also download the update payload of the latest Stable release through plain HTTP and use the `flatcar-update` script instead:

```shell
$ VER=$(curl -fsSL --insecure --ssl-no-revoke http://stable.release.flatcar-linux.net/amd64-usr/current/version.txt | grep FLATCAR_VERSION= | cut -d = -f 2)
$ wget --no-check-certificate "http://update.release.flatcar-linux.net/amd64-usr/$VER/flatcar_production_update.gz"
$ wget --no-check-certificate http://raw.githubusercontent.com/flatcar/init/flatcar-master/bin/flatcar-update
$ less flatcar-update # Double check the content of the script
$ chmod +x flatcar-update
$ sudo ./flatcar-update --to-version "$VER" --to-payload flatcar_production_update.gz --force-flatcar-key
```

**Before you reboot, check that you migrated the variable names as written in [Migrating from CoreOS Container Linux](migrate-from-container-linux).**

## Going back to CoreOS Container Linux

You can also go the other way.

### Manual rollback

If you just updated to Flatcar (and haven't done any additional updates), CoreOS Container Linux will still be on your disk, you just need to roll back to the other partition.

To do that, just use this command composition:

```shell
sudo cgpt prioritize "$(sudo cgpt find -t flatcar-usr | grep --invert-match "$(rootdev -s /usr)")"
```

Now you can reboot and you'll be back to CoreOS Container Linux.
Remember to undo your changes in your `/etc/coreos/update.conf` after rolling back if you want to keep getting CoreOS Container Linux updates.

For more information about manual rollbacks, check [Performing a manual rollback][manual-rollback].

### Force an update to CoreOS Container Linux

This procedure is similar to updating from CoreOS Container Linux to Flatcar Container Linux.
You need to get CoreOS Container Linux's public key, point update_engine to CoreOS Container Linux's update server, and force an update.

Get CoreOS Container Linux's public key:

```shell
curl -L -o /tmp/key https://raw.githubusercontent.com/coreos/coreos-overlay/master/coreos-base/coreos-au-key/files/official-v2.pub.pem
```

Bind-mount it:

```shell
sudo mount --bind /tmp/key /usr/share/update_engine/update-payload-key.pub.pem
```

Create an `/etc/flatcar` directory and copy the current update configuration:

```shell
sudo mkdir -p /etc/flatcar
sudo cp /etc/coreos/update.conf /etc/flatcar/
```

Change the `SERVER` field in `/etc/flatcar/update.conf`:

```shell
SERVER=https://public.update.core-os.net/v1/update/
```

Bind-mount the release file:

```shell
cp /usr/share/flatcar/release /tmp
sudo mount --bind /tmp/release /usr/share/flatcar/release
```

Edit `FLATCAR_RELEASE_VERSION` to force an update:

```shell
FLATCAR_RELEASE_VERSION=0.0.0
```

After that, restart the update service so it rescans the edited configuration and initiates an update.
The system will reboot into CoreOS Container Linux:

```shell
sudo update_engine_client -update
```

[migrate-from-container-linux]: _index.md
[manual-rollback]: ../setup/debug/manual-rollbacks/#performing-a-manual-rollback
