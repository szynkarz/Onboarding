#!/bin/bash
yum update -y
amazon-linux-extras install nginx1 -y

rpm --install https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-7.17.8-x86_64.rpm

cat > /etc/filebeat/filebeat.yml << "EOF"
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /var/log/nginx/access.log
setup.template.enabled: false
filebeat.config.modules:
  path: ${path.config}/modules.d/*.yml
  reload.enabled: true
filebeat.modules:
- module: nginx
  access:
    enabled: true
output.logstash:
  enabled: true
  hosts: ["logstash.elk.internal:5044"]
EOF


systemctl enable nginx
systemctl start nginx
filebeat modules enable nginx
systemctl enable filebeat
systemctl start filebeat

