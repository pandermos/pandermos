# Contributing

Thanks for helping. Three kinds of contributions are especially welcome.

## 1. Task files

The runner is small on purpose; the value is in good tasks. A task for your stack (Laravel, Django, Rails, Ghost, Magento, Postfix, Nextcloud, Kubernetes nodes, Proxmox...) helps everyone running the same thing.

- Put it in `tasks/<name>.md`, in English.
- Follow [docs/WRITING-TASKS.md](docs/WRITING-TASKS.md): purpose, locations, what wrong looks like, order of checks, what may be fixed and how, what is report-only.
- Replace your hostnames, paths and names with placeholders (`example.com`, `/var/www/app`).
- In the PR, say where you ran it and for how long, and paste an anonymized report.

## 2. Runner fixes

- `bin/pandermos` is one Bash file. Keep it that way: no new runtime dependencies beyond bash, coreutils, jq, curl, flock.
- Every behaviour change needs a case in `tests/run.sh` (it uses `tests/fixtures/fake-claude`, no network or credentials).
- Run `shellcheck -x bin/pandermos install.sh uninstall.sh tests/run.sh` and `bash tests/run.sh` before opening the PR. CI runs both.

## 3. Stories

Ran Pandermos somewhere interesting? Open an issue with what it caught, what it got wrong, and what rule you added because of it. The "Lessons from running it in production" section grows from these.

## Ground rules

- No telemetry, no phoning home, no network calls except Claude, the configured notifications and what the user's tasks ask for.
- Safety defaults only get stricter, never looser, without a discussion in an issue first.
