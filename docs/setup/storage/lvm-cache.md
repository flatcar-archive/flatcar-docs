---
title: LVM Cache
description: How to create LVM setup with LVM Cache
weight: 10
aliases:
    - ../../os/lvm-cache
---


From lvmcache(7):

> The cache logical volume type uses a small and fast LV to improve the performance of a large and slow LV. It does this by storing the frequently used blocks on the faster LV. LVM refers to the small fast LV as a cache pool LV. The large slow LV is called the origin LV. D


**Setting up the LVM cache**

You can create the LVM setup with [pvcreate](https://linux.die.net/man/8/pvcreate), [vgcreate](https://linux.die.net/man/8/vgcreate), [lvcreate](https://linux.die.net/man/8/lvcreate), and [lvconvert]([https://linux.die.net/man/8/pvcreate](https://linux.die.net/man/8/lvconvert)) traditionally. See below:

For Flatcar you could use a butane configuration file for the same that would be transpiled to ignition for the same purpose (upload a script for your setup based on above somewhere): 

The following is a Butane YAML config - replace the `...` placeholders with your desired values:

```
variant: flatcar
version: 1.0.0
systemd:
  units:
    - name: lvm-cache-setup.service
      enabled: true
      contents: |
        [Unit]
        Description=LVM Cachesetup
        ConditionFirstBoot=yes
        Before=local-fs-pre.target
        [Service]
        Type=oneshot
        Restart=on-failure
        RemainAfterExit=yes
        ExecStart=.../lvm-cache.sh
        [Install]
        WantedBy=multi-user.target
    - name: llvm-cache.mount
      enabled: true
      contents: |
        [Unit]
        Description=LVM Mount
        [Mount]
        What=/dev/cache-layer-vg/data
        Where="${DIRECTORYTOMOUNTVOLUME}"
        Type=ext4
        Options=defaults
        [Install]
        WantedBy=local-fs.target
storage:
  files:
    - path: .../lvm-cache.sh
      mode: 0744
      contents:
        inline: |
        #!/bin/bash
        set -euo pipefail
        
        # Define variables
        VOLUME="/dev/...."
        DEVA="/dev/..."
        DEVB="/dev/..."
        CACHEDISKSIZE="...G"
        METADISKSIZE="...G"
        DIRECTORYTOMOUNTVOLUME="...."
        
        # Create Physical Volumes
        pvcreate "${VOLUME}" "${DEVA}" "${DEVB}"
        
        # Create Volume Group
        vgcreate cache-layer-vg "$VOLUME" "$DEVA" "$DEVB"
        
        # Create Logical Volume for data
        lvcreate -l 100%FREE -n data cache-layer-vg "$VOLUME"
        
        # Create Logical Volumes for cachedisk and metadisk
        lvcreate -L $"{CACHEDISKSIZE}" -n cachedisk cache-layer-vg
        lvcreate -L $"{METADISKSIZE}" -n metadisk cache-layer-vg
        
        # Convert cachedisk to cache pool with metadisk as pool metadata
        lvconvert --type=cache-pool /dev/cache-layer-vg/cachedisk --poolmetadata /dev/cache-layer-vg/metadisk
        
        # Convert data volume to cache volume using cachedisk as the cache pool
        lvconvert --type cache /dev/cache-layer-vg/data --cachepool /dev/cache-layer-vg/cachedisk
        
        # Format the data volume with ext4 filesystem
        mkfs.ext4 /dev/cache-layer-vg/data
        
        # Create directory for mounting the data volume
        mkdir "${DIRECTORYTOMOUNTVOLUME}"

```

Then you transpile it to ignition:

```
cat cl.yaml | docker run --rm -i quay.io/coreos/butane:latest > ignition-config.json
```


