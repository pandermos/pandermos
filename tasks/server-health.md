Task: server health.

Check, in this order, and keep the commands short:

1. **Disk**: `df -h` and `df -i`. Over 85% → WARNING, over 95% → CRITICAL. If a disk is filling, find the biggest growers (`du -xh --max-depth=2` on the culprit) and the usual suspects: old logs, journal (`journalctl --disk-usage`), docker images and build cache, package caches, core dumps. Safe cleanups: `journalctl --vacuum-time=14d`, `apt-get clean`, `docker image prune -f` (dangling only). Never delete application data or backups.
2. **Memory and load**: `free -m`, load average vs CPU count, top 5 processes by memory and CPU. Look for OOM kills: `journalctl -k --since "-2h" | grep -i oom`.
3. **Services**: `systemctl --failed`. For each failed unit, read its last 30 log lines; restart it once if the cause is transient and write down what happened.
4. **Process managers**: pm2 (`pm2 jlist`), docker (`docker ps -a --format '{{.Names}} {{.Status}}'`). Flag containers or processes that are restarting repeatedly or exited unexpectedly.
5. **Databases**: the database servers are up and accept connections; connection count vs limit; long-running queries (over 5 minutes).
6. **Backups**: the newest backup file/snapshot is less than 26 hours old (locations in the Environment section of CLAUDE.md).
7. **Time and updates**: clock is synchronized (`timedatectl`); pending security updates count (report only, do not upgrade).

Report numbers, not adjectives: "disk / 91% (+4% since last report)".
