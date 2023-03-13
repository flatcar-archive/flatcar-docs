---
content_type: butane
title: Butane Config Transpiler
linktitle: Butane Config Transpiler
description: Transforms Butane files into Ignition configuration
main_menu: true
weight: 30
aliases:
    - ../container-linux-config-transpiler/doc/overview
    - ../container-linux-config-transpiler
---

Butane is the utility responsible for transforming a user-provided Butane Configuration into an [Ignition][ignition] configuration. The resulting Ignition config can then be provided to a Container Linux machine when it first boots in order to provision it.

The Butane Config is intended to be human-friendly, and is thus in YAML. The syntax is rather forgiving, and things like references and multi-line strings are supported.

The resulting Ignition config is very much not intended to be human-friendly. It is an artifact produced by butane that users should simply pass along to their machines. JSON was chosen over a binary format to make the process more transparent and to allow power users to inspect/modify what butane produces, but it would have worked fine if the result from butane had not been human readable at all.

[butane]: https://github.com/coreos/butane/
[ignition]: https://github.com/kinvolk/ignition

**Note:**: Butane is utilized to generate Ignition v3+ configurations. If you are still utilizing a version of Container Linux that requires Ignition v2, you can refer to the [Container Linux Config Transpiler][cl-config] documentation. This particularly applies to those using the current LTS releases.

## Why a two-step process?

There are a couple factors motivating the decision to not incorporate support for Butane Configs directly into the boot process of Container Linux (as in, the ability to provide a Butane Config directly to a booting machine, instead of an Ignition config).

- By making users run their configs through butane before they attempt to boot a machine, issues with their configs can be caught before any machine attempts to boot. This will save users time, as they can much more quickly find problems with their configs. Were users to provide Butane Configs directly to machines at first boot, they would need to find a way to extract the Ignition logs from a machine that may have failed to boot, which can be a slow and tedious process.
- YAML parsing is a complex process that in the past has been rather error-prone. By only doing JSON parsing in the boot path, we can guarantee that the utilities necessary for a machine to boot are simpler and more reliable. We want to allow users to use YAML however, as it's much more human-friendly than JSON, hence the decision to have a tool separate from the boot path to "transpile" YAML configurations to machine-appropriate JSON ones.

## Tell me more about Ignition

[Ignition][ignition] is the utility inside of a Container Linux image that is responsible for setting up a machine. It takes in a configuration, written in JSON, that instructs it to do things like add users, format disks, and install systemd units. The artifacts that butane produces are Ignition configs. All of this should be an implementation detail however, users are encouraged to write Butane Configs for butane, and to simply pass along the produced JSON file to their machines.

## How similar are Butane Configs and Ignition configs?

Some features in Butane Configs and Ignition configs are identical.  Both support listing users for creation, systemd unit dropins for installation, and files for writing.

All of the differences stem from the fact that Ignition configs are distribution agnostic. An Ignition config can't just tell Ignition to enable etcd, because Ignition doesn't know what etcd is. The config must tell Ignition what systemd unit to enable, and provide a systemd dropin to configure etcd.

Butane on the other hand _does_ understand the specifics of Flatcar Container Linux. A user currently can't specify Clevis options on Flatcar and Butane does these sanity checks for the user.

## Example Butane Config

The following small example of a Butane Config will ensure that the default core user exists and adds a specified public key

```yaml
variant: flatcar
version: 1.0.0
passwd:
  users:
    - name: core
      ssh_authorized_keys:
        - ssh-rsa AAAAB......xyz email@host.net
```

To turn this Butane Config into a usable Ignition Config, we can then run: `docker run --rm -i quay.io/coreos/butane:latest < your_config.yaml > your_config.json`. This will result in the above YAML being turned into the below JSON

```json
{
  "ignition": {
    "version": "3.3.0"
  },
  "passwd": {
    "users": [
      {
        "name": "core",
        "sshAuthorizedKeys": [
          "ssh-rsa AAAAB......xyz email@host.net"
        ]
      }
    ]
  }
}
```

To learn more about Butane and the configurations that are available, you can refer to the latest [Butane Spec][butane-spec].

[butane-spec]: https://coreos.github.io/butane
[cl-config]: ../cl-config
