#!/bin/bash

echo $UPASS
if [[ -z "$UPASS" ]]; then
    echo 'User sftp password in not set, default value will be used'
    UPASS="password123"
fi


#1 create folder for sftp share
sudo mkdir -p /var/sftp
sudo chown root:root /var/sftp

#2 create a SFTP user with password
sudo useradd -p $(openssl passwd -1 $UPASS) -u 1999 usftp

# todo: mkdir -p /home/usftp/.ssh usar chave

sudo mkdir -p /var/sftp/usftp
sudo chown usftp:usftp /var/sftp/usftp

#4 add this user as sftp user
rm mysshd_config

echo 'Match User usftp 
ForceCommand internal-sftp 
PasswordAuthentication yes 
ChrootDirectory /var/sftp 
PermitTunnel no 
AllowAgentForwarding no 
AllowTcpForwarding no 
X11Forwarding no' > mysshd_config

sudo grep -rnw '/etc/ssh/sshd_config' -e 'usftp'

if [ $? -eq 1 ]
then
    cat mysshd_config | sudo tee -a /etc/ssh/sshd_config 
else
  echo "Configuration for sftp already exists"
fi
#5 restart sftp
sudo systemctl restart sshd
[ $? -eq 0 ] && echo "Restart was successful" || echo "Restart failed"

# mount the share 

