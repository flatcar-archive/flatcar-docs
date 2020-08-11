---
title: Flatcar Container Linux quick start
weight: 10
---

If you don't have a Flatcar Container Linux machine running, check out the guides on [running Flatcar Container Linux][running-container-linux] on most cloud providers ([EC2][ec2-docs], [Azure][azure-docs], [GCE][gce-docs], [Packet][packet-docs]), virtualization platforms ([Vagrant][vagrant-docs], [VMware][vmware-docs], [VirtualBox][virtualbox-docs] [QEMU/KVM][qemu-docs]/[libVirt][libvirt-docs]) and bare metal servers ([PXE][pxe-docs], [iPXE][ipxe-docs], [ISO][iso-docs], [Installer][install-docs]). With any of these guides you will have machines up and running in a few minutes.

It's highly recommended that you set up a cluster of at least 3 machines &mdash; it's not as much fun on a single machine. If you don't want to break the bank, [Vagrant][vagrant-docs] allows you to run an entire cluster on your laptop. For a cluster to be properly bootstrapped, you have to provide ideally an [Ignition config][ignition] (generated from a [Container Linux Config][cl-configs]), or possibly a cloud-config, via user-data, which is covered in each platform's guide.

Flatcar Container Linux gives you three essential tools: service discovery, container management and process management. Let's try each of them out.

First, on the client start your user agent by typing:

```shell
eval $(ssh-agent)
```

Then, add your private key to the agent by typing:

```shell
ssh-add
```

Connect to a Flatcar Container Linux machine via SSH as the user `core`. For example, on Amazon, use:

```shell
$ ssh core@an.ip.compute-1.amazonaws.com
Flatcar Container Linux (beta)
```

If you're using Vagrant, you'll need to connect a bit differently:

```shell
$ ssh-add ~/.vagrant.d/insecure_private_key
Identity added: /Users/core/.vagrant.d/insecure_private_key (/Users/core/.vagrant.d/insecure_private_key)
$ vagrant ssh core-01
Flatcar Container Linux (beta)
```

## Service discovery with etcd

The first building block of Flatcar Container Linux is service discovery with **etcd** ([docs][etcd-docs]). Data stored in etcd is distributed across all of your machines running Flatcar Container Linux. For example, each of your app containers can announce itself to a proxy container, which would automatically know which machines should receive traffic. Building service discovery into your application allows you to add more machines and scale your services seamlessly.

If you used an example [Container Linux Config][cl-configs] or [cloud-config](https://github.com/flatcar-linux/coreos-cloudinit/blob/master/Documentation/cloud-config.md) from a guide linked in the first paragraph, etcd is automatically started on boot.

A good starting point for a Container Linux Config would be something like:

```yaml
etcd:
  discovery: https://discovery.etcd.io/<token>
passwd:
  users:
    - name: core
      ssh_authorized_keys:
        - ssh-rsa AAAA...
```

In order to get the discovery token, visit [https://discovery.etcd.io/new](https://discovery.etcd.io/new) and you will receive a URL including your token. Paste the whole thing into your Container Linux Config file.

`etcdctl` is a command line interface to etcd that is preinstalled on Flatcar Container Linux. To set and retrieve a key from etcd you can use the following examples:

Set a key `message` with value `Hello world`:

```shell
etcdctl set /message "Hello world"
```

Read the value of `message` back:

```shell
etcdctl get /message
```

You can also use simple `curl`. These examples correspond to previous ones:

Set the value:

```shell
curl -L http://127.0.0.1:2379/v2/keys/message -XPUT -d value="Hello world"
```

Read the value:

```shell
curl -L http://127.0.0.1:2379/v2/keys/message
```

If you followed a guide to set up more than one Flatcar Container Linux machine, you can SSH into another machine and can retrieve this same value.

### More detailed information (service discovery)

<a class="btn btn-primary" href="https://coreos.com/etcd/docs/latest/getting-started-with-etcd.html" data-category="More Information" data-event="Docs: Getting Started etcd">View Complete Guide</a>
<a class="btn btn-default" href="https://etcd.io/docs/">Read etcd API Docs</a>

## Container management with Docker

The second building block, **Docker** ([docs][docker-docs]), is where your applications and code run. It is installed on each Flatcar Container Linux machine. You should make each of your services (web server, caching, database) into a container and connect them together by reading and writing to etcd. You can quickly try out a minimal busybox container in two different ways:

Run a command in the container and then stop it:

```shell
docker run busybox /bin/echo hello world
```

Open a shell prompt inside the container:

```shell
docker run -i -t busybox /bin/sh
```

### More detailed information (Docker)

<a class="btn btn-default" href="http://docs.docker.io/">Read Docker Docs</a>

[docker-docs]: https://docs.docker.com/
[etcd-docs]: https://etcd.io/
[running-container-linux]: https://docs.flatcar-linux.org/#getting-started
[ec2-docs]: booting-on-ec2.md
[azure-docs]: booting-on-azure.md
[gce-docs]: booting-on-google-compute-engine.md
[vagrant-docs]: booting-on-vagrant.md
[vmware-docs]: booting-on-vmware.md
[virtualbox-docs]: booting-on-virtualbox.md
[qemu-docs]: booting-with-qemu.md
[libvirt-docs]: booting-with-libvirt.md
[packet-docs]: booting-on-packet.md
[pxe-docs]: booting-with-pxe.md
[ipxe-docs]: booting-with-ipxe.md
[iso-docs]: booting-with-iso.md
[install-docs]: installing-to-disk.md
[ignition]: https://coreos.com/ignition/docs/latest/
[cl-configs]: provisioning.md
