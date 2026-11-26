# Changelog

## 0.1.0 (2026-11-26)

First public release, extracted from the auditor that has been running pandermos.com and its server.

- `pandermos` runner: `loop`, `run`, `status`, `usage`, `report`, `notify`, `doctor`
- Text schedule with `every N`, `at HH:MM[,HH:MM]` and `manual`
- Report contract (`STATUS:` / `NOTIFY:`, Turkish `DURUM:` / `TELEGRAM:` also accepted)
- Telegram and JSON webhook notifications, de-duplication, daily digest
- Usage ledger with API-equivalent cost, usage-limit back-off, per-task locks
- Failure alert after N runs without a report
- Report and backup retention
- Standing rules template, seven example tasks
- `install.sh` with audit, sudo whitelist and full-sudo modes; `uninstall.sh`
- Test suite with a fake Claude CLI, ShellCheck in CI
