#!/bin/bash
apt update
apt install -y apache2 php mysql-server php-mysql

systemctl enable apache2
systemctl start apache2

mkdir -p /var/www/html

cat > /etc/apache2/sites-available/wordpress.conf << 'EOF'
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

mount -t nfs4 -o  nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport  ${EFS}:/ /var/www/html/

cd /var/www/html
cp wp-config-sample.php wp-config.php

sed -i "s/database_name_here/${DB_NAME}/" wp-config.php
sed -i "s/username_here/${DB_USER}/" wp-config.php
sed -i "s/password_here/${DB_PASSWORD}/" wp-config.php
sed -i "s/localhost/${MYSQL_HOST}/" wp-config.php

SALTS=$(curl -s https://api.wordpress.org/secret-key/1.1/salt/)
sed -i "/AUTH_KEY/,/NONCE_SALT/d" wp-config.php
echo "$SALTS" >> wp-config.php
systemctl restart apache2