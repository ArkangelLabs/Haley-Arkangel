#!/bin/bash
# Haley AWS Lightsail Deployment Script
# Deploys ERPNext v16 using official frappe_docker compose stack

set -e

echo "=== Haley AWS Lightsail Deployment ==="

# Configuration
SITE_NAME="${SITE_NAME:-haley.localhost}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-admin}"
DB_PASSWORD="${DB_PASSWORD:-admin}"
ERPNEXT_VERSION="${ERPNEXT_VERSION:-v16}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (sudo)"
  exit 1
fi

# Step 1: Install Docker if not present
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com | sh
    systemctl enable docker
    systemctl start docker
fi

# Step 2: Install Docker Compose if not present
if ! command -v docker-compose &> /dev/null; then
    echo "Installing Docker Compose..."
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
fi

# Step 3: Create deployment directory
DEPLOY_DIR="/opt/haley"
mkdir -p "$DEPLOY_DIR"
cd "$DEPLOY_DIR"

# Step 4: Copy compose file
if [ -f "/tmp/docker-compose.yml" ]; then
    cp /tmp/docker-compose.yml ./docker-compose.yml
else
    echo "docker-compose.yml not found at /tmp/docker-compose.yml"
    echo "Please copy docker-compose.yml to /tmp/ first"
    exit 1
fi

# Step 5: Create .env file
cat > .env << EOF
ERPNEXT_VERSION=${ERPNEXT_VERSION}
SITE_NAME=${SITE_NAME}
ADMIN_PASSWORD=${ADMIN_PASSWORD}
DB_PASSWORD=${DB_PASSWORD}
EOF

echo "Configuration saved to .env"

# Step 6: Pull images
echo "Pulling Docker images..."
docker-compose pull

# Step 7: Start services
echo "Starting services..."
docker-compose up -d

# Step 8: Wait for site creation
echo "Waiting for site creation (this may take a few minutes)..."
sleep 30

# Check if site was created successfully
for i in {1..20}; do
    if docker-compose logs create-site 2>&1 | grep -q "Site.*created"; then
        echo "Site created successfully!"
        break
    fi
    echo "Waiting for site creation... (attempt $i/20)"
    sleep 15
done

# Step 9: Show status
echo ""
echo "=== Deployment Complete ==="
echo ""
docker-compose ps
echo ""
echo "Access your site at: http://localhost:8080"
echo "Username: Administrator"
echo "Password: ${ADMIN_PASSWORD}"
echo ""
echo "To view logs: docker-compose logs -f"
echo "To stop: docker-compose down"
echo "To restart: docker-compose restart"
