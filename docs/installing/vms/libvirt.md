---
title: Running Flatcar Container Linux on libvirt
linktitle: Running on libvirt
weight: 30
aliases:
    - ../../os/booting-with-libvirt
    - ../../cloud-providers/booting-with-libvirt
---

This guide explains how to run Flatcar Container Linux with libvirt using the QEMU driver. The libvirt configuration
file can be used (for example) with `virsh` or `virt-manager`. The guide assumes
that you already have a running libvirt setup and `virt-install` tool. If you
don’t have that, other solutions are most likely easier.
At the end of the document there are instructions for deploying with Terraform.

You can direct questions to the [IRC channel][irc] or [mailing list][flatcar-dev].

## Download the Flatcar Container Linux image

In this guide, the example virtual machine we are creating is called flatcar-linux1 and
all files are stored in `/var/lib/libvirt/images/flatcar-linux`. This is not a requirement — feel free
to substitute that path if you use another one.

### Choosing a channel

Flatcar Container Linux is designed to be updated automatically with different schedules per channel. You can [disable this feature][update-strategies], although we don't recommend it. Read the [release notes][release-notes] for specific features and bug fixes.

<div id="libvirt-create">
  <ul class="nav nav-tabs">
    <li class="active"><a href="#stable-create" data-toggle="tab">Stable Channel</a></li>
    <li><a href="#beta-create" data-toggle="tab">Beta Channel</a></li>
    <li><a href="#alpha-create" data-toggle="tab">Alpha Channel</a></li>
  </ul>
  <div class="tab-content coreos-docs-image-table">
    <div class="tab-pane" id="alpha-create">
      <p>The Alpha channel closely tracks master and is released frequently. The newest versions of system libraries and utilities will be available for testing. The current version is Flatcar Container Linux {{< param alpha_channel >}}.</p>
      <p>We start by downloading the most recent disk image:</p>
      <pre>
mkdir -p /var/lib/libvirt/images/flatcar-linux
cd /var/lib/libvirt/images/flatcar-linux
wget https://alpha.release.flatcar-linux.net/amd64-usr/current/flatcar_production_qemu_image.img.bz2{,.sig}
gpg --verify flatcar_production_qemu_image.img.bz2.sig
bunzip2 flatcar_production_qemu_image.img.bz2</pre>
    </div>
    <div class="tab-pane" id="beta-create">
      <p>The Beta channel consists of promoted Alpha releases. The current version is Flatcar Container Linux {{< param beta_channel >}}.</p>
      <p>We start by downloading the most recent disk image:</p>
      <pre>
mkdir -p /var/lib/libvirt/images/flatcar-linux
cd /var/lib/libvirt/images/flatcar-linux
wget https://beta.release.flatcar-linux.net/amd64-usr/current/flatcar_production_qemu_image.img.bz2{,.sig}
gpg --verify flatcar_production_qemu_image.img.bz2.sig
bunzip2 flatcar_production_qemu_image.img.bz2</pre>
    </div>
    <div class="tab-pane active" id="stable-create">
      <p>The Stable channel should be used by production clusters. Versions of Flatcar Container Linux are battle-tested within the Beta and Alpha channels before being promoted. The current version is Flatcar Container Linux {{< param stable_channel >}}.</p>
      <p>We start by downloading the most recent disk image:</p>
      <pre>
mkdir -p /var/lib/libvirt/images/flatcar-linux
cd /var/lib/libvirt/images/flatcar-linux
wget https://stable.release.flatcar-linux.net/amd64-usr/current/flatcar_production_qemu_image.img.bz2{,.sig}
gpg --verify flatcar_production_qemu_image.img.bz2.sig
bunzip2 flatcar_production_qemu_image.img.bz2</pre>
    </div>
  </div>
</div>

## Virtual machine configuration

Now create a qcow2 image snapshot using the command below:

```shell
cd /var/lib/libvirt/images/flatcar-linux
qemu-img create -f qcow2 -F qcow2 -b flatcar_production_qemu_image.img flatcar-linux1.qcow2
```

This will create a `flatcar-linux1.qcow2` snapshot image. Any changes to `flatcar-linux1.qcow2` will not be reflected in `flatcar_production_qemu_image.img`. Making any changes to a base image (`flatcar_production_qemu_image.img` in our example) will corrupt its snapshots.

### Ignition config

The preferred way to configure a Flatcar Container Linux machine is via Ignition.

#### Create the Ignition config

Typically you won't write Ignition files yourself, rather you will typically use a tool like the [config transpiler][config-transpiler] to generate them.

However the Ignition file is created, it should be placed in a location which qemu can access. In this example, we'll place it in `/var/lib/libvirt/flatcar-linux/flatcar-linux1/provision.ign`.

Here, for example, we create an empty Ignition config that contains no further declarations besides its specification version:

```shell
mkdir -p /var/lib/libvirt/flatcar-linux/flatcar-linux1/
echo '{"ignition":{"version":"2.0.0"}}' > /var/lib/libvirt/flatcar-linux/flatcar-linux1/provision.ign
```

If the host uses SELinux, allow the VM access to the config:

```shell
semanage fcontext -a -t virt_content_t "/var/lib/libvirt/flatcar-linux/flatcar-linux1"
restorecon -R "/var/lib/libvirt/flatcar-linux/flatcar-linux1"
```

If the host uses AppArmor, allow `qemu` to access the config files:

```shell
echo "  # For ignition files" >> /etc/apparmor.d/abstractions/libvirt-qemu
echo "  /var/lib/libvirt/flatcar-linux/** r," >> /etc/apparmor.d/abstractions/libvirt-qemu
```

Since the empty Ignition config is not very useful, here is an example how to write a simple Flatcar Container Linux config to add your ssh keys and write a hostname file:

```yaml
storage:
  files:
  - path: /etc/hostname
    filesystem: "root"
    contents:
      inline: "flatcar-linux1"

passwd:
  users:
    - name: core
      ssh_authorized_keys:
        - "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC0g+ZTxC7weoIJLUafOgrm+h..."
```

Assuming that you save this as `example.yaml` (and replace the dummy key with public key), you can convert it to an Ignition config with the [config transpiler][config-transpiler].
Here we run it from a Docker image:

```shell
cat example.yaml | docker run --rm -i ghcr.io/flatcar/ct:latest > /var/lib/libvirt/flatcar-linux/flatcar-linux1/provision.ign
```

#### Creating the domain

Once the Ignition file exists on disk, the machine can be configured and started:

```shell
virt-install --connect qemu:///system \
             --import \
             --name flatcar-linux1 \
             --ram 1024 --vcpus 1 \
             --os-type=generic \
             --disk path=/var/lib/libvirt/images/flatcar-linux/flatcar-linux1.qcow2,format=qcow2,bus=virtio \
             --vnc --noautoconsole \
             --qemu-commandline='-fw_cfg name=opt/org.flatcar-linux/config,file=/var/lib/libvirt/flatcar-linux/flatcar-linux1/provision.ign'
```

#### SSH into the machine

By default, libvirt runs its own DHCP server which will provide an IP address to new instances. You can query it for what IP addresses have been assigned to machines:

```shell
$ virsh net-dhcp-leases default
Expiry Time          MAC address        Protocol  IP address                Hostname        Client ID or DUID
-------------------------------------------------------------------------------------------------------------------
 2017-08-09 16:32:52  52:54:00:13:12:45  ipv4      192.168.122.184/24        flatcar-linux1 ff:32:39:f9:b5:00:02:00:00:ab:11:06:6a:55:ed:5d:0a:73:ee
```


To SSH into:

```
ssh core@192.168.122.184
```

### Network configuration

#### Static IP

By default, Flatcar Container Linux uses DHCP to get its network configuration. In this example the VM will be attached directly to the local network via a bridge on the host's virbr0 and the local network. To configure a static address add a [networkd unit][systemd-network] to the Flatcar Container Linux config:

```yaml
passwd:
  users:
  - name: core
    ssh_authorized_keys:
    - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDGdByTgSVHq.......

storage:
  files:
  - path: /etc/hostname
    filesystem: "root"
    contents:
      inline: flatcar-linux1

networkd:
  units:
  - name: 10-ens3.network
    contents: |
      [Match]
      MACAddress=52:54:00:fe:b3:c0

      [Network]
      Address=192.168.122.2
      Gateway=192.168.122.1
      DNS=8.8.8.8
```

[systemd-network]: http://www.freedesktop.org/software/systemd/man/systemd.network.html

#### Using DHCP with a libvirt network

An alternative to statically configuring an IP at the host level is to do so at the libvirt level. If you're using libvirt's built in DHCP server and a recent libvirt version, it allows configuring what IP address will be provided to a given machine ahead of time.

This can be done using the `net-update` command. The following assumes you're using the `default` libvirt network and have configured the MAC Address to `52:54:00:fe:b3:c0` through the `--network` flag on `virt-install`:

```shell
ip="192.168.122.2"
mac="52:54:00:fe:b3:c0"

virsh net-update --network "default" add-last ip-dhcp-host \
    --xml "<host mac='${mac}' ip='${ip}' />" \
    --live --config
```

By executing these commands before running `virsh start`, we can ensure the libvirt DHCP server will hand out a known IP.

### SSH Config

To simplify this and avoid potential host key errors in the future add the following to `~/.ssh/config`:

```ini
Host flatcar-linux1
HostName 192.168.122.2
User core
StrictHostKeyChecking no
UserKnownHostsFile /dev/null
```

Now you can log in to the virtual machine with:

```shell
ssh flatcar-linux1
```

## Using Flatcar Container Linux

Now that you have a machine booted it is time to play around. Check out the [Flatcar Container Linux Quickstart][quickstart] guide or dig into [more specific topics][doc-index].

## Terraform

The [`libvirt` Terraform Provider](https://github.com/dmacvicar/terraform-provider-libvirt/) allows to quickly deploy machines in a declarative way.
This is especially useful for local development of a configuration that is also in use on a cloud provider.
Read more about using Terraform and Flatcar [here](../../provisioning/terraform/).

The following Terraform v0.13 module may serve as a base for your own setup.
A new disk volume pool will be created in `/var/tmp` as precaution to not modify the base image by accident.

First, prepare the base image and make sure you don't boot it via the [`flatcar_production_qemu.sh`](https://stable.release.flatcar-linux.net/amd64-usr/current/flatcar_production_qemu.sh) script or similar:

```sh
cd ~/Downloads
wget https://stable.release.flatcar-linux.net/amd64-usr/current/flatcar_production_qemu_image.img.bz2
bunzip2 flatcar_production_qemu_image.img.bz2
mv flatcar_production_qemu_image-libvirt-import.img
# optional, increase the image by 5 GB:
qemu-img resize flatcar_production_qemu_image-libvirt-import.img +5G
```

It will only be used once for the import and can be deleted afterwards even when new VMs are added.

Start with a `libvirt-machines.tf` file that contains the main declarations:

```
terraform {
  required_version = ">= 0.13"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.6.3"
    }
    ct = {
      source  = "poseidon/ct"
      version = "0.7.1"
    }
    template = {
      source  = "hashicorp/template"
      version = "~> 2.2.0"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_pool" "volumetmp" {
  name = "${var.cluster_name}-pool"
  type = "dir"
  path = "/var/tmp/${var.cluster_name}-pool"
}

resource "libvirt_volume" "base" {
  name   = "flatcar-base"
  source = var.base_image
  pool   = libvirt_pool.volumetmp.name
  format = "qcow2"
}

resource "libvirt_volume" "vm-disk" {
  for_each = toset(var.machines)
  # workaround: depend on libvirt_ignition.ignition[each.key], otherwise the VM will use the old disk when the user-data changes
  name           = "${var.cluster_name}-${each.key}-${md5(libvirt_ignition.ignition[each.key].id)}.qcow2"
  base_volume_id = libvirt_volume.base.id
  pool           = libvirt_pool.volumetmp.name
  format         = "qcow2"
}

resource "libvirt_ignition" "ignition" {
  for_each = toset(var.machines)
  name     = "${var.cluster_name}-${each.key}-ignition"
  pool     = libvirt_pool.volumetmp.name
  content  = data.ct_config.vm-ignitions[each.key].rendered
}

resource "libvirt_domain" "machine" {
  for_each = toset(var.machines)
  name     = "${var.cluster_name}-${each.key}"
  vcpu     = var.virtual_cpus
  memory   = var.virtual_memory

  fw_cfg_name     = "opt/org.flatcar-linux/config"
  coreos_ignition = libvirt_ignition.ignition[each.key].id

  disk {
    volume_id = libvirt_volume.vm-disk[each.key].id
  }

  graphics {
    listen_type = "address"
  }

  # dynamic IP assignment on the bridge, NAT for Internet access
  network_interface {
    network_name   = "default"
    wait_for_lease = true
  }
}

data "ct_config" "vm-ignitions" {
  for_each = toset(var.machines)
  content  = data.template_file.vm-configs[each.key].rendered
}

data "template_file" "vm-configs" {
  for_each = toset(var.machines)
  template = file("${path.module}/machine-${each.key}.yaml.tmpl")

  vars = {
    ssh_keys = jsonencode(var.ssh_keys)
    name     = each.key
  }
}
```

Create a `variables.tf` file that declares the variables used above:

```
variable "machines" {
  type        = list(string)
  description = "Machine names, corresponding to machine-NAME.yaml.tmpl files"
}

variable "cluster_name" {
  type        = string
  description = "Cluster name used as prefix for the machine names"
}

variable "ssh_keys" {
  type        = list(string)
  description = "SSH public keys for user 'core'"
}

variable "base_image" {
  type        = string
  description = "Path to unpacked Flatcar Container Linux image flatcar_production_qemu_image.img (probably after a qemu-img resize IMG +5G)"
}

variable "virtual_memory" {
  type        = number
  default     = 2048
  description = "Virtual RAM in MB"
}

variable "virtual_cpus" {
  type        = number
  default     = 1
  description = "Number of virtual CPUs"
}
```

An `outputs.tf` file shows the resulting IP addresses:

```
output "ip-addresses" {
  value = {
    for key in var.machines :
    "${var.cluster_name}-${key}" => libvirt_domain.machine[key].network_interface.0.addresses.*
  }
  # or instead of outputs, use dig CLUSTERNAME-VMNAME @192.168.122.1
}
```

Now you can use the module by declaring the variables and a Container Linux Configuration for a machine.
First create a `terraform.tfvars` file with your settings:

```
base_image     = "file:///home/myself/Downloads/flatcar_production_qemu_image-libvirt-import.img"
cluster_name  = "mycluster"
machines     = ["mynode"]
virtual_memory = 768
ssh_keys     = ["ssh-rsa AA... me@mail.net"]
```

Create the configuration for `mynode` in the file `machine-mynode.yaml.tmpl`:

```yaml
---
passwd:
  users:
    - name: core
      ssh_authorized_keys: ${ssh_keys}
storage:
  files:
    - path: /home/core/works
      filesystem: root
      mode: 0755
      contents:
        inline: |
          #!/bin/bash
          set -euo pipefail
          hostname="$(hostname)"
          echo My name is ${name} and the hostname is $${hostname}
```

Finally, run Terraform v0.13 as follows to create the machine:

```
terraform init
terraform apply
```

View the VMs in `virt-manager` where you can see the VGA console.
Log in via `ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null core@IPADDRESS` with the printed IP address.

When you make a change to `machine-mynode.yaml.tmpl` and run `terraform apply` again, the instance and its disk will be replaced.

[flatcar-dev]: https://groups.google.com/forum/#!forum/flatcar-linux-dev
[irc]: irc://irc.freenode.org:6667/#flatcar
[config-transpiler]: ../../provisioning/config-transpiler
[update-strategies]: ../../setup/releases/update-strategies
[release-notes]: https://flatcar-linux.org/releases
[quickstart]: ../
[doc-index]: ../../
