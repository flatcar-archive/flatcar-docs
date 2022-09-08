---
title: Flatcar Container Linux FIPS guide
linktitle: FIPS mode
description: Enabling FIPS mode.
weight: 20
---

FIPS stands for Federal Information Processing Standards, a set of standards issued by the National Institute of Standards and Technology (NIST). While Flatcar is not officially FIPS certified, it is possible to deploy it so that it is compliant with two of these standards:
* [FIPS 200][fips-200]
* [FIPS 140-2][fips-140-2]

# Enabling FIPS

Booting the instance with the kernel parameter `fips=1` allows the instance to operate in a FIPS 200 mode. This means the kernel will use FIPS-compliant algorithms and will enforce some security practices like RSA key [size][rsa-key-size]. It's also recommended to create the empty file `/etc/system-fips` for other software (like cryptsetup).

To confirm that FIPS mode is enabled on the Kernel, check the content of the file `/proc/sys/crypto/fips_enabled`:
```bash
$ cat /proc/sys/crypto/fips_enabled
0 # disabled
1 # enabled
```

or by inspecting boot logs:
```bash
$ journalctl --boot | grep -i "kernel: fips"
Jun 27 18:07:22 localhost kernel: fips mode: enabled
```

# Enabling OpenSSL FIPS provider

[OpenSSL][openssl] is an open-source library used for ciphering and hashing. As a library, it is widely used by programming software and third-party programs to ensure security. OpenSSL 3.0 FIPS provider is FIPS [validated][certificate] since Aug. 2022.

OpenSSL FIPS module is built by default on Flatcar but it is required to update the OpenSSL configuration to actually use this module:
```bash
openssl fipsinstall \
    -out /etc/ssl/fipsmodule.cnf \
    -module /usr/lib64/ossl-modules/fips.so
mv /etc/ssl/openssl.cnf.fips /etc/ssl/openssl.cnf
```

Once again, it's possible to check that FIPS is enabled:
```bash
$ echo "Flatcar + FIPS" | openssl sha1 -
SHA1(stdin)= ee2219bd6a234fa0e4436b475fc3b351e2dc85a0
$ echo "Flatcar + FIPS" | openssl md5 -
Error setting digest C0422ACDB57F0000:error:0308010C:digital envelope routines:inner_evp_generic_fetch:unsupported:crypto/evp/evp_fetch.c:349:Global default library context, Algorithm (MD5 : 104), Properties ()C0422ACDB57F0000:error:03000086:digital envelope routines:evp_md_init_internal:initialization error:crypto/evp/digest.c:252:
```

OpenSSL FIPS module is also being used by `cryptsetup` when running in FIPS mode (detection is based on `fips` kernel parameter and `/etc/system-fips` file).

To check that cryptsetup runs in FIPS mode, it's possible to add the `--verbose` flag:
```bash
$ cryptsetup --verbose luksFormat ./volume
...
Running in FIPS mode.
Command successful.
```

_NOTE_: Formatting a LUKS device with `cryptsetup` on a non-FIPS instance will use `argon2id` as key derivation function. This algorithm is not FIPS-compliant, so it will be impossible to open the LUKS device on a FIPS instance. It is possible to have a FIPS-compatible LUKS device if it is formatted using `cryptsetup luksFormat --pbkdf=pbkdf2 ./my-volume` which is the default behavior on a Flatcar FIPS instance even if `--pbkdf=pbkdf2` is not specified.

# Ignition provisioning

The two sections above can be combined into one Ignition configuration, as follows.

Starting from 3185.0.0 with Butane config:
```yaml
# To transpile it to Ignition config:
# butane < config.yml > ignition.json
---
version: 1.0.0
variant: flatcar
kernel_arguments:
  should_exist:
    - fips=1
storage:
  files:
    - path: /etc/system-fips
    - path: /etc/ssl/openssl.cnf.fips
      mode: 0644
      contents:
        inline: |
          config_diagnostics = 1
          openssl_conf = openssl_init
          # it includes the fipsmodule configuration generated
          # by the `enable-fips.service`
          .include /etc/ssl/fipsmodule.cnf
          [openssl_init]
          providers = provider_sect
          [provider_sect]
          fips = fips_sect
          base = base_sect
          [base_sect]
          activate = 1
systemd:
  units:
    - name: enable-fips.service
      enabled: true
      contents: |
        [Unit]
        Description=Enable OpenSSL FIPS provider
        ConditionPathExists=!/etc/ssl/fipsmodule.cnf
        After=system-config.target
        [Service]
        Type=oneshot
        RemainAfterExit=yes
        ExecStart=/usr/bin/openssl fipsinstall \
          -out /etc/ssl/fipsmodule.cnf \
          -module /usr/lib64/ossl-modules/fips.so
        ExecStart=/usr/bin/mv /etc/ssl/openssl.cnf.fips /etc/ssl/openssl.cnf
        [Install]
        WantedBy=multi-user.target
```

# Troubleshooting

## SSH login does not work with OpenSSL FIPS provider

It's possible to have a SSH connection refused when OpenSSL FIPS provider is enabled. Inspecting the SSHd logs:
```bash
Jun 28 07:58:39 localhost sshd[1080]: ssh_dispatch_run_fatal: Connection from 10.0.2.2 port 40192: invalid argument [preauth]
```

In this case, it is likely that one of the `Ciphers`, defined in the `/etc/ssh/sshd_config`, is not FIPS-compliant (like `chacha20-poly1305`).


[fips-200]: https://csrc.nist.gov/publications/detail/fips/200/final
[fips-140-2]: https://csrc.nist.gov/publications/detail/fips/140/2/final
[rsa-key-size]: https://github.com/torvalds/linux/blob/941e3e7912696b9fbe3586083a7c2e102cee7a87/crypto/rsa_helper.c#L33-L37
[openssl]: https://www.openssl.org/
[certificate]: https://csrc.nist.gov/projects/cryptographic-module-validation-program/certificate/4282
