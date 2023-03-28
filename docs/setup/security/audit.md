---
title: Setting up the Linux Auditing System
linktitle: Set up audit
description: Setting up the Linux Auditing System.
weight: 20
---

On Flatcar Container Linux `audit-rules.service` loads the audit rules to set up the logging filters for the kernel messages.
The `auditd.service` daemon to collect these logs does not run by default.

# Enabling the standard rules or custom rules

There is an ignore rule by default that suppresses the standard rules, which means that certain PAM audit messages are not shown.
It is also important to remove this default ignore rule when setting up own rules, or otherwise they will be ignored, too.
The following Butane Config will overwrite the default ignore rule:

```yaml
variant: flatcar
version: 1.0.0
storage:
  files:
    - path: /etc/audit/rules.d/99-default.rules
      overwrite: true
      contents:
        inline: |
          # custom rules may go here, can be empty to use only the standard rules
```

# Enabling auditd

In addition to the above, it may make sense to enable `auditd.service`, here a Butane Config snippet for that:

```yaml
variant: flatcar
version: 1.0.0
systemd:
  units:
    - name: auditd.service
      enabled: true
```
