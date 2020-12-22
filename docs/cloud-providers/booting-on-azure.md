---
title: Running Flatcar Container Linux on Microsoft Azure
linktitle: Running on Microsoft Azure
weight: 10
aliases:
    - ../os/booting-on-azure
---

## Creating resource group via Microsoft Azure CLI

Follow the [installation and configuration guides][azure-cli] for the Microsoft Azure CLI to set up your local installation.

Instances on Microsoft Azure must be created within a resource group. Create a new resource group with the following command:

```shell
az group create --name group-1 --location <location>
```

Now that you have a resource group, you can choose a channel of Flatcar Container Linux you would like to install.

## Using the official image from the Marketplace

Official Flatcar Container Linux images for all channels are available in the Marketplace.
Flatcar Container Linux is designed to be [updated automatically][update-docs] with different schedules per channel. Updating
can be [disabled][reboot-docs], although it is not recommended to do so. The [release notes][release-notes] contain
information about specific features and bug fixes.

The following command will create a single instance through the Azure CLI.

<div id="azure-images">
  <ul class="nav nav-tabs">
    <li class="active"><a href="#stable" data-toggle="tab">Stable Channel</a></li>
    <li><a href="#beta" data-toggle="tab">Beta Channel</a></li>
    <li><a href="#alpha" data-toggle="tab">Alpha Channel</a></li>
    <li><a href="#edge" data-toggle="tab">Edge Channel</a></li>
  </ul>
  <div class="tab-content coreos-docs-image-table">
    <div class="tab-pane active" id="stable">
      <div class="channel-info">
        <p>The Stable channel should be used by production clusters. Versions of Flatcar Container Linux are battle-tested within
        the Beta and Alpha channels before being promoted. The current version is Flatcar Container Linux {{< param stable_channel >}}.</p>
        <pre>
$ az vm image list --all -p kinvolk -f flatcar -s stable  # Query the image name urn specifier
[
  {
    "offer": "flatcar-container-linux",
    "publisher": "kinvolk",
    "sku": "stable",
    "urn": "kinvolk:flatcar-container-linux:stable:2345.3.0",
    "version": "2345.3.0"
  }
]
$ az vm create --name node-1 --resource-group group-1 --admin-username core --custom-data "$(cat config.ign)" --image kinvolk:flatcar-container-linux:stable:2345.3.0
        </pre>
      </div>
    </div>
    <div class="tab-pane" id="beta">
      <div class="channel-info">
        <p>The Beta channel consists of promoted Alpha releases. The current version is Flatcar Container Linux {{< param beta_channel >}}.</p>
        <pre>
$ az vm image list --all -p kinvolk -f flatcar -s beta  # Query the image name urn specifier
[
  {
    "offer": "flatcar-container-linux",
    "publisher": "kinvolk",
    "sku": "beta",
    "urn": "kinvolk:flatcar-container-linux:beta:2411.1.0",
    "version": "2411.1.0"
  }
]
$ az vm create --name node-1 --resource-group group-1 --admin-username core --custom-data "$(cat config.ign)" --image kinvolk:flatcar-container-linux:beta:2411.1.0
        </pre>
      </div>
    </div>
    <div class="tab-pane" id="alpha">
      <div class="channel-info">
        <p>The Alpha channel closely tracks the master branch and is released frequently. The newest versions of system
        libraries and utilities are available for testing in this channel. The current version is Flatcar Container Linux {{< param alpha_channel >}}.</p>
        <pre>
$ az vm image list --all -p kinvolk -f flatcar -s alpha
[
  {
    "offer": "flatcar-container-linux",
    "publisher": "kinvolk",
    "sku": "alpha",
    "urn": "kinvolk:flatcar-container-linux:alpha:2430.0.0",
    "version": "2430.0.0"
  }
]
$ az vm create --name node-1 --resource-group group-1 --admin-username core --custom-data "$(cat config.ign)" --image kinvolk:flatcar-container-linux:alpha:2430.0.0
        </pre>
      </div>
    </div>
    <div class="tab-pane" id="edge">
      <div class="channel-info">
        <p>The Edge channel includes bleeding-edge features with the newest versions of the Linux kernel, systemd
        and other core packages. Can be highly unstable. The current version is Flatcar Container Linux {{< param edge_channel >}}.</p>
        <pre>
$ az vm image list --all -p kinvolk -f flatcar -s edge
[
  {
    "offer": "flatcar-container-linux",
    "publisher": "kinvolk",
    "sku": "edge",
    "urn": "kinvolk:flatcar-container-linux:edge:2430.99.0",
    "version": "2430.99.0"
  }
]
$ az vm create --name node-1 --resource-group group-1 --admin-username core --custom-data "$(cat config.ign)" --image kinvolk:flatcar-container-linux:edge:2430.99.0
        </pre>
      </div>
    </div>
  </div>
</div>

## Uploading your own Image

To automatically download the Flatcar image for Azure from the release page and upload it to your Azure account, run the following command:

```shell
docker run -it --rm quay.io/kinvolk/azure-flatcar-image-upload \
  --resource-group <resource group> \
  --storage-account-name <storage account name>
```

Where:

- `<resource group>` should be a valid [Resource Group][resource-group] name.
- `<storage account name>` should be a valid [Storage Account][storage-account] name.

During execution, the script will ask you to log into your Azure account and then create all necessary resources for
uploading an image. It will then download the requested Flatcar Container Linux image and upload it to Azure.

If uploading fails with one of the following errors, it usually indicates a problem on Azure's side:

```text
Put https://mystorage.blob.core.windows.net/vhds?restype=container: dial tcp: lookup iago-dev.blob.core.windows.net on 80.58.61.250:53: no such host
```

```text
storage: service returned error: StatusCode=403, ErrorCode=AuthenticationFailed, ErrorMessage=Server failed to authenticate the request. Make sure the value of Authorization header is formed correctly including the signature. RequestId:a3ed1ebc-701e-010c-5258-0a2e84000000 Time:2019-05-14T13:26:00.1253383Z, RequestId=a3ed1ebc-701e-010c-5258-0a2e84000000, QueryParameterName=, QueryParameterValue=
```

The command is idempotent and it is therefore safe to re-run it in case of failure.

To see all available options, run:

```shell
docker run -it --rm quay.io/kinvolk/azure-flatcar-image-upload --help

Usage: /usr/local/bin/upload_images.sh [OPTION...]

 Required arguments:
  -g, --resource-group        Azure resource group.
  -s, --storage-account-name  Azure storage account name. Must be between 3 and 24 characters and unique within Azure.

 Optional arguments:
  -c, --channel              Flatcar Container Linux release channel. Defaults to 'stable'.
  -v, --version              Flatcar Container Linux version. Defaults to 'current'.
  -i, --image-name           Image name, which will be used later in Lokomotive configuration. Defaults to 'flatcar-<channel>'.
  -l, --location             Azure location to storage image. To list available locations run with '--locations'. Defaults to 'westeurope'.
  -S, --storage-account-type Type of storage account. Defaults to 'Standard_LRS'.
```

The Dockerfile for the `quay.io/kinvolk/azure-flatcar-image-upload` image is managed [here][azure-flatcar-image-upload].

## Container Linux Config

Flatcar Container Linux allows you to configure machine parameters, configure networking, launch systemd units on startup, and more
via a Container Linux Config. Head over to the [provisioning docs][cl-configs] to learn how to use Container Linux Configs.
Note that Microsoft Azure doesn't allow an instance's userdata to be modified after the instance had been launched. This
isn't a problem since Ignition, the tool that consumes the userdata, only runs on the first boot.

You can provide a raw Ignition config (produced from a Container Linux Config) to Flatcar Container Linux via the Azure CLI using the `----custom-data` flag.

As an example, the following config will configure and start etcd:

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

## Using Flatcar Container Linux

For information on using Flatcar Container Linux check out the [Flatcar Container Linux quickstart guide][quickstart] or dive into [more specific topics][docs].

[flatcar-user]: https://groups.google.com/forum/#!forum/flatcar-linux-user
[etcd-docs]: https://github.com/flatcar-linux/etcd/tree/master/Documentation
[quickstart]: quickstart
[reboot-docs]: update-strategies
[azure-cli]: https://docs.microsoft.com/en-us/cli/azure/overview
[cl-configs]: provisioning
[irc]: irc://irc.freenode.org:6667/#flatcar
[docs]: https://docs.flatcar-linux.org/
[resource-group]: https://docs.microsoft.com/en-us/azure/architecture/best-practices/naming-conventions#naming-rules-and-restrictions
[storage-account]: https://docs.microsoft.com/en-us/azure/storage/common/storage-account-overview#naming-storage-accounts
[azure-flatcar-image-upload]: https://github.com/kinvolk/flatcar-cloud-image-uploader/blob/master/azure-flatcar-image-upload
[release-notes]: https://flatcar-linux.org/releases
[update-docs]: https://docs.flatcar-linux.org/os/update-strategies
