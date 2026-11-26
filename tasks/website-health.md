Task: health of every website on this server.

Discover the sites yourself from the web server configuration (`/etc/nginx/sites-enabled`, `/etc/apache2/sites-enabled`, Caddyfile). Skip redirect-only vhosts. List the sites you checked in the report.

For each site:
1. **Reachability**: home page HTTP status, time to first byte, final URL after redirects (http→https and www/non-www should land on a single canonical host).
2. **TLS**: certificate expiry date. Less than 14 days → WARNING; less than 3 days or expired → CRITICAL. If certbot is used, check that its timer is active and try `certbot renew --dry-run` only if renewal is failing.
3. **Content sanity**: the page is not a default server page, a PHP error, a maintenance page or an empty body. The `<title>` exists.
4. **SEO basics** (report only, never "fix" by inserting generic text): robots.txt is reachable and does not block the whole site by accident; sitemap is reachable; no `noindex` on the home page unless it is intended (check notes.md).
5. **Errors**: count 5xx responses and PHP/app fatal errors in the last 2 hours of the access and error logs. Show the three most frequent error lines.
6. **Upstreams**: if the site proxies to an app (pm2, docker, systemd service), make sure the process is up and not restart-looping.

Fix when it is safe and reversible: restart a crashed service, reload a web server after a config test passes (`nginx -t`), clear a full cache directory. Anything else goes into the report.

Compare with the previous report and only notify about new or worsening problems.
