# ERPNext v16 Beta 2 Migration Guide

## Pre-Migration Checklist

The following changes have already been made to your codebase:
- [x] Removed whitelabel app
- [x] Switched Frappe to `version-16-beta` branch
- [x] Switched ERPNext to `version-16-beta` branch
- [x] Updated `mythril_haley/pyproject.toml` to require Python 3.12+
- [x] Updated `sites/apps.json` with v16 version info
- [x] Updated `sites/apps.txt` to remove whitelabel

## Your DocTypes are Safe

Your custom DocTypes (Carrier, Activation, Wireless Commission, Wireless Commission Detail) use standard Frappe patterns and require no code changes for v16.

## Migration Steps (Run Inside Docker Container)

### 1. Backup First!

```bash
bench backup --with-files
```

### 2. Check Node Version

Frappe v16 requires Node.js 22 LTS. Check your version:

```bash
node --version
```

If below v22, upgrade Node inside the container:

```bash
# Install nvm if not present
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source ~/.bashrc

# Install and use Node 22
nvm install 22
nvm use 22
nvm alias default 22
```

### 3. Upgrade frappe-bench

```bash
pip install --upgrade frappe-bench
```

### 4. Install Python Dependencies

```bash
bench setup requirements
```

### 5. Run Database Migration

```bash
bench --site haley.localhost migrate
```

### 6. Rebuild Assets

```bash
bench build
```

### 7. Restart Services

```bash
bench restart
```

## Post-Migration

### Optional: Install Offsite Backups App

Google Drive and S3 backups have been moved to a separate app in v16:

```bash
bench get-app https://github.com/frappe/offsite_backups
bench --site haley.localhost install-app offsite_backups
```

## Troubleshooting

### If migration fails

1. Check the error message carefully
2. Ensure all dependencies are installed: `bench setup requirements`
3. Try running patches manually: `bench --site haley.localhost run-patches`

### If UI looks broken

Rebuild assets: `bench build --force`

### To rollback (if needed)

```bash
cd apps/frappe && git checkout version-15
cd apps/erpnext && git checkout version-15
bench --site haley.localhost migrate
bench build
```

## v16 Breaking Changes (Reference)

1. **Node.js 22 required** (not 20)
2. **Python 3.12 required** (you have 3.12.3 ✓)
3. **New UI/Navigation** - URLs and navigation patterns have changed
4. **Offsite backups** moved to separate app
5. **API changes** in Sales Invoice timesheet billing (not relevant to your app)
