---
title: Getting started with Kubernetes
description: Operate Kubernetes from Flatcar
weight: 11
---

One of the Flatcar purposes is to run container workloads, this term is quite generic: it goes from running a single Docker container to operate a Kubernetes cluster.

This documentation will cover preliminary aspects of operating Kubernetes cluster based on Flatcar.

# Supported Kubernetes version

A Kubernetes basic scenario (deploy a simple Nginx) is being tested on Flatcar accross the channels and various CNIs, it mainly ensures that Kubernetes can be correctly installed and can operate in a simple way.

One way to contribute to Flatcar would be to extend the covered CNIs (example: [kubenet][kubenet]) or to provide more complex scenarios (example: [cilium extension][cilium]).

This is a compatibility matrix between Flatcar and Kubernetes:
| :arrow_down: Flatcar channel \ Kubernetes Version :arrow_right: | 1.23               | 1.24               | 1.25               | 1.26               |
|--------------------------------------|--------------------|--------------------|--------------------|--------------------|
| Alpha                                | :large_orange_diamond: | :white_check_mark: | :white_check_mark: | :white_check_mark: |
| Beta                                 | :large_orange_diamond: | :white_check_mark: | :white_check_mark: | :white_check_mark: |
| Stable                               | :large_orange_diamond: | :white_check_mark: | :white_check_mark: | :white_check_mark: |
| LTS                                  | :large_orange_diamond: | :white_check_mark: | :white_check_mark: | :x:                |

:large_orange_diamond:: The version is not tested anymore before a release but was known for working.

Tested CNIs:
- Cilium
- Flannel
- Calico

_Known issues_:
* Flannel > 0.17.0 does not work with enforced SELinux ([flatcar#779][flatcar-779])
* Cilium needs to be patched regarding SELinux labels to work (even in permissive mode) ([flatcar#891][flatcar-891])

# Deploy a Kubernetes cluster with Flatcar

## Using Kubeadm

`kubeadm` remains one standard way to quickly deploy and operate a Kubernetes cluster. It's possible to install the tools (`kubeadm`, `kubelet`, etc.) using Ignition.

### Setup the control plane

Here's an example with [butane][butane] to setup a control plane.

:warning: To ease the reading, we voluntarily omitted the checksums of the downloaded artifacts.

```yaml
---
version: 1.0.0
variant: flatcar
storage:
  files:
    - path: /opt/bin/kubectl
      mode: 0755
      contents:
        source: https://storage.googleapis.com/kubernetes-release/release/v1.26.0/bin/linux/amd64/kubectl
    - path: /opt/bin/kubeadm
      mode: 0755
      contents:
        source: https://storage.googleapis.com/kubernetes-release/release/v1.26.0/bin/linux/amd64/kubeadm
    - path: /opt/bin/kubelet
      mode: 0755
      contents:
        source: https://storage.googleapis.com/kubernetes-release/release/v1.26.0/bin/linux/amd64/kubelet
    - path: /etc/systemd/system/kubelet.service
      contents:
        source: https://raw.githubusercontent.com/kubernetes/release/v0.14.0/cmd/kubepkg/templates/latest/deb/kubelet/lib/systemd/system/kubelet.service
    - path: /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
      contents:
        source: https://raw.githubusercontent.com/kubernetes/release/v0.14.0/cmd/kubepkg/templates/latest/deb/kubeadm/10-kubeadm.conf
    - path: /etc/kubeadm.yml
      contents:
        inline: |
          apiVersion: kubeadm.k8s.io/v1beta2
          kind: InitConfiguration
          nodeRegistration:
            kubeletExtraArgs:
              volume-plugin-dir: "/opt/libexec/kubernetes/kubelet-plugins/volume/exec/"
          ---
          apiVersion: kubeadm.k8s.io/v1beta2
          kind: ClusterConfiguration
          controllerManager:
            extraArgs:
              flex-volume-plugin-dir: "/opt/libexec/kubernetes/kubelet-plugins/volume/exec/"
systemd:
  units:
    - name: kubelet.service
      enabled: true
      dropins:
        - name: 20-kubelet.conf
          contents: |
            [Service]
            ExecStart=
            ExecStart=/opt/bin/kubelet $KUBELET_KUBECONFIG_ARGS $KUBELET_CONFIG_ARGS $KUBELET_KUBEADM_ARGS $KUBELET_EXTRA_ARGS
    - name: kubeadm.service
      enabled: true
      contents: |
        [Unit]
        Description=Kubeadm service
        Requires=containerd.service
        After=containerd.service
        ConditionPathExists=!/etc/kubernetes/kubelet.conf

        [Service]
        Environment="PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/opt/bin"
        ExecStartPre=/opt/bin/kubeadm config images pull
        ExecStartPre=/opt/bin/kubeadm init --config /etc/kubeadm.yml
        ExecStartPre=/usr/bin/mkdir /home/core/.kube
        ExecStartPre=/usr/bin/cp /etc/kubernetes/admin.conf /home/core/.kube/config
        ExecStart=/usr/bin/chown -R core:core /home/core/.kube

        [Install]
        WantedBy=multi-user.target
```

This minimal configuration can be used with Flatcar on QEMU (:warning: be sure that the instance has enough memory: 4096mb is good).

```bash
butane < config.yaml > config.json
./flatcar_production_qemu.sh -i config.json -- -curses
kubectl get nodes
NAME        STATUS     ROLES           AGE    VERSION
localhost   NotReady   control-plane   6m5s   v1.26.0
```

The control plane will appear has non-ready until a CNI is deployed, here's an example with calico:
```bash
kubectl \
  apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.24.1/manifests/calico.yaml
kubectl get nodes
NAME        STATUS   ROLES           AGE     VERSION
localhost   Ready    control-plane   8m30s   v1.26.0
```

We can now prepare the nodes to join the cluster.

### Setup the nodes

Here's the [butane][butane] configuration to setup the nodes.

```yaml
---
version: 1.0.0
variant: flatcar
storage:
  files:
    - path: /opt/bin/kubeadm
      mode: 0755
      contents:
        source: https://storage.googleapis.com/kubernetes-release/release/v1.26.0/bin/linux/amd64/kubeadm
    - path: /opt/bin/kubelet
      mode: 0755
      contents:
        source: https://storage.googleapis.com/kubernetes-release/release/v1.26.0/bin/linux/amd64/kubelet
    - path: /etc/systemd/system/kubelet.service
      contents:
        source: https://raw.githubusercontent.com/kubernetes/release/v0.14.0/cmd/kubepkg/templates/latest/deb/kubelet/lib/systemd/system/kubelet.service
    - path: /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
      contents:
        source: https://raw.githubusercontent.com/kubernetes/release/v0.14.0/cmd/kubepkg/templates/latest/deb/kubeadm/10-kubeadm.conf
systemd:
  units:
    - name: kubelet.service
      enabled: true
      dropins:
        - name: 20-kubelet.conf
          contents: |
            [Service]
            ExecStart=
            ExecStart=/opt/bin/kubelet $KUBELET_KUBECONFIG_ARGS $KUBELET_CONFIG_ARGS $KUBELET_KUBEADM_ARGS $KUBELET_EXTRA_ARGS
    - name: kubeadm.service
      enabled: true
      contents: |
        [Unit]
        Description=Kubeadm service
        Requires=containerd.service
        After=containerd.service

        [Service]
        Environment="PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/opt/bin"
        ExecStart=/opt/bin/kubeadm join <output from 'kubeadm token create --print-join-command'>

        [Install]
        WantedBy=multi-user.target
```

This method is far from being ideal in terms of infrastructure as code as it requires a two steps manipulation: create the control plane to generate the join configuration then pass that configuration to the nodes. Other solutions exist to make things easier, like Cluster API or [Typhoon][typhoon].

## Cluster API

From the official [documentation][capi-documentation]:
> Cluster API is a Kubernetes sub-project focused on providing declarative APIs and tooling to simplify provisioning, upgrading, and operating multiple Kubernetes clusters.

As it requires to have some tools already installed on the OS to work correcly with CAPI, Flatcar images can be built using the [image-builder][image-builder] project.

While CAPI is an evolving project and Flatcar support is in-progress regarding the various providers, here's the current list of supported providers:
* [AWS][capi-aws]
* [Azure][capi-azure]
* [vSphere][capi-vsphere]

[butane]: https://coreos.github.io/butane/
[capi-documentation]: https://cluster-api.sigs.k8s.io/
[capi-aws]: https://cluster-api-aws.sigs.k8s.io/
[capi-azure]: https://capz.sigs.k8s.io/
[capi-vsphere]: https://github.com/kubernetes-sigs/cluster-api-provider-vsphere
[cilium]: https://github.com/flatcar/mantle/pull/292
[flatcar-779]: https://github.com/flatcar/Flatcar/issues/779
[flatcar-891]: https://github.com/flatcar/Flatcar/issues/891
[image-builder]: https://github.com/kubernetes-sigs/image-builder
[kubenet]: https://github.com/flatcar/Flatcar/issues/579
[typhoon]: https://typhoon.psdn.io/
