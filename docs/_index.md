---
content_type: flatcar
title: Flatcar Container Linux
main_menu: true
weight: 40
cascade:
  alpha_channel: 2605.0.0
  stable_channel: 2512.3.0
  beta_channel: 2512.3.0
  edge_channel: 2466.99.0
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
[CL Config Dynamic Metadata][config-dynamic-data], [Ignition Dynamic Metadata][ignition-metadata] | [Packet][packet]
[CL ct][config-intro], [CL Config Examples][config-examples]                                      | [QEMU][qemu], [libVirt][libvirt], [VirtualBox][virtualbox]¹, [Vagrant][vagrant]¹
[CL Config Spec][config-spec], [CL Config Notes][config-notes]                                    | [VMware][vmware]

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

### Reference
APIs and troubleshooting guides for working with Flatcar Container Linux.

[Developer guides][developer-guides]

[Integrations][integrations]

[Migrating from cloud-config to Container Linux Config][migrating-from-cloud-config]

[quick-start]: os/quickstart
[ignition-what]: ignition/what-is-ignition
[ignition-boot]: ignition/boot-process
[ignition-network]: ignition/network-configuration
[ignition-metadata]: ignition/metadata
[container-linux-config]: os/provisioning
[config-transpiler]: container-linux-config-transpiler/doc/overview
[config-intro]: container-linux-config-transpiler/doc/getting-started
[config-dynamic-data]: container-linux-config-transpiler/doc/dynamic-data
[config-examples]: container-linux-config-transpiler/doc/examples
[config-spec]: container-linux-config-transpiler/doc/configuration
[config-notes]: container-linux-config-transpiler/doc/operators-notes
[matchbox]: https://matchbox.psdn.io/
[ipxe]: os/booting-with-ipxe
[pxe]: os/booting-with-pxe
[install-to-disk]: os/installing-to-disk
[boot-iso]: os/booting-with-iso
[filesystem-placement]: os/root-filesystem-placement
[migrate-from-container-linux]: os/migrate-from-container-linux
[update-from-container-linux]: os/update-from-container-linux
[ec2]: os/booting-on-ec2
[digital-ocean]: os/booting-on-digitalocean
[gce]: os/booting-on-google-compute-engine
[azure]: os/booting-on-azure
[qemu]: os/booting-with-qemu
[packet]: os/booting-on-packet
[libvirt]: os/booting-with-libvirt
[virtualbox]: os/booting-on-virtualbox
[vagrant]: os/booting-on-vagrant
[vmware]: os/booting-on-vmware
[cluster-architectures]: os/cluster-architectures
[update-strategies]: os/update-strategies
[clustering-machines]: os/cluster-discovery
[verify-container-linux]: os/verify-images
[networkd-customize]: os/network-config-with-networkd
[systemd-drop-in]: os/using-systemd-drop-in-units
[environment-variables-systemd]: os/using-environment-variables-in-systemd-units
[dns]: os/configuring-dns
[date-timezone]: os/configuring-date-and-timezone
[users]: os/adding-users
[parameters]: os/other-settings
[disk-space]: os/adding-disk-space
[mounting-storage]: os/mounting-storage
[power-management]: os/power-management
[registry-authentication]: os/registry-authentication
[iscsi]: os/iscsi
[swap]: os/adding-swap
[ec2-container-service]: os/booting-on-ecs
[manage-docker-containers]: os/getting-started-with-systemd
[udev-rules]: os/using-systemd-and-udev-rules
[release-channels]: os/switching-channels
[tasks-with-systemd]: os/scheduling-tasks-with-systemd-timers
[ssh-daemon]: os/customizing-sshd
[sssd-container-linux]: os/sssd
[hardening-container-linux]: os/hardening-guide
[hardware-requirements]: os/trusted-computing-hardware-requirements
[cert-authorities]: os/adding-certificate-authorities
[selinux]: os/selinux
[disabling-smt]: os/disabling-smt
[debugging-tools]: os/install-debugging-tools
[btrfs]: os/btrfs-troubleshooting
[system-log]: os/reading-the-system-log
[crash-log]: os/collecting-crash-logs
[container-linux-rollbacks]: os/manual-rollbacks
[docker]: os/getting-started-with-docker
[customizing-docker]: os/customizing-docker
[developer-guides]: os/developer-guides
[integrations]: os/integrations
[migrating-from-cloud-config]: os/migrating-to-clcs
