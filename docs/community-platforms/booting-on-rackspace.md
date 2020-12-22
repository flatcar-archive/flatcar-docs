---
title: Running Flatcar Container Linux on Rackspace
linktitle: Running on Rackspace
weight: 10
aliases:
    - ../os/booting-on-rackspace
---

These instructions will walk you through running Flatcar Container Linux on the Rackspace OpenStack cloud, which differs slightly from the generic OpenStack instructions. There are two ways to launch a Flatcar Container Linux cluster: launch an entire cluster with Heat or launch machines with Nova.

## Choosing a channel

Flatcar Container Linux is designed to be updated automatically with different schedules per channel. You can [disable this feature](update-strategies), although we don't recommend it. Read the [release notes](https://flatcar-linux.org/releases) for specific features and bug fixes.

<div id="rax-images">
  <ul class="nav nav-tabs">
    <li class="active"><a href="#stable" data-toggle="tab">Stable Channel</a></li>
    <li><a href="#beta" data-toggle="tab">Beta Channel</a></li>
    <li><a href="#alpha" data-toggle="tab">Alpha Channel</a></li>
  </ul>
  <div class="tab-content coreos-docs-image-table">
    <div class="tab-pane" id="alpha">
      <div class="channel-info">
        <p>The Alpha channel closely tracks master and is released frequently. The newest versions of system libraries and utilities will be available for testing. The current version is Flatcar Container Linux {{< param alpha_channel >}}.</p>
        <p>The following command can be used to determine the image IDs for Alpha:</p>
        <pre>supernova production image-list | grep 'Flatcar Container Linux (Alpha)'</pre>
      </div>
    </div>
    <div class="tab-pane" id="beta">
      <div class="channel-info">
        <p>The Beta channel consists of promoted Alpha releases. The current version is Flatcar Container Linux {{< param beta_channel >}}.</p>
        <p>The following command can be used to determine the image IDs for Beta:</p>
        <pre>supernova production image-list | grep 'Flatcar Container Linux (Beta)'</pre>
      </div>
    </div>
    <div class="tab-pane active" id="stable">
      <div class="channel-info">
        <p>The Stable channel should be used by production clusters. Versions of Flatcar Container Linux are battle-tested within the Beta and Alpha channels before being promoted. The current version is Flatcar Container Linux {{< param stable_channel >}}.</p>
        <p>The following command can be used to determine the image IDs for Stable:</p>
        <pre>supernova production image-list | grep 'Flatcar Container Linux (Stable)'</pre>
      </div>
    </div>
  </div>
</div>

## Cloud-config

Flatcar Container Linux allows you to configure machine parameters, launch systemd units on startup and more via cloud-config. Jump over to the [docs to learn about the supported features][cloud-config-docs]. Cloud-config is intended to bring up a cluster of machines into a minimal useful state and ideally shouldn't be used to configure anything that isn't standard across many hosts. Once a machine is created on Rackspace, the cloud-config can't be modified.

You can provide cloud-config data via both Heat and Nova APIs. You **cannot** provide cloud-config via the Control Panel. If you launch machines via the UI, you will have to do all configuration manually.

The most common Rackspace cloud-config looks like:

```yaml
#cloud-config

flatcar:
  etcd2:
    # generate a new token for each unique cluster from https://discovery.etcd.io/new?size=3
    # specify the initial size of your cluster with ?size=X
    discovery: https://discovery.etcd.io/<token>
    # multi-region and multi-cloud deployments need to use $public_ipv4
    advertise-client-urls: http://$private_ipv4:2379,http://$private_ipv4:4001
    initial-advertise-peer-urls: http://$private_ipv4:2380
    # listen on both the official ports and the legacy ports
    # legacy ports can be omitted if your application doesn't depend on them
    listen-client-urls: http://0.0.0.0:2379,http://0.0.0.0:4001
    listen-peer-urls: http://$private_ipv4:2380
  units:
    - name: etcd2.service
      command: start
    - name: fleet.service
      command: start
```

The `$private_ipv4` and `$public_ipv4` substitution variables are fully supported in cloud-config on Rackspace.

[cloud-config-docs]: https://github.com/flatcar-linux/coreos-cloudinit/blob/master/Documentation/cloud-config.md

### Mount data disk

Certain server flavors have separate system and data disks. To utilize the data disks, they must be mounted with a `.mount` unit. Check to make sure the `Where=` parameter accurately reflects the location of the block device:

```yaml
#cloud-config
flatcar:
  units:
    - name: media-data.mount
      command: start
      content: |
        [Mount]
        What=/dev/xvde
        Where=/media/data
        Type=ext3
```

Mounting Cloud Block Storage can be done with a mount unit, but should not be included in cloud-config unless the disk is present on the first boot.

For more general information, check out [mounting storage on Flatcar Container Linux](mounting-storage).

## Launch with Nova

We're going to install `rackspace-novaclient`, upload a keypair and boot the image id from above.

### Install Supernova tool

The Supernova tool requires Python and `pip`, a Python package manager. If you don't have `pip` installed, install it by running `sudo easy_install pip`. Now let's use `pip` to install Supernova, a tool that lets you easily switch Rackspace regions. Be sure to install these in the order listed:

```shell
sudo pip install keyring
sudo pip install rackspace-novaclient
sudo pip install supernova
```

### Store account information

Edit your config file (`~/.supernova`) to store your Rackspace username, API key (referenced as `OS_PASSWORD`) and some other settings. The `OS_TENANT_NAME` should be set to your Rackspace account ID, which can be found by clicking on your Rackspace username in the upper right-hand corner of the cloud control panel UI.

```ini
[production]
OS_AUTH_URL = https://identity.api.rackspacecloud.com/v2.0/
OS_USERNAME = username
OS_PASSWORD = fd62afe2-4686-469f-9849-ceaa792c55a6
OS_TENANT_NAME = 123456
OS_REGION_NAME = DFW
OS_AUTH_SYSTEM = rackspace
```

We're ready to create a keypair then boot a server with it.

### Create keypair

For this guide, I'm assuming you already have a public key you use for your Flatcar Container Linux servers. Note that only RSA keypairs are supported. Load the public key to Rackspace:

```shell
supernova production keypair-add --pub-key ~/.ssh/flatcar.pub flatcar-key
```

Check you make sure the key is in your list by running `supernova production keypair-list`

```sell
+------------+--------------------------------------------------+
| Name       | Fingerprint                                      |
+------------+--------------------------------------------------+
| flatcar-key | d0:6b:d8:3a:3e:6a:52:43:32:bc:01:ea:c2:0f:49:59 |
+------------+--------------------------------------------------+
```

### Boot a server

<div id="rax-create">
  <ul class="nav nav-tabs">
    <li class="active"><a href="#stable-create" data-toggle="tab">Stable Channel</a></li>
    <li><a href="#beta-create" data-toggle="tab">Beta Channel</a></li>
    <li><a href="#alpha-create" data-toggle="tab">Alpha Channel</a></li>
  </ul>
  <div class="tab-content coreos-docs-image-table">
    <div class="tab-pane" id="alpha-create">
      <p>Boot a new Cloud Server with our new keypair and specify optional cloud-config data:</p>
      <pre>supernova production boot --image &lt;image-id&gt; --flavor performance1-2 --key-name flatcar-key --user-data ~/cloud_config.yml --config-drive true My_Flatcar_Server</pre>
      <p>Boot a new OnMetal Server with our new keypair and specify optional cloud-config data:</p>
      <pre>supernova production boot --image &lt;image-id&gt; --flavor onmetal-compute1 --key-name flatcar-key --user-data ~/cloud_config.yml --config-drive true My_Flatcar_Server</pre>
    </div>
    <div class="tab-pane" id="beta-create">
      <p>Boot a new Cloud Server with our new keypair and specify optional cloud-config data:</p>
      <pre>supernova production boot --image &lt;image-id&gt; --flavor performance1-2 --key-name flatcar-key --user-data ~/cloud_config.yml --config-drive true My_Flatcar_Server</pre>
    </div>
    <div class="tab-pane active" id="stable-create">
      <p>Boot a new Cloud Server with our new keypair and specify optional cloud-config data:</p>
      <pre>supernova production boot --image &lt;image-id&gt; --flavor performance1-2 --key-name flatcar-key --user-data ~/cloud_config.yml --config-drive true My_Flatcar_Server</pre>
    </div>
  </div>
</div>

You should now see the details of your new server in your terminal and it should also show up in the control panel:

```shell
+------------------------+--------------------------------------+
| Property               | Value                                |
+------------------------+--------------------------------------+
| status                 | BUILD                                |
| updated                | 2013-11-02T19:43:45Z                 |
| hostId                 |                                      |
| key_name               | flatcar-key                          |
| image                  | Flatcar Container Linux              |
| OS-EXT-STS:task_state  | scheduling                           |
| OS-EXT-STS:vm_state    | building                             |
| flavor                 | 512MB Standard Instance              |
| id                     | 82dbe66d-0762-4cba-a286-8c1af8431e47 |
| user_id                | 3c55bca772ba4a4bb6a4eb5b25754738     |
| name                   | My_Flatcar_Server                    |
| adminPass              | mgNqEx7I9pQA                         |
| tenant_id              | 833111                               |
| created                | 2013-11-02T19:43:44Z                 |
| OS-DCF:diskConfig      | MANUAL                               |
| accessIPv4             |                                      |
| accessIPv6             |                                      |
| progress               | 0                                    |
| OS-EXT-STS:power_state | 0                                    |
| metadata               | {}                                   |
+------------------------+--------------------------------------+
```

### Launching more servers

To launch more servers and have them join your cluster, simply provide the same cloud-config.

## Launch via control panel

You can also launch servers with either the `alpha` and `beta` channel versions via the web-based Control Panel, although you can't provide cloud-config via the UI. To do so:

 1. Log into your Rackspace Control Panel
 2. Click on 'Servers'
 3. Click on 'Create Server'
 4. Choose server name and region
 5. Click on 'Linux', then on 'Flatcar Container Linux' and finally choose '(alpha)' or '(beta)' version
 6. Choose flavor and use 'Advanced Options' to select SSH Key -- if available
 7. Click on 'Create Server'

## Using Flatcar Container Linux

Now that you have a machine booted it is time to play around. Check out the [Flatcar Container Linux Quickstart](quickstart) guide or dig into [more specific topics](https://docs.flatcar-linux.org).
