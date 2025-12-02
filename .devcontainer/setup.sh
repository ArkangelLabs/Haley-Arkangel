#!/bin/bash
# Haley Development Environment Setup
# This script sets up the bench and restores the database

set -e

SITE_NAME="haley.localhost"
SEED_DIR="/workspace/development/seed"

cd /workspace/development

# Check if bench is already initialized
if [ ! -f "sites/common_site_config.json" ]; then
    echo "=== Initializing Bench ==="
    bench init --skip-redis-config-generation --frappe-branch version-16 .

    # Configure bench to use existing redis/mariadb
    bench set-config -g db_host mariadb
    bench set-config -g redis_cache redis://redis-cache:6379
    bench set-config -g redis_queue redis://redis-queue:6379
    bench set-config -g redis_socketio redis://redis-cache:6379
    bench set-config -g developer_mode 1
fi

# Check if site exists
if [ ! -d "sites/$SITE_NAME" ]; then
    echo "=== Creating Site ==="
    bench new-site $SITE_NAME \
        --db-root-password 123 \
        --admin-password admin \
        --no-mariadb-socket

    # Install apps
    echo "=== Installing Apps ==="
    bench --site $SITE_NAME install-app erpnext

    # Restore database if seed exists
    if [ -f "$SEED_DIR/database.sql.gz" ]; then
        echo "=== Restoring Database from Seed ==="
        bench --site $SITE_NAME restore $SEED_DIR/database.sql.gz

        # Restore files
        if [ -f "$SEED_DIR/files.tar" ]; then
            echo "Restoring public files..."
            cd sites/$SITE_NAME/public
            tar -xf $SEED_DIR/files.tar 2>/dev/null || true
            cd /workspace/development
        fi

        if [ -f "$SEED_DIR/private-files.tar" ]; then
            echo "Restoring private files..."
            cd sites/$SITE_NAME/private
            tar -xf $SEED_DIR/private-files.tar 2>/dev/null || true
            cd /workspace/development
        fi
    fi

    # Run migrations
    echo "=== Running Migrations ==="
    bench --site $SITE_NAME migrate

    # Clear cache
    bench --site $SITE_NAME clear-cache

    # Build assets
    echo "=== Building Assets ==="
    bench build
fi

echo "=== Setup Complete ==="
echo "Run 'bench start' to start the development server"
echo "Access at: http://localhost:8010"
