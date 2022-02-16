#!/usr/bin/env bash
set -x
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
export PATH="$PATH:/usr/bin"
sudo apt-get update
sudo apt-get install mariadb-server
sudo mysql -e "UPDATE mysql.user SET Password = PASSWORD('rinrinrenacuajo') WHERE User = 'root'"
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

