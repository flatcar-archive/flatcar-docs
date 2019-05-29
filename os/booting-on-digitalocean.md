# Running Flatcar Linux on DigitalOcean

On Digital Ocean, users can upload Flatcar Linux as a [custom image](https://www.digitalocean.com/docs/images/custom-images/). Digital Ocean offers a [quick start guide](https://www.digitalocean.com/docs/images/custom-images/quickstart/) that walks you through the process.

The _import URL_ should be `https://<channel>.release.flatcar-linux.net/amd64-usr/<version>/flatcar_production_digitalocean_image.bin.bz2`. See the [release page](https://www.flatcar-linux.org/releases/) for version and channel history.

When starting a droplet, make sure to add an SSH key which will be used for accessing the instance.
