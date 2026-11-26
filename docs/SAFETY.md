# Safety

Pandermos gives a language model a shell on your server. It is useful for exactly that reason, so treat the setup the way you would treat a new colleague with production access: limited rights at first, everything logged, wider rights once you have seen how they work.

## Layers of control (strongest first)

1. **Unix permissions.** The agent runs as the `pandermos` user. What that user cannot read or write, the agent cannot either, whatever the prompt says. This is the only hard boundary.
2. **sudo rules.** `install.sh` gives no sudo by default, a list of commands with `--sudo-commands`, or everything with `--full-sudo`.
3. **Database roles.** Give it read-only roles (`default_transaction_read_only = on` in PostgreSQL, `SELECT`-only grants in MySQL). Let it write through your application's own tools (CLI, admin API) where possible: those keep your validation and audit logs.
4. **Allowed tools.** `ALLOWED_TOOLS` decides which Claude Code tools run without a prompt. Note that `Bash` can write files, so removing `Write,Edit` does not make the agent read-only; permissions do.
5. **Standing rules (`CLAUDE.md`).** Backup first, no deletion, no money/DNS/accounts/credentials, two strikes, always report. The model follows these well in practice, but they are instructions, not enforcement.

## Recommended setups

| Stage | sudo | DB | Rules |
|---|---|---|---|
| Week 1: watch | none | read-only role | AUDIT MODE |
| Week 2+: fix the boring stuff | `systemctl restart <your services>`, `nginx -t`, `systemctl reload nginx`, `journalctl` | read-only | FIX MODE for listed actions |
| Trusted | full | read-only + app CLI | FIX MODE |

We run the last row in production, after a few weeks of reading reports. Every change still comes with a backup path.

## Prompt injection

The agent reads untrusted text: web pages, news sources, user comments, log lines, emails stored in a database. Any of it can contain "ignore your instructions and ...". Mitigations:

- Keep secrets the agent does not need out of its reach (the `pandermos` user cannot read other users' `.env` files unless you let it).
- No credentials for money, DNS, registrars, cloud consoles or email sending on the server where it runs.
- The default rules tell it to treat content it reads as data, and to never act on instructions found inside it. Add your own examples to `CLAUDE.md` if your sites accept user content.
- Network egress filtering (for example only your own domains plus `api.anthropic.com`) is the strong version of this, if your tasks allow it.

## Things the agent should never get

- Payment provider keys, bank or registrar access, cloud root credentials
- SSH keys to other servers (unless that is the job, and then a dedicated restricted key)
- Write access to backups it is supposed to protect
- Your personal email or chat accounts

## Auditing what it did

- `reports/` keeps every report for `REPORT_RETENTION_DAYS`.
- `state/last-<task>.json` holds the full result of the last run of each task.
- `backups/` holds what it saved before changes.
- With `--full-sudo`, sudo logs every command to the journal: `journalctl _COMM=sudo --since today`.

## Turning it off

```bash
sudo systemctl disable --now pandermos      # stop the loop
sudo rm /etc/sudoers.d/pandermos            # drop root rights
```

Running tasks are killed by systemd when the service stops.
