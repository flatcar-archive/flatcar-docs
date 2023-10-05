---
title: Hands on 2 - Provisioning
linktitle: Hands on 2 - Provisioning
weight: 2
---

The goal of this hands-on is to:
* provision a local Flatcar instance
* write Butane configuration
* generate the Ignition configuration
* boot the instance with the config

This is what we've done in the previous hands-on but now it's done _as code_, we want to deploy an Nginx container serving a "hello world" static webpage. As a reminder, Ignition configuration is used to provision a Flatcar instance, it's JSON file generated from a Butane configuration (YAML).

# Step-by-step

* Clone the tutorial repository and cd into it: `git clone https://github.com/tormath1/flatcar-tutorial ; cd flatcar-tutorial/hands-on-2`
* Open `./config.yaml` and find the TODO section.
* Add the following section (from https://coreos.github.io/butane/examples/#files):
```
storage:
  files:
    - path: /var/www/index.html
      contents:
        inline: Hello world
```
* Transpile the Butane configuration (`config.yaml`) to Ignition configuration (`config.json`) - it is possible to use the Butane [binary](https://coreos.github.io/butane/getting-started/#standalone-binary) or the Docker image
```
$ docker run --rm -i quay.io/coreos/butane:latest < config.yaml > config.json
```
* Use a fresh Flatcar image from the previous hands-on (or download again). NOTE: Ignition runs at first boot, it won't work if you reuse your the previously booted image, always decompress again each time you change your Ignition config.
```
cp -i --reflink=auto ../hands-on-1/flatcar_production_qemu_image.img.fresh flatcar_production_qemu_image.img
chmod +x flatcar_production_qemu.sh
```
* Start the image with Ignition configuration (`-i ./config.json`)
```
./flatcar_production_qemu.sh -i ./config.json -- -display curses
```
* Once on the instance, assert nginx works correctly (`curl localhost` or `systemctl status nginx.service`)

# Resources

* https://coreos.github.io/butane/examples/
* https://coreos.github.io/ignition/rationale/
* https://www.flatcar.org/docs/latest/installing/#concepts-configuration-and-provisioning

# Demo

* Video with timestamp: https://youtu.be/woZlGiLsKp0?t=676
* Asciinema: https://asciinema.org/a/591440
