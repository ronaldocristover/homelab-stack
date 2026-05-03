.PHONY: build up restart down logs logs-upload logs-sync logs-run \
        test test-run test-backup test-upload test-sync test-notify test-notify-host update

build:
	docker compose build

up:
	docker compose up -d

down:
	docker compose down

restart: down up

# Full pipeline: backup + sync + upload + rich Discord embed
test: test-run

test-run:
	@echo "Running full backup pipeline (backup + sync + upload + Discord embed)..."
	docker compose exec mysql-backup /run.sh

test-backup:
	@echo "Running backup only..."
	docker compose exec mysql-backup /backup.sh

test-upload:
	@echo "Running upload only..."
	docker compose exec mysql-backup /upload.sh

test-sync:
	@echo "Running local HDD sync only..."
	docker compose exec mysql-backup /sync-local.sh

# Plain text notification from inside the container
test-notify:
	@echo "Testing notification from container..."
	docker compose exec mysql-backup /notify.sh "TEST" "manual test at $$(date)"

# Plain text notification from host — reads .env directly, no container needed
test-notify-host:
	@echo "Testing notification from host..."
	bash test-notify.sh

logs:
	docker compose exec mysql-backup tail -50 /var/log/backup.log

logs-upload:
	docker compose exec mysql-backup tail -50 /var/log/upload.log

logs-sync:
	docker compose exec mysql-backup tail -50 /var/log/sync-local.log

logs-run:
	docker compose logs -f mysql-backup

update: build up
	@echo "Rebuilt and restarted with latest .env"
