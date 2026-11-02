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
| `netresearch/nr-passkeys-fe` | Passkey login for frontend users | Frontend Passkeys module |
| `netresearch/nr-repurpose` | Turn a page/PDF into a podcast, diagram and story | Content › Repurpose |
| `netresearch/nr-landingpage` | AI-generated landing pages from reusable templates | Content › Landing Pages |
| `netresearch/nr-browser-ai` | On-device page assistant via Chrome's built-in AI, no API key and no server call | (content element on `/extensions/browser-ai`) |
| `netresearch/t3-cowriter` | AI writing assistant inside CKEditor | Tools › Cowriter Status |
| `netresearch/nr-temporal-cache` | Time-based page-cache invalidation | Tools › Temporal Cache |
| `netresearch/rte-ckeditor-image` | Image support inside the RTE | (RTE toolbar) |

The backend has two dashboards: **Netresearch Demo** (one explainer card per
extension, each with a "how to demo it" recipe) and **Netresearch Widgets**
(the extensions' own live dashboard widgets).

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
`composer.json` **and refresh `composer.lock` in the same commit**:

```bash
composer update <package> --no-install --no-scripts
```

A partial update leaves every other package at its locked version and does not
need the private `git.netresearch.de` credential. `composer validate` in the
`composer-audit` job is the freshness gate and fails the build when the two
files disagree — the image and the attested SBOM would otherwise describe
different resolutions.

## How deployment works

Merging to `main` triggers, in order:

1. **Build** (`.github/workflows/build.yml`) — builds and pushes the multi-arch
   image to GHCR as `:latest` and `:sha-<commit>`; a `validate` job brings the
   stack up on push to `main`.
2. **Deploy (Update)** (`update.yml`) — SSHes into the host, fast-forwards the
   checkout to the commit that Build built (a manual run: `main`'s head),
   stores `TYPO3_DEMO_IMAGE_TAG=sha-<commit>` in `.env` and runs `make update`,
   so code and image always come from the same commit. A Build older than the
   deployed commit deploys nothing; a commit without an image fails the run.

Never SSH in to edit files by hand; change the repo and let the pipeline deploy.

## Install Tool checks

`make install-tool-check` runs the checks behind four views of the Install
Tool and prints every finding with its severity, check and message:

| Install Tool view | What runs | Check name in the output |
|-------------------|-----------|--------------------------|
| Environment › Environment Status | core's `Check`, `SetupCheck`, `DatabaseCheck` and `ServerResponseCheck` | `environment`, `sapi`, `server-response` |
| Environment › Directory Status | the `DefaultFactory` folder structure (nginx counts as "other web server") and the two create-mask checks | `directory` |
| Maintenance › Analyze Database Structure | `SchemaMigrator::getUpdateSuggestions()` with and without removals | `database` |
| Environment › Image Processing | the read, write, scale and convert tests, on core's own test images | `image` |

It runs the site package's `demo:install-tool:check`. Core ships no command for
any of these views, and `database:updateschema` belongs to typo3-console, which
this project does not install. The command applies nothing: the schema
comparison only lists statements. Like the backend, the server response probe,
the writability test of the directory check and the image tests write temporary
files and delete them again. Image Processing covers the ImageMagick read,
write, scale and convert tests; the view's TrueType, combine-mask and GDlib
tests produce images that only a person can compare with the reference, and
are not run.

The backend runs these checks under php-fpm; the command runs under the CLI.
Core skips the trusted-hosts comparison on the CLI and accepts the CLI's
unlimited `max_execution_time`, so the command evaluates both for php-fpm: the
trusted-hosts result appears under `environment`, `max_execution_time` under
`sapi`, together with every php.ini directive or PHP extension the checks read
that differs between the two SAPIs. The server response probe requests
its test files from the nginx in the `web` container: Caddy in front adds none
of the headers the probe evaluates.

`make update` runs the check after the cache warmup and the removal of the
schema leftovers ([below](#schema-leftovers)). A finding does not stop
the deploy, which has replaced the containers by then: unexpected findings
give the run a warning annotation, a check that did not run an error
annotation, and the full list is in the job log. The pull-request build runs
the same check on the image under test and fails on any unexpected finding.

A finding at warning or above counts as unexpected unless
[`expected-findings.yaml`](packages/netresearch-demo-site/Configuration/InstallTool/expected-findings.yaml)
lists it with the reason it is expected here.

### Expected Install Tool findings

What the four views show on this instance, and why. Entries marked
*listed* are in `expected-findings.yaml`; notices and information are below
the floor and listed here only.

| View | Severity | Finding | Class | Why |
|------|----------|---------|-------|-----|
| Directory Status | error | `/`, `/public`, `/config`, `/config/sites` not writable | intended, listed | The image owns the code and the site configuration; only `var/`, `config/system/`, `fileadmin/` and `typo3temp/` belong to `www-data`. Site configuration is versioned in `config/sites/` here, not edited in the backend. |
| Directory Status | warning | `/var/.htaccess` does not exist | false positive, listed | `var/` lies outside the document root, so the file would protect nothing. Core gates only the root `.htaccess` on the web server type. |
| Directory Status | notice | permissions mismatch (`0755`/`0644` instead of `2775`/`0664`) | intended | The image and the entrypoint create directories with the default umask; nginx reads `fileadmin/` and `typo3temp/` as another user, which these modes allow. |
| Directory Status | notice | `fileadmin/.htaccess` and `user_upload/_temp_/importexport/index.html` content differs | intended | The seed's copies; nginx ignores `.htaccess`, and `nginx.conf` denies the temp folders itself. |
| Directory Status | notice | create masks readable by anyone (`0664`, `2775`) | intended | nginx serves `fileadmin/` and `typo3temp/` as user `nginx`, not `www-data`; core's recommended `0660`/`2770` would make those files unreadable for it. |
| Environment Status | information | empty `systemLocale` | intended | No UTF-8 file names are in use (`UTF8filesystem` is off). |

Analyze Database Structure has no expected finding. `make update` and the
pull-request build remove the schema leftovers it used to list before the
check runs (next section), so every suggestion they report is new, unless the
removal failed: `make update` then adds an error annotation and still runs the
check. `data/db.sql.gz` still carries the leftovers
([#412](https://github.com/netresearch/typo3-demo/issues/412)): on a stack
started with `make up` alone, run `make remove-schema-leftovers` first, or the
check reports them as unexpected.

## Schema leftovers

`make remove-schema-leftovers` removes the tables, columns and indexes that
[`schema-leftovers.yaml`](packages/netresearch-demo-site/Configuration/InstallTool/schema-leftovers.yaml)
lists: 25 tables, 109 columns and 5 indexes that Analyze Database Structure
suggested removing on the live instance, left over from extensions and core
versions this project no longer installs
([#397](https://github.com/netresearch/typo3-demo/issues/397)). It deletes the
data in them; the repository holds everything the demo needs, so no backup is
taken. `make update` runs it on every deploy, after the cache warmup and
before the Install Tool checks.

It runs the site package's `demo:schema:remove-leftovers` and uses core's own
statements, the ones the Install Tool offers:

1. drop the listed indexes,
2. rename the listed tables and columns with the `zzz_deleted_` prefix,
3. drop those renamed copies, and no other `zzz_deleted_` object.

Before each step it asks core's schema comparison again and executes a
statement only when it is a removal suggestion of core and names an object on
the list. So nothing that is not listed is ever removed, and a listed object
that a package defines again is kept and reported as `kept`. Every executed
statement is printed, with the row count of each table. A second run finds
nothing to do and prints `Nothing to do`. `--dry-run` prints the statements
that could run now without executing them; the drop of a renamed copy appears
only once the rename has run.

The run fails (exit 1) when a statement fails, when an object it removed (or
its `zzz_deleted_` copy) is still there afterwards, or when core suggests a removal statement the command cannot
read, because that statement could name a listed object.

On the live instance, before the first run, the tables held: `index_rel` 8,855
rows, `index_words` 2,231, four more `index_*` tables 105 to 129 each,
`sys_language` 2, every other table 0.

A git revert of the change that added the command does not bring the dropped
objects back. It would restore seed statements that write to dropped columns,
and `make seed-extensions`, and with it the deploy, would then fail.

A new removal suggestion, for example from an extension that is uninstalled
later, is not removed: `make install-tool-check` reports it, and removing it
means adding it to the list.

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

## Alternative texts (ai_filemetadata)

`mfd/ai-filemetadata` generates alt texts for FAL images: a generate button next
to the alt-text field, an automatic run on upload, and `vendor/bin/typo3
ai:generate-alt-texts` for the existing stock. It ships no backend module.

It cannot use nr-vault. Like autotranslate it reads a plain key from its own
extension configuration — but unlike DeepL it speaks the OpenAI API directly, so
the existing `OPENAI_API_KEY` secret covers it and no second secret is needed.

`make update` runs `make persist-env-secret SECRET_NAME=OPENAI_API_KEY` before
`up`, which writes the value into the host `.env` (so a reboot keeps it); compose
passes it to `web`; and the entrypoint writes it, together with the four
behaviour settings, into **`config/system/settings.php`**.

That file, not `additional.php`, is the one that works — and the difference is
not cosmetic. The extension reads its behaviour settings through
`ConfigurationService` → `ConfigurationManager::getMergedLocalConfiguration()`,
which is `getDefaultConfiguration()` merged with `require settings.php`.
`additional.php` is applied on top of `$GLOBALS` instead and never reaches that
call, so four of the five keys would silently fall back to the extension's
catch-defaults — and those fail **open**: `imageResizing = 0` (no downscaling,
full-resolution images billed by the pixel) and `generateAltTextInFrontend =
true` (a synchronous OpenAI call while a visitor waits for the page). Only
`apiKey` would have arrived, because that one is read via
`ExtensionConfiguration::get()`, which does read `$GLOBALS`.

The key therefore sits in `settings.php` in plaintext, next to
`MARIADB_PASSWORD`. There is no alternative for this extension: it has no
nr-vault support, and `typo3 extension:setup` would copy the value there anyway.

Two things that cost a measurement each, so they are written down rather than
rediscovered:

- **`.env` values are interpolated, and `$$` is the escape.** compose expands
  `$NAME` in a `.env` value and collapses `$$` back to one literal `$` there,
  exactly as it does in `compose.yml`. `persist-env-secret` doubles dollars on
  the way in. **Do not verify this with `docker compose config`** — it
  re-escapes a literal `$` back to `$$` in its own output, which reads exactly
  like a failure and is not one. Measure with `printenv` inside a running
  container; against compose v5.3.1, `V=sk-a$$b` in `.env` arrives as `sk-a$b`.
- **`imageResizing` is a cost control, not a quality setting.** Images are
  billed by the pixel and a 50-word alt text does not need full resolution;
  the demo shrinks to 512.

`generateAltTextInFrontend` is off: a missing alt text must not trigger a
synchronous API call while a visitor waits for the page. `enableTokenTracking`
is on, and the three token widgets sit on the Netresearch Widgets dashboard.

The automatic run on upload happens only in a **backend request** — an upload
in the file list or a file field. Upstream's listener only skips frontend
requests, so it also ran on the CLI: nr_repurpose saves its rendered images to
FAL, each save called the vision model, nothing in the chain catches an
exception, and one failed call aborted the artifact. The composer patch
`patches/mfd-ai-filemetadata-application-type.patch` narrows the guard to the
backend, and the image build fails if the installed listener lacks it. Existing
images without an alt text still get one from the generate button or
`ai:generate-alt-texts`.

An upload generates the alt text in **English and German**. The entrypoint
writes `EXTCONF.ai_filemetadata.falLanguageMappings` into `settings.php` —
again the only file the extension reads — with `"1:/" => [0 => "en_US.UTF-8",
1 => "de_DE.UTF-8"]`: all of fileadmin (storage 1), site languages 0 and 1. The
listener writes the English text into the new metadata record and then creates
the German metadata translation (`sys_language_uid = 1`) with its own call, so
an upload is expected to cost two vision calls. Without the mapping only English
was generated. `falExcludedPrefixes` is not configured: the upload listener does
not consult it.

A failed generation never fails the upload. The same composer patch wraps the
vision call, the metadata update and the German translation in a `try`; on any
exception the upload succeeds and the TYPO3 log gets a warning "Alt text
generation on upload failed for file …" with the file uid, exception class and
message — not the file name, which may carry personal data. That file then has
no alt text (vision call failed) or no German one (translation failed); the
generate button fills it later. A second patch,
`patches/mfd-ai-filemetadata-fal-adapter-log.patch`, makes the extension log
its DataHandler errors as a warning instead of `var_dump()`ing them as HTML
into the upload's AJAX response.

The German record is written through DataHandler as the uploading user.
`bypassAccessCheckForRecords` skips only the page permission check, so a
non-admin needs modify access to `sys_file_metadata` and access to language 1
to get a German alt text; without it the upload keeps only the English text
and logs the warning. All seeded accounts that can upload are admins.

## AI Chat turns

`chat-worker` runs the turns of the AI Chat, in two replicas. A booted process waits
for a turn, runs it and ends, and the loop in the service starts the next one, so a
reader does not wait for TYPO3 to boot. A turn that finds no free worker starts a
process of its own in the web container (nr_mcp_agent ADR-029). The strategy is set
in `docker/web/entrypoint.sh`.

## Background AI runs

nr-llm stores a background run and leaves it there, and this stack has no
scheduler, so two loop services do the work, in the style of `chat-cleanup`:

- `llm-agent-worker` runs `nrllm:agent:work` and `nrllm:agent:reap` once a minute.
  Without it a queued run stays queued.
- `alt-text-batch` runs `nrllm:editor-action:batch set_file_alternative_text` over
  `1:/introduction/images/unsplash/` once a day and after every deploy. Each of the
  five images without a text becomes one run, which sends the image to the model
  and stops at its approval card. Nothing is written before an admin approves the
  card in **AI > Agent Runs**.

A repeat costs nothing: a file with an open or decided card, or with a text, is
skipped. The run history is **Background runs** in the same module.

Both act as `nr_llm_worker` (be_user 994), seeded in
`data/seed-extensions.sql`. It is not an admin and cannot log in. Its one file mount
is that folder, because the rights of `--user` decide which files a run reaches. On
the command line nr_vault refuses the provider key to a process without a logged-in
user, and `allowCliAccess` stays off here, so `worker.technicalBeUserUid = 994`
(written by the entrypoint) makes the worker read the key as this user, whose group
holds the read tier on that one secret.

`fieldFill.fields` stays empty on purpose: a save does not start a background run
here.

## The DeepL key

The key travels as the `DEEPL_API_KEY` repository secret and reaches two places.

**nr-llm, through nr-vault.** `make update` runs `make provision-deepl-key`
right after `make provision-llm-key`. It stores the value as the vault secret
`deepl_api_key` only after DeepL has accepted the key (`GET /v2/usage` answers
200, sent from the `web` container). A rejected or unreachable key is not
stored and the deploy logs a warning, because the Cowriter does not fall back
to the language model when DeepL errors: a dead key would break every Cowriter
translation. The secret is stored the same way the OpenAI key is: on stdin, never echoed,
written as the provisioning user 991, which owns a secret it created. It fails
the deploy if `vault:store` fails or the secret is missing afterwards. The
entrypoint sets `EXTENSIONS.nr_llm.translators.deepl.apiKeyIdentifier` to that
name. nr-llm's DeepL translator counts as available only when the identifier
names an existing secret; otherwise the Cowriter translates with the language
model. An empty variable skips the step and keeps a stored secret.

**autotranslate's extension configuration.** `thieleundklose/autotranslate`
reads its key from the extension configuration or from the site configuration
and has no nr-vault support at all, and the site configuration is public in this
repository. `make update` runs
`make persist-env-secret SECRET_NAME=DEEPL_API_KEY`, which writes the key into
the host `.env` (so a reboot keeps it), compose passes it into the `web`
container, and the entrypoint writes it into `config/system/additional.php` as
a managed block. An empty variable keeps
whatever key that file already holds; it never wipes it. autotranslate does not
translate with this copy, though: its translations are routed through nr-llm by
`Netresearch\DemoSite\Translation\NrLlmDeeplTranslator`, which calls
`TranslationService::translate()`, and that method always uses the language
model, never the DeepL translator.

Language mapping lives in `config/sites/default/config.yaml` and is not secret:
`deeplSourceLang: EN` on the English language, `deeplTargetLang: DE` on the
German one, plus the per-table `autotranslate*` keys. Without `deeplTargetLang`
the extension skips its whole DeepL block, and the localization then creates the
German record as a plain copy of the English source.

Two upstream defects make that failure mode hard to see, and both are why this
instance runs `autotranslate.debug = 1`:

- [#156](https://github.com/thieleundklose/tk-typo3-autotranslate/issues/156) —
  batch translation reports `done` when nothing was translated.
- [#157](https://github.com/thieleundklose/tk-typo3-autotranslate/issues/157) —
  `LogUtility` drops error messages unless `debug` is on.

A green `done` badge is therefore not evidence. Check the frontend, or the
module's translation-cache counter.

A translation made with the Cowriter in the rich text editor goes to nr-llm's
DeepL translator whenever the vault secret above exists, and a language model
then revises the DeepL text, so each one costs two requests. The entrypoint
switches the revision on by writing the cowriter setting
`translation.polish = "1"` into `config/system/settings.php`, next to the
ai_filemetadata settings. When the revision fails or changes markup,
placeholders or glossary terms, the DeepL text is inserted unchanged. Without
the secret the Cowriter translates with the language model in one request and
nothing is revised. The JSON answer of the translate route shows which path ran:
only the DeepL path carries `translator` and `polished`.

The Cowriter's **Generate image** button (3.17+) is switched on the same way:
the entrypoint writes `image.enable = "1"` next to `translation.polish`. The
image is generated with nr-llm's OpenAI key, stored in the editor's default
upload folder and inserted through rte_ckeditor_image, which the demo RTE
preset imports. `image.model` is not set, so the Cowriter uses the active image
model of nr-llm's model registry, or `gpt-image-2` when there is none. Because
the file is added through FAL in a backend request, ai_filemetadata's
alt-text-on-upload also runs for it: one vision call per mapped language, so
two with the English and German mapping described above, on top of the image
request itself. From 3.18 the same switch also adds a **Generate image** control
to file fields that accept PNG (for example the images of a Text & Media
element); the generated file is added to the field as a new file reference.

The Cowriter's inline suggestions (3.19+) are switched on the same way: the
entrypoint writes `inlineSuggestions.enable = "1"`, and the demo RTE preset
lists the per-editor toggle `cowriterInlineSuggestions`. After a pause in typing
at the end of a paragraph or heading, a short continuation appears as grey text;
Tab inserts it. Each suggestion is a request against the editor's nr-llm budget,
also when it is not taken: at most one every 5 s per field and 12 per minute per
backend user.

The Cowriter's **Present as tabs or accordion** button (3.20+) is switched on
the same way: the entrypoint writes `presentation.enable = "1"`. It appears next
to the rich text of Text, Text & Images and Text & Media elements, because the
demo installs bootstrap_package. A text with h2 or h3 headings is split at them
without a request; a text without headings costs one request against the
editor's nr-llm budget. The new Tabs or Accordion element is created hidden
after the original, and a switch in the dialog shows it and hides the original.
There is no switch for an element with translations or for a connected
translation; the dialog says what to do instead.

From 3.21 the field suggestion button appears on all descriptive page fields
and on the header and subheader of content elements, and the record's document
header offers "Suggest values for all fields with AI". From 3.22 every
Cowriter dialog ends with "About this suggestion": the nr-llm configuration and
model, which context sources were sent, and the current settings. 3.22 also
sends more page context with field suggestions: the descriptive page fields the
editor may read, the parent page title and up to five neighbouring page titles,
capped at 16,000 characters. No entrypoint change is needed for either.

From nr-mcp-agent 0.26 the chat lists order conversations by their last message.
`extension:setup` adds the new columns, and the entrypoint runs the upgrade
wizard `nrMcpAgent_lastMessageTime`, which fills the time for older
conversations. The dashboard widget "Recent chats" is full width from 0.26.2;
the entrypoint runs the wizard `nrMcpAgent_recentChatsWidgetSize`, which widens
a stored narrow position on dashboards arranged before.

From nr-mcp-agent 0.27 the "KI-Assistent" widgets follow the designer's mockup,
and page actions open the page module with the chat beside it. The seed adds
"Seite bearbeiten" and "Inhalte erstellen" to existing "KI-Assistent"
dashboards and removes "Häufige Aufgaben" from them once, recorded per
dashboard in `sys_registry`; later edits by the user are kept. The new cache `nrmcpagent_dashboard` gets its tables from
`extension:setup`, which the entrypoint runs on every start.

## Backend languages

The backend is available in German as well as English. The entrypoint adds the
languages in `BACKEND_LANGUAGES` (`docker/web/entrypoint.sh`) to
`LANG/availableLocales` and downloads their language packs with
`language:update`, on the first boot and again whenever the installed packages
change. Each backend user picks the language under *User Settings › Language*.

Do not install a language through *Maintenance › Manage Language Packs*: it
writes into the `typo3-config` and `typo3-var` volumes, and `Deploy (Fresh
Install)` removes both. Add the language to `BACKEND_LANGUAGES` instead.

A boot that has to download or refresh a pack needs outbound HTTPS to
`localize.typo3.org`; a boot whose packs are current contacts nothing. Without
network the boot logs a warning, keeps the labels already present and tries
again on the next start. The labels an extension ships itself do not depend on
it.

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
data/                           # db.sql.gz (DB seed), seed-extensions.sql, fileadmin
packages/netresearch-demo-site  # site package: TypoScript, RTE preset, dashboard widgets/presets
config/                         # TYPO3 site + system config
deploy/                         # host provisioning
.github/workflows/              # build, deploy, and the ops workflows above
```
