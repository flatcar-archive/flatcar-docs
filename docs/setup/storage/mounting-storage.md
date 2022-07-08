---
title: Mounting storage
description: How to format and attach additional storage devices.
weight: 10
aliases:
    - ../../os/mounting-storage
    - ../../clusters/scaling/mounting-storage
---

Container Linux Configs can be used to format and attach additional filesystems to Flatcar Container Linux nodes, whether such storage is provided by an underlying cloud platform, physical disk, SAN, or NAS system. This is done by specifying how partitions should be mounted in the config, and then using a _systemd mount unit_ to mount the partition. By [systemd convention][systemd-mount-man], mount unit names derive from the target mount point, with interior slashes replaced by dashes, and the `.mount` extension appended. A unit mounting onto `/var/www` is thus named `var-www.mount`.

Mount units name the source filesystem and target mount point, and optionally the filesystem type. *Systemd* mounts filesystems defined in such units at boot time. The following example formats an [EC2 ephemeral disk][ec2-disk] and then mounts it at the node's `/media/ephemeral` directory. The mount unit is therefore named `media-ephemeral.mount`.

Note that you should not use the direct path `/dev/sdX`for the `What=` path but **use a distinct stable identifier** such as `/dev/disk/by-label/X` or `/dev/disk/by-partlabel/X` because, e.g., `/dev/sda` can become `/dev/sdb` after reboot as the Linux kernel assigns the devices in the order they appear which can be unstable. The best idea is to match the disk based on the content you expect, such as a filesystem or partition label that you set up through formatting the disk on first boot via Ignition's `mount:` directive. This way you can use `/dev/sdX` as the `mount: device:` path which is only used on the first boot and don't have to care whether it will get different names after reboot because your mount unit uses `/dev/disk/by-label/` to find the correct disk. If that is not possible you can try your luck with `/dev/disk/by-path/X` entries that depend on the way the disk are attached to the machine but not on the discovery order of the Linux kernel.

```yaml
storage:
  filesystems:
    - name: ephemeral1
      mount:
        device: /dev/xvdb
        format: ext4
        wipe_filesystem: true
        label: ephemeral1
systemd:
  units:
    - name: media-ephemeral.mount
      enable: true
      contents: |
        [Unit]
        Before=local-fs.target
        [Mount]
        What=/dev/disk/by-label/ephemeral1
        Where=/media/ephemeral
        Type=ext4
        [Install]
        WantedBy=local-fs.target
```

## Use attached storage for Docker

Docker containers can be very large and debugging a build process makes it easy to accumulate hundreds of containers. It's advantageous to use attached storage to expand your capacity for container images. Be aware that some cloud providers treat certain disks as ephemeral and you will lose all Docker images contained on that disk.

We're going to format a device as ext4 and then mount it to `/var/lib/docker`, where Docker stores images. Be sure to hardcode the correct device or look for a device by label:

```yaml
storage:
  filesystems:
    - name: ephemeral1
      mount:
        device: /dev/xvdb
        format: ext4
        wipe_filesystem: true
        label: ephemeral1
systemd:
  units:
    - name: var-lib-docker.mount
      enable: true
      contents: |
        [Unit]
        Description=Mount ephemeral to /var/lib/docker
        Before=local-fs.target
        [Mount]
        What=/dev/disk/by-label/ephemeral1
        Where=/var/lib/docker
        Type=ext4
        [Install]
        WantedBy=local-fs.target
    - name: docker.service
      dropins:
        - name: 10-wait-docker.conf
          contents: |
            [Unit]
            After=var-lib-docker.mount
            Requires=var-lib-docker.mount
```

## Creating and mounting a btrfs volume file

Flatcar Container Linux uses ext4 + overlayfs to provide a layered filesystem for the root partition. If you'd like to use btrfs for your Docker containers, you can do so with two systemd units: one that creates and formats a btrfs volume file and another that mounts it.

In this example, we are going to mount a new 25GB btrfs volume file to `/var/lib/docker`. One can verify that Docker is using the btrfs storage driver once the Docker service has started by executing `sudo docker info`. We recommend allocating **no more than 85%** of the available disk space for a btrfs filesystem as journald will also require space on the host filesystem.

```yaml
systemd:
  units:
    - name: format-var-lib-docker.service
      contents: |
        [Unit]
        Before=docker.service var-lib-docker.mount
        RequiresMountsFor=/var/lib
        ConditionPathExists=!/var/lib/docker.btrfs
        [Service]
        Type=oneshot
        ExecStart=/usr/bin/truncate --size=25G /var/lib/docker.btrfs
        ExecStart=/usr/sbin/mkfs.btrfs /var/lib/docker.btrfs
    - name: var-lib-docker.mount
      enable: true
      contents: |
        [Unit]
        Before=docker.service
        After=format-var-lib-docker.service
        Requires=format-var-lib-docker.service
        [Mount]
        What=/var/lib/docker.btrfs
        Where=/var/lib/docker
        Type=btrfs
        Options=loop,discard
        [Install]
        RequiredBy=docker.service
```

Note the declaration of `ConditionPathExists=!/var/lib/docker.btrfs`. Without this line, systemd would reformat the btrfs filesystem every time the machine starts.

## Mounting NFS exports

This Container Linux Config excerpt mounts an NFS export onto the Flatcar Container Linux node's `/var/www`.

```yaml
systemd:
  units:
    - name: var-www.mount
      enable: true
      contents: |
        [Unit]
        Before=remote-fs.target
        [Mount]
        What=nfs.example.com:/var/www
        Where=/var/www
        Type=nfs
        [Install]
        WantedBy=remote-fs.target
```

To declare that another service depends on this mount, name the mount unit in the dependent unit's `After` and `Requires` properties:

```yaml
[Unit]
After=var-www.mount
Requires=var-www.mount
```

If the mount fails, dependent units will not start.

## Further reading

Check the [`systemd mount` docs][systemd-mount-man] to learn about the available options. Examples specific to [EC2][ec2-disk], [Google Compute Engine][gcp-disk] can be used as a starting point.

[ec2-disk]: ../../installing/cloud/aws-ec2#instance-storage
[gcp-disk]: ../../installing/cloud/gcp#additional-storage
[systemd-mount-man]: http://www.freedesktop.org/software/systemd/man/systemd.mount.html
