---
title: Running Flatcar Container Linux on Hetzner
linktitle: Running on Hetzner
weight: 20
aliases:
    - ../../os/booting-on-hetzner
    - ../../cloud-providers/booting-on-hetzner
---

[Hetzner Cloud](https://www.hetzner.com/cloud) is a cloud hosting provider.
Flatcar Container Linux is not installable as one of the default operating system options but you can deploy it by installing it through the rescue OS.
At the end of the document there are instructions for deploying with Terraform.

## Preparations

Register your SSH key in the Hetzner web interface to be able to log in to a machine.

For programatic access, create an API token (e.g., used with Terraform as `HCLOUD_TOKEN` environment variable).

## Provisioning

Select any OS like Debian when you create the instance but boot into the `linux64` rescue OS.
Connect via SSH and download and run the `flatcar-install` script:

```sh
curl -fsSLO --retry-delay 1 --retry 60 --retry-connrefused --retry-max-time 60 --connect-timeout 20 https://raw.githubusercontent.com/kinvolk/init/flatcar-master/bin/flatcar-install
chmod +x flatcar-install
./flatcar-install -s -i ignition.json # optional: you may provide a Ignition Config as file, it should contain your SSH key
shutdown -r +1 # reboot into Flatcar
```

## Terraform

The [`hcloud`](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs) Terraform Provider allows to deploy machines in a declarative way.
Read more about using Terraform and Flatcar [here](../../terraform/).

The following Terraform v0.13 module may serve as a base for your own setup.
It will also take care of registering your SSH key at Hetzner.

Start with a `hetzner-machines.tf` file that contains the main declarations:

```
terraform {
  required_version = ">= 0.13"
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.23.0"
    }
    ct = {
      source  = "poseidon/ct"
      version = "0.7.1"
    }
    template = {
      source  = "hashicorp/template"
      version = "~> 2.2.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0.0"
    }
  }
}

resource "hcloud_ssh_key" "first" {
  name       = var.cluster_name
  public_key = var.ssh_keys.0
}

resource "hcloud_server" "machine" {
  for_each = toset(var.machines)
  name     = "${var.cluster_name}-${each.key}"
  ssh_keys = [hcloud_ssh_key.first.id]
  # boot into rescue OS
  rescue = "linux64"
  # dummy value for the OS because Flatcar is not available
  image       = "debian-9"
  server_type = var.server_type
  datacenter  = var.datacenter
  connection {
    host    = self.ipv4_address
    timeout = "1m"
  }
  provisioner "file" {
    content     = data.ct_config.machine-ignitions[each.key].rendered
    destination = "/root/ignition.json"
  }

  provisioner "remote-exec" {
    inline = [
      "set -ex",
      "curl -fsSLO --retry-delay 1 --retry 60 --retry-connrefused --retry-max-time 60 --connect-timeout 20 https://raw.githubusercontent.com/kinvolk/init/flatcar-master/bin/flatcar-install",
      "chmod +x flatcar-install",
      "./flatcar-install -s -i /root/ignition.json",
      "shutdown -r +1",
    ]
  }

  # optional:
  provisioner "remote-exec" {
    connection {
      host    = self.ipv4_address
      timeout = "3m"
      user    = "core"
    }

    inline = [
      "sudo hostnamectl set-hostname ${self.name}",
    ]
  }
}

data "ct_config" "machine-ignitions" {
  for_each = toset(var.machines)
  content  = data.template_file.machine-configs[each.key].rendered
}

data "template_file" "machine-configs" {
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
  description = "SSH public keys for user 'core' and to register on Hetzner Cloud"
}

variable "server_type" {
  type        = string
  default     = "cx11"
  description = "The server type to rent"
}

variable "datacenter" {
  type        = string
  description = "The region to deploy in"
}
```

An `outputs.tf` file shows the resulting IP addresses:

```
output "ip-addresses" {
  value = {
    for key in var.machines :
    "${var.cluster_name}-${key}" => hcloud_server.machine[key].ipv4_address
  }
}
```

Now you can use the module by declaring the variables and a Container Linux Configuration for a machine.
First create a `terraform.tfvars` file with your settings:

```
cluster_name = "mycluster"
machines     = ["mynode"]
datacenter   = "fsn1-dc14"
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
export HCLOUD_TOKEN=...
terraform init
terraform apply
```

Log in via `ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null core@IPADDRESS` with the printed IP address.

When you make a change to `machine-mynode.yaml.tmpl` and run `terraform apply` again, the machine will be replaced.
