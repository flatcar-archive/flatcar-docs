---
title: Verify Flatcar Container Linux images with GPG
linktitle: Verifying Images
description: How to verify the authenticity of Flatcar Container Linux images, using GPG.
weight: 40
aliases:
    - ../../os/verify-images
    - ../../clusters/creation/verify-images
---

Kinvolk publishes new Flatcar Container Linux images for each release across a variety of platforms and hosting providers. Each channel has its own set of images ([stable], [beta], [alpha]) that are posted to our storage site. Along with each image, a signature is generated from the [Flatcar Container Linux Image Signing Key][signing-key] and posted.

[signing-key]: https://www.flatcar.org/security/image-signing-key/
[stable]: https://stable.release.flatcar-linux.net/amd64-usr/current/
[beta]: https://beta.release.flatcar-linux.net/amd64-usr/current/
[alpha]: https://alpha.release.flatcar-linux.net/amd64-usr/current/

After downloading your image, you should verify it with `gpg` tool. First, download the image signing key:

```shell
curl -L -O https://www.flatcar.org/security/image-signing-key/Flatcar_Image_Signing_Key.asc
```

Next, import the public key and verify that the ID matches the website: [Flatcar Image Signing Key][signing-key]

```shell
gpg --import --keyid-format LONG Flatcar_Image_Signing_Key.asc
gpg: key E25D9AED0593B34A: public key "Flatcar Buildbot (Official Builds) <buildbot@flatcar-linux.org>" imported
gpg: Total number processed: 1
gpg:               imported: 1
```

Optionally, if you have your own gpg key, mark the key as valid in the local trustdb:
```shell
gpg --lsign-key E25D9AED0593B34A
```

Now we're ready to download an image and it's signature, ending in .sig. We're using the QEMU image in this example:

```shell
curl -L -O https://stable.release.flatcar-linux.net/amd64-usr/current/flatcar_production_qemu_image.img.bz2
curl -L -O https://stable.release.flatcar-linux.net/amd64-usr/current/flatcar_production_qemu_image.img.bz2.sig
```

Verify image with `gpg` tool:

```shell
gpg --verify flatcar_production_qemu_image.img.bz2.sig
gpg: assuming signed data in 'flatcar_production_qemu_image.img.bz2'
gpg: Signature made Tue Aug 31 19:47:19 2021 CEST
gpg:                using RSA key 858A560F97C9AEB22EC1C732961DDDD5250D4A42
gpg:                issuer "buildbot@flatcar-linux.org"
gpg: Good signature from "Flatcar Buildbot (Official Builds) <buildbot@flatcar-linux.org>"
```

The `Good signature` message indicates that the file signature is valid. Go launch some machines now that we've successfully verified that this Flatcar Container Linux image isn't corrupt, that it was authored by Kinvolk, and wasn't tampered with in transit.
