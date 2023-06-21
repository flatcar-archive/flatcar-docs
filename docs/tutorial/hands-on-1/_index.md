---
title: Hands on 1 - Discovering
linktitle: Hands on 1 - Discovering
weight: 2
---

The goal of this hands-on is to:
* locally run a Flatcar instance
* boot the instance and SSH into
* run Nginx container on the instance

# Step-by-step

```bash
# create a working directory
mkdir flatcar; cd flatcar
# get the qemu helper
wget https://stable.release.flatcar-linux.net/amd64-usr/current/flatcar_production_qemu.sh
# get the latest stable release for qemu
wget https://stable.release.flatcar-linux.net/amd64-usr/current/flatcar_production_qemu_image.img.bz2
# extract the downloaded image
bzip2 --decompress --keep flatcar_production_qemu_image.img.bz2
# make the qemu helper executable
chmod +x flatcar_production_qemu.sh
# starts the flatcar image in console mode
./flatcar_production_qemu.sh -- -display curses
```

NOTE: it's possible to connect to the instance via SSH:
```bash
$ cat ~/.ssh/config
Host flatcar
	User core
	StrictHostKeyChecking no
	UserKnownHostsFile /dev/null
	HostName 127.0.0.1
	Port 2222
$ ssh flatcar
```

Once on the instance, you can try things and run a docker image:
```
# run an nginx docker image
docker run --rm -p 80:80 -d nginx
# assert it works
curl localhost
```

# Resources

* [documentation][./installing/vms/qemu/#startup-flatcar-container-linux]

# Demo

* Video with timestamp: https://youtu.be/woZlGiLsKp0?t=472
* Asciinema: https://asciinema.org/a/591438
