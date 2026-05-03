.PHONY: build up down restart logs logs-upload logs-sync logs-run \
        test test-run test-backup test-upload test-s3 test-sync test-notify test-notify-host update \
        prod-build prod-up prod-down prod-restart prod-logs prod-test prod-test-run \
        prod-test-backup prod-test-upload prod-test-s3 prod-test-sync prod-test-notify prod-update

COMPOSE_PROD = docker compose -f docker-compose.yml -f docker-compose.prod.yml --env-file .env.prod
PROD_EXEC = $(COMPOSE_PROD) exec mysql-backup-prod

# ── Dev targets ────────────────────────────────────────────────────

build:
	docker compose build

up:
	docker compose up -d --build --force-recreate

down:
	docker compose down

restart: down up

test: up test-run

test-run:
	@echo "Running full backup pipeline (backup + sync + upload + Discord embed)..."
	docker compose exec mysql-backup /scripts/run.sh

test-backup:
	@echo "Running backup only..."
	docker compose exec mysql-backup /scripts/backup.sh

test-upload:
	@echo "Running upload only..."
	docker compose exec mysql-backup /scripts/upload.sh

test-s3:
	@echo "Testing S3 / DigitalOcean Spaces connectivity (bucket access + write + delete)..."
	docker compose exec mysql-backup bash /scripts/test-s3.sh

test-sync:
	@echo "Running local HDD sync only..."
	docker compose exec mysql-backup /scripts/sync-local.sh

test-notify:
	@echo "Testing notification from container..."
	docker compose exec mysql-backup /scripts/notify.sh "TEST" "manual test at $$(date)"

test-notify-host:
	@echo "Testing notification from host..."
	bash scripts/test-notify.sh

logs:
	docker compose exec mysql-backup tail -50 /var/log/backup.log

logs-upload:
	docker compose exec mysql-backup tail -50 /var/log/upload.log

logs-sync:
	docker compose exec mysql-backup tail -50 /var/log/sync-local.log

logs-run:
	docker compose logs -f mysql-backup

update: up
	@echo "Rebuilt and restarted with latest .env"

# ── Production targets ─────────────────────────────────────────────

prod-build:
	$(COMPOSE_PROD) build

prod-up:
	$(COMPOSE_PROD) up -d --build --force-recreate

prod-down:
	$(COMPOSE_PROD) down

prod-restart: prod-down prod-up

prod-test: prod-up prod-test-run

prod-test-run:
	@echo "[PROD] Running full backup pipeline..."
	$(PROD_EXEC) /scripts/run.sh

prod-test-backup:
	@echo "[PROD] Running backup only..."
	$(PROD_EXEC) /scripts/backup.sh

prod-test-upload:
	@echo "[PROD] Running upload only..."
	$(PROD_EXEC) /scripts/upload.sh

prod-test-s3:
	@echo "[PROD] Testing S3 connectivity..."
	$(PROD_EXEC) bash /scripts/test-s3.sh

prod-test-sync:
	@echo "[PROD] Running local HDD sync only..."
	$(PROD_EXEC) /scripts/sync-local.sh

prod-test-notify:
	@echo "[PROD] Testing notification from container..."
	$(PROD_EXEC) /scripts/notify.sh "TEST" "manual test at $$(date)"

prod-logs:
	$(PROD_EXEC) tail -50 /var/log/backup.log

prod-logs-upload:
	$(PROD_EXEC) tail -50 /var/log/upload.log

prod-logs-sync:
	$(PROD_EXEC) tail -50 /var/log/sync-local.log

prod-logs-run:
	$(COMPOSE_PROD) logs -f mysql-backup-prod

prod-update: prod-up
	@echo "Rebuilt and restarted production with latest .env.prod"
