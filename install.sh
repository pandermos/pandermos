#!/usr/bin/env bash
# Installs Pandermos on a systemd Linux server. Safe to re-run: never overwrites your config, rules or tasks.
#
#   sudo ./install.sh                      read-mostly agent, no sudo
#   sudo ./install.sh --sudo-commands "/usr/bin/systemctl restart nginx,/usr/bin/systemctl restart php8.3-fpm"
#   sudo ./install.sh --full-sudo          agent may run anything as root (fix mode, read docs/SAFETY.md first)
#   sudo ./install.sh --user auditor --no-start
set -euo pipefail

USER_NAME=pandermos
HOME_DIR=/var/lib/pandermos
CONF_DIR=/etc/pandermos
SUDO_MODE=none
SUDO_CMDS=""
START=1

while [ $# -gt 0 ]; do
  case "$1" in
    --user) USER_NAME="$2"; shift 2 ;;
    --home) HOME_DIR="$2"; shift 2 ;;
    --full-sudo) SUDO_MODE=full; shift ;;
    --sudo-commands) SUDO_MODE=list; SUDO_CMDS="$2"; shift 2 ;;
    --no-start) START=0; shift ;;
    -h|--help) sed -n '2,8p' "$0"; exit 0 ;;
    *) echo "unknown option $1" >&2; exit 2 ;;
  esac
done

[ "$(id -u)" -eq 0 ] || { echo "run as root (sudo ./install.sh)" >&2; exit 1; }
SRC="$(cd "$(dirname "$0")" && pwd)"

say() { printf '\033[1;32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*"; }

for bin in jq curl flock timeout; do
  command -v "$bin" >/dev/null || { warn "missing $bin, installing"; apt-get install -y "$bin" >/dev/null 2>&1 || warn "install $bin manually"; }
done
if ! command -v claude >/dev/null; then
  if command -v npm >/dev/null; then
    say "installing Claude Code CLI"
    npm install -g @anthropic-ai/claude-code >/dev/null
  else
    warn "Claude Code CLI not found and npm is missing. Install Node.js 18+ then: npm install -g @anthropic-ai/claude-code"
  fi
fi

if ! id "$USER_NAME" >/dev/null 2>&1; then
  say "creating system user $USER_NAME"
  useradd --system --home-dir "$HOME_DIR" --create-home --shell /bin/bash "$USER_NAME"
  usermod -aG adm "$USER_NAME" 2>/dev/null || true
fi

say "installing /usr/local/bin/pandermos"
install -m 755 "$SRC/bin/pandermos" /usr/local/bin/pandermos

install -d -m 750 -o root -g "$USER_NAME" "$CONF_DIR"
copy_once() { [ -e "$2" ] || { install -m "$3" -o "${4:-root}" -g "$USER_NAME" "$1" "$2"; say "created $2"; }; }
copy_once "$SRC/etc/pandermos.conf.example" "$CONF_DIR/pandermos.conf" 640
copy_once "$SRC/etc/schedule.example" "$CONF_DIR/schedule" 640
copy_once "$SRC/etc/secrets.env.example" "$CONF_DIR/secrets.env" 640
if [ "$HOME_DIR" != /var/lib/pandermos ] && ! grep -q '^PANDERMOS_HOME=' "$CONF_DIR/pandermos.conf"; then
  echo "PANDERMOS_HOME=$HOME_DIR" >> "$CONF_DIR/pandermos.conf"
fi

install -d -m 750 -o "$USER_NAME" -g "$USER_NAME" "$HOME_DIR" "$HOME_DIR"/{tasks,reports,state,backups}
copy_once "$SRC/templates/CLAUDE.md" "$HOME_DIR/CLAUDE.md" 640 "$USER_NAME"
copy_once "$SRC/templates/notes.md" "$HOME_DIR/notes.md" 640 "$USER_NAME"
for t in "$SRC"/tasks/*.md; do copy_once "$t" "$HOME_DIR/tasks/$(basename "$t")" 640 "$USER_NAME"; done

case "$SUDO_MODE" in
  full)
    warn "granting $USER_NAME passwordless sudo for ALL commands (fix mode)"
    echo "$USER_NAME ALL=(ALL) NOPASSWD: ALL" > "/etc/sudoers.d/$USER_NAME" ;;
  list)
    say "granting $USER_NAME sudo for: $SUDO_CMDS"
    echo "$USER_NAME ALL=(ALL) NOPASSWD: $SUDO_CMDS" > "/etc/sudoers.d/$USER_NAME" ;;
esac
if [ -f "/etc/sudoers.d/$USER_NAME" ]; then
  chmod 440 "/etc/sudoers.d/$USER_NAME"
  visudo -cf "/etc/sudoers.d/$USER_NAME" >/dev/null || { warn "sudoers file invalid, removing"; rm -f "/etc/sudoers.d/$USER_NAME"; }
fi

sed -e "s#^User=.*#User=$USER_NAME#" -e "s#^Group=.*#Group=$USER_NAME#" \
    -e "s#/var/lib/pandermos#$HOME_DIR#g" "$SRC/systemd/pandermos.service" > /etc/systemd/system/pandermos.service
systemctl daemon-reload 2>/dev/null || warn "systemd not running here; reload it yourself later"

echo
say "installed. Next steps:"
cat <<EOF
  1. Put your Claude token in $CONF_DIR/secrets.env
       claude setup-token          (Pro/Max plan, run on any machine with a browser)
  2. Optional: Telegram bot token + chat id (or WEBHOOK_URL) in the same file
  3. Edit the rules:      $HOME_DIR/CLAUDE.md
     Edit / add tasks:    $HOME_DIR/tasks/*.md
     Edit the schedule:   $CONF_DIR/schedule
  4. Check everything:    sudo -u $USER_NAME pandermos doctor
     Try one task:        sudo -u $USER_NAME pandermos run server-health
  5. Start the loop:      systemctl enable --now pandermos
EOF
if [ "$START" -eq 1 ] && grep -qE '^(CLAUDE_CODE_OAUTH_TOKEN|ANTHROPIC_API_KEY)=.+' "$CONF_DIR/secrets.env"; then
  systemctl enable --now pandermos && say "pandermos.service started"
fi
