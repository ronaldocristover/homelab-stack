.PHONY: build up restart down logs logs-upload logs-sync logs-run \
        test test-run test-backup test-upload test-s3 test-sync test-notify test-notify-host update

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
