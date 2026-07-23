.PHONY: up down reset update logs shell db-shell seed seed-extensions export-seed build clean dev dev-down prune help

COMPOSE     := docker compose
COMPOSE_DEV := docker compose -f compose.yml -f compose.dev.yml
# Run the TYPO3 CLI as the php-fpm user: a root exec creates root-owned
# cache/log files that php-fpm (www-data) can no longer write, which breaks
# the backend on the next warning-level log record.
TYPO3       := $(COMPOSE) exec -T -u www-data web vendor/bin/typo3

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

up: ## Start all services (pulls pre-built images from GHCR)
	@test -f .env || { test -f .env.example && cp .env.example .env || { echo "ERROR: .env.example not found"; exit 1; }; }
	$(COMPOSE) pull
	$(COMPOSE) up -d --wait --wait-timeout 180 || $(COMPOSE) up -d
	$(MAKE) prune
	@echo "TYPO3 Demo running at $${TYPO3_DOMAIN:-localhost}"

up-build: ## Start all services (builds images locally)
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

reset: ## Full reset: purge app data and re-seed (preserves Caddy TLS certs)
	$(COMPOSE) down --volumes --remove-orphans
	docker volume rm -f typo3-demo_typo3-db typo3-demo_typo3-fileadmin typo3-demo_typo3-var typo3-demo_typo3-config 2>/dev/null || true
	@echo "App volumes purged (caddy-data preserved). Run 'make up' to re-seed."

update: ## Update code without purging data
	$(COMPOSE) pull
	$(COMPOSE) up -d --wait --wait-timeout 180 || $(COMPOSE) up -d
	$(TYPO3) database:updateschema || true
	$(MAKE) seed-extensions
	$(TYPO3) extension:setup || true
	$(TYPO3) cache:flush
	$(TYPO3) cache:warmup
	-@echo "===DIAG-BEGIN==="
	-@echo "[waiting 90s for worker to drain the nr_ai_search queue]"; sleep 90
	-$(COMPOSE) ps --format 'table {{.Service}}\t{{.Status}}' 2>&1
	-$(COMPOSE) exec -T db sh -c 'MYSQL_PWD="$$MARIADB_PASSWORD" mariadb -u"$$MARIADB_USER" "$$MARIADB_DATABASE" -N -e "SELECT CONCAT(\"chunks=\",COUNT(*)) FROM tx_nraisearch_chunk; SELECT CONCAT(queue_name,\": total=\",COUNT(*),\" delivered=\",SUM(delivered_at IS NOT NULL)) FROM sys_messenger_messages GROUP BY queue_name;" 2>&1'
	-$(COMPOSE) exec -T worker sh -c 'pgrep -af "[m]essenger:consume" 2>&1 | head -2'
	-$(COMPOSE) exec -T web sh -c 'echo "--embed/vault errors (lochmueller flood excluded)--"; grep -hiE "NrAiSearch|Embedding|CircuitOpen|AccessDenied|Vault|VectorRetrieval|Vektor|handling message|for retry|nr_ai_search" var/log/typo3_*.log 2>/dev/null | grep -viE "Lochmueller|bodytext" | tail -20'
	-@echo "===DIAG-END==="
	$(MAKE) prune

prune: ## Remove dangling images left behind by image pulls (keeps volumes + in-use images)
	docker image prune -f

seed: ## Seed fileadmin from data/ into volume
	$(COMPOSE) cp data/fileadmin/. web:/var/www/public/fileadmin/
	$(COMPOSE) exec -T web chown -R www-data:www-data /var/www/public/fileadmin

seed-extensions: ## Apply data/seed-extensions.sql to the DB (idempotent — INSERT IGNORE only)
	$(COMPOSE) exec -T db sh -c 'MYSQL_PWD="$$MARIADB_PASSWORD" mariadb -u "$$MARIADB_USER" "$$MARIADB_DATABASE"' < data/seed-extensions.sql

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
