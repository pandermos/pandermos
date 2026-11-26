# Example report

What a `website-health` report looks like. Hostnames are placeholders.

```markdown
# website-health · 2026-11-26 08:23

Checked 9 sites from /etc/nginx/sites-enabled (2 redirect-only vhosts skipped).

## Fixed
- **shop.example.com** returned 502 since ~08:12. `php8.3-fpm` had been killed by the
  OOM killer (journal 08:11:57). `pm.max_children = 40` × ~110 MB per worker does not
  fit in 4 GB. Restarted php8.3-fpm; home page 200 in 180 ms. Lowered max_children
  to 24 and reloaded after `php-fpm8.3 -t`.
  Backup: backups/20261126-0823/etc/php/8.3/fpm/pool.d/www.conf

## Found but not fixed
- **blog.example.com** TLS certificate expires in 9 days. certbot timer is active but
  the last renewal failed: the HTTP-01 challenge path is caught by a rewrite rule in
  `/etc/nginx/sites-enabled/blog`. Not changing the rewrite without review. Suggested fix:
  add `location ^~ /.well-known/acme-challenge/ { root /var/www/letsencrypt; }` above it.

## Ongoing
- api.example.com p95 TTFB 1.9 s (1.7 s in the previous report), slow query on
  /v1/search, see database report.

STATUS: FIXED
NOTIFY: shop.example.com was down 08:12-08:24 (php-fpm OOM). Restarted, max_children 40→24, backup saved. blog.example.com certificate expires in 9 days: renewal blocked by a rewrite rule, fix suggested in report.
```
