#!/bin/bash

# ======================================================
# DATABASE BACKUP SCRIPT
# ======================================================

set -e

# Configuration
DB_NAME="microblog_db"
DB_USER="postgres"
BACKUP_DIR="/backups/postgres"
RETENTION_DAYS=30
DATE=$(date +"%Y%m%d_%H%M%S")
BACKUP_PATH="${BACKUP_DIR}/${DB_NAME}_${DATE}.sql.gz"
S3_BUCKET="s3://microblog-backups"

# Create backup directory
mkdir -p ${BACKUP_DIR}

# Log start
echo "[$(date)] Starting backup of ${DB_NAME}"

# Perform backup
PGPASSWORD=${DB_PASSWORD} pg_dump \
    -h ${DB_HOST:-localhost} \
    -U ${DB_USER} \
    -d ${DB_NAME} \
    -F c \
    -f "${BACKUP_PATH%.gz}" \
    -v

# Compress
gzip "${BACKUP_PATH%.gz}"

# Upload to S3 (if configured)
if [ -n "$S3_BUCKET" ]; then
    aws s3 cp ${BACKUP_PATH} ${S3_BUCKET}/$(date +%Y/%m/%d)/${DB_NAME}_${DATE}.sql.gz
fi

# Remove old backups
find ${BACKUP_DIR} -name "${DB_NAME}_*.sql.gz" -mtime +${RETENTION_DAYS} -delete

echo "[$(date)] Backup completed: ${BACKUP_PATH}"