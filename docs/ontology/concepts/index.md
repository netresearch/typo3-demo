# Concepts

* [TYPO3 demo instance](demo-instance.md) - The live TYPO3 14 showcase of the Netresearch extensions at typo3-demo.netresearch.de.
* [Application container](app-container.md) - The web, worker and scheduler services, all started from the one image of this repository.
* [Container image](container-image.md) - The image ghcr.io/netresearch/typo3-demo: PHP-FPM with nginx, the Composer dependencies and the site package.
* [Composer manifest](composer-manifest.md) - composer.json and composer.lock: which extensions the instance installs, in which versions.
* [Database](database.md) - MariaDB from the Docker Hardened Image, created and seeded by the one-shot db-init service.
* [Seed data](seed-data.md) - The database dump data/db.sql.gz with the demo content, landing-page templates, dashboards and nr-llm records.
* [Cache](cache.md) - Valkey, the key-value store behind the TYPO3 caches.
* [Proxy](proxy.md) - Caddy, the HTTPS front of the instance.
* [Deployment](deployment.md) - The GitOps path: a merge to main builds the image, and the workflow Deploy (Update) rolls it out on the host.
* [Demo account](demo-account.md) - The backend accounts of the demo, among them the admin nr_admin and the AI editor redakteur_ki with a small AI budget.

# Installed extensions

* [Installed extensions](extensions/index.md) - The AI extensions this instance installs, one file each
