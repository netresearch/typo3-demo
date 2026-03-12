.PHONY: up down reset update logs shell db-shell seed export-seed build clean dev dev-down help

COMPOSE     := docker compose
COMPOSE_DEV := docker compose -f compose.yml -f compose.dev.yml
TYPO3       := $(COMPOSE) exec -T web vendor/bin/typo3

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

up: ## Start all services (fresh seed if DB is empty)
	@test -f .env || { test -f .env.example && cp .env.example .env || { echo "ERROR: .env.example not found"; exit 1; }; }
	$(COMPOSE) up -d --build --wait
	@echo "TYPO3 Demo running at $${TYPO3_DOMAIN:-localhost}"

dev: ## Start in dev mode (bind mounts, xdebug, DB port exposed)
	@test -f .env || { test -f .env.example && cp .env.example .env || { echo "ERROR: .env.example not found"; exit 1; }; }
	$(COMPOSE_DEV) up -d --build --wait
	@echo "TYPO3 Dev running at $${TYPO3_DOMAIN:-localhost} (xdebug enabled, DB on 127.0.0.1:$${DB_PORT:-3306})"

dev-down: ## Stop dev services
	$(COMPOSE_DEV) down

down: ## Stop all services
	$(COMPOSE) down

reset: ## Full reset: purge all data and re-seed
	$(COMPOSE) down -v
	@echo "All volumes purged. Run 'make up' to re-seed."

update: ## Update code without purging data
	$(COMPOSE) pull
	$(COMPOSE) build
	$(COMPOSE) up -d --wait
	$(TYPO3) database:updateschema || true
	$(TYPO3) extension:setup || true
	$(TYPO3) cache:flush
	$(TYPO3) cache:warmup

seed: ## Seed fileadmin from data/ into volume
	$(COMPOSE) cp data/fileadmin/. web:/var/www/public/fileadmin/
	$(COMPOSE) exec -T web chown -R www-data:www-data /var/www/public/fileadmin

export-seed: ## Export current DB as new seed
	$(COMPOSE) exec -T db sh -c 'MYSQL_PWD="$$MARIADB_ROOT_PASSWORD" mariadb-dump -u root "$$MARIADB_DATABASE" --single-transaction --quick --skip-lock-tables' | gzip > data/db.sql.gz
	@echo "Seed exported to data/db.sql.gz ($$(du -h data/db.sql.gz | cut -f1))"

logs: ## Tail service logs
	$(COMPOSE) logs -f

shell: ## Open shell in web container
	$(COMPOSE) exec web sh

db-shell: ## Open MariaDB shell
	$(COMPOSE) exec db sh -c 'MYSQL_PWD="$$MARIADB_PASSWORD" mariadb -u "$$MARIADB_USER" "$$MARIADB_DATABASE"'

build: ## Build images with bake
	docker buildx bake

clean: ## Remove all containers, volumes, and images
	$(COMPOSE) down -v --rmi local
	@echo "Cleaned up."
