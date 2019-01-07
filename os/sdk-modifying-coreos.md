# Flatcar Linux developer SDK guide

These are the instructions for building Flatcar Linux itself. By the end of the guide you will build a developer image that you can run under KVM and have tools for making changes to the code.

Flatcar Linux is an open source project. All of the source for Flatcar Linux is available on [github][github-flatcar]. If you find issues with these docs or the code please send a pull request.

Direct questions and suggestions to the [IRC channel][irc] or [mailing list][flatcar-dev].

## Getting started

Let's get set up with an SDK chroot and build a bootable image of Flatcar Linux. The SDK chroot has a full toolchain and isolates the build process from quirks and differences between host OSes. The SDK must be run on an x86-64 Linux machine, the distro should not matter (Ubuntu, Fedora, etc).

### Prerequisites

System requirements to get started:

* curl
* git
* bzip2
* gpg
* sudo

You also need a proper git setup:

```sh
git config --global user.email "you@example.com"
git config --global user.name "Your Name"
```

**NOTE**: Do the git configuration as a normal user and not with sudo.

### Using Cork

The `cork` utility, included in the Flatcar Linux [mantle](https://github.com/flatcar-linux/mantle) project, is used to create and work with an SDK chroot.

First, download the cork utility and verify it with the signature:

```sh
curl -L -o cork https://github.com/flatcar-linux/mantle/releases/download/v0.11.2/cork-0.11.2-amd64
curl -L -o cork.sig https://github.com/flatcar-linux/mantle/releases/download/v0.11.2/cork-0.11.2-amd64.sig
gpg --receive-keys 84C8E771C0DF83DFBFCAAAF03ADA89DEC2507883
gpg --verify cork.sig cork
```

The `gpg --verify` command should output something like this:

```
gpg: Signature made Mon 07 Jan 2019 14:51:50 CET
gpg:                using RSA key 84C8E771C0DF83DFBFCAAAF03ADA89DEC2507883
gpg: Good signature from "Flatcar Application Signing Key <buildbot@flatcar-linux.org>" [unknown]
Primary key fingerprint: C1C0 B82A 2F75 90B2 E369  822B E52F 0DB3 9145 3C45
     Subkey fingerprint: 84C8 E771 C0DF 83DF BFCA  AAF0 3ADA 89DE C250 7883
```

Then proceed with the installation of the cork binary to a location on your path:

```sh
chmod +x cork
mkdir -p ~/.local/bin
mv cork ~/.local/bin
export PATH=$PATH:$HOME/.local/bin
```

You may want to add the `PATH` export to your shell profile (e.g. `.bashrc`).


Next, use the cork utility to create a project directory. This will hold all of your git repos and the SDK chroot. A few gigabytes of space will be necessary.

```sh
mkdir flatcar-sdk
cd flatcar-sdk
cork create --manifest-branch=flatcar-master --manifest-url=https://github.com/flatcar-linux/manifest
cork enter
```

**Note**: The `create` and `enter` commands will request root permissions via sudo.


To use the SDK chroot in the future, run `cork enter` from the above directory.

### Building an image

After entering the chroot via `cork` for the first time, you should set user `core`'s password:

```sh
./set_shared_user_password.sh
```

This is the password you will use to log into the console of images built and launched with the SDK.

#### Selecting the architecture to build

`amd64-usr` is the only target supported by Flatcar.

##### 64 bit AMD: The amd64-usr target

The `--board` option can be set to one of a few known target architectures, or system "boards", to build for a given CPU.

To create a root filesystem for the `amd64-usr` target beneath the directory `/build/amd64-usr/`:

```sh
./setup_board --default --board=amd64-usr
```

#### Compile and link system binaries

Build all of the target binary packages:

```sh
./build_packages
```

#### Render the Flatcar Linux image

Build an image based on the binary packages built above:

```sh
./build_image
```

After `build_image` completes, it prints commands for converting the raw bin into a bootable virtual machine. Run the `image_to_vm.sh` command.

### Booting

Once you build an image you can launch it with KVM (instructions will print out after `image_to_vm.sh` runs).

## Making changes

### git and repo

Flatcar Linux is managed by `repo`, a tool built for the Android project that makes managing a large number of git repositories easier. From the repo announcement blog:

> The repo tool uses an XML-based manifest file describing where the upstream
> repositories are, and how to merge them into a single working checkout. repo
> will recurse across all the git subtrees and handle uploads, pulls, and other
> needed items. repo has built-in knowledge of topic branches and makes working
> with them an essential part of the workflow.

(from the [Google Open Source Blog][repo-blog])

You can find the full manual for repo by visiting [android.com - Developing][android-repo-git].

### Updating repo manifests

The repo manifest for Flatcar Linux lives in a git repository in
`.repo/manifests`. If you need to update the manifest edit `default.xml`
in this directory.

`repo` uses a branch called 'default' to track the upstream branch you
specify in `repo init`, this defaults to 'origin/master'. Keep this in
mind when making changes, the origin git repository should not have a
'default' branch.

## Building images

There are separate workflows for building [production images][prodimages].

## Tips and tricks

We've compiled a [list of tips and tricks][sdktips] that can make working with the SDK a bit easier.

## Testing images

[Mantle][mantle] is a collection of utilities used in testing and launching SDK images.


[android-repo-git]: https://source.android.com/source/developing.html
[flatcar-dev]: https://groups.google.com/forum/#!forum/flatcar-linux-dev
[github-flatcar]: https://github.com/flatcar-linux/
[irc]: irc://irc.freenode.org:6667/#flatcar
[mantle]: https://github.com/flatcar-linux/mantle
[prodimages]: sdk-building-production-images.md
[repo-blog]: http://google-opensource.blogspot.com/2008/11/gerrit-and-repo-android-source.html
[sdktips]: sdk-tips-and-tricks.md
