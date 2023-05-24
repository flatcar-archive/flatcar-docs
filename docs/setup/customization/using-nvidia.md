---
title: Using NVIDIA GPUs on Flatcar
description: How to use and customize the NVIDIA driver on Flatcar
weight: 30
---

### Installation

Flatcar Container Linux offers support for the installation and customization of NVIDIA drivers for Tesla GPU VMs on AWS and Azure.

During the initial boot, the `nvidia.service` automates hardware detection and triggers driver installation within a dedicated Flatcar developer container, ensuring a streamlined process. The current version of the installed NVIDIA driver can be found in the `/usr/share/flatcar/nvidia-metadata` file, assuming it's a vanilla installation and the version hasn't been customized (see below).

It's important to note that Flatcar Container Linux adheres strictly to NVIDIA's distribution terms, and therefore does not include pre-installed support for NVIDIA drivers. However, Flatcar simplifies the installation process by seamlessly integrating it into the first boot experience. This approach allows users to quickly and effortlessly set up the NVIDIA driver environment, aligning with NVIDIA's guidelines for driver distribution.

Since the installation is triggered after boot, the overall installation time is around 5-10 minutes. To check the installation status, use the following command:

```
# journalctl -u nvidia -f
```

Once the installation is complete, you will have access to various NVIDIA commands. To verify the installation, run the command:

```
# nvidia-smi
```

### Customization

To customize the version number of the NVIDIA driver, you can override the value in the `/etc/flatcar/nvidia-metadata` file by specifying the desired version in the `NVIDIA_DRIVER_VERSION`. However, it's important to ensure that the chosen driver version is compatible with the GPU hardware present in the instance.
E.g., for older GPUs the 460 driver series is needed because the latest drivers dropped support for them.

```
echo "NVIDIA_DRIVER_VERSION=460.106.00" | sudo tee /etc/flatcar/nvidia-metadata
sudo systemctl restart nvidia
```

**Butane Config**

```
variant: flatcar
version: 1.0.0
storage:
  files:
    - path: /etc/flatcar/nvidia-metadata
      mode: 0644
      contents:
        inline: |
          NVIDIA_DRIVER_VERSION=460.106.00
