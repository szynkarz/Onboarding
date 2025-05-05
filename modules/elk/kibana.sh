#!/bin/bash
yum update -y
amazon-linux-extras install nginx1 -y
rpm --install https://artifacts.elastic.co/downloads/kibana/kibana-7.17.8-x86_64.rpm

echo "
server.host: "0.0.0.0"
server.port: 5601
server.name: "kibana"
server.publicBaseUrl: "https://kibana.shynkaruk.me"
elasticsearch.hosts: ["http://es-master.elk.internal:9200", "http://es-data.elk.internal:9200"]
xpack.monitoring.ui.container.elasticsearch.enabled: true
xpack.reporting.encryptionKey: "a_random_string_of_32_or_more_characters"
xpack.security.encryptionKey: "another_random_string_of_32_or_more_characters"
elasticsearch.requestTimeout: 300
" >> /etc/kibana/kibana.yml

echo "
NODE_OPTIONS="--max-old-space-size=1024"
" >> /etc/default/kibana

cat > /etc/nginx/conf.d/kibana.conf << 'EOF'
server {
    listen 80;
    server_name kibana.shynkaruk.me;

    location / {
        auth_request /oauth2/auth;
        error_page 401 = /oauth2/sign_in;
        proxy_pass http://localhost:5601;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
    location /oauth2/ {
        proxy_pass       http://localhost:4180;
        proxy_set_header Host                    $host;
        proxy_set_header X-Real-IP               $remote_addr;
        proxy_set_header X-Scheme                $scheme;
        proxy_set_header X-Auth-Request-Redirect $scheme://$host$request_uri;
        }
}
EOF

systemctl daemon-reload
systemctl enable kibana
systemctl start kibana
systemctl enable nginx
systemctl start nginx

wget https://github.com/oauth2-proxy/oauth2-proxy/releases/download/v7.8.2/oauth2-proxy-v7.8.2.linux-amd64.tar.gz
tar -xf oauth2-proxy-v7.8.2.linux-amd64.tar.gz
cd oauth2-proxy-v7.8.2.linux-amd64

./oauth2-proxy \
--provider github \
--client-id "Ov23liOeLdzZmrrYR0oC" \
--client-secret  "9588a4f5706920f27152949d95e31dfa686aae91" \
--upstream "http://localhost" \
--http-address "http://localhost:4180" \
--cookie-name "_oauth2_proxy" \
--cookie-secret "a_random_string_of_32_or_more_ch" \
--email-domain "*" \
--redirect-url "https://kibana.shynkaruk.me/oauth2/callback"

