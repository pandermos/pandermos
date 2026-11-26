Task: daily security review. Report-first: change only what is listed as safe below.

1. **Logins**: successful SSH logins in the last 24 hours (`journalctl -u ssh --since -24h` or `/var/log/auth.log`), source IPs and users. Any login from an IP not seen in previous reports or notes.md → WARNING.
2. **Brute force**: failed login volume, fail2ban (or equivalent) status and currently banned IP count. If fail2ban is installed but stopped, start it.
3. **Users and keys**: new users in `/etc/passwd`, new sudoers entries, changes in `~/.ssh/authorized_keys` of all users since the last report (store hashes in the state directory to compare).
4. **Listening ports**: `ss -tulpn`. Compare with the list in the state directory; a new public listener → WARNING with the owning process.
5. **Web roots**: files that should never be public: `.env`, `.git/`, `*.sql`, `*.bak`, `*.zip` of the site, `phpinfo.php`. Check the files exist AND whether they are actually served (request them with curl). A served secret is CRITICAL; block it in the web server config (test the config first) and move the file into the backup directory.
6. **Recently changed executable code**: PHP/JS files changed in the last 24 hours inside web roots outside of normal deploy paths (uploads directories especially). PHP inside an uploads folder is CRITICAL.
7. **TLS and headers**: HSTS and basic security headers on each main site (report only).
8. **Updates**: number of pending security updates; packages with known critical CVEs if the distro tools show them (report only).

Never rotate keys, change passwords, edit firewall rules that could lock out SSH, or contact third parties. Recommend those in the report.
