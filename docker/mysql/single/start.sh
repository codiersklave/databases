#!/bin/bash

docker-compose down -v

# Check if the first argument is 'clear-data'
if [ "$1" == "clear-data" ]; then
  echo "Clearing data directory..."
  rm -rf ./data/*
fi

docker-compose build
docker-compose up -d

until docker exec mysql_single sh -c 'export MYSQL_PWD=root; mysql -u root -e ";"'
do
  echo "Waiting for mysql_single database connection..."
  sleep 4
done

if [ "$1" == "reset" ]; then
  echo "Loading databases..."
  docker exec mysql_single sh -c '
    export MYSQL_PWD=root;
    for sql_file in /var/lib/mysql-files/*.sql; do
      echo "Loading $sql_file into mysql_single...";
      mysql -u root < "$sql_file";
    done
  '
fi

# docker exec mysql_single sh -c 'export MYSQL_PWD=root; mysql -u root < "/var/lib/files/init.sql";'
