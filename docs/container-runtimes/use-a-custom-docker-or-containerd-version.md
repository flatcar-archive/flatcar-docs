---
title: Using a custom Docker or containerd version
linktitle: Using custom versions
description: How to download and run a different version of docker or containerd than the one shipped by Flatcar.
weight: 30
aliases:
    - ../os/use-a-custom-docker-or-containerd-version
---

Some system tooling can't be run on Container Linux via containers and this is especially true for the container runtime itself.
As with other special binaries you want to bring to the system you can use an Ignition config that downloads the binaries.

For custom Docker binaries you can consider to use the [Torcx](../provisioning/torcx/) addon manager when you build your own Torcx image and profile.
However, since the Torcx makes certain assumtions about the files being shipped you may find it too limiting (e.g., the wrapper scripts under `/usr/bin/` exist for only a fixed set of binaries).
In this case you can directly place the custom binaries to `/opt/bin/` as done by the following Container Linux Config which you can transpile to an Ignition config with [`ct`](../provisioning/config-transpiler/).

This replicates the Docker setup as of Flatcar Container Linux 2605.10.0 but under `/etc` and `/opt/bin/`, and with additional support for the upstream Containerd socket location. You can modify it to use different socket paths or plugins, or even only ship `containerd` if you don't need Docker.

```
systemd:
  units:
    - name: prepare-docker.service
      enabled: true
      contents: |
        [Unit]
        Description=Unpack docker binaries to /opt/bin
        ConditionPathExists=!/opt/bin/docker
        [Service]
        Type=oneshot
        RemainAfterExit=true
        Restart=on-failure
        ExecStartPre=/usr/bin/mkdir -p /opt/bin
        ExecStartPre=/usr/bin/tar -v --extract --file /opt/docker.tgz --directory /opt/ --no-same-owner
        ExecStartPre=/usr/bin/rm /opt/docker.tgz
        ExecStartPre=/usr/bin/sh -c "mv /opt/docker/* /opt/bin/"
        ExecStart=/usr/bin/rmdir /opt/docker
        [Install]
        WantedBy=multi-user.target
    - name: docker.socket
      enabled: true
      contents: |
        [Unit]
        PartOf=docker.service
        Description=Docker Socket for the API
        [Socket]
        ListenStream=/var/run/docker.sock
        SocketMode=0660
        SocketUser=root
        SocketGroup=docker
        [Install]
        WantedBy=sockets.target
    - name: docker.service
      enabled: false
      contents: |
        [Unit]
        Description=Docker Application Container Engine
        After=containerd.service docker.socket network-online.target prepare-docker.service
        Wants=network-online.target
        Requires=containerd.service docker.socket prepare-docker.service
        [Service]
        Type=notify
        EnvironmentFile=-/run/flannel/flannel_docker_opts.env
        Environment=DOCKER_SELINUX=--selinux-enabled=true
        # the default is not to use systemd for cgroups because the delegate issues still
        # exists and systemd currently does not support the cgroup feature set required
        # for containers run by docker
        Environment=PATH=/opt/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin
        ExecStart=/opt/bin/dockerd --host=fd:// --containerd=/run/docker/libcontainerd/docker-containerd.sock $DOCKER_SELINUX $DOCKER_OPTS $DOCKER_CGROUPS $DOCKER_OPT_BIP $DOCKER_OPT_MTU $DOCKER_OPT_IPMASQ
        ExecReload=/bin/kill -s HUP $MAINPID
        LimitNOFILE=1048576
        # Having non-zero Limit*s causes performance problems due to accounting overhead
        # in the kernel. We recommend using cgroups to do container-local accounting.
        LimitNPROC=infinity
        LimitCORE=infinity
        # Uncomment TasksMax if your systemd version supports it.
        # Only systemd 226 and above support this version.
        TasksMax=infinity
        TimeoutStartSec=0
        # set delegate yes so that systemd does not reset the cgroups of docker containers
        Delegate=yes
        # kill only the docker process, not all processes in the cgroup
        KillMode=process
        # restart the docker process if it exits prematurely
        Restart=on-failure
        StartLimitBurst=3
        StartLimitInterval=60s
        [Install]
        WantedBy=multi-user.target
    - name: containerd.service
      enabled: false
      contents: |
        [Unit]
        Description=containerd container runtime
        After=network.target prepare-docker.service
        Requires=prepare-docker.service
        [Service]
        Delegate=yes
        Environment=PATH=/opt/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin
        ExecStartPre=mkdir -p /run/docker/libcontainerd
        ExecStartPre=ln -fs /run/containerd/containerd.sock /run/docker/libcontainerd/docker-containerd.sock
        ExecStart=/opt/bin/containerd --config /etc/containerd/config.toml
        KillMode=process
        Restart=always
        # (lack of) limits from the upstream docker service unit
        LimitNOFILE=1048576
        LimitNPROC=infinity
        LimitCORE=infinity
        TasksMax=infinity
        [Install]
        WantedBy=multi-user.target
storage:
  files:
    - path: /etc/systemd/system-generators/torcx-generator
    - path: /opt/docker.tgz
      filesystem: root
      mode: 0644
      contents:
        remote:
          url: https://download.docker.com/linux/static/stable/x86_64/docker-19.03.14.tgz
    - path: /etc/containerd/config.toml
      filesystem: root
      mode: 0644
      contents:
        inline: |
          # persistent data location
          root = "/var/lib/containerd"
          # runtime state information
          state = "/run/containerd"
          # set containerd as a subreaper on linux when it is not running as PID 1
          subreaper = true
          # set containerd's OOM score
          oom_score = -999
          disabled_plugins = []
          # grpc configuration
          [grpc]
          address = "/run/containerd/containerd.sock"
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
```

While the system services have a `PATH` variable that prefers `/opt/bin/` by placing it first, you have to run the following command on every interactive login shell (also after `sudo` or `su`) to make sure you use the correct binaries.

```sh
export PATH="/opt/bin:$PATH"
```

The empty file `/etc/systemd/system-generators/torcx-generator` serves the purpose of disabling Torcx to make sure it is not used accidentally in case `/opt/bin` was missing from the `PATH` variable.
