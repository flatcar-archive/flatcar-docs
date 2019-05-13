# Packet

In this tutorial, we'll create a Kubernetes v1.14.1 cluster on Packet.net with Flatcar Linux.

We'l declare a Kubernetes cluster using the Lokomotive Terraform module. Then apply the changes to create controller and worker instances along with TLS assets. We will use AWS's Route53 to create a DNS A record.

## Requirements

* AWS Account and IAM credentials
* AWS Route53 DNS Zone (registered Domain Name or delegated subdomains)
* Packet.net account
* Project ID from Packet.net account and API key (Note, that the term Auth token is also used to refer to the API key in the packet docs)
* Terraform v0.11.x and [terraform-provider-ct](https://github.com/poseidon/terraform-provider-ct) installed locally

## Terraform Setup

Install [Terraform](https://www.terraform.io/downloads.html) v0.11.x on your system.

```sh
$ terraform version
Terraform v0.11.12
```

Add the [terraform-provider-ct](https://github.com/poseidon/terraform-provider-ct) plugin binary for your system to `~/.terraform.d/plugins/`, noting the final name.

```sh
wget https://github.com/poseidon/terraform-provider-ct/releases/download/v0.3.1/terraform-provider-ct-v0.3.1-linux-amd64.tar.gz
tar xzf terraform-provider-ct-v0.3.1-linux-amd64.tar.gz
mv terraform-provider-ct-v0.3.1-linux-amd64/terraform-provider-ct ~/.terraform.d/plugins/terraform-provider-ct_v0.3.1
```

Read [concepts](/docs/architecture/concepts.md) to learn about Terraform, modules, and organizing resources. Change to your infrastructure repository (e.g. `infra`).

```
cd infra/clusters
```

## Provider

### AWS

Login to your AWS IAM dashboard and find your IAM user. Select "Security Credentials" and create an access key. Save the id and secret to a file that can be referenced in configs.

```
[default]
aws_access_key_id = xxx
aws_secret_access_key = yyy
```

Configure the AWS provider to use your access key credentials in a `providers.tf` file.

```
provider "aws" {
  version = "~> 2.8.0"
  alias   = "default"

  region                  = "eu-central-1"
  shared_credentials_file = "/home/user/.config/aws/credentials"
}

provider "ct" {
  version = "0.3.1"
}

provider "local" {
  version = "~> 1.0"
  alias   = "default"
}

provider "null" {
  version = "~> 1.0"
  alias   = "default"
}

provider "template" {
  version = "~> 1.0"
  alias   = "default"
}

provider "tls" {
  version = "~> 1.0"
  alias   = "default"
}

provider "packet" {
  version = "~> 1.2"
  alias   = "default"
}
```

### Packet

Login to you Packet.net account and obtain the project ID from the `Project Settings` tab. Obtain an API Key from the User settings menu. Note that project level API keys don't have all the necessary permissions for this exercise. The API key can be set in the `providers.tf` file for the `packet` provider as described in the docs [here](https://www.terraform.io/docs/providers/packet/index.html#example-usage). However this is not recommended to avoid accidentally committing API keys to version control. Instead set the env variable `PACKET_AUTH_TOKEN`.

## Cluster

Define a Kubernetes cluster using the module [packet/flatcar-linux/kubernetes](https://github.com/kinvolk/lokomotive-kubernetes/tree/master/packet/flatcar-linux/kubernetes).

```tf
module "controller" {
  source = "git::https://github.com/kinvolk/lokomotive-bkubernetes//packet/flatcar-linux/kubernetes?ref=v1.14.1"

  providers = {
    aws      = "aws.default"
    local    = "local.default"
    null     = "null.default"
    template = "template.default"
    tls      = "tls.default"
    packet   = "packet.default"
  }

  # Route53
  dns_zone    = "packet.example.com"
  dns_zone_id = "Z3PAABBCFAKEC0"

  # configuration
  ssh_keys = [
    "ssh-rsa AAAAB3Nz...",
    "ssh-rsa AAAAB3Nz...",
  ]

  asset_dir = "/home/user/.secrets/clusters/packet"

  # Packet
  cluster_name = "supernova"
  project_id   = "93fake81..."
  facility     = "ams1"

  # This must be the total of all worker pools
  worker_count              = 2
  worker_nodes_hostnames    = "${concat("${module.worker-pool-1.worker_nodes_hostname}", "${module.worker-pool-2.worker_nodes_hostname}")}"
  worker_nodes_public_ipv4s = "${concat("${module.worker-pool-backend.worker_nodes_public_ipv4}", "${module.worker-pool-storage.worker_nodes_public_ipv4}")}"

  # optional
  controller_count = 1
  controller_type  = "t1.small.x86"

  ipxe_script_url = "https://raw.githubusercontent.com/kinvolk/flatcar-ipxe-scripts/no-https/packet.ipxe"

  management_cidrs = [
    "0.0.0.0/0",       # Instances can be SSH-ed into from anywhere on the internet.
  ]

  # This is different for each project on Packet and depends on the packet facility/region. Check yours from the `IPs & Networks` tab from your Packet.net account. If an IP block is not allocated yet, try provisioning an instance from the console in that region. Packet will allocate a public IP CIDR.
  node_private_cidr = "10.128.156.0/25"
}

module "worker-pool-1" {
  source = "git::https://git@github.com/kinvolk/lokomotive-kubernetes//packet/flatcar-linux/kubernetes/workers?ref=v1.14.1"

  providers = {
    local    = "local.default"
    template = "template.default"
    tls      = "tls.default"
    packet   = "packet.default"
  }

  ssh_keys = [
    "ssh-rsa AAAAB3Nz...",
    "ssh-rsa AAAAB3Nz...",
  ]

  cluster_name = "supernova"
  project_id   = "93fake81..."
  facility     = "ams1"
  pool_name    = "one"

  count = 4
  type  = "c2.medium.x86"

  ipxe_script_url = "https://raw.githubusercontent.com/kinvolk/flatcar-ipxe-scripts/no-https/packet.ipxe"

  kubeconfig = "${module.controller.kubeconfig}"

  labels = "node.pubnative.io/role=backend,node-role.kubernetes.io/backend="
}
```
