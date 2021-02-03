---
title: Switching from Docker to containerd for Kubernetes
linktitle: Switching to containerd
description: How to setup containerd to be the default Kubernetes container runtime.
weight: 20
aliases:
    - ../os/switching-from-docker-to-containerd-for-kubernetes
---

In Kubernetes v1.20, `dockershim` will be deprecated and eventually removed in next releases.
You can find more information about it [here](https://kubernetes.io/blog/2020/12/02/dockershim-faq/).

The `containerd` CRI plugin is enabled by default and you can use containerd for Kubernetes while still allowing Docker to function.

If you run `kubelet` in a Docker container, make sure it has access
to the following directories on the host file system:
- `/run/docker/libcontainerd/`
- `/var/lib/containerd/`

And that it has access to the following binaries on the host file system and that they are included in `PATH`:

- `/run/torcx/unpack/docker/bin/containerd-shim-runc-v1`
- `/run/torcx/unpack/docker/bin/containerd-shim-runc-v2`

Finally, tell `kubelet` to use containerd by adding to it the following flags:
- `--container-runtime=remote`
- `--container-runtime-endpoint=unix:///run/containerd/containerd.sock`
