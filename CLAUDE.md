# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Haley is a customized ERPNext v16 deployment with an Enhanced Kanban View app for a wireless/telecom business. It extends the standard Frappe/ERPNext framework with Bitrix24-inspired Kanban functionality.

## Tech Stack

- **Frappe Framework** v16 (Python 3.12+, Node.js 22+)
- **ERPNext** v16 - Open source ERP
- **Enhanced Kanban View** - Custom Frappe app for advanced Kanban boards
- **MariaDB** - Database
- **Redis** - Cache and queue

## Repository Structure

```
/
├── apps/
│   ├── frappe/           # Core Frappe framework
│   ├── erpnext/          # ERPNext ERP modules
│   └── enhanced_kanban_view/  # Custom Kanban app
├── sites/                # Site configuration and data
│   └── haley.localhost/  # Main site
├── aws/                  # AWS Lightsail deployment files
├── production/           # Railway deployment files
└── config/               # Bench configuration
```

## Development Commands

### Local Development (bench)
```bash
# Start development server
bench start

# Run single process
bench serve --port 8000

# Watch for JS/CSS changes
bench watch

# Build assets
bench build
bench build --app enhanced_kanban_view  # Single app

# Migrate database
bench --site haley.localhost migrate
bench --site haley.localhost migrate --skip-failing

# Clear cache
bench --site haley.localhost clear-cache

# Run Python console
bench --site haley.localhost console
```

### Testing
```bash
# Run all tests for an app
bench --site haley.localhost run-tests --app enhanced_kanban_view

# Run single test file
bench --site haley.localhost run-tests --module enhanced_kanban_view.enhanced_kanban_view.doctype.kanban_board_rule.test_kanban_board_rule

# Run specific test
bench --site haley.localhost run-tests --doctype "Kanban Board Rule"
```

### Database Operations
```bash
# Backup
bench --site haley.localhost backup
bench --site haley.localhost backup --with-files

# Restore
bench --site haley.localhost restore <backup-file>

# MariaDB console
bench --site haley.localhost mariadb
```

## Deployment

### Current Production: AWS Lightsail (Bare Metal)
Deploys via GitHub Actions (`.github/workflows/deploy.yml`) on push to main.

Manual deployment SSH:
```bash
ssh ubuntu@75.101.190.200
cd /home/frappe/frappe-bench
sudo -u frappe bench --site haley.localhost migrate
sudo -u frappe bench build --app enhanced_kanban_view
sudo supervisorctl restart all
```

### Docker Deployment (AWS)
```bash
cd /opt/haley
docker-compose up -d
docker exec $(docker-compose ps -q backend) bench --site haley.localhost migrate
```

### Railway Deployment
Uses `Dockerfile.railway` with self-contained MariaDB+Redis.

## Enhanced Kanban View Architecture

The custom app extends Frappe's Kanban view with:

- **Link field-based columns**: Auto-creates columns from Link field options
- **Column rules/validation**: Required fields when moving cards between columns
- **Monkey patches**: Automatic column CRUD when linked records change

Key files:
- `apps/enhanced_kanban_view/enhanced_kanban_view/hooks.py` - App configuration
- `apps/enhanced_kanban_view/enhanced_kanban_view/api/` - API endpoints
- `apps/enhanced_kanban_view/enhanced_kanban_view/monkey_patches/` - Document event hooks

DocTypes:
- `Kanban Board Rule` - Validation rules for columns
- `Kanban Rule Field` - Child table for required fields

## Frappe Framework Patterns

### Creating a new DocType
```bash
bench --site haley.localhost new-doctype "My DocType" --module "Enhanced Kanban View"
```

### API Endpoints
Whitelisted functions are exposed as REST endpoints:
```python
@frappe.whitelist()
def my_api_function(arg1, arg2):
    return {"result": "value"}
```
Called via: `POST /api/method/enhanced_kanban_view.api.module.my_api_function`

### Document Hooks
In `hooks.py`:
```python
doc_events = {
    "DocType Name": {
        "on_update": "app.module.function",
        "on_trash": "app.module.function"
    }
}
```

## Linting

The enhanced_kanban_view app uses Ruff for Python linting:
```bash
cd apps/enhanced_kanban_view
ruff check .
ruff format .
```

## frappe-deployer Integration

This project can use [frappe-deployer](https://github.com/rtCamp/frappe-deployer) for advanced deployment:

```bash
# Install
pip install frappe-deployer

# Configure site
frappe-deployer configure haley --mode host

# Deploy with apps
frappe-deployer pull haley --apps frappe/erpnext:version-16

# Cleanup old releases
frappe-deployer cleanup haley
```
