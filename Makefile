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
	docker volume rm -f typo3-demo_typo3-db-v2 typo3-demo_typo3-db typo3-demo_typo3-fileadmin typo3-demo_typo3-var typo3-demo_typo3-config 2>/dev/null || true
	@echo "App volumes purged (caddy-data preserved). Run 'make up' to re-seed."

update: ## Update code without purging data
	$(COMPOSE) pull
	# --remove-orphans: a service deleted from compose.yml otherwise keeps running
	# forever. The reverted EXT:solr spike kept its container alive for 8 days and
	# grew a 29.6GB writable layer, which filled the disk and broke the deploy.
	$(COMPOSE) up -d --remove-orphans --wait --wait-timeout 180 || $(COMPOSE) up -d --remove-orphans
	$(TYPO3) database:updateschema || true
	$(MAKE) seed-extensions
	$(TYPO3) extension:setup || true
	$(TYPO3) cache:flush
	$(TYPO3) cache:warmup
	$(MAKE) prune

prune: ## Remove dangling images left behind by image pulls (keeps volumes + in-use images)
	docker image prune -f

seed: ## Seed fileadmin from data/ into volume
	$(COMPOSE) cp data/fileadmin/. web:/var/www/public/fileadmin/
	$(COMPOSE) exec -T web chown -R www-data:www-data /var/www/public/fileadmin

seed-extensions: ## Apply data/seed-extensions.sql to the DB (idempotent; fails on SEED-PROBLEM)
	@# The client output is captured rather than piped so that BOTH failure modes
	@# stay visible: a real SQL error (the client exits non-zero and aborts the
	@# import) and a silently skipped record (the import succeeds, but the
	@# verification at the end of the .sql file prints SEED-PROBLEM lines). Piping
	@# straight into grep would hide the client's exit code behind grep's.
	@set -e; \
	out=$$(mktemp); \
	trap 'rm -f "$$out"' EXIT; \
	echo "Applying data/seed-extensions.sql ..."; \
	if ! $(COMPOSE) exec -T db sh -c 'MYSQL_PWD="$$MARIADB_PASSWORD" mariadb -u "$$MARIADB_USER" "$$MARIADB_DATABASE"' < data/seed-extensions.sql > "$$out" 2>&1; then \
		cat "$$out" >&2; \
		echo "ERROR: seed import failed — the database client reported an error (above)." >&2; \
		exit 1; \
	fi; \
	cat "$$out"; \
	if grep -q '^SEED-PROBLEM:' "$$out"; then \
		echo "ERROR: seeded records are missing or their uids are held by foreign rows (SEED-PROBLEM lines above)." >&2; \
		echo "       Move the affected records to free uids in data/seed-extensions.sql; the seed never overwrites a foreign row." >&2; \
		exit 1; \
	fi; \
	echo "Seed applied and verified."

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
