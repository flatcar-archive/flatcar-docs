---
title: Switching to Unified Cgroups
linktitle: Switching to unified cgroups
description: Overview of changes necessary to use unified cgroups with Kubernetes
weight: 20
aliases:
---

Beginning with Flatcar version 2969.0.0, Flatcar Linux has migrated to the unified
cgroup hierarchy (aka cgroup v2). Much of the container ecosystem has already
moved to default to cgroup v2. Cgroup v2 brings exciting new features in
areas such as eBPF and rootless containers.

Flatcar nodes deployed prior to this change will be kept on cgroups v1 (legacy
hierarchy) and will require manual migration. During an update from an older
Flatcar version, a post update script does two things:

* adds the kernel command line parameters `systemd.unified_cgroup_hierarchy=0 systemd.legacy_systemd_cgroup_controller`
  to `/usr/share/oem/grub.cfg`
* creates a systemd drop-in unit at `/etc/systemd/system/containerd.service.d/10-use-cgroupfs.conf` that
  configures `containerd` to keep using cgroupfs for cgroups.

# Migrating old nodes to unified cgroups

To undo the changes performed by the post update script, execute the following commands as root (or using `sudo`):

```bash
rm /etc/systemd/system/containerd.service.d/10-use-cgroupfs.conf
sed -i -e '/systemd.unified_cgroup_hierarchy=0/d' /usr/share/oem/grub.cfg
sed -i -e '/systemd.legacy_systemd_cgroup_controller/d' /usr/share/oem/grub.cfg
reboot
```

# Starting new nodes with legacy cgroups

Nodes deployed with the release incorporating the described changes use cgroups v2 by default. To revert to cgroups v1 on new
nodes during provisioning, use the following Ignition snippet (here as CLC YAML to be transpiled to Ignition JSON):

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
          set linux_append="$linux_append systemd.unified_cgroup_hierarchy=0 systemd.legacy_systemd_cgroup_controller"
systemd:
  units:
    - name: containerd.service
      dropins:
        - name: 10-use-cgroupfs.conf
          contents: |
            [Service]
            Environment=CONTAINERD_CONFIG=/usr/share/containerd/config-cgroupfs.toml
```

However, the kernel commandline setting doesn't take effect on the first boot, and a reboot is required before the snippet becomes active.

Beware that over time it is expected that upstream projects will drop support for cgroups v1.

# Kubernetes

The unified cgroup hierarchy is supported starting with Docker v20.10 and
Kubernetes v1.19. Users that need to run older version will need to revert to
cgroups v1, but are urged to find a migration path. Flatcar now ships with Docker
v20.10, older versions can be deployed following the instructions on [running custom docker versions](use-a-custom-docker-or-containerd-version).

Flatcar nodes that had Kubernetes deployed on them before the introduction of
cgroups v2 should be careful when migrating. Depending on the deployment method,
the `cgroupfs` cgroup driver may be hardcoded in the `kubelet` configuration.
Cgroups v2 are only supported with the `systemd` cgroup driver. See [configuring a cgroup driver][kube-cgroup-docs] in the Kubernetes documentation for a discussion of cgroup drivers and how to migrate nodes. We recommend redeploying Kubernetes on fresh nodes instead of migrating inplace.

The cgroup driver used by `kubelet` should be the same as the one used by `docker` daemon. `docker` defaults to `systemd` cgroup driver when started on a system running cgroup v2 and `cgroupfs` when running on a system with cgroup v1. The cgroup driver can be explicitly configured for `docker` by extending `/etc/docker/daemon.json`:
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

## Container Runtimes

When deploying Kubernetes through `kubeadm`, the default container runtime on Flatcar is currently `dockershim`. In this setup, `kubelet` talks to `dockershim`, which talks to `docker`, which interfaces with `containerd`. The `SystemdCgroup` setting in `containerd`'s `config.toml` is ignored. `docker`'s cgroup driver and `kubelet` cgroup driver settings must match. Starting with Kubernetes v1.22, `kubeadm` will default to the `systemd` `cgroupDriver` setting if no setting is provided explicitly. Out of the box, Flatcar defaults are compatible with Docker and Kubernetes defaults - everything will use `systemd` cgroup driver.

When using `kubeadm`, add the snippet to your `kubeadm-config.yaml` to configure the `kubelet` cgroup driver:

```yaml
---
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
cgroupDriver: systemd
```

## Containerd

If users choose the `containerd` runtime, they must ensure that `containerd`'s setting for `SystemdCgroup` is consistent with `kubelet` and `docker` settings. Flatcar enables `SystemdCgroup` by default for `containerd`. Users may change the setting to suit their deployment.
If you maintain your own containerd configuration or did follow the instructions on
[how to customize containerd configuration](customizing-docker), you should add the relevant lines to your `config.toml`:
```toml
version = 2

[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
  # setting runc.options unsets parent settings
  runtime_type = "io.containerd.runc.v2"
  [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
    SystemdCgroup = true
 ```
 
For a more detailed discussion of container runtimes, see the [Kubernetes documentation][kube-runtime-docs].

## Known issues

* `aws/amazon-ecs-agent` does not support `cgroupsv2`: [Flatcar issue](https://github.com/flatcar-linux/Flatcar/issues/585), [AWS issue](https://github.com/aws/containers-roadmap/issues/1535).


[kube-cgroup-docs]: https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/configure-cgroup-driver/#migrating-to-the-systemd-driver
[kube-runtime-docs]: https://kubernetes.io/docs/setup/production-environment/container-runtimes/
