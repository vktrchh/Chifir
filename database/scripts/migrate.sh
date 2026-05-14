#!/bin/bash

# ======================================================
# DATABASE MIGRATION SCRIPT
# ======================================================

set -e

DB_NAME="microblog_db"
DB_USER="postgres"
MIGRATIONS_DIR="$(dirname $0)/../migrations"

echo "[$(date)] Starting database migrations"

# Run migrations in order
for migration in ${MIGRATIONS_DIR}/V*.sql; do
    echo "Applying: $(basename ${migration})"
    PGPASSWORD=${DB_PASSWORD} psql \
        -h ${DB_HOST:-localhost} \
        -U ${DB_USER} \
        -d ${DB_NAME} \
        -f ${migration}
done

echo "[$(date)] Migrations completed"