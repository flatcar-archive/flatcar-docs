---
title: Hands on 3 - Deploying
linktitle: Hands on 3 - Deploying
weight: 2
---

The goal of this hands-on is to:
* deploy Flatcar instances with IaC (Terraform)
* manipulate Terraform code
* write Flatcar provisioning with Terraform
* deploy Flatcar on OpenStack with Terraform

This is a bundle of hands-on-1 and hands-on-2 but it's not a local deployment and _everything_ is as code.

# Step-by-step

```bash
git clone https://github.com/tormath1/flatcar-tutorial; cd flatcar-tutorial/hands-on-3
# go into the terraform directory
cd terraform
# update the config for creating index.html from previous hands-on
vim server-configs/server1.yaml
# init the terraform project locally
terraform init
# get the credentials and update the `terraform.tfvars` consequently
# generate the plan and inspect it
terraform plan
# apply the plan
terraform apply
# go on the horizon dashboard and connect with terraform credentials
# find your instance
```

One can assert that it works by accessing the console (click on the instance then "console")

_NOTE_: it's possible to SSH into the instance but at the moment, it takes a SSH jump through the openstack (devstack) instance.
```
ssh -J user@[DEVSTACK-IP] -i ./.ssh/provisioning_private_key.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null core@[SERVER-IP]
```

To destroy the instance:
```
# if you are happy, destroy everything
terraform destroy
```

# Resources

* https://github.com/flatcar/flatcar-terraform/ (NOTE: the terraform code used here is based on this repository)
* https://www.flatcar.org/docs/latest/installing/cloud/openstack/

# Demo

* Video with timestamp: https://youtu.be/woZlGiLsKp0?t=1395
* Asciinema: https://asciinema.org/a/591442


