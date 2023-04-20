---
title: Cluster Architectures
linktitle: Architectures
description: Understanding different cluster sizes, how they get configured, and how machines interact with each other.
weight: 10
aliases:
    - ../../os/cluster-architectures
    - ../../clusters/creation/cluster-architectures
---

## Overview

Depending on the size and expected use of your Flatcar Container Linux cluster, you will have different architectural requirements. A few of the common cluster architectures, as well as their strengths and weaknesses, are described below.

Most of these scenarios dedicate a few machines, bare metal or virtual, to running central cluster services. These may include etcd and the distributed controllers for applications like Kubernetes, Mesos, and OpenStack. Isolating these services onto a few known machines helps to ensure they are distributed across cabinets or availability zones. It also helps in setting up static networking to allow for easy bootstrapping. This architecture helps to resolve concerns about relying on a discovery service.

## Docker dev environment on laptop

<img class="img-center" src="../../img/laptop.jpg" alt="Laptop Environment Diagram"/>
<div class="caption">Laptop development environment with Flatcar Container Linux VM</div>

| Cost | Great For          | Set Up Time | Production |
|------|--------------------|-------------|------------|
| Low  | Laptop development | Minutes     | No         |

If you're developing locally but plan to run containers in production, it's best practice to mirror that environment locally. Run Docker commands on your laptop that control a Flatcar Container Linux VM in VMware Fusion or Virtual box to mirror your container production environment locally.

### Configuring your laptop

Start a single Flatcar Container Linux VM with the Docker remote socket enabled in the Butane Config. Here's what the config looks like:

```yaml
variant: flatcar
version: 1.0.0
systemd:
  units:
    - name: docker-tcp.socket
      enabled: true
      mask: false
      contents: |
        [Unit]
        Description=Docker Socket for the API

        [Socket]
        ListenStream=2375
        BindIPv6Only=both
        Service=docker.service

        [Install]
        WantedBy=sockets.target
    - name: enable-docker-tcp.service
      enabled: true
      contents: |
        [Unit]
        Description=Enable the Docker Socket for the API
        [Service]
        Type=oneshot
        ExecStart=/usr/bin/systemctl enable docker-tcp.socket
```

This file is used to provision your local Flatcar Container Linux machine on its first boot. This sets up and enables the Docker API, which is how you can use Docker on your laptop. The Docker CLI manages containers running within the VM, *not* on your personal operating system.

Using the Butane Config Transpiler, or `butane` ([download][butane-download]), convert the above yaml into an [Ignition][ignition-getting-started]. Alternatively, copy the contents of the Igntion tab in the above example. Once you have the Ignition configuration file, pass it to your provider.
In addition to providers supported by [upstream Ignition][ignition-supported], Flatcar [supports](https://github.com/flatcar/scripts/blob/main/sdk_container/src/third_party/coreos-overlay/sys-apps/ignition/files/0018-revert-internal-oem-drop-noop-OEMs.patch) cloudsigma, hyperv, interoute, niftycloud, rackspace[-onmetal], and vagrant.

Once the local VM is running, tell your Docker binary on your personal operating system to use the remote port by exporting an environment variable and start running Docker commands. Run these commands in a terminal *on your local operating system (MacOS or Linux), not in the Flatcar Container Linux virtual machine*:

```shell
export DOCKER_HOST=tcp://localhost:2375
docker ps
```

This avoids discrepancies between your development and production environments.

### Related local installation tools

There are several different options for testing Flatcar Container Linux locally:

- [Flatcar Container Linux on QEMU][flatcar-qemu] is a feature rich way of running Flatcar Container Linux locally, provisioned by Ignition configs like the one shown above.
- [Minikube][minikube] is used for local Kubernetes development. This does not use Flatcar Container Linux but is very fast to setup and is the easiest way to test-drive use Kubernetes.

## Small cluster

<img class="img-center" src="../../img/small.jpg" alt="Small Flatcar Container Linux Cluster Diagram"/>
<div class="caption">Small Flatcar Container Linux cluster running etcd on all machines</div>

| Cost | Great For                                  | Set Up Time | Production |
|------|--------------------------------------------|-------------|------------|
| Low  | Small clusters, trying out Flatcar Container Linux | Minutes     | Yes        |

For small clusters, between 3-9 machines, running etcd on all of the machines allows for high availability without paying for extra machines that just run etcd.

Getting started is easy &mdash; a single Butane Config can be used to provision all machines in your environment.

Once you have a small cluster up and running, you can install a Kubernetes on the cluster. You can do this easily using [Typhoon][typhoon].

### Configuring the machines

For more information on getting started with this architecture, see the Flatcar Container Linux documentation on [supported platforms][flatcar-supported]. These include [Amazon EC2][flatcar-ec2], [Equinix Metal][flatcar-equinix-metal], [Azure][flatcar-azure], [Google Compute Platform][flatcar-gce], [bare metal iPXE][flatcar-bm], [Digital Ocean][flatcar-do], and many more community supported platforms.

Boot the desired number of machines with the same Butane Config and discovery token. The Butane Config specifies which services will be started on each machine.

## Easy development/testing cluster

<img class="img-center" src="../../img/dev.jpg" alt="Flatcar Container Linux cluster optimized for development and testing"/>
<div class="caption">Flatcar Container Linux cluster optimized for development and testing</div>

| Cost | Great For | Set Up Time | Production |
|------|-----------|-------------|------------|
| Low | Development/Testing | Minutes | No |

When getting started with Flatcar Container Linux, it's common to frequently boot, reboot, and destroy machines while tweaking your configuration. To avoid the need to generate new discovery URLs and bootstrap etcd, start a single etcd node, and build your cluster around it.

You can now boot as many machines as you'd like as test workers that read from the etcd node. All the features of Locksmith and etcdctl will continue to work properly but will connect to the etcd node instead of using a local etcd instance. Since etcd isn't running on all of the machines you'll gain a little bit of extra CPU and RAM to play with.

You can easily provision the remaining (non-etcd) nodes with Kubernetes using [Typhoon][typhoon] to start running containerized app with your cluster.

Once this environment is set up, it's ready to be tested. Destroy a machine, and watch Kubernetes reschedule the units, max out the CPU, and rebuild your setup automatically.

### Configuration for etcd role

Since we're only using a single etcd node, there is no need to include a discovery token. There isn't any high availability for etcd in this configuration, but that's assumed to be OK for development and testing. Boot this machine first so you can configure the rest with its IP address, which is specified with the networkd unit.

The networkd unit is typically used for bare metal installations that require static networking. See your provider's documentation for specific examples.

Here's the Butane Config for the etcd machine:

```yaml
variant: flatcar
version: 1.0.0
systemd:
  units:
    - name: etcd-member.service
      enabled: true
      dropins:
        - name: 20-clct-etcd-member.conf
          contents: |
            [Unit]
            Requires=coreos-metadata.service
            After=coreos-metadata.service
            [Service]
            Environment=ETCD_IMAGE_TAG=v3.1.5
            Environment="ETCD_NAME=etcdserver"
            ExecStart=
            ExecStart=/usr/lib/coreos/etcd-wrapper $ETCD_OPTS \
              --name="etcdserver" \
              --listen-peer-urls="http://0.0.0.0:2380" \
              --listen-client-urls="http://0.0.0.0:2379,http://0.0.0.0:4001" \
              --initial-advertise-peer-urls="http://10.0.0.101:2380" \
              --initial-cluster="etcdserver=http://10.0.0.101:2380" \
              --advertise-client-urls="http://10.0.0.101:2379"
storage:
  files:
    - path: /etc/systemd/network/00-eth0.network
      contents:
        inline: |
          [Match]
          Name=eth0

          [Network]
          DNS=1.2.3.4
          Address=10.0.0.101/24
          Gateway=10.0.0.1
```

### Configuration for worker role

This architecture allows you to boot any number of workers, from a single unit to a large cluster designed for load testing. The notable configuration difference for this role is specifying that applications like Kubernetes should use our etcd proxy instead of starting etcd server locally.

## Production cluster with central services

<img class="img-center" src="../../img/prod.jpg" alt="Flatcar Container Linux cluster optimized for production environments"/>
<div class="caption">Flatcar Container Linux cluster separated into central services and workers.</div>

| Cost | Great For | Set Up Time | Production |
|------|-----------|-------------|------------|
| High | Large bare-metal installations | Hours | Yes |

For large clusters, it's recommended to set aside 3-5 machines to run central services. Once those are set up, you can boot as many workers as you wish. Each of the workers will use your distributed etcd cluster on the central machines via local etcd proxies. This is explained in greater depth below.

### Configuration for central services role

Our central services machines will run services like etcd and Kubernetes controllers that support the rest of the cluster. etcd is configured with static networking and a peers list.

Here's an example Butane Config for one of the central service machines. Be sure to generate a new discovery token with the initial size of your cluster:

```yaml
variant: flatcar
version: 1.0.0
systemd:
  units:
    - name: etcd-member.service
      enabled: true
      dropins:
        - name: 20-clct-etcd-member.conf
          contents: |
            [Unit]
            Requires=coreos-metadata.service
            After=coreos-metadata.service
            [Service]
            Environment=ETCD_IMAGE_TAG=v3.1.5
            Environment="ETCD_NAME=etcdserver"
            ExecStart=
            ExecStart=/usr/lib/coreos/etcd-wrapper $ETCD_OPTS \
              --name="etcdserver" \
              --listen-peer-urls="http://10.0.0.101:2380" \
              --listen-client-urls="http://0.0.0.0:2379" \
              --initial-advertise-peer-urls="http://10.0.0.101:2380" \
              --initial-cluster="etcdserver=http://10.0.0.101:2380" \
              --advertise-client-urls="http://10.0.0.101:2379" \
              --discovery="https://discovery.etcd.io/<token>"
# generate a new token for each unique cluster from https://discovery.etcd.io/new?size=3
# specify the initial size of your cluster with ?size=X
storage:
  files:
    - path: /etc/systemd/network/00-eth0.network
      contents:
        inline: |
          [Match]
          Name=eth0

          [Network]
          DNS=1.2.3.4
          Address=10.0.0.101/24
          Gateway=10.0.0.1
```

[butane-download]: https://github.com/coreos/butane/releases
[ignition-getting-started]: https://github.com/coreos/ignition/blob/main/docs/getting-started.md
[ignition-supported]: https://github.com/coreos/ignition/blob/main/docs/supported-platforms.md
[flatcar-qemu]: ../../installing/vms/qemu
[minikube]: https://github.com/kubernetes/minikube
[nebraska-update]: https://github.com/kinvolk/nebraska
[flatcar-channels]: https://www.flatcar-linux.org/releases/
[flatcar-supported]: ../../
[flatcar-ec2]: ../../installing/cloud/aws-ec2
[flatcar-equinix-metal]: ../../installing/cloud/equinix-metal
[flatcar-azure]: ../../installing/cloud/azure
[flatcar-gce]: ../../installing/cloud/gcp
[flatcar-do]: ../../installing/cloud/digitalocean
[flatcar-bm]: ../../installing/bare-metal/booting-with-ipxe
[typhoon]: https://github.com/poseidon/typhoon
