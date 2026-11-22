# AGENTS.md

`README.md` is the manual for this repository. Read the section that owns a task before you start it, and follow it as written.

- **Extension or dependency update:** README § "Data lifecycle", from "To change installed extension versions". An extension update on the demo is always a full update: all netresearch extensions to their newest releases, `composer update` without a package name, the base images in `docker/web/Dockerfile`, and the superseded dependency-bot pull requests closed. A brief or ticket that names one package does not narrow this.
- **Deploying:** README § "How deployment works". A merge to `main` builds the image, and Deploy (Update) rolls it out.
- **Changing content on the live instance:** README § "Content changes on the live instance".
- **Running an operation on the server:** README § "Operations workflows (manual, `workflow_dispatch`)".
