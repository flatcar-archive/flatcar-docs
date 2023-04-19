---
title: Running Flatcar Container Linux with AWS EC2 Container Service
linktitle: Using AWS ECS
description: How to setup AWS ECS clusters using Flatcar.
weight: 30
aliases:
    - ../../os/booting-on-ecs
    - ../../clusters/management/booting-on-ecs
---

[Amazon EC2 Container Service (ECS)][aws-ecs] is a container management service which provides a set of APIs for scheduling container workloads across EC2 clusters. It supports Flatcar Container Linux with Docker containers.

Your Flatcar Container Linux machines communicate with ECS via an agent. The agent interacts with Docker to start new containers and gather information about running containers.

## Set up a new cluster

When booting your [Flatcar Container Linux Machines on EC2][boot-ec2], configure the ECS agent to be started via [Ignition][ignition-docs].

Be sure to change `ECS_CLUSTER` to the cluster name you've configured via the ECS CLI or leave it empty for the default. Here's a full config example:

```yaml
variant: flatcar
version: 1.0.0
storage:
  files:
    - path: /var/lib/iptables/rules-save
      mode: 0644
      contents:
        inline: |
          *nat
          -A PREROUTING -d 169.254.170.2/32 -p tcp -m tcp --dport 80 -j DNAT --to-destination 127.0.0.1:51679
          -A OUTPUT -d 169.254.170.2/32 -p tcp -m tcp --dport 80 -j REDIRECT --to-ports 51679
          COMMIT
    - path: /etc/sysctl.d/localnet.conf
      mode: 0644
      contents:
        inline: |
          net.ipv4.conf.all.route_localnet=1

systemd:
 units:
   - name: iptables-restore.service
     enabled: true
   - name: systemd-sysctl.service
     enabled: true
   - name: amazon-ecs-agent.service
     enabled: true
     contents: |
       [Unit]
       Description=AWS ECS Agent
       Documentation=https://docs.aws.amazon.com/AmazonECS/latest/developerguide/
       Requires=docker.socket
       After=docker.socket

       [Service]
       Environment=ECS_CLUSTER=your_cluster_name
       Environment=ECS_LOGLEVEL=info
       Environment=ECS_VERSION=latest
       Restart=on-failure
       RestartSec=30
       RestartPreventExitStatus=5
       SyslogIdentifier=ecs-agent
       ExecStartPre=-/bin/mkdir -p /var/log/ecs /var/ecs-data /etc/ecs
       ExecStartPre=-/usr/bin/touch /etc/ecs/ecs.config
       ExecStartPre=-/usr/bin/docker kill ecs-agent
       ExecStartPre=-/usr/bin/docker rm ecs-agent
       ExecStartPre=/usr/bin/docker pull amazon/amazon-ecs-agent:${ECS_VERSION}
       ExecStart=/usr/bin/docker run \
           --name ecs-agent \
           --env-file=/etc/ecs/ecs.config \
           --volume=/var/run/docker.sock:/var/run/docker.sock \
           --volume=/var/log/ecs:/log \
           --volume=/var/ecs-data:/data \
           --volume=/sys/fs/cgroup:/sys/fs/cgroup:ro \
           --volume=/run/docker/execdriver/native:/var/lib/docker/execdriver/native:ro \
           --publish=127.0.0.1:51678:51678 \
           --publish=127.0.0.1:51679:51679 \
           --env=ECS_AVAILABLE_LOGGING_DRIVERS='["awslogs","json-file","journald","logentries","splunk","syslog"]' \
           --env=ECS_ENABLE_TASK_IAM_ROLE=true \
           --env=ECS_ENABLE_TASK_IAM_ROLE_NETWORK_HOST=true \
           --env=ECS_LOGFILE=/log/ecs-agent.log \
           --env=ECS_LOGLEVEL=${ECS_LOGLEVEL} \
           --env=ECS_DATADIR=/data \
           --env=ECS_CLUSTER=${ECS_CLUSTER} \
           amazon/amazon-ecs-agent:${ECS_VERSION}

       [Install]
       WantedBy=multi-user.target
```

The example above pulls the latest official Amazon ECS agent container from the Docker Hub when the machine starts. If you ever need to update the agent, it’s as simple as restarting the amazon-ecs-agent service or the Flatcar Container Linux machine.

If you want to configure SSH keys in order to log in, mount disks or configure other options, see the [Butane config documentation][butane-configs].

For more information on using ECS, check out the [official Amazon documentation][ecs-docs].

[aws-ecs]: http://aws.amazon.com/ecs/
[boot-ec2]: ../../installing/cloud/aws-ec2
[butane-configs]: ../../provisioning/config-transpiler
[ignition-docs]: ../../provisioning/ignition
[ecs-docs]: http://aws.amazon.com/documentation/ecs/
