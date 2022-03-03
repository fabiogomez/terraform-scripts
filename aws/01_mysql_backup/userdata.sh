#!/usr/bin/env bash
set -x
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
export PATH="$PATH:/usr/bin"



#install mysql and aws cli using ansible
sudo apt-get update
sudo apt --assume-yes install ansible
sudo git clone https://github.com/fabiogomez/terraform-scripts.git
sudo cp terraform-scripts/aws/01_mysql_backup/ansible/hosts /etc/ansible/
sudo ansible-playbook  terraform-scripts/aws/01_mysql_backup/ansible/main.yml

#execute restore
chmod +x terraform-scripts/aws/01_mysql_backup/scripts/restore.sh
/terraform-scripts/aws/01_mysql_backup/scripts/restore.sh
