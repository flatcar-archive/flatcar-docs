# Building custom kernel modules

## Create a writable overlay

The kernel modules directory `/usr/lib64/modules` is read-only on Flatcar Linux. A writable overlay can be mounted over it to allow installing new modules.

```sh
modules=/opt/modules  # Adjust this writable storage location as needed.
sudo mkdir -p "$modules" "$modules.wd"
sudo mount \
    -o "lowerdir=/usr/lib64/modules,upperdir=$modules,workdir=$modules.wd" \
    -t overlay overlay /usr/lib64/modules
```

The following systemd unit can be written to `/etc/systemd/system/usr-lib64-modules.mount`.

```ini
[Unit]
Description=Custom Kernel Modules
Before=local-fs.target
ConditionPathExists=/opt/modules

[Mount]
Type=overlay
What=overlay
Where=/usr/lib64/modules
Options=lowerdir=/usr/lib64/modules,upperdir=/opt/modules,workdir=/opt/modules.wd

[Install]
WantedBy=local-fs.target
```

Enable the unit so this overlay is mounted automatically on boot.

```sh
sudo systemctl enable usr-lib64-modules.mount
```

## Prepare a Flatcar Linux development container

Read system configuration files to determine the URL of the development container that corresponds to the current Flatcar Linux version.

```sh
. /usr/share/coreos/release
. /usr/share/coreos/update.conf
url="https://${GROUP:-stable}.release.flatcar-linux.net/$FLATCAR_RELEASE_BOARD/$FLATCAR_RELEASE_VERSION/flatcar_developer_container.bin.bz2"
```

Download, decompress, and verify the development container image.

```sh
gpg2 --keyserver pool.sks-keyservers.net --recv-keys F88CFEDEFF29A5B4D9523864E25D9AED0593B34A  # Fetch the buildbot key if necessary.
curl -L "$url" |
    tee >(bzip2 -d > flatcar_developer_container.bin) |
    gpg2 --verify <(curl -Ls "$url.sig") -
```

Start the development container with the host's writable modules directory mounted into place.

```sh
sudo systemd-nspawn \
    --bind=/usr/lib64/modules \
    --image=flatcar_developer_container.bin
```

Now, inside the container, fetch the Flatcar Linux package definitions, then download and prepare the Linux kernel source for building external modules.

```sh
emerge-gitclone
emerge -gKv coreos-sources
gzip -cd /proc/config.gz > /usr/src/linux/.config
make -C /usr/src/linux modules_prepare
```

## Build and install kernel modules

At this point, upstream projects' instructions for building their out-of-tree modules should work in the Flatcar Linux development container. New kernel modules should be installed into `/usr/lib64/modules`, which is bind-mounted from the host, so they will be available on future boots without using the container again.

In case the installation step didn't update the module dependency files automatically, running the following command will ensure commands like `modprobe` function correctly with the new modules.

```sh
sudo depmod
```
