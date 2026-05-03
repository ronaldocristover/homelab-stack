# Homelab Stack

Modular Docker Compose stacks for self-hosted services. Each service lives in its own directory with its own compose file.

## Services

| Directory | Description |
|-----------|-------------|
| `minio-s3/` | MinIO S3-compatible object storage |
| `portainer/` | Container management UI |
| `mysql-backup/` | Multi-server MySQL backup with S3 upload, local HDD sync, and webhook alerts |

## Prerequisites

- Docker Engine
- Docker Compose v2+

## Quick Start

### 1. Create the shared network (required by MinIO)

```bash
docker network create global-network
```

### 2. Start MinIO S3

```bash
cd minio-s3
cp .env.example .env
docker compose up -d
```

### 3. Start Portainer

```bash
cd portainer
cp .env-example .env
docker compose up -d
```

### 4. Start MySQL Backup

```bash
cd mysql-backup
cp .env.example .env
cp servers.json.example servers.json
```

Edit `.env` with your DigitalOcean Spaces credentials and `servers.json` with your MySQL server connections.

Then start from the repo root:

```bash
make up
```

## MySQL Backup

The primary active service. Backs up multiple MySQL servers, uploads to S3 (DigitalOcean Spaces), syncs to a local HDD, and sends webhook alerts on failure.

### Configuration

**`.env`** — General settings (S3 credentials, cleanup policies, webhook URL):

| Variable | Description |
|----------|-------------|
| `DO_ACCESS_KEY` / `DO_SECRET_KEY` | DigitalOcean Spaces credentials |
| `DO_ENDPOINT` / `DO_REGION` / `DO_BUCKET` | S3 target configuration |
| `DO_PATH` | Default S3 prefix for backups |
| `DO_CLEANUP_DAYS` | Days to retain S3 backups (default: 30) |
| `LOCAL_BACKUP_ENABLED` | Enable local HDD sync |
| `HDD_MOUNT_PATH` | Local HDD mount path |
| `LOCAL_CLEANUP_DAYS` | Days to retain local backups (default: 90) |
| `ALERT_WEBHOOK_URL` | Webhook URL for failure alerts (Discord/Slack/generic) |
| `ALERT_HOSTNAME` | Hostname shown in alert messages |

**`servers.json`** — Database connections (one entry per MySQL server):

```json
[
  {
    "name": "prod-primary",
    "host": "mysql.example.com",
    "port": 3306,
    "user": "backup_user",
    "pass": "secret",
    "s3_path": "prod-primary-backup",
    "databases": ["app_db", "users_db"]
  }
]
```

Each server can override the default S3 prefix with `s3_path`.

### Commands (dev)

Run from the repo root:

```bash
make up            # Start the backup service
make test          # Run full backup pipeline
make test-backup   # Backup only
make test-upload   # S3 upload only
make test-sync     # Local HDD sync only
make test-notify   # Test webhook notification
make logs          # View backup log
make update        # Rebuild and restart (picks up .env changes)
make down          # Stop the service
```

### Production

Production uses a separate compose overlay and env file. The container runs as `mysql-backup-prod` and reads `servers.prod.json`.

```bash
# First-time setup
cd mysql-backup
cp .env.example .env.prod
cp servers.json.example servers.prod.json
# Edit .env.prod and servers.prod.json

# Run from repo root
make prod-up
make prod-test           # Full backup pipeline on production
make prod-test-backup    # Backup only
make prod-test-upload    # S3 upload only
make prod-test-sync      # Local HDD sync only
make prod-logs           # View production logs
make prod-update         # Rebuild and restart production
```

## Port Reference

| Service | Port | Purpose |
|---------|------|---------|
| MinIO API | 9000 | S3-compatible API |
| MinIO Console | 9001 | Web management UI |
| Portainer | 9443 | HTTPS management UI |
| Portainer | 9000 | HTTP management UI |
| Portainer Edge | 8000 | Edge agent |

> **Port 9000 conflict**: MinIO API and Portainer HTTP UI both use port 9000. Change one before running both.

## Security Notes

- `.env` and `.env.prod` files contain real secrets and are gitignored
- `servers.json` and `servers.prod.json` contain database credentials and are gitignored
- Never commit these files to version control
