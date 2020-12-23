---
content_type: flatcar
title: Flatcar Container Linux
main_menu: true
weight: 40
---

Flatcar Container Linux is a container optimized OS that ships a minimal OS
image, which includes only the tools needed to run containers. The OS is
shipped through an immutable filesystem and includes automatic atomic
updates.

### Installing Flatcar

Flatcar Container Linux runs on most cloud providers, virtualization
platforms and bare metal servers. 

#### Cloud Providers
 * [Amazon EC2][ec2]
 * [Microsoft Azure][azure]
 * [Google Compute Engine][gce]
 * [Equinix Metal][equinix-metal]
 * [VMware][vmware]
 * [DigitalOcean][digital-ocean]
 * [Hetzner][hetzner]

#### Virtualization options
It's easy to run a local Flatcar VM on your laptop for testing and debugging
purposes. You can use any of the following options.

 * [QEMU][qemu]
 * [libVirt][libvirt]
 * [VirtualBox][virtualbox] (not officially supported)
 * [Vagrant][vagrant] (not officially supported)

#### Bare Metal
You can install Flatcar on bare metal machines in different ways: using ISO
images, booting from PXE or iPXE, and even by running an installation
script on an existing Linux system.

 * [Installing from ISO images][boot-iso]
 * [Booting with PXE][pxe]
 * [Booting with iPXE][ipxe]
 * [Installing with flatcar-install][install-to-disk]

If you want to provide metadata to your baremetal machines, we recommend
using [Matchbox][matchbox].

#### Upgrading from CoreOS Container Linux

Flatcar Container Linux is a drop-in replacement of CoreOS Container Linux.
If you are a CoreOS Container Linux user looking for a replacement,
checkout our guides to [migrate from CoreOS Container
Linux][migrate-from-container-linux], or you can [update from CoreOS
Container Linux][update-from-container-linux] directly.

### Provisioning Tools

[Ignition][ignition-what] is the recommended way to provision Flatcar
Container Linux at first boot.  Ignition uses a JSON configuration file,
and it is recommended to generate it from the [Container Linux
Config][container-linux-config] YAML format, which has additional features.
The [Container Linux Config Transpiler][config-transpiler] converts a
Container Linux Config to an Ignition config.

 * [Understanding the Boot Process][ignition-boot]
 * [Configuring the Network with Ignition][ignition-network]
 * [Using metadata during provisioning][ignition-metadata]
 * [Getting started with Container Linux Config][config-intro]
 * [Platform agnostic metadata in Container Linux Config][config-dynamic-data]
 * [Using Terraform to provision Flatcar Container Linux][terraform]

### Setting Flatcar Up and Common Operations

Follow these guides to connect your machines together as a cluster,
configure machine parameters, create users, inject multiple SSH keys, and
more.

#### Customizing Flatcar
 * [Using networkd to customize networking][networkd-customize]
 * [Using systemd drop-in units][systemd-drop-in]
 * [Using environment variables in systemd units][environment-variables-systemd]
 * [Using systemd and udev rules][udev-rules]
 * [Scheduling tasks with systemd timers][tasks-with-systemd]
 * [Configuring DNS][dns]
 * [Configuring date & timezone][date-timezone]
 * [Adding users][users]
 * [Kernel modules / sysctl parameters][parameters]
 * [Adding swap][swap]
 * [Power management][power-management]

#### Managing Releases and Updates
 * [Switching release channels][release-channels]
 * [Configuring the update strategy][update-strategies]
 * [Flatcar update configuration specification][update-conf]
 * [Verifying Flatcar Images with GPG][verify-container-linux]

#### Creating Clusters
 * [Cluster architectures][cluster-architectures]
 * [Clustering machines][clustering-machines]
 * [Using Amazon EC2 Container Service][ec2-container-service]

#### Managing Storage
 * [Using RAID for the root filesystem][filesystem-placement]
 * [Adding disk space][disk-space]
 * [Mounting storage][mounting-storage]
 * [iSCSI configuration][iscsi]

#### Additional security options
 * [Customizing the SSH daemon][ssh-daemon]
 * [Configuring SSSD on Flatcar Container Linux][sssd-container-linux]
 * [Hardening a Flatcar Container Linux machine][hardening-container-linux]
 * [Trusted Computing Hardware Requirements][hardware-requirements]
 * [Adding Cert Authorities][cert-authorities]
 * [Using SELinux][selinux]
 * [Disabling SMT][disabling-smt]

#### Debugging Flatcar
 * [Install debugging tools][debugging-tools]
 * [Working with btrfs][btrfs]
 * [Reading the system log][system-log]
 * [Collecting crash logs][crash-log]
 * [Manual Flatcar Container Linux rollbacks][container-linux-rollbacks]

### Container Runtimes
Flatcar Container Linux supports all of the popular methods for running
containers, and you can choose to interact with the containers at a
low-level, or use a higher level orchestration framework. Listed below are
some guides to help you choose and make use of the different runtimes.

 * [Getting started with Docker][docker]
 * [Customizing Docker][customizing-docker]
 * [Using systemd to manage Docker containers][manage-docker-containers]
 * [Use a custom Docker or containerd version][use-a-custom-docker-or-containerd-version]
 * [Switching from Docker to containerd for Kubernetes][containerd-for-kubernetes]
 * [Authenticating to Container registries][registry-authentication]

### Reference
APIs and troubleshooting guides for working with Flatcar Container Linux.

[Developer guides][developer-guides]

[Integrations][integrations]

[Migrating from cloud-config to Container Linux Config][migrating-from-cloud-config]

[quick-start]: installing
[ignition-what]: ignition/
[ignition-boot]: ignition/boot-process
[ignition-network]: ignition/network-configuration
[ignition-metadata]: ignition/metadata
[container-linux-config]: reference/migrating-to-clcs/provisioning/
[config-transpiler]: container-linux-config-transpiler/
[config-intro]: container-linux-config-transpiler/getting-started
[config-dynamic-data]: container-linux-config-transpiler/dynamic-data
[config-examples]: container-linux-config-transpiler/examples
[config-spec]: container-linux-config-transpiler/configuration
[config-notes]: container-linux-config-transpiler/operators-notes
[matchbox]: https://matchbox.psdn.io/
[ipxe]: installing/bare-metal/booting-with-ipxe
[pxe]: installing/bare-metal/booting-with-pxe
[install-to-disk]: installing/bare-metal/installing-to-disk
[boot-iso]: installing/bare-metal/booting-with-iso
[filesystem-placement]: installing/bare-metal/root-filesystem-placement
[migrate-from-container-linux]: migrating-from-coreos/
[update-from-container-linux]: migrating-from-coreos/update-from-container-linux
[ec2]: installing/cloud/aws-ec2
[digital-ocean]: installing/cloud/digitalocean
[gce]: installing/cloud/gcp
[azure]: installing/cloud/azure
[qemu]: installing/vms/qemu
[equinix-metal]: installing/cloud/equinix-metal
[libvirt]: installing/vms/libvirt
[virtualbox]: installing/vms/virtualbox
[vagrant]: installing/vms/vagrant
[vmware]: installing/cloud/vmware
[cluster-architectures]: clusters/creation/cluster-architectures
[update-strategies]: clusters/creation/update-strategies
[clustering-machines]: clusters/creation/cluster-discovery
[verify-container-linux]: clusters/creation/verify-images
[networkd-customize]: clusters/customization/network-config-with-networkd
[systemd-drop-in]: clusters/customization/using-systemd-drop-in-units
[environment-variables-systemd]: clusters/customization/using-environment-variables-in-systemd-units
[dns]: clusters/customization/configuring-dns
[date-timezone]: clusters/customization/configuring-date-and-timezone
[users]: clusters/customization/adding-users
[parameters]: clusters/customization/other-settings
[disk-space]: clusters/scaling/adding-disk-space
[mounting-storage]: clusters/scaling/mounting-storage
[power-management]: clusters/scaling/power-management
[registry-authentication]: clusters/management/registry-authentication
[iscsi]: clusters/management/iscsi
[swap]: clusters/management/adding-swap
[ec2-container-service]: clusters/management/booting-on-ecs/
[manage-docker-containers]: clusters/management/getting-started-with-systemd
[udev-rules]: clusters/management/using-systemd-and-udev-rules
[update-conf]: clusters/management/update-conf
[release-channels]: clusters/management/switching-channels
[tasks-with-systemd]: clusters/management/scheduling-tasks-with-systemd-timers
[ssh-daemon]: clusters/securing/customizing-sshd
[sssd-container-linux]: clusters/securing/sssd
[hardening-container-linux]: clusters/securing/hardening-guide
[hardware-requirements]: clusters/securing/trusted-computing-hardware-requirements
[cert-authorities]: clusters/securing/adding-certificate-authorities
[selinux]: clusters/securing/selinux
[disabling-smt]: clusters/securing/disabling-smt
[debugging-tools]: clusters/debug/install-debugging-tools
[btrfs]: clusters/debug/btrfs-troubleshooting
[system-log]: clusters/debug/reading-the-system-log
[crash-log]: clusters/debug/collecting-crash-logs
[container-linux-rollbacks]: clusters/debug/manual-rollbacks
[docker]: container-runtimes/getting-started-with-docker
[customizing-docker]: container-runtimes/customizing-docker
[use-a-custom-docker-or-containerd-version]: container-runtimes/use-a-custom-docker-or-containerd-version
[developer-guides]: reference/developer-guides/
[integrations]: reference/integrations/
[migrating-from-cloud-config]: reference/migrating-to-clcs/
[containerd-for-kubernetes]: container-runtimes/switching-from-docker-to-containerd-for-kubernetes
[terraform]: terraform/
[hetzner]: installing/cloud/hetzner
