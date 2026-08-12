<<<<<<< HEAD
.PHONY: up down reset update logs shell db-shell seed seed-extensions provision-llm-key provision-deepl-key export-seed build clean dev dev-down prune help
=======
.PHONY: up down reset update logs shell db-shell seed seed-extensions provision-llm-key persist-env-secret export-seed build clean dev dev-down prune help
>>>>>>> origin/main

COMPOSE     := docker compose
COMPOSE_DEV := docker compose -f compose.yml -f compose.dev.yml
# Run the TYPO3 CLI as the php-fpm user: a root exec creates root-owned
# cache/log files that php-fpm (www-data) can no longer write, which breaks
# the backend on the next warning-level log record.
TYPO3       := $(COMPOSE) exec -T -u www-data web vendor/bin/typo3
# Identifier under which the OpenAI key lives in nr_vault. It is a name, not the
# key: tx_nrllm_provider.api_key stores this string and nr_vault resolves the
# value from it, so the key itself never touches the database in plaintext.
# Underscores, no hyphens: nr_vault validates a non-UUID identifier against
# /^[a-zA-Z]\w*$$/ (IdentifierValidator::USER_PATTERN) and rejects anything else.
LLM_KEY_ID  := openai_api_key

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
<<<<<<< HEAD
	# Runs before up: the containers read DEEPL_API_KEY from .env at creation time.
	$(MAKE) provision-deepl-key
=======
	# Runs before `up`: containers read their environment from .env at creation
	# time, and the deploy session's variables are gone by the next host reboot.
	$(MAKE) persist-env-secret SECRET_NAME=OPENAI_API_KEY
>>>>>>> origin/main
	$(COMPOSE) pull
	# --remove-orphans: a service deleted from compose.yml otherwise keeps running
	# forever. The reverted EXT:solr spike kept its container alive for 8 days and
	# grew a 29.6GB writable layer, which filled the disk and broke the deploy.
	$(COMPOSE) up -d --remove-orphans --wait --wait-timeout 180 || $(COMPOSE) up -d --remove-orphans
	$(TYPO3) database:updateschema || true
	# Three steps in a cycle, and the order is the whole point:
	#
	#   seed      creates be_users 991 and its group — the identity
	#             provision-llm-key acts as
	#   provision creates the vault secret and links tx_nrllm_provider.api_key
	#             to it
	#   seed      grants the nr_ai_search technical user ownership of that
	#             secret, which it can only do once the secret exists AND
	#             api_key is non-empty
	#
	# Provisioning first looked right — the grant is conditional on api_key —
	# but the actor it needs is created by the very step that was supposed to
	# follow it. The deploy said so plainly: "Technical actor uid 991 does not
	# resolve to a non-deleted be_users record". The seed is idempotent and
	# takes well under a second, so running it on both sides of the
	# provisioning is cheaper than splitting it.
	$(MAKE) seed-extensions
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
	@#
	@# --as-provisioner writes as the seeded be_user 991 instead of the
	@# unattributed CLI actor. That user holds no admin flag; its group carries
	@# exactly tx_nrvault:secret.create and secret.rotate, so the deploy can
	@# create and rotate this one secret and nothing else, and every write is
	@# attributable to it in the vault audit log. The alternative, nr_vault's
	@# allowCliAccess, grants the same operation to every process with a shell
	@# in this container — it was removed here on purpose (72e123a) and is not
	@# coming back.
	@set -e; \
	if [ -z "$${OPENAI_API_KEY:-}" ]; then \
		echo "OPENAI_API_KEY is not set - skipping LLM key provisioning."; \
		echo "         The AI modules remain non-functional until it is provided."; \
		exit 0; \
	fi; \
	case "$(LLM_KEY_ID)" in \
		[a-zA-Z]*) : ;; \
		*) echo "ERROR: LLM_KEY_ID '$(LLM_KEY_ID)' must start with a letter." >&2; exit 1 ;; \
	esac; \
	if printf '%s' "$(LLM_KEY_ID)" | grep -q '[^a-zA-Z0-9_]'; then \
		echo "ERROR: LLM_KEY_ID '$(LLM_KEY_ID)' may contain only letters, digits" >&2; \
		echo "       and underscores - nr_vault rejects anything else, and finding" >&2; \
		echo "       that out costs a whole deploy cycle." >&2; \
		exit 1; \
	fi; \
	echo "Storing the OpenAI key as vault secret '$(LLM_KEY_ID)' ..."; \
	if ! out=$$(printf '%s' "$$OPENAI_API_KEY" | $(TYPO3) vault:store $(LLM_KEY_ID) --stdin --as-provisioner 2>&1); then \
		echo "ERROR: vault:store failed. Its output follows; the key is passed on" >&2; \
		echo "       stdin, so it cannot appear in the command line it reports." >&2; \
		printf '%s\n' "$$out" | sed 's/^/    /' >&2; \
		echo "    --- commands the CLI actually offers under 'vault' ---" >&2; \
		$(TYPO3) list vault 2>&1 | sed 's/^/    /' >&2 || true; \
		exit 1; \
	fi; \
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

<<<<<<< HEAD
provision-deepl-key: ## Persist $DEEPL_API_KEY in .env so autotranslate keeps it across reboots
	@# autotranslate has no nr_vault support (verified against v3.2.2 and upstream
	@# main): it reads its key from the extension configuration or from the site
	@# configuration, and nowhere else. The site configuration is public in this
	@# repository, so the extension configuration is the only usable place — the
	@# entrypoint writes it into config/system/additional.php from this variable.
	@#
	@# That leaves durability. compose passes DEEPL_API_KEY from the environment,
	@# which during a deploy is the SSH session's; a later `docker compose up`
	@# after a host reboot has no such session. Writing it into .env once makes
	@# every subsequent boot carry it, the same file that already holds
	@# MARIADB_PASSWORD.
	@#
	@# The value is never echoed and never passed as an argument; the file is
	@# rewritten through a temporary file with restrictive permissions.
	@set -e; \
	if [ -z "$${DEEPL_API_KEY:-}" ]; then \
		echo "DEEPL_API_KEY is not set - skipping DeepL key provisioning."; \
		echo "         A key already stored in config/system/additional.php is kept."; \
		echo "         Without any key autotranslate reports 'done' and translates"; \
		echo "         nothing (upstream issues #156/#157)."; \
=======
persist-env-secret: ## Write $$SECRET_NAME from the environment into .env (usage: make persist-env-secret SECRET_NAME=FOO)
	@# Some extensions cannot use nr_vault. ai_filemetadata reads a plain OpenAI
	@# key from its own extension configuration and has no vault support at all,
	@# so the key has to reach the container as an environment variable, which
	@# compose reads from .env at container creation time.
	@#
	@# The deploy passes it in the SSH session's environment, and that is enough
	@# for `compose up` during the deploy — but not for a `compose up` after a
	@# host reboot, which has no such session. Writing it into .env once makes
	@# every later boot carry it, in the same file that already holds
	@# MARIADB_PASSWORD.
	@#
	@# The value is never echoed and never passed as an argument, and the file is
	@# rewritten through a temporary file that a trap removes on any failure - it
	@# holds a full copy of .env, secrets included, until the mv lands.
	@#
	@# A literal dollar in the value is doubled on the way into .env. compose
	@# interpolates .env values, and it collapses a doubled dollar back to a single
	@# one there exactly as it does in compose.yml. Measured with printenv INSIDE a
	@# running container, compose v5.3.1.
	@#
	@# Do NOT verify this with `docker compose config`: it re-escapes a literal
	@# dollar in its own output, so a correct value is printed doubled and reads
	@# exactly like a corrupted one. That artefact already produced one wrong
	@# "measurement" in this file.
	@set -e; \
	test -n "$(SECRET_NAME)" || { echo "ERROR: SECRET_NAME= is required." >&2; exit 1; }; \
	case "$(SECRET_NAME)" in [A-Z]*) : ;; *) echo "ERROR: SECRET_NAME '$(SECRET_NAME)' must be an uppercase environment variable name." >&2; exit 1 ;; esac; \
	value=$$(printenv "$(SECRET_NAME)" || true); \
	if [ -z "$$value" ]; then \
		echo "$(SECRET_NAME) is not set - leaving .env untouched."; \
		echo "         A value stored on a previous deploy is kept."; \
>>>>>>> origin/main
		exit 0; \
	fi; \
	test -f .env || { echo "ERROR: .env is missing - run 'make up' first." >&2; exit 1; }; \
	umask 077; \
	tmp=$$(mktemp .env.XXXXXX); \
<<<<<<< HEAD
	grep -v '^DEEPL_API_KEY=' .env > "$$tmp" || true; \
	printf 'DEEPL_API_KEY=%s\n' "$$DEEPL_API_KEY" >> "$$tmp"; \
	chmod --reference=.env "$$tmp" 2>/dev/null || chmod 600 "$$tmp"; \
	mv "$$tmp" .env; \
	echo "DeepL key written to .env (length $${#DEEPL_API_KEY})."
=======
	trap 'rm -f "$$tmp"' EXIT INT TERM; \
	escaped=$$(printf '%s' "$$value" | sed 's/\$$/$$$$/g'); \
	: 'grep exit 1 means no line matched, which is normal; anything above that'; \
	: 'is a real failure and must not be swallowed - it would leave a .env'; \
	: 'holding only the new line. The status is captured directly, because'; \
	: 'inside an if-not construct the status reads as the negated one.'; \
	rc=0; grep -v "^$(SECRET_NAME)=" .env > "$$tmp" || rc=$$?; \
	[ "$$rc" -le 1 ] || { echo "ERROR: grep over .env failed (exit $$rc) - refusing to write a truncated .env" >&2; exit 1; }; \
	printf '%s=%s\n' "$(SECRET_NAME)" "$$escaped" >> "$$tmp"; \
	chmod 600 "$$tmp"; \
	mv "$$tmp" .env; \
	trap - EXIT INT TERM; \
	echo "$(SECRET_NAME) written to .env (length $${#value}), file mode 600."
>>>>>>> origin/main

prune: ## Remove dangling images left behind by image pulls (keeps volumes + in-use images)
	docker image prune -f

seed: ## Seed fileadmin from data/ into volume
	$(COMPOSE) cp data/fileadmin/. web:/var/www/public/fileadmin/
	$(COMPOSE) exec -T web chown -R www-data:www-data /var/www/public/fileadmin

seed-extensions: ## Apply data/seed-extensions.sql to the DB (idempotent; fails on SEED-PROBLEM)
	@# --default-character-set is stated rather than left to the client default.
	@# Every German string this file seeds currently reaches the frontend
	@# double-encoded — "genügt" renders as "genÃ¼gt" on both German extension
	@# pages, 93 and 94 occurrences respectively — which is what a UTF-8 file
	@# announced to the server as latin1 produces.
	@#
	@# What is proven: the file is UTF-8, the frontend output is double-encoded,
	@# and on the stock mariadb image the client already defaults to utf8mb4, so
	@# the flag changes nothing there. What is NOT proven: that the hardened
	@# image this stack runs defaults differently. It ships no configuration file
	@# at all, and the my.cnf mounted beside it sets only [mariadbd], leaving the
	@# client to its compiled-in default — but that server could not be stood up
	@# outside this stack to measure it.
	@#
	@# So the flag is a no-op if the diagnosis is wrong and a repair if it is
	@# right, and the seed re-asserts bodytext and pi_flexform on every import,
	@# which means the next deploy rewrites the affected rows either way. The
	@# next German page load is the measurement.
	@# The client output is captured rather than piped so that BOTH failure modes
	@# stay visible: a real SQL error (the client exits non-zero and aborts the
	@# import) and a silently skipped record (the import succeeds, but the
	@# verification at the end of the .sql file prints SEED-PROBLEM lines). Piping
	@# straight into grep would hide the client's exit code behind grep's.
	@set -e; \
	out=$$(mktemp); \
	trap 'rm -f "$$out"' EXIT; \
	echo "Applying data/seed-extensions.sql ..."; \
	if ! $(COMPOSE) exec -T db sh -c 'MYSQL_PWD="$$MARIADB_PASSWORD" mariadb --default-character-set=utf8mb4 -u "$$MARIADB_USER" "$$MARIADB_DATABASE"' < data/seed-extensions.sql > "$$out" 2>&1; then \
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
