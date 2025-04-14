#!/bin/bash
yum update
sudo yum install -y httpd amazon-efs-utils
sudo amazon-linux-extras install -y mariadb10.5 php8.2
systemctl enable httpd
systemctl start httpd

mkdir -p /var/www/html
sudo mount -t efs -o tls fs-05a8712da9c2d7fb1:/ /var/www/html

cat > /etc/httpd/sites-available/wordpress.conf << 'EOF'
<VirtualHost *:80>
    DocumentRoot /var/www/html
    <Directory /var/www/html/>
        Options FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF

wget https://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz

cp -R wordpress/* /var/www/html/
rm -rf wordpress latest.tar.gz

cd /var/www/html
cp wp-config-sample.php wp-config.php

sed -i "s/database_name_here/${DB_NAME}/" wp-config.php
sed -i "s/username_here/${DB_USER}/" wp-config.php
sed -i "s/password_here/${DB_PASSWORD}/" wp-config.php
sed -i "s/localhost/${MYSQL_HOST}/" wp-config.php

echo "\$_SERVER['HTTPS']='on';" >> wp-config.php 

SALTS=$(curl -s https://api.wordpress.org/secret-key/1.1/salt/)
sed -i "/AUTH_KEY/,/NONCE_SALT/d" wp-config.php
echo "$SALTS" >> wp-config.php
systemctl restart httpd