.PHONY: help build start stop restart logs clean

help: ## Show this help message
	@echo "MinIO Homelab Stack Commands:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

build: ## Build and start MinIO services
	@echo "Building and starting MinIO services..."
	@cd minio-s3 && docker compose build
	@cd minio-s3 && docker compose up -d

start: ## Start MinIO services
	@echo "Starting MinIO services..."
	@cd minio-s3 && docker compose up -d

stop: ## Stop MinIO services
	@echo "Stopping MinIO services..."
	@cd minio-s3 && docker compose down

restart: ## Restart MinIO services
	@echo "Restarting MinIO services..."
	@cd minio-s3 && docker compose restart
	@echo "Waiting for services to be healthy..."
	@sleep 10
	@cd minio-s3 && docker compose ps

logs: ## Show MinIO service logs
	@echo "Showing MinIO service logs..."
	@cd minio-s3 && docker compose logs -f minio

status: ## Check MinIO service status
	@echo "Checking MinIO service status..."
	@cd minio-s3 && docker compose ps

clean: ## Stop and remove MinIO containers and volumes
	@echo "Stopping and removing MinIO containers and volumes..."
	@cd minio-s3 && docker compose down -v
	@echo "MinIO stack cleaned up"

rebuild: ## Clean, build, and restart MinIO services
	@echo "Cleaning, building, and restarting MinIO services..."
	@$(MAKE) clean
	@$(MAKE) build
	@$(MAKE) status