# Netresearch TYPO3 Demo

A reproducible, disposable TYPO3 14 showcase for the Netresearch extension suite.
Live at **<https://typo3-demo.netresearch.de/>**.

The instance runs the **same container stack in local dev and in production**
(web, worker, MariaDB, Valkey, Caddy) so what you see locally matches the
deployed site. It is fully GitOps-driven: merge to `main` → images build → the
host pulls and updates itself. There is no manual server editing.

## Showcased extensions

| Extension | What it demonstrates | Backend entry point |
|-----------|----------------------|---------------------|
| `netresearch/nr-llm` | Central AI/LLM foundation (providers, encrypted keys, chat/vision/embeddings) | Admin Tools › LLM |
| `netresearch/nr-mcp-agent` | Tool-using AI chat agent in the backend | Admin Tools › AI Chat |
| `netresearch/nr-vault` | Encrypted secrets management (backs the LLM API keys) | Admin Tools › Vault |
| `netresearch/nr-passkeys-be` | Passwordless backend login (WebAuthn/FIDO2) | User Settings › Account security |
| `netresearch/nr-passkeys-fe` | Passkey login for frontend users | Web › FE Passkeys |
| `netresearch/nr-repurpose` | Turn a page/PDF into a podcast, diagram and story | Web › Repurpose |
| `netresearch/nr-landingpage` | AI-generated landing pages from reusable templates | Web › Landing Pages |
| `netresearch/nr-browser-ai` | On-device page assistant via Chrome's built-in AI, no API key and no server call | (content element on `/extensions/browser-ai`) |
| `netresearch/t3-cowriter` | AI writing assistant inside CKEditor | Tools › Cowriter Status |
| `netresearch/nr-temporal-cache` | Time-based page-cache invalidation | Tools › Temporal Cache |
| `netresearch/rte-ckeditor-image` | Image support inside the RTE | (RTE toolbar) |
| `apache-solr-for-typo3/solr` | Full-text search over the demo content (spike) | Search module (Index Queue / Info) |

The backend has two dashboards: **Netresearch Demo** (one explainer card per
extension, each with a "how to demo it" recipe) and **Netresearch Widgets**
(the extensions' own live dashboard widgets).

### Apache Solr (spike)

EXT:solr is a **release-candidate** dependency (`14.0.0-RC1`; there is no stable
v14 yet, hence the `@RC` constraint in `composer.json`). The `solr` service runs
always-on but memory-bounded for the 4GB host: a **256M JVM heap** under a
**512M** container limit, and the `worker` service was trimmed from 1G to 768M
to make room. It is internal-only (no published ports; reached at `solr:8983`
over the compose network) and its connection is configured in the site
`config.yaml` (`solr_host_read` etc.). A larger host (**8GB**) is recommended
for comfortable always-on use. EXT:solr v14 provides no indexing console
command — populate the index via **Web › Search › Index Queue** plus the
**Index Queue Worker** scheduler task.

## Quick start

Requires Docker with the Compose plugin, plus one login: the database runs the
**MariaDB Docker Hardened Image**, and `dhi.io` serves no anonymous pulls.

```bash
docker login dhi.io           # Docker Hub account with DHI entitlement
make up                       # pulls prebuilt images from GHCR, starts the stack, seeds on first boot
```

The hardened image carries a minimal debian-13 base and an entrypoint that
honours `MARIADB_ROOT_PASSWORD` and nothing else. Creating the application
database and user and importing `data/db.sql.gz` is therefore done by the
one-shot `db-init` service (`docker/db/init.sh`) instead of by the image.

Then open the URL printed by `make up` (defaults to `localhost`). The backend is
at `/typo3/`. Backend user is **`nr_admin`**; the demo password lives in the
team password manager (it is not stored in this repo). The database seed is
imported automatically on first boot, including demo content, landing-page
templates and both dashboards.

```bash
make down                     # stop
make logs                     # tail service logs
make shell                    # shell in the web container
make db-shell                 # MariaDB shell
```

## Local development

```bash
make dev                      # builds locally; bind-mounts packages/ and config/, Xdebug on, DB on 127.0.0.1:${DB_PORT:-3306}
make dev-down
```

`make dev` is the mode to use when editing the site package or an extension
symlinked into `packages/` — changes are reflected without a rebuild.

## Data lifecycle

The database and fileadmin live in named Docker volumes. Only these commands
touch data:

```bash
make reset                    # purge app data + re-seed from data/db.sql.gz (preserves Caddy TLS certs)
make update                   # pull new images + migrate + apply seed-extensions + flush caches (no data purge)
make seed-extensions          # (idempotent) apply data/seed-extensions.sql — extra demo records, dashboards, templates
make export-seed              # dump the current DB back to data/db.sql.gz
```

`make up` and `make update` prune dangling images automatically, so the host
disk stays bounded across repeated deploys.

To change installed extension **versions**, edit the constraints in
`composer.json` and merge — dependencies resolve at image-build time (there is
no committed `composer.lock`).

## How deployment works

Merging to `main` triggers, in order:

1. **Build** (`.github/workflows/build.yml`) — builds and pushes the multi-arch
   image to GHCR; a `validate` job brings the stack up on push to `main`.
2. **Deploy (Update)** (`update.yml`) — SSHes into the host and runs
   `git pull && make update`.

Never SSH in to edit files by hand; change the repo and let the pipeline deploy.

## The OpenAI key

Every AI module on this instance resolves its key through nr-vault, and the
committed dump deliberately carries neither the vault secret nor the provider's
reference to it — `scripts/export-seed-sanitized.sh` strips both before the dump
is published, because the repository is public.

Something therefore has to put the key back after every import, and that is the
`OPENAI_API_KEY` repository secret. `make update` runs `make provision-llm-key`
just before the seed: it stores the value as the vault secret `openai-api-key`
(passed on stdin, never as an argument, never echoed) and points
`tx_nrllm_provider.api_key` at that identifier. The step is idempotent, verifies
both halves afterwards, and fails the deploy if either is missing.

Without the secret the deploy still succeeds and says so — a missing key must
not take the whole instance down — but every AI module reports "API key
identifier is required for provider OpenAI" until it is set. Rotating the key
means updating the repository secret and re-running the deploy; nothing has to
be clicked in the backend, and no reset can lose it again.

## Verifying the image SBOM

Every image pushed from `main` carries a CycloneDX SBOM as a signed GitHub
attestation. Verifying it needs two flags that are easy to miss:

```console
$ gh attestation verify oci://ghcr.io/netresearch/typo3-demo:latest \
    --repo netresearch/typo3-demo \
    --predicate-type https://cyclonedx.org/bom \
    --signer-repo netresearch/.github
```

Without them the command fails, and it fails in a way that reads like the
attestation is missing rather than like the query is wrong:

- **`--predicate-type`** — `verify` looks for SLSA provenance unless told
  otherwise, and this is an SBOM attestation. Omitting it answers `HTTP 404:
  Not Found`.
- **`--signer-repo`** — the attestation is signed by the shared workflow, not
  by this repository. The certificate names
  `netresearch/.github/.github/workflows/attest-sbom.yml@refs/heads/main`, so
  `--repo` alone cannot match the signer and verification is refused.

To read the SBOM itself, add `--format json` and take `.[0].verificationResult
.statement.predicate`.

## Operations workflows (manual, `workflow_dispatch`)

Run these from the repo's **Actions** tab:

| Workflow | Purpose |
|----------|---------|
| `Deploy (Fresh Install)` | Full reset + reinstall (wipes data — requires typing `yes`) |
| `Reset BE Admin Password` | Reset a backend user's password to the `TYPO3_BE_ADMIN_PASSWORD` secret |
| `Remote Diagnostics` | Read-only host/DB snapshot, output encrypted with `DIAG_PASSPHRASE` |
| `Export DB Seed` | Produce a **sanitized** DB dump (API keys/secrets/logs stripped) as an encrypted artifact for review before committing |
| `Host Maintenance` | Deeper disk reclaim (all unused images + build cache; never volumes) with `df` before/after |

## Layout

```
compose.yml / compose.dev.yml   # production stack / dev overrides
docker/                         # web + db images, entrypoint
data/                           # db.sql.gz (LFS seed), seed-extensions.sql, fileadmin
packages/netresearch-demo-site  # site package: TypoScript, RTE preset, dashboard widgets/presets
config/                         # TYPO3 site + system config
deploy/                         # host provisioning
.github/workflows/              # build, deploy, and the ops workflows above
```
