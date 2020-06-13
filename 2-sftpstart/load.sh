#!/bin/bash          

FQDN="diogofdsilvasftp.eastus.cloudapp.azure.com"
USER=azureuser
PASSWORD="P2ssw0rd2018"
SFTP_PASSWORD="password123"


sshpass -p $PASSWORD scp usercreate.sh $USER@$FQDN:/home/$USER


echo "Start SFTP Config @ $FQDN"
sshpass -p $PASSWORD ssh $USER@$FQDN export UPASS=$SFTP_PASSWORD
sshpass -p $PASSWORD ssh -tt $USER@$FQDN 'sudo -S ./usercreate.sh'

