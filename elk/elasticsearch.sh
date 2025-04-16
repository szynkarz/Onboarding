#!/bin/bash
# Update system packages
yum update -y

# Import Elasticsearch GPG key
rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch

# Install Elasticsearch and Kibana
yum install -y --enablerepo=elasticsearch elasticsearch kibana

echo "
cluster.name: elk-cluster
path.data: /var/lib/elasticsearch
path.logs: /var/log/elasticsearch
network.host: 0.0.0.0
http.port: 9200
discovery.type: single-node
xpack.license.self_generated.type: basic" >> /etc/elasticsearch/elasticsearch.yml

# Install Metricbeat
yum install -y metricbeat
cat > /etc/metricbeat/metricbeat.yml << 'EOF'
metricbeat.modules:
- module: elasticsearch
  metricsets:
    - node
    - node_stats
    - cluster_stats
    - index
    - index_recovery
    - index_summary
    - shard
  period: 10s
  hosts: ["http://localhost:9200"]

- module: system
  metricsets:
    - cpu
    - load
    - memory
    - network
    - process
    - process_summary
    - uptime
    - socket_summary
  period: 10s
  cpu.metrics: ["percentages"]
  core.metrics: ["percentages"]
  
output.elasticsearch:
  hosts: ["localhost:9200"]
  
setup.kibana:
  host: "localhost:5601"
EOF

# Setup Metricbeat dashboards and start the service
metricbeat setup
systemctl enable metricbeat
systemctl start metricbeat

# Configure Kibana
cat > /etc/kibana/kibana.yml << 'EOF'
server.port: 5601
server.host: "0.0.0.0"
elasticsearch.hosts: ["http://localhost:9200"]
server.name: "kibana"
xpack.monitoring.ui.container.elasticsearch.enabled: true
xpack.reporting.encryptionKey: "a_random_string_of_32_or_more_characters"
xpack.security.encryptionKey: "another_random_string_of_32_or_more_characters"
EOF

# Increase memory for Node.js (used by Kibana)
cat > /etc/default/kibana << 'EOF'
NODE_OPTIONS="--max-old-space-size=1024"
EOF

# Start and enable Elasticsearch service
systemctl daemon-reload
systemctl enable elasticsearch.service
systemctl start elasticsearch.service

# Wait for Elasticsearch to start
echo "Waiting for Elasticsearch to start..."
retries=0
max_retries=30
until curl -s http://localhost:9200 > /dev/null || [ $retries -eq $max_retries ]; do
    sleep 10
    ((retries++))
    echo "Waiting for Elasticsearch... ($retries/$max_retries)"
done

if [ $retries -eq $max_retries ]; then
    echo "Elasticsearch failed to start in time"
    exit 1
fi

# Explicitly set basic license
curl -X POST "http://localhost:9200/_license/start_basic?acknowledge=true" -H 'Content-Type: application/json'

# Start and enable Kibana service
systemctl enable kibana.service
systemctl start kibana.service

# Wait for Kibana to be available
echo "Waiting for Kibana to start..."
retries=0
max_retries=30
until curl -s http://localhost:5601/api/status > /dev/null || [ $retries -eq $max_retries ]; do
    sleep 10
    ((retries++))
    echo "Waiting for Kibana... ($retries/$max_retries)"
done

# echo "Installation completed at $(date)"
# echo "Kibana should be available at http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):5601"