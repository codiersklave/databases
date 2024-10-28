#!/bin/bash

docker-compose down -v
rm -rf ./primary/data/*
rm -rf ./replica1/data/*
rm -rf ./replica2/data/*
docker-compose build
docker-compose up -d

until docker exec mysql_primary sh -c 'export MYSQL_PWD=root; mysql -u root -e ";"'
do
  echo "Waiting for mysql_primary database connection..."
  sleep 4
done

priv_stmt='CREATE USER "mydb_replica1_user"@"%" IDENTIFIED BY "mydb_replica1_pwd"; GRANT REPLICATION SLAVE ON *.* TO "mydb_replica1_user"@"%"; FLUSH PRIVILEGES;'
docker exec mysql_primary sh -c "export MYSQL_PWD=root; mysql -u root -e '$priv_stmt'"

priv2_stmt='CREATE USER "mydb_replica2_user"@"%" IDENTIFIED BY "mydb_replica2_pwd"; GRANT REPLICATION SLAVE ON *.* TO "mydb_replica2_user"@"%"; FLUSH PRIVILEGES;'
docker exec mysql_primary sh -c "export MYSQL_PWD=root; mysql -u root -e '$priv2_stmt'"

until docker-compose exec mysql_replica1 sh -c 'export MYSQL_PWD=root; mysql -u root -e ";"'
do
  echo "Waiting for mysql_replica1 database connection..."
  sleep 4
done

until docker-compose exec mysql_replica2 sh -c 'export MYSQL_PWD=root; mysql -u root -e ";"'
do
  echo "Waiting for mysql_replica2 database connection..."
  sleep 4
done  

MS_STATUS=`docker exec mysql_primary sh -c 'export MYSQL_PWD=root; mysql -u root -e "SHOW MASTER STATUS"'`
CURRENT_LOG=`echo $MS_STATUS | awk '{print $6}'`
CURRENT_POS=`echo $MS_STATUS | awk '{print $7}'`

start_replica1_stmt="CHANGE MASTER TO MASTER_HOST='mysql_primary',MASTER_USER='mydb_replica1_user',MASTER_PASSWORD='mydb_replica1_pwd',MASTER_LOG_FILE='$CURRENT_LOG',MASTER_LOG_POS=$CURRENT_POS; START SLAVE;"
start_replica1_cmd='export MYSQL_PWD=root; mysql -u root -e "'
start_replica1_cmd+="$start_replica1_stmt"
start_replica1_cmd+='"'
docker exec mysql_replica1 sh -c "$start_replica1_cmd"

docker exec mysql_replica1 sh -c "export MYSQL_PWD=root; mysql -u root -e 'SHOW SLAVE STATUS \G'"

start_replica2_stmt="CHANGE MASTER TO MASTER_HOST='mysql_primary',MASTER_USER='mydb_replica2_user',MASTER_PASSWORD='mydb_replica2_pwd',MASTER_LOG_FILE='$CURRENT_LOG',MASTER_LOG_POS=$CURRENT_POS,MASTER_DELAY=5; START SLAVE;"
start_replica2_cmd='export MYSQL_PWD=root; mysql -u root -e "'
start_replica2_cmd+="$start_replica2_stmt"
start_replica2_cmd+='"'
docker exec mysql_replica2 sh -c "$start_replica2_cmd"

docker exec mysql_replica2 sh -c "export MYSQL_PWD=root; mysql -u root -e 'SHOW SLAVE STATUS \G'"

docker exec mysql_primary sh -c 'export MYSQL_PWD=root; mysql -u root < "/var/lib/files/init.sql";'

#docker exec mysql_primary sh -c '
#  export MYSQL_PWD=root;
#  for sql_file in /var/lib/files/*.sql; do
#    mysql -u root < "$sql_file";
#  done
#'
