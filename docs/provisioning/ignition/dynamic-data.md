---
title: Referencing dynamic data
weight: 40
aliases:
    - ./metadata
    - ../../ignition/metadata
---

## Overview

Sometimes it can be useful to refer to data in an Ignition config that isn't known until a machine boots, like its network address. This can be accomplished with [afterburn][afterburn] (previously called `coreos-metadata`). Afterburn is a very basic utility that fetches information about the current machine and makes it available for consumption. By making it a dependency of services which requires this information, systemd will ensure that coreos-metadata has successfully completed before starting these services. These services can then simply source the fetched information and let systemd perform the environment variable expansions.

While the `coreos-metadata.service` runs afterburn, it will not set the hostname. The hostname is set either through an OEM agent or for particular platforms through afterburn in the initramfs. If afterburn supports your platform and is not invoked in the initramfs by default, you can run it later to set the hostname (`--hostname=/etc/hostname`).

## Supported data by provider

The information available for each provider can be found in the [afterburn docs][afterburndocs] - the variable names however differ in the used prefix: In Flatcar Container Linux (since CoreOS Container Linux), they are called `COREOS_*` instead of `AFTERBURN_*`. Also, `*_AWS_*` is `*_EC2_*` and `*_GCP_*` is `*_GCE_*`.
These variables are written to `/run/metadata/flatcar` as environment file from where you can either source them or set them up as environment for a systemd unit (note that your service should be started `After=coreos-metadata.service`).

## Custom metadata providers

To use the `custom` platform, create a coreos-metadata service unit to execute your own custom metadata fetcher. The custom metadata fetcher must write an environment file `/run/metadata/flatcar` defining a `COREOS_CUSTOM_*` environment variable for every piece of dynamic data you want to use.

### Example

Assume `https://example.com/metadata-script.sh` is a script which communicates with a metadata service and then writes the following file to `/run/metadata/flatcar`:

```
COREOS_CUSTOM_HOSTNAME=foobar
COREOS_CUSTOM_PRIVATE_IPV4=<The instance's private ipv4 address>
COREOS_CUSTOM_PUBLIC_IPV4=<The instance's public ipv4 address>
```

The following Butane config downloads the metadata fetching script, sets up a `coreos-metadata` service to use the script, and configures a test service using the metadata provided.

```yaml
variant: flatcar
version: 1.0.0
storage:
  files:
    - path: "/opt/get-metadata.sh"
      contents:
        source: "https://example.com/metadata-script.sh"

systemd:
  units:
    - name: "coreos-metadata.service"
      contents: |
        [Unit]
        Description=Metadata agent
        After=nss-lookup.target
        After=network-online.target
        Wants=network-online.target
        [Service]
        Type=oneshot
        Restart=on-failure
        RemainAfterExit=yes
        ExecStart=/opt/get-metadata.sh
    - name: "test.service"
      enabled: true
      contents: |
        [Unit]
        After=coreos-metadata.service
        Requires=coreos-metadata.service
        [Service]
        EnvironmentFile=/run/metadata/flatcar
        Type=oneshot
        RemainAfterExit=yes
        Restart=on-failure
        # Print the custom hostname variable from /run/metadata/flatcar
        ExecStart=echo "${COREOS_CUSTOM_HOSTNAME}"
        # Directly use /run/metadata/flatcar to print the private IP address out (with multiple patterns to work with any provider not only custom)
        ExecStart=bash -C 'cat /run/metadata/flatcar | grep -v -E '(IPV6|GATEWAY)' | grep IP | grep -E '(PRIVATE|LOCAL|DYNAMIC)' | cut -d = -f 2'
        [Install]
        WantedBy=multi-user.target
```

You can find another example in the [VMware docs](../../installing/cloud/vmware.md).


[afterburndocs]: https://github.com/coreos/afterburn/blob/main/docs/usage/attributes.md#metadata-attributes
