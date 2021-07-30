---
title: Switching to Unified Cgroups
linktitle: Switching to unified cgroups
description: Overview of changes necessary to use unified cgroups with Kubernetes
weight: 20
aliases:
---

With the upgrade to Systemd v248, Flatcar Linux has migrated to the unified
cgroup hierarchy (aka cgroup v2). Much of the container ecosystem has already
moved to default to cgroup v2. Cgroup v2 also brings new and exciting features related to
eBPF tracing.

Flatcar nodes deployed prior to this change will be kept on cgroup v1 (legacy
hierarchy) and will require manual migration. During an update from an older
Flatcar version, a post installation script adds the kernel command line
parameter `systemd.unified_cgroup_hierarchy=0` to `/usr/share/oem/grub.cfg`. To
migrate such nodes to cgroup v2, either remove the line or change it to
`systemd.unified_cgroup_hierarchy=1`.

Newly deployed nodes will default to cgroup v2.  To revert to cgroup v1 on such
nodes, use the following ignition snippet:

```yaml
storage:
  filesystems:
    - name: "OEM"
      mount:
        device: "/dev/disk/by-label/OEM"
        format: "btrfs"
  files:
    - filesystem: "OEM"
      path: "/grub.cfg"
      mode: 0644
      append: true
      contents:
        inline: |
          set linux_append="$linux_append systemd.unified_cgroup_hierarchy=0"
```

A reboot is required before the snippet becomes active.

Beware that over time it is expected that upstream projects will drop support for cgroup v1.

The unified cgroup hierarchy is supported starting with Docker v20.10 and
Kubernetes v1.19. Users that need to run older version will need to revert to
cgroup v1, but are urged to find a migration path. Flatcar now ships with Docker
v20.10, older versions can be deployed following the instructions on [running custom docker versions](use-a-custom-docker-or-containerd-version).

Flatcar nodes that had Kubernetes deployed on them before the introduction of
cgroup v2 should be careful when migrating. Depending on the deployment method,
the `cgroupfs` cgroup driver may be hardcoded in the `kubelet` configuration.
Cgroup v2 is only supported with the `systemd` cgroup driver. See [configuring a cgroup driver][kube-cgroup-docs] in the Kubernetes documentation for a discussion of cgroup drivers and how to migrate nodes. We recommend redeploying Kubernetes on fresh nodes instead of migrating inplace.

The cgroup driver used by `kubelet` should be the same as the one used by `docker` daemon. `docker` defaults to `systemd` cgroup driver when started on a system running cgroup v2 and `cgroupfs` when running on a system with cgroup v1. The cgroup driver can be explicitly configured for `docker` by either creating/extending `/etc/docker/daemon.json`:
```json
{
  "exec-opts": ["native.cgroupdriver=systemd"]
}
```
or adding a `docker.service` drop-in at `/etc/systemd/system/docker.service.d/10-cgroup-v2.conf`:
```ini
[Service]
Environment="DOCKER_CGROUPS=--exec-opt native.cgroupdriver=systemd"
```
[kube-cgroup-docs]: https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/configure-cgroup-driver/#migrating-to-the-systemd-driver