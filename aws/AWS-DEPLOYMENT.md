# Haley AWS Deployment

Deploy ERPNext v16 + Enhanced Kanban View to AWS Lightsail using the official frappe_docker compose stack.

## Prerequisites

- AWS account with Lightsail access
- SSH key pair for Lightsail instance

## Quick Start

### 1. Create Lightsail Instance

1. Go to AWS Lightsail Console
2. Create instance:
   - **OS**: Ubuntu 22.04 LTS
   - **Plan**: $10/month (2GB RAM minimum, 4GB recommended)
   - **Region**: Your preferred region
3. Add SSH key and create instance

### 2. Deploy to Lightsail

SSH into your instance:

```bash
ssh -i your-key.pem ubuntu@YOUR_INSTANCE_IP
```

Upload deployment files:

```bash
# From your local machine
scp -i your-key.pem aws/docker-compose.yml ubuntu@YOUR_INSTANCE_IP:/tmp/
scp -i your-key.pem -r apps/enhanced_kanban_view ubuntu@YOUR_INSTANCE_IP:/tmp/
```

Run deployment script:

```bash
# On the Lightsail instance
sudo su
export SITE_NAME="haley.yourdomain.com"
export ADMIN_PASSWORD="your_secure_password"
export DB_PASSWORD="your_db_password"
curl -s https://raw.githubusercontent.com/YOUR_REPO/Haley/main/aws/deploy-lightsail.sh | bash
```

Or manually:

```bash
# Install Docker
curl -fsSL https://get.docker.com | sh
systemctl enable docker && systemctl start docker

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Create deployment directory
mkdir -p /opt/haley && cd /opt/haley

# Copy compose file
cp /tmp/docker-compose.yml .

# Create .env
cat > .env << EOF
ERPNEXT_VERSION=v16
SITE_NAME=haley.localhost
ADMIN_PASSWORD=your_secure_password
DB_PASSWORD=your_db_password
EOF

# Start
docker-compose up -d
```

### 3. Install Enhanced Kanban View

After initial deployment completes (~5 minutes):

```bash
cd /opt/haley

# Copy enhanced_kanban_view to backend container
BACKEND=$(docker-compose ps -q backend)
docker cp /tmp/enhanced_kanban_view $BACKEND:/home/frappe/frappe-bench/apps/

# Install the app
docker exec $BACKEND bench --site haley.localhost install-app enhanced_kanban_view
docker exec $BACKEND bench build --app enhanced_kanban_view

# Restart services
docker-compose restart backend queue-short queue-long scheduler
```

### 4. Configure Domain (Optional)

1. Point your domain to the Lightsail instance IP
2. Install Caddy for automatic HTTPS:

```bash
# Install Caddy
apt install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list
apt update && apt install caddy

# Configure reverse proxy
cat > /etc/caddy/Caddyfile << EOF
haley.yourdomain.com {
    reverse_proxy localhost:8080
}
EOF

systemctl restart caddy
```

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   AWS Lightsail Instance                 │
│                                                          │
│  ┌────────────────────────────────────────────────────┐ │
│  │              Docker Compose Stack                   │ │
│  │                                                     │ │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────────────────┐│ │
│  │  │frontend │  │websocket│  │      backend        ││ │
│  │  │ :8080   │  │  :9000  │  │      :8000          ││ │
│  │  └────┬────┘  └────┬────┘  └──────────┬──────────┘│ │
│  │       │            │                   │           │ │
│  │       └────────────┴───────────────────┘           │ │
│  │                       │                            │ │
│  │  ┌───────────┐  ┌─────┴─────┐  ┌──────────────┐   │ │
│  │  │queue-short│  │queue-long │  │  scheduler   │   │ │
│  │  └───────────┘  └───────────┘  └──────────────┘   │ │
│  │                       │                            │ │
│  │       ┌───────────────┼───────────────┐           │ │
│  │       ▼               ▼               ▼           │ │
│  │  ┌─────────┐    ┌───────────┐   ┌───────────┐    │ │
│  │  │MariaDB  │    │redis-cache│   │redis-queue│    │ │
│  │  │  :3306  │    │   :6379   │   │   :6379   │    │ │
│  │  └─────────┘    └───────────┘   └───────────┘    │ │
│  └────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

## Commands

```bash
cd /opt/haley

# View logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f backend

# Restart all services
docker-compose restart

# Stop all services
docker-compose down

# Start services
docker-compose up -d

# Access bench shell
docker exec -it $(docker-compose ps -q backend) bash

# Run bench commands
docker exec $(docker-compose ps -q backend) bench --site haley.localhost migrate
docker exec $(docker-compose ps -q backend) bench --site haley.localhost clear-cache
```

## Backup

```bash
cd /opt/haley

# Backup database
docker exec $(docker-compose ps -q backend) bench --site haley.localhost backup

# Find backup files
docker exec $(docker-compose ps -q backend) ls -la sites/haley.localhost/private/backups/

# Copy backup to host
docker cp $(docker-compose ps -q backend):/home/frappe/frappe-bench/sites/haley.localhost/private/backups/ ./backups/
```

## Costs

| Resource | Cost |
|----------|------|
| Lightsail 2GB | $10/month |
| Lightsail 4GB | $20/month |
| Static IP | Free (1 per instance) |
| DNS (Route53) | ~$0.50/month |

**Total: $10-20/month**

## Troubleshooting

### Site not loading
```bash
docker-compose logs create-site
docker-compose logs backend
```

### Permission errors
```bash
docker exec -u root $(docker-compose ps -q backend) chown -R frappe:frappe /home/frappe/frappe-bench/sites
```

### Clear cache
```bash
docker exec $(docker-compose ps -q backend) bench --site haley.localhost clear-cache
docker-compose restart
```
