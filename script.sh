#!/bin/sh

## Install dependencies ##
apt-get update
apt-get install -y git build-essential

## Install VSFTPD ##
echo "Install VSFTPD"
FTP_FOLDER="$PWD/Insecure-WebStack/vsftpd-2.3.4-infected"
git clone https://github.com/TheMatrix97/Insecure-WebStack.git
make -C $FTP_FOLDER
# Deps #
mkdir -p /usr/share/empty /var/ftp/ 
/sbin/useradd -d /var/ftp ftp
chown root:root /var/ftp
chmod og-w /var/ftp
# Install
cp $FTP_FOLDER/vsftpd /usr/local/sbin/vsftpd
cp $FTP_FOLDER/vsftpd.8 /usr/local/man/man8
cp $FTP_FOLDER/vsftpd.conf.5 /usr/local/man/man5
cp $FTP_FOLDER/vsftpd.conf /etc
# Set password to FTP user
echo "ftp:supersecret" | /sbin/chpasswd
cat << EOF > /etc/systemd/system/vsftpd.service
[Unit]
Description=vsftpd FTP Service
After=network.target

[Service]
ExecStart=/usr/local/sbin/vsftpd /etc/vsftpd.conf
Type=service
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload && systemctl enable vsftpd --now
rm -rf $PWD/Insecure-WebStack

echo "Done VSFTPD!"

## MySQL ##
echo "Install MySQL"
apt install -y mariadb-server
systemctl enable mysql --now
echo "Config MySQL..."
sleep 5
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'root';RENAME USER 'root'@'localhost' TO 'root'@'%';FLUSH PRIVILEGES;"
sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mysql/mariadb.conf.d/50-server.cnf
cat << EOF > /etc/mysql/conf.d/90-max-connections.cnf
[mysqld]
max_connections = 999999999
max_connect_errors = 999999999
EOF
systemctl restart mysql
echo "Done MySQL!"

## Nginx ##
apt install -y nginx
cat << EOF > /var/www/html/README
AWS_ACCESS_KEY_ID=root
AWS_SECRET_ACCESS_KEY=mySuperSecureCredentialsNobodyCouldGuess
EOF