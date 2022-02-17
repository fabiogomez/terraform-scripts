#!/usr/bin/env bash
set -x
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
export PATH="$PATH:/usr/bin"
MYSQLPASS="5TQRRWDSFF98"
DBNAME="test_prod_12"
sudo apt-get update
pwd

#install mysql and aws cli using ansible
sudo apt --assume-yes install ansible
sudo git clone https://github.com/fabiogomez/terraform-scripts.git
sudo cp terraform-scripts/aws/01_mysql_backup/ansible/hosts /etc/ansible/
sudo ansible-playbook  terraform-scripts/aws/01_mysql_backup/ansible/main.yml

#download backup and restore in database
sudo wget -q  https://dmdomus30dias.s3.us-west-2.amazonaws.com/2020/202202/domus_gateways-UTF8-20220201-010130.sql.tar.gz
sudo tar -xvf domus_gateways-UTF8-20220201-010130.sql.tar.gz
rm -rf domus_gateways-UTF8-20220201-010130.sql.tar.gz
sudo mysql -u root -p$MYSQLPASS  -e "CREATE DATABASE $DBNAME CHARACTER SET utf8 COLLATE utf8_general_ci;"
sudo mysql -u root -p$MYSQLPASS  -e "SET GLOBAL log_bin_trust_function_creators = 1;"
sudo mysql  -u root -p$MYSQLPASS  $DBNAME<  202202/domus_gateways-UTF8-20220201-010130.sql
sudo touch report.txt
mysql -u root -p$MYSQLPASS  -e "use $DBNAME; SHOW TABLES " >> report.txt
mysql -u root -p$MYSQLPASS  -e "SELECT count(*) from $DBNAME.invoices;" >> report.txt

# sends the results to email