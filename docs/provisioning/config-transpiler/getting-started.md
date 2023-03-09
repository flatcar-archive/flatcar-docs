---
title: Getting Started
weight: 10
aliases:
    - ../../container-linux-config-transpiler/doc/getting-started
    - ../../container-linux-config-transpiler/getting-started
---


`butane` is a tool that will consume a Butane configuration and produce an Ignition configuration file that can be given to a Container Linux machine when it first boots to set the machine up. Using this config, a machine can be told to create users, format the root filesystem, set up the network, install systemd units, and more.

Butane configuration are YAML files conforming to Butane's schema. For more information on the schema, take a look at [configuration][1].

`butane` can be downloaded from its [GitHub Releases page][4] or used via Docker (`docker run --rm -i quay.io/coreos/butane:latest < butane_config.yaml > ignition_config.json`).

As a simple example, let's use `butane` to set the authorized ssh key for the core user on a Container Linux machine.

```yaml
variant: flatcar
version: 1.0.0
passwd:
  users:
    - name: core
      ssh_authorized_keys:
        - ssh-rsa AAAAB3NzaC1yc...
```

In this above file, you'll want to set the `ssh-rsa AAAAB3NzaC1yc...` line to be your ssh public key (which is probably the contents of `~/.ssh/id_rsa.pub`, if you're on Linux).

If we take this file and give it to `butane`:

```
$ docker run --rm -i quay.io/coreos/butane:latest < butane_config.yaml
{"ignition":{"version":"3.3.0"},"passwd":{"users":[{"name":"core","sshAuthorizedKeys":["ssh-rsa AAAAB3NzaC1yc..."]}]}}
```

We can see that it produces a JSON file. This file isn't intended to be human-friendly, and will definitely be a pain to read/edit (especially if you have multi-line things like systemd units). Luckily, you shouldn't have to care about this file! Just provide it to a booting Container Linux machine and Ignition, the utility inside of Container Linux that receives this file, will know what to do with it.

The method by which this file is provided to a Container Linux machine depends on the environment in which the machine is running. For instructions on a given provider, head over to the [list of supported platforms for Ignition][2].

To see some examples for what else ct can do, head over to the [examples][3].

[1]: ../config-transpiler/configuration
[2]: https://coreos.github.io/ignition/supported-platforms/
[3]: https://coreos.github.io/butane/examples/
[4]: https://github.com/coreos/butane/releases
