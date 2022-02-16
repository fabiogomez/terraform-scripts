#!/usr/bin/env bash
set -x
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
export PATH="$PATH:/usr/bin"
MYSQLPASS="5TQRRWDSFF98"
DBNAME="test_prod_12"
sudo apt-get update
sudo apt --assume-yes install ansible
sudo echo "[mysqlserver]
localhost ansible_connection=local" >> /etc/ansible/hosts
sudo echo "---
- hosts: mysqlserver
  vars:
    mysql_root_password: $MYSQLPASS
  tasks:
    - name: Add PGP key
      apt_key:
        keyserver: hkp://pgp.mit.edu:80
        id: 5072E1F5
    
    - name: Add official APT repository
      apt_repository:
        repo: 'deb http://repo.mysql.com/apt/debian/ stretch mysql-5.7'

    - name: Install mysql-server
      apt:
        name: "{{item}}"
        state: present
        update_cache: yes
        allow_unauthenticated: yes
      with_items:
        - mysql-server" > install_mysql.yml
    

sudo ansible-playbook  install_mysql.yml

sudo wget -q s3://dmdomus30dias/2020/202202/domus_gateways-UTF8-20220201-010130.sql.tar.gz
sudo tar -xvf domus_gateways-UTF8-20220201-010130.sql.tar.gz
rm -rf domus_gateways-UTF8-20220201-010130.sql.tar.gz
sudo mysql -u root -p$MYSQLPASS  -e "CREATE DATABASE $DBNAME CHARACTER SET utf8 COLLATE utf8_general_ci;"
sudo mysql -u root -p$MYSQLPASS  -e "SET GLOBAL log_bin_trust_function_creators = 1;"
sudo mysql  -u root -p$MYSQLPASS  $DBNAME<  202202/domus_gateways-UTF8-20220201-010130.sql
mysql -u root -p$MYSQLPASS  -e "use $DBNAME; SHOW TABLES $DBNAME;"   
mysql -u root -p$MYSQLPASS  -e "SELECT count(*) from $DBNAME.inmuebles;"   
    


#sudo mysql -e "UPDATE mysql.user SET Password = PASSWORD('rinrinrenacuajo') WHERE User = 'root'"
#curl "url"
#tar -xvf  "file"
#!/bin/bash

# mysql -sfu root <<EOS
# -- set root password
# UPDATE mysql.user SET Password=PASSWORD('complex_password') WHERE User='root';
# -- delete anonymous users
# DELETE FROM mysql.user WHERE User='';
# -- delete remote root capabilities
# DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
# -- drop database 'test'
# DROP DATABASE IF EXISTS test;
# -- also make sure there are lingering permissions to it
# DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
# -- make changes immediately
# FLUSH PRIVILEGES;
# EOS

