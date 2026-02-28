#!/bin/bash

printf "\n%-12s %-10s %-6s %-25s %-25s %-10s %-12s %-10s %-10s %-8s %-8s %-25s\n" \
"Database" "Version" "Port" "Config Path" "Backup Path" "Status" "User" "Disk" "RAM(MB)" "CPU%" "PID" "Data Dir"

printf "%-12s %-10s %-6s %-25s %-25s %-10s %-12s %-10s %-10s %-8s %-8s %-25s\n" \
"------------" "----------" "------" "-------------------------" "-------------------------" "----------" "------------" "----------" "----------" "------" "------" "-------------------------"

get_ram_mb() {
    ps -o rss= -C $1 2>/dev/null | awk '{sum+=$1} END {print sum/1024}'
}

get_cpu() {
    ps -o %cpu= -C $1 2>/dev/null | awk '{sum+=$1} END {print sum}'
}

get_pid() {
    pgrep $1 | head -1
}

get_uptime() {
    PID=$(get_pid $1)
    if [ -n "$PID" ]; then
        ps -p $PID -o etime= 2>/dev/null
    fi
}

get_disk() {
    du -sh $1 2>/dev/null | awk '{print $1}'
}

# ---------------- MYSQL ----------------
if command -v mysql >/dev/null 2>&1; then
    VERSION=$(mysql --version | awk '{print $5}' | tr -d ',')
    PORT=$(grep -R "port" /etc/mysql 2>/dev/null | head -1 | awk -F= '{print $2}' | tr -d ' ')
    CONFIG=$(find /etc -name "my.cnf" 2>/dev/null | head -1)
    BACKUP="/var/backups/mysql"
    STATUS=$(systemctl is-active mysql 2>/dev/null)
    USER=$(ps -o user= -C mysqld | head -1)
    DATA_DIR="/var/lib/mysql"
    DISK=$(get_disk $DATA_DIR)
    RAM=$(get_ram_mb mysqld)
    CPU=$(get_cpu mysqld)
    PID=$(get_pid mysqld)

    printf "%-12s %-10s %-6s %-25s %-25s %-10s %-12s %-10s %-10.1f %-8.1f %-8s %-25s\n" \
    "MySQL" "$VERSION" "${PORT:-3306}" "${CONFIG:-N/A}" "$BACKUP" "$STATUS" "$USER" \
    "${DISK:-N/A}" "${RAM:-0}" "${CPU:-0}" "$PID" "$DATA_DIR"
fi

# ---------------- POSTGRES ----------------
if command -v psql >/dev/null 2>&1; then
    VERSION=$(psql --version | awk '{print $3}')
    PORT=$(grep -R "^port" /etc/postgresql 2>/dev/null | head -1 | awk '{print $3}')
    CONFIG=$(find /etc/postgresql -name "postgresql.conf" 2>/dev/null | head -1)
    BACKUP="/var/backups/postgresql"
    STATUS=$(systemctl is-active postgresql 2>/dev/null)
    USER=$(ps -o user= -C postgres | head -1)
    DATA_DIR=$(find /var/lib/postgresql -type d -name "main" 2>/dev/null | head -1)
    DISK=$(get_disk $DATA_DIR)
    RAM=$(get_ram_mb postgres)
    CPU=$(get_cpu postgres)
    PID=$(get_pid postgres)

    printf "%-12s %-10s %-6s %-25s %-25s %-10s %-12s %-10s %-10.1f %-8.1f %-8s %-25s\n" \
    "PostgreSQL" "$VERSION" "${PORT:-5432}" "${CONFIG:-N/A}" "$BACKUP" "$STATUS" "$USER" \
    "${DISK:-N/A}" "${RAM:-0}" "${CPU:-0}" "$PID" "$DATA_DIR"
fi

# ---------------- MONGODB ----------------
if command -v mongod >/dev/null 2>&1; then
    VERSION=$(mongod --version | grep "db version" | awk '{print $3}')
    PORT=$(grep "port:" /etc/mongod.conf 2>/dev/null | awk '{print $2}')
    CONFIG="/etc/mongod.conf"
    BACKUP="/var/backups/mongodb"
    STATUS=$(systemctl is-active mongod 2>/dev/null)
    USER=$(ps -o user= -C mongod | head -1)
    DATA_DIR=$(grep "dbPath" /etc/mongod.conf 2>/dev/null | awk '{print $2}')
    DISK=$(get_disk $DATA_DIR)
    RAM=$(get_ram_mb mongod)
    CPU=$(get_cpu mongod)
    PID=$(get_pid mongod)

    printf "%-12s %-10s %-6s %-25s %-25s %-10s %-12s %-10s %-10.1f %-8.1f %-8s %-25s\n" \
    "MongoDB" "$VERSION" "${PORT:-27017}" "$CONFIG" "$BACKUP" "$STATUS" "$USER" \
    "${DISK:-N/A}" "${RAM:-0}" "${CPU:-0}" "$PID" "$DATA_DIR"
fi
