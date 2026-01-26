#!/bin/bash
set -e

# Database Migration Script
# Exports data from local PostgreSQL and imports to Docker container

LOCAL_HOST="${LOCAL_DB_HOST:-localhost}"
LOCAL_PORT="${LOCAL_DB_PORT:-5432}"
LOCAL_DB="${LOCAL_DB_NAME:-auradb}"
LOCAL_USER="${LOCAL_DB_USER:-aura}"

DUMP_FILE="/tmp/aura_dump_$(date +%Y%m%d_%H%M%S).sql"

echo "=== Database Migration Script ==="
echo "Source: $LOCAL_USER@$LOCAL_HOST:$LOCAL_PORT/$LOCAL_DB"

# Check if running on server or local
if [ -f "/.dockerenv" ] || [ -n "$DOCKER_HOST" ]; then
    echo "Detected Docker environment - skipping local export"
else
    # Export from local PostgreSQL
    echo "Step 1: Exporting database from local PostgreSQL..."
    echo "Enter password for local database when prompted:"

    PGPASSWORD=${LOCAL_DB_PASSWORD} pg_dump -h $LOCAL_HOST -p $LOCAL_PORT -U $LOCAL_USER -d $LOCAL_DB \
        --no-owner --no-privileges --clean --if-exists \
        -f $DUMP_FILE

    echo "Database exported to: $DUMP_FILE"
    echo "Size: $(du -h $DUMP_FILE | cut -f1)"
fi

# If this is on the server, import the dump
if [ -f "$1" ]; then
    DUMP_FILE="$1"
    echo "Using provided dump file: $DUMP_FILE"
fi

if [ -f "$DUMP_FILE" ]; then
    echo ""
    echo "Step 2: Importing to Docker PostgreSQL..."

    # Wait for PostgreSQL container to be ready
    echo "Waiting for PostgreSQL container..."
    until docker exec aura-postgres pg_isready -U aura -d auradb; do
        sleep 2
    done

    # Import the dump
    echo "Importing database..."
    docker exec -i aura-postgres psql -U aura -d auradb < $DUMP_FILE

    echo ""
    echo "=== Migration Complete ==="
    echo "Dump file: $DUMP_FILE"

    # Verify migration
    echo ""
    echo "Verification - Table counts:"
    docker exec aura-postgres psql -U aura -d auradb -c "\dt"
else
    echo ""
    echo "No dump file found. To import on server:"
    echo "1. Copy the dump file to the server"
    echo "2. Run: ./migrate-database.sh /path/to/dump.sql"
fi
