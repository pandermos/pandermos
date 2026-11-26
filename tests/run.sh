#!/usr/bin/env bash
# End-to-end tests with a fake Claude CLI. No network, no credentials needed.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "  ok   $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL $1"; }
expect() { if eval "$2"; then ok "$1"; else bad "$1"; fi; }

setup() {
  T=$(mktemp -d)
  export PANDERMOS_CONF="$T/etc" PANDERMOS_HOME="$T/home"
  mkdir -p "$PANDERMOS_CONF" "$PANDERMOS_HOME/tasks"
  cat > "$PANDERMOS_CONF/pandermos.conf" <<CONF
PANDERMOS_HOME=$PANDERMOS_HOME
CLAUDE_BIN=$ROOT/tests/fixtures/fake-claude
LOOP_SLEEP=0
TASK_GAP=0
DIGEST_AT=00:00
CONF
  printf 'CLAUDE_CODE_OAUTH_TOKEN=test\n' > "$PANDERMOS_CONF/secrets.env"
  printf 'alpha sonnet 1m every 1\nbeta sonnet 1m every 2\nnightly opus 1m at 00:00\nadhoc sonnet 1m manual\n' > "$PANDERMOS_CONF/schedule"
  for t in alpha beta nightly adhoc; do echo "Task $t" > "$PANDERMOS_HOME/tasks/$t.md"; done
  cp "$ROOT/templates/CLAUDE.md" "$PANDERMOS_HOME/"
  export NOTIFY_DRY_RUN=1
}
P="$ROOT/bin/pandermos"

echo "run: fixed report"
setup
FAKE_MODE=fixed $P run alpha >/dev/null
expect "report written" "ls $PANDERMOS_HOME/reports/alpha-*.md >/dev/null 2>&1"
expect "usage row recorded" "[ \$(wc -l < $PANDERMOS_HOME/state/usage.tsv) -eq 1 ]"
expect "cost parsed" "cut -f6 $PANDERMOS_HOME/state/usage.tsv | grep -q 0.42"
expect "notification sent" "grep -q 'alpha · FIXED' $PANDERMOS_HOME/state/notify.log"

echo "run: same message is not sent twice"
rm -f "$PANDERMOS_HOME"/reports/*.md
FAKE_MODE=fixed $P run alpha >/dev/null
expect "deduplicated" "[ \$(grep -c 'alpha · FIXED' $PANDERMOS_HOME/state/notify.log) -eq 1 ]"

echo "run: clean report is silent"
setup
FAKE_MODE=clean $P run alpha >/dev/null
expect "no notification" "[ ! -s $PANDERMOS_HOME/state/notify.log ]"

echo "run: Turkish status lines"
setup
FAKE_MODE=turkish $P run alpha >/dev/null
expect "DURUM/TELEGRAM parsed" "grep -q 'alpha · WARNING\] disk' $PANDERMOS_HOME/state/notify.log"

echo "run: missing report"
setup
FAKE_MODE=noreport $P run alpha >/dev/null 2>&1; r1=$?
FAKE_MODE=noreport $P run alpha >/dev/null 2>&1
expect "non-zero exit" "[ $r1 -ne 0 ]"
expect "alert after 2 failures" "grep -q 'no report 2 times' $PANDERMOS_HOME/state/notify.log"

echo "run: usage limit"
setup
FAKE_MODE=limit $P run alpha >/dev/null 2>&1
expect "limit marker set" "[ -f $PANDERMOS_HOME/state/.limit ]"

echo "run: input validation"
setup
expect "unknown task rejected" "! $P run nope >/dev/null 2>&1"
expect "path traversal rejected" "! $P run ../etc >/dev/null 2>&1"

echo "loop: one turn"
setup
FAKE_MODE=clean PANDERMOS_ONE_TURN=1 timeout 600 "$P" loop >/dev/null 2>&1
expect "every-1 task ran" "ls $PANDERMOS_HOME/reports/alpha-*.md >/dev/null 2>&1"
expect "every-2 task ran on turn 0" "ls $PANDERMOS_HOME/reports/beta-*.md >/dev/null 2>&1"
expect "at task ran" "ls $PANDERMOS_HOME/reports/nightly-*.md >/dev/null 2>&1"
expect "manual task skipped" "! ls $PANDERMOS_HOME/reports/adhoc-*.md >/dev/null 2>&1"
expect "at task marked for today" "[ -f $PANDERMOS_HOME/state/.at-nightly-0000 ]"
expect "digest sent" "grep -q 'daily digest' $PANDERMOS_HOME/state/notify.log"

echo "status / usage / doctor"
expect "status lists tasks" "$P status | grep -q '^alpha .*CLEAN'"
expect "usage totals" "$P usage 1 | grep -q '^total'"
expect "doctor passes" "$P doctor >/dev/null 2>&1"

echo
echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
