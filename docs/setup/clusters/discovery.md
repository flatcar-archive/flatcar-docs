---
title: Cluster discovery
description: How to configure etcd so that cluster discovery works on your Flatcar clusters.
weight: 10
aliases:
    - ../../os/cluster-discovery
    - ../../clusters/creation/cluster-discovery
---

## Overview

Flatcar Container Linux uses etcd, a service running on each machine, to handle coordination between software running on the cluster. For a group of Flatcar Container Linux machines to form a cluster, their etcd instances need to be connected.

A discovery service, [https://discovery.etcd.io](https://discovery.etcd.io), is provided as a free service to help connect etcd instances together by storing a list of peer addresses, metadata and the initial size of the cluster under a unique address, known as the discovery URL. You can generate them very easily:

```shell
$ curl -w "\n" 'https://discovery.etcd.io/new?size=3'
https://discovery.etcd.io/6a28e078895c5ec737174db2419bb2f3
```

The discovery URL can be provided to each Flatcar Container Linux machine
via [Butane Configs](../../provisioning/config-transpiler). The rest of this guide will
explain what's happening behind the scenes, but if you're trying to get
clustered as quickly as possible, all you need to do is provide a _fresh,
unique_ discovery token in your config.

Boot each one of the machines with identical Butane Config and they should be automatically clustered:

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
            EnvironmentFile=/run/metadata/flatcar
            ExecStart=
            ExecStart=/usr/lib/coreos/etcd-wrapper $ETCD_OPTS \
              --listen-peer-urls="http://${COREOS_CUSTOM_PRIVATE_IPV4}:2380" \
              --listen-client-urls="http://0.0.0.0:2379,http://0.0.0.0:4001" \
              --initial-advertise-peer-urls="http://${COREOS_CUSTOM_PRIVATE_IPV4}:2380" \
              --advertise-client-urls="http://${COREOS_CUSTOM_PRIVATE_IPV4}:2379,http://${COREOS_CUSTOM_PRIVATE_IPV4}:4001" \
              --discovery="https://discovery.etcd.io/<token>"
```

Note that you have to generate a new token for each unique cluster from https://discovery.etcd.io/new?size=3 where you specify the initial size of your cluster with `?size=X`.
The used variable name needs to be changed to match those that Afterburn uses for your platform.
Multi-region and multi-cloud deployments need to use the public IP address.
The configuration listens on both the official ports and the legacy ports.
Legacy ports can be omitted if your application doesn't depend on them.

Specific documentation are provided for each platform's guide.

## New clusters

Starting a Flatcar Container Linux cluster requires one of the new machines to become the first leader of the cluster. The initial leader is stored as metadata with the discovery URL in order to inform the other members of the new cluster. Let's walk through a timeline a new three-machine Flatcar Container Linux cluster discovering each other:

1. All three machines are booted via a cloud-provider with the same config in the user-data.
2. Machine 1 starts up first. It requests information about the cluster from the discovery token and submits its `-initial-advertise-peer-urls` address `10.10.10.1`.
3. No state is recorded into the discovery URL metadata, so machine 1 becomes the leader and records the state as `started`.
4. Machine 2 boots and submits its `-initial-advertise-peer-urls` address `10.10.10.2`. It also reads back the list of existing peers (only `10.10.10.1`) and attempts to connect to the address listed.
5. Machine 2 connects to Machine 1 and is now part of the cluster as a follower.
6. Machine 3 boots and submits its `-initial-advertise-peer-urls` address `10.10.10.3`. It reads back the list of peers (`10.10.10.1` and `10.10.10.2`) and selects one of the addresses to try first. When it connects to a machine in the cluster, the machine is given a full list of the existing other members of the cluster.
7. The cluster is now bootstrapped with an initial leader and two followers.

There are a few interesting things happening during this process.

First, each machine is configured with the same discovery URL and etcd figured out what to do. This allows you to load the same Butane Config into an auto-scaling group and it will work whether it is the first or 30th machine in the group.

Second, machine 3 only needed to use one of the addresses stored in the discovery URL to connect to the cluster. Since etcd uses the Raft consensus algorithm, existing machines in the cluster already maintain a list of healthy members in order for the algorithm to function properly. This list is given to the new machine and it starts normal operations with each of the other cluster members.

Third, if you specified `?size=3` upon discovery URL creation, any other machines that join the cluster in the future will automatically start as etcd proxies.

## Common problems with cluster discovery

### Existing clusters

[Do not use the public discovery service to reconfigure a running etcd cluster.][etcd-reconf-no-disc] The public discovery service is a convenience for bootstrapping new clusters, especially on cloud providers with dynamic IP assignment, but is not designed for the later case when the cluster is running and member IPs are known.

To promote proxy members or join new members into an existing etcd cluster, configure static discovery and add members. The [etcd cluster reconfiguration guide][etcd-reconf-on-flatcar] details the steps for performing this reconfiguration on Flatcar Container Linux systems that were originally deployed with public discovery. The more general [etcd cluster reconfiguration document][etcd-reconf] explains the operations for removing and adding cluster members in a cluster already configured with static discovery.

### Stale tokens

A common problem with cluster discovery is attempting to boot a new cluster with a stale discovery URL. As explained above, the initial leader election is recorded into the URL, which indicates that the new etcd instance should be joining an existing cluster.

If you provide a stale discovery URL, the new machines will attempt to connect to each of the old peer addresses, which will fail since they don't exist, and the bootstrapping process will fail.

If you're thinking, why can't the new machines just form a new cluster if they're all down. There's a really great reason for this &mdash; if an etcd peer was in a network partition, it would look exactly like the "full-down" situation and starting a new cluster would form a split-brain. Since etcd will never be able to determine whether a token has been reused or not, it must assume the worst and abort the cluster discovery.

If you're running into problems with your discovery URL, there are a few sources of information that can help you see what's going on. First, you can open the URL in a browser to see what information etcd is using to bootstrap itself:

```json
{
  action: "get",
  node: {
    key: "/_etcd/registry/506f6c1bc729377252232a0121247119",
    dir: true,
    nodes: [
      {
        key: "/_etcd/registry/506f6c1bc729377252232a0121247119/0d79b4791be9688332cc05367366551e",
        value: "http://10.183.202.105:7001",
        expiration: "2014-08-17T16:21:37.426001686Z",
        ttl: 576008,
        modifiedIndex: 72783864,
        createdIndex: 72783864
      },
      {
        key: "/_etcd/registry/506f6c1bc729377252232a0121247119/c72c63ffce6680737ea2b670456aaacd",
        value: "http://10.65.177.56:7001",
        expiration: "2014-08-17T12:05:57.717243529Z",
        ttl: 560669,
        modifiedIndex: 72626400,
        createdIndex: 72626400
      },
      {
        key: "/_etcd/registry/506f6c1bc729377252232a0121247119/f7a93d1f0cd4d318c9ad0b624afb9cf9",
        value: "http://10.29.193.50:7001",
        expiration: "2014-08-17T17:18:25.045563473Z",
        ttl: 579416,
        modifiedIndex: 72821950,
        createdIndex: 72821950
      }
    ],
    modifiedIndex: 69367741,
    createdIndex: 69367741
  }
}
```

To rule out firewall settings as a source of your issue, ensure that you can curl each of the IPs from machines in your cluster.

If all of the IPs can be reached, the etcd log can provide more clues:

```shell
journalctl -u etcd-member
```

### Communicating with discovery.etcd.io

If your Flatcar Container Linux cluster can't communicate out to the public internet, [https://discovery.etcd.io](https://discovery.etcd.io) won't work and you'll have to run your own discovery endpoint, which is described below.

### Setting advertised client addresses correctly

Each etcd instance submits the list of `-initial-advertise-peer-urls` of each etcd instance to the configured discovery service. It's important to select an address that *all* peers in the cluster can communicate with. If you are configuring a list of addresses, make sure each member can communicate with at least one of the addresses.

For example, if you're located in two regions of a cloud provider, configuring a private `10.x` address will not work between the two regions, and communication will not be possible between all peers. The `-listen-client-urls` flag allows you to bind to a specific list of interfaces and ports (or all interfaces) to ensure your etcd traffic is routed properly.

## Running your own discovery service

The public discovery service is just an etcd cluster made available to the public internet. Since the discovery service conducts and stores the result of the first leader election, it needs to be consistent. You wouldn't want two machines in the same cluster to think they were both the leader.

Since etcd is designed to this type of leader election, it was an obvious choice to use it for everyone's initial leader election. This means that it's easy to run your own etcd cluster for this purpose.

If you're interested in how discovery API works behind the scenes in etcd, read about [etcd clustering][etcd-clustering].

[etcd-reconf]: https://etcd.io/docs/v3.4.0/op-guide/runtime-configuration/
[etcd-reconf-no-disc]: https://etcd.io/docs/v3.4.0/op-guide/runtime-reconf-design/#do-not-use-public-discovery-service-for-runtime-reconfiguration
[etcd-clustering]: https://etcd.io/docs/v3.4.0/op-guide/clustering/
[etcd-reconf-on-flatcar]: https://github.com/coreos/docs/blob/master/etcd/etcd-live-cluster-reconfiguration.md
