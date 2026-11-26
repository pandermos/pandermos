#!/usr/bin/env bash
# Removes the Pandermos service and binary. Keeps config, reports and backups unless --purge is given.
set -euo pipefail
USER_NAME="${PANDERMOS_USER:-pandermos}"
[ "$(id -u)" -eq 0 ] || { echo "run as root" >&2; exit 1; }
systemctl disable --now pandermos 2>/dev/null || true
rm -f /etc/systemd/system/pandermos.service /usr/local/bin/pandermos "/etc/sudoers.d/$USER_NAME"
systemctl daemon-reload 2>/dev/null || true
if [ "${1:-}" = "--purge" ]; then
  rm -rf /etc/pandermos /var/lib/pandermos
  userdel "$USER_NAME" 2>/dev/null || true
  echo "pandermos removed, including config, reports and backups"
else
  echo "pandermos removed. Kept /etc/pandermos and /var/lib/pandermos (use --purge to delete them)"
fi
