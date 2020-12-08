---
title: Switching from Docker to containerd for Kubernetes
weight: 10
---

In Kubernetes v1.20, `dockershim` will be deprecated and eventually removed in next releases.
You can find more information about it [here](https://kubernetes.io/blog/2020/12/02/dockershim-faq/).

The current default configuration in Flatcar does not enable the `containerd` CRI plugin which is required
by Kubelet. This means switching to `containerd` as container runtime for pods requires some configuration changes.

In future Flatcar versions this might no longer be needed. See the
[tracking issue](https://github.com/kinvolk/Flatcar/issues/284) for more details.

## Running `containerd` with CRI plugin enabled alongside with Docker

If you would like to use `containerd` as a container runtime for pods on Kubernetes, but still be able
to run standalone containers with Docker, the following Container Linux Config enables that.

The contents of `/etc/containerd/config.toml` were derived from `/run/torcx/unpack/docker/usr/share/containerd/config.toml`:

```yaml
storage:
  files:
  - path: /etc/containerd/config.toml
    filesystem: root
    mode: 0600
    contents:
      inline: |
        # persistent data location
        root = "/var/lib/containerd"
        # runtime state information
        state = "/run/docker/libcontainerd/containerd"
        # set containerd as a subreaper on linux when it is not running as PID 1
        subreaper = true
        # set containerd's OOM score
        oom_score = -999
        # CRI plugin listens on a TCP port by default
        disabled_plugins = []

        # grpc configuration
        [grpc]
        address = "/run/docker/libcontainerd/docker-containerd.sock"
        # socket uid
        uid = 0
        # socket gid
        gid = 0

        [plugins.linux]
        # shim binary name/path
        shim = "containerd-shim"
        # runtime binary name/path
        runtime = "runc"
        # do not use a shim when starting containers, saves on memory but
        # live restore is not supported
        no_shim = false
        # display shim logs in the containerd daemon's log output
        shim_debug = true
systemd:
  units:
  - name: containerd.service
    enabled: true
    dropins:
    - name: 10-use-custom-config.conf
      contents: |
        [Service]
        Environment=CONTAINERD_CONFIG=/etc/containerd/config.toml
        ExecStart=
        ExecStart=/usr/bin/env PATH=$${TORCX_BINDIR}:$${PATH} $${TORCX_BINDIR}/containerd --config $${CONTAINERD_CONFIG}
```

Then, if you run `kubelet` in a Docker container, make sure it has access
to the following directories on host file system:
- `/run/docker/libcontainerd/`
- `/var/lib/containerd/`

And that it has access to the following binaries on host file system and that they are included in PATH:

- `/run/torcx/unpack/docker/bin/containerd-shim-runc-v1`
- `/run/torcx/unpack/docker/bin/containerd-shim-runc-v2`

Finally, tell `kubelet` to use containerd by adding to it the following flags:
- `--container-runtime=remote`
- `--container-runtime-endpoint=unix:///run/docker/libcontainerd/docker-containerd.sock`

## Running only `containerd` with CRI plugin enabled

If you don't care about Docker compatibility and you only need `containerd` for Kubernetes, the following
configuration allows that:

```yaml
storage:
  files:
  - path: /etc/containerd/config.toml
    filesystem: root
    mode: 0600
    contents:
      inline: ""
systemd:
  units:
  - name: containerd.service
    enabled: true
    dropins:
    - name: 10-use-custom-config.conf
      contents: |
        [Service]
        Environment=CONTAINERD_CONFIG=/etc/containerd/config.toml
        ExecStart=
        ExecStart=/usr/bin/env PATH=$${TORCX_BINDIR}:$${PATH} $${TORCX_BINDIR}/containerd --config $${CONTAINERD_CONFIG}
```

When running `kubelet`, make sure following directory is included in its PATH:

- `/run/torcx/unpack/docker/bin/`

Finally, tell `kubelet` to use containerd by adding to it the following flags:
- `--container-runtime=remote`
- `--container-runtime-endpoint=unix:///run/containerd/containerd.sock`
