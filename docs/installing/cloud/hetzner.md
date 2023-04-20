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
apt update
apt -y install gawk
curl -fsSLO --retry-delay 1 --retry 60 --retry-connrefused --retry-max-time 60 --connect-timeout 20 https://raw.githubusercontent.com/flatcar/init/flatcar-master/bin/flatcar-install
chmod +x flatcar-install
./flatcar-install -s -i ignition.json # optional: you may provide a Ignition Config as file, it should contain your SSH key
shutdown -r +1 # reboot into Flatcar
```

## Terraform

The [`hcloud`](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs) Terraform Provider allows to deploy machines in a declarative way.
Read more about using Terraform and Flatcar [here](../../provisioning/terraform/).

The following Terraform v0.13 module may serve as a base for your own setup.
It will also auto-generate an SSH key for this deployment, and register it with Hetzner.

Since Flatcar does not yet natively support Hetzner metadata, automation will boot into the node's rescue OS during deployment, and install Flatcar from there.

You can clone the setup from the [Flatcar Terraform examples repository](https://github.com/flatcar/flatcar-terraform/tree/main/flatcar-terraform-hetzner) or create the files manually as we go through them and explain each one.

```
git clone https://github.com/flatcar/flatcar-terraform.git
# From here on you could directly run it, TLDR:
cd flatcar-terraform-hetzner
export HCLOUD_TOKEN=...
terraform init
# Edit the server configs or just go ahead with the default example
terraform plan
terraform apply
```

Start with a `hetzner-machines.tf` file that contains the main declarations:

```
resource "tls_private_key" "provisioning" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "hcloud_ssh_key" "provisioning_key" {
  name       = "Provisioning key for Flatcar cluster '${var.cluster_name}'"
  public_key = tls_private_key.provisioning.public_key_openssh
}

resource "local_file" "provisioning_key" {
  filename             = "${path.module}/.ssh/provisioning_private_key.pem"
  content              = tls_private_key.provisioning.private_key_pem
  directory_permission = "0700"
  file_permission      = "0400"
}

resource "local_file" "provisioning_key_pub" {
  filename             = "${path.module}/.ssh/provisioning_key.pub"
  content              = tls_private_key.provisioning.public_key_openssh
  directory_permission = "0700"
  file_permission      = "0440"
}


resource "hcloud_server" "machine" {
  for_each = toset(var.machines)
  name     = "${var.cluster_name}-${each.key}"
  ssh_keys = [hcloud_ssh_key.provisioning_key.id]
  # boot into rescue OS
  rescue = "linux64"
  # dummy value for the OS because Flatcar is not available
  image       = "debian-11"
  server_type = var.server_type
  location    = var.location
  connection {
    host        = self.ipv4_address
    private_key = tls_private_key.provisioning.private_key_pem
    timeout     = "1m"
  }
  provisioner "file" {
    content     = data.ct_config.machine-ignitions[each.key].rendered
    destination = "/root/ignition.json"
  }

  provisioner "remote-exec" {
    inline = [
      "set -ex",
      "apt update",
      "apt install -y gawk",
      "curl -fsSLO --retry-delay 1 --retry 60 --retry-connrefused --retry-max-time 60 --connect-timeout 20 https://raw.githubusercontent.com/flatcar/init/flatcar-master/bin/flatcar-install",
      "chmod +x flatcar-install",
      "./flatcar-install -s -i /root/ignition.json -C ${var.release_channel}",
      "shutdown -r +1",
    ]
  }

  provisioner "remote-exec" {
    connection {
      host        = self.ipv4_address
      private_key = tls_private_key.provisioning.private_key_pem
      timeout     = "3m"
      user        = "core"
    }

    inline = [
      "sudo hostnamectl set-hostname ${self.name}",
    ]
  }
}

data "ct_config" "machine-ignitions" {
  for_each = toset(var.machines)
  strict   = true
  content  = file("${path.module}/server-configs/${each.key}.yaml")
  snippets = [
    data.template_file.core_user.rendered
  ]
}

data "template_file" "core_user" {
  template = file("${path.module}/core-user.yaml.tmpl")
  vars = {
    ssh_keys = jsonencode(concat(var.ssh_keys, [tls_private_key.provisioning.public_key_openssh]))
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
  default     = []
  description = "Additional SSH public keys for user 'core'."
}

variable "server_type" {
  type        = string
  default     = "cx11"
  description = "The server type to rent."
}

variable "location" {
  type        = string
  default     = "fsn1"
  description = "The Hetzner region code for the region to deploy to."
}

variable "release_channel" {
  type        = string
  description = "Release channel"
  default     = "stable"

  validation {
    condition     = contains(["lts", "stable", "beta", "alpha"], var.release_channel)
    error_message = "release_channel must be lts, stable, beta, or alpha."
  }
}
```

An `outputs.tf` file for showing the nodes' IP addresses, ids, and names - as well as the SSH key generated for the deployment:

```
output "provisioning_public_key_file" {
  value = local_file.provisioning_key_pub.filename
}

output "provisioning_private_key_file" {
  value = local_file.provisioning_key.filename
}

output "ipv4" {
  value = {
    for key in var.machines :
    "${var.cluster_name}-${key}" => hcloud_server.machine[key].ipv4_address
  }
}

output "ipv6" {
  value = {
    for key in var.machines :
    "${var.cluster_name}-${key}" => hcloud_server.machine[key].ipv6_address
  }
}

output "id" {
  value = {
    for key in var.machines :
    "${var.cluster_name}-${key}" => hcloud_server.machine[key].id
  }
}

output "name" {
  value = {
    for key in var.machines :
    "${var.cluster_name}-${key}" => hcloud_server.machine[key].name
  }
}
```

Define a user for logging in to the node(s) in a file `core-user.yaml.tmpl`:

```
variant: flatcar
version: 1.0.0

passwd:
  users:
    - name: core
      ssh_authorized_keys: ${ssh_keys}
```

Lastly, define a file `versions.tf` and set desired terraform and provider versions there:

```
terraform {
  required_version = ">= 0.14"
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.36.0"
    }
    ct = {
      source  = "poseidon/ct"
      version = "0.11.0"
    }
    template = {
      source  = "hashicorp/template"
      version = "~> 2.2.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2.1"
    }
  }
}
```

Done!

Now you can use the module by declaring the variables and a Container Linux Configuration for a machine.
Define your cluster in a file `terraform.tfvars`:

```
# Server names are [cluster]-[machine #1], [cluster]-[machine #2] ... etc.
cluster_name = "flatcar"

# Uses server-configs/server1.yaml
machines = ["server1"]

# One of nbg1, fsn1, hel1, or ash
location = "fsn1"

# Smallest instance size
server_type = "cx11"

# Additional SSH "authorized hosts" keys for the "core" user.
# ssh_keys = [ "...", "..." ]

# One of "lts", "stable", "beta", or "alpha"
release_channel = "stable"
```

The above references a deployment configuration in [Butane](../../../provisioning/config-transpiler/configuration/) syntax; `server-configs/server1.yaml`.
This is used to set up containers on your node, e.g. for a simple service, or to kick off bootstrapping a complex control plane like Kubernetes.

The example below will run a simple web server on the node. Create a file `server-configs/server1.yaml` with the following contents:

```
variant: flatcar
version: 1.0.0

systemd:
  units:
    - name: nginx.service
      enabled: true
      contents: |
        [Unit]
        Description=NGINX example
        After=docker.service
        Requires=docker.service
        [Service]
        TimeoutStartSec=0
        ExecStartPre=-/usr/bin/docker rm --force nginx1
        ExecStart=/usr/bin/docker run --name nginx1 --pull always --net host docker.io/nginx:1
        ExecStop=/usr/bin/docker stop nginx1
        Restart=always
        RestartSec=5s
        [Install]
        WantedBy=multi-user.target
```


Finally, run Terraform v0.13 as follows to create the machine:

```
export HCLOUD_TOKEN=...
terraform init
terraform apply
```

Terraform will print server information (name, ipv4 and v6, and ID) after the deployment concluded. The deployment will create an SSH key pair in `.ssh/`.

You can now log in via `ssh -i ./.ssh/provisioning_private_key.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null core@[SERVER-IP]`.

When you make a change to `terraform.tfvars` (e.g. to add more nodes) and/or to `server-configs/server1.yaml` for updating your deployment, make sure to run `terraform apply` again.
NOTE that changes in existing server configurations (like `server-configs/server1.yaml`) will replace the existing machine.

As mentined in the beginning, you can find this Terraform module in the repository for [Flatcar Terraform examples](https://github.com/flatcar/flatcar-terraform/tree/main/hetzner).
