#!/bin/bash
# Haley Railway Entrypoint
# Configures frappe for external DB/Redis and starts all processes via supervisor

set -e

cd /home/frappe/frappe-bench

echo "=== Haley Railway Startup ==="

# Default PORT if not set
export PORT=${PORT:-8000}

# Configure database connection
echo "Configuring database..."
if [ -n "$DB_HOST" ]; then
    bench set-config -g db_host "$DB_HOST"
fi

if [ -n "$DB_PORT" ]; then
    bench set-config -gp db_port "$DB_PORT"
else
    bench set-config -gp db_port 3306
fi

# Configure Redis (Railway provides these)
echo "Configuring Redis..."
if [ -n "$REDIS_URL" ]; then
    # Railway provides REDIS_URL format: redis://default:password@host:port
    bench set-config -g redis_cache "$REDIS_URL"
    bench set-config -g redis_queue "$REDIS_URL"
    bench set-config -g redis_socketio "$REDIS_URL"
elif [ -n "$REDIS_CACHE" ] && [ -n "$REDIS_QUEUE" ]; then
    bench set-config -g redis_cache "redis://$REDIS_CACHE"
    bench set-config -g redis_queue "redis://$REDIS_QUEUE"
    bench set-config -g redis_socketio "redis://$REDIS_QUEUE"
fi

# Set socketio port
bench set-config -gp socketio_port 9000

# Generate apps.txt if not exists
if [ ! -f "sites/apps.txt" ]; then
    echo "Generating apps.txt..."
    ls -1 apps > sites/apps.txt
fi

# Check if we need to create a site
if [ -n "$SITE_NAME" ] && [ -n "$DB_ROOT_PASSWORD" ]; then
    if [ ! -d "sites/$SITE_NAME" ]; then
        echo "=== Creating new site: $SITE_NAME ==="

        # Wait for database to be ready
        echo "Waiting for database..."
        timeout=60
        while ! mariadb -h "$DB_HOST" -P "${DB_PORT:-3306}" -u root -p"$DB_ROOT_PASSWORD" -e "SELECT 1" > /dev/null 2>&1; do
            timeout=$((timeout - 1))
            if [ $timeout -le 0 ]; then
                echo "ERROR: Database not ready after 60 seconds"
                exit 1
            fi
            sleep 1
        done
        echo "Database is ready!"

        # Create site
        bench new-site "$SITE_NAME" \
            --db-root-password "$DB_ROOT_PASSWORD" \
            --admin-password "${ADMIN_PASSWORD:-admin}" \
            --no-mariadb-socket \
            --db-host "$DB_HOST" \
            --db-port "${DB_PORT:-3306}" || true

        # Install apps
        echo "Installing ERPNext..."
        bench --site "$SITE_NAME" install-app erpnext || true

        echo "Installing Enhanced Kanban View..."
        bench --site "$SITE_NAME" install-app enhanced_kanban_view || true

        # Run migrations
        echo "Running migrations..."
        bench --site "$SITE_NAME" migrate || true

        # Build assets
        echo "Building assets..."
        bench build || true

        echo "=== Site creation complete ==="
    fi
fi

# Set default site if specified
if [ -n "$SITE_NAME" ]; then
    echo "Setting default site to: $SITE_NAME"
    bench use "$SITE_NAME" || true
fi

# Verify configuration
echo "=== Configuration Summary ==="
cat sites/common_site_config.json | jq '.' 2>/dev/null || cat sites/common_site_config.json
echo ""

# Start supervisor with all processes
echo "=== Starting Supervisor ==="
exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
