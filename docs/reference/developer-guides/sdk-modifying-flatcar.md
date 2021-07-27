---
title: Guide to building customised Flatcar images
weight: 10
aliases:
    - ../../os/sdk-modifying-flatcar
    - ../../os/sdk-modifying-coreos
---

The guides in this document aim to enable engineers to update, and to extend, packages in both the Flatcar OS image as well as the SDK, to suit their own needs. Overarching goal of this collection of how-tos is to help you to scratch your own itch, to set you up to play with Flatcar. We’ll cover everything you need to make the changes you want, and to produce an image for the runtime environment(s) you want to use Flatcar in (e.g. AWS, qemu, Packet, etc). By the end of the guide you will build a developer image that you can run under qemu and have tools for making changes to the OS image like adding or removing packages, or shipping custom kernels. Note that we chose this guide's "qemu" image target solely to enable local testing; the same process can be used to produce images for any and all targets (cloud providers etc.) supported by Flatcar.

Flatcar Container Linux is an open source project. All of the source for Flatcar Container Linux is available on [github][github-flatcar]. If you find issues with these docs or the code please send a pull request.

Direct questions and suggestions to the [IRC channel][irc] or [mailing list][flatcar-dev].

## Getting started

You’ll need the latest Flatcar SDK installed before we get to the fun part. This is discussed below. After you're set up with an SDK we’ll also do a full image build so you start from a known-good, working Flatcar image. So let's get set up with an SDK chroot and build a bootable image of Flatcar Container Linux. The SDK chroot has a full toolchain and isolates the build process from quirks and differences between host OSes. The SDK must be run on an x86-64 Linux machine, the distro should not matter (Ubuntu, Fedora, etc).

### Prerequisites

**System requirements to get started**

* curl
* git
* bzip2
* gpg
* sudo

Optionally:
* golang if you want to compile cork yourself (see below)


**You also need a proper git setup**

```shell
$ git config --global user.email "you@example.com"
$ git config --global user.name "Your Name"
```

**NOTE**: Do the git configuration as a normal user and not with sudo.


**Finally, you'll need an ssh-agent set up**

Make sure to set up ssh-agent, otherwise github will return access denied even for our public repos. In most cases this is not an issue as an ssh-agent is enabled by default in most distros. The ssh-agent is required as the chroot will access your SSH keys through the agent’s socket to authenticate github access.

### Using Cork

The `cork` utility, included in the Flatcar Container Linux [mantle](https://github.com/kinvolk/mantle) project, is used to create and work with an SDK chroot.

When installing an SDK, cork will
* download an SDK chroot tarball
* unpack the tarball in a local directory
* clone Flatcar Container Linux repositories into the local SDK directory

After the installation finished, `cork enter` may be used to enter the SDK chroot environment.


First, download the cork utility and verify it with the signature:

```shell
$ curl -L -o cork https://github.com/kinvolk/mantle/releases/download/v0.15.2/cork-0.15.2-amd64
$ curl -L -o cork.sig https://github.com/kinvolk/mantle/releases/download/v0.15.2/cork-0.15.2-amd64.sig
$ curl -LO https://www.flatcar-linux.org/security/image-signing-key/Flatcar_Image_Signing_Key.asc
$ gpg --import Flatcar_Image_Signing_Key.asc
$ rm Flatcar_Image_Signing_Key.asc
$ gpg --verify cork.sig cork
```

The `gpg --verify` command should output something like this:

```shell
gpg: Signature made Mon 07 Jan 2019 14:51:50 CET
gpg:                using RSA key 84C8E771C0DF83DFBFCAAAF03ADA89DEC2507883
gpg: Good signature from "Flatcar Application Signing Key <buildbot@flatcar-linux.org>" [unknown]
Primary key fingerprint: C1C0 B82A 2F75 90B2 E369  822B E52F 0DB3 9145 3C45
     Subkey fingerprint: 84C8 E771 C0DF 83DF BFCA  AAF0 3ADA 89DE C250 7883
```

Then proceed with the installation of the cork binary to a location on your path:

```shell
$ chmod +x cork
$ mkdir -p ~/.local/bin
$ mv cork ~/.local/bin
$ export PATH=$PATH:$HOME/.local/bin
```

You may want to add the `PATH` export to your shell profile (e.g. `.bashrc`).

**Alternatively, clone the mantle repo and build cork from sources**

If you want to build cork from sources instead of using an official release, you'll need golang installed as mantle is written in go.

```shell
$ git clone git@github.com:kinvolk/mantle.git
$ cd mantle
$ ./build cork
```

Now you want to make the resulting `bin/cork` binary part of your `$PATH`. Some prefer a symlink `~/.local/bin/cork -> ~/code/mantle/bin/cork ` ( `~/.local/bin/` often is in `$PATH` already as per `.bashrc`) - but you’re free to make your own arrangements as you see fit. Simply running `export PATH="$PATH:$(pwd/bin)"` in the mantle repo directory works (for the current shell), too.

Next, use the cork utility to download and install the SDK and related repositories. This will hold all of Flatcar's git repos as well as the SDK chroot. For building all binaries and images, about 20 gigabytes of free disk space are recommended.

**NOTE** that you can use multiple SDKs in separate directories (and separate shells, of course) at the same time.

First, we'll create a directory cork will install the SDK to.
```shell
$ mkdir flatcar-sdk
$ cd flatcar-sdk
```

**NOTE** if you are considering installing the SDK to `/tmp` or any directory mounted with `nodev`, then the SDK will not be properly installed. You must remount the directory without `nodev` specified. Errors such as `permission denied` upon `cork install` otherwise will be seen and it will prevent you from getting the SDK up and running.

Before we download and install the SDK, we need to pick a release. Generally it is recommended that people base their work on the latest Alpha release (both SDK and OS image). This guarantees a sane, known-good base to get started with - as Alpha releases are required to pass the full range of release tests - while at the same time staying reasonably current for, e.g., filing a PR later.

Get a list of all Alpha releases:
```shell
$ curl -s https://kinvolk.io/flatcar-container-linux/releases-json/releases.json \
         | jq -r 'to_entries[] | "\(.value | .channel) tag: v\(.key) - kernel \(.value | .major_software.kernel[0]), released \(.value | .release_date)"' \
         | grep 'alpha tag'
```

Then you can use the "alpha tag" value (without leading 'v') with cork's `--manifest-branch flatcar-alpha-[VERSION]` option to install that SDK version. E.g. to install Alpha release 2801.0.0, run

```shell
$ cork create --verbose --manifest-branch flatcar-alpha-2801.0.0    # Be prepared: This will request root permisions via sudo after downoad!
$ cork enter   # This will also request root permisions via sudo
```

Note that we're using the `--verbose` flag with `cork create` so you get a progress bar for downloading the SDK chroot tarball. The tarball is ~1.4GB in size, so the download can take some time. After the download finished, cork will install the SDK chroot - at that point it will require `sudo` and might prompt for your user password. Note that this prompt can time out if you weren't looking (since the download can take time). Should that happen, run
```shell
$ rm -rf chroot
$ cork create ...   # same options as above, but it will use the cached SDK (i.e. not download again)
```

As discussed above you most probably want to base your work on the latest Alpha release. Technically, you could use any release - for instance, if you want to fix a bug in Beta or Stable - by using the appropriate `--manifest-branch` option. Basing your work on the development branches for filing PRs to `main` or the `flatcar-MAJOR` maintenance branches is not covered here but under [the section for using nightly packages][sdktips]. For the given release manifest the SDK checks out the right git branches with matching ebuild files and you should not change them unless you follow the instructions on setting up the nightly binary package URLs.
```shell
$ cork create --verbose --manifest-branch flatcar-stable-2765.2.0
```
to base your work on the Stable 2765.2.0 release published on March 3rd, 2021.

### Enter the SDK

Run
```shell
$ cork enter
```

Verify you are in the SDK chroot:

```shell
$ grep NAME /etc/os-release
NAME="Flatcar Container Linux by Kinvolk"
```

To leave the SDK chroot, simply run `exit`.

To use the SDK chroot in the future, run `cork enter` from the directory you installed the SDK to (i.e. where you ran `cork create`).

## Building an image

### A brief introduction to Gentoo

Flatcar Container Linux is based on ChromiumOS, which is based on Gentoo. While the ChromiumOS heritage has faded and is barely visible nowadays, we heavily leverage Gentoo processes and tools.

Contrary to traditional Linux distributions, Gentoo applications and “packages” are compiled at installation time. Gentoo itself does not ship packages - instead, it consists of a massive number of ebuild files to build applications at installation time (that’s an oversimplification as there are binary package caches, but that’s beyond the scope of this document).

Packages are organised in a flat hierarchy of `<group>/<package>`. For instance, Linux kernel related ebuilds are in the group `sys-kernel` (kernel sources, headers, off-tree modules, etc.), while mail clients like thunderbird or mutt are in group `mail-client`. Each package may contain ebuild files for multiple versions, e.g. `sys-kernel/gentoo-kernel/` contains ebuilds for building 5.4 (LTS kernel) and 5.10 (most current kernel).

Ebuild files end with `.ebuild` and contain a package’s dependencies - both build and runtime - as well as implement callbacks for various build steps, written in shell. The Gentoo package system calls those e.g. for fetching sources (`src_fetch()`) or for compiling the package (`src_compile()`). To make code reusable, Gentoo supports the concept of classes (in `eclass/`), which allow package ebuild files to inherit common base functions.

Multiple ebuild trees can be stacked on “overlays”, allowing custom extensions or even custom sub-trees. In these stacks, “upper” level ebuilds override “lower” level ones. The Flatcar build system uses a fork of Gentoo upstream’s [portage-stable](https://github.com/flatcar-linux/portage-stable) as its base, and the overlay repository [coreos-overlay](https://github.com/flatcar-linux/coreos-overlay) for Flatcar specific modifications and packages on top.

For more information on Gentoo in general please refer to the [Gentoo devmanual](https://devmanual.gentoo.org/).


### Get to know the SDK chroot

When entering the SDK you are in the `~/trunk/src/scripts` repository which can be seen as the build system.
It is one of the three repositories that define a Flatcar build:
1. flatcar-scripts (the directory you're in) contains high-level build scripts to build all packages for an image, to build an image, and to bootstrap an SDK.
2. `~/trunk/src/third_party/portage-stable` contains ebuild files of all packages close to (or identical to) Gentoo upstream.
3. `~/trunk/src/third_party/coreos-overlay` contains Flatcar specific packages like ignition and mayday, as well as Gentoo packages which were significantly modified for Flatcar.

The SDK chroot you just entered is self-sustained and has all necessary "host" binaries installed to build Flatcar packages. Flatcar OS image packages are "cross-compiled" (even when host machine equals target machine, e.g. building an x86 image on an x86 host). The OS image packages have their own root within the SDK - `/build/amd64-usr/` for x86_64 and `/build/arm64-usr/` for ARM64, depending on which _board_ you initialised (see below).

In other words, you'll be dealing with two levels of chroot:
* The top-level SDK chroot, activated by `cork enter`, consisting of the build chroot with ebuild file sources (`src/` in the SDK directory) mounted in
* The image chroot, in `/build/<arch>` in the SDK

Both chroots use Gentoo's portage to manage the packages: `sudo emerge` is used to manage SDK packages, and `emerge-<arch>` (`emerge-amd64-usr` or `emerge-arm64-usr`, without sudo) is used to do the same for the OS image roots.

#### Select the architecture to build

`amd64-usr` and `arm64-usr` are the only targets supported by Flatcar.
When setting up a new build target you can select it as default architecture, otherwise you need to specify the architecture for each step.
The `--board` option can be set to one of a few known target architectures, or system "boards", to build for a given CPU.

#### 64 bit AMD: The amd64-usr target

AMD64 / x86_64 is well supported and is recommended for engineers getting started with Flatcar development.

To initialise an AMD64 board chroot (`amd64-usr` in Flatcar lingo) in the directory `/build/amd64-usr/`, run:

```shell
$ ./setup_board [--default] --board=amd64-usr
```

The `--default` flag makes this architecture the default so you don't need to specify `--board` when buidling packages and images.

##### 64 bit ARM: The arm64-usr target

ARM64 support is experimental and only recommended for advanced users.

The SDK runs on an amd64 host system, relying on cross-compilation to create arm64 binaries.
Still, during the compilation phase many package builds perform `configure` tests by running a compiled binary or invoke compiled helper binaries.
This requires the host system to use binary translation (software-based virtualisation) for seamlessly running arm64 binaries.

On a Fedora/Debian host system there is a `qemu-user-static` package that sets everything up.
If you have troubles or use a different host system, check that a statically compiled aarch64 qemu-user binary is referenced with the `:F` flag for pinning it into the kernel so that it is not needed in every chroot:

```shell
$ cat /usr/lib/binfmt.d/qemu-aarch64-static.conf
:qemu-aarch64:M::\x7fELF\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\xb7\x00:\xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff:/usr/bin/qemu-aarch64-static:F
$ sudo systemctl restart systemd-binfmt.service
```

You can run `docker run --rm -ti arm64v8/alpine` on your host system as an easy check to verify everything is ready.

In the SDK, to initialise an ARM64 / AARCH64 board chroot (`arm64-usr` in Flatcar lingo) in the directory `/build/amd64-usr/`, run:

```shell
$ ./setup_board [--default] --board=arm64-usr
```

The SDK will set up the `QEMU_LD_PREFIX` environment variable, allowing to run any binaries under `/build/arm64-usr/`, without an additional `chroot` command.

### Build all packages that make up the OS image

Before we discuss any modifications to the image, we'll do a full image build first. This will create a "known-good" base to mount your changes on.

First, build all of the target binary packages:

```shell
$ ./build_packages [--board=...]
```

You only need to use `--board` if you did not use the `--default` option with `setup_board` above, or if you want to build for an architecture that's not your default one.
The command should download most packages from our binary cache - speeding up the "build" - since we are basing this on an existing release. All packages will be installed to `/build/<arch>`.

You can also rebuild individual packages manually by running `emerge-<arch>-usr PACKAGE`, e.g. `emerge-amd64-usr vim`. In this case, no binary cache will be used and the package will always be rebuilt. 

### Create the Flatcar Container Linux OS image

Now that we have all packages for the OS image either built or downloaded from the binary cache, we'll build a production base image:

```shell
$ ./build_image [--board=...]
```

This will create a temporary directory into which all of the binary packages built above will be installed. Then, a generic full [disk image](sdk-disk-partitions) is created from that temp directory.
After `build_image` completes, it prints commands for converting the raw bin into a bootable virtual machine, by means of the `image_to_vm.sh` command.

To create a qemu image for local testing, run
```shell
$ ./image_to_vm.sh --format=qemu --from=../build/images/arm64-usr/developer-latest [--board=...]
```

In general, `image_to_vm.sh` will read the generic disk image, install any vendor specific tools to the OEM partition where applicable (e.g. Azure VM tools for the Azure VM), and produce a vendor specific image. In the case of QEMU, a qcow2 image is produced. QEMU does not require vendor specific tooling in the OEM partition.

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

### Add (or update) a package

Let’s add a new package to our custom image. We’ll use a package already available in Gentoo upstream, add it to our SDK, chase down dependencies, and add those, too. Updating a package follows the same process - but instead of adding whole packages, new versions’ ebuild files are added to existing ones. Note that adding a package “from scratch” (including dependencies) which is not available via upstream is a completely different kind of beast and requires experience with both Gentoo as well as with fixing build and toolchain issues - so we're not going to discuss that here.

To get access to a rich and up-to-date selection of packages, we’ll use the upstream Gentoo ebuilds repository. We’ll copy the ebuild file of the package we want to add from upstream gentoo to portage-stable, as well as the package’s dependencies.

Let’s start by checking out the Gentoo upstream ebuilds to some place outside the SDK. We’ll only do a shallow clone to limit the amount of data we need to download:
```shell
$ git clone --depth 5 https://anongit.gentoo.org/git/repo/gentoo.git
```

This gives us ~170 groups with a total of ~20,000 packages to pick from.

Browse the Gentoo packages and find the one you want to add, or - in case of package updates - the newer version's `.ebuild` file of the package you want to update. Copy the whole package directory (including all upstream ebuilds and supplemental files, like patches) into the SDK’s `portage-stable/` directory, and create the group directory in `portage-stable/` if the group is not present yet. In the case of a package update, copy the new version's ebuild file to either `coreos-overlay` or `portage-stable`, depending on where the package to be upgraded resides. 

```shell
$ mkdir -p <flatcar-SDK>/src/third_party/portage-stable/<group>/
$ cp -R <gentoo-repo-dir>/<group>/<package> <flatcar-SDK>/src/third_party/portage-stable/<group>/
```
If you just want to upgrade a package by adding the ebuild file of a newer version, don’t forget to add the newer version’s tarball checksum for Gentoo’s `Manifest` file to `portage-stable`’s.

The next step will have us add all required dependencies for the new package. This usually is not necessary for package upgrades. We will try to build the new / upgraded package, chase down all of the dependencies, and likewise copy those to the respective `<flatcar-SDK>/src/third_party` folder, too. Depending on the gentoo classes inherited by the new package’s ebuild file, we might need to copy .eclass files, too.

So let’s enter the SDK chroot and try to build and install:
```shell
$ emerge-amd64-usr --newuse <group>/<package>
```

If you see walls of error output that contain lines like `[XXXXX].eclass could not be found by inherit()` then we need to copy the respective `.eclass` file. It means that the ebuild of the package we are trying to add contains in its `inherit` line an eclass which is not present in our SDK’s portage-stable. eclasses exist to prevent code duplication; ebuild files can “inherit” common callback implementations e.g. for fetching, configuring, and compiling sources from these base classes. Copy all required eclasses:
```shell
$ cp <gentoo-repo-dir>/eclass/[XXXXX].eclass <flatcar-SDK>/src/third_party/portage-stable/eclass/
```
until the errors go away.

Also, you may encounter errors like `Invalid implementation in PYTHON_COMPAT: python3_8` which implies that the ebuild declares compatibility to python version 3.8, which is not (yet) available in the SDK. To mitigate, edit the new package’s `.ebuild` file, find the line 
```shell
 PYTHON_COMPAT=( python3_{6,7,8} )
```
And remove the “,8”:
```shell
 PYTHON_COMPAT=( python3_{6,7} )
```

Lastly, the SDK might lack unmasks if the respective architecture is masked in the upstream ebuild of the package(s) added (i.e. the `KEYWORDS` variable contains `"... ~amd64 ~arm64 ... "`). Gentoo upstream uses these masks to mark a package as experimental. If that’s the case then emerge will fail with an error like
```shell
  The following keyword changes are necessary to proceed:
  [ ... ]
  # required by =<group>/package> (argument)
  =<other-group>/<other-package> **
```
The keywords and unmasks can be added automatically to your local SDK by running
```shell
$  emerge-amd64-usr --newuse <group>/<package> --autounmask=y --autounmask-write --ask
```

which will print the changes and prompt you before writing them. Run `emerge-amd64-usr --newuse <group>/<package>` again to proceed.

**NOTE**: a bug in the Chromium part of the SDK will lead to the following warning:
```shell
--- Invalid atom in /build/amd64-usr/etc/portage/package.unmask/cros-workon:
     =<group>/<package>
```
The SDK creates softlinks for both `/build/amd64-usr/etc/portage/package.unmask/cros-workon` and `/build/amd64-usr/etc/portage/package.keywords/cros-workon` to the same file - to `.config/cros_workon/amd64-usr` (outside the SDK chroot). This effectively merges all required keywords and unmasks into the same file. The keywords and unmasks files follow different semantics, leading to emerge printing the warning above. Since invalid atoms will be ignored, it’s safe to ignore the warning for the time being.

If you want to use optional build flags (USE flags in Gentoo lingo) e.g. for compiling optional library support into the application, add the new package and the respective USE flag(s) to `src/third_party/portage-stable/profiles/base/package.use`.

After the above issues have been addressed and emerge is not reporting errors anymore, we might need to add dependencies of our new package. If `emerge` fails, look for errors like:
```
emerge: there are no ebuilds to satisfy "<group>/<package>:=" for /build/amd64-usr/.
```

For each of those missing dependencies, repeat the process of adding a package described above.

Of course, the missing dependencies can also have missing dependencies on their own. Or missing `.eclass` files. Or referencing a python version not in the SDK. Or are in need of more keywords / unmasks. Worry not, just keep iterating, things will work eventually.


##### Rebuild the image

After we’ve successfully built and packaged (calling `emerge` without parameters does both) it’s time to create a new OS image to validate whether the new addition works as intended. We’ll first generate an image from our workspace (where we built a "stock" image successfully already) to make sure the new addition does not cause file conflicts with other packages, and to be able to validate the new software works as intended. After that, we’ll purge everything we’ve built, then rebuild the image from scratch.

First, we add the new package to the base image packages list. The list of packages for the base image is an ebuild file itself - and the packages list is just a list of dependencies in that ebuild. Let’s add the package: 
```shell
$ cork enter
$ vim ../third_party/coreos-overlay/coreos-base/coreos/coreos-0.0.1.ebuild
```
In Vim, add `<group>/<package>` to list of packages in `RDEPENDS="..."`.

If you were required to add unmasks for the new package(s) to your local SDK via `--autounmask-write`, make sure to add the package version to `../third_party/portage-stable/profiles/base/package.accept_keywords` in the format `=<group>/<package>-<version> ~amd64 ~arm64`. 

Now we’ll rebuild the OS image from the updated list of packages, then run it in qemu. This will allow us to validate whether the new package works correctly:
```shell
$ ./build_image --board=amd64-usr
$ ./image_to_vm.sh --from=../build/images/amd64-usr/latest --board=amd64-usr --format qemu
$ ../build/images/amd64-usr/latest/flatcar_production_qemu.sh
$ ssh core@localhost -p 2222
```

Now try commands from the package you added and make sure they work, or check the presence of files (e.g. new libraries). If something is wrong (e.g. config files are missing etc.), go back and e.g. change the application ebuild accordingly, addressing the errors you’ve observed. Then `emerge` the application once more to force re-packaging, and rebuild the image and test again. Should you run into “no space left on device” issues when building the image, you will need to increase the size of the USR1 and USR2 partitions in `build_library/disk_layout.json`.

Finally, we want to perform a scratch build to make sure your change is reproducible and did not break pristine builds. For this, reinitialise the board (which will purge everything we’ve built and all binary packages downloaded for the image) and rebuild the OS image from scratch:
```shell
$ ./setup_board --board=amd64-usr --force
$ ./build_packages --board=amd64-usr
$ ./build_image --board=amd64-usr
```

### Change the kernel configuration / add or remove a kernel module

Next, we’ll look into changing the kernel configuration - e.g. for adding a kernel module or a core kernel feature not shipped with stock Flatcar. This will give you a low level deep dive into the Gentoo build system.

Our first step is to set you all up with a pre-configured stock Flatcar Linux kernel to base your modifications on. The Flatcar Linux kernel build is split over multiple gentoo ebuild files which all reside in <code>[coreos-overlay/sys-kernel/](https://github.com/kinvolk/coreos-overlay/tree/main/sys-kernel)</code>:

*   `coreos-sources/` for pulling the kernel sources from git.kernel.org
*   `coreos-kernel/` for building the main kernel (vmlinuz)
*   `coreos-modules/` for building the modules, and - somewhat counterintuitively - containing all kernel config files. The kernel configuration in `coreos-modules/files/` is split into 
    *   a platform independent part  - `commonconfig-<version>`
    *   platform dependent configs - `<arch>_defconfig-<version>`

The first section below will elaborate on developing, and testing, your modifications before we’ll merge into the ebuilds mentioned above. To achieve this, we will use the low level `ebuild` tool to selectively prepare the build of kernel image and modules, then make our modifications in Gentoo’s temporary build directories, and then continue the build. This way we’ll arrive at a boot-able, test-able image before merging your changes into the coreos-overlay ebuild file. Using Gentoo’s build-temp directories will also allow you to better iterate on your changes if you encounter problems during the build, or when testing your changes in a qemu image.

Only after we’ve tested our changes will we modify the kernel ebuild to persist the new configuration.

First, we will set up kernel and module sources, and modify those before build. To fetch and to configure the sources and to build a stock kernel, run:
```shell
$ cork enter
$ ebuild-amd64-usr ../third_party/coreos-overlay/sys-kernel/coreos-modules/coreos-modules-<version>.ebuild configure
$ ebuild-amd64-usr ../third_party/coreos-overlay/sys-kernel/coreos-kernel/coreos-kernel-<version>.ebuild compile
```

The tool we just used - `ebuild` - is a low-level tool and part of the Gentoo package ecosystem. It is used by the higher level `emerge` tool for fetching, building, and installing source packages. A single `emerge` call runs `ebuild fetch, unpack, compile, install, merge, package`. Using `ebuild` instead of emerge (like above) allows us to stop the installation process after the package sources are configured, edit the sources, and then continue with the installation. Let’s cd to the configured kernel source tree in Gentoo’s temporary build directory:
```shell
$ cd /build/amd64-usr/var/tmp/portage/sys-kernel/
$ cd coreos-kernel-<version>/work/coreos-kernel-<version>/build
```

Before we introduce our modifications we’ll make a copy of the original config:
```shell
$ cp .config ~/trunk/src/scripts/kernel-config.orig
```

The kernel’s menuconfig is a nice way to review the configuration as well as to make changes:
```shell
$ make menuconfig
```

Make your changes, save the new configuration, and copy the resulting `.config` to `scripts/`:
```shell
$ cp .config ~/trunk/src/scripts/kernel-config.mine
```

Back in `~/trunk/src/scripts/`, rebuild the kernel image:
```shell
$ cd ~/trunk/src/scripts/
$ rm /build/amd64-usr/var/tmp/portage/sys-kernel/coreos-kernel-<version>/.compiled
$ ebuild-amd64-usr ../third_party/coreos-overlay/sys-kernel/coreos-kernel/coreos-kernel-<version>.ebuild compile
```

The kernel configuration will contain an auto-generated INITRAMFS line. This line must not be present in a pristine Flatcar kernel config (i.e. in an original ebuild config); there’s a sanity check in the module ebuild that will cause the module build to fail if that line is present. So we’ll remove it:
```shell
$ sed -i 's/^CONFIG_INITRAMFS_SOURCE=.*//' kernel-config.mine
```

Then delete the modules build directory - which we only needed above to get to a kernel .config - and fetch it anew, copy the kernel configuration, and rebuild the modules:
```shell
$ rm -rf /build/amd64-usr/var/tmp/portage/sys-kernel/coreos-modules-<version>
$ ebuild-amd64-usr ../third_party/coreos-overlay/sys-kernel/coreos-modules/coreos-modules-<version>.ebuild unpack
$ cp kernel-config.mine /build/amd64-usr/var/tmp/portage/sys-kernel/coreos-modules-<version>/work/coreos-modules-<version>/build/.config
$ ebuild-amd64-usr ../third_party/coreos-overlay/sys-kernel/coreos-modules/coreos-modules-<version>.ebuild compile
```

At this point, we have both a kernel build as well as kernel module binaries - but these are in temporary working directories. In order to be able to use those for an image build, we need to generate binary packages from what we compiled. All binary packages reside below `/build/amd64-usr/var/lib/portage/pkgs/`. In the next step, we’ll build `coreos-kernel-<version>.tbz2` and `coreos-modules-<version>.tbz2`, which will land in `/build/amd64-usr/var/lib/portage/pkgs/sys-kernel`.

We package the kernel and kernel modules:
```shell
$ ebuild-amd64-usr ../third_party/coreos-overlay/sys-kernel/coreos-kernel/coreos-kernel-<version>.ebuild package
$ ebuild-amd64-usr ../third_party/coreos-overlay/sys-kernel/coreos-modules/coreos-modules-<version>.ebuild package
```

These packages can now be picked up by the image builder script. Let’s build a new image and boot it with qemu - this will allow us to validate the changes we made to the kernel config before persisting: 
```shell
$ ./build_image --board=amd64-usr
$ ./image_to_vm.sh --from=../build/images/amd64-usr/latest --board=amd64-usr --format qemu
$ ../build/images/amd64-usr/latest/flatcar_production_qemu.sh
$ ssh core@localhost -p 2222
```

After we’ve verified that our modifications work as expected, let’s persist the changes into the ebuild file - in `sys-kernel/coreos-modules` (as previously mentioned).
First, we’ll generate a diff between the original config and our own config. Then, we’ll open an editor and manually transfer the configuration changes.
```shell
$ diff kernel-config.orig kernel-config.mine > ../third_party/coreos-overlay/sys-kernel/coreos-modules/files/my.diff
$ cd ../third_party/coreos-overlay/sys-kernel/coreos-modules/files/
$ vim -O commonconfig* amd64_defconfig* my.diff
$ rm my.diff
```

Finally, we’ll rebuild kernel and modules using the updated ebuild, to make sure the build works:
```shell
$ emerge-amd64-usr sys-kernel/coreos-kernel
$ emerge-amd64-usr sys-kernel/coreos-modules
$ ./build_image --board=amd64-usr
$ ./image_to_vm.sh --from=../build/images/amd64-usr/latest --board=amd64-usr --format qemu
$ ../build/images/amd64-usr/latest/flatcar_production_qemu.sh
$ ssh core@localhost -p 2222
```

## Tips and tricks

We've compiled a [list of tips and tricks][sdktips] that can make working with the SDK a bit easier.


## Rebuilding the SDK

Take a look at the [SDK bootstrap process](sdk-bootstrapping) to learn how to build your own SDK.

## Testing images

[Mantle][mantle] is a collection of utilities used in testing and launching SDK images.

[android-repo-git]: https://source.android.com/source/developing.html
[flatcar-dev]: https://groups.google.com/forum/#!forum/flatcar-linux-dev
[github-flatcar]: https://github.com/kinvolk/Flatcar
[irc]: irc://irc.freenode.org:6667/#flatcar
[mantle]: https://github.com/kinvolk/mantle
[prodimages]: sdk-building-production-images
[repo-blog]: http://google-opensource.blogspot.com/2008/11/gerrit-and-repo-android-source.html
[sdktips]: sdk-tips-and-tricks
