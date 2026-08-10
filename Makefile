.PHONY: up down reset update logs shell db-shell seed seed-extensions provision-llm-key export-seed build clean dev dev-down prune help

COMPOSE     := docker compose
COMPOSE_DEV := docker compose -f compose.yml -f compose.dev.yml
# Run the TYPO3 CLI as the php-fpm user: a root exec creates root-owned
# cache/log files that php-fpm (www-data) can no longer write, which breaks
# the backend on the next warning-level log record.
TYPO3       := $(COMPOSE) exec -T -u www-data web vendor/bin/typo3
# Identifier under which the OpenAI key lives in nr_vault. It is a name, not the
# key: tx_nrllm_provider.api_key stores this string and nr_vault resolves the
# value from it, so the key itself never touches the database in plaintext.
LLM_KEY_ID  := openai-api-key

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
	# Before seed-extensions, not after: the seed's grant on the vault secret is
	# conditional on tx_nrllm_provider.api_key being non-empty and silently does
	# nothing while it is not.
	$(MAKE) provision-llm-key
	$(MAKE) seed-extensions
	$(TYPO3) extension:setup || true
	$(TYPO3) cache:flush
	$(TYPO3) cache:warmup
	$(MAKE) prune

provision-llm-key: ## Store $OPENAI_API_KEY in the vault and point the OpenAI provider at it
	@# Without this the demo has no LLM at all: the sanitized dump ships
	@# tx_nrllm_provider.api_key empty by design (export-seed-sanitized.sh clears
	@# it and drops tx_nrvault_secret), so every AI module fails with "API key
	@# identifier is required for provider OpenAI" until something sets it. That
	@# something used to be a human clicking through the backend, which no reset
	@# survived and nothing reproduced.
	@#
	@# The value is passed on stdin and never as an argument: /proc is readable
	@# inside the container, so an argv secret is visible to every process there.
	@# It is never echoed either — only its presence is reported.
	@set -e; \
	if [ -z "$${OPENAI_API_KEY:-}" ]; then \
		echo "OPENAI_API_KEY is not set - skipping LLM key provisioning."; \
		echo "         The AI modules remain non-functional until it is provided."; \
		exit 0; \
	fi; \
	echo "Storing the OpenAI key as vault secret '$(LLM_KEY_ID)' ..."; \
	printf '%s' "$$OPENAI_API_KEY" | $(TYPO3) vault:store $(LLM_KEY_ID) --stdin >/dev/null; \
	echo "UPDATE tx_nrllm_provider SET api_key = '$(LLM_KEY_ID)' WHERE uid = 1;" \
		| $(COMPOSE) exec -T db sh -c 'MYSQL_PWD="$$MARIADB_PASSWORD" mariadb -u "$$MARIADB_USER" "$$MARIADB_DATABASE"'; \
	state=$$(echo "SELECT CONCAT(\
		(SELECT COUNT(*) FROM tx_nrvault_secret WHERE identifier = '$(LLM_KEY_ID)' AND deleted = 0), \
		':', \
		(SELECT LENGTH(api_key) FROM tx_nrllm_provider WHERE uid = 1));" \
		| $(COMPOSE) exec -T db sh -c 'MYSQL_PWD="$$MARIADB_PASSWORD" mariadb -N -u "$$MARIADB_USER" "$$MARIADB_DATABASE"'); \
	case "$$state" in \
		0:*) echo "ERROR: vault:store reported success but no secret '$(LLM_KEY_ID)' exists." >&2; exit 1 ;; \
		*:0) echo "ERROR: the provider row was not linked to the vault secret." >&2; exit 1 ;; \
	esac; \
	echo "OpenAI key provisioned and linked to provider 1."

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
