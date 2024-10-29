# Stop and remove Docker containers, networks, and volumes
& docker-compose down -v

# Remove directories recursively
Remove-Item -Recurse -Force ./primary/data/*
Remove-Item -Recurse -Force ./replica1/data/*
Remove-Item -Recurse -Force ./replica2/data/*

# Build and start Docker containers
& docker-compose build
& docker-compose up -d

# Wait until mysql_primary is ready
while (-not (& docker exec mysql_primary sh -c 'export MYSQL_PWD=root; mysql -u root -e ";"')) {
    Write-Output "Waiting for mysql_primary database connection..."
    Start-Sleep -Seconds 4
}

# Create replication user for replica1
$priv_stmt = 'CREATE USER "mydb_replica1_user"@"%" IDENTIFIED BY "mydb_replica1_pwd"; GRANT REPLICATION SLAVE ON *.* TO "mydb_replica1_user"@"%"; FLUSH PRIVILEGES;'
& docker exec mysql_primary sh -c "export MYSQL_PWD=root; mysql -u root -e '$priv_stmt'"

# Create replication user for replica2
$priv2_stmt = 'CREATE USER "mydb_replica2_user"@"%" IDENTIFIED BY "mydb_replica2_pwd"; GRANT REPLICATION SLAVE ON *.* TO "mydb_replica2_user"@"%"; FLUSH PRIVILEGES;'
& docker exec mysql_primary sh -c "export MYSQL_PWD=root; mysql -u root -e '$priv2_stmt'"

# Wait until mysql_replica1 is ready
while (-not (& docker-compose exec mysql_replica1 sh -c 'export MYSQL_PWD=root; mysql -u root -e ";"')) {
    Write-Output "Waiting for mysql_replica1 database connection..."
    Start-Sleep -Seconds 4
}

# Wait until mysql_replica2 is ready
while (-not (& docker-compose exec mysql_replica2 sh -c 'export MYSQL_PWD=root; mysql -u root -e ";"')) {
    Write-Output "Waiting for mysql_replica2 database connection..."
    Start-Sleep -Seconds 4
}

# Get Master Status
$MS_STATUS = & docker exec mysql_primary sh -c 'export MYSQL_PWD=root; mysql -u root -e "SHOW MASTER STATUS"'
$CURRENT_LOG = ($MS_STATUS -split '\s+')[-2]
$CURRENT_POS = ($MS_STATUS -split '\s+')[-1]

# Configure mysql_replica1 to start replication
$start_replica1_stmt = "CHANGE MASTER TO MASTER_HOST='mysql_primary',MASTER_USER='mydb_replica1_user',MASTER_PASSWORD='mydb_replica1_pwd',MASTER_LOG_FILE='$CURRENT_LOG',MASTER_LOG_POS=$CURRENT_POS; START SLAVE;"
& docker exec mysql_replica1 sh -c "export MYSQL_PWD=root; mysql -u root -e '$start_replica1_stmt'"

# Show mysql_replica1 slave status
& docker exec mysql_replica1 sh -c "export MYSQL_PWD=root; mysql -u root -e 'SHOW SLAVE STATUS \G'"

# Configure mysql_replica2 to start replication with a delay
$start_replica2_stmt = "CHANGE MASTER TO MASTER_HOST='mysql_primary',MASTER_USER='mydb_replica2_user',MASTER_PASSWORD='mydb_replica2_pwd',MASTER_LOG_FILE='$CURRENT_LOG',MASTER_LOG_POS=$CURRENT_POS,MASTER_DELAY=5; START SLAVE;"
& docker exec mysql_replica2 sh -c "export MYSQL_PWD=root; mysql -u root -e '$start_replica2_stmt'"

# Show mysql_replica2 slave status
& docker exec mysql_replica2 sh -c "export MYSQL_PWD=root; mysql -u root -e 'SHOW SLAVE STATUS \G'"

# Load all SQL files located in /var/lib/files within the mysql_primary container
& docker exec mysql_primary sh -c 'export MYSQL_PWD=root; for sql_file in /var/lib/files/*.sql; do mysql -u root < "$sql_file"; done'