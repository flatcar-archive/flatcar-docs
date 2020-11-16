---
content_type: reference
title: update.conf
description: >
  Definitions for Flatcar update configuration.
weight: 100
---

Flatcar Container Linux uses [`update_engine`][update_engine] to check and fetch new updates from the [Nebraska Update Service](https://github.com/kinvolk/nebraska).

## Location

The client-side configuration of these updates is stored in `/etc/flatcar/update.conf`.
(there is a legacy symlink of `/etc/coreos -> /etc/flatcar` for compatibility with third-party integrations).
This file is in the user writable partition by default.

Next order of client-side configurations that are checked are:

* `/usr/share/flatcar/update.conf`
  * Generated at build time of the image/payload build
  * will typically contain:
    * `SERVER=`
    * `GROUP=`
* `/usr/share/flatcar/release`
  * Generated at build time of the image/payload build
  * will typically contain:
    * `FLATCAR_RELEASE_VERSION=`
    * `FLATCAR_RELEASE_BOARD=`
    * `FLATCAR_RELEASE_APPID=`

## Fields

Default installs of Flatcar will likely not need custom settings, and an empty or non-existing `/etc/flatcar/update.conf` file is sufficient.

* `GROUP`
  * The channel/group this host will pull updates from
  * public channels will be: `stable`, `beta`, `alpha`
  * otherwise these are UUIDs
* `SERVER`
  * The update server to reach for updates
  * default community server is: https://public.update.flatcar-linux.net/v1/update/
* `FLATCAR_RELEASE_VERSION`
  * The current version of this machine's version
* `FLATCAR_RELEASE_BOARD`
  * The board build is determined by the architecture of the machine
* `FLATCAR_RELEASE_APPID`
  * The Flatcar specific application ID
  * For Flatcar this is: `{e96281a6-d1af-4bde-9a0a-97b76e56dc57}`
* `PCR_POLICY_SERVER`
  * Server to receive the `POST`'ed TPM PCR Policy
* `DOWNLOAD_USER`
  * Authentication user for fetching the update payload
  * As the update server can redirect to a payload download that may require its own authentication
* `DOWNLOAD_PASSWORD`
  * Authentication password for fetching the update payload
  * As the update server can redirect to a payload download that may require its own authentication

_(for future-proofing, calling `git grep GetConfValue\(\"` in the [`update_engine`][update_engine] repo)_

[update_engine]: https://github.com/kinvolk/update_engine
