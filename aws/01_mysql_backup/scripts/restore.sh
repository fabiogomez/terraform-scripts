#!/usr/bin/env bash

#declare variables
DATE_BACKUP=`date -d yesterday +%Y%m%d`
DATE_RESTORE=`date +%Y%m%d`
#arrays with dbs info
DBNAMES=("gateways_test" "prod_12_test" "nd_test")
FILES_PRE=("domus_gateways-UTF8-$DATE_BACKUP" "prod_12-UTF8-$DATE_BACKUP" "nd2-UTF8-$DATE_BACKUP")
TABLES_VERIFY=("invoices" "inmuebles" "opportunities" )
MYSQLPASS="5TQRRWDSFF98"
DBNAME="test_gateways"
TABLE_TEST="invoices"
CARPETA=`date +%Y%m`
clear

#Restore all databases
sudo touch report.txt
array_length=${#DBNAMES[*]}

for ((i=0; i<$(( $array_length)); i++))
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
    sudo mysql  -u root -p$MYSQLPASS  ${DBNAMES[$i]} <  "$CARPETA/$NAMEFILE" > /dev/null 

    #delete folder and file
    rm -rf $CARPETA/$NAMEFILE
    
    #export result    
    echo "RESULTADO BASE DE DATOS ${DBNAMES[$i]} " >> report.txt
    echo "TABLAS: " >> report.txt
    mysql -u root -p$MYSQLPASS  -e "use ${DBNAMES[$i]}; SHOW TABLES " | awk '{new_var=$1" ok";print new_var}' >> report.txt
    echo "CANTIDAD TABLA ${TABLES_VERIFY[$i]} " >> report.txt 
    mysql -u root -p$MYSQLPASS -e "SELECT count(*) from ${DBNAMES[$i]}.${TABLES_VERIFY[$i]};" >> report.txt
    mysql -u root -p$MYSQLPASS -e "DROP DATABASE ${DBNAMES[$i]};"

    
done

# sends the results to email
mkdir reporte
cp /var/log/user-data.log /reporte
cp /report.txt /reporte
tar -czvf reporte.tar.gz /reporte
KEY_REPORT_FILE_S3="2020/$CARPETA/reports/report-$DATE_RESTORE.tar.gz"
sudo aws s3 cp reporte.tar.gz s3://dmdomus30dias/$KEY_REPORT_FILE_S3 --acl public-read
echo '{"Data": "From: notifications@domus.la\nTo: desarrollo@domus.la\nSubject:REPORT RESTORE DATABASE\nMIME-Version: 1.0\nContent-type: Multipart/Mixed; boundary=\"NextPart\"\n\n--NextPart\nContent-Type: text/plain\n\nTHE PROCESS OF BACKUP FINISHED PLEASE GET INFO HERE https://dmdomus30dias.s3.us-west-2.amazonaws.com/'$(echo $KEY_REPORT_FILE_S3)' .\n\n--NextPart"}' > message.json
sudo aws ses send-raw-email --cli-binary-format raw-in-base64-out  --raw-message file://message.json