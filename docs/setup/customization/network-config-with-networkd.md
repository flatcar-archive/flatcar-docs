---
title: Network configuration with networkd
description: How to setup static networking, turn on/off ipv4/ipv6, and debugging tips.
weight: 40
aliases:
    - ../../os/network-config-with-networkd
    - ../../clusters/customization/network-config-with-networkd
---

Flatcar Container Linux machines are preconfigured with [networking customized][notes-for-distributors] for each platform. You can write your own networkd units to replace or override the units created for each platform. This article covers a subset of networkd functionality. You can view the [full docs here](http://www.freedesktop.org/software/systemd/man/systemd-networkd.service.html).

Drop a networkd unit in `/etc/systemd/network/` or inject a unit on boot via a Butane Config. Files placed manually on the filesystem will need to reload networkd afterwards with `sudo systemctl restart systemd-networkd`. Network units injected via a Butane Config will be written to the system before networkd is started, so there are no work-arounds needed.

Let's take a look at two common situations: using a static IP and turning off DHCP.

## Static networking

To configure a static IP on `enp2s0`, create `static.network`:

```ini
[Match]
Name=enp2s0

[Network]
Address=192.168.0.15/24
Gateway=192.168.0.1
DNS=1.2.3.4
```

Place the file in `/etc/systemd/network/`. To apply the configuration, run:

```shell
sudo systemctl restart systemd-networkd
```

### Butane Config

Setting up static networking in your Butane Config can be done by writing out the network unit. Be sure to modify the `[Match]` section with the name of your desired interface, and replace the IPs:

```yaml
variant: flatcar
version: 1.0.0
storage:
  files:
    - path: /etc/systemd/network/00-eth0.network
      contents:
        inline: |
          [Match]
          Name=eth0

          [Network]
          DNS=1.2.3.4
          Address=10.0.0.101/24
          Gateway=10.0.0.1
```

## Turn off DHCP on specific interface

If you'd like to use DHCP on all interfaces except `enp2s0`, create two files. They'll be checked in lexical order, as described in the [full network docs](http://www.freedesktop.org/software/systemd/man/systemd-networkd.service.html). Any interfaces matching during earlier files will be ignored during later files.

`10-static.network`:

```ini
[Match]
Name=enp2s0

[Network]
Address=192.168.0.15/24
Gateway=192.168.0.1
DNS=1.2.3.4
```

Put your settings-of-last-resort in `20-dhcp.network`. For example, any interfaces matching `en*` that weren't matched in `10-static.network` will be configured with DHCP:

`20-dhcp.network`:

```ini
[Match]
Name=en*

[Network]
DHCP=yes
```

To apply the configuration, run `sudo systemctl restart systemd-networkd`. Check the status with `systemctl status systemd-networkd` and read the full log with `journalctl -u systemd-networkd`.

## Turn off IPv6 on specific interfaces

While IPv6 can be disabled globally at boot by appending `ipv6.disable=1` to the kernel command line, networkd supports disabling IPv6 on a per-interface basis. When a network unit's `[Network]` section has either `LinkLocalAddressing=ipv4` or `LinkLocalAddressing=no`, networkd will not try to configure IPv6 on the matching interfaces.

Note however that even when using the above option, networkd will still be expecting to receive router advertisements if IPv6 is not disabled globally. If IPv6 traffic is not being received by the interface (e.g. due to `sysctl` or `ip6tables` settings), it will remain in the `configuring` state and potentially cause timeouts for services waiting for the network to be fully configured. To avoid this, the `IPv6AcceptRA=no` option should also be set in the `[Network]` section.

A network unit file's `[Network]` section should therefore contain the following to disable IPv6 on its matching interfaces.

```ini
[Network]
LinkLocalAddressing=no
IPv6AcceptRA=no
```

## Configure static routes

Specify static routes in a systemd network unit's `[Route]` section. In this example, we create a unit file, `10-static.network`, and define in it a static route to the `172.16.0.0/24` subnet:

`10-static.network`:

```ini
[Route]
Gateway=192.168.122.1
Destination=172.16.0.0/24
```

To specify the same route in a Butane Config, create the systemd network unit there instead:

```yaml
variant: flatcar
version: 1.0.0
storage:
  files:
    - path: /etc/systemd/network/10-static.network
      contents:
        inline: |
          [Route]
          Gateway=192.168.122.1
          Destination=172.16.0.0/24
```

## Configure multiple IP addresses

To configure multiple IP addresses on one interface, we define multiple `Address` keys in the network unit. In the example below, we've also defined a different gateway for each IP address.

`20-multi_ip.network`:

```ini
[Match]
Name=eth0

[Network]
DNS=8.8.8.8
Address=10.0.0.101/24
Gateway=10.0.0.1
Address=10.0.1.101/24
Gateway=10.0.1.1
```

To do the same thing through a Butane Config:

```yaml
variant: flatcar
version: 1.0.0
storage:
  files:
    - path: /etc/systemd/network/20-multi_ip.network
      contents:
        inline: |
          [Match]
          Name=eth0

          [Network]
          DNS=8.8.8.8
          Address=10.0.0.101/24
          Gateway=10.0.0.1
          Address=10.0.1.101/24
          Gateway=10.0.1.1
```

## Debugging networkd

If you've faced some problems with networkd you can enable debug mode following the instructions below.

### Enable debugging manually

```shell
mkdir -p /etc/systemd/system/systemd-networkd.service.d/
```

Create a [Drop-In][drop-ins] `/etc/systemd/system/systemd-networkd.service.d/10-debug.conf` with following content:

```shell
[Service]
Environment=SYSTEMD_LOG_LEVEL=debug
```

And restart `systemd-networkd` service:

```shell
systemctl daemon-reload
systemctl restart systemd-networkd
journalctl -b -u systemd-networkd
```

### Enable debugging through a Butane Config

Define a [Drop-In][drop-ins] in a [Butane Linux Config][butane-configs]:

```yaml
variant: flatcar
version: 1.0.0
systemd:
  units:
    - name: systemd-networkd.service
      dropins:
        - name: 10-debug.conf
          contents: |
            [Service]
            Environment=SYSTEMD_LOG_LEVEL=debug
```

## Further reading

- [networkd full documentation](http://www.freedesktop.org/software/systemd/man/systemd-networkd.service.html)
- [Getting Started with systemd](../systemd/getting-started)
- [Reading the System Log](../debug/reading-the-system-log)

[butane-configs]: ../../provisioning/config-transpiler
[drop-ins]: ../systemd/drop-in-units
[notes-for-distributors]: ../../installing/community-platforms/notes-for-distributors
