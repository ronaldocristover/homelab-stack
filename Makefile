.PHONY: build up restart down logs logs-upload logs-sync logs-run \
        test test-run test-backup test-upload test-sync test-notify test-notify-host update \
        prod-build prod-up prod-down prod-restart prod-logs prod-test prod-test-run \
        prod-test-backup prod-test-upload prod-test-sync prod-test-notify prod-update

COMPOSE = docker compose
COMPOSE_PROD = docker compose -f docker-compose.yml -f docker-compose.prod.yml --env-file .env.prod

# ── Dev targets ────────────────────────────────────────────────────

build:
	$(COMPOSE) build --force-recreate

up:
	$(COMPOSE) up -d --build --force-recreate

down:
	$(COMPOSE) down

restart: down up

test: up test-run

test-run:
	@echo "Running full backup pipeline (backup + sync + upload + Discord embed)..."
	$(COMPOSE) exec mysql-backup /scripts/run.sh

test-backup:
	@echo "Running backup only..."
	$(COMPOSE) exec mysql-backup /scripts/backup.sh

test-upload:
	@echo "Running upload only..."
	$(COMPOSE) exec mysql-backup /scripts/upload.sh

test-sync:
	@echo "Running local HDD sync only..."
	$(COMPOSE) exec mysql-backup /scripts/sync-local.sh

test-notify:
	@echo "Testing notification from container..."
	$(COMPOSE) exec mysql-backup /scripts/notify.sh "TEST" "manual test at $$(date)"

test-notify-host:
	@echo "Testing notification from host..."
	bash scripts/test-notify.sh

logs:
	$(COMPOSE) exec mysql-backup tail -50 /var/log/backup.log

logs-upload:
	$(COMPOSE) exec mysql-backup tail -50 /var/log/upload.log

logs-sync:
	$(COMPOSE) exec mysql-backup tail -50 /var/log/sync-local.log

logs-run:
	$(COMPOSE) logs -f mysql-backup

update: up
	@echo "Rebuilt and restarted with latest .env"

# ── Production targets ─────────────────────────────────────────────

prod-build:
	$(COMPOSE_PROD) build --force-recreate

prod-up:
	$(COMPOSE_PROD) up -d --build --force-recreate

prod-down:
	$(COMPOSE_PROD) down

prod-restart: prod-down prod-up

prod-test: prod-up prod-test-run

prod-test-run:
	@echo "[PROD] Running full backup pipeline..."
	$(COMPOSE_PROD) exec mysql-backup-prod /scripts/run.sh

prod-test-backup:
	@echo "[PROD] Running backup only..."
	$(COMPOSE_PROD) exec mysql-backup-prod /scripts/backup.sh

prod-test-upload:
	@echo "[PROD] Running upload only..."
	$(COMPOSE_PROD) exec mysql-backup-prod /scripts/upload.sh

prod-test-sync:
	@echo "[PROD] Running local HDD sync only..."
	$(COMPOSE_PROD) exec mysql-backup-prod /scripts/sync-local.sh

prod-test-notify:
	@echo "[PROD] Testing notification from container..."
	$(COMPOSE_PROD) exec mysql-backup-prod /scripts/notify.sh "TEST" "manual test at $$(date)"

prod-logs:
	$(COMPOSE_PROD) exec mysql-backup-prod tail -50 /var/log/backup.log

prod-logs-upload:
	$(COMPOSE_PROD) exec mysql-backup-prod tail -50 /var/log/upload.log

prod-logs-sync:
	$(COMPOSE_PROD) exec mysql-backup-prod tail -50 /var/log/sync-local.log

prod-logs-run:
	$(COMPOSE_PROD) logs -f mysql-backup-prod

prod-update: prod-up
	@echo "Rebuilt and restarted production with latest .env.prod"
