#!/bin/bash

# ======================================================
# DATABASE RESTORE SCRIPT
# ======================================================

set -e

# Configuration
DB_NAME="microblog_db"
DB_USER="postgres"
BACKUP_FILE=$1

if [ -z "$BACKUP_FILE" ]; then
    echo "Usage: $0 <backup_file.sql.gz>"
    exit 1
fi

# Check if backup exists
if [ ! -f "$BACKUP_FILE" ]; then
    echo "Backup file not found: $BACKUP_FILE"
    exit 1
fi

echo "[$(date)] Starting restore from ${BACKUP_FILE}"

# Drop and recreate database
PGPASSWORD=${DB_PASSWORD} dropdb -h ${DB_HOST:-localhost} -U ${DB_USER} --if-exists ${DB_NAME}
PGPASSWORD=${DB_PASSWORD} createdb -h ${DB_HOST:-localhost} -U ${DB_USER} ${DB_NAME}

# Restore
gunzip -c ${BACKUP_FILE} | PGPASSWORD=${DB_PASSWORD} pg_restore \
    -h ${DB_HOST:-localhost} \
    -U ${DB_USER} \
    -d ${DB_NAME} \
    -v

echo "[$(date)] Restore completed"