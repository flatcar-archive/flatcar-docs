---
title: Tips and tricks
weight: 10
aliases:
    - ../../os/sdk-tips-and-tricks
---

## Finding all open pull requests and issues

- [Flatcar Container Linux Issues][issues]
- [Flatcar Container Linux Pull Requests][pullrequests]

[issues]: https://github.com/issues?user=flatcar-linux
[pullrequests]: https://github.com/pulls?user=flatcar-linux

## Searching all repo code

Using `repo grep` you can search across all of the Git repos at once:

```shell
repo grep CONFIG_EXTRA_FIRMWARE
```

Note: this could take some time.

### Base system dependency graph

Get a view into what the base system will contain and why it will contain those things with the emerge tree view:

```shell
equery-amd64-usr depgraph --depth 1 coreos-base/coreos-dev
```

Get a tree view of the SDK dependencies:

```shell
equery depgraph --depth 1 coreos-base/hard-host-depends coreos-devel/sdk-depends
```

### Import ebuilds from Gentoo

You can use `scripts/update_ebuilds` to fetch unmodified packages into `src/third_party/portage-stable` and add the files to git. The package argument should be in the format of `category/package-name`, e.g.:

```shell
~/trunk/src/scripts $ ./update_ebuilds sys-block/open-iscsi
```

Modified packages must be moved out of `src/third_party/portage-stable` to `src/third_party/coreos-overlay`.

If you know in advance that any files in the upstream package will need to be changed, the package can be fetched from upstream Gentoo directly into `src/third_party/coreos-overlay`. e.g.:

```shell
~/trunk/src/third_party/coreos-overlay $ mkdir -p sys-block/open-iscsi
~/trunk/src/third_party/coreos-overlay $ rsync -av rsync://rsync.gentoo.org/gentoo-portage/sys-block/open-iscsi/ sys-block/open-iscsi/
```

The tailing / prevents rsync from creating the directory for the package so you don't end up with `sys-block/open-iscsi/open-iscsi`. Remember to add any new files to git.

To quickly test your new package(s), use the following commands:

```shell
~/trunk/src/scripts $ # Manually merge a package in the chroot
~/trunk/src/scripts $ emerge-amd64-usr packagename
~/trunk/src/scripts $ # Manually unmerge a package in the chroot
~/trunk/src/scripts $ emerge-amd64-usr --unmerge packagename
~/trunk/src/scripts $ # Remove a binary from the cache
~/trunk/src/scripts $ sudo rm /build/amd64-usr/packages/category/packagename-version.tbz2
```

To include the new package as a dependency of Flatcar Container Linux, add the package to the end of the `RDEPEND` environment variable in `coreos-base/coreos/coreos-0.0.1.ebuild` then increment the revision of Flatcar Container Linux by renaming the softlink (e.g.):

```shell
~/trunk/src/third_party/coreos-overly $ git mv coreos-base/coreos/coreos-0.0.1-r237.ebuild coreos-base/coreos/coreos-0.0.1-r238.ebuild
```

The new package will now be built and installed as part of the normal build flow when you run `build_packages` again.

If tests are successful, commit the changes, push to your GitHub fork and create a pull request.

[CONTRIBUTING]: https://github.com/flatcar/Flatcar#participate-and-contribute

### Packaging references

References:

- Chromium OS [Portage Build FAQ]
- [Gentoo Development Guide]
- [Package Manager Specification]

[Portage Build FAQ]: http://www.chromium.org/chromium-os/how-tos-and-troubleshooting/portage-build-faq
[Gentoo Development Guide]: http://devmanual.gentoo.org/
[Package Manager Specification]: https://wiki.gentoo.org/wiki/Package_Manager_Specification


#### Set a password for the core user (when building your own images)

Your SSH keys should be detected and added automatically by the image build process. Optionally, you can set a password for the `core` user which you can use later for ssh authentication, should SSH pubkey authentication not work for you.

After entering the SDK container for the first time (or after re-creating it), you can set user `core`'s password:

```shell
$ ./set_shared_user_password.sh
```

This is the password you will use to log into the console of images built with the SDK.

## Caching git https passwords

Turn on the credential helper and git will save your password in memory for some time:

```shell
git config --global credential.helper cache
```

Note: You need git 1.7.10 or newer to use the credential helper

Why doesn't Flatcar Container Linux use SSH in the git remotes?  Because we can't do anonymous clones from GitHub with an SSH URL.  This will be fixed eventually.

## SSH config

You will be booting lots of VMs with on the fly ssh key generation. Add this in your `$HOME/.ssh/config` to stop the annoying fingerprint warnings.

```ini
Host 127.0.0.1
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
  User core
  LogLevel QUIET
```

## Hide loop devices from desktop environments

By default desktop environments will diligently display any mounted devices including loop devices used to construct Flatcar Container Linux disk images. If the daemon responsible for this happens to be ``udisks`` then you can disable this behavior with the following udev rule:

```shell
echo 'SUBSYSTEM=="block", KERNEL=="ram*|loop*", ENV{UDISKS_PRESENTATION_HIDE}="1", ENV{UDISKS_PRESENTATION_NOPOLICY}="1"' > /etc/udev/rules.d/85-hide-loop.rules
udevadm control --reload
```

## Leaving developer mode

Some daemons act differently in "dev mode". For example update_engine refuses to auto-update or connect to HTTPS URLs. If you need to test something out of dev_mode on a vm you can do the following:

```shell
mv /root/.dev_mode{,.old}
```

If you want to permanently leave you can run the following:

```shell
crossystem disable_dev_request=1; reboot
```

## Re-initialise the SDK container

By default, the SDK container is re-used when using the `./run_sdk_container` script; all your changes within the container are preserved.
To reset the container, list all docker containers:
```shell
docker ps --all
…
00a133b61c55   ghcr.io/flatcar/flatcar-sdk-all:3087.0.0        "/bin/sh -c /home/sd…"   2 weeks ago   Exited (137) 11 days ago             flatcar-sdk-all-3087.0.0_os-alpha-3087.0.0-1-g39d915ae
…
```
and identify the SDK / OS image release version you've been working on.
Then delete the container:
```shell
docker container rm 00a133b61c55
```

The next run of `./run_sdk_container` will initialise a new container.

## Build everything from scratch

If you want to build everything from scratch, but at the same time want to exclude several packages that take much time.

```shell
emerge-amd64-usr --emptytree -1 -v --tree --exclude="dev-lang/rust sys-devel/gcc" coreos-base/coreos-dev
```

Or if you want to do the rebuild by running `build_packages`, you should remove the binary package of `coreos` before rebuilding it:

```shell
emerge-amd64-usr --unmerge coreos-base/coreos
rm -f /build/amd64-usr/var/lib/portage/pkgs/coreos-base/coreos-0.0.1*.tbz2
./build_packages
```

## Modify or update invididual packages

You can modify the package definitions in `third_party/coreos-overlay/`.
A complete and thorough guide for modifying packages is [here][mod-cl].
Changes for toolchain packages like the compiler need to be done to the SDK directly; `./setup_board` needs to be called after such changes (and ideally, the SDK should be rebuilt).
Any changes to the OS image only can be built by running `./build_packages && ./build_image`.
All build commands can be run multiple times but whether your last changes are picked up depends on whether the package revision
was increased (by renaming the ebuild file) or the package uninstalled and the binary package removed (See the last commands in
_Build everything from scratch_ where it was done for the parent package `coreos-base/coreos`).
Therefore, we recommend to run every build command only once in a fresh SDK to be sure that your most recent modification is used.

For some packages, like the Linux kernel in `coreos-source`, `coreos-kernel`, and `coreos-modules`, it is enough to rename
the ebuild file and it will download a new kernel version.
Ebuilds for other packages under `coreos-overlay/` reference a specific commit in `CROS_WORKON_COMMIT` which needs to be changed.
If files of a package changed their hash sums, use `ebuild packagename.ebuild manifest` to recalculate the hashes for
the `Manifest` file.

Here is an example of updating an individual package to a newer version:

```shell
git mv aaa-bbb/package/package-0.0.1-r1.ebuild aaa-bbb/package/package-0.0.1-r2.ebuild
ebuild aaa-bbb/package/package-0.0.1-r2.ebuild manifest
emerge-amd64-usr -1 -v aaa-bbb/package
```

Do not forget about updating its version and revision in `package.accept_keywords` files in the `profiles` directory.
In some cases such a file can pin an exact version of a specific package, which needs to be updated as well.

## Use binary packages from a shared build store

Some packages like `coreos-modules` take a long time to build. Use:

```shell
./build_packages --getbinpkgver=$(gsutil cat gs://…/boards/amd64-usr/current-master/version.txt |& sed -n 's/^FLATCAR_VERSION=//p')
```

to use packages from the another build store.

## Allow /usr to be remounted as read-write

By default, in every Flatcar image, it is not possible to remount `/usr` partition as read-write. However, sometimes it is needed to mount the partition as read-write mainly for debugging purposes. To make such a debugging image, Use

```shell
./build_image --noenable_rootfs_verification
```

Then it will create an image without dm-verity being enabled. So after booting with the image, you can simply run:

```shell
sudo mount -o remount,rw /usr
```

## Known issues

### build\_packages fails on coreos-base

Sometimes coreos-dev or coreos builds will fail in `build_packages` with a backtrace pointing to `epoll`. This hasn't been tracked down but running `build_packages` again should fix it. The error looks something like this:

```shell
Packages failed:
coreos-base/coreos-dev-0.1.0-r63
coreos-base/coreos-0.0.1-r187
```

### Newly added package fails checking for kernel sources

It may be necessary to comment out kernel source checks from the ebuild if the build fails, as Flatcar Container Linux does not yet provide visibility of the configured kernel source at build time.  Usually this is not a problem, but may lead to warning messages.

### `coreos-kernel` fails to link after previously aborting a build

Emerging `coreos-kernel` (either manually or through `build_packages`) may fail with the error:

```shell
/usr/lib/gcc/x86_64-pc-linux-gnu/4.9.4/../../../../x86_64-pc-linux-gnu/bin/ld: scripts/kconfig/conf.o: relocation R_X86_64_32 against `.rodata.str1.8' can not be used when making a shared object; recompile with -fPIC scripts/kconfig/conf.o: error adding symbols: Bad value
```

This indicates the ccache is corrupt. To clear the ccache, run:

```shell
CCACHE_DIR=/var/tmp/ccache ccache -C
```

To avoid corrupting the ccache, do not abort builds.

### `build_image` hangs while emerging packages after previously aborting a build

Delete all `*.portage_lockfile`s in `/build/<arch>/`. To avoid stale lockfiles, do not abort builds.

## Constants and IDs

### Flatcar Container Linux app ID

This UUID is used to identify Flatcar Container Linux to the update service and elsewhere:

```uuid
e96281a6-d1af-4bde-9a0a-97b76e56dc57
```

### GPT UUID types

- Flatcar Container Linux Root: 5dfbf5f4-2848-4bac-aa5e-0d9a20b745a6
- Flatcar Container Linux Reserved: c95dc21a-df0e-4340-8d7b-26cbfa9a03e0
- Flatcar Container Linux Raid Containing Root: be9067b9-ea49-4f15-b4f6-f36f8c9e1818



[mod-cl]: sdk-modifying-flatcar
