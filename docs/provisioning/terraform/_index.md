---
title: Terraform
description: Provision Flatcar Container Linux with an Ignition configuration through Terraform
weight: 40
---

Flatcar Container Linux fits well with Terraform for the principle of Immutable Infrastructure where you deploy a node and, instead of making changes via SSH, you destroy it and deploy a new node.
The big advantages compared to other OSes are the inbuilt support for declarative configuration with Ignition on first boot and the automatic OS updates.

Many cloud services allow to provide _User Data_ for a node in an extra attribute. Ignition will fetch the configuration from this place and apply it. No Terraform SSH provisioning commands are needed.

## Terraform Providers for the different Cloud Services

How to use the Terraform Providers of each cloud service is explained on the respective documentation page under [Cloud Providers][cloud].

## Changing the Ignition Configuration

Changes to the User Data attribute should normally destroy the node and recreate it so that Ignition runs again on the first boot.
However, this behavior depends on the Terraform provider for your cloud service.
Some cloud services allow to update the attribute in-place without destroying the node but Ignition won't run again by default and even if you triggered it, you would have to be careful as this is not recommended (more on this at the end of this document).
You can also tell Terraform not ignore attribute changes (set `ignore_changes`) and thus delay the change until you manually destroy the node and recreate it with Terraform.
This is sometimes useful but may be a source of errors when you don't know that a node still runs an old configuration.

To make the recreation of a node less disruptive, you can architect your setup to accept a node to exist twice at the same time and set `create_before_destroy` to let Terraform first create the replacement node and then destroy the old node.
On AWS, it's also possible to use Auto Scaling Groups instead of directly operating on instances. In this case, to update the User Data you can replace the Auto Scaling Group, and the new one will take care of creating new nodes and the old one deletes the old ones.
An advanced scheme of this on AWS can use Auto Scaling Groups instead of directly operating on instances, and to change the User Data you replace the Auto Scaling Group and the new one takes care of creating new nodes and the old one deletes the old ones.
It is also advisable to separate the persistent data from the disposable nodes to external data volumes or to use a backup mechanism and inject the backup on the first boot.

## Generating the Ignition Configuration within Terraform

To convert the Container Linux Config in YAML to the final Igniton Config in JSON you don't need to run [`ct`][ct] manually. Instead, you can directly do this within Terraform, through the [`terraform-ct-provider`][terraform-ct-provider].
Combined with the `template-provider` you can reference Terraform variables in the YAML template.

An alternative is the [`terraform-ignition-provider`][terraform-ignition-provider] that allows to assemble the Ignition Config from Terraform declarations.

The following snippet demonstrates the use of the `terraform-ct-provider` and the `template-provider` to specify the User Data attribute on a Packet (now Equinix Metal) instance:

```
resource "packet_device" "machine" {
  operating_system = "flatcar_stable"
  user_data = data.ct_config.machine-ignition.rendered
  [...]
}

data "ct_config" "machine-ignition" {
  content = data.template_file.machine-cl-config.rendered
}

data "template_file" "machine-cl-config" {
  template = file("${path.module}/machine.yaml.tmpl")
  vars = { something = var.something }
}
```

When using a template be careful to refer to the Terraform variables via `${variable}` while shell variables in scripts used at OS runtime need to be quoted like `$${variable}` or need to use the `$variable` syntax.

## Updating the User Data in-place and rerunning Ignition instead of destroying nodes

Sometimes you want to take the declarative approach of Terraform but can't accept that nodes are destroyed and recreated for configuration changes.
This is the case for nodes that have a manual or slow bring-up process, much data that can't be moved easily, or where the IP address should not change.

Ignition can be told to run again through `touch /boot/flatcar/first_boot` but it [won't clean up any old state][boot-process].
For that you have to reformat the root filesystem with Ignition to ensure that no old state is present.
Persistent data should be stored on another partition.

We can also preserve the machine ID by setting it as kernel cmdline parameter (it must not be kept as file on the root filesystem because that prevents the systemd first-boot semantics to enable units through the preset Ignition creates).

This Container Linux Config snippet takes care of reformating the root filesystem and places a reprovisioning helper script on the OEM partition:

```yaml
storage:
  files:
    - path: /reprovision
      filesystem: oem
      mode: 0755
      contents:
        inline: |
          #!/bin/bash
          set -euo pipefail
          touch /usr/share/oem/grub.cfg
          sed -i "/linux_append systemd.machine_id=.*/d" /usr/share/oem/grub.cfg
          echo "set linux_append=\"\$linux_append systemd.machine_id=$(cat /etc/machine-id)\"" >> /usr/share/oem/grub.cfg
          touch /boot/flatcar/first_boot
  filesystems:
    - name: root
      mount:
        device: /dev/disk/by-label/ROOT
        format: ext4
        wipe_filesystem: true
        label: ROOT
    - name: oem
      mount:
        device: /dev/disk/by-label/OEM
        format: btrfs
        label: OEM
```

The final User Data needs to be stored on a place where modifications are allowed without destroying the node.
A good option could be AWS S3 or other similar cloud storage solutions.
The real User Data of the node is just an Ignition Config that references the external User Data:

```
{ "ignition": { "version": "2.1.0", "config": { "replace": { "source": "s3://..." } } } }
```

Under these conditions it is possible to run `sudo /usr/share/oem/reprovision` on the node and trigger reboot for the new Ignition Config to take effect (assuming data in S3):

```
resource "null_resource" "reboot-when-ignition-changes" {
  for_each = toset(var.machines)
  # Triggered when the Ignition Config changes
  triggers = {
    ignition_config = data.ct_config.machine-ignitions[each.key].rendered
  }
  # Wait for the new Ignition config object to be ready before rebooting
  depends_on = [aws_s3_bucket_object.object]
  # Trigger running Ignition on the next reboot and reboot the instance (current limitation: also runs on the first provisioning)
  provisioner "local-exec" {
    command = "while ! ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null core@${packet_device.machine[each.key].access_public_ipv4} sudo /usr/share/oem/reprovision ; do sleep 1; done; while ! ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null core@${packet_device.machine[each.key].access_public_ipv4} sudo systemctl reboot; do sleep 1; done"
  }
}
```

## Examples

You can find the full code for working examples in this [git repository][example-repo].


[cloud]: ../../installing/cloud/
[ct]: ../container-linux-config-transpiler/
[terraform-ct-provider]: https://registry.terraform.io/providers/poseidon/ct/latest
[terraform-ignition-provider]: https://www.terraform.io/docs/providers/ignition/index.html
[boot-process]: ../ignition/boot-process/#reprovisioning
[example-repo]: https://github.com/kinvolk/flatcar-terraform
