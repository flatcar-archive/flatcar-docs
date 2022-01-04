---
title: Guide to building custom Flatcar images from source
weight: 10
aliases:
    - ../../os/sdk-modifying-flatcar
    - ../../os/sdk-modifying-coreos
---

The guides in this document aim to enable engineers to update, and to extend, packages in both the Flatcar OS image as well as the SDK, to suit their own needs.
Overarching goal of this collection of how-tos is to help you to scratch your own itch, to set you up to play with Flatcar.
We’ll cover everything you need to make the changes you want, and to produce an image for the runtime environment(s) you want to use Flatcar in (e.g. AWS, qemu, Packet, etc).
By the end of the guide you will build a developer image that you can run under qemu and have tools for making changes to the OS image like adding or removing packages, or shipping custom kernels.
Note that we chose this guide's "qemu" image target solely to enable local testing; the same process can be used to produce images for any and all targets (cloud providers etc.) supported by Flatcar.

**Note** there is a "tl;dr" paragraph at the start of each section which summarises the commands discussed in the section.

Flatcar Container Linux is an open source project. All of the source for Flatcar Container Linux is available on [github][github-flatcar]. If you find issues with these docs or the code please send a pull request.

Please direct questions and suggestions to the [#flatcar:matrix.org Matrix channel][matrix] or [mailing list][flatcar-dev].

## Getting started

<table><tr><td>

**tl;dr** Check out a release branch and start the SDK (this uses the current Alpha release branch).
```shell
$ git clone https://github.com/flatcar-linux/scripts.git
$ cd scripts
$ branch="$(git branch -r -l | sed -n 's:origin/\(flatcar-[0-9]\+\)$:\1:p' | sort | tail -n1)"
$ git checkout "$branch"
$ git submodule init
$ git submodule update
$ for s in sdk_container/src/third_party/coreos-overlay/ sdk_container/src/third_party/portage-stable; do
$   git -C "$s" checkout "$branch"
$   git -C "$s" pull --rebase
$ done
$ ./run_sdk_container -t
```

</td></tr></table>

Flatcar Container Linux uses a containerised SDK; pre-built container images are available via [ghcr.io][ghcr-sdk].
The SDK itself is containerised, but it requires version information and package build instructions to build an OS image. 
This information is contained in the scripts repository:

```
scripts
   +--sdk_container
          +---------src
          |          +--third_party
          |                  +------coreos-overlay
          |                  +------portage-stable
          `---------.repo
                     +----manifests
                           +-------- version.txt
```

There are 2 ways to use the SDK container:
1. Standalone: Run the container and clone the scripts repo inside the container.
   This is great for one-shot SDK usage; it's not optimal for sustained OS development since versioning is unclear and changes might get lost.
2. Wrapped: Uses a wrapper script to run the container and to bind-mount the local scripts directory into the container.
   **This is the recommended way of using the SDK.**

**NOTE** that currently, Docker is required to run the SDK.
While work on supporting other runtimes (e.g. Podman) is ongoing, the wrapper scripts currently only support Docker.

### Clone the scripts repo

The [scripts repository][scripts] - among other things - contains SDK wrapper scripts, a `version.txt` with release version information, and both the [coreos-overlay][coreos] and [portage-stable][portage] ebuild repositories as git submodules (more on ebuilds later).
A good way to think of the scripts repo is this being Flatcar's "SDK repo".

```shell
$ git clone https://github.com/flatcar-linux/scripts.git
$ cd scripts
$ git submodule init
$ git submodule update
```

#### Optionally, pick a release tag or branch

Cloning the repo will have it land on the `main` branch, which can be thought of as "alpha-next" - i.e. the next major Alpha release.
Even though main is smoke-tested in nightly builds, it might occasionally be broken in subtle ways.
This can make it harder to track down issues introduced by actual changes to Flatcar.

* Release **tags** signify specific (past) releases, like "stable-2905.2.4" or "beta-3033.1.1". Tags are created in release branches.
* Release **branches** only use major numbers and might contain, on top of the latest release tag, changes for the next upcoming release.
  Branches follow the pattern "flatcar-[MAJOR]".
  Following the tag example above, "flatcar-2905" would contain all changes of major release version 2095 up until stable-2905.2.4, and might contain changes on top of 2905.2.4 slated for a future 2905.2.5 release.


It is generally recommended to base work on the latest Alpha release.
While new features should target `main` at merge time, Alpha is a tested release and therefore offers a more stable foundation to base work on.
At the same time, Alpha is not too far away from `main` so the risk of merge-time conflicts should be low.

Find the latest Alpha release branch:

```shell
$ git branch -r -l | sed -n 's:origin/\(flatcar-[0-9]\+\)$:\1:p' | sort | tail -n1
```

If the goal is to reproduce and to fix a bug of a release other than Alpha, it is recommended to base the work on the latest point release of the respective major version instead of Alpha. All currrently "active" major versions can be found at the top of the [releases][flatcar-releases] web page.

For quick reference, to get the latest stable release tag, use:
```shell
$ git tag -l | grep -E 'stable-[0-9.]+$' | sort | tail -n 1
```
(replace `stable` with `beta` or `alpha` in accordance with your needs).

Now check out the tag or branch and update the submodules:

```shell
$ git checkout [branch-or-tag-from-above]
$ git submodule update
```

**Note**: When using a branch, the submodule pinnings might be outdated, so it's always a good idea to pull the latest branch tips for the submodules, too.
This is not an issue with release tags; a release tag always pins the submodule state at the point of release.

```shell
$ for s in sdk_container/src/third_party/coreos-overlay/ sdk_container/src/third_party/portage-stable; do
$   git -C "$s" checkout [branch]
$   git -C "$s" pull --rebase
$ done
```

Lastly, to verify the version in use, consult the version file.
This file is updated on each release and reflects the SDK and OS versions corresponding to the the current commit.

```shell
$ cat sdk_container/.repo/manifests/version.txt
FLATCAR_VERSION=3066.0.0
FLATCAR_VERSION_ID=3066.0.0
FLATCAR_BUILD_ID=""
FLATCAR_SDK_VERSION=3066.0.0
```

The example above is from the Alpha branch of the 3066 major release at the time of writing.


### Start the SDK

We are now set to run the SDK container.
This will download the container image of the respective version if not present locally, and then start the container with the local directory bind-mounted.

```shell
$ ./run_sdk_container -t
sdk@flatcar-sdk-all-3066_0_0_os-alpha-3066_0_0-5-gcf4ff44a ~/trunk/src/scripts $ cat sdk_container/.repo/manifests/version.txt
```

The `-t` flag is used to tell docker to allocate a TTY. It should be omitted when calling `run_sdk_container` from a script.

The container uses the "sdk" user (user and group ID are updated on container entry to match the host user's UID and GID).
After entering you're put right into the (host) script repository's bind mount root.
By default, the name of the container contains SDK and OS image version.
After starting, the version file will have been updated:

```shell
sdk@flatcar-sdk-all-3066_0_0_os-alpha-3066_0_0-5-gcf4ff44a ~/trunk/src/scripts $ cat sdk_container/.repo/manifests/version.txt
FLATCAR_VERSION=3066.0.0+5-gcf4ff44a
FLATCAR_VERSION_ID=3066.0.0
FLATCAR_BUILD_ID="5-gcf4ff44a"
FLATCAR_SDK_VERSION=3066.0.0
```

We're basing our work on release 3066.0.0 in this example, the current branch has 5 patches on top of that release, and the latest patch has the shortlog hash `cf4ff44a`.
This leads to `FLATCAR_BUILD_ID` being set (to the output of `git describe --tags`) and is reflected in the container name `...os-alpha-3066_0_0-5-gcf4ff44a`.


#### A note on persistence

`run_sdk_container` re-uses containers once started; containers to be re-used are identified by name (see above). 
Persistence helps with keeping changes in your work environment across container runs.
**Keep in mind though that a new container will be created if the working commit in the scripts repository changes**.
This is usually desired to prevent version muddling.
It can be explicitly overridden by using the `-n <name>` argument to `run_sdk_container`.


## Building an OS image

<table><tr><td>

**tl;dr** Build packages, base image, and vendor (qemu launchable) image.
This builds for the default architecture, `amd64-usr`.
Use `--board=arm64-usr` with packages / image script to build for ARM64.
```shell
sdk@flatcar-sdk $ ./build_packages
sdk@flatcar-sdk $ ./build_image
sdk@flatcar-sdk $ ./image_to_vm.sh <path-to-image--see-output-of-build_image>
```

</td></tr></table>

Before we discuss any modifications to the image, we'll do a full image build first. This will create a "known-good" base to mount your changes on.

### Select the target architecture

**NOTE on cross-compilation**: if you are cross-compiling make sure a static aarch64 qemu is set up via binfmt-misc on your host machine.
Some packages compile and execute intermediate commands during their build process - this can break cross-compiling since the commands are built for the target architecture.
The qemu binary on the host needs to be a static binary since it will be called from within the container context.
Check if your distro has a `qemu-user-static` package that you can install or whether it has support for aarch64 in `binfmt-misc` already; on e.g. Fedora there's an `qemu-aarch64` entry in `/proc` for that (the name of the proc file may vary across distributions though):
```shell
$ cat /proc/sys/fs/binfmt_misc/qemu-aarch64
enabled
interpreter /usr/bin/qemu-aarch64-static
flags: F
offset 0
magic 7f454c460201010000000000000000000200b700
mask ffffffffffffff00fffffffffffffffffeffffff
```
Note the [**F flag**](https://www.kernel.org/doc/html/latest/admin-guide/binfmt-misc.html) to tell the kernel to preload ("fix") the binary instead of loading it lazily when emulation is required (since the latter leads to issues in namespaced environments).

Should emulation via `binfmt-misc` *not* be set up it can be added e.g. via the host's `systemd-binfmt` service like this:
```shell
$ cat /usr/lib/binfmt.d/qemu-aarch64-static.conf
:qemu-aarch64:M::\x7fELF\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\xb7\x00:\xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff:/usr/bin/qemu-aarch64-static:F
$ sudo systemctl restart systemd-binfmt.service
```

You can run `docker run --rm -ti arm64v8/alpine` on your host system as an easy check to verify everything is ready.

At the time of writing the SDK supports two target architectures: AMD64 (x86-64) and ARM64.
The target architecture can be specified by use of the `--board=` parameter to both `build_packages` and `build_image`:
* `--board=amd64-usr` will build an x86 image
* `--board=arm64-usr` will build and ARM64 image

If no architecture is specified then AMD64 will be used by default.

### Build the OS image packages

It's likely this won't *actually* build the packages but rather download pre-built packages from the Flatcar binary package cache.
The package cache is updated on every release.

```shell
$ ./build_packages [--board=...]
```

The command should download most packages from our binary cache - speeding up the "build" - since we are basing this on an existing release.
All packages will be installed to `/build/<arch>`.

You can rebuild individual packages by running `emerge-<arch>-usr PACKAGE`, e.g. `emerge-amd64-usr vim`. In this case, no binary cache will be used and the package will always be rebuilt. 

### Create the Flatcar Container Linux OS image

Now that we have all packages for the OS image either built or downloaded from the binary cache, we'll build a production base image:

```shell
$ ./build_image [--board=...]
```

This will create a temporary directory into which all of the binary packages built above will be installed. Then, a generic full [disk image](sdk-disk-partitions) is created from that temp directory.
After `build_image` completes, it prints commands for converting the raw bin into a bootable virtual machine, by means of the `image_to_vm.sh` command.

To create a qemu image for local testing, run
```shell
$ ./image_to_vm.sh --from=../build/images/arm64-usr/developer-latest [--board=...]
```

For other vendor images, pass the `--format=` parameter (see `./image_to_vm.sh --help`).
In general, `image_to_vm.sh` will read the generic disk image, install any vendor specific tools to the OEM partition where applicable (e.g. Azure VM tools for the Azure VM), and produce a vendor specific image. In the case of QEMU, a qcow2 image is produced. QEMU does not require vendor specific tooling in the OEM partition.

On the host outside the container, the image(s) built are located in `__build__/images/…`.
This directory is also bind-mounted into the container by `run_sdk_container`.

### Booting

`image_to_vm.sh` will also generate a wrapper script to launch a Flatcar VM with qemu. In a new terminal, without entering the SDK, you can boot the VM with:
```shell
$ src/build/images/arm64-usr/developer-latest/flatcar_production_qemu.sh
```

After the VM is running you should be able to SSH into Flatcar (using port 2222):
```shell
$ ssh core@localhost -p 2222
```

You should be able to log in either with your SSH public key (i.e. automatically).

If you encounter errors with KVM, verify that virtualization is supported by your CPU by running `egrep '(vmx|svm)' /proc/cpuinfo`. The `/dev/kvm` directory will be in your host OS when virtualization is enabled in the BIOS.

#### Boot Options

After `image_to_vm.sh` completes, run `./flatcar_production_qemu.sh -curses` to launch a graphical interface to log in to the Flatcar Container Linux VM.

You could instead use the `-nographic` option, `./flatcar_production_qemu.sh -nographic`, which gives you the ability to switch from the VM to the QEMU monitor console by pressing <kbd>CTRL</kbd>+<kbd>a</kbd> and then <kbd>c</kbd>. To close the Flatcar Container Linux Guest OS VM, run `sudo systemctl poweroff` inside the VM.

You can log in via SSH keys or with a different ssh port by running this example `./flatcar_production_qemu.sh -a ~/.ssh/authorized_keys -p 2223 -- -curses`. Refer to the [Booting with QEMU](booting-with-qemu#SSH-keys) guide for more information on this usage.

## Making changes

Now for the interesting part! We are going to discuss 2 ways of making changes: adding or upgrading a package, and modifying the kernel configuration.

### A brief introduction to Gentoo and how it relates to the SDK

Flatcar Container Linux is based on ChromiumOS, which is based on Gentoo.
While the ChromiumOS heritage has faded and is barely visible nowadays, we heavily leverage Gentoo processes and tools.

Contrary to traditional Linux distributions, Gentoo applications and “packages” are compiled at installation time.
Gentoo itself does not ship packages - instead, it consists of a massive number of ebuild files to build applications at installation time (that’s an oversimplification as there are binary package caches, but that’s beyond the scope of this document).
While the Flatcar SDK can be understood as a Gentoo derivative, the OS image is special.
The OS image is not self-contained, i.e. it cannot install / update packages - it lacks both a compiler to build packages as well as tools to orchestrate builds and install the resulting binaries.
Instead, OS images are built via the SDK, by building packages in the SDK, then installing the binaries into a chroot environment.
From the chroot environment, the resulting OS image is generated.

Packages in Gentoo are organised in a flat hierarchy of `<group>/<package>/`.
For instance, Linux kernel related ebuilds are in the group `sys-kernel` (kernel sources, headers, off-tree modules, etc.), while mail clients like thunderbird or mutt are in group `mail-client`.
Each package directory may contain ebuild files for multiple versions, e.g. `dev-lang/python` contains a host of python versions (used in the SDK).
Furthermore, each package directory contains a `Manifest` file with cryptographic checksums and file sizes of the package's source tarball(s), and may contain a `files/` directory containing auxiliary files to build / install the package, e.g. patches or config files.

Multiple package sources - in separate directories - can be stacked on top of each other.
These “overlays” allow custom extensions or even custom sub-trees on top of an existing foundation.
In these stacks, “upper” level packages override “lower” level ones.
The Flatcar build system uses a fork of Gentoo upstream’s [portage-stable](https://github.com/flatcar-linux/portage-stable) as its base, and the overlay repository [coreos-overlay](https://github.com/flatcar-linux/coreos-overlay) for Flatcar specific modifications and packages on top.

Packages are built using "ebuild" files.
These files contain dependencies of a package - both build and runtime - as well as implement callbacks for downloading, patching, building, and installing the package.
The callbacks in these ebuild files are written in shell.
The Gentoo package system - portage - will, when building / installing a package, run the respective callbacks in order (e.g. `src_fetch()` for downloading package sources, and `src_compile()` for building).
Common ebuild functions shared across many packages are implemented via classes (in `eclass/`) which can be inherited by package ebuilds.


For more information on Gentoo in general please refer to the [Gentoo devmanual](https://devmanual.gentoo.org/).


### Get to know the SDK chroot

When entering the SDK you are in the `~/trunk/src/scripts` repository which can be seen as the build system.
It is one of the three repositories that define a Flatcar build:
1. flatcar-scripts (the directory you're in) contains high-level build scripts to build all packages for an image, to build an image, and to bootstrap an SDK.
2. `~/trunk/src/third_party/portage-stable` contains ebuild files of all packages close to (or identical to) Gentoo upstream.
3. `~/trunk/src/third_party/coreos-overlay` contains Flatcar specific packages like ignition and mayday, as well as Gentoo packages which were significantly modified for Flatcar, like the Linux kernel, or systemd.

The SDK chroot you just entered is self-sustained and has all necessary "host" binaries installed to build Flatcar packages.
Flatcar OS image packages are "cross-compiled" even when host machine equals target machine, e.g. building an x86 image on an x86 host.
Cross-compiling via Gentoo's "crossdev" environment allows us to install packages in a chroot, which then can be used to build the OS image from.
The OS image packages therefore have their own root inside the SDK - AMD64 is located at `/build/amd64-usr/` and ARM64 is under `/build/arm64-usr/`.

Both board chroot and SDK use Gentoo's portage to manage its respective packages: `sudo emerge` is used to manage SDK packages, and `emerge-<arch>` (`emerge-amd64-usr` or `emerge-arm64-usr`, without sudo) is used to do the same for the OS image roots.


## Add (or update) a package

All of the following is done inside the SDK container, i.e. after running
```shell
$ ./run_sdk_container.sh -t
```

<table><tr><td>

**tl;dr** In the SDK container, introduce a new upstream package from Gentoo.
```shell
~/trunk/src/scripts $ git clone --depth 5 https://github.com/gentoo/gentoo.git
~/trunk/src/scripts $ mkdir -p ../third_party/portage-stable/<group>/
~/trunk/src/scripts $ cp -R gentoo/<group>/<package> ../third_party/portage-stable/<group>/
~/trunk/src/scripts $ emerge-amd64-usr --newuse <group>/<package>
# optional - add missing eclass
~/trunk/src/scripts $ cp gentoo/eclass/<eclass-name>.eclass ../third_party/portage-stable/eclass/
~/trunk/src/scripts $ emerge-amd64-usr --newuse <group>/<package>
# optional - unmask package
~/trunk/src/scripts $ vim ../third_party/coreos-overlay/profiles/coreos/base/package.accept_keywords
# remove '~' from arm64 and amd64
~/trunk/src/scripts $ emerge-amd64-usr --newuse <group>/<package>
# optional - add missing dependencies, see line 2 ff. above
~/trunk/src/scripts $ ./build_image
~/trunk/src/scripts $ ./image_to_vm.sh --from=../build/images/amd64-usr/latest --format qemu
~/trunk/src/scripts $ ../build/images/amd64-usr/latest/flatcar_production_qemu.sh &
~/trunk/src/scripts $ ssh core@localhost -p 2222
# run new software to verify it works
core@localhost ~ $ ...
```

</td></tr></table>

Let’s add a new package to our custom image.
We’ll use a package already available in Gentoo upstream, add it to our SDK, chase down dependencies, and add those, too.
Updating a package follows the same process - but instead of adding whole packages, new versions’ ebuild files are added to existing ones.
Note that adding a package “from scratch” - i.e. with no ebuild available via upstream is a completely different kind of beast and requires experience with both Gentoo as well as with fixing build and toolchain issues - so we're not going to discuss that here.

To get access to a rich and up-to-date selection of packages, we’ll use the upstream Gentoo ebuilds repository.
We’ll copy the ebuild file of the package we want to add from upstream gentoo to portage-stable, as well as the package’s dependencies.

Let’s start by checking out the Gentoo upstream ebuilds to some place outside the SDK.
We’ll only do a shallow clone to limit the amount of data we need to download:
```shell
~/trunk/src/scripts $ git clone --depth 5 https://github.com/gentoo/gentoo.git
```

This gives us ~170 groups with a total of ~20,000 packages to pick from.

Browse the Gentoo packages and find the one you want to add, or - in case of package updates - the newer version's `.ebuild` file of the package you want to update.
Create the respective group directory in `~/trunk/src/third_party/portage-stable/` if it does not exist.
Then copy the whole package directory (including all upstream ebuilds and supplemental files, like patches) into the SDK’s `portage-stable/` directory.

In the case of a package update, copy the new version's ebuild file to either `coreos-overlay` or `portage-stable`, depending on where the package to be upgraded resides.
Then add the newer version’s tarball checksum from the Gentoo package's `Manifest` file to the one in `portage-stable`.

```shell
~/trunk/src/scripts $ mkdir -p <flatcar-SDK>/src/third_party/portage-stable/<group>/
~/trunk/src/scripts $ cp -R <gentoo-repo-dir>/<group>/<package> <flatcar-SDK>/src/third_party/portage-stable/<group>/
```

The next step will have us add all required dependencies for the new package.
This usually is not necessary for package upgrades.
We will try to build the new / upgraded package, chase down all of the dependencies, and likewise copy those to the respective `<flatcar-SDK>/src/third_party` folder, too.
Depending on the gentoo classes inherited by the new package’s ebuild file, we might need to copy .eclass files, too.

So let’s enter the SDK chroot and try to build and install:
```shell
~/trunk/src/scripts $ emerge-amd64-usr --newuse <group>/<package>
```

If you see walls of error output that contain lines like `[XXXXX].eclass could not be found by inherit()` then we need to copy the respective `.eclass` file.
It means that the ebuild of the package we are trying to add contains in its `inherit` line an eclass which is not present in our SDK’s portage-stable.
So let's copy the missing eclass:
```shell
~/trunk/src/scripts $ cp <gentoo-repo-dir>/eclass/[XXXXX].eclass <flatcar-SDK>/src/third_party/portage-stable/eclass/
```
and re-run emerge. Repeat with other missing classes until the errors go away.

Lastly, the SDK might lack unmasks if the respective architecture is masked in the upstream ebuild of the package(s) added (i.e. the `KEYWORDS` variable contains `"... ~amd64 ~arm64 ... "`). Gentoo upstream uses these masks to mark a package as experimental. If that’s the case then emerge will fail with an error like
```shell
  The following keyword changes are necessary to proceed:
  [ ... ]
  # required by =<group>/package> (argument)
  =<other-group>/<other-package> **
```

To proceed, add the package name and version, and its masked architectures to the `package.accept_keywords` file inside the `coreos` profile. Which `package.accept_keywords` file should be updated depends on couple factors - whether it is needed for both SDK and OS image or only for SDK or only for OS image, whether it is needed for both AMD64 and ARM64 images, or only for AMD64 or only for ARM64. Please refer to `README.md` in coreos-overlay for a summary about profiles
Flatcar follows its own stabilisation process (through the Alpha - Beta - Stable channels); it's perfectly fine to unmask a package upstream considers unstable.

If you want to use optional build flags (USE flags in Gentoo lingo) e.g. for compiling optional library support into the application, add the new package and the respective USE flag(s) to `src/third_party/portage-stable/profiles/base/package.use`.

After the above issues have been addressed and emerge is not reporting errors anymore, we might need to add dependencies of our new package. If `emerge` fails, look for errors like:
```
emerge: there are no ebuilds to satisfy "<group>/<package>:=" for /build/amd64-usr/.
```

For each of those missing dependencies, repeat the process of adding a package described above.

Of course, the missing dependencies can also have missing dependencies on their own.
Or missing `.eclass` files.
Or are in need of more keywords / unmasks.
Worry not, just keep iterating, things will work eventually.


### Rebuild the image

After we’ve successfully built and packaged (calling `emerge` without parameters does both) it’s time to create a new OS image to validate whether the new addition works as intended.
We’ll first generate an image from our workspace (where we built a "stock" image successfully already) to make sure the new addition does not cause file conflicts with other packages, and to be able to validate the new software in a live system.

First, we add the new package to the base image packages list.
The list of packages for the base image is an ebuild file itself - and the packages list is just a list of dependencies in that ebuild.
Let’s add the package: 
```shell
~/trunk/src/scripts $ vim ../third_party/coreos-overlay/coreos-base/coreos/coreos-0.0.1.ebuild
```
In Vim, add `<group>/<package>` to list of packages in `RDEPENDS="..."`.

Now we’ll rebuild the OS image from the updated list of packages, then run it in qemu.
This will allow us to validate whether the software added works to our expectations:
```shell
~/trunk/src/scripts $ ./build_image
~/trunk/src/scripts $ ./image_to_vm.sh --from=../build/images/amd64-usr/latest --format qemu
~/trunk/src/scripts $ ../build/images/amd64-usr/latest/flatcar_production_qemu.sh &
~/trunk/src/scripts $ ssh core@localhost -p 2222
core@localhost ~ $ ...
```

Now try commands from the package you added and make sure they work, or check the presence of files (e.g. new libraries).
If something is wrong (e.g. config files are missing etc.), go back and e.g. change the application ebuild accordingly, addressing the errors you’ve observed.
Then `emerge` the application once more to force re-packaging, and rebuild the image and test again.

## Change the kernel configuration / add or remove a kernel module

All of the following is done inside the SDK container, i.e. after running
```shell
$ ./run_sdk_container.sh -t
```

<table><tr><td>

**tl;dr** In the SDK container, build the kernel package with a custom config, run+test, and persist
```shell
~/trunk/src/scripts $ ebuild-amd64-usr ../third_party/coreos-overlay/sys-kernel/coreos-modules/coreos-modules-<version>.ebuild configure
~/trunk/src/scripts $ ebuild-amd64-usr ../third_party/coreos-overlay/sys-kernel/coreos-kernel/coreos-kernel-<version>.ebuild compile
~/trunk/src/scripts $ cd /build/amd64-usr/var/tmp/portage/sys-kernel/coreos-kernel-<version>/work/coreos-kernel-<version>/build
<build-temp-directory> $ cp .config ~/trunk/src/scripts/kernel-config.orig
<build-temp-directory> $ make menuconfig
<build-temp-directory> $ cp .config ~/trunk/src/scripts/kernel-config.mine
<build-temp-directory> $ cd ~/trunk/src/scripts/
~/trunk/src/scripts $ rm /build/amd64-usr/var/tmp/portage/sys-kernel/coreos-kernel-<version>/.compiled
~/trunk/src/scripts $ ebuild-amd64-usr ../third_party/coreos-overlay/sys-kernel/coreos-kernel/coreos-kernel-<version>.ebuild compile
~/trunk/src/scripts $ sed -i 's/^CONFIG_INITRAMFS_SOURCE=.*//' kernel-config.mine
~/trunk/src/scripts $ rm -rf /build/amd64-usr/var/tmp/portage/sys-kernel/coreos-modules-<version>
~/trunk/src/scripts $ ebuild-amd64-usr ../third_party/coreos-overlay/sys-kernel/coreos-modules/coreos-modules-<version>.ebuild unpack
~/trunk/src/scripts $ cp kernel-config.mine /build/amd64-usr/var/tmp/portage/sys-kernel/coreos-modules-<version>/work/coreos-modules-<version>/build/.config
~/trunk/src/scripts $ ebuild-amd64-usr ../third_party/coreos-overlay/sys-kernel/coreos-modules/coreos-modules-<version>.ebuild compile
~/trunk/src/scripts $ ebuild-amd64-usr ../third_party/coreos-overlay/sys-kernel/coreos-kernel/coreos-kernel-<version>.ebuild package
~/trunk/src/scripts $ ebuild-amd64-usr ../third_party/coreos-overlay/sys-kernel/coreos-modules/coreos-modules-<version>.ebuild package
~/trunk/src/scripts $ ./build_image --board=amd64-usr
~/trunk/src/scripts $ ./image_to_vm.sh --from=../build/images/amd64-usr/latest --board=amd64-usr --format qemu
~/trunk/src/scripts $ ../build/images/amd64-usr/latest/flatcar_production_qemu.sh &
~/trunk/src/scripts $ ssh core@localhost -p 2222
core@localhost ~ $ ...

~/trunk/src/scripts $ diff kernel-config.orig kernel-config.mine > ../third_party/coreos-overlay/sys-kernel/coreos-modules/files/my.diff
~/trunk/src/scripts $ cd ../third_party/coreos-overlay/sys-kernel/coreos-modules/files/
~/trunk/src/scripts $ vim -O commonconfig* amd64_defconfig* my.diff
~/trunk/src/scripts $ rm my.diff
~/trunk/src/scripts $ emerge-amd64-usr sys-kernel/coreos-kernel
~/trunk/src/scripts $ emerge-amd64-usr sys-kernel/coreos-modules
~/trunk/src/scripts $ ./build_image --board=amd64-usr
~/trunk/src/scripts $ ./image_to_vm.sh --from=../build/images/amd64-usr/latest --board=amd64-usr --format qemu
~/trunk/src/scripts $ ../build/images/amd64-usr/latest/flatcar_production_qemu.sh
~/trunk/src/scripts $ ssh core@localhost -p 2222

~/trunk/src/scripts $ diff kernel-config.orig kernel-config.mine > ../third_party/coreos-overlay/sys-kernel/coreos-modules/files/my.diff
~/trunk/src/scripts $ cd ../third_party/coreos-overlay/sys-kernel/coreos-modules/files/
~/trunk/src/third_party/coreos-overlay/sys-kernel/coreos-modules/files/ $ vim -O commonconfig* amd64_defconfig* my.diff
~/trunk/src/third_party/coreos-overlay/sys-kernel/coreos-modules/files/ $ rm my.diff

~/trunk/src/scripts $ cd ~/trunk/src/scripts 
~/trunk/src/scripts $ emerge-amd64-usr sys-kernel/coreos-kernel
~/trunk/src/scripts $ emerge-amd64-usr sys-kernel/coreos-modules
~/trunk/src/scripts $ ./build_image --board=amd64-usr
~/trunk/src/scripts $ ./image_to_vm.sh --from=../build/images/amd64-usr/latest --board=amd64-usr --format qemu
~/trunk/src/scripts $ ../build/images/amd64-usr/latest/flatcar_production_qemu.sh
~/trunk/src/scripts $ ssh core@localhost -p 2222
```

</td></tr></table>

Next, we’ll look into changing the kernel configuration - e.g. for adding a kernel module or a core kernel feature not shipped with stock Flatcar.
This will give you a deep dive into the low-level bits of Gentoo's build and packaging system.
To modify the configuration of a package we will run its individual build steps manually - by use of `ebuild` instead of `emerge`.
This will allow for pausing after downloading the sources, to change the source tree configuration before building and installing.

Our first step is to set you all up with a pre-configured stock Flatcar Linux kernel to base your modifications on.
The Flatcar Linux kernel build is split over multiple gentoo ebuild files which all reside in [`coreos-overlay/sys-kernel/`](https://github.com/kinvolk/coreos-overlay/tree/main/sys-kernel):

*   `coreos-sources/` for pulling the kernel sources from git.kernel.org
*   `coreos-kernel/` for building the main kernel (vmlinuz)
*   `coreos-modules/` for building the modules, and - somewhat counterintuitively - containing all kernel config files. The kernel configuration in `coreos-modules/files/` is split into 
    *   a platform independent part  - `commonconfig-<version>`
    *   platform dependent configs - `<arch>_defconfig-<version>`
**NOTE** that these configuration snippets do not contain the whole kernel config but only Flatcar specific ones.
During the build process the config snippets are merged with the kernel's defaults for all the settings not covered by our snippets, via `make oldconfig`.

The first section below will elaborate on developing and testing your modifications via Portage's temporary build directory before we’ll merge into the ebuilds mentioned above.
This way we’ll arrive at a boot-able, test-able image before merging your changes into the coreos-overlay ebuild file.
Using Gentoo’s build-temp directories will also allow you to better iterate on your changes if you encounter problems during the build, or when testing your changes in a qemu image.

Only after we’ve tested our changes will we modify the kernel ebuild in `coreos-overlay` to persist the new configuration.

First, we will set up kernel and module sources, and modify those before build. To fetch and to configure the sources and to build a stock kernel, run:
```shell
~/trunk/src/scripts $ ebuild-amd64-usr ../third_party/coreos-overlay/sys-kernel/coreos-modules/coreos-modules-<version>.ebuild configure
~/trunk/src/scripts $ ebuild-amd64-usr ../third_party/coreos-overlay/sys-kernel/coreos-kernel/coreos-kernel-<version>.ebuild compile
```

`ebuild` is a low-level tool and part of the Portage ecosystem.
It is used by the higher level `emerge` tool for fetching, building, and installing source packages.
A single `emerge` call runs `ebuild fetch, unpack, compile, install, merge, package`.
Using `ebuild` instead of emerge allows us to stop the installation process after the package sources are configured, edit the sources, and then continue with the installation.
Let’s cd to the configured kernel source tree in Gentoo’s temporary build directory:
```shell
~/trunk/src/scripts $ cd /build/amd64-usr/var/tmp/portage/sys-kernel/coreos-kernel-<version>/work/coreos-kernel-<version>/build
```

Before we introduce our modifications we’ll make a copy of the original config:
```shell
<build-temp-directory> $ cp .config ~/trunk/src/scripts/kernel-config.orig
```

The kernel’s menuconfig is a nice way to review the configuration as well as to make changes:
```shell
<build-temp-directory> $ make menuconfig
```

Make your changes, save the new configuration, and copy the resulting `.config` to `scripts/`:
```shell
<build-temp-directory> $ cp .config ~/trunk/src/scripts/kernel-config.mine
```

Back in `~/trunk/src/scripts/`, rebuild the kernel image:
```shell
<build-temp-directory> $ cd ~/trunk/src/scripts/
~/trunk/src/scripts $ rm /build/amd64-usr/var/tmp/portage/sys-kernel/coreos-kernel-<version>/.compiled
~/trunk/src/scripts $ ebuild-amd64-usr ../third_party/coreos-overlay/sys-kernel/coreos-kernel/coreos-kernel-<version>.ebuild compile
```

The kernel configuration will contain an auto-generated INITRAMFS line.
This line must not be present in a pristine Flatcar kernel config (i.e. in an original ebuild config); there’s a sanity check in the module ebuild that will cause the module build to fail if that line is present.
So we’ll remove it:
```shell
~/trunk/src/scripts $ sed -i 's/^CONFIG_INITRAMFS_SOURCE=.*//' kernel-config.mine
```

Then delete the modules build directory - which we only needed above to get to a kernel .config - and fetch it anew, copy the kernel configuration, and rebuild the modules:
```shell
~/trunk/src/scripts $ rm -rf /build/amd64-usr/var/tmp/portage/sys-kernel/coreos-modules-<version>
~/trunk/src/scripts $ ebuild-amd64-usr ../third_party/coreos-overlay/sys-kernel/coreos-modules/coreos-modules-<version>.ebuild unpack
~/trunk/src/scripts $ cp kernel-config.mine /build/amd64-usr/var/tmp/portage/sys-kernel/coreos-modules-<version>/work/coreos-modules-<version>/build/.config
~/trunk/src/scripts $ ebuild-amd64-usr ../third_party/coreos-overlay/sys-kernel/coreos-modules/coreos-modules-<version>.ebuild compile
```

At this point, we have both a kernel build as well as kernel module binaries - but these are in temporary working directories.
In order to be able to use those for an image build, we need to generate binary packages from what we compiled.
All binary packages reside in the board chroot at `/build/amd64-usr/var/lib/portage/pkgs/`.
In the next step, we’ll build `coreos-kernel-<version>.tbz2` and `coreos-modules-<version>.tbz2`, which will land in `/build/amd64-usr/var/lib/portage/pkgs/sys-kernel`.

We package the kernel and kernel modules:
```shell
~/trunk/src/scripts $ ebuild-amd64-usr ../third_party/coreos-overlay/sys-kernel/coreos-kernel/coreos-kernel-<version>.ebuild package
~/trunk/src/scripts $ ebuild-amd64-usr ../third_party/coreos-overlay/sys-kernel/coreos-modules/coreos-modules-<version>.ebuild package
```

These packages can now be picked up by the image builder script. Let’s build a new image and boot it with qemu - this will allow us to validate the changes we made to the kernel config before persisting: 
```shell
~/trunk/src/scripts $ ./build_image --board=amd64-usr
~/trunk/src/scripts $ ./image_to_vm.sh --from=../build/images/amd64-usr/latest --board=amd64-usr --format qemu
~/trunk/src/scripts $ ../build/images/amd64-usr/latest/flatcar_production_qemu.sh &
~/trunk/src/scripts $ ssh core@localhost -p 2222
```

After we’ve verified that our modifications work as expected, let’s persist the changes into the ebuild file - in `sys-kernel/coreos-modules` (as previously mentioned).
First, we’ll generate a diff between the original config and our own config.
Then, we’ll open an editor and manually transfer the settings we actually changed - remember, the config snippets in `coreos-overlay` only contain Flatcar specifics.
```shell
~/trunk/src/scripts $ diff kernel-config.orig kernel-config.mine > ../third_party/coreos-overlay/sys-kernel/coreos-modules/files/my.diff
~/trunk/src/scripts $ cd ../third_party/coreos-overlay/sys-kernel/coreos-modules/files/
~/trunk/src/third_party/coreos-overlay/sys-kernel/coreos-modules/files/ $ vim -O commonconfig* amd64_defconfig* my.diff
~/trunk/src/third_party/coreos-overlay/sys-kernel/coreos-modules/files/ $ rm my.diff
```

Finally, we’ll rebuild kernel and modules using the updated ebuild, to make sure the build works:
```shell
~/trunk/src/scripts $ emerge-amd64-usr sys-kernel/coreos-kernel
~/trunk/src/scripts $ emerge-amd64-usr sys-kernel/coreos-modules
~/trunk/src/scripts $ ./build_image --board=amd64-usr
~/trunk/src/scripts $ ./image_to_vm.sh --from=../build/images/amd64-usr/latest --board=amd64-usr --format qemu
~/trunk/src/scripts $ ../build/images/amd64-usr/latest/flatcar_production_qemu.sh
~/trunk/src/scripts $ ssh core@localhost -p 2222
```


## Rebuilding the SDK

Take a look at the [SDK bootstrap process](sdk-bootstrapping) to learn how to build your own SDK.

## Testing images

[Mantle][mantle] is a collection of utilities used in testing and launching SDK images.

[flatcar-dev]: https://groups.google.com/forum/#!forum/flatcar-linux-dev
[github-flatcar]: https://github.com/flatcar-linux
[matrix]: https://app.element.io/#/room/#flatcar:matrix.org
[ghcr-sdk]: https://github.com/orgs/flatcar-linux/packages
[scripts]: https://github.com/flatcar-linux/scripts
[flatcar-releases]: https://www.flatcar-linux.org/releases/


[coreos]: https://github.com/flatcar-linux/coreos-overlay
[portage]: https://github.com/flatcar-linux/portage-stable
[mantle]: https://github.com/flatcar-linux/mantle
[prodimages]: sdk-building-production-images
[sdktips]: sdk-tips-and-tricks
