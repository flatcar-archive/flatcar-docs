# Updating from Container Linux

If you already have Countainer Linux clusters and can't or don't want to freshly install Flatcar Linux, you can update to Flatcar Linux directly from Container Linux by performing the following steps.

## Getting the public update key

First, you need to get Flatcar's public update key:

```
$ curl -L -o /tmp/key https://raw.githubusercontent.com/flatcar-linux/coreos-overlay/flatcar-master/coreos-base/coreos-au-key/files/official-v2.pub.pem
```

Since the `/usr` partition is read-only, to allow the updater to use the new key, you need to bind-mount it:

```
$ sudo mount --bind /tmp/key /usr/share/update_engine/update-payload-key.pub.pem
```

## Modifying the configuration files

Now, you need to point update_engine to Flatcar's update server by setting the `SERVER` configuration option in `/etc/coreos/update.conf`:

```
SERVER=https://public.update.flatcar-linux.net/v1/update/
```

To make sure you get an update even if you're running the same Container Linux version as the latest Flatcar Linux, you need to force an update by clearing the current version number from the `release` file.
This file also lives in the `/usr` partition so you need to do a bind-mount again:

```
$ cp /usr/share/coreos/release /tmp
$ sudo mount --bind /tmp/release /usr/share/coreos/release
```

Then, you need to edit `/usr/share/coreos/release` and replace the value of `COREOS_RELEASE_VERSION` with `0.0.0`:

```
COREOS_RELEASE_VERSION=0.0.0
```

**NOTE:** In bare metal installations, the path where `user_data` is expected changes from `/var/lib/coreos-install/user_data` to `/var/lib/flatcar-install/user-data`. Make sure you place your `user_data` in the new path.

## Restart service and reboot

After that, restart the update service so it rescans the edited configuration and initiates an update.
The system will reboot into Flatcar Linux:

```
$ sudo systemctl restart update-engine
$ update_engine_client -update
```

## Going back to Container Linux

You can also go the other way.

### Manual rollback

If you just updated to Flatcar (and haven't done any additional updates), Container Linux will still be on your disk, you just need to roll back to the other partition.

To do that, just use this command composition:

```
$ sudo cgpt prioritize "$(sudo cgpt find -t coreos-usr | grep --invert-match "$(rootdev -s /usr)")"
```

Now you can reboot and you'll be back to Container Linux.
Remember to undo your changes in your `/etc/coreos/update.conf` after rolling back if you want to keep getting Container Linux updates.

For more information about manual rollbacks, check [Performing a manual rollback](https://coreos.com/os/docs/latest/manual-rollbacks.html#performing-a-manual-rollback).

### Force an update to Container Linux

This procedure is similar to updating from Container Linux to Flatcar linux.
You need to get Container Linux's public key, point update_engine to Container Linux's update server, and force an update.

Get Container Linux's public key:

```
$ curl -L -o /tmp/key https://raw.githubusercontent.com/coreos/coreos-overlay/master/coreos-base/coreos-au-key/files/official-v2.pub.pem
```

Bind-mount it:

```
$ sudo mount --bind /tmp/key /usr/share/update_engine/update-payload-key.pub.pem
```

Create an `/etc/flatcar` directory and copy the current update configuration:

```
$ sudo mkdir -p /etc/flatcar
$ sudo cp /etc/coreos/update.conf /etc/flatcar/
```

Change the `SERVER` field in `/etc/flatcar/update.conf`:

```
SERVER=https://public.update.core-os.net/v1/update/
```

Bind-mount the release file:

```
$ cp /usr/share/flatcar/release /tmp
$ sudo mount --bind /tmp/release /usr/share/flatcar/release
```

Edit `FLATCAR_RELEASE_VERSION` to force an update:

```
FLATCAR_RELEASE_VERSION=0.0.0
```

After that, restart the update service so it rescans the edited configuration and initiates an update.
The system will reboot into Container Linux:

```
$ sudo systemctl restart update-engine
$ update_engine_client -update
```
