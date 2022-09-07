---
title: SELinux on Flatcar Container Linux
linktitle: SELinux
description: How to configure, enable or disable SELinux.
weight: 10
aliases:
    - ../../os/selinux
    - ../../clusters/securing/selinux
---

SELinux is a fine-grained access control mechanism integrated into Flatcar Container Linux and rkt. Each container runs in its own independent SELinux context, increasing isolation between containers and providing another layer of protection should a container be compromised.

Flatcar Container Linux implements SELinux, but currently does not enforce SELinux protections by default. This allows deployers to verify container operation before enabling SELinux enforcement. This document covers the process of checking containers for SELinux policy compatibility, and switching SELinux into `enforcing` mode.

## Check a container's compatibility with SELinux policy

To verify whether the current SELinux policy would inhibit your containers, enable SELinux logging. In the following set of commands, we delete the rules that suppress this logging by default, and copy the policy store from Flatcar Container Linux's read-only `/usr` to a writable file system location.

```shell
rm /etc/audit/rules.d/80-selinux.rules
rm /etc/audit/rules.d/99-default.rules
rm /etc/selinux/mcs
cp -a /usr/lib/selinux/mcs /etc/selinux
rm /var/lib/selinux
cp -a /usr/lib/selinux/policy /var/lib/selinux
semodule -DB
systemctl restart audit-rules
```

Now run your container. Check the system logs for any messages containing `avc: denied`. Such messages indicate that an `enforcing` SELinux would prevent the container from performing the logged operation. Please open an issue on [github][gh-flatcar], including the full avc log message.

## Enable SELinux enforcement

Once satisfied that your container workload is compatible with the SELinux policy, you can temporarily enable enforcement by running the following command as root:

`$ setenforce 1`

A reboot will reset SELinux to `permissive` mode.

### Make SELinux enforcement permanent

To enable SELinux enforcement across reboots, replace the symbolic link `/etc/selinux/config` with the file it targets, so that the file can be written. You can use the `readlink` command to dereference the link, as shown in the following one-liner:

`$ cp --remove-destination $(readlink -f /etc/selinux/config) /etc/selinux/config`

Now, edit `/etc/selinux/config` to replace `SELINUX=permissive` with `SELINUX=enforcing`.

## Limitations

* SELinux enforcement is currently incompatible with Btrfs volumes and volumes that are shared between multiple containers.
* Starting from Flannel-0.15 installed via `kube-flannel.yml`, SELinux enforcement will prevent the CNI installation on the host. (See: [flatcar-linux/Flatcar#635][flannel-issue])


[gh-flatcar]: https://github.com/kinvolk/Flatcar/issues
[flannel-issue]: https://github.com/flatcar/Flatcar/issues/635
