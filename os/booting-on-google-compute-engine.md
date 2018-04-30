# Running Flatcar Linux on Google Compute Engine

Before proceeding, you will need a GCE account ([GCE free trial ][free-trial]) and [install gcloud][gcloud-documentation] on your machine. In each command below, be sure to insert your project name in place of `<project-id>`.

[gce-advanced-os]: http://developers.google.com/compute/docs/transition-v1#customkernelbinaries
[gcloud-documentation]: https://cloud.google.com/sdk/
[free-trial]: https://cloud.google.com/free-trial/?utm_source=flatcar&utm_medium=partners&utm_campaign=partner-free-trial

After installation, log into your account with `gcloud auth login` and enter your project ID when prompted.

## Installation from a tarball

One of the possible ways of installation is to import a pre-built tarball. The image file will be in `https://${CHANNEL}.release.flatcar-linux.net/amd64-usr/${VERSION}/flatcar_production_gce.tar.gz`.
Make sure you download the signature (it's available in `https://${CHANNEL}.release.flatcar-linux.net/amd64-usr/${VERSION}/flatcar_production_gce.tar.gz.sig`) and check it before proceeding.

For example, to get the latest alpha:

```
$ wget https://alpha.release.flatcar-linux.net/amd64-usr/current/flatcar_production_gce.tar.gz
$ wget https://alpha.release.flatcar-linux.net/amd64-usr/current/flatcar_production_gce.tar.gz.sig
$ gpg --verify flatcar_production_gce.tar.gz.sig
gpg: assuming signed data in 'flatcar_production_gce.tar.gz'
gpg: Signature made Thu 15 Mar 2018 10:28:25 AM CET
gpg:                using RSA key A621F1DA96C93C639506832D603443A1D0FC498C
gpg: Good signature from "Flatcar Buildbot (Official Builds) <buildbot@flatcar-linux.org>" [ultimate]
```

Follow the [Importing Boot Disk Images to Compute Engine](https://cloud.google.com/compute/docs/images/import-existing-image#import_image) guide to learn how to import the image and start instances with it.

## Upgrade from Container Linux

You can also upgrade from an existing Container Linux system. See also [Update from Container Linux](./flatcar-update-from-container-linux.md).

## Container Linux Config

Flatcar Linux allows you to configure machine parameters, configure networking, launch systemd units on startup, and more via Container Linux Configs. These configs are then transpiled into Ignition configs and given to booting machines. Head over to the [docs to learn about the supported features][cl-configs].

You can provide a raw Ignition config to Flatcar Linux via the Google Cloud console's metadata field `user-data` or via a flag using `gcloud`.

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

[cl-configs]: provisioning.md

## Choosing a channel

Flatcar Linux is designed to be updated automatically with different schedules per channel. You can [disable this feature](update-strategies.md), although we don't recommend it. Read the [release notes](https://flatcar-linux.org/releases) for specific features and bug fixes.

Create 3 instances from the image above using our Ignition from `example.ign`:

<div id="gce-create">
  <ul class="nav nav-tabs">
    <li class="active"><a href="#stable-create" data-toggle="tab">Stable Channel</a></li>
    <li><a href="#beta-create" data-toggle="tab">Beta Channel</a></li>
    <li><a href="#alpha-create" data-toggle="tab">Alpha Channel</a></li>
  </ul>
  <div class="tab-content coreos-docs-image-table">
    <div class="tab-pane" id="alpha-create">
      <p>The Alpha channel closely tracks master and is released frequently. The newest versions of system libraries and utilities will be available for testing. The current version is Flatcar Linux {{site.alpha-channel}}.</p>
      <pre>gcloud compute instances create core1 core2 core3 --image-project coreos-cloud --image-family coreos-alpha --zone us-central1-a --machine-type n1-standard-1 --metadata-from-file user-data=config.ign</pre>
    </div>
    <div class="tab-pane" id="beta-create">
      <p>The Beta channel consists of promoted Alpha releases. The current version is Flatcar Linux {{site.beta-channel}}.</p>
      <pre>gcloud compute instances create core1 core2 core3 --image-project coreos-cloud --image-family coreos-beta --zone us-central1-a --machine-type n1-standard-1 --metadata-from-file user-data=config.ign</pre>
    </div>
    <div class="tab-pane active" id="stable-create">
      <p>The Stable channel should be used by production clusters. Versions of Flatcar Linux are battle-tested within the Beta and Alpha channels before being promoted. The current version is Flatcar Linux {{site.stable-channel}}.</p>
      <pre>gcloud compute instances create core1 core2 core3 --image-project coreos-cloud --image-family coreos-stable --zone us-central1-a --machine-type n1-standard-1 --metadata-from-file user-data=config.ign</pre>
    </div>
  </div>
</div>

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

For more information about mounting storage, Google's [own documentation](https://developers.google.com/compute/docs/disks#attach_disk) is the best source. You can also read about [mounting storage on Flatcar Linux](mounting-storage.md).

### Adding more machines

To add more instances to the cluster, just launch more with the same Ignition config inside of the project.

## SSH

You can log in your Flatcar Linux instances using:

```sh
gcloud compute ssh --zone us-central1-a core@<instance-name>
```

Users other than `core`, which are set up by the GCE account manager, may not be a member of required groups. If you have issues, try running commands such as `journalctl` with sudo.

## Using Flatcar Linux

Now that you have a machine booted it is time to play around. Check out the [Flatcar Linux Quickstart](quickstart.md) guide or dig into [more specific topics](https://docs.flatcar-linux.org).
