---
title: Getting Started with Flatcar Container Linux 
linktitle: Installing
weight: 2
aliases:
    - os/quickstart
    - quickstart
---

If you don't have a Flatcar Container Linux machine running, check out the guides on [running Flatcar Container Linux][running-container-linux] on most cloud providers ([EC2][ec2-docs], [Azure][azure-docs], [GCE][gce-docs], [Equinix Metal][equinix-metal-docs]), virtualization platforms ([Vagrant][vagrant-docs], [VMware][vmware-docs], [VirtualBox][virtualbox-docs] [QEMU/KVM][qemu-docs]/[libVirt][libvirt-docs]) and bare metal servers ([PXE][pxe-docs], [iPXE][ipxe-docs], [ISO][iso-docs], [Installer][install-docs]). With any of these guides you will have machines up and running in a few minutes.

## Booting your first machine

The way from a small [Container Linux Config (CLC) YAML][cl-configs] or [Ignition JSON][ignition] file to a local [QEMU VM][qemu-docs] on your laptop is not far.
Here we will create a systemd service that starts an NGINX container as example configuration for the VM.
This is a good starting point for you to modify the CLC YAML file (or the Ignition JSON file) and test it by provisioning a temporary QEMU VM.
This should work on most Linux systems and assumes you have an SSH key set up for ssh-agent.

First download the Flatcar QEMU image and the helper script to start it with QEMU.
For provisioning with Ignition we have to make sure that we always boot an unmodified fresh image because Ignition only runs on first boot.
Therefore, before trying to use an Ignition config we will always discard the image modifications by using a fresh copy.
You can already boot the image and have a look around in the OS through the QEMU VGA console - you can close the QEMU window or stop the script with `Ctrl-C`.

```shell
wget https://stable.release.flatcar-linux.net/amd64-usr/current/flatcar_production_qemu_image.sh
chmod +x flatcar_production_qemu_image.sh
wget https://stable.release.flatcar-linux.net/amd64-usr/current/flatcar_production_qemu_image.img.bz2
bunzip2 flatcar_production_qemu_image.img.bz2
mv flatcar_production_qemu_image.img flatcar_production_qemu_image.img.fresh
# If you want to have a first look, boot it and wait for the autologin to give you a prompt:
cp -i --reflink=auto flatcar_production_qemu_image.img.fresh flatcar_production_qemu_image.img
./flatcar_production_qemu.sh
```

Besides the interaction with the VM through the VGA console you can also use SSH because the script passes your SSH public key to the VM.
Since we don't want to remember the VM's SSH host keys, we can add SSH options to ignore them.
The user is `core` and the script defauls to port 2222:

```shell
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 core@127.0.0.1
```

Now we will provision the VM on first boot through Ignition.
Instead of writing the JSON config we use CLC YAML and transpile it.
Save the following CLC YAML file as `cl.yaml` (or another name).
It contains directives for setting up a systemd service that runs an NGINX Docker container:

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

Before we can use it we have to transpile the CLC YAML to Ignition JSON:

```shell
cat cl.yaml | docker run --rm -i quay.io/coreos/ct:latest-dev > ignition.json
```

You can also skip this step and copy the resulting JSON file from here to `ignition.json` (or another name):

```
{
  "ignition": {
    "version": "2.3.0"
  },
  "systemd": {
    "units": [
      {
        "contents": "[Unit]\nDescription=NGINX example\nAfter=docker.service\nRequires=docker.service\n[Service]\nTimeoutStartSec=0\nExecStartPre=-/usr/bin/docker rm --force nginx1\nExecStart=/usr/bin/docker run --name nginx1 --pull always --net host docker.io/nginx:1\nExecStop=/usr/bin/docker stop busybox1\nRestart=always\nRestartSec=5s\n[Install]\nWantedBy=multi-user.target\n",
        "enabled": true,
        "name": "nginx.service"
      }
    ]
  }
}
```

The final step is to boot the VM and make the Ignition configuration available to it.
As said, the provisioning will only be done on first boot and if you want your (changed) Ignition configuration to be used, you have to boot from a fresh copy.
You can repeat these combined steps as often as you want to test your Ignition changes:

```shell
# Make sure we boot a fresh copy:
cp -i --reflink=auto flatcar_production_qemu_image.img.fresh flatcar_production_qemu_image.img
./flatcar_production_qemu.sh -i ignition.json
# Log in via SSH in a new terminal tab:
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 core@127.0.0.1
# Check that NGINX is running:
systemctl status nginx
curl http://localhost/
```

If you can't or don't want to use the SSH public key from ssh-agent, you can specify another one in the CLC config by adding this section to your YAML file:

```yaml
passwd:
  users:
    - name: core
      ssh_authorized_keys:
        - ssh-rsa AAAAB......xyz email@host.net
```

Afterwards, transpile it again to Ignition JSON.


[running-container-linux]: ../#installing-flatcar
[ec2-docs]: cloud/aws-ec2
[azure-docs]: cloud/azure
[gce-docs]: cloud/gcp
[vagrant-docs]: vms/vagrant
[vmware-docs]: cloud/vmware
[virtualbox-docs]: vms/virtualbox
[qemu-docs]: vms/qemu
[libvirt-docs]: vms/libvirt
[equinix-metal-docs]: cloud/equinix-metal
[pxe-docs]: bare-metal/booting-with-pxe
[ipxe-docs]: bare-metal/booting-with-ipxe
[iso-docs]: bare-metal/booting-with-iso
[install-docs]: bare-metal/installing-to-disk
[ignition]: ../provisioning/ignition/
[cl-configs]: ../provisioning/cl-config
