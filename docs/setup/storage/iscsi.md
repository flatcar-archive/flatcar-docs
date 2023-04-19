---
title: Configuring iSCSI on Flatcar Container Linux
linktitle: Configuring iSCSI
description: How to configure the iSCSI daemon, either manually or automatically.
weight: 30
aliases:
    - ../../os/iscsi
    - ../../clusters/management/iscsi
---

[iSCSI][iscsi-wiki] is a protocol which provides block-level access to storage devices over IP.
This allows applications to treat remote storage devices as if they were local disks.
iSCSI handles taking requests from clients and carrying them out on the remote SCSI devices.

Flatcar Container Linux has integrated support for mounting devices.
This guide covers iSCSI configuration manually or automatically with [Butane Configs][butane-configs].

## Manual iSCSI configuration

### Set the Flatcar Container Linux iSCSI initiator name

iSCSI clients each have a unique initiator name.
Flatcar Container Linux generates a unique initiator name on each install and stores it in `/etc/iscsi/initiatorname.iscsi`.
This may be replaced if necessary.

### Configure the global iSCSI credentials

If all iSCSI mounts on a Flatcar Container Linux system use the same credentials, these may be configured locally by editing `/etc/iscsi/iscsid.conf` and setting the `node.session.auth.username` and `node.session.auth.password` fields.
If the iSCSI target is configured to support mutual authentication (allowing the initiator to verify that it is speaking to the correct client), these should be set in `node.session.auth.username_in` and `node.session.auth.password_in`.

### Start the iSCSI daemon

```shell
systemctl start iscsid
```

### Discover available iSCSI targets

To discover targets, run:

```shell
iscsiadm -m discovery -t sendtargets -p target_ip:target_port
```

### Provide target-specific credentials

For each unique `--targetname`, first enter the username:

```shell
iscsiadm -m node \
  --targetname=custom_target \
  --op update \
  --name=node.session.auth.username \
  --value=my_username
```

And then the password:

```shell
iscsiadm -m node \
  --targetname=custom_target \
  --op update \
  --name=node.session.auth.password \
  --value=my_secret_passphrase
```

### Log into an iSCSI target

The following command will log into all discovered targets.

```shell
iscsiadm -m node --login
```

Then, to log into a specific target use:

```shell
iscsiadm -m node --targetname=custom_target --login
```

### Enable automatic iSCSI login at boot

If you want to connect to iSCSI targets automatically at boot you first need to enable the systemd service:

```shell
systemctl enable iscsi
```

## Automatic iSCSI configuration

To configure and start iSCSI automatically after a machine is provisioned, credentials need to be written to disk and the iSCSI service started.

A Butane Config will be used to write the file `/etc/iscsi/iscsid.conf` to disk:

```ini
isns.address = host_ip
isns.port = host_port
node.session.auth.username = my_username
node.session.auth.password = my_secret_password
discovery.sendtargets.auth.username = my_username
discovery.sendtargets.auth.password = my_secret_password
```

### The Butane Config

```yaml
variant: flatcar
version: 1.0.0
systemd:
  units:
    - name: iscsi.service
      enabled: true
storage:
  files:
    - path: /etc/iscsi/iscsid.conf
      mode: 0644
      contents:
        inline: |
          isns.address = host_ip
          isns.port = host_port
          node.session.auth.username = my_username
          node.session.auth.password = my_secret_password
          discovery.sendtargets.auth.username = my_username
          discovery.sendtargets.auth.password = my_secret_password
```

## Mounting iSCSI targets

See the [mounting storage docs][mounting-storage] for an example.

[iscsi-wiki]: https://en.wikipedia.org/wiki/ISCSI
[mounting-storage]: mounting-storage
[butane-configs]: ../../provisioning/config-transpiler
