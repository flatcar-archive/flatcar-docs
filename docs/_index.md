---
content_type: flatcar
title: Flatcar Container Linux
main_menu: true
weight: 40
cascade:
  stable_channel: 3.2.1
  beta_channel: 3.2.1
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

[quick-start]: os/quickstart.md
[ignition-what]: ignition/what-is-ignition.md
[ignition-boot]: ignition/boot-process.md
[ignition-network]: ignition/network-configuration.md
[ignition-metadata]: ignition/metadata.md
[container-linux-config]: os/provisioning.md
[config-transpiler]: container-linux-config-transpiler/doc/overview.md
[config-intro]: container-linux-config-transpiler/doc/getting-started.md
[config-dynamic-data]: container-linux-config-transpiler/doc/dynamic-data.md
[config-examples]: container-linux-config-transpiler/doc/examples.md
[config-spec]: container-linux-config-transpiler/doc/configuration.md
[config-notes]: container-linux-config-transpiler/doc/operators-notes.md
[matchbox]: https://matchbox.psdn.io/
[ipxe]: os/booting-with-ipxe.md
[pxe]: os/booting-with-pxe.md
[install-to-disk]: os/installing-to-disk.md
[boot-iso]: os/booting-with-iso.md
[filesystem-placement]: os/root-filesystem-placement.md
[migrate-from-container-linux]: os/migrate-from-container-linux.md
[update-from-container-linux]: os/update-from-container-linux.md
[ec2]: os/booting-on-ec2.md
[digital-ocean]: os/booting-on-digitalocean.md
[gce]: os/booting-on-google-compute-engine.md
[azure]: os/booting-on-azure.md
[qemu]: os/booting-with-qemu.md
[packet]: os/booting-on-packet.md
[libvirt]: os/booting-with-libvirt.md
[virtualbox]: os/booting-on-virtualbox.md
[vagrant]: os/booting-on-vagrant.md
[vmware]: os/booting-on-vmware.md
[cluster-architectures]: os/cluster-architectures.md
[update-strategies]: os/update-strategies.md
[clustering-machines]: os/cluster-discovery.md
[verify-container-linux]: os/verify-images.md
[networkd-customize]: os/network-config-with-networkd.md
[systemd-drop-in]: os/using-systemd-drop-in-units.md
[environment-variables-systemd]: os/using-environment-variables-in-systemd-units.md
[dns]: os/configuring-dns.md
[date-timezone]: os/configuring-date-and-timezone.md
[users]: os/adding-users.md
[parameters]: os/other-settings.md
[disk-space]: os/adding-disk-space.md
[mounting-storage]: os/mounting-storage.md
[power-management]: os/power-management.md
[registry-authentication]: os/registry-authentication.md
[iscsi]: os/iscsi.md
[swap]: os/adding-swap.md
[ec2-container-service]: os/booting-on-ecs.md
[manage-docker-containers]: os/getting-started-with-systemd.md
[udev-rules]: os/using-systemd-and-udev-rules.md
[release-channels]: os/switching-channels.md
[tasks-with-systemd]: os/scheduling-tasks-with-systemd-timers.md
[ssh-daemon]: os/customizing-sshd.md
[sssd-container-linux]: os/sssd.md
[hardening-container-linux]: os/hardening-guide.md
[hardware-requirements]: os/trusted-computing-hardware-requirements.md
[cert-authorities]: os/adding-certificate-authorities.md
[selinux]: os/selinux.md
[disabling-smt]: os/disabling-smt.md
[debugging-tools]: os/install-debugging-tools.md
[btrfs]: os/btrfs-troubleshooting.md
[system-log]: os/reading-the-system-log.md
[crash-log]: os/collecting-crash-logs.md
[container-linux-rollbacks]: os/manual-rollbacks.md
[docker]: os/getting-started-with-docker.md
[customizing-docker]: os/customizing-docker.md
[developer-guides]: os/developer-guides.md
[integrations]: os/integrations.md
[migrating-from-cloud-config]: os/migrating-to-clcs.md
