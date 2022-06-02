---
title: Running Flatcar Container Linux on Equinix Metal
linktitle: Running on Equinix Metal
weight: 10
aliases:
    - ../../os/booting-on-packet
    - ../../cloud-providers/booting-on-packet
---

Equinix Metal (formerly known as Packet) is a bare metal cloud hosting provider. Flatcar Container Linux is installable as one of the default operating system options. You can deploy Flatcar Container Linux servers via the web portal or API. At the end of the document there are instructions for deploying with Terraform.

## Deployment instructions

The first step in deploying any devices on Equinix Metal is to first create an account and decide if you'd like to deploy via our portal or API. The portal is appropriate for small clusters of machines that won't change frequently. If you'll be deploying a lot of machines, or expect your workload to change frequently it is much more efficient to use the API. You can generate an API token through the portal once you've set up an account and payment method.

### Projects

Equinix Metal has a concept of 'projects' that represent a grouping of machines that defines several other aspects of the service. A project defines who on the team has access to manage the machines in your account. Projects also define your private network; all machines in a given project will automatically share backend network connectivity. The SSH keys of all team members associated with a project will be installed to all newly provisioned machines in a project. All servers need to be in a project, even if there is only one server in that project.

### Portal instructions

Once logged into the portal you will be able to click the 'New server' button and choose Flatcar Container Linux from the menu of operating systems, and choose which region you want the server to be deployed in. If you choose to enter a custom Ignition config, you can enable 'Add User Data' and paste it there. The SSH key that you associate with your account and any other team member's keys that are on the project will be added to your Flatcar Container Linux machine once it is provisioned.

### API instructions

If you select to use the API to provision machines on Equinix Metal you should consider using [one of the language libraries](https://metal.equinix.com/developers/docs/libraries/) to code against. As an example, this is how you would launch a single Type 1 machine in a curl command. [API Documentation](https://metal.equinix.com/developers/api/).

```shell
# Replace items in brackets (<EXAMPLE>) with the appropriate values.

curl -X POST \
-H 'Content-Type: application/json' \
-H 'Accept: application/json' \
-H 'X-Auth-Token: <API_TOKEN>' \
-d '{"hostname": "<HOSTNAME>", "plan": "c3.small.x86", "facility": "da11", "operating_system": "flatcar_stable", "userdata": "<USERDATA>"}' \
https://api.equinix.com/metal/v1/projects/<PROJECT_ID>/devices
```

Double quotes in the `<USERDATA>` value must be escaped such that the request body is valid JSON. See the Container Linux Config section below for more information about accepted forms of userdata.

## iPXE booting

If you need to run a Flatcar Container Linux image which is not available through the OS option in the API, you can boot via 'Custom iPXE'.
This is the case for ARM64 images right now as they are not available via Equinix Metal's API.

Assuming you want to run boot an Alpha image via iPXE on a `c2.large.arm` machine, you have to provide this URL for 'Custom iPXE Settings':

```text
https://alpha.release.flatcar-linux.net/arm64-usr/current/flatcar_production_packet.ipxe
```

Do not forget to provide an Ignition config with your SSH key because the PXE images don't have any OEM packages which could fetch the Equinix Metal Project's SSH keys after booting.

If not configured elsewise, iPXE booting will only done at the first boot because you are expected to install the operating system to the hard disk yourself.

## Container Linux Configs

Flatcar Container Linux allows you to configure machine parameters, configure networking, launch systemd units on startup, and more via Container Linux Configs (CLC). These configs are then transpiled into Ignition configs and given to booting machines. Head over to the [docs to learn about the supported features][cl-configs]. Note that Equinix Metal doesn't allow an instance's userdata to be modified after the instance has been launched. This isn't a problem since Ignition only runs on the first boot.

You can provide a raw Ignition JSON config to Flatcar Container Linux via Equinix Metal's userdata field.

As an example, this CLC YAML config will start an NGINX Docker container:

```yaml
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

Transpile it to Ignition JSON:

```shell
cat cl.yaml | docker run --rm -i ghcr.io/flatcar-linux/ct:latest -platform packet > ignition.json
```

[cl-configs]: ../../provisioning/cl-config

## Disabling/enabling autologin

Beginning with Flatcar major version 3185 the `kernelArguments` directive in Ignition v3 allows to add/remove the `flatcar.autologin` kernel command line parameter that is set in `grub.cfg`.
The following short Butane YAML config (to be transpiled to Ignition v3 JSON) ensures that the `flatcar.autologin` kernel parameter gets removed and then as part of the first boot it gets applied to an instant reboot before the instance comes up:

```yaml
variant: flatcar
version: 1.0.0
kernel_arguments:
  should_not_exist:
    - flatcar.autologin
```

With `should_exist` instead of `should_not_exist` the argument would be added if it isn't set in `grub.cfg` already.

Read more about setting kernel command line parameters this way [here](../../../setup/customization/other-settings/#adding-custom-kernel-boot-options).

In case you want to disable the autologin on the console with Ignition v2 where no `kernelArguments` directive exists, you can use the following directive in your Container Linux Config YAML.
To take effect it requires an additional reboot.

```yaml
storage:
  filesystems:
    - name: oem
      mount:
        device: /dev/disk/by-label/OEM
        format: btrfs
        label: OEM
  files:
    - path: /grub.cfg
      filesystem: oem
      mode: 0644
      append: true
      contents:
        inline: |
          set linux_append=""
```

## Using Flatcar Container Linux

Now that you have a machine booted it is time to play around. Check out the [Flatcar Container Linux Quickstart][quickstart] guide or dig into [more specific topics][doc-index].

[quickstart]: ../
[doc-index]: ../../

## Terraform

The [`metal`](https://registry.terraform.io/providers/equinix/metal/latest/docs) Terraform Provider allows to deploy machines in a declarative way.
Read more about using Terraform and Flatcar [here](../../provisioning/terraform/).

The following Terraform v0.13 module may serve as a base for your own setup.

Start with a `metal-machines.tf` file that contains the main declarations:

```
terraform {
  required_version = ">= 0.13"
  required_providers {
    metal = {
      source  = "equinix/metal"
      version = "3.3.0-alpha.1"
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

resource "metal_device" "machine" {
  for_each         = toset(var.machines)
  hostname         = "${var.cluster_name}-${each.key}"
  plan             = var.plan
  facilities       = var.facilities
  operating_system = "flatcar_stable"
  billing_cycle    = "hourly"
  project_id       = var.project_id
  user_data        = data.ct_config.machine-ignitions[each.key].rendered
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
  description = "SSH public keys for user 'core', only needed if you don't have it specified in the Equinix Metal Project"
}

variable "facilities" {
  type        = list(string)
  default     = ["sjc1"]
  description = "List of facility codes with deployment preferences"
}

variable "plan" {
  type        = string
  default     = "t1.small.x86"
  description = "The device plan slug"
}

variable "project_id" {
  type        = string
  description = "The Equinix Metal Project to deploy in (in the web UI URL after /projects/)"
}
```

An `outputs.tf` file shows the resulting IP addresses:

```
output "ip-addresses" {
  value = {
    for key in var.machines :
    "${var.cluster_name}-${key}" => metal_device.machine[key].access_public_ipv4
  }
}
```

Now you can use the module by declaring the variables and a Container Linux Configuration for a machine.
First create a `terraform.tfvars` file with your settings:

```
cluster_name = "mycluster"
machines     = ["mynode"]
plan         = "t1.small.x86"
facilities   = ["sjc1"]
project_id   = "1...-2...-3...-4...-5..."
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
export METAL_AUTH_TOKEN=...
terraform init
terraform apply
```

Log in via `ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null core@IPADDRESS` with the printed IP address.

When you make a change to `machine-mynode.yaml.tmpl` and run `terraform apply` again, the machine will be replaced.

It is recommended to register your SSH key in the Equinix Metal Project to use the out-of-band console. Since Flatcar will fetch this key, too, you can remove it from the YAML config.

You can find this Terraform module in the repository for [Flatcar Terraform examples](https://github.com/flatcar-linux/flatcar-terraform/tree/main/equinix-metal-aka-packet).
