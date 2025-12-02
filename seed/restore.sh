#!/bin/bash
# Haley Database Restore Script
# Run this inside the frappe container after site creation

SITE_NAME="${SITE_NAME:-haley.localhost}"
SEED_DIR="/workspace/development/seed"

echo "=== Restoring Haley Database ==="

# Check if seed files exist
if [ ! -f "$SEED_DIR/database.sql.gz" ]; then
    echo "Error: database.sql.gz not found in $SEED_DIR"
    exit 1
fi

# Restore database
echo "Restoring database..."
bench --site $SITE_NAME restore $SEED_DIR/database.sql.gz

# Restore files if they exist
if [ -f "$SEED_DIR/files.tar" ]; then
    echo "Restoring public files..."
    cd /workspace/development/sites/$SITE_NAME/public
    tar -xf $SEED_DIR/files.tar
fi

if [ -f "$SEED_DIR/private-files.tar" ]; then
    echo "Restoring private files..."
    cd /workspace/development/sites/$SITE_NAME/private
    tar -xf $SEED_DIR/private-files.tar
fi

# Clear cache
echo "Clearing cache..."
bench --site $SITE_NAME clear-cache

echo "=== Restore Complete ==="
