---
title: Running Flatcar Container Linux on Eucalyptus 3.4
linktitle: Running on Eucalyptus 3.4
weight: 10
aliases:
    - ../os/booting-on-eucalyptus
---

These instructions will walk you through downloading Flatcar Container Linux, bundling the image, and running an instance from it.

## Import the image

These steps will download the Flatcar Container Linux image, uncompress it, convert it from qcow to raw, and then import it into Eucalyptus. In order to convert the image you will need to install `qemu-img` with your favorite package manager.

### Choosing a channel

Flatcar Container Linux is designed to be updated automatically with different schedules per channel. You can [disable this feature](update-strategies), although we don't recommend it. Read the [release notes](https://flatcar-linux.org/releases) for specific features and bug fixes.

<div id="eucalyptus-create">
  <ul class="nav nav-tabs">
    <li class="active"><a href="#stable-create" data-toggle="tab">Stable Channel</a></li>
    <li><a href="#beta-create" data-toggle="tab">Beta Channel</a></li>
    <li><a href="#alpha-create" data-toggle="tab">Alpha Channel</a></li>
  </ul>
  <div class="tab-content coreos-docs-image-table">
    <div class="tab-pane" id="alpha-create">
      <p>The Alpha channel closely tracks master and is released frequently. The newest versions of system libraries and utilities will be available for testing. The current version is Flatcar Container Linux {{< param alpha_channel >}}.</p>
      <pre>
$ wget -q https://alpha.release.flatcar-linux.net/amd64-usr/current/flatcar_production_openstack_image.img.bz2
$ bunzip2 flatcar_production_openstack_image.img.bz2
$ qemu-img convert -O raw flatcar_production_openstack_image.img flatcar_production_openstack_image.raw
$ euca-bundle-image -i flatcar_production_openstack_image.raw -r x86_64 -d /var/tmp
00% |====================================================================================================|   5.33 GB  59.60 MB/s Time: 0:01:35
Wrote manifest bundle/flatcar_production_openstack_image.raw.manifest.xml
$ euca-upload-bundle -m /var/tmp/flatcar_production_openstack_image.raw.manifest.xml -b flatcar-production
Uploaded flatcar-production/flatcar_production_openstack_image.raw.manifest.xml
$ euca-register flatcar-production/flatcar_production_openstack_image.raw.manifest.xml --virtualization-type hvm --name "Flatcar Container Linux-Production"
emi-E4A33D45
      </pre>
    </div>
    <div class="tab-pane" id="beta-create">
      <p>The Beta channel consists of promoted Alpha releases. The current version is Flatcar Container Linux {{< param beta_channel >}}.</p>
      <pre>
$ wget -q https://beta.release.flatcar-linux.net/amd64-usr/current/flatcar_production_openstack_image.img.bz2
$ bunzip2 flatcar_production_openstack_image.img.bz2
$ qemu-img convert -O raw flatcar_production_openstack_image.img flatcar_production_openstack_image.raw
$ euca-bundle-image -i flatcar_production_openstack_image.raw -r x86_64 -d /var/tmp
00% |====================================================================================================|   5.33 GB  59.60 MB/s Time: 0:01:35
Wrote manifest bundle/flatcar_production_openstack_image.raw.manifest.xml
$ euca-upload-bundle -m /var/tmp/flatcar_production_openstack_image.raw.manifest.xml -b flatcar-production
Uploaded flatcar-production/flatcar_production_openstack_image.raw.manifest.xml
$ euca-register flatcar-production/flatcar_production_openstack_image.raw.manifest.xml --virtualization-type hvm --name "Flatcar Container Linux-Production"
emi-E4A33D45
      </pre>
    </div>
    <div class="tab-pane active" id="stable-create">
      <p>The Stable channel should be used by production clusters. Versions of Flatcar Container Linux are battle-tested within the Beta and Alpha channels before being promoted. The current version is Flatcar Container Linux {{< param stable_channel >}}.</p>
      <pre>
$ wget -q https://stable.release.flatcar-linux.net/amd64-usr/current/flatcar_production_openstack_image.img.bz2
$ bunzip2 flatcar_production_openstack_image.img.bz2
$ qemu-img convert -O raw flatcar_production_openstack_image.img flatcar_production_openstack_image.raw
$ euca-bundle-image -i flatcar_production_openstack_image.raw -r x86_64 -d /var/tmp
00% |====================================================================================================|   5.33 GB  59.60 MB/s Time: 0:01:35
Wrote manifest bundle/flatcar_production_openstack_image.raw.manifest.xml
$ euca-upload-bundle -m /var/tmp/flatcar_production_openstack_image.raw.manifest.xml -b flatcar-production
Uploaded flatcar-production/flatcar_production_openstack_image.raw.manifest.xml
$ euca-register flatcar-production/flatcar_production_openstack_image.raw.manifest.xml --virtualization-type hvm --name "Flatcar Container Linux-Production"
emi-E4A33D45
      </pre>
    </div>
  </div>
</div>

## Boot it up

Now generate the ssh key that will be injected into the image for the `core` user and boot it up!

```sh
$ euca-create-keypair flatcar > core.pem
$ euca-run-instances emi-E4A33D45 -k flatcar -t m1.medium -g default
...
```

Your first Flatcar Container Linux instance should now be running. The only thing left to do is find the IP and SSH in.

```shell
$ euca-describe-instances | grep flatcar
RESERVATION     r-BCF44206      498025213678    group-1380012085
INSTANCE        i-22444094      emi-E4A33D45    euca-10-0-1-61.cloud.home       euca-172-16-0-56.cloud.internal running flatcar  0
                m1.small        2013-10-02T05:32:44.096Z        one     eki-05573B4A    eri-EA7436D2            monitoring-enabled      10.0.1.61    172.16.0.56                     instance-store                                  paravirtualized         5046c208-fec1-4a6e-b079-e7cdf6a7db8f_one_1

```

Finally SSH into it, note that the user is `core`:

```shell
$ chmod 400 core.pem
$ ssh -i core.pem core@10.0.1.61
core@10-0-0-3 ~ $
```

## Using Flatcar Container Linux

Now that you have a machine booted it is time to play around. Check out the [Flatcar Container Linux Quickstart](quickstart) guide or dig into [more specific topics](https://docs.flatcar-linux.org).
