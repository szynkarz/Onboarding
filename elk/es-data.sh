#!/bin/bash
yum update -y
rpm --install https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.17.8-x86_64.rpm

echo "
cluster.name: elk-cluster
node.name: data
bootstrap.memory_lock: true
network.host: "0.0.0.0"
discovery.seed_hosts: ["es-master.elk.internal", "es-data.elk.internal"]
cluster.initial_master_nodes: ["master"]
xpack.security.enabled: false
" >> /etc/elasticsearch/elasticsearch.yml

systemctl enable elasticsearch
systemctl start elasticsearch