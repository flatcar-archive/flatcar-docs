---
title: Butane Config Examples
linktitle: Examples
weight: 20
---

Here you can find a bunch of simple examples for using Butane configs, with some explanations about what they do. The examples here are in no way comprehensive, for a full list of all the available fields check out the [Butane specification][spec].

## Users and groups

```yaml
variant: flatcar
version: 1.0.0
passwd:
  users:
    - name: core
      password_hash: "$6$43y3tkl..."
      ssh_authorized_keys:
        - ssh-rsa ABCLKJASD...
```

This example modifies the existing `core` user, giving it a known password hash (this will enable login via password), and setting its ssh key.

```yaml
variant: flatcar
version: 1.0.0
passwd:
  users:
    - name: user1
      password_hash: "$6$43y3tkl..."
      ssh_authorized_keys:
        - key1
        - key2
    - name: user2
      ssh_authorized_keys:
        - key3
```

This example will create two users, `user1` and `user2`. The first user has a password set and two ssh public keys authorized to log in as the user. The second user doesn't have a password set (so log in via password will be disabled), but have one ssh key.

```yaml
variant: flatcar
version: 1.0.0
passwd:
  users:
    - name: user1
      password_hash: "$6$43y3tkl..."
      ssh_authorized_keys:
        - key1
      home_dir: /home/user1
      no_create_home: true
      groups:
        - wheel
        - plugdev
      shell: /bin/bash
```

This example creates one user, `user1`, with the password hash `$6$43y3tkl...`, and sets up one ssh public key for the user. The user is also given the home directory `/home/user1`, but it's not created, the user is added to the `wheel` and `plugdev` groups, and the user's shell is set to `/bin/bash`.

### Generating a password hash

If you choose to use a password instead of an SSH key, generating a safe hash is extremely important to the security of your system. Simplified hashes like md5crypt are trivial to crack on modern GPU hardware. Here are a few ways to generate secure hashes:

```
# On Debian/Ubuntu (via the package "whois")
mkpasswd --method=SHA-512 --rounds=4096

# OpenSSL (note: this will only make md5crypt.  While better than plantext it should not be considered fully secure)
openssl passwd -1

# Python
python -c "import crypt,random,string; print(crypt.crypt(input('clear-text password: '), '\$6\$' + ''.join([random.choice(string.ascii_letters + string.digits) for _ in range(16)])))"

# Perl (change password and salt values)
perl -e 'print crypt("password","\$6\$SALT\$") . "\n"'
```

Using a higher number of rounds will help create more secure passwords, but given enough time, password hashes can be reversed.  On most RPM based distributions there is a tool called mkpasswd available in the `expect` package, but this does not handle "rounds" nor advanced hashing algorithms.

## Storage and files

### Files

```yaml
variant: flatcar
version: 1.0.0
storage:
  files:
    - path: /opt/file
      contents:
        inline: Hello, world!
      mode: 0644
      user:
        id: 500
      group:
        id: 501
```

This example creates a file at `/opt/file` with the contents `Hello, world!`, permissions 0644 (so readable and writable by the owner, and only readable by everyone else), and the file is owned by user uid 500 and gid 501.

```yaml
variant: flatcar
version: 1.0.0
storage:
  files:
    - path: /opt/file2
      contents:
          source: http://example.com/file2
          compression: gzip
          verification:
            hash: sha512-4ee6a9d20cc0e6c7ee187daffa6822bdef7f4cebe109eff44b235f97e45dc3d7a5bb932efc841192e46618f48a6f4f5bc0d15fd74b1038abf46bf4b4fd409f2e
      mode: 0644
```

This example fetches a gzip-compressed file from `http://example.com/file2`, makes sure that it matches the provided sha512 hash, and writes it decompressed to `/opt/file2`.

### Filesystems

```yaml
variant: flatcar
version: 1.0.0
storage:
  filesystems:
    - device: /dev/disk/by-partlabel/ROOT
      format: btrfs
      wipe_filesystem: true
      label: ROOT
```

This example formats the root filesystem to be `btrfs`.

## systemd units

```yaml
variant: flatcar
version: 1.0.0
systemd:
  units:
    - name: etcd-member.service
      dropins:
        - name: conf1.conf
          contents: |
            [Service]
            Environment="ETCD_NAME=infra0"
```

This example adds a drop-in for the `etcd-member` unit, setting the name for etcd to `infra0` with an environment variable. More information on systemd dropins can be found in [the docs][dropins].

```yaml
variant: flatcar
version: 1.0.0
systemd:
  units:
    - name: hello.service
      enabled: true
      contents: |
        [Unit]
        Description=A hello world unit!

        [Service]
        Type=oneshot
        ExecStart=/usr/bin/echo "Hello, World!"

        [Install]
        WantedBy=multi-user.target
```

This example creates a new systemd unit called hello.service, enables it so it will run on boot, and defines the contents to simply echo `"Hello, World!"`.

## systemd user units

```yaml
variant: flatcar
version: 1.0.0
storage:
  directories:
    - path: /etc/systemd/user/default.target.wants
      mode: 0755
  files:
    - path: /etc/systemd/user/hello.service
      mode: 0644
      contents:
        inline: |
          [Unit]
          Description=A hello world unit!

          [Service]
          Type=oneshot
          ExecStart=/usr/bin/echo "Hello, World!"

          [Install]
          WantedBy=default.target
  links:
    - path: /etc/systemd/user/default.target.wants/hello.service
      target: /etc/systemd/user/hello.service
      hard: false
```

This example creates a new systemd user unit called `hello.service`, enables it with an explicit symlink (workaround for Ignition) so it will run on boot, and defines the contents to simply echo `"Hello, World!"`.

## networkd units

```yaml
variant: flatcar
version: 1.0.0
storage:
  files:
    - path: /etc/systemd/network/static.network
      contents:
        inline: |
          [Match]
          Name=enp2s0

          [Network]
          Address=192.168.0.15/24
          Gateway=192.168.0.1
```

This example creates a networkd unit to set the IP address on the `enp2s0` interface to the static address `192.168.0.15/24`, and sets an appropriate gateway. More information on networkd units in Flatcar Container Linux can be found in [the docs][networkd].


[spec]: ./configuration
[dropins]: ../../setup/systemd/drop-in-units
[networkd]: ../../setup/customization/network-config-with-networkd
