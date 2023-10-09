---
title: Running Flatcar Container Linux on Google Compute Engine
linktitle: Running on Google Compute Engine
weight: 15
aliases:
    - ../../os/booting-on-google-compute-engine
    - ../../cloud-providers/booting-on-google-compute-engine
---

Before proceeding, you will need a GCE account ([GCE free trial][free-trial]) and [install gcloud][gcloud-documentation] on your machine. In each command below, be sure to insert your project name in place of `<project-id>`.

[gce-advanced-os]: http://developers.google.com/compute/docs/transition-v1#customkernelbinaries
[gcloud-documentation]: https://cloud.google.com/sdk/
[free-trial]: https://cloud.google.com/free-trial/?utm_source=flatcar&utm_medium=partners&utm_campaign=partner-free-trial

After installation, log into your account with `gcloud auth login` and enter your project ID when prompted.

Flatcar is published by the `kinvolk` publisher on GCE.

## Choosing a channel

Flatcar Container Linux is designed to be updated automatically with different schedules per channel. You can [disable this feature][update-strategies], although we don't recommend it. Read the [release notes](https://flatcar-linux.org/releases) for specific features and bug fixes.

Create 3 instances from the image above using our Ignition from `example.ign`:

<div id="gce-create">
  <ul class="nav nav-tabs">
    <li class="active"><a href="#stable-create" data-toggle="tab">Stable Channel</a></li>
    <li><a href="#beta-create" data-toggle="tab">Beta Channel</a></li>
    <li><a href="#alpha-create" data-toggle="tab">Alpha Channel</a></li>
  </ul>
  <div class="tab-content coreos-docs-image-table">
    <div class="tab-pane active" id="stable-create">
      <p>The Stable channel should be used by production clusters. Versions of Flatcar Container Linux are battle-tested within the Beta and Alpha channels before being promoted. The current version is Flatcar Container Linux {{< param stable_channel >}}.</p>
      <pre>gcloud compute instances create flatcar1 flatcar2 flatcar3 --image-project kinvolk-public --image-family flatcar-stable --zone us-central1-a --machine-type n1-standard-1 --metadata-from-file user-data=config.ign</pre>
    </div>
    <div class="tab-pane" id="beta-create">
      <p>The Beta channel consists of promoted Alpha releases. The current version is Flatcar Container Linux {{< param beta_channel >}}.</p>
      <pre>gcloud compute instances create flatcar1 flatcar2 flatcar3 --image-project kinvolk-public --image-family flatcar-beta --zone us-central1-a --machine-type n1-standard-1 --metadata-from-file user-data=config.ign</pre>
    </div>
    <div class="tab-pane" id="alpha-create">
      <p>The Alpha channel closely tracks master and is released frequently. The newest versions of system libraries and utilities will be available for testing. The current version is Flatcar Container Linux {{< param alpha_channel >}}.</p>
      <pre>gcloud compute instances create flatcar1 flatcar2 flatcar3 --image-project kinvolk-public --image-family flatcar-alpha --zone us-central1-a --machine-type n1-standard-1 --metadata-from-file user-data=config.ign</pre>
    </div>
  </div>
</div>

## Uploading an Image

If you prefer, you can also run Flatcar Container Linux by uploading a custom image to your account.

To do so, run the following command:

```shell
docker run -it quay.io/kinvolk/google-cloud-flatcar-image-upload \
  --bucket-name <bucket name> \
  --project-id <project id>
```

Where:

- `<bucket name>` should be a valid [bucket][bucket] name.
- `<project id>` should be your project ID.

During execution, the script will ask you to log into your Google account and then create all necessary resources for
uploading an image. It will then download the requested Flatcar Container Linux image and upload it to the Google Cloud.

To see all available options, run:

```shell
docker run -it quay.io/kinvolk/google-cloud-flatcar-image-upload --help

Usage: /usr/local/bin/upload_images.sh [OPTION...]

 Required arguments:
  -b, --bucket-name Name of GCP bucket for storing images.
  -p, --project-id  ID of the project for creating bucket.

 Optional arguments:
  -c, --channel     Flatcar Container Linux release channel. Defaults to 'stable'.
  -v, --version     Flatcar Container Linux version. Defaults to 'current'.
  -i, --image-name  Image name, which will be used later in Lokomotive configuration. Defaults to 'flatcar-<channel>'.

 Optional flags:
   -f, --force-reupload If used, image will be uploaded even if it already exist in the bucket.
   -F, --force-recreate If user, if compute image already exist, it will be removed and recreated.
```

The Dockerfile for the `quay.io/kinvolk/google-cloud-flatcar-image-upload` image is managed [here][google-cloud-flatcar-image-upload].

[bucket]: https://cloud.google.com/storage/docs/key-terms#bucket-names
[google-cloud-flatcar-image-upload]: https://github.com/flatcar/flatcar-cloud-image-uploader/blob/master/google-cloud-flatcar-image-upload

## Upgrade from CoreOS Container Linux

You can also [upgrade from an existing CoreOS Container Linux system](./update-from-container-linux).

## Butane Config

Flatcar Container Linux allows you to configure machine parameters, configure networking, launch systemd units on startup, and more via Butane Configs. These configs are then transpiled into Ignition configs and given to booting machines. Head over to the [docs to learn about the supported features][butane-configs].

You can provide a raw Ignition JSON config to Flatcar Container Linux via the Google Cloud console's metadata field `user-data` or via a flag using `gcloud`.

As an example, this Butane YAML config will start an NGINX Docker container:

```yaml
variant: flatcar
version: 1.0.0
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
cat cl.yaml | docker run --rm -i quay.io/coreos/butane:latest > ignition.json
```
### Additional storage

Additional disks attached to instances can be mounted with a `.mount` unit. Each disk can be accessed via `/dev/disk/by-id/google-<disk-name>`. Here's the Butane Config to format and mount a disk called `database-backup`:

```yaml
variant: flatcar
version: 1.0.0
storage:
  filesystems:
    - device: /dev/disk/by-id/scsi-0Google_PersistentDisk_database-backup
      format: ext4
systemd:
  units:
    - name: media-backup.mount
      enabled: true
      contents: |
        [Mount]
        What=/dev/disk/by-id/scsi-0Google_PersistentDisk_database-backup
        Where=/media/backup
        Type=ext4

        [Install]
        RequiredBy=local-fs.target
```

For more information about mounting storage, Google's [own documentation](https://developers.google.com/compute/docs/disks#attach_disk) is the best source. You can also read about [mounting storage on Flatcar Container Linux][mounting-storage].

### Adding more machines

To add more instances to the cluster, just launch more with the same Ignition config inside of the project.

## SSH and users

Users are added to Container Linux on GCE by the user provided configuration (i.e. Ignition, cloudinit) and by either the GCE account manager or [GCE OS Login](https://cloud.google.com/compute/docs/instances/managing-instance-access). OS Login is used if it is enabled for the instance, otherwise the GCE account manager is used.

### Using the GCE account manager

You can log in your Flatcar Container Linux instances using:

```sh
gcloud compute ssh --zone us-central1-a core@<instance-name>
```

Users other than `core`, which are set up by the GCE account manager, may not be a member of required groups. If you have issues, try running commands such as `journalctl` with sudo.

### Using OS Login

You can log in using your Google account on instances with OS Login enabled. OS Login needs to be [enabled in the GCE console](https://cloud.google.com/compute/docs/instances/managing-instance-access#enable_oslogin) and on the instance. It is enabled by default on instances provisioned with Container Linux 1898.0.0 or later. Once enabled, you can log into your Container Linux instances using:

```sh
gcloud compute ssh --zone us-central1-a <instance-name>
```

This will use your GCE user to log in.

#### Disabling OS Login on newly provisioned nodes

You can disable the OS Login functionality by masking the `oem-gce-enable-oslogin.service` unit:

```yaml
variant: flatcar
version: 1.0.0
systemd:
  units:
    - name: oem-gce-enable-oslogin.service
      mask: true
```

When disabling OS Login functionality on the instance, it is also recommended to disable it in the GCE console.

## Monitoring

Flatcar isn't a supported distro for the
[Google Ops Agent](https://cloud.google.com/stackdriver/docs/solutions/agents/ops-agent)
, as it's designed for traditional operating systems and monitoring the
processes running on them.

It's likely however that there will be metrics within Flatcar that will be
useful additions to VM metrics in Google Cloud Monitoring.

### GCP Custom Metrics

Google provide an API and SDKs to ingest custom metrics. For example this
Python script will send CPU load average and root volume utilisation
every minute:

**gcp_custom_metrics.py**

```python
#!/usr/bin/env python3
from google.cloud import monitoring_v3

import time
import os
import shutil
import requests

metadata_server = "http://metadata/computeMetadata/v1/"
metadata_flavor = {'Metadata-Flavor' : 'Google'}

gce_name = requests.get(metadata_server + 'instance/hostname', headers = metadata_flavor).text
gce_project = requests.get(metadata_server + 'project/project-id', headers = metadata_flavor).text
split_gce_name=gce_name.split(".",2)

client = monitoring_v3.MetricServiceClient()
project_id = gce_project
project_name = f"projects/{project_id}"

load_series = monitoring_v3.TimeSeries()
load_series.metric.type = "custom.googleapis.com/node_load"
load_series.resource.type = "gce_instance"
load_series.resource.labels["instance_id"] = split_gce_name[0]
load_series.resource.labels["zone"] = split_gce_name[1]

du_series = monitoring_v3.TimeSeries()
du_series.metric.type = "custom.googleapis.com/root_volume_usage"
du_series.resource.type = "gce_instance"
du_series.resource.labels["instance_id"] = split_gce_name[0]
du_series.resource.labels["zone"] = split_gce_name[1]

while True:
    load1, load5, load15 = os.getloadavg()
    root_total, root_used, root_free = shutil.disk_usage("/")

    now = time.time()
    seconds = int(now)
    nanos = int((now - seconds) * 10 ** 9)
    interval = monitoring_v3.TimeInterval(
        {"end_time": {"seconds": seconds, "nanos": nanos}}
    )
    load_point = monitoring_v3.Point({"interval": interval, "value": {"double_value": load5}})
    load_series.points = [load_point]
    client.create_time_series(request={"name": project_name, "time_series": [load_series]})

    du_point = monitoring_v3.Point({"interval": interval, "value": {"double_value": root_used/root_total}})
    du_series.points = [du_point]
    client.create_time_series(request={"name": project_name, "time_series": [du_series]})

    time.sleep(60)
```

The script can then be packaged up into a Dockerfile:

**Dockerfile**

```dockerfile
FROM python:3-slim

WORKDIR /usr/src/app

RUN pip3 install --no-cache-dir google-cloud-monitoring

COPY gcp_custom_metrics.py .

CMD [ "python3", "./gcp_custom_metrics.py" ]
```

The resulting image can then be deployed to a container on each Flatcar node.

## Using Flatcar Container Linux

Now that you have a machine booted it is time to play around. Check out the [Flatcar Container Linux Quickstart][quickstart] guide or dig into [more specific topics][doc-index].

[mounting-storage]: ../../setup/storage/mounting-storage
[quickstart]: ../
[doc-index]: ../../
[update-strategies]: ../../setup/releases/update-strategies
[cl-configs]: ../../provisioning/config-transpiler
