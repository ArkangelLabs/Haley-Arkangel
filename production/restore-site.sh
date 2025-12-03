#!/bin/bash
# Haley Site Restore Script
# Restores a site from a database backup

set -e

SITE_NAME="${SITE_NAME:-haley.localhost}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-admin}"
DB_ROOT_PASSWORD="${DB_ROOT_PASSWORD:-}"
BACKUP_FILE="${1:-}"

# Check required variables
if [ -z "$DB_ROOT_PASSWORD" ]; then
    echo "Error: DB_ROOT_PASSWORD environment variable is required"
    echo "Usage: DB_ROOT_PASSWORD=your_password ./restore-site.sh /path/to/backup.sql.gz"
    exit 1
fi

if [ -z "$BACKUP_FILE" ]; then
    echo "Error: Backup file path is required"
    echo "Usage: DB_ROOT_PASSWORD=your_password ./restore-site.sh /path/to/backup.sql.gz"
    exit 1
fi

if [ ! -f "$BACKUP_FILE" ]; then
    echo "Error: Backup file not found: $BACKUP_FILE"
    exit 1
fi

echo "=== Creating Site: ${SITE_NAME} ==="

# Create the site
docker compose exec backend bench new-site "${SITE_NAME}" \
    --db-root-password "${DB_ROOT_PASSWORD}" \
    --admin-password "${ADMIN_PASSWORD}" \
    --no-mariadb-socket

# Copy backup file to container
BACKUP_FILENAME=$(basename "$BACKUP_FILE")
docker compose cp "$BACKUP_FILE" backend:/home/frappe/frappe-bench/"$BACKUP_FILENAME"

# Restore database
echo "=== Restoring Database ==="
docker compose exec backend bench --site "${SITE_NAME}" restore "/home/frappe/frappe-bench/${BACKUP_FILENAME}"

# Clean up backup file in container
docker compose exec backend rm "/home/frappe/frappe-bench/${BACKUP_FILENAME}"

# Run migrations
echo "=== Running Migrations ==="
docker compose exec backend bench --site "${SITE_NAME}" migrate

# Build assets
echo "=== Building Assets ==="
docker compose exec backend bench build

# Clear cache
echo "=== Clearing Cache ==="
docker compose exec backend bench --site "${SITE_NAME}" clear-cache

echo "=== Site Restore Complete ==="
echo "Site: ${SITE_NAME}"
echo ""
echo "Access your site at: http://localhost:${HTTP_PUBLISH_PORT:-8080}"
