# Haley Railway Deployment - Root Cause Analysis

> **For Claude:** This is a root cause analysis, not an implementation plan.

**Problem:** Railway deployment of Haley (ERPNext v16-beta + Enhanced Kanban View) failed repeatedly across multiple attempts.

**Date:** 2025-12-03

---

## Failure Timeline

| # | Attempt | Error | Root Cause |
|---|---------|-------|------------|
| 1 | Railpack auto-build | Immediate failure | No Dockerfile, Railpack can't build Frappe |
| 2 | Multi-container frappe_docker | Architecture incompatible | Railway volumes attach to ONE service only |
| 3 | pipech pattern, multi-RUN | MariaDB not running | Docker layers don't persist services |
| 4 | Single RUN, v5.22.1 base | Image not found | Wrong base image version |
| 5 | Single RUN, v5.19.0, version-16 | Branch not found | `version-16` doesn't exist, only `version-16-beta` |
| 6 | Changed to version-15 | Wrong version | Would break compatibility with dev environment |

---

## Root Cause #1: Frappe Branch Naming Convention

**What happened:**
```
bench.exceptions.InvalidRemoteException: Invalid branch or tag: version-16
for the remote https://github.com/frappe/frappe
```

**Why:**
- Frappe's branch naming: `version-15`, `version-15-hotfix`, `version-16-beta`
- There is NO `version-16` branch - v16 is still in beta
- Assumed naming pattern would be consistent with v15

**Evidence:**
```bash
$ git ls-remote --heads https://github.com/frappe/frappe.git | grep version-16
4d57a0577749640ab81ad34642ceeb75754d5324  refs/heads/version-16-beta
```

**Fix:** Use `version-16-beta` explicitly

**Prevention:** Always verify branch exists before using:
```bash
git ls-remote --heads https://github.com/frappe/frappe.git | grep <branch>
```

---

## Root Cause #2: Docker Layer Persistence

**What happened:**
Original Dockerfile had multiple RUN commands:
```dockerfile
RUN sudo apt-get install mariadb-server ...
RUN sudo service mariadb start && bench init ...  # FAILS - mariadb not running
```

**Why:**
- Each Docker RUN creates a new layer
- Processes started in one RUN don't persist to the next
- MariaDB MUST be running during `bench init`, `bench new-site`, `install-app`

**Fix:** Single monolithic RUN command (pipech pattern):
```dockerfile
RUN sudo apt-get install mariadb-server \
    && sudo service mariadb start \
    && bench init ... \
    && bench new-site ... \
    && bench install-app ...
```

**Prevention:** For stateful builds requiring running services, use single RUN.

---

## Root Cause #3: Railway Platform Constraints

**What happened:**
Initial attempt used frappe_docker multi-container pattern:
- backend, frontend, queue-short, queue-long, scheduler (5 services)
- All need to share `/sites` directory

**Why Railway can't do this:**
- Railway volumes can only attach to ONE service
- Frappe requires multiple processes sharing same filesystem
- No shared volume = processes can't see same site data

**Fix:** Self-contained single container with:
- MariaDB inside
- Redis inside
- All bench processes via `bench start` (honcho)

**This is the pipech/erpnext-docker-debian pattern.**

---

## Root Cause #4: No Local Testing

**What happened:**
- Push to Railway → wait 15-20 min → see failure → fix → repeat
- Each iteration burned 15-20 minutes
- 5 iterations = 75-100 minutes wasted

**Why:**
- Railway builds from source each time
- No way to inspect intermediate failures
- Logs hard to access

**Fix:** Build locally first:
```bash
docker build -f Dockerfile.railway -t ghcr.io/arkangellabs/haley:latest .
```

Then push pre-built image to ghcr.io and have Railway pull it.

**Prevention:** ALWAYS test Docker builds locally before CI/CD.

---

## Root Cause #5: Configuration Drift

**What happened:**
Multiple files had branch/path configuration:
- `Dockerfile.railway`: `ARG appBranch=version-16`
- `railway.toml`: `FRAPPE_BRANCH = "version-16"`
- `railway-entrypoint.sh`: `/home/frappe/frappe-bench`
- `railway-setup.sh`: `/home/frappe/frappe-bench`

**Why:**
- Changed Dockerfile but not railway.toml
- Changed benchFolderName to `bench` but scripts still had `frappe-bench`

**Fix:** Audit all files when changing configuration.

**Prevention:** Use environment variables from single source of truth.

---

## Current Solution

**Build locally → Push to ghcr.io → Railway pulls pre-built image**

```
┌─────────────────┐      ┌─────────────────┐      ┌─────────────────┐
│  Local Machine  │ ──── │    ghcr.io      │ ──── │    Railway      │
│  docker build   │ push │  pre-built img  │ pull │  just runs it   │
└─────────────────┘      └─────────────────┘      └─────────────────┘
```

**Benefits:**
1. Debug build failures locally with full access
2. Railway deployment is fast (just pull, no build)
3. Consistent image across environments
4. Can test image locally before deploying

---

## Files Modified

| File | Change |
|------|--------|
| `Dockerfile.railway` | Single RUN, v5.19.0 base, version-16-beta, benchFolderName=bench |
| `railway.toml` | Points to `Dockerfile.railway.pullonly` |
| `Dockerfile.railway.pullonly` | Just `FROM ghcr.io/arkangellabs/haley:latest` |
| `production/railway-entrypoint.sh` | Path `/home/frappe/bench` |
| `production/railway-setup.sh` | Path `/home/frappe/bench` |
| `RAILWAY.md` | Updated paths |

---

## Lessons Learned

1. **Verify external dependencies** - Branch names, image tags, API versions
2. **Understand platform constraints** - Railway's single-volume-per-service limit
3. **Test locally first** - Never push untested Docker builds to CI/CD
4. **Single source of truth** - Don't duplicate configuration across files
5. **Know your patterns** - pipech vs frappe_docker serve different use cases

---

## Current Status

- Local build running with `version-16-beta` (correct branch)
- Will push to `ghcr.io/arkangellabs/haley:latest`
- Railway will pull pre-built image (fast, no build)
