---
title: Running Flatcar Container Linux on VMware
linktitle: Running on VMware
weight: 10
aliases:
    - ../os/booting-on-vmware
---

These instructions walk through running Flatcar Container Linux on VMware Fusion or ESXi. If you are familiar with another VMware product, you can use these instructions as a starting point.

## Running the VM

### Choosing a channel

Flatcar Container Linux is designed to be updated automatically with different schedules per channel. You can [disable this feature](update-strategies), although we don't recommend it. Read the [release notes](https://flatcar-linux.org/releases) for specific features and bug fixes.

<div id="vmware-images">
  <ul class="nav nav-tabs">
    <li class="active"><a href="#stable" data-toggle="tab">Stable Channel</a></li>
    <li><a href="#beta" data-toggle="tab">Beta Channel</a></li>
    <li><a href="#alpha" data-toggle="tab">Alpha Channel</a></li>
    <li><a href="#edge" data-toggle="tab">Edge Channel</a></li>
  </ul>
  <div class="tab-content coreos-docs-image-table">
    <div class="tab-pane active" id="stable">
      <div class="channel-info">
        <p>The Stable channel should be used by production clusters. Versions of Flatcar Container Linux are battle-tested within the Beta and Alpha channels before being promoted. The current version is Flatcar Container Linux {{< param stable_channel >}}.</p>
       </div>
      <pre>curl -LO https://stable.release.flatcar-linux.net/amd64-usr/current/flatcar_production_vmware_ova.ova</pre>
    </div>
    <div class="tab-pane" id="alpha">
      <div class="channel-info">
        <p>The Alpha channel closely tracks master and is released frequently. The newest versions of system libraries and utilities will be available for testing. The current version is Flatcar Container Linux {{< param alpha_channel >}}.</p>
      </div>
      <pre>curl -LO https://alpha.release.flatcar-linux.net/amd64-usr/current/flatcar_production_vmware_ova.ova</pre>
    </div>
    <div class="tab-pane" id="beta">
      <div class="channel-info">
        <p>The Beta channel consists of promoted Alpha releases. The current version is Flatcar Container Linux {{< param beta_channel >}}.</p>
      </div>
      <pre>curl -LO https://beta.release.flatcar-linux.net/amd64-usr/current/flatcar_production_vmware_ova.ova</pre>
    </div>
    <div class="tab-pane" id="edge">
      <div class="channel-info">
        <p>The Edge channel includes bleeding-edge features with the newest versions of the Linux kernel, systemd and other core packages. Can be highly unstable. The current version is Flatcar Container Linux {{< param edge_channel >}}.</p>
      </div>
      <pre>curl -LO https://edge.release.flatcar-linux.net/amd64-usr/current/flatcar_production_vmware_ova.ova</pre>
    </div>
  </div>
</div>

### Booting with VMware vSphere/ESXi from the web interface

Use the vSphere Client/ESXi web interface to deploy the VM as follows:

1. In the menu, click `File` > `Deploy OVF Template...`
2. In the wizard, specify the location of the OVA file downloaded earlier
3. Name your VM
4. Choose "thin provision" for the disk format
5. Choose your network settings and [specify provisioning userdata][guestinfo]
6. Confirm the settings, then click "Finish"

Uncheck `Power on after deployment` in order to edit the VM before booting it the first time.

The last step uploads the files to the ESXi datastore and registers the new VM. You can now tweak VM settings, then power it on.

### Booting with VMware vSphere/ESXi from the command line with ovftool

Use the [`ovftool`][ovftool] to deploy from the command line as follows:

```shell
ovftool --name=testvm --skipManifestCheck --noSSLVerify --datastore=datastore1 --powerOn=True --net:"VM Network=VM Network" --X:waitForIp --overwrite --powerOffTarget --X:guest:ignition.config.data=$(cat ignition_config.json | base64 --wrap=0) --X:guest:ignition.config.data.encoding=base64 ./flatcar_production_vmware_ova.ova 'vi:///<YOUR_USER>:<ESXI_PASSWORD>@<ESXI_HOST_IP>'
```

This assumes that you downloaded `flatcar_production_vmware_ova.ova` to your current folder, and that you want to specify an Ignition config as userdata from `ignition_config.json`.

*NB: These instructions were tested with an ESXi v5.5 host.*

### Booting with VMware Workstation 12 or VMware Fusion

Run VMware Workstation GUI:

1. In the menu, click `File` > `Open...`
2. In the wizard, specify the location of the OVA template downloaded earlier
3. Name your VM, then click `Import`
4. (Press `Retry` *if* VMware Workstation raises an "OVF specification" warning)
5. Edit VM settings if necessary and [specify provisioning userdata][guestinfo]
6. Start your Flatcar Container Linux VM

*NB: These instructions were tested with a Fusion 8.1 host.*

### Installing via PXE or ISO image

Flatcar Container Linux can also be installed by booting the virtual machine via [PXE][PXE] or the [ISO image][ISO] and then [installing Flatcar Container Linux to disk][install].

## Container Linux Configs

Flatcar Container Linux allows you to configure machine parameters, configure networking, launch systemd units on startup, and more via Container Linux Configs. These configs are then [transpiled][transpiler] into Ignition configs and given to booting machines. Head over to the [docs to learn about the supported features][cl-configs].

You can provide a raw Ignition config to Flatcar Container Linux via VMware's [Guestinfo interface][guestinfo].

As an example, this Container Linux config will start etcd and configure private and public static IP addresses (the config needs to be transpiled to a raw Ignition config):

```yaml
networkd:
  units:
    - name: 00-vmware.network
      contents: |
        [Match]
        Name=ens192
        [Network]
        DHCP=no
        DNS=1.1.1.1
        DNS=1.0.0.1
        [Address]
        Address=123.45.67.2/29
        [Address]
        Address=10.0.0.2/29
        [Route]
        Destination=0.0.0.0/0
        Gateway=123.45.67.1
        [Route]
        Destination=10.0.0.0/8
        Gateway=10.0.0.1
etcd:
  # All options get passed as command line flags to etcd.
  # Any information inside curly braces comes from the machine at boot time.

  # See the next section for dynamic data with {PRIVATE_IPV4} and {PUBLIC_IPV4}
  advertise_client_urls:       "http://10.0.0.2:2379"
  initial_advertise_peer_urls: "http://10.0.0.2:2380"
  # listen on both the official ports and the legacy ports
  # legacy ports can be omitted if your application doesn't depend on them
  listen_client_urls:          "http://0.0.0.0:2379"
  listen_peer_urls:            "http://10.0.0.2:2380"
  # generate a new token for each unique cluster from https://discovery.etcd.io/new?size=3
  # specify the initial size of your cluster with ?size=X
  discovery:                   "https://discovery.etcd.io/<token>"
```

For DHCP you don't need to specify any networkd units.

After transpilation, the resulting JSON content can be used in `guestinfo.ignition.config.data` after encoding it to base64 and setting `guestinfo.ignition.config.data.encoding` to `base64`.
If DHCP is used, the JSON file can also be uploaded to a web server and fetched by Ignition if the HTTP(s) URL is given in `guestinfo.ignition.config.url`.

With static IP addresses there is no network connectivity in the initramfs. Therefore, fetching remote resources in Ignition or with torcx is currently only supported with DHCP.

IP configuration specified via `guestinfo.interface.*` and `guestinfo.dns.*` variables is currently not supported with Ignition and will only work if you provide coreos-cloudinit data (cloud-config or a script) as userdata.

[cl-configs]: provisioning

### Templating with Container Linux Configs and setting up metadata

On many cloud providers Ignition will run the [`coreos-metadata.service`](/ignition/metadata/#metadataconf) (which runs `afterburn`) to set up [node metadata](/container-linux-config-transpiler/doc/dynamic-data/#referencing-dynamic-data). This is not the case with VMware because the network setup is defined by you and nothing generic that `afterburn` would know about.

If you want to use dynamic data such as `{PRIVATE_IPV4}` and `{PUBLIC_IPV4}` in your Container Linux Config, you have to use the `--platform=custom` argument to the config transpiler and define your own `coreos-metadata.service`.

In the following example we will use the [reserved variables](https://github.com/flatcar-linux/afterburn/blob/master/docs/container-linux-legacy.md) `COREOS_CUSTOM_PUBLIC_IPV4` and `COREOS_CUSTOM_PRIVATE_IPV4` known to the config transpiler so that Container Linux Configs which contain `{PUBLIC_IPV4}` in a systemd unit will use `${COREOS_CUSTOM_PUBLIC_IPV4}` instead by automatically sourcing it via `EnvironmentFile=/run/metadata/coreos`.

```yaml
systemd:
  units:
    - name: coreos-metadata.service
      contents: |
        [Unit]
        Description=VMware metadata agent
        After=nss-lookup.target
        After=network-online.target
        Wants=network-online.target
        [Service]
        Type=oneshot
        Environment=OUTPUT=/run/metadata/coreos
        ExecStart=/usr/bin/mkdir --parent /run/metadata
        ExecStart=/usr/bin/bash -c 'echo "COREOS_CUSTOM_PRIVATE_IPV4=$(ip addr show ens192 | grep "inet 10." | grep -Po "inet \K[\d.]+")\nCOREOS_CUSTOM_PUBLIC_IPV4=$(ip addr show ens192 | grep -v "inet 10." | grep -Po "inet \K[\d.]+")" > ${OUTPUT}'

etcd:
  # Now we can use dynamic data with {PRIVATE_IPV4} and {PUBLIC_IPV4}
  advertise_client_urls:       "http://{PUBLIC_IPV4}:2379"
```

This populates `/run/metadata/coreos` with variables for a public IP address on interface `ens192` (taking the one that is not starting with `10.…`) and a private IP address on the same interface (taking the one that is starting with `10.…`). You need to adjust this to your network setup. In case you use the `guestinfo.interface.*` variables you could use `/usr/share/oem/bin/vmware-rpctool 'info-get guestinfo.interface.0.ip.0.address'` instead of `ip addr show … | grep …`.

## Using coreos-cloudinit Cloud-Configs

Ignition is the preferred way of provisioning because it runs in the initramfs and only at first boot.
Cloud-Configs are supported, too, but coreos-cloudinit is not actively developed at the moment.

Both Cloud-Config YAML content and raw bash scripts are supported by coreos-cloudinit. You can provide them to Flatcar Container Linux via VMware's [Guestinfo interface][guestinfo].

For `$public_ipv4` and `$private_ipv4` substitutions to work you either need to use static IPs (through `guestinfo.interface.*` as described below) or you need to write the variables `COREOS_PUBLIC_IPV4` and `COREOS_PRIVATE_IPV4` to `/etc/environment` before coreos-cloudinit runs which would require a reboot. Thus, it may be easier to use the `coreos-metadata.service` approach and write these variables to `/run/metadata/coreos`. To do so, set `EnvironmentFile=/run/metadata/coreos`, `Requires=coreos-metadata.service`, and `After=coreos-metadata.service` in your systemd unit.

Besides applying the config itself `coreos-cloudinit` supports the `guestinfo.interface.*` variables and will generate a networkd unit from them stored in `/run/systemd/network/`.

The guestinfo variables known to coreos-cloudinit are (taken from [here](https://github.com/flatcar-linux/coreos-cloudinit/blob/flatcar-master/Documentation/vmware-guestinfo.md#cloud-config-vmware-guestinfo-variables)), with `<n>`, `<m>`, `<l>` being numbers starting from 0:

* `guestinfo.hostname` used for `hostnamectl set-hostname`
* `guestinfo.interface.<n>.name` used in the `[Match]` section of the networkd unit (can include wildcards)
* `guestinfo.interface.<n>.mac` used in the `[Match]` section of the networkd unit
* `guestinfo.interface.<n>.dhcp` is either `yes` or `no` and used in the `[Network]` section of the networkd unit
* `guestinfo.interface.<n>.role` (required to generate a networkd unit for `<n>`) is either `public` or `private` and used for Cloud-Config variable substitions (`$public_ipv4` etc) instead of `COREOS_PUBLIC_IPV4` from `/etc/environment`
* `guestinfo.interface.<n>.ip.<m>.address` is a static IP address with subnet, e.g., `123.4.5.6/29`, used in the `[Address]` section of the networkd unit
* `guestinfo.interface.<n>.route.<l>.gateway` used in the `[Route]` section of the networkd unit
* `guestinfo.interface.<n>.route.<l>.destination` is a IP CIDR, e.g., `0.0.0.0/0`, used in the `[Route]` section of the networkd unit
* `guestinfo.dns.server.<x>` used in the `[Network]` section of any networkd unit
* `guestinfo.dns.domain.<y>` used in the `[Network]` section of any networkd unit
* `guestinfo.(ignition|coreos).config.data`, `guestinfo.(ignition|coreos).config.data.encoding`, and `guestinfo.(ignition|coreos).config.url` as described in the surrounding sections

If you rely on `$public_ipv4` and `$private_ipv4` substitutions through `guestinfo.interface.<n>.role` but have both IP addresses in one interface you may either use variables in `/run/metadata/coreos` as written in the previous section or you could provide the second IP address again on a dummy interface with a name that never matches a real interface, just to propagate the IP address to the coreos-cloudinit metadata.

## VMware Guestinfo interface

### Setting Guestinfo options

The VMware guestinfo interface is a mechanism for VM configuration. Guestinfo properties are stored in the VMX file, or in the VMX representation in host memory. These properties are available to the VM at boot time. Within the VMX, the names of these properties are prefixed with `guestinfo.`. Guestinfo settings can be injected into VMs in one of four ways:

* Configure guestinfo in the OVF for deployment. Software like [vcloud director][vcloud director] manipulates OVF descriptors for guest configuration. For details, check out this VMware blog post about [Self-Configuration and the OVF Environment][ovf-selfconfig].

* The ESXi web UI and VMware Workstation Player either directly display the OVF guestinfo variables for editing or allow to add them as parameters in the VM settings before deployment. They can also be changed and added later in the VM settings (but for Ignition configs that requires `touch /boot/flatcar/first_boot` so that Ignition runs again on the next boot).

* The [`ovftool`][ovftool] supports guestinfo variables with `--X:guest:VARIABLE=value`.

* Set guestinfo keys and values from the Flatcar Container Linux guest itself, by using a VMware Tools command like:

```shell
/usr/share/oem/bin/vmtoolsd --cmd "info-set guestinfo.<variable> <value>"
```

* Guestinfo keys and values can be set from a VMware Service Console, using the `setguestinfo` subcommand:

```shell
vmware-cmd /vmfs/volumes/[...]/<VMNAME>/<VMNAME>.vmx setguestinfo guestinfo.<property> <value>
```

* You can manually modify the VMX and reload it on the VMware Workstation, ESXi host, or in vCenter.

Guestinfo configuration set via the VMware API or with `vmtoolsd` from within the Flatcar Container Linux guest itself are stored in VM process memory and are lost on VM shutdown or reboot.

### Defining the Ignition config or coreos-cloudinit Cloud-Config in Guestinfo

If either the `guestinfo.ignition.config.data` or the `guestinfo.ignition.config.url` userdata property contains an Ignition config, Ignition will apply the referenced config on first boot during the initramfs phase. If it contains a Cloud-Config or script, Ignition will enable a service for coreos-cloudinit that will run on every boot and apply the config.

The userdata is prepared for the guestinfo facility in one of two encoding types, specified in the `guestinfo.ignition.config.data.encoding` variable:

|    Encoding    |                        Command                        |
|:---------------|:------------------------------------------------------|
| &lt;elided&gt; | `sed -e 's/%/%%/g' -e 's/"/%22/g' /path/to/user_data` |
| base64         | `base64 -w0 /path/to/user_data`                       |
| gz+base64      | `gzip -c -9 /path/to/user_data | base64 -w0`          |

#### Example

```ini
guestinfo.ignition.config.data = "ewogICJpZ25pdGlvbiI6IHsgInZlcnNpb24iOiAiMi4wLjAiIH0KfQo="
guestinfo.ignition.config.data.encoding = "base64"
```

This example will be decoded into the following Ignition config, but a Cloud-Config can be specified the same way in the variable:

```json
{
  "ignition": { "version": "2.0.0" }
}
```

Instead of providing the userdata inline, you can also specify a remote HTTP location in `guestinfo.ignition.config.url`.
Both Ignition and coreos-cloudinit support it but Ignition relies on DHCP in the initramfs which means that it can't fetch remote resources if you have to use static IPs.

## Logging in

The VGA console will have autologin enabled for releases after 2020/04/28.

Networking can take some time to start under VMware. Once it does, you will see the IP when typing `ip a` or in the VM info that VMware displays.

You can login to the host at that IP using your SSH key, or the password set in your cloud-config:

```shell
ssh core@YOURIP
```

## Using Flatcar Container Linux

Now that you have a machine booted, it's time to explore. Check out the [Flatcar Container Linux Quickstart][quickstart] guide, or dig into [more specific topics][docs].

[quickstart]: quickstart
[docs]: https://docs.flatcar-linux.org
[PXE]: booting-with-pxe
[ISO]: booting-with-iso
[install]: installing-to-disk
[vcloud director]: http://blogs.vmware.com/vsphere/2012/06/leveraging-vapp-vm-custom-properties-in-vcloud-director.html
[ovf-selfconfig]: http://blogs.vmware.com/vapp/2009/07/selfconfiguration-and-the-ovf-environment.html
[guestinfo]: #defining-the-ignition-config-or-coreos-cloudinit-cloud-config-in-guestinfo
[transpiler]: /os/provisioning/#config-transpiler
[ovftool]: https://www.vmware.com/support/developer/ovf/
