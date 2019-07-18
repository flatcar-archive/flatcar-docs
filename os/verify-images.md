# Verify Flatcar Linux images with GPG

Kinvolk publishes new Flatcar Linux images for each release across a variety of platforms and hosting providers. Each channel has its own set of images ([stable], [beta], [alpha], [edge]) that are posted to our storage site. Along with each image, a signature is generated from the [Flatcar Linux Image Signing Key][signing-key] and posted.

[signing-key]: https://www.flatcar-linux.org/security/image-signing-key/
[stable]: https://stable.release.flatcar-linux.net/amd64-usr/current/
[beta]: https://beta.release.flatcar-linux.net/amd64-usr/current/
[alpha]: https://alpha.release.flatcar-linux.net/amd64-usr/current/
[edge]: https://edge.release.flatcar-linux.net/amd64-usr/current/

After downloading your image, you should verify it with `gpg` tool. First, download the image signing key:

```sh
curl -L -O https://flatcar-linux.org/security/image-signing-key/Flatcar_Image_Signing_Key.asc
```

Next, import the public key and verify that the ID matches the website: [Flatcar Image Signing Key][signing-key]

```sh
gpg --import --keyid-format LONG Flatcar_Image_Signing_Key.asc
gpg: key 50E0885593D2DCB4: public key "Flatcar Buildbot (Official Builds) <buildbot@flatcar-linux.org>" imported
gpg: Total number processed: 1
gpg:               imported: 1  (RSA: 1)
gpg: 3 marginal(s) needed, 1 complete(s) needed, PGP trust model
gpg: depth: 0  valid:   2  signed:   0  trust: 0-, 0q, 0n, 0m, 0f, 2u
```

Now we're ready to download an image and it's signature, ending in .sig. We're using the QEMU image in this example:

```sh
curl -L -O https://stable.release.flatcar-linux.net/amd64-usr/current/flatcar_production_qemu_image.img.bz2
curl -L -O https://stable.release.flatcar-linux.net/amd64-usr/current/flatcar_production_qemu_image.img.bz2.sig
```

Verify image with `gpg` tool:

```sh
gpg --verify flatcar_production_qemu_image.img.bz2.sig
gpg: Signature made Tue Jun 23 09:39:04 2015 CEST using RSA key ID E5676EFC
gpg: Good signature from "Flatcar Buildbot (Official Builds) <buildbot@flatcar-linux.org>"
```

The `Good signature` message indicates that the file signature is valid. Go launch some machines now that we've successfully verified that this Flatcar Linux image isn't corrupt, that it was authored by Kinvolk, and wasn't tampered with in transit.
