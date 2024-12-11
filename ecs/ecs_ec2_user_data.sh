#!/bin/bash

echo "ECS_CLUSTER=${CLUSTER_NAME}" >> /etc/ecs/ecs.config;
echo "ECS_AWSVPC_BLOCK_IMDS=true" >> /etc/ecs/ecs.config;
echo "ECS_DISABLE_PRIVILEGED=true" >> /etc/ecs/ecs.config;
echo "ECS_ENABLE_SPOT_INSTANCE_DRAINING=true" >> /etc/ecs/ecs.config;
echo "ECS_INSTANCE_ATTRIBUTES={\"custom.placement_tag\":\"${PLACEMENT_TAG}\"}" >> /etc/ecs/ecs.config

shred -u /etc/ssh/*_key /etc/ssh/*_key.pub;

rm -rf /etc/ssh

yum remove --assumeyes -y openssh-server sudo ec2-utils ec2-instance-connect wget amazon-ssm-agent

gpasswd -d ec2-user docker;

passwd -l root;