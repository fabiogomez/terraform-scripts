#!/usr/bin/env bash

#declare variables
DATE_BACKUP=`date -d yesterday +%Y%m%d`
#arrays with dbs info
DBNAMES=("prod_12_test" "nd_test" "gateways_test")
FILES_PRE=("prod_12-UTF8-$DATE_BACKUP" "nd2-UTF8-$DATE_BACKUP" "domus_gateways-UTF8-$DATE_BACKUP" )
TABLES_VERIFY=("inmuebles" "opportunities" "invoices")
MYSQLPASS="5TQRRWDSFF98"
DBNAME="test_gateways"
TABLE_TEST="invoices"
CARPETA=`date +%Y%m`
clear

#Restore all databases
sudo touch report.txt
array_length=${#DBNAMES[*]}

for ((i=0; i<=$(( $array_length)); i++))
do
    #download backup and extract
    NAMEFILE_TAR=`aws s3 ls s3://dmdomus30dias/2020/$CARPETA/ | awk '{print $4}' | grep "${FILES_PRE[$i]}" | head -1`
    sudo aws s3 cp s3://dmdomus30dias/2020/$CARPETA/$NAMEFILE_TAR .
    sudo tar -xvf $NAMEFILE_TAR
    rm -rf $NAMEFILE_TAR
    NAMEFILE=`ls $CARPETA`


    #import database
    sudo mysql -u root -p$MYSQLPASS  -e "CREATE DATABASE IF NOT EXISTS ${DBNAMES[$i]} CHARACTER SET utf8 COLLATE utf8_general_ci;"
    sudo mysql -u root -p$MYSQLPASS  -e "SET GLOBAL log_bin_trust_function_creators = 1;"
    sudo mysql  -u root -p$MYSQLPASS  ${DBNAMES[$i]} <  "$CARPETA/$NAMEFILE"

    #delete folder and file
    rm -rf $CARPETA/$NAMEFILE
    
    #export result    
    echo "RESULTADO BASE DE DATOS ${DBNAMES[$i]} \n\r" >> report.txt
    echo "TABLAS: \n\r" >> report.txt
    mysql -u root -p$MYSQLPASS  -e "use ${DBNAMES[$i]}; SHOW TABLES " | awk '{new_var=$1" \\n\\r";print new_var}' >> report.txt
    echo "\n\rCANTIDAD TABLA ${$TABLES_VERIFY[$i]} \n\r" >> report.txt
    mysql -u root -p$MYSQLPASS -e "SELECT count(*) from ${DBNAMES[$i]}.${$TABLES_VERIFY[$i]};" >> report.txt
    mysql -u root -p$MYSQLPASS -e "DROP DATABASE ${DBNAMES[$i]};"

    
done

# sends the results to email
sudo aws ses send-raw-email --cli-binary-format raw-in-base64-out  --raw-message file://terraform-scripts/aws/01_mysql_backup/message.json