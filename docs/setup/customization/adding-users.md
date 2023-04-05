---
title: Adding users
description: How to create additional user accounts, either manually or with container linux configs.
weight: 10
aliases:
    - ../../os/adding-users
    - ../../clusters/customization/adding-users
---

You can create user accounts on a Flatcar Container Linux machine manually with `useradd` or via a [Butane Config][butane-config] when the machine is created.

## Add Users via Butane Configs

In your Butane Config, you can specify many [different parameters][config-spec] for each user. Here's an example:

```yaml
variant: flatcar
version: 1.0.0
passwd:
  users:
    - name: core
      ssh_authorized_keys:
        - "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDGdByTgSVHq......."
    - name: elroy
      password_hash: "$6$5s2u6/jR$un0AvWnqilcgaNB3Mkxd5yYv6mTlWfOoCYHZmfi3LDKVltj.E8XNKEcwWm..."
      ssh_authorized_keys:
        - "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDGdByTgSVHq......."
      groups: [ sudo, docker ]
```

Because `usermod` does not work to add a user to a predefined system group, you can use [systemd-userdb][systemd-userdb] to define membership. Here's the same example with userdb:

```
variant: flatcar
version: 1.0.0
passwd:
  users:
    - name: elroy
      password_hash: "$6$5s2u6/jR$un0AvWnqilcgaNB3Mkxd5yYv6mTlWfOoCYHZmfi3LDKVltj.E8XNKEcwWm..."
      ssh_authorized_keys:
        - "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDGdByTgSVHq......."
storage:
  files:
    - path: /etc/userdb/elroy:sudo.membership
      contents:
        inline: " "
    - path: /etc/userdb/elroy:docker.membership
      contents:
        inline: " "
```

## Add user manually

If you'd like to add a user manually, SSH to the machine and use the `useradd` tool. To create the user `user`, run:

```shell
sudo useradd -p "*" -U -m user1 -G sudo
```

The `"*"` creates a user that cannot login with a password but can log in via SSH key. `-U` creates a group for the user, `-G` adds the user to the existing `sudo` group and `-m` creates a home directory. If you'd like to add a password for the user, run:

```shell
$ sudo passwd user1
New password:
Re-enter new password:
passwd: password changed.
```

To assign an SSH key, run:

```shell
update-ssh-keys -u user1 -a user1 user1.pem
```

## Grant sudo Access

If you trust the user, you can grant administrative privileges using `visudo`. `visudo` checks the file syntax before actually overwriting the `sudoers` file. This command should be run as root to avoid losing sudo access in the event of a failure. Instead of editing `/etc/sudo.conf` directly you will create a new file under the `/etc/sudoers.d/` directory. When you run visudo, it is required that you specify which file you are attempting to edit with the `-f` argument:

```shell
# visudo -f /etc/sudoers.d/user1
```

Add a the line:

```text
user1 ALL=(ALL) NOPASSWD: ALL
```

Check that sudo has been granted:

```shell
# su user1
$ cat /etc/sudoers.d/user1
cat: /etc/sudoers.d/user1: Permission denied

$ sudo cat /etc/sudoers.d/user1
user1 ALL=(ALL) NOPASSWD: ALL
```

[cl-config]: ../../provisioning/config-transpiler
[config-spec]: ../../provisioning/config-transpiler/configuration
[systemd-userdb]: https://www.freedesktop.org/software/systemd/man/systemd-userdbd.service.html
