#!/bin/bash
# Haley Site Initialization Script
# Run this after the containers are up to create and configure the site

set -e

SITE_NAME="${SITE_NAME:-haley.localhost}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-admin}"
DB_ROOT_PASSWORD="${DB_ROOT_PASSWORD:-}"

# Check if DB_ROOT_PASSWORD is set
if [ -z "$DB_ROOT_PASSWORD" ]; then
    echo "Error: DB_ROOT_PASSWORD environment variable is required"
    echo "Usage: DB_ROOT_PASSWORD=your_password ./init-site.sh"
    exit 1
fi

echo "=== Creating Site: ${SITE_NAME} ==="

# Create the site
docker compose exec backend bench new-site "${SITE_NAME}" \
    --db-root-password "${DB_ROOT_PASSWORD}" \
    --admin-password "${ADMIN_PASSWORD}" \
    --no-mariadb-socket

# Install ERPNext
echo "=== Installing ERPNext ==="
docker compose exec backend bench --site "${SITE_NAME}" install-app erpnext

# Install Enhanced Kanban View
echo "=== Installing Enhanced Kanban View ==="
docker compose exec backend bench --site "${SITE_NAME}" install-app enhanced_kanban_view

# Run migrations
echo "=== Running Migrations ==="
docker compose exec backend bench --site "${SITE_NAME}" migrate

# Build assets
echo "=== Building Assets ==="
docker compose exec backend bench build

# Clear cache
echo "=== Clearing Cache ==="
docker compose exec backend bench --site "${SITE_NAME}" clear-cache

echo "=== Site Setup Complete ==="
echo "Site: ${SITE_NAME}"
echo "Admin Password: ${ADMIN_PASSWORD}"
echo ""
echo "Access your site at: http://localhost:${HTTP_PUBLISH_PORT:-8080}"
