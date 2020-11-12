---
title: Running Flatcar Container Linux on Packet
linktitle: Running on Packet
weight: 10
---

Packet is a bare metal cloud hosting provider. Flatcar Container Linux is installable as one of the default operating system options. You can deploy Flatcar Container Linux servers via the Packet portal or API.

## Deployment instructions

The first step in deploying any devices on Packet is to first create an account and decide if you'd like to deploy via our portal or API. The portal is appropriate for small clusters of machines that won't change frequently. If you'll be deploying a lot of machines, or expect your workload to change frequently it is much more efficient to use the API. You can generate an API token through the portal once you've set up an account and payment method.

### Projects

Packet has a concept of 'projects' that represent a grouping of machines that defines several other aspects of the service. A project defines who on the team has access to manage the machines in your account. Projects also define your private network; all machines in a given project will automatically share backend network connectivity. The SSH keys of all team members associated with a project will be installed to all newly provisioned machines in a project. All servers need to be in a project, even if there is only one server in that project.

### Portal instructions

Once logged into the portal you will be able to click the 'New server' button and choose Flatcar Container Linux from the menu of operating systems, and choose which region you want the server to be deployed in. If you choose to enter a custom Ignition config, you can enable 'Add User Data' and paste it there. The SSH key that you associate with your account and any other team member's keys that are on the project will be added to your Flatcar Container Linux machine once it is provisioned.

### API instructions

If you select to use the API to provision machines on Packet you should consider using [one of the language libraries](https://www.packet.com/developers/libraries/) to code against. As an example, this is how you would launch a single Type 1 machine in a curl command. [Packet API Documentation](https://www.packet.com/developers/api/).

```shell
# Replace items in brackets (<EXAMPLE>) with the appropriate values.

curl -X POST \
-H 'Content-Type: application/json' \
-H 'Accept: application/json' \
-H 'X-Auth-Token: <API_TOKEN>' \
-d '{"hostname": "<HOSTNAME>", "plan": "baremetal_1", "facility": "ewr1", "operating_system": "flatcar_alpha", "userdata": "<USERDATA>"}' \
https://api.packet.net/projects/<PROJECT_ID>/devices
```

Double quotes in the `<USERDATA>` value must be escaped such that the request body is valid JSON. See the Container Linux Config section below for more information about accepted forms of userdata.

## iPXE booting

If you need to run a Flatcar Container Linux image which is not available through the OS option in the API, you can boot via 'Custom iPXE'.
This is the case for ARM64 images which are just published in the Alpha and Edge channels right now and not available via Packet's API.

Assuming you want to run boot an Alpha image via iPXE on a `c2.large.arm` machine, you have to provide this URL for 'Custom iPXE Settings':

```text
https://alpha.release.flatcar-linux.net/arm64-usr/current/flatcar_production_packet.ipxe
```

Do not forget to provide an Ignition config with your SSH key because the PXE images don't have any OEM packages which could fetch the Packet project's SSH keys after booting.

If not configured elsewise, iPXE booting will only done at the first boot because you are expected to install the operating system to the hard disk yourself.

## Container Linux Configs

Flatcar Container Linux allows you to configure machine parameters, configure networking, launch systemd units on startup, and more via Container Linux Configs. These configs are then transpiled into Ignition configs and given to booting machines. Head over to the [docs to learn about the supported features][cl-configs]. Note that Packet doesn't allow an instance's userdata to be modified after the instance has been launched. This isn't a problem since Ignition only runs on the first boot.

You can provide a raw Ignition config to Flatcar Container Linux via Packet's userdata field.

As an example, this config will configure and start etcd:

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

[cl-configs]: provisioning

## Using Flatcar Container Linux

Now that you have a machine booted it is time to play around. Check out the [Flatcar Container Linux Quickstart](quickstart) guide or dig into [more specific topics](https://docs.flatcar-linux.org).
