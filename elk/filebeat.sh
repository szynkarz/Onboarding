#!/bin/bash
yum update -y
amazon-linux-extras install nginx1 -y
systemctl enable nginx
systemctl start nginx

rpm --install https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-7.17.8-x86_64.rpm

echo "
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
" > /etc/filebeat/filebeat.yml

filebeat modules enable nginx
systemctl enable filebeat
systemctl filebeat start

