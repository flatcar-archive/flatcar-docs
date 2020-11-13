---
title: Running Flatcar Container Linux on Google Compute Engine
weight: 10
---

Before proceeding, you will need a GCE account ([GCE free trial][free-trial]) and [install gcloud][gcloud-documentation] on your machine. In each command below, be sure to insert your project name in place of `<project-id>`.

[gce-advanced-os]: http://developers.google.com/compute/docs/transition-v1#customkernelbinaries
[gcloud-documentation]: https://cloud.google.com/sdk/
[free-trial]: https://cloud.google.com/free-trial/?utm_source=flatcar&utm_medium=partners&utm_campaign=partner-free-trial

After installation, log into your account with `gcloud auth login` and enter your project ID when prompted.

<!--
This section is commented out until images have been made public

## Choosing a channel

Flatcar Container Linux is designed to be updated automatically with different schedules per channel. You can [disable this feature](update-strategies), although we don't recommend it. Read the [release notes](https://flatcar-linux.org/releases) for specific features and bug fixes.

Create 3 instances from the image above using our Ignition from `example.ign`:

<div id="gce-create">
  <ul class="nav nav-tabs">
    <li class="active"><a href="#stable-create" data-toggle="tab">Stable Channel</a></li>
    <li><a href="#beta-create" data-toggle="tab">Beta Channel</a></li>
    <li><a href="#alpha-create" data-toggle="tab">Alpha Channel</a></li>
    <li><a href="#edge-create" data-toggle="tab">Edge Channel</a></li>
  </ul>
  <div class="tab-content coreos-docs-image-table">
    <div class="tab-pane active" id="stable-create">
      <p>The Stable channel should be used by production clusters. Versions of Flatcar Container Linux are battle-tested within the Beta and Alpha channels before being promoted. The current version is Flatcar Container Linux {{< param stable_channel >}}.</p>
      <pre>gcloud compute instances create flatcar1 flatcar2 flatcar3 --image-project flatcar-cloud --image-family flatcar-stable --zone us-central1-a --machine-type n1-standard-1 --metadata-from-file user-data=config.ign</pre>
    </div>
    <div class="tab-pane" id="beta-create">
      <p>The Beta channel consists of promoted Alpha releases. The current version is Flatcar Container Linux {{< param beta_channel >}}.</p>
      <pre>gcloud compute instances create flatcar1 flatcar2 flatcar3 --image-project flatcar-cloud --image-family flatcar-beta --zone us-central1-a --machine-type n1-standard-1 --metadata-from-file user-data=config.ign</pre>
    </div>
    <div class="tab-pane" id="alpha-create">
      <p>The Alpha channel closely tracks master and is released frequently. The newest versions of system libraries and utilities will be available for testing. The current version is Flatcar Container Linux {{< param alpha_channel >}}.</p>
      <pre>gcloud compute instances create flatcar1 flatcar2 flatcar3 --image-project flatcar-cloud --image-family flatcar-alpha --zone us-central1-a --machine-type n1-standard-1 --metadata-from-file user-data=config.ign</pre>
    </div>
    <div class="tab-pane" id="edge-create">
      <p>The Edge channel includes bleeding-edge features with the newest versions of the Linux kernel, systemd
      and other core packages. Can be highly unstable. The current version is Flatcar Container Linux {{< param edge_channel >}}.</p>
      <pre>gcloud compute instances create flatcar1 flatcar2 flatcar3 --image-project flatcar-cloud --image-family flatcar-edge --zone us-central1-a --machine-type n1-standard-1 --metadata-from-file user-data=config.ign</pre>
    </div>
  </div>
</div>
-->

## Uploading an Image

Official Flatcar Container Linux images are not available on Google Cloud at the moment. However, you can run Flatcar Container Linux today by uploading an image to your account.

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
[google-cloud-flatcar-image-upload]: https://github.com/kinvolk/flatcar-cloud-image-uploader/blob/master/google-cloud-flatcar-image-upload

## Upgrade from CoreOS Container Linux

You can also [upgrade from an existing CoreOS Container Linux system](./update-from-container-linux).

## Container Linux Config

Flatcar Container Linux allows you to configure machine parameters, configure networking, launch systemd units on startup, and more via Container Linux Configs. These configs are then transpiled into Ignition configs and given to booting machines. Head over to the [docs to learn about the supported features][cl-configs].

You can provide a raw Ignition config to Flatcar Container Linux via the Google Cloud console's metadata field `user-data` or via a flag using `gcloud`.

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

### Additional storage

Additional disks attached to instances can be mounted with a `.mount` unit. Each disk can be accessed via `/dev/disk/by-id/google-<disk-name>`. Here's the Container Linux Config to format and mount a disk called `database-backup`:

```yaml
storage:
  filesystems:
    - mount:
        device: /dev/disk/by-id/scsi-0Google_PersistentDisk_database-backup
        format: ext4

systemd:
  units:
    - name: media-backup.mount
      enable: true
      contents: |
        [Mount]
        What=/dev/disk/by-id/scsi-0Google_PersistentDisk_database-backup
        Where=/media/backup
        Type=ext4

        [Install]
        RequiredBy=local-fs.target
```

For more information about mounting storage, Google's [own documentation](https://developers.google.com/compute/docs/disks#attach_disk) is the best source. You can also read about [mounting storage on Flatcar Container Linux](mounting-storage).

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
systemd:
  units:
    - name: oem-gce-enable-oslogin.service
      mask: true
```

When disabling OS Login functionality on the instance, it is also recommended to disable it in the GCE console.

## Using Flatcar Container Linux

Now that you have a machine booted it is time to play around. Check out the [Flatcar Container Linux Quickstart](quickstart) guide or dig into [more specific topics](https://docs.flatcar-linux.org).
