# Stop and remove Docker containers, networks, and volumes
& docker-compose down -v

# Check if the first argument is 'clear-data'
param(
    [string]$Action
)

if ($Action -eq 'clear-data') {
    Write-Output "Clearing data directory..."
    Remove-Item -Recurse -Force ./data/*
}

# Build and start Docker containers
& docker-compose build
& docker-compose up -d

# Wait until mysql_single is ready
while (-not (& docker exec mysql_single sh -c 'export MYSQL_PWD=root; mysql -u root -e ";"')) {
    Write-Output "Waiting for mysql_single database connection..."
    Start-Sleep -Seconds 4
}

# Check if the first argument is 'reset'
if ($Action -eq 'reset') {
    Write-Output "Loading databases..."
    & docker exec mysql_single sh -c '
        export MYSQL_PWD=root;
        for sql_file in /var/lib/mysql-files/*.sql; do
          echo "Loading $sql_file into mysql_single...";
          mysql -u root < "$sql_file";
        done
    '
}

# Load all SQL files located in /var/lib/files within the mysql_primary container
& docker exec mysql_primary sh -c 'export MYSQL_PWD=root; for sql_file in /var/lib/files/*.sql; do mysql -u root < "$sql_file"; done'