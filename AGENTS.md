# AGENTS.md

## Repository Structure

Modular Docker Compose stacks — each service lives in its own directory. There is no root-level compose file.

- `minio-s3/` — MinIO S3-compatible object storage
- `portainer/` — Container management UI
- `mysql-backup/` — Multi-server MySQL backup, S3 upload, local HDD sync, webhook alerts (the primary active service)

## Commands

All `make` targets in the root `Makefile` run `docker compose` from the repo root and target the `mysql-backup` service.

### Dev targets (`.env`)

- `make up` / `make down` / `make restart` — lifecycle
- `make test` — full backup pipeline (backup + sync + upload + webhook notification)
- `make test-backup` / `make test-upload` / `make test-sync` — individual stages
- `make test-notify` — notification from inside container; `make test-notify-host` — from host (no container needed)
- `make logs` / `make logs-upload` / `make logs-sync` / `make logs-run` — tail logs
- `make update` — rebuild and restart (picks up `.env` changes)

### Production targets (`.env.prod` + `docker-compose.prod.yml`)

Production uses `docker compose -f docker-compose.yml -f docker-compose.prod.yml --env-file .env.prod` and runs as `mysql-backup-prod`.

- `make prod-up` / `make prod-down` / `make prod-restart` — lifecycle
- `make prod-test` — full backup pipeline on production
- `make prod-test-backup` / `make prod-test-upload` / `make prod-test-sync` — individual stages
- `make prod-test-notify` — notification from production container
- `make prod-logs` / `make prod-logs-upload` / `make prod-logs-sync` / `make prod-logs-run` — tail logs
- `make prod-update` — rebuild and restart production (picks up `.env.prod` changes)

For other stacks (minio-s3, portainer), `cd` into their directory and run `docker compose up -d` directly.

## Gotchas

- **Port 9000 conflict**: minio-s3 API and portainer HTTP UI both default to 9000. Change one before running both.
- **`global-network` is external**: minio-s3 requires `docker network create global-network` before it can start. Other stacks don't use it.
- **`mysql-backup/.env` and `.env.prod` contain real secrets** (DB credentials, DigitalOcean keys, webhook URLs). Both are gitignored but double-check before committing.
- **Root `.gitignore` only covers root-level `.env`**. Each service subdirectory has its own `.gitignore`.
- **Portainer `.env-example` defines vars (`PORTAINER_HTTP_PORT` etc.) that its `docker-compose.yml` does not use** — ports are hardcoded.
- **Production compose overrides**: `docker-compose.prod.yml` sets container name to `mysql-backup-prod` and mounts `servers.prod.json` instead of `servers.json`.

## Multi-Server Config (`servers.json`)

DB connections are defined in `mysql-backup/servers.json` (dev) or `mysql-backup/servers.prod.json` (production). Each entry has `name`, `host`, `port`, `user`, `pass`, `s3_path` (optional S3 prefix override), and `databases` (list of DBs to dump). See `servers.json.example` for the format. The old env vars `DB_SERVER`/`DB_PORT`/`DB_USER`/`DB_PASS`/`DB_NAMES` are no longer used.

## Env Files

Copy `.env.example` (or `.env-example` for portainer) to `.env` in each service directory before starting. The minio and portainer stacks have defaults baked into compose; mysql-backup requires a real `.env` to function. For production, copy `.env.example` to `.env.prod` and `servers.json.example` to `servers.prod.json`.

## No CI, Lint, or Test Framework

This is a pure infrastructure repo. Verification is manual via `make test-*` / `make prod-test-*` targets (requires running containers).
