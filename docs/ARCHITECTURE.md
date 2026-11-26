# Architecture

Pandermos is a scheduler and a report contract wrapped around `claude -p`. Everything interesting happens inside Claude Code; the runner's job is to start it at the right time with the right context, keep runs from overlapping, and turn the result into a notification you can act on.

## Files on disk

```text
/usr/local/bin/pandermos          the runner (single Bash file)
/etc/systemd/system/pandermos.service

/etc/pandermos/                   root:pandermos 750
├── pandermos.conf                settings (all optional, defaults in the script)
├── schedule                      which task, which model, timeout, when
└── secrets.env                   Claude token, Telegram, webhook (640)

/var/lib/pandermos/               the agent's working directory and $HOME
├── CLAUDE.md                     standing rules + description of your environment
├── notes.md                      accepted situations, lessons learned (agent writes)
├── tasks/<task>.md               one prompt per task
├── reports/<task>-YYYYmmdd-HHMM.md
├── backups/YYYYmmdd-HHMM/        whatever the agent saved before changing things
└── state/
    ├── usage.tsv                 one line per run
    ├── last-<task>.json/.err     raw output of the last run
    ├── .lock-<task>              flock, prevents overlapping runs
    ├── .limit                    epoch of the last usage-limit hit
    ├── .fail-<task>              consecutive runs without a report
    ├── .notified-<task>          hash of the last message sent
    ├── .at-<task>-HHMM           date an "at" slot last ran
    ├── .digest                   date of the last daily digest
    └── <anything the tasks keep> e.g. last-post-id
```

## The loop

```text
forever:
  load secrets (so a new token works without a restart)
  no credentials?          sleep 5 min
  usage limit < 1h ago?    sleep 15 min
  for each task due this turn:
      pandermos run task --model M --timeout T
      stop early if a limit was just hit
      sleep TASK_GAP
  send the daily digest if it is time
  turn += 1
  sleep LOOP_SLEEP
```

A turn takes `LOOP_SLEEP` plus the time the due tasks took. With the defaults (25 minute sleep, a 10–20 minute news task every turn) a turn is roughly 40 minutes, so `every 4` means about every 2.5 hours. `at` entries are wall-clock: the first turn after 04:00 runs them, once per day.

## One run

1. Validate the task name (letters, digits, `.`, `_`, `-` only) and take `flock` on `state/.lock-<task>`. If another run of the same task holds it, exit 3.
2. Build the prompt: the task file, then a context block:

   ```text
   ---
   Current time: 2026-11-26 09:05 +03
   Write your report to: /var/lib/pandermos/reports/news-20261126-0905.md
   Previous report: /var/lib/pandermos/reports/news-20261126-0823.md
   State directory for this task: /var/lib/pandermos/state
   Backups go under: /var/lib/pandermos/backups/20261126-0905/
   Operator note: (only with --note)
   ```

3. `cd` into the working directory (so `CLAUDE.md` is picked up as project memory) and run

   ```bash
   timeout --kill-after=60 $TIMEOUT claude -p "$PROMPT" --model $MODEL \
     --max-turns $MAX_TURNS --allowedTools "$ALLOWED_TOOLS" --output-format json
   ```

4. Append a usage row from the JSON result: time, task, model, turns, minutes, API-equivalent cost, input tokens (including cache), output tokens, error flag.
5. Look for usage-limit messages in the output; if found, write `state/.limit` so the loop backs off.
6. No report file? Count it. On the `FAIL_ALERT_AFTER`-th consecutive miss, notify with the tail of the output.
7. Parse the last `STATUS:` and `NOTIFY:` lines (`DURUM:` / `TELEGRAM:` also accepted, as are bold variants). Notify unless the status is CLEAN, the message is `-`, or the same message was the last one sent for this task.
8. Delete reports older than `REPORT_RETENTION_DAYS` and backup folders older than `BACKUP_RETENTION_DAYS`.

## The report contract

The only thing the runner understands about the agent's work is the last two lines of the report:

```text
STATUS: CLEAN | FIXED | WARNING | CRITICAL
NOTIFY: <one message or ->
```

Everything else in the report is for humans (and for the next run, which reads it). Keeping the contract this small is deliberate: any task, in any language, can follow it, and a broken report degrades to "UNKNOWN" instead of crashing the loop.

## Why not ...

- **cron instead of a loop?** You can: `pandermos run <task>` works from cron. The loop adds the usage-limit back-off, the digest, and natural spacing (a slow run delays the next turn instead of piling up).
- **the Agent SDK?** It would need a runtime and a build step. `claude -p` is already installed, authenticated and updated by the same tool your developers use, and its JSON output has everything the runner needs.
- **a web dashboard?** Reports are Markdown files and the status is one command away. A dashboard is a good contribution as a separate project that reads `reports/` and `state/usage.tsv`.
