---
content_type: flatcar
title: Flatcar Container Linux
main_menu: true
weight: 40
---

Welcome to Flatcar Container Linux documentation

### Getting Started
Flatcar Container Linux runs on most cloud providers, virtualization platforms and bare metal servers. Running a local VM on your laptop is a great dev environment. Following the [Quick Start guide][quick-start] is the fastest way to get set up.

Ignition is the recommended way to provision Flatcar Container Linux at first boot.
Ignition uses a JSON configuration file, and it is recommended to generate it from the Container Linux Config YAML format, which has additional features.
The Container Linux Config Transpiler converts a Container Linux Config to an Ignition config.


Provisioning                                                                                      | Cloud Providers
--------------                                                                                    | -------------
[Using Ignition and Container Linux Config][container-linux-config]                               | [Amazon EC2][ec2]
[Ignition vs coreos-cloudinit][ignition-what], [Boot Process][ignition-boot]                      | [DigitalOcean][digital-ocean]
[Ignition Network Config][ignition-network]                                                       | [Google Compute Engine][gce]
[Container Linux Config Transpiler][config-transpiler]                                            | [Microsoft Azure][azure]
[CL Config Dynamic Metadata][config-dynamic-data], [Ignition Dynamic Metadata][ignition-metadata] | [Equinix Metal][equinix-metal]
[CL ct][config-intro], [CL Config Examples][config-examples]                                      | [QEMU][qemu], [libVirt][libvirt], [VirtualBox][virtualbox]¹, [Vagrant][vagrant]¹
[CL Config Spec][config-spec], [CL Config Notes][config-notes]                                    | [VMware][vmware]
[Terraform][terraform]                                                                            | [Hetzner][hetzner]

_¹ These platforms are not officially supported and releases are not tested._

Bare Metal                                              | Upgrading from CoreOS Container Linux
--------------                                          | -------------
[Using Matchbox][matchbox]                              | [Migrate from CoreOS Container Linux][migrate-from-container-linux]
[Booting with iPXE][ipxe]                               | [Update from CoreOS Container Linux][update-from-container-linux] directly.
[Booting with PXE][pxe]                                 |
[Installing to Disk][install-to-disk]                   |
[Booting from ISO][boot-iso]                            |
[Root filesystem placement][filesystem-placement]


### Working with Clusters
Follow these guides to connect your machines together as a cluster. Configure machine parameters, create users, inject multiple SSH keys, and more with Container Linux Config.

Creating Clusters                                               | Customizing Clusters
--------------                                                  | -------------
[Cluster architectures][cluster-architectures]                  | [Using networkd to customize networking][networkd-customize]
[Update strategies][update-strategies]                          | [Using systemd drop-in units][systemd-drop-in]
[Clustering machines][clustering-machines]                      | [Using environment variables in systemd units][environment-variables-systemd]
[Verify Flatcar Container Linux Images with GPG][verify-container-linux]  | [Configuring DNS][dns]
                                                                | [Configuring date & timezone][date-timezone]
                                                                | [Adding users][users]
                                                                | [Kernel modules / sysctl parameters][parameters]

Managing Clusters                                                      | Scaling Clusters
-------------                                                          | --------------
[Registry authentication][registry-authentication]                     | [Adding disk space][disk-space]
[iSCSI configuration][iscsi]                                           | [Mounting storage][mounting-storage]
[Adding swap][swap]                                                    | [Power management][power-management]
[Amazon EC2 Container Service][ec2-container-service]                  |
[Using systemd to manage Docker containers][manage-docker-containers]  |
[Using systemd and udev rules][udev-rules]                             |
[Switching release channels][release-channels]                         |
[Scheduling tasks with systemd][tasks-with-systemd]                    |
[Flatcar update configuration][update-conf]                            |

Securing Clusters                                               | Debugging Clusters
--------------                                                  | --------------
[Customizing the SSH daemon][ssh-daemon]                        | [Install debugging tools][debugging-tools]
[Configuring SSSD on Flatcar Container Linux][sssd-container-linux]       | [Working with btrfs][btrfs]
[Hardening a Flatcar Container Linux machine][hardening-container-linux]  | [Reading the system log][system-log]
[Trusted Computing Hardware Requirements][hardware-requirements]| [Collecting crash logs][crash-log]
[Adding Cert Authorities][cert-authorities]                     | [Manual Flatcar Container Linux rollbacks][container-linux-rollbacks]
[Using SELinux][selinux]                                        |
[Disabling SMT][disabling-smt]                                    |


### Container Runtimes
Flatcar Container Linux supports all of the popular methods for running containers, and you can choose to interact with the containers at a low-level, or use a higher level orchestration framework. Listed below are your options from the highest level abstraction down to the lowest level, the container runtime.

Docker |
-------------- |
[Getting started with Docker][docker] |
[Customizing Docker][customizing-docker] |
[Use a custom Docker or containerd version][use-a-custom-docker-or-containerd-version] |
[Switching from Docker to containerd for Kubernetes][containerd-for-kubernetes] |

### Reference
APIs and troubleshooting guides for working with Flatcar Container Linux.

[Developer guides][developer-guides]

[Integrations][integrations]

[Migrating from cloud-config to Container Linux Config][migrating-from-cloud-config]

[quick-start]: quickstart
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
[ipxe]: bare-metal/booting-with-ipxe
[pxe]: bare-metal/booting-with-pxe
[install-to-disk]: bare-metal/installing-to-disk
[boot-iso]: bare-metal/booting-with-iso
[filesystem-placement]: bare-metal/root-filesystem-placement
[migrate-from-container-linux]: migrating-from-coreos/
[update-from-container-linux]: migrating-from-coreos/update-from-container-linux
[ec2]: cloud-providers/booting-on-ec2
[digital-ocean]: cloud-providers/booting-on-digitalocean
[gce]: cloud-providers/booting-on-google-compute-engine
[azure]: cloud-providers/booting-on-azure
[qemu]: cloud-providers/booting-with-qemu
[equinix-metal]: cloud-providers/booting-on-packet
[libvirt]: cloud-providers/booting-with-libvirt
[virtualbox]: cloud-providers/booting-on-virtualbox
[vagrant]: cloud-providers/booting-on-vagrant
[vmware]: cloud-providers/booting-on-vmware
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
[hetzner]: cloud-providers/booting-on-hetzner
