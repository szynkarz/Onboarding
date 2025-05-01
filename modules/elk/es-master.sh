#!/bin/bash
yum update -y
rpm --install https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.17.8-x86_64.rpm

echo "
cluster.name: elk-cluster
node.name: ${NODE_NAME}
bootstrap.memory_lock: true
network.host: "0.0.0.0"
discovery.seed_hosts: [${SEED_HOSTS}]
cluster.initial_master_nodes: [${INITIAL_MASTER_NODES}]

xpack.security.enabled: false
" >> /etc/elasticsearch/elasticsearch.yml

systemctl enable elasticsearch
systemctl start elasticsearch