# Installing Flatcar Container Linux to disk

## Install script

There is a simple installer that will destroy everything on the given target disk and install Flatcar Container Linux. Essentially it downloads an image, verifies it with gpg, and then copies it bit for bit to disk. An installation requires at least 8 GB of usable space on the device.

The script is self-contained and located [on GitHub here][flatcar-install] and can be run from any Linux distribution. You cannot normally install Flatcar Container Linux to the same device that is currently booted. However, the [Flatcar Container Linux ISO][flatcar-iso] or any Linux liveCD will allow Flatcar Container Linux to install to a non-active device.

If you boot Flatcar Container Linux via PXE, the install script is already installed. By default the install script will attempt to install the same version and channel that was PXE-booted:

```sh
flatcar-install -d /dev/sda -i ignition.json
```

`ignition.json` should include user information (especially an SSH key) generated from a [Container Linux Config][clc-section], or you will not be able to log into your Flatcar Container Linux instance.

If you are installing on VMware, pass `-o vmware_raw` to install the VMware-specific image:

```sh
flatcar-install -d /dev/sda -i ignition.json -o vmware_raw
```

## Choose a channel

Flatcar Container Linux is designed to be [updated automatically][update-strategies] with different schedules per channel. You can [disable this feature](update-strategies.md), although we don't recommend it. Read the [release notes](https://flatcar-linux.org/releases) for specific features and bug fixes.

<div id="install">
  <ul class="nav nav-tabs">
    <li class="active"><a href="#stable-create" data-toggle="tab">Stable Channel</a></li>
    <li><a href="#beta-create" data-toggle="tab">Beta Channel</a></li>
    <li><a href="#alpha-create" data-toggle="tab">Alpha Channel</a></li>
    <li><a href="#edge-create" data-toggle="tab">Edge Channel</a></li>
  </ul>
  <div class="tab-content coreos-docs-image-table">
    <div class="tab-pane" id="alpha-create">
      <p>The Alpha channel closely tracks master and is released frequently. The newest versions of system libraries and utilities will be available for testing. The current version is Flatcar Container Linux {{site.alpha-channel}}.</p>
      <p>If you want to ensure you are installing the latest alpha version, use the <code>-C</code> option:</p>
      <pre>flatcar-install -d /dev/sda -C alpha</pre>
    </div>
    <div class="tab-pane" id="beta-create">
      <p>The Beta channel consists of promoted Alpha releases. The current version is Flatcar Container Linux {{site.beta-channel}}.</p>
      <p>If you want to ensure you are installing the latest beta version, use the <code>-C</code> option:</p>
      <pre>flatcar-install -d /dev/sda -C beta</pre>
    </div>
    <div class="tab-pane" id="edge-create">
      <p>The Edge channel includes bleeding-edge features with the newest versions of the Linux kernel, systemd and other core packages. Can be highly unstable. The current version is Flatcar Container Linux {{site.edge-channel}}.</p>
      <p>If you want to ensure you are installing the latest edge version, use the <code>-C</code> option:</p>
      <pre>flatcar-install -d /dev/sda -C edge</pre>
    </div>
    <div class="tab-pane active" id="stable-create">
      <p>The Stable channel should be used by production clusters. Versions of Flatcar Container Linux are battle-tested within the Beta and Alpha channels before being promoted. The current version is Flatcar Container Linux {{site.stable-channel}}.</p>
      <p>If you want to ensure you are installing the latest stable version, use the <code>-C</code> option:</p>
      <pre>flatcar-install -d /dev/sda -C stable</pre>
    </div>
  </div>
</div>

For reference here are the rest of the `flatcar-install` options:

```
-d DEVICE   Install Flatcar Container Linux to the given device.
-s          EXPERIMENTAL: Install Flatcar Container Linux to the smallest unmounted disk found
            (min. size 10GB). It is recommended to use it with -e or -I to filter the
            block devices by their major numbers. E.g., -e 7 to exclude loop devices
            or -I 8,259 for certain disk types. Read more about the numbers here:
            https://www.kernel.org/doc/Documentation/admin-guide/devices.txt.
-V VERSION  Version to install (e.g. current)
-B BOARD    Flatcar Container Linux board to use
-C CHANNEL  Release channel to use (e.g. beta)
-I|e <M,..> EXPERIMENTAL (used with -s): List of major device numbers to in-/exclude
            when finding the smallest disk.
-o OEM      OEM type to install (e.g. ami), using flatcar_production_<OEM>_image.bin.bz2
-c CLOUD    Insert a cloud-init config to be executed on boot.
-i IGNITION Insert an Ignition config to be executed on boot.
-b BASEURL  URL to the image mirror (overrides BOARD and CHANNEL)
-k KEYFILE  Override default GPG key for verifying image signature
-f IMAGE    Install unverified local image file to disk instead of fetching
-n          Copy generated network units to the root partition.
-v          Super verbose, for debugging.
```

## Container Linux Configs

By default there isn't a password or any other way to log into a fresh Flatcar Container Linux system. The easiest way to configure accounts, add systemd units, and more is via Container Linux Configs. Jump over to the [docs to learn about the supported features][cl-configs].

After using the [Container Linux Config Transpiler][ct] to produce an Ignition config, the installation script will process your `ignition.json` file specified with the `-i` flag and use it when the installation is booted.

A Container Linux Config that specifies an SSH key for the `core` user but doesn't use any other parameters looks like:

```yaml
passwd:
  users:
    - name: core
      ssh_authorized_keys:
        - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDGdByTgSVHq.......
```


Note: The `{PRIVATE_IPV4}` and `{PUBLIC_IPV4}` substitution variables referenced in other documents are not supported on libvirt.

To start the installation script with a reference to our Ignition config, run:

```
flatcar-install -d /dev/sda -C stable -i ~/ignition.json
```

### Advanced Container Linux Config example

This example will configure Flatcar Container Linux components: etcd and flannel. You have to substitute `<PEER_ADDRESS>` to your host's IP or DNS address.

```yaml
passwd:
  users:
    - name: core
      ssh_authorized_keys:
        - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDGdByTgSVHq.......
etcd:
  # generate a new token for each unique cluster from https://discovery.etcd.io/new?size=3
  # specify the initial size of your cluster with ?size=X
  discovery: https://discovery.etcd.io/<token>
  advertise_client_urls: http://<PEER_ADDRESS>:2379,http://<PEER_ADDRESS>:4001
  initial_advertise_peer_urls: http://<PEER_ADDRESS>:2380
  # listen on both the official ports and the legacy ports
  # legacy ports can be omitted if your application doesn't depend on them
  listen_client_urls: http://0.0.0.0:2379,http://0.0.0.0:4001
  listen_peer_urls: http://<PEER_ADDRESS>:2380
systemd:
  units:
    - name: flanneld.service
      enable: true
      dropins:
      - name: 50-network-config.conf
        contents: |
          [Service]
          ExecStartPre=/usr/bin/etcdctl set /kinvolk.io/network/config '{"Network":"10.1.0.0/16", "Backend": {"Type": "vxlan"}}'
```

## Using Flatcar Container Linux

Now that you have a machine booted it is time to play around. Check out the [Flatcar Container Linux Quickstart][quickstart] guide or dig into [more specific topics][docs-root].

[quickstart]: quickstart.md
[docs-root]: https://docs.flatcar-linux.org
[update-strategies]: https://docs.flatcar-linux.org/os/update-strategies/
[flatcar-iso]: booting-with-iso.md
[clc-section]: #container-linux-configs
[flatcar-install]: https://raw.githubusercontent.com/flatcar-linux/init/flatcar-master/bin/flatcar-install
[cl-configs]: provisioning.md
[ct]: https://github.com/coreos/container-linux-config-transpiler/blob/master/doc/overview.md
