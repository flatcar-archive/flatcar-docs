---
title: Running Flatcar Container Linux on EC2
weight: 10
---

The current AMIs for all Flatcar Container Linux channels and EC2 regions are listed below and updated frequently. Using CloudFormation is the easiest way to launch a cluster, but it is also possible to follow the manual steps at the end of the article. Questions can be directed to the Flatcar Container Linux [IRC channel][irc] or [user mailing list][flatcar-user].

## Release retention time

After publishing, releases will remain available as public AMIs on AWS for 9 months. AMIs older than 9 months will be un-published in regular garbage collection sweeps. Please note that this will not impact existing AWS instances that use those releases. However, deploying new instances (e.g. in autoscaling groups pinned to a specific AMI) will not be possible after the AMI was un-published.

## Choosing a channel

Flatcar Container Linux is designed to be updated automatically with different schedules per channel. You can [disable this feature](../../clusters/creation/update-strategies), although we don't recommend it. Read the [release notes](https://flatcar-linux.org/releases) for specific features and bug fixes.

<div id="ec2-images">
  <ul class="nav nav-tabs">
    <li class="active"><a href="#stable" data-toggle="tab">Stable Channel</a></li>
    <li><a href="#beta" data-toggle="tab">Beta Channel</a></li>
    <li><a href="#alpha" data-toggle="tab">Alpha Channel</a></li>
    <li><a href="#edge" data-toggle="tab">Edge Channel</a></li>
  </ul>
  <div class="tab-content coreos-docs-image-table">
    <div class="tab-pane" id="alpha">
      <div class="channel-info">
        <p>The Alpha channel closely tracks master and is released frequently. The newest versions of system libraries and utilities will be available for testing. The current version is Flatcar Container Linux {{< param alpha-channel >}}.</p>
        View as json feed: {{< docs_amis_feed "alpha" >}}
      </div>
      {{< docs_amis_table "alpha" >}}
    </div>
    <div class="tab-pane" id="beta">
      <div class="channel-info">
        <p>The Beta channel consists of promoted Alpha releases. The current version is Flatcar Container Linux {{< param beta-channel >}}.</p>
        View as json feed: {{< docs_amis_feed "beta" >}}
      </div>
      {{< docs_amis_table "beta" >}}
    </div>
    <div class="tab-pane" id="edge">
      <div class="channel-info">
        <p>The Edge channel includes bleeding-edge features with the newest versions of the Linux kernel, systemd and other core packages. Can be highly unstable. The current version is Flatcar Container Linux {{< param edge-channel >}}.</p>
      </div>
      {{< docs_amis_table "edge" >}}
    </div>
    <div class="tab-pane active" id="stable">
      <div class="channel-info">
        <p>The Stable channel should be used by production clusters. Versions of Flatcar Container Linux are battle-tested within the Beta and Alpha channels before being promoted. The current version is Flatcar Container Linux {{< param stable-channel >}}.</p>
        View as json feed: {{< docs_amis_feed "stable" >}}
      </div>
      {{< docs_amis_table "stable" >}}
      <div class="channel-info">
      <h4>AWS China AMIs maintained by <a href="https://www.giantswarm.io/" target="_blank">Giant Swarm</a></h4>
      <p>The following AMIs are not part of the official Flatcar Container Linux release process and may lag behind (<a href="https://flatcar-prod-ami-import-cn-north-1.s3.cn-north-1.amazonaws.com.cn/version.txt" target="_blank">query version</a>).</p>
      View as json feed: <a href="https://flatcar-prod-ami-import-cn-north-1.s3.cn-north-1.amazonaws.com.cn/stable-amd64-usr.json"><span class="fa fa-rss"></span>amd64</a>
      </div>
      {{< docs_amis_table "stable_china" >}}
    </div>
  </div>
</div>

CloudFormation will launch a cluster of Flatcar Container Linux machines with a security and autoscaling group.

## Container Linux Configs

Flatcar Container Linux allows you to configure machine parameters, configure networking, launch systemd units on startup, and more via Container Linux Configs. These configs are then transpiled into Ignition configs and given to booting machines. Head over to the [docs to learn about the supported features][cl-configs].

You can provide a raw Ignition config to Flatcar Container Linux via the Amazon web console or [via the EC2 API][ec2-user-data].

As an example, this Container Linux Config will configure and start etcd:

```yaml
etcd:
  # All options get passed as command line flags to etcd.
  # Any information inside curly braces comes from the machine at boot time.

  # multi_region and multi_cloud deployments need to use {PUBLIC_IPV4}
  advertise_client_urls:       "http://{PRIVATE_IPV4}:2379"
  initial_advertise_peer_urls: "http://{PRIVATE_IPV4}:2380"
  # listen on both the official ports and the legacy ports
  # legacy ports can be omitted if your application doesn't depend on them
  listen_client_urls:          "http://0.0.0.0:2379"
  listen_peer_urls:            "http://{PRIVATE_IPV4}:2380"
  # generate a new token for each unique cluster from https://discovery.etcd.io/new?size=3
  # specify the initial size of your cluster with ?size=X
  discovery:                   "https://discovery.etcd.io/<token>"
```

[ec2-user-data]: http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html
[cl-configs]: ../../reference/migrating-to-clcs/provisioning

### Instance storage

Ephemeral disks and additional EBS volumes attached to instances can be mounted with a `.mount` unit. Amazon's block storage devices are attached differently [depending on the instance type](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/InstanceStorage.html#InstanceStoreDeviceNames). Here's the Container Linux Config to format and mount the first ephemeral disk, `xvdb`, on most instance types:

```yaml
storage:
  filesystems:
    - mount:
        device: /dev/xvdb
        format: ext4
        wipe_filesystem: true

systemd:
  units:
    - name: media-ephemeral.mount
      enable: true
      contents: |
        [Mount]
        What=/dev/xvdb
        Where=/media/ephemeral
        Type=ext4

        [Install]
        RequiredBy=local-fs.target
```

For more information about mounting storage, Amazon's [own documentation](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/InstanceStorage.html) is the best source. You can also read about [mounting storage on Flatcar Container Linux](../../clusters/scaling/mounting-storage).

### Adding more machines

To add more instances to the cluster, just launch more with the same Container Linux Config, the appropriate security group and the AMI for that region. New instances will join the cluster regardless of region if the security groups are configured correctly.

## SSH to your instances

Flatcar Container Linux is set up to be a little more secure than other cloud images. By default, it uses the `core` user instead of `root` and doesn't use a password for authentication. You'll need to add an SSH key(s) via the AWS console or add keys/passwords via your Container Linux Config in order to log in.

To connect to an instance after it's created, run:

```shell
ssh core@<ip address>
```

## Multiple clusters

If you would like to create multiple clusters you will need to change the "Stack Name". You can find the direct [template file on S3](https://flatcar-prod-ami-import-eu-central-1.s3.amazonaws.com/dist/aws/flatcar-stable-hvm.template).

## Manual setup

{% for region in site.data.alpha-channel.amis %}
  {% if region.name == 'us-east-1' %}
**TL;DR:** launch three instances of [{{region.hvm}}](https://console.aws.amazon.com/ec2/home?region={{region.name}}#launchAmi={{region.hvm}}) (amd64) in **{{region.name}}** with a security group that has open port 22, 2379, 2380, 4001, and 7001 and the same "User Data" of each host. SSH uses the `core` user and you have [etcd][etcd-docs] and [Docker][docker-docs] to play with.
  {% endif %}
{% endfor %}

### Creating the security group

You need open port 2379, 2380, 7001 and 4001 between servers in the `etcd` cluster. Step by step instructions below.

Note: _This step is only needed once_

First we need to create a security group to allow Flatcar Container Linux instances to communicate with one another.

1. Go to the [security group][sg] page in the EC2 console.
2. Click "Create Security Group"
    * Name: flatcar-testing
    * Description: Flatcar Container Linux instances
    * VPC: No VPC
    * Click: "Yes, Create"
3. In the details of the security group, click the `Inbound` tab
4. First, create a security group rule for SSH
    * Create a new rule: `SSH`
    * Source: 0.0.0.0/0
    * Click: "Add Rule"
5. Add two security group rules for etcd communication
    * Create a new rule: `Custom TCP rule`
    * Port range: 2379
    * Source: type "flatcar-testing" until your security group auto-completes. Should be something like "sg-8d4feabc"
    * Click: "Add Rule"
    * Repeat this process for port range 2380, 4001 and 7001 as well
6. Click "Apply Rule Changes"

[sg]: https://console.aws.amazon.com/ec2/home?region=us-east-1#s=SecurityGroups

### Launching a test cluster

<div id="ec2-manual">
  <ul class="nav nav-tabs">
    <li class="active"><a href="#stable-manual" data-toggle="tab">Stable Channel</a></li>
    <li><a href="#beta-manual" data-toggle="tab">Beta Channel</a></li>
    <li><a href="#alpha-manual" data-toggle="tab">Alpha Channel</a></li>
  </ul>
  <div class="tab-content coreos-docs-image-table">
    <div class="tab-pane" id="alpha-manual">
      <p>We will be launching three instances, with a few parameters in the User Data, and selecting our security group.</p>
      <ol>
        <li>
        {% for region in site.data.alpha_channel.amis %}
          {% if region.name == 'us-east-1' %}
            Open the <a href="https://console.aws.amazon.com/ec2/home?region={{region.name}}#launchAmi={{region.hvm}}" target="_blank">quick launch wizard</a> to boot {{region.hvm}} (amd64).
          {% endif %}
        {% endfor %}
        </li>
        <li>
          On the second page of the wizard, launch 3 servers to test our clustering
          <ul>
            <li>Number of instances: 3</li>
            <li>Click "Continue"</li>
          </ul>
        </li>
        <li>
          Next, we need to specify a discovery URL, which contains a unique token that allows us to find other hosts in our cluster. If you're launching your first machine, generate one at <a href="https://discovery.etcd.io/new?size=3">https://discovery.etcd.io/new?size=3</a>, configure the `?size=` to your initial cluster size and add it to the metadata. You should re-use this key for each machine in the cluster.
        </li>
        <li>
          Use <a href="../../reference/migrating-to-clcs/provisioning">ct</a> to convert the following configuration into an Ignition config, and back in the EC2 dashboard, paste it into the "User Data" field.
          ```yaml
          etcd:
            # All options get passed as command line flags to etcd.
            # Any information inside curly braces comes from the machine at boot time.

            # multi_region and multi_cloud deployments need to use {PUBLIC_IPV4}
            advertise_client_urls:       "http://{PRIVATE_IPV4}:2379"
            initial_advertise_peer_urls: "http://{PRIVATE_IPV4}:2380"
            # listen on both the official ports and the legacy ports
            # legacy ports can be omitted if your application doesn't depend on them
            listen_client_urls:          "http://0.0.0.0:2379"
            listen_peer_urls:            "http://{PRIVATE_IPV4}:2380"
            # generate a new token for each unique cluster from https://discovery.etcd.io/new?size=3
            # specify the initial size of your cluster with ?size=X
            discovery:                   "https://discovery.etcd.io/<token>"
          ```
          <ul>
            <li>Paste configuration into "User Data"</li>
            <li>"Continue"</li>
          </ul>
        </li>
        <li>
          Storage Configuration
          <ul>
            <li>"Continue"</li>
          </ul>
        </li>
        <li>
          Tags
          <ul>
            <li>"Continue"</li>
          </ul>
        </li>
        <li>
          Create Key Pair
          <ul>
            <li>Choose a key of your choice, it will be added in addition to the one in the gist.</li>
            <li>"Continue"</li>
          </ul>
        </li>
        <li>
          Choose one or more of your existing Security Groups
          <ul>
            <li>"flatcar-testing" as above.</li>
            <li>"Continue"</li>
          </ul>
        </li>
        <li>
          Launch!
        </li>
      </ol>
    </div>
    <div class="tab-pane" id="beta-manual">
      <p>We will be launching three instances, with a few parameters in the User Data, and selecting our security group.</p>
      <ol>
        <li>
        {% for region in site.data.beta_channel.amis %}
          {% if region.name == 'us-east-1' %}
            Open the <a href="https://console.aws.amazon.com/ec2/home?region={{region.name}}#launchAmi={{region.hvm}}" target="_blank">quick launch wizard</a> to boot {{region.hvm}} (amd64).
          {% endif %}
        {% endfor %}
        </li>
        <li>
          On the second page of the wizard, launch 3 servers to test our clustering
          <ul>
            <li>Number of instances: 3</li>
            <li>Click "Continue"</li>
          </ul>
        </li>
        <li>
          Next, we need to specify a discovery URL, which contains a unique token that allows us to find other hosts in our cluster. If you're launching your first machine, generate one at <a href="https://discovery.etcd.io/new?size=3">https://discovery.etcd.io/new?size=3</a>, configure the `?size=` to your initial cluster size and add it to the metadata. You should re-use this key for each machine in the cluster.
        </li>
        <li>
          Use <a href="provisioning">ct</a> to convert the following configuration into an Ignition config, and back in the EC2 dashboard, paste it into the "User Data" field.
          ```yaml
          etcd:
            # All options get passed as command line flags to etcd.
            # Any information inside curly braces comes from the machine at boot time.

            # multi_region and multi_cloud deployments need to use {PUBLIC_IPV4}
            advertise_client_urls:       "http://{PRIVATE_IPV4}:2379"
            initial_advertise_peer_urls: "http://{PRIVATE_IPV4}:2380"
            # listen on both the official ports and the legacy ports
            # legacy ports can be omitted if your application doesn't depend on them
            listen_client_urls:          "http://0.0.0.0:2379"
            listen_peer_urls:            "http://{PRIVATE_IPV4}:2380"
            # generate a new token for each unique cluster from https://discovery.etcd.io/new?size=3
            # specify the initial size of your cluster with ?size=X
            discovery:                   "https://discovery.etcd.io/<token>"
          ```
          <ul>
            <li>Paste configuration into "User Data"</li>
            <li>"Continue"</li>
          </ul>
        </li>
        <li>
          Storage Configuration
          <ul>
            <li>"Continue"</li>
          </ul>
        </li>
        <li>
          Tags
          <ul>
            <li>"Continue"</li>
          </ul>
        </li>
        <li>
          Create Key Pair
          <ul>
            <li>Choose a key of your choice, it will be added in addition to the one in the gist.</li>
            <li>"Continue"</li>
          </ul>
        </li>
        <li>
          Choose one or more of your existing Security Groups
          <ul>
            <li>"flatcar-testing" as above.</li>
            <li>"Continue"</li>
          </ul>
        </li>
        <li>
          Launch!
        </li>
      </ol>
    </div>
    <div class="tab-pane active" id="stable-manual">
      <p>We will be launching three instances, with a few parameters in the User Data, and selecting our security group.</p>
      <ol>
        <li>
        {% for region in site.data.stable_channel.amis %}
          {% if region.name == 'us-east-1' %}
            Open the <a href="https://console.aws.amazon.com/ec2/home?region={{region.name}}#launchAmi={{region.hvm}}" target="_blank">quick launch wizard</a> to boot {{region.hvm}} (amd64).
          {% endif %}
        {% endfor %}
        </li>
        <li>
          On the second page of the wizard, launch 3 servers to test our clustering
          <ul>
            <li>Number of instances: 3</li>
            <li>Click "Continue"</li>
          </ul>
        </li>
        <li>
          Next, we need to specify a discovery URL, which contains a unique token that allows us to find other hosts in our cluster. If you're launching your first machine, generate one at <a href="https://discovery.etcd.io/new?size=3">https://discovery.etcd.io/new?size=3</a>, configure the `?size=` to your initial cluster size and add it to the metadata. You should re-use this key for each machine in the cluster.
        </li>
        <li>
          Use <a href="https://docs.flatcar-linux.org/os/provisioning/#config-transpiler">ct</a> to convert the following configuration into an Ignition config, and back in the EC2 dashboard, paste it into the "User Data" field.
          ```yaml
          etcd:
            # All options get passed as command line flags to etcd.
            # Any information inside curly braces comes from the machine at boot time.

            # multi_region and multi_cloud deployments need to use {PUBLIC_IPV4}
            advertise_client_urls:       "http://{PRIVATE_IPV4}:2379"
            initial_advertise_peer_urls: "http://{PRIVATE_IPV4}:2380"
            # listen on both the official ports and the legacy ports
            # legacy ports can be omitted if your application doesn't depend on them
            listen_client_urls:          "http://0.0.0.0:2379"
            listen_peer_urls:            "http://{PRIVATE_IPV4}:2380"
            # generate a new token for each unique cluster from https://discovery.etcd.io/new?size=3
            # specify the initial size of your cluster with ?size=X
            discovery:                   "https://discovery.etcd.io/<token>"
          ```
          <ul>
            <li>Paste configuration into "User Data"</li>
            <li>"Continue"</li>
          </ul>
        </li>
        <li>
          Storage Configuration
          <ul>
            <li>"Continue"</li>
          </ul>
        </li>
        <li>
          Tags
          <ul>
            <li>"Continue"</li>
          </ul>
        </li>
        <li>
          Create Key Pair
          <ul>
            <li>Choose a key of your choice, it will be added in addition to the one in the gist.</li>
            <li>"Continue"</li>
          </ul>
        </li>
        <li>
          Choose one or more of your existing Security Groups
          <ul>
            <li>"flatcar-testing" as above.</li>
            <li>"Continue"</li>
          </ul>
        </li>
        <li>
          Launch!
        </li>
      </ol>
    </div>
  </div>
</div>

## Installation from a VMDK image

One of the possible ways of installation is to import the generated VMDK Flatcar image as a snapshot. The image file will be in `https://${CHANNEL}.release.flatcar-linux.net/${ARCH}-usr/${VERSION}/flatcar_production_ami_vmdk_image.vmdk.bz2`.
Make sure you download the signature (it's available in `https://${CHANNEL}.release.flatcar-linux.net/${ARCH}-usr/${VERSION}/flatcar_production_ami_vmdk_image.vmdk.bz2.sig`) and check it before proceeding.

```shell
$ wget https://alpha.release.flatcar-linux.net/amd64-usr/current/flatcar_production_ami_vmdk_image.vmdk.bz2
$ wget https://alpha.release.flatcar-linux.net/amd64-usr/current/flatcar_production_ami_vmdk_image.vmdk.bz2.sig
$ gpg --verify flatcar_production_ami_vmdk_image.vmdk.bz2.sig
gpg: assuming signed data in 'flatcar_production_ami_vmdk_image.vmdk.bz2'
gpg: Signature made Thu 15 Mar 2018 10:27:57 AM CET
gpg:                using RSA key A621F1DA96C93C639506832D603443A1D0FC498C
gpg: Good signature from "Flatcar Buildbot (Official Builds) <buildbot@flatcar-linux.org>" [ultimate]
```

Then, follow the instructions in [Importing a Disk as a Snapshot Using VM Import/Export](https://docs.aws.amazon.com/vm-import/latest/userguide/vmimport-import-snapshot.html). You'll need to upload the uncompressed vmdk file to S3.

After the snapshot is imported, you can go to "Snapshots" in the EC2 dashboard, and generate an AMI image from it.
To make it work, use `/dev/sda2` as the "Root device name" and you probably want to select "Hardware-assisted virtualization" as "Virtualization type".

## Using Flatcar Container Linux

Now that you have a machine booted it is time to play around. Check out the [Flatcar Container Linux Quickstart](../../quickstart) guide or dig into [more specific topics](https://docs.flatcar-linux.org).

[flatcar-user]: https://groups.google.com/forum/#!forum/flatcar-linux-user
[docker-docs]: https://docs.docker.io
[etcd-docs]: https://github.com/flatcar-linux/etcd/tree/master/Documentation
[irc]: irc://irc.freenode.org:6667/#flatcar
