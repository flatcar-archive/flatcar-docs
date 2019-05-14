# Worker Pools

Typhoon AWS, Azure, and Google Cloud allow additional groups of workers to be defined and joined to a cluster. For example, add worker pools of instances with different types, disk sizes, Container Linux channels, or preemptibility modes.

Internal Terraform Modules:

* `aws/container-linux/kubernetes/workers`
* `packet/flatcar-linux/kubernetes/workers`

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

## Packet

The controller module for Packet does not provision any worker nodes. To add worker nodes, the worker module must be used. The [Packet tutorial](/lokomotive/platforms/packet.md) describes this in detail.
