#!/bin/bash
yum update -y
rpm --install https://artifacts.elastic.co/downloads/logstash/logstash-7.17.8-x86_64.rpm

cat > /etc/logstash/conf.d/logstash.conf << 'EOF'
input {
  beats {
    port => 5044
    host => "0.0.0.0"
  }
}

output {
  elasticsearch {
    hosts => ["es-master.elk.internal:9200", "es-data.elk.internal:9200"]
    index => "%{[@metadata][beat]}-%{[@metadata][version]}" 
    action => "create"
  }
}
EOF

systemctl enable logstash
systemctl start logstash

