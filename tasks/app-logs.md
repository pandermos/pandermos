Task: triage application logs (pm2, docker, systemd services).

1. List the applications: `pm2 jlist`, `docker ps --format '{{.Names}}'`, and the app units named in CLAUDE.md.
2. For each, read the error output of the last 2 hours only. pm2 log lines often have no timestamps: use the file modification time and the previous report to tell new lines from old ones, and never raise an alarm from a line you cannot date.
3. Group errors by signature (same message with ids and numbers stripped). For each group: count, first/last seen, one example, and the code location from the stack trace.
4. Classify: new since previous report, ongoing, resolved.
5. Fix only what is operational and reversible: a crashed process (restart once), a full disk or log file (rotate), an expired cache. Code bugs go into the report and, if the `improve` task is used, as one line into its backlog in the state directory.
6. Restart loops (restart count rising between reports) are always WARNING or worse.
