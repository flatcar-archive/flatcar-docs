---
title: Building production images
weight: 10
aliases:
    - ../../os/sdk-building-production-images
---


## Introduction

This guide discusses automating the OS build process and is aimed at audiences comfortable with producing, testing, and distributing their very own Flatcar releases. For this purpose we'll have a closer look at the CI automation stubs provided in the [scripts repository][scripts-repo-ci].

It is assumed that readers are familiar with the [SDK][mod-cl] and the general build process outlined in the [CI automation][scripts-repo-ci].


## Stabilisation process and versioning

The Flatcar OS version number follows the pattern MMMM.m.p[ppp] - "M" being the major number, "m" the minor, and "p" the patch level.
Specifically:
- A new major version number is introduced with every new Alpha release.
- The minor version denotes the stabilisation level; 0 means Alpha, 1 is Beta, and 2 is Stable.
- The patch level denotes incremental releases within the same channel and is incremented e.g. to address issues before promoting a major version to the next stabilisation phase.

Roughly, every second Alpha major release goes Beta, and every second Beta major release goes stable.
A notable exception is the "3033" major release used in the example below; this release shipped ARM64 support and was moved to Stable faster than usual.
This allows for swift iterations in the "Alpha" channel while keeping Stable major releases … well … stable, and ensuring new major Stable releases introduce meaningful sets of updates and new features.

A good way to look at releases and stabilisation through channels is to consider major releases as branches from "main", while Alpha, Beta and Stable releases are distinct points in the lifecycle of a release branch:
```
  main
  ...
   +-- Alpha-2983.0.0
   |        +-- Beta-2983.1.0
   |                +--- Stable-2983.2.0
   |                +--- Stable-2983.2.1
   |
   +-- Alpha-3005.0.0
   +-- Alpha-3005.0.1
   |
   +-- Alpha-3033.0.0
   |        +-- Beta-3033.1.0
   |        +-- Beta-3033.1.1
   |                +--- Stable-3033.2.0
   |
   +-- Alpha-3046.0.0
   |
   +-- Alpha-3066.0.0
   |        +-- Beta-3066.1.0
  ...
```


## On versioning

For Flatcar versioning, the scripts repo is authoritative: 
Versioning is controlled by the [`version.txt` file in the scripts repo](https://github.com/flatcar/scripts/blob/main/sdk_container/.repo/manifests/version.txt).
`version.txt` contains version strings for both the SDK version as well as the OS image version.

Core idea is that a simple
```shell
git checkout 3033.2.0
```
will set up the scripts repo for development on top of Flatcar release `3033.2.0`.

Keeping `version.txt` in sync, updating version strings, and generating version tags is one of the main concerns of the build automation scripts.
Running a new build via the CI automation will *always* generate a new version.
This can be non-production version, e.g. nightly build or a PR or branch build - in which case it should be given a suffix following the `MMMM.mm.pp` number.
The official Flatcar CI uses `-nightly-YYYYMMDD-hhmm` as suffix for nightly builds, e.g. the tag `alpha-3066.0.0-nightly-20221231-0139` would refer to the nightly of the 31st of December, 2021.
However, custom CI implementations may freely choose to use different suffixes.


Version information is a mandatory parameter which the CI implementation must feed into the CI automation scripts. Two of the build steps (detailed on below) take version parameters:
- The SDK bootstrap takes a version string that is used for both the new SDK as well as the downstream OS image version.
- The OS packages build step takes a version string that is used for the new OS image version.

Both scripts will, based on a given version string:
1. check out a respective version tag in both `coreos-overlay` and `portage-stable`
2. update the `version.txt` file accordingly
3. create a new commit with the above changes
4. tag the commit with the version string and push the tag.


## Build automation and build steps

The Flatcar Container Linux build process consists of

1. compiling packages from source, and generating a new OS image release version / tag
2. creating a generic OS image file from the resulting binary packages
3. creating one or more vendor-specific image files from the generic OS image.


Optionally, the build process may include building the SDK from scratch based on a previous - existing - SDK, e.g. to update core build tools and utilities.
In that case, the above 3 steps are preceded by

1. Compile all core and SDK packages from source to generate a new SDK root FS and build a tarball from that; generate a new SDK release version and set the OS release to the same (SDK) version.
2. Build a base SDK container image using the tarball from 1.
   1. build amd64 and arm64 toolchains and related board support
   2. then, from the image from 2. i., generate from scratch 3 container images - "all", "amd64", and "arm64" with the respective board support included.


Running all 5 steps in one go will produce a new SDK and new OS image based on that new SDK.
In this pipeline, both a new SDK version as well as a new OS image version are generated.
This is what we call a "full" (or "all-full") build.
The main use case is for nightly builds of the "main" branches where development of new features happen.
A new major version release will also use this process (and can be seen as a "special case" of a nightly build of "main").
New major releases always include a new SDK.

Running only the 3 OS image steps is used for active (i.e. supported) release branches.
This uses an existing SDK and thus only generates a new OS image version.
Usually, stabilisation of a major release (alpha -> beta -> stable) uses the same SDK release during its lifetime, so there's no need to always build the SDK.
Only in rare cases it is necessary to update the SDK after a new major version has been published.


### Automation scripts

The [build automation scripts][scripts-repo-ci] reflect the 5 steps outlined above; each step is done in a separate script.
Check out the build automation's `README.md` to get an overview.
Each of the scripts contains documentation of the inputs and outputs of the respective build step:

1. [`sdk_bootstrap.sh`](https://github.com/flatcar/scripts/blob/main/ci-automation/sdk_bootstrap.sh) builds a new SDK tarball from scratch
2. [`sdk_container.sh`](https://github.com/flatcar/scripts/blob/main/ci-automation/sdk_container.sh) builds an SDK container image from a tarball
3. [`packages.sh`](https://github.com/flatcar/scripts/blob/main/ci-automation/packages.sh) builds all binary packages for an OS image
4. [`image.sh`](https://github.com/flatcar/scripts/blob/main/ci-automation/image.sh) builds a generic OS image
5. [`vms.sh`](https://github.com/flatcar/scripts/blob/main/ci-automation/vms.sh) builds vendor-specific images

CI / build automation infrastructure should set up the steps in a build pipeline.
Artifacts of a preceding build step are fed into the succeeding step.
The scripts are meant to implement build logic in a CI agnostic manner; the concrete CI system used (Jenkins, Bamboo, etc.) should require only very minimal glue logic to run builds.

The build scripts should run on most Linux-based nodes out of the box; `git` and `docker` are the only requirements.
In the Flatcar project, we use Flatcar Container Linux on our CI worker nodes.


### Auxiliary infrastructure

Apart from infrastructure to run the CI / builds on we also need a server for caching build artifacts.
Build artifacts are mostly container images - with only few exceptions - and are almost always huge (some gigabytes).
To not overly pollute CI workers' disk space, the build scripts support an "artifact cache" server.
Requirements for this server are rather simple - it should have sufficient disk space (we use 7TB on Flatcar's CI and can hold ~50 past builds), ssh access (for rsync) and serve artifacts from the (rsync/ssh) path prefix via HTTPS.
See the `BUILDCACHE_…` settings in the [CI automation settings file](https://github.com/flatcar/scripts/blob/main/ci-automation/ci-config.env) for adapting the build scripts to your environment.

[scripts-repo-ci]: https://github.com/flatcar/scripts/tree/main/ci-automation
[mod-cl]: sdk-modifying-flatcar
