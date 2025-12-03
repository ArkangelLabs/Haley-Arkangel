# Haley Railway Deployment Guide

This guide covers deploying Haley (ERPNext v16) to Railway.

## Architecture

Railway has a **volume limitation**: each volume can only be attached to ONE service. Since Frappe requires multiple processes (web, workers, scheduler, socketio) to share the same `sites/` directory, we use **supervisor** to run ALL processes in a single container.

```
┌─────────────────────────────────────────────────────────┐
│                   Railway Project                        │
├─────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────┐    │
│  │              Haley Container                     │    │
│  │  ┌─────────────────────────────────────────┐    │    │
│  │  │           Supervisor                     │    │    │
│  │  │  • Gunicorn (web)                       │    │    │
│  │  │  • Socketio (realtime)                  │    │    │
│  │  │  • Scheduler (cron)                     │    │    │
│  │  │  • Worker-short (background jobs)       │    │    │
│  │  │  • Worker-long (background jobs)        │    │    │
│  │  └─────────────────────────────────────────┘    │    │
│  │                      │                           │    │
│  │               [sites/ volume]                   │    │
│  └──────────────────────┼──────────────────────────┘    │
│                         │                               │
│       ┌─────────────────┼─────────────────┐             │
│       ▼                 ▼                 ▼             │
│  ┌──────────┐     ┌──────────┐      ┌──────────┐       │
│  │  MySQL   │     │  Redis   │      │  Redis   │       │
│  │    DB    │     │  Cache   │      │  Queue   │       │
│  └──────────┘     └──────────┘      └──────────┘       │
└─────────────────────────────────────────────────────────┘
```

## Deployment Steps

### 1. Create Railway Project

1. Go to [Railway](https://railway.app)
2. Click "New Project" → "Deploy from GitHub repo"
3. Select the `Haley-Arkangel` repository
4. The build will start but the container won't work yet (needs DB/Redis)

### 2. Add Required Services

#### MySQL Database
1. Click "New" → "Database" → "MySQL"
2. Railway will create and configure the database automatically

#### Redis (ONE instance for both cache and queue)
1. Click "New" → "Database" → "Redis"
2. One Redis instance is sufficient for both cache and queue

### 3. Configure Environment Variables

Click on your Haley service → Variables tab → Add these:

```bash
# Database - Reference Railway's MySQL service
DB_HOST=${{MySQL.MYSQLHOST}}
DB_PORT=${{MySQL.MYSQLPORT}}
DB_ROOT_PASSWORD=${{MySQL.MYSQL_ROOT_PASSWORD}}

# Redis - Reference Railway's Redis service
REDIS_URL=${{Redis.REDIS_URL}}

# Site Configuration
SITE_NAME=haley.example.com
ADMIN_PASSWORD=your_secure_password_here
```

**Important**: Replace `haley.example.com` with your actual domain or Railway's generated domain.

### 4. Deploy

After setting variables, Railway will automatically redeploy. The first deployment:
1. Configures database/redis connections
2. Creates the site (if SITE_NAME and DB_ROOT_PASSWORD are set)
3. Installs ERPNext and Enhanced Kanban View
4. Runs migrations
5. Starts all processes via supervisor

This takes several minutes on first run.

### 5. Access Your Site

Once deployment completes:
1. Go to Settings → Networking → Generate Domain (or add custom domain)
2. Access your site at the provided URL
3. Login with:
   - Username: `Administrator`
   - Password: Value of `ADMIN_PASSWORD` env var

## Environment Variables Reference

| Variable | Description | Required |
|----------|-------------|----------|
| `DB_HOST` | MySQL host (from Railway service) | Yes |
| `DB_PORT` | MySQL port (default: 3306) | No |
| `DB_ROOT_PASSWORD` | MySQL root password | Yes |
| `REDIS_URL` | Full Redis URL from Railway | Yes |
| `SITE_NAME` | Your domain name for the site | Yes |
| `ADMIN_PASSWORD` | Administrator password | Yes |
| `PORT` | Web server port (Railway sets this) | No |

## Manual Site Creation (Alternative)

If automatic site creation fails, you can create the site manually:

1. Open Railway shell: Click on service → Shell tab
2. Run these commands:

```bash
cd /home/frappe/frappe-bench

# Create site
bench new-site your-site-name \
    --db-root-password "$DB_ROOT_PASSWORD" \
    --admin-password "your_password" \
    --no-mariadb-socket

# Install apps
bench --site your-site-name install-app erpnext
bench --site your-site-name install-app enhanced_kanban_view

# Set default site
bench use your-site-name

# Run migrations
bench --site your-site-name migrate
```

## Restoring from Backup

To restore your existing database:

1. Upload backup to a public URL or use Railway shell
2. Open Railway shell and run:

```bash
cd /home/frappe/frappe-bench
bench --site $SITE_NAME restore /path/to/backup.sql.gz
bench --site $SITE_NAME migrate
bench build
bench --site $SITE_NAME clear-cache
```

## Costs

Estimated Railway costs (varies by usage):
- Haley container: ~$10-20/month
- MySQL: ~$5-10/month
- Redis: ~$5/month

Total: ~$20-35/month

## Troubleshooting

### Build Fails
- Check Railway build logs for specific errors
- Ensure `Dockerfile.railway` exists at root
- Verify `production/apps.json` has valid GitHub URLs

### Site Not Loading
- Check that all environment variables are set correctly
- Verify MySQL and Redis services are running
- Check container logs for errors

### 502 Bad Gateway
- Container might still be starting (can take 2-5 minutes)
- Check supervisor status: `supervisorctl status`
- View logs: `tail -f /var/log/supervisor/*.log`

### Database Connection Issues
- Verify DB_HOST matches Railway's MySQL host
- Check DB_ROOT_PASSWORD is correct
- Test connection: `mariadb -h $DB_HOST -P $DB_PORT -u root -p`

### Redis Connection Issues
- Verify REDIS_URL is set correctly
- Check Redis service is running in Railway dashboard

## Limitations

- **Single container**: All processes run in one container (Railway volume limitation)
- **Cold starts**: May take 1-2 minutes after period of inactivity
- **File uploads**: Stored in container volume, may be lost on redeploy without persistent volume
- **Scaling**: Horizontal scaling not possible due to shared state

For production workloads requiring high availability, consider:
- [Frappe Cloud](https://frappecloud.com) (managed hosting)
- Self-hosted on DigitalOcean/Hetzner with proper Docker Compose setup
