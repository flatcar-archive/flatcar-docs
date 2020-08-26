---
title: Booting Flatcar Container Linux from an ISO
weight: 10
---

The latest Flatcar Container Linux ISOs can be downloaded from the image storage site:

<div id="iso-images">
  <ul class="nav nav-tabs">
    <li class="active"><a href="#stable" data-toggle="tab">Stable Channel</a></li>
    <li><a href="#beta" data-toggle="tab">Beta Channel</a></li>
    <li><a href="#alpha" data-toggle="tab">Alpha Channel</a></li>
    <li><a href="#edge" data-toggle="tab">Edge Channel</a></li>
  </ul>
  <div class="tab-content coreos-docs-image-table">
    <div class="tab-pane" id="alpha">
      <div class="channel-info">
        <p>The Alpha channel closely tracks master and is released frequently. The newest versions of system libraries and utilities will be available for testing. The current version is Flatcar Container Linux {{site.alpha-channel}}.</p>
      </div>
      <a href="https://alpha.release.flatcar-linux.net/amd64-usr/current/flatcar_production_iso_image.iso" class="btn btn-primary">Download Alpha ISO</a>
      <a href="https://alpha.release.flatcar-linux.net/amd64-usr/current/" class="btn btn-default">Browse Storage Site</a>
      <br/><br/>
      <p>All of the files necessary to verify the image can be found on the storage site.</p>
    </div>
    <div class="tab-pane" id="beta">
      <div class="channel-info">
        <p>The Beta channel consists of promoted Alpha releases. The current version is Flatcar Container Linux {{site.beta-channel}}.</p>
      </div>
      <a href="https://beta.release.flatcar-linux.net/amd64-usr/current/flatcar_production_iso_image.iso" class="btn btn-primary">Download Beta ISO</a>
      <a href="https://beta.release.flatcar-linux.net/amd64-usr/current/" class="btn btn-default">Browse Storage Site</a>
      <br/><br/>
      <p>All of the files necessary to verify the image can be found on the storage site.</p>
    </div>
    <div class="tab-pane" id="edge">
      <div class="channel-info">
        <p>The Edge channel includes bleeding-edge features with the newest versions of the Linux kernel, systemd and other core packages. Can be highly unstable. The current version is Flatcar Container Linux {{site.edge-channel}}.</p>
      </div>
      <a href="https://edge.release.flatcar-linux.net/amd64-usr/current/flatcar_production_iso_image.iso" class="btn btn-primary">Download Edge ISO</a>
      <a href="https://edge.release.flatcar-linux.net/amd64-usr/current/" class="btn btn-default">Browse Storage Site</a>
      <br/><br/>
      <p>All of the files necessary to verify the image can be found on the storage site.</p>
    </div>
    <div class="tab-pane active" id="stable">
      <div class="channel-info">
        <p>The Stable channel should be used by production clusters. Versions of Flatcar Container Linux are battle-tested within the Beta and Alpha channels before being promoted. The current version is Flatcar Container Linux {{site.stable-channel}}.</p>
      </div>
      <a href="https://stable.release.flatcar-linux.net/amd64-usr/current/flatcar_production_iso_image.iso" class="btn btn-primary">Download Stable ISO</a>
      <a href="https://stable.release.flatcar-linux.net/amd64-usr/current/" class="btn btn-default">Browse Storage Site</a>
      <br/><br/>
      <p>All of the files necessary to verify the image can be found on the storage site.</p>
    </div>
  </div>
</div>

## Known limitations

1. UEFI boot is not currently supported. Boot the system in BIOS compatibility mode.
2. There is no straightforward way to provide an [Ignition config][cl-configs].
3. A minimum of 2 GB of RAM is required to boot Flatcar Container Linux via ISO.

## Install to disk

The most common use-case for this ISO is to install Flatcar Container Linux to disk. You can [find those instructions here](installing-to-disk.md).

## No authentication on console

The ISO is configured to start a shell on the console without prompting for a password. This is convenient for installation and troubleshooting, but use caution.

[cl-configs]: provisioning.md
