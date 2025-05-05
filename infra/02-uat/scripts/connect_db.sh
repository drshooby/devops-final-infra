#!/bin/bash
set -euo pipefail

DB_ENDPOINT=""
DB_USER=""
DB_NAME="uatdb"
DB_PASS=''

echo "🔌 Connecting to $DB_NAME at $DB_ENDPOINT..."

PGPASSWORD=$DB_PASS psql "sslmode=require host=$DB_ENDPOINT user=$DB_USER dbname=$DB_NAME" -f ./init.sql && \
PGPASSWORD=$DB_PASS psql "sslmode=require host=$DB_ENDPOINT user=$DB_USER dbname=$DB_NAME"