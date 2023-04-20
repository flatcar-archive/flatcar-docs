---
title: Flatcar Container Linux hardening guide
linktitle: Hardening options
description: Disabling unnecessary services and other hardening options.
weight: 20
aliases:
    - ../../os/hardening-guide
    - ../../clusters/securing/hardening-guide
---

This guide covers the basics of securing a Flatcar Container Linux instance. Flatcar Container Linux has a very slim network profile and the only service that listens by default on Flatcar Container Linux is sshd on port 22 on all interfaces. There are also some defaults for local users and services that should be considered.

## Remote listening services

### Disabling sshd

To disable sshd from listening you can stop the socket:

```shell
systemctl mask sshd.socket --now
```

If you wish to make further customizations see our [customize sshd guide][sshd-guide].

## Remote non-listening services

### etcd and Locksmith

etcd and Locksmith should be secured and authenticated using TLS if you are using these services. Please see the relevant guides for details.

* [etcd security guide][etcd-sec-guide]

## Local services

### Local users

Flatcar Container Linux has a single default user account called "core". Generally this user is the one that gets ssh keys added to it via a Butane Config for administrators to login. The core user, by default, has access to the wheel group which grants sudo access. The group can't be easily changed and thus the solution to restrict access is to either require a password for sudo but not setting one, or disable login for the `core` user.

A sudo drop-in can be created under `/etc/sudoers.d/core-passwd` with the contents `core	ALL=(ALL) 	ALL` and as long as the core user has no password set it can't use `sudo`. Here is a Butane snippet:

```
variant: flatcar
version: 1.0.0
storage:
  files:
    - path: /etc/sudoers.d/core-passwd
      mode: 0644
      contents:
        inline: |
          core	ALL=(ALL) 	ALL
```

You can disable the `core` user by setting the login shell to `/sbin/nologin`, here a Butane snippet:

```yaml
variant: flatcar
version: 1.0.0
passwd:
  users:
    - name: core
      shell: /sbin/nologin
```

### Docker daemon

The docker daemon is accessible via a unix domain socket at `/run/docker.sock`. Users in the "docker" group have access to this service and access to the docker socket grants similar capabilities to sudo. The core user, by default, has access to the docker group. The group can't be easily changed and thus the solution to restrict access is to disable login for the `core` user or restrict the Docker socket permissions.

You can restrict the Docker socket to root by creating a unit drop-in for `docker.socket` in `/etc/systemd/system/docker.socket.d/10-restrict.conf`, here a Butane snippet:

```
variant: flatcar
version: 1.0.0
systemd:
  units:
    - name: docker.socket
      dropins:
        - name: 10-restrict.conf
          contents: |
            [Socket]
            SocketGroup=root
```

## Additional hardening

### Disabling Simultaneous Multi-Threading

Recent Intel CPU vulnerabilities cannot be fully mitigated in software without disabling Simultaneous Multi-Threading. This can have a substantial performance impact and is only necessary for certain workloads, so for compatibility reasons, SMT is enabled by default.

The [SMT on Container Linux guide][smt-guide] provides guidance and instructions for disabling SMT.

### Disable USB

If you don't expect to ever use USB, you can disable the kernel module, here a Butane snippet:

```
variant: flatcar
version: 1.0.0
storage:
  files:
    - path: /etc/modprobe.d/blacklist.conf
      mode: 0644
      contents:
        inline: |
          blacklist usb-storage
```

### SELinux

SELinux is a fine-grained access control mechanism integrated into Flatcar Container Linux. Each container runs in its own independent SELinux context, increasing isolation between containers and providing another layer of protection should a container be compromised.

Flatcar Container Linux implements SELinux, but currently does not enforce SELinux protections by default. The [SELinux on Flatcar Container Linux guide][selinux-guide] covers the process of checking containers for SELinux policy compatibility and switching SELinux into enforcing mode.

[smt-guide]: disabling-smt
[sshd-guide]: customizing-sshd
[etcd-sec-guide]: https://etcd.io/docs/v3.4.0/op-guide/security/
[selinux-guide]: selinux
