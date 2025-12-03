#!/bin/bash
# Install Enhanced Kanban View app after site creation
# Run this from the Lightsail instance after initial deployment

set -e

SITE_NAME="${SITE_NAME:-haley.localhost}"
DEPLOY_DIR="${DEPLOY_DIR:-/opt/haley}"

echo "=== Installing Enhanced Kanban View ==="

cd "$DEPLOY_DIR"

# Get the backend container name
BACKEND_CONTAINER=$(docker-compose ps -q backend)

if [ -z "$BACKEND_CONTAINER" ]; then
    echo "Error: Backend container not found. Is the stack running?"
    exit 1
fi

# Method 1: If enhanced_kanban_view is published to a git repo
# docker exec -it "$BACKEND_CONTAINER" bench get-app https://github.com/YOUR_ORG/enhanced_kanban_view --branch version-16-beta

# Method 2: Copy local app into container and install
echo "Copying enhanced_kanban_view to container..."

# Copy the app directory to the container
docker cp /tmp/enhanced_kanban_view "$BACKEND_CONTAINER":/home/frappe/frappe-bench/apps/enhanced_kanban_view

# Install the app
echo "Installing enhanced_kanban_view..."
docker exec -it "$BACKEND_CONTAINER" bench --site "$SITE_NAME" install-app enhanced_kanban_view

# Build assets
echo "Building assets..."
docker exec -it "$BACKEND_CONTAINER" bench build --app enhanced_kanban_view

# Restart workers to pick up new app
echo "Restarting services..."
docker-compose restart backend queue-short queue-long scheduler

echo ""
echo "=== Enhanced Kanban View Installed ==="
echo "Clear your browser cache and refresh the page."
