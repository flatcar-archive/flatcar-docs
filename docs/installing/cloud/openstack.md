---
title: Running Flatcar Container Linux on OpenStack
linktitle: Running on OpenStack
weight: 10
aliases:
    - ../../os/booting-on-openstack
    - ../../cloud-providers/booting-on-openstack
---

These instructions will walk you through downloading Flatcar Container Linux for OpenStack, importing it with the `glance` tool, and running your first cluster with the `nova` tool.

## Import the image

These steps will download the Flatcar Container Linux image, uncompress it, and then import it into the glance image store.

## Choosing a channel

Flatcar Container Linux is designed to be updated automatically with different schedules per channel. You can [disable this feature][update-strategies], although we don't recommend it. Read the [release notes][release-notes] for specific features and bug fixes.

<div id="openstack-create">
  <ul class="nav nav-tabs">
    <li class="active"><a href="#stable-create" data-toggle="tab">Stable Channel</a></li>
    <li><a href="#beta-create" data-toggle="tab">Beta Channel</a></li>
    <li><a href="#alpha-create" data-toggle="tab">Alpha Channel</a></li>
  </ul>
  <div class="tab-content coreos-docs-image-table">
    <div class="tab-pane" id="alpha-create">
      <p>The Alpha channel closely tracks master and is released frequently. The newest versions of system libraries and utilities will be available for testing. The current version is Flatcar Container Linux {{< param alpha_channel >}}.</p>
<pre>
$ wget https://alpha.release.flatcar-linux.net/amd64-usr/current/flatcar_production_openstack_image.img.bz2
$ bunzip2 flatcar_production_openstack_image.img.bz2
</pre>
    </div>
    <div class="tab-pane" id="beta-create">
      <p>The Beta channel consists of promoted Alpha releases. The current version is Flatcar Container Linux {{< param beta_channel >}}.</p>
<pre>
$ wget https://beta.release.flatcar-linux.net/amd64-usr/current/flatcar_production_openstack_image.img.bz2
$ bunzip2 flatcar_production_openstack_image.img.bz2
</pre>
    </div>
  <div class="tab-pane active" id="stable-create">
      <p>The Stable channel should be used by production clusters. Versions of Flatcar Container Linux are battle-tested within the Beta and Alpha channels before being promoted. The current version is Flatcar Container Linux {{< param stable_channel >}}.</p>
<pre>
$ wget https://stable.release.flatcar-linux.net/amd64-usr/current/flatcar_production_openstack_image.img.bz2
$ bunzip2 flatcar_production_openstack_image.img.bz2
</pre>
    </div>
  </div>
</div>

Once the download completes, add the Flatcar Container Linux image into Glance:

```shell
$ glance image-create --name Container-Linux \
  --container-format bare \
  --disk-format qcow2 \
  --file flatcar_production_openstack_image.img
+------------------+--------------------------------------+
| Property         | Value                                |
+------------------+--------------------------------------+
| checksum         | 4742f3c30bd2dcbaf3990ac338bd8e8c     |
| container_format | ovf                                  |
| created_at       | 2013-08-29T22:21:22                  |
| deleted          | False                                |
| deleted_at       | None                                 |
| disk_format      | qcow2                                |
| id               | cdf3874c-c27f-4816-bc8c-046b240e0edd |
| is_public        | False                                |
| min_disk         | 0                                    |
| min_ram          | 0                                    |
| name             | flatcar                               |
| owner            | 8e662c811b184482adaa34c89a9c33ae     |
| protected        | False                                |
| size             | 363660800                            |
| status           | active                               |
| updated_at       | 2013-08-29T22:22:04                  |
+------------------+--------------------------------------+
```

Optionally add the `--visibility public` flag to make this image available outside of the configured OpenStack account tenant.

## Butane Configs

Flatcar Container Linux allows you to configure machine parameters, launch systemd units on startup and more via Butane Configs. These configs are then transpiled into Ignition JSON configs and given to booting machines. Jump over to the [docs to learn about the supported features][butane-configs]. We're going to provide our Butane Config to OpenStack via the user-data flag. Our Butane Config will also contain SSH keys that will be used to connect to the instance. In order for this to work your OpenStack cloud provider must support [config drive][config-drive] or the OpenStack metadata service.

[config-drive]: http://docs.openstack.org/user-guide/cli_config_drive.html

As an example, this Butane YAML config will start an NGINX Docker container:

```yaml
variant: flatcar
version: 1.0.0
passwd:
  users:
    - name: core
      ssh_authorized_keys:
        - ssh-rsa ABCD...
systemd:
  units:
    - name: nginx.service
      enabled: true
      contents: |
        [Unit]
        Description=NGINX example
        After=docker.service
        Requires=docker.service
        [Service]
        TimeoutStartSec=0
        ExecStartPre=-/usr/bin/docker rm --force nginx1
        ExecStart=/usr/bin/docker run --name nginx1 --pull always --log-driver=journald --net host docker.io/nginx:1
        ExecStop=/usr/bin/docker stop nginx1
        Restart=always
        RestartSec=5s
        [Install]
        WantedBy=multi-user.target
```

Transpile it to Ignition JSON:

```shell
cat cl.yaml | docker run --rm -i ghcr.io/flatcar/ct:latest -platform openstack-metadata > ignition.json
```

The `coreos-metadata.service` saves metadata variables to `/run/metadata/flatcar`. Systemd units can use them with `EnvironmentFile=/run/metadata/flatcar` in the `[Service]` section when setting `Requires=coreos-metadata.service` and `After=coreos-metadata.service` in the `[Unit]` section.
Unfortunately systems relying on config drive are currently unsupported.

## Launch cluster

Boot the machines with the `nova` CLI, referencing the image ID from the import step above and your [JSON file from ct][cl-configs]:

```shell
nova boot \
--user-data ./config.ign \
--image cdf3874c-c27f-4816-bc8c-046b240e0edd \
--key-name flatcar \
--flavor m1.medium \
--min-count 3 \
--security-groups default,flatcar
```

To use config drive you may need to add `--config-drive=true` to command above.

If you have more than one network, you may have to be explicit in the nova boot command.

```shell
--nic net-id=5b9c5ef6-28b9-4781-ac18-d7d86765fd38
```

You can see the IDs for your configured networks by running

```shell
nova network-list
+--------------------------------------+---------+------+
| ID                                   | Label   | Cidr |
+--------------------------------------+---------+------+
| f54b48c7-34fc-4828-8ee9-21b623c7b8f9 | public  | -    |
| 5b9c5ef6-28b9-4781-ac18-d7d86765fd38 | private | -    |
+--------------------------------------+---------+------+
```

Your first Flatcar Container Linux cluster should now be running. The only thing left to do is find an IP and SSH in.

```shell
$ nova list
+--------------------------------------+-----------------+--------+------------+-------------+--------------------+
| ID                                   | Name            | Status | Task State | Power State | Networks           |
+--------------------------------------+-----------------+--------+------------+-------------+--------------------+
| a1df1d98-622f-4f3b-adef-cb32f3e2a94d | flatcar-a1df1d98 | ACTIVE | None       | Running     | private=10.0.0.3  |
| db13c6a7-a474-40ff-906e-2447cbf89440 | flatcar-db13c6a7 | ACTIVE | None       | Running     | private=10.0.0.4  |
| f70b739d-9ad8-4b0b-bb74-4d715205ff0b | flatcar-f70b739d | ACTIVE | None       | Running     | private=10.0.0.5  |
+--------------------------------------+-----------------+--------+------------+-------------+--------------------+
```

Finally SSH into an instance, note that the user is `core`:

```shell
$ chmod 400 core.pem
$ ssh -i core.pem core@10.0.0.3
core@10-0-0-3 ~ $
```

## Adding more machines

Adding new instances to the cluster is as easy as launching more with the same Butane Config. New instances will join the cluster assuming they can communicate with the others.

Example:

```shell
nova boot \
--user-data ./config.ign \
--image cdf3874c-c27f-4816-bc8c-046b240e0edd \
--key-name flatcar \
--flavor m1.medium \
--security-groups default,flatcar
```

## Using Flatcar Container Linux

Now that you have a machine booted it is time to play around. Check out the [Flatcar Container Linux Quickstart][quickstart] guide or dig into [more specific topics][doc-index].

[update-strategies]: ../../setup/releases/update-strategies
[release-notes]: https://flatcar-linux.org/releases
[quickstart]: ../
[doc-index]: ../../
[butane-configs]: ../../provisioning/config-transpiler
