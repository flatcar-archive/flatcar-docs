---
title: Flatcar tutorial
linktitle: Tutorial
weight: 2
---

# Introduction

This tutorial is a deep dive into some Flatcar fundamental concepts, it is designed to give you the key elements and resources to become autonomous with Flatcar. If you want to have a quickstart, please have a look to the [quickstart guide][quickstart].

# Requirements

* Linux VM with nested virtualization (or Linux host with KVM)
* `qemu`
* `terraform` (https://developer.hashicorp.com/terraform/downloads)
* `butane` (can be used from the Docker image or directly from the binary: https://coreos.github.io/butane/getting-started/#getting-butane)
* (OpenStack credentials for the "Hands-on 3")

For each covered item, there is a demo and a few lines to explain what's going on under the hood - each item is independent, but it's recommended to follow them in the given order, especially if it is your first time operating Flatcar.

* [Hands-on 1][hands-on-1]: Discovering
* [Hands-on 2][hands-on-2]: Provisioning
* [Hands-on 3][hands-on-3]: Deploying
* [Hands-on 4][hands-on-4]: Updating

[hands-on-1]: hands-on-1
[hands-on-2]: hands-on-2
[hands-on-3]: hands-on-3
[hands-on-4]: hands-on-4
[quickstart]: ../installing
