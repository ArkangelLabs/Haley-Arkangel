# Haley Production Deployment

Production Docker setup for Haley (ERPNext v16 with custom modifications).

## Architecture

Based on [frappe_docker](https://github.com/frappe/frappe_docker) patterns:

- **frontend**: Nginx reverse proxy (port 8080)
- **backend**: Gunicorn application server
- **websocket**: Socket.IO for real-time updates
- **scheduler**: Background job scheduler
- **queue-short/queue-long**: Background workers
- **db**: MariaDB 11.8
- **redis-cache/redis-queue**: Redis for caching and job queues

## Quick Start

### 1. Build the Custom Image

```bash
./build.sh
```

This builds a Docker image with:
- Frappe v16
- ERPNext v16
- Enhanced Kanban View

### 2. Configure Environment

```bash
cp .env.example .env
# Edit .env with your configuration
```

Required settings:
- `DB_PASSWORD`: MariaDB root password
- `FRAPPE_SITE_NAME_HEADER`: Your domain (optional, defaults to $host)

### 3. Start Services

```bash
docker compose up -d
```

### 4. Initialize Site

For a new site:
```bash
DB_ROOT_PASSWORD=your_password ./init-site.sh
```

To restore from backup:
```bash
DB_ROOT_PASSWORD=your_password ./restore-site.sh /path/to/backup.sql.gz
```

## Building Custom Image

The Dockerfile uses `apps.json` to specify which apps to install:

```json
[
  {"url": "https://github.com/frappe/erpnext", "branch": "version-16"},
  {"url": "https://github.com/your-org/your-app", "branch": "main"}
]
```

Build arguments:
- `FRAPPE_BRANCH`: Frappe version (default: version-16)
- `APPS_JSON_BASE64`: Base64-encoded apps.json

## Pushing to Registry

```bash
# Login to registry
docker login ghcr.io

# Push image
docker push ghcr.io/arkangellabs/haley:latest
```

## Railway/Dokploy Deployment

For Railway or Dokploy, use the pre-built image:

1. Set `HALEY_IMAGE` and `HALEY_VERSION` in environment
2. Configure database and Redis (external or included services)
3. Set `DB_PASSWORD` and `FRAPPE_SITE_NAME_HEADER`

## Backups

### Create Backup
```bash
docker compose exec backend bench --site your-site backup --with-files
```

### Scheduled Backups
Add to crontab:
```bash
0 2 * * * cd /path/to/production && docker compose exec -T backend bench --site your-site backup --with-files
```

## Troubleshooting

### Check Logs
```bash
docker compose logs -f backend
docker compose logs -f scheduler
```

### Access Shell
```bash
docker compose exec backend bash
```

### Rebuild Assets
```bash
docker compose exec backend bench build
```

### Clear Cache
```bash
docker compose exec backend bench --site your-site clear-cache
```
