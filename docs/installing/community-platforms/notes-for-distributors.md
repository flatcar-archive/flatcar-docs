---
title: Notes for distributors
weight: 10
aliases:
    - ../../os/notes-for-distributors
    - ../../bare-metal/notes-for-distributors
---

## Importing images

Images of Flatcar Container Linux alpha releases are hosted at [`https://alpha.release.flatcar-linux.net/amd64-usr/`][alpha-bucket]. There are directories for releases by version as well as `current` with a copy of the latest version. Similarly, beta releases can be found at [`https://beta.release.flatcar-linux.net/amd64-usr/`][beta-bucket], and stable releases at [`https://stable.release.flatcar-linux.net/amd64-usr/`][stable-bucket].

Each directory has a `version.txt` file containing version information for the files in that directory. If you are importing images for use inside your environment it is recommended that you fetch `version.txt` from the `current` directory and use its contents to compute the path to the other artifacts. For example, to download the alpha OpenStack version of Flatcar Container Linux:

1. Download `https://alpha.release.flatcar-linux.net/amd64-usr/current/version.txt`.
2. Parse `version.txt` to obtain the value of `COREOS_VERSION_ID`, for example `1576.1.0`.
3. Download `https://alpha.release.flatcar-linux.net/amd64-usr/1576.1.0/flatcar_production_openstack_image.img.bz2`.

It is recommended that you also verify files using the [Flatcar Container Linux Image Signing Key][signing-key]. The GPG signature for each image is a detached `.sig` file that must be passed to `gpg --verify`. For example:

```shell
wget https://alpha.release.flatcar-linux.net/amd64-usr/current/flatcar_production_qemu_image.img.bz2
wget https://alpha.release.flatcar-linux.net/amd64-usr/current/flatcar_production_qemu_image.img.bz2.sig
gpg --verify flatcar_production_qemu_image.img.bz2.sig
```

The signing key is rotated annually. We will announce upcoming rotations of the signing key on the [user mailing list][flatcar-user].

[alpha-bucket]: https://alpha.release.flatcar-linux.net/amd64-usr/
[beta-bucket]: https://beta.release.flatcar-linux.net/amd64-usr/
[stable-bucket]: https://stable.release.flatcar-linux.net/amd64-usr/
[signing-key]: https://www.flatcar.org/security/image-signing-key/
[flatcar-user]: https://groups.google.com/forum/#!forum/flatcar-linux-user

## Image customization

There are two predominant ways that a Flatcar Container Linux image can be easily customized for a specific operating environment: through Ignition, a first-boot provisioning tool that runs during a machine's boot process, and through [cloud-config](https://github.com/flatcar/coreos-cloudinit/blob/master/Documentation/cloud-config.md), an older tool that runs every time a machine boots.

### Ignition

[Ignition][ignition] is a tool that acquires a JSON config file when a machine first boots, and uses this config to perform tasks such as formatting disks, creating files, modifying and creating users, and adding systemd units. How Ignition acquires this config file varies per-platform, and it is highly recommended that providers ensure Ignition supports their respective platform. In addition to providers supported by [upstream Ignition][ign-platforms], Flatcar [supports](https://github.com/flatcar/scripts/blob/main/sdk_container/src/third_party/coreos-overlay/sys-apps/ignition/files/0018-revert-internal-oem-drop-noop-OEMs.patch) cloudsigma, hyperv, interoute, niftycloud, rackspace[-onmetal], and vagrant.

Use Ignition to handle platform specific configuration such as custom networking, running an agent on the machine, or injecting files onto disk. To do this, place an Ignition config at `/usr/share/oem/base/base.ign` and it will be prepended to the user provided config. In addition, any config placed at `/usr/share/oem/base/default.ign` will be executed if a user config is not found. On platforms that support cloud-config, use this feature to run coreos-cloudinit when no Ignition config is provided.

Additionally, it is recommended that providers ensure that [Afterburn][coreos-metadata] has support for their platform. This will allow a nicer user experience, as Afterburn will be able to install users' ssh keys and users will be able to reference metadata variables in their systemd units.

[ignition]: ../../provisioning/ignition
[ign-platforms]: https://github.com/coreos/ignition/blob/main/docs/supported-platforms.md
[ign-platforms]: https://github.com/kinvolk/ignition/blob/master/doc/supported-platforms.md
[coreos-metadata]: https://github.com/coreos/afterburn/

### Cloud config

A Flatcar Container Linux image can also be customized using [cloud-config](https://github.com/kinvolk/coreos-cloudinit/blob/master/Documentation/cloud-config.md). Users are recommended to instead use Butane Configs (that are converted into Ignition configs with [Butane][butane-configs]), for reasons [outlined in the blog post that introduced Ignition][ignition-blog].

Providers that previously supported cloud-config should continue to do so, as not all users have switched over to Butane Configs. New platforms do not need to support cloud-config.

Flatcar Container Linux will automatically parse and execute `/usr/share/oem/cloud-config.yml` if it exists.

[ignition-blog]: https://www.toddpigram.com/2016/04/introducing-ignition-new-coreos-machine.html
[butane-configs]: ../../provisioning/config-transpiler

## Handling end-user Ignition files

End-users should be able to provide an Ignition file to your platform while specifying their VM's parameters. This file should be made available to Flatcar Container Linux at the time of boot (e.g. at known network address, injected directly onto disk). Examples of these data sources can be found in the [Ignition documentation][ign-platforms].

[ign-platforms]: https://github.com/coreos/ignition/blob/main/docs/supported-platforms.md
