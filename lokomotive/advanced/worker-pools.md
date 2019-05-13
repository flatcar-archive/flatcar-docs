# Worker Pools

Typhoon AWS, Azure, and Google Cloud allow additional groups of workers to be defined and joined to a cluster. For example, add worker pools of instances with different types, disk sizes, Container Linux channels, or preemptibility modes.

Internal Terraform Modules:

* `aws/container-linux/kubernetes/workers`
* `aws/fedora-atomic/kubernetes/workers`
* `azure/container-linux/kubernetes/workers`
* `google-cloud/container-linux/kubernetes/workers`
* `google-cloud/fedora-atomic/kubernetes/workers`

## AWS

Create a cluster following the AWS [tutorial](../cl/aws.md#cluster). Define a worker pool using the AWS internal `workers` module.

```tf
module "tempest-worker-pool" {
  source = "git::https://github.com/poseidon/typhoon//aws/container-linux/kubernetes/workers?ref=v1.14.1"
  
  providers = {
    aws = "aws.default"
  }

  # AWS
  vpc_id          = "${module.aws-tempest.vpc_id}"
  subnet_ids      = "${module.aws-tempest.subnet_ids}"
  security_groups = "${module.aws-tempest.worker_security_groups}"
  
  # configuration
  name               = "tempest-worker-pool"
  kubeconfig         = "${module.aws-tempest.kubeconfig}"
  ssh_authorized_key = "${var.ssh_authorized_key}"

  # optional
  count         = 2
  instance_type = "m5.large"
  os_image      = "coreos-beta"
}
```

Apply the change.

```
terraform apply
```

Verify an auto-scaling group of workers joins the cluster within a few minutes.

### Variables

The AWS internal `workers` module supports a number of [variables](https://github.com/poseidon/typhoon/blob/master/aws/container-linux/kubernetes/workers/variables.tf).

#### Required

| Name | Description | Example |
|:-----|:------------|:--------|
| name | Unique name (distinct from cluster name) | "tempest-m5s" |
| vpc_id | Must be set to `vpc_id` output by cluster | "${module.cluster.vpc_id}" |
| subnet_ids | Must be set to `subnet_ids` output by cluster | "${module.cluster.subnet_ids}" |
| security_groups | Must be set to `worker_security_groups` output by cluster | "${module.cluster.worker_security_groups}" |
| kubeconfig | Must be set to `kubeconfig` output by cluster | "${module.cluster.kubeconfig}" |
| ssh_authorized_key | SSH public key for user 'core' | "ssh-rsa AAAAB3NZ..." |

#### Optional

| Name | Description | Default | Example |
|:-----|:------------|:--------|:--------|
| count | Number of instances | 1 | 3 |
| instance_type | EC2 instance type | "t3.small" | "t3.medium" |
| os_image | AMI channel for a Container Linux derivative | coreos-stable | coreos-stable, coreos-beta, coreos-alpha, flatcar-stable, flatcar-beta, flatcar-alpha |
| disk_size | Size of the disk in GB | 40 | 100 |
| spot_price | Spot price in USD for workers. Leave as default empty string for regular on-demand instances | "" | "0.10" |
| service_cidr | Must match `service_cidr` of cluster | "10.3.0.0/16" | "10.3.0.0/24" |
| cluster_domain_suffix | Must match `cluster_domain_suffix` of cluster | "cluster.local" | "k8s.example.com" |

Check the list of valid [instance types](https://aws.amazon.com/ec2/instance-types/) or per-region and per-type [spot prices](https://aws.amazon.com/ec2/spot/pricing/).

## Azure

Create a cluster following the Azure [tutorial](../cl/azure.md#cluster). Define a worker pool using the Azure internal `workers` module.

```tf
module "ramius-worker-pool" {
  source = "git::https://github.com/poseidon/typhoon//azure/container-linux/kubernetes/workers?ref=v1.14.1"
  
  providers = {
    azurerm = "azurerm.default"
  }

  # Azure
  region                  = "${module.azure-ramius.region}"
  resource_group_name     = "${module.azure-ramius.resource_group_name}"
  subnet_id               = "${module.azure-ramius.subnet_id}"
  security_group_id       = "${module.azure-ramius.security_group_id}"
  backend_address_pool_id = "${module.azure-ramius.backend_address_pool_id}"

  # configuration
  name               = "ramius-low-priority"
  kubeconfig         = "${module.azure-ramius.kubeconfig}"
  ssh_authorized_key = "${var.ssh_authorized_key}"

  # optional
  count    = 2
  vm_type  = "Standard_F4"
  priority = "Low"
}
```

Apply the change.

```
terraform apply
```

Verify a scale set of workers joins the cluster within a few minutes.

### Variables

The Azure internal `workers` module supports a number of [variables](https://github.com/poseidon/typhoon/blob/master/azure/container-linux/kubernetes/workers/variables.tf).

#### Required

| Name | Description | Example |
|:-----|:------------|:--------|
| name | Unique name (distinct from cluster name) | "ramius-f4" |
| region | Must be set to `region` output by cluster | "${module.cluster.region}" |
| resource_group_name | Must be set to `resource_group_name` output by cluster | "${module.cluster.resource_group_name}" |
| subnet_id | Must be set to `subnet_id` output by cluster | "${module.cluster.subnet_id}" |
| security_group_id | Must be set to `security_group_id` output by cluster | "${module.cluster.security_group_id}" |
| backend_address_pool_id | Must be set to `backend_address_pool_id` output by cluster | "${module.cluster.backend_address_pool_id}" |
| kubeconfig | Must be set to `kubeconfig` output by cluster | "${module.cluster.kubeconfig}" |
| ssh_authorized_key | SSH public key for user 'core' | "ssh-rsa AAAAB3NZ..." |

#### Optional

| Name | Description | Default | Example |
|:-----|:------------|:--------|:--------|
| count | Number of instances | 1 | 3 |
| vm_type | Machine type for instances | "Standard_F1" | See below |
| os_image | Channel for a Container Linux derivative | coreos-stable | coreos-stable, coreos-beta, coreos-alpha |
| priority | Set priority to Low to use reduced cost surplus capacity, with the tradeoff that instances can be deallocated at any time | Regular | Low |
| clc_snippets | Container Linux Config snippets | [] | [example](/advanced/customization/#usage) |
| service_cidr | CIDR IPv4 range to assign to Kubernetes services | "10.3.0.0/16" | "10.3.0.0/24" |
| cluster_domain_suffix | FQDN suffix for Kubernetes services answered by coredns. | "cluster.local" | "k8s.example.com" |

Check the list of valid [machine types](https://azure.microsoft.com/en-us/pricing/details/virtual-machines/linux/) and their [specs](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/sizes-general). Use `az vm list-skus` to get the identifier.

## Google Cloud

Create a cluster following the Google Cloud [tutorial](../cl/google-cloud.md#cluster). Define a worker pool using the Google Cloud internal `workers` module.

```tf
module "yavin-worker-pool" {
  source = "git::https://github.com/poseidon/typhoon//google-cloud/container-linux/kubernetes/workers?ref=v1.14.1"

  providers = {
    google = "google.default"
  }

  # Google Cloud
  region       = "europe-west2"
  network      = "${module.google-cloud-yavin.network_name}"
  cluster_name = "yavin"

  # configuration
  name               = "yavin-16x"
  kubeconfig         = "${module.google-cloud-yavin.kubeconfig}"
  ssh_authorized_key = "${var.ssh_authorized_key}"
  
  # optional
  count        = 2
  machine_type = "n1-standard-16"
  os_image     = "coreos-beta"
  preemptible  = true
}
```

Apply the change.

```
terraform apply
```

Verify a managed instance group of workers joins the cluster within a few minutes.

```
$ kubectl get nodes
NAME                                             STATUS   AGE    VERSION
yavin-controller-0.c.example-com.internal        Ready    6m     v1.14.1
yavin-worker-jrbf.c.example-com.internal         Ready    5m     v1.14.1
yavin-worker-mzdm.c.example-com.internal         Ready    5m     v1.14.1
yavin-16x-worker-jrbf.c.example-com.internal     Ready    3m     v1.14.1
yavin-16x-worker-mzdm.c.example-com.internal     Ready    3m     v1.14.1
```

### Variables

The Google Cloud internal `workers` module supports a number of [variables](https://github.com/poseidon/typhoon/blob/master/google-cloud/container-linux/kubernetes/workers/variables.tf).

#### Required

| Name | Description | Example |
|:-----|:------------|:--------|
| name | Unique name (distinct from cluster name) | "yavin-16x" |
| region | Region for the worker pool instances. May differ from the cluster's region | "europe-west2" |
| network | Must be set to `network_name` output by cluster | "${module.cluster.network_name}" |
| cluster_name | Must be set to `cluster_name` of cluster | "yavin" |
| kubeconfig | Must be set to `kubeconfig` output by cluster | "${module.cluster.kubeconfig}" |
| ssh_authorized_key | SSH public key for user 'core' | "ssh-rsa AAAAB3NZ..." |

Check the list of regions [docs](https://cloud.google.com/compute/docs/regions-zones/regions-zones) or with `gcloud compute regions list`.

#### Optional

| Name | Description | Default | Example |
|:-----|:------------|:--------|:--------|
| count | Number of instances | 1 | 3 |
| machine_type | Compute instance machine type | "n1-standard-1" | See below |
| os_image | Container Linux image for compute instances | "coreos-stable" | "coreos-alpha", "coreos-beta" |
| disk_size | Size of the disk in GB | 40 | 100 |
| preemptible | If true, Compute Engine will terminate instances randomly within 24 hours | false | true |
| service_cidr | Must match `service_cidr` of cluster | "10.3.0.0/16" | "10.3.0.0/24" |
| cluster_domain_suffix | Must match `cluster_domain_suffix` of cluster | "cluster.local" | "k8s.example.com" |

Check the list of valid [machine types](https://cloud.google.com/compute/docs/machine-types).

