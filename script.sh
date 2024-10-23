#!/bin/sh

## Install dependencies ##
apt-get update
apt-get install -y git build-essential

## Install VSFTPD ##
echo "Install VSFTPD"
FTP_FOLDER="$PWD/insecure-webstack/vsftpd-2.3.4-infected"
git clone https://github.com/thematrix97/insecure-webstack
make -C $FTP_FOLDER
# Deps #
mkdir -p /usr/share/empty /var/ftp/ 
useradd -d /var/ftp ftp
chown root:root /var/ftp
chmod og-w /var/ftp
# Install
sudo cp $FTP_FOLDER/vsftpd /usr/local/sbin/vsftpd
sudo cp $FTP_FOLDER/vsftpd.8 /usr/local/man/man8
sudo cp $FTP_FOLDER/vsftpd.conf.5 /usr/local/man/man5
sudo cp $FTP_FOLDER/vsftpd.conf /etc
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
echo "Done VSFTPD!"

## MySQL ##
echo "Install MySQL"
apt install -y mariadb-server
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'root';RENAME USER 'root'@'localhost' TO 'root'@'%';FLUSH PRIVILEGES;"
sudo systemctl enable mysql
sudo systemctl start mysql
echo "Done MySQL!"

## Nginx ##
apt install -y nginx
cat << EOF > /var/www/html/credentials.txt
AWS_ACCESS_KEY_ID=root
AWS_SECRET_ACCESS_KEY=mySuperSecureCredentialsNobodyCouldGuess
EOF