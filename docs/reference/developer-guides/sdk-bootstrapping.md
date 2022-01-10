## SDK bootstrap process

This document aims to provide a high-level overview of the SDK build ("bootstrap") process.

SDK bootstrapping is implemented in `bootstrap_sdk` and happens in 4 stages.  Gentoo's catalyst is used to run each of the stages in an isolated chroot. Each stage requires a "seed" tarball which contains the root filesystem used by that stage. The first stage will use an existing SDK as its seed (i.e. root FS); stages 2 to 4 will use the output of the previous stage as its seed (root FS).

### SDK bootstrap phases

The SDK bootstrap will use a previous SDK release for bootstrapping. By default, the version of the SDK is used in which the `bootstrap_sdk` script is run.

Each stage will
1. unpack the seed
2. bind-mount package repositories to the seed, mount proc
3. copy the stage's script into the unpacked seed
4. chroot into the seed
5. run the stage's script, creating the root FS for the next step in `/tmp/stageXroot` (with X bein 1 to 4, depending on stage)
6. clean up and archive the stage's `/tmp/stageXroot` to be used as the succeeding stage's seed

The output of the 4th stage, i.e. the archived contents of `/tmp/stage4root`, resembles the full-built SDK.

#### Stage 1 - Create minimal toolchain to bootstrap the SDK toolchain

Stage 1 is somewhat of a preparation phase and does not actually involve any components to be found in the final SDK. This stage takes the seed tarball - which must be a previously released Flatcar SDK - and builds a minimal toolchain from the seed (with `USE=-*`).

**NOTE** 
* this toolchain, i.e. the output of Stage 1, will be built from the "old" package versions from the seed SDK. Contents of `../third_party/coreos-overlay` and `../third_party/portage-stable` are ignored in this step. Instead, the ebuild repos included in the seed SDK are used (**FIXME: Not entirely true yet**)
* Stage 1 does _not_ feature strong library link isolation. All packages installed to `/tmp/stage1root` will be linked against libraries in `/` instead of libraries in `/tmp/stage1root`. Therefore, Stage 1 only uses the "old" seed SDK's package versions when building the seed for Stage 2.

#### Stage 2 - Build the toolchain that builds the SDK

Stage 2 uses the minimal (but potentially outdated) toolchain from Stage 1 to build a full-featured (and potentially updated) toolchain used in Stage 3 for building the actual SDK. Stage 2, contrary to Stage 1, offers strong library link isolation - everything installed to `/tmp/stage2root` is linked against libraries in `/tmp/stage2root`.

Stage 2 utilises a (slightly modified) [bootstrap.sh](https://github.com/kinvolk/portage-stable/blob/main/scripts/bootstrap.sh) - the script upstream Gentoo uses to bootstrap a Gentoo distribution.


#### Stage 3 - Build the base OS

Stage 3 runs `emerge @world` to build the base OS into `/tmp/stage3root`.

#### Stage 4 - Build additional SDK dependencies and cross-compiler toolchains

Stage 4 builds all additional dependencies of the SDK (from [coreos-devel/sdk-depends](https://github.com/kinvolk/coreos-overlay/tree/main/coreos-devel/sdk-depends)) that were not included in the base OS packages built in Stage 3. Stage 4 also builds the ARM and x86 cross-compiler toolchains included with the SDK. Finally, Stage 4 archives the portage-stable and coreos-overlay repos used to build this stage, for use in future Stage 1s (see above).

The output of Stage 4 is a full-featured SDK tarball.


## Tips and tricks

Some helpful notes when working with `bootstrap_sdk` in development.

### Continue an aborted SDK build

Using the `--version` command line flag you can continue an SDK build which was
previously aborted, e.g. after fixing an issue that caused the abort:

```
~/trunk/src/scripts $ sudo ./bootstrap_sdk --version <[release-ID]+[timestamp]>
```
e.g.
```
~/trunk/src/scripts $ sudo ./bootstrap_sdk --version 2783.0.0+2021-02-26-1321
```
