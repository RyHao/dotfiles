#!/usr/bin/env bash
# atamux smoke tests — fully isolated:
#   - a `tmux` shim routes every tmux call to a private socket (-L atamux-test)
#   - a stub `ata` avoids launching real Claude
#   - install/uninstall run against temp TMUX_CONF + CLAUDE_SETTINGS
# Nothing here touches your real tmux server, ~/.tmux.conf, or ~/.claude.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d)"
SOCK="atamux-test-$$"
REAL_TMUX="$(command -v tmux)"
PASS=0 FAIL=0

cleanup() { "$REAL_TMUX" -L "$SOCK" kill-server 2>/dev/null; rm -rf "$WORK"; }
trap cleanup EXIT

ok()   { PASS=$((PASS+1)); printf '  \033[32mok\033[0m   %s\n' "$1"; }
no()   { FAIL=$((FAIL+1)); printf '  \033[31mFAIL\033[0m %s\n' "$1"; }
check(){ if [ "$2" = "$3" ]; then ok "$1"; else no "$1 (want [$3] got [$2])"; fi; }

# --- isolated PATH: tmux shim + stub ata --------------------------------------
mkdir -p "$WORK/bin"
cat > "$WORK/bin/tmux" <<EOF
#!/usr/bin/env bash
exec "$REAL_TMUX" -L "$SOCK" "\$@"
EOF
cat > "$WORK/bin/ata" <<'EOF'
#!/usr/bin/env bash
if [ "$1" = "list" ]; then
  printf '  main-website   主站前端 · 30 skills\n'
  printf '  teacher-web    教師端 · 5 skills\n'
  exit 0
fi
exec sleep 600   # stand in for an interactive claude session
EOF
chmod +x "$WORK/bin/tmux" "$WORK/bin/ata"
export PATH="$WORK/bin:$PATH"
export ATAMUX_STATE_DIR="$WORK/state"
export ATAMUX_SESSION="ata"

echo "== pure functions =="
source "$ROOT/bin/atamux"
check "status_icon waiting" "$(status_icon waiting)" "●"
check "status_icon idle"    "$(status_icon idle)"    "○"
check "status_icon exited"  "$(status_icon exited)"  "✗"
check "human_since 5s"   "$(human_since 95 100)"   "5s ago"
check "human_since 2m"   "$(human_since 0 120)"    "2m ago"
check "pane_key %47"     "$(pane_key '%47')"       "_47"
check "parse_ata_list"   "$(printf '  main-website  d\n  teacher-web  e\n' | parse_ata_list | tr '\n' ',')" "main-website,teacher-web,"

echo "== atamux-hook writes state + renames window =="
tmux new-session -d -s ata -n placeholder
PANE="$(tmux list-panes -t ata -F '#{pane_id}' | head -1)"
AT_AGENTS_PRODUCT="main-website" TMUX_PANE="$PANE" "$ROOT/bin/atamux-hook" Notification
KEY="${PANE//[^0-9A-Za-z]/_}"
check "state file status" "$(cut -f1 "$ATAMUX_STATE_DIR/$KEY" 2>/dev/null)" "waiting"
check "state file product" "$(cut -f2 "$ATAMUX_STATE_DIR/$KEY" 2>/dev/null)" "main-website"
check "window renamed" "$(tmux display-message -p -t "$PANE" '#{window_name}')" "● main-website"

echo "== hook is a no-op outside the ata session =="
tmux new-session -d -s other -n w
OPANE="$(tmux list-panes -t other -F '#{pane_id}' | head -1)"
AT_AGENTS_PRODUCT="x" TMUX_PANE="$OPANE" "$ROOT/bin/atamux-hook" Notification
OKEY="${OPANE//[^0-9A-Za-z]/_}"
[ ! -f "$ATAMUX_STATE_DIR/$OKEY" ] && ok "no state written for non-ata session" || no "wrote state for non-ata session"

echo "== launcher spawns + dedups windows =="
tmux kill-session -t ata 2>/dev/null
TMUX=fake ATAMUX_SELECT="main-website,teacher-web" cmd_new >/dev/null 2>&1
check "two product windows" "$(tmux list-windows -t ata -F '#{@atamux_product}' | grep -c .)" "2"
TMUX=fake ATAMUX_SELECT="main-website" cmd_new >/dev/null 2>&1
check "dedup: still two windows" "$(tmux list-windows -t ata -F '#{@atamux_product}' | grep -c .)" "2"

echo "== build_list renders a row per window =="
check "build_list rows" "$(build_list | grep -c .)" "2"

echo "== install / uninstall are reversible =="
export TMUX_CONF="$WORK/tmux.conf"; export CLAUDE_SETTINGS="$WORK/claude.json"
export BIN_DST="$WORK/localbin"
printf 'set -g mouse on\n' > "$TMUX_CONF"
printf '{"hooks":{"Stop":[{"hooks":[{"type":"command","command":"echo keepme"}]}]}}\n' > "$CLAUDE_SETTINGS"
TMUX= bash "$ROOT/install.sh" >/dev/null 2>&1
check "binding injected"      "$(grep -c 'atamux new' "$TMUX_CONF")" "1"
check "symlink created"       "$([ -L "$BIN_DST/atamux" ] && echo yes)" "yes"
check "hook merged"           "$(jq -r '.hooks.Notification[0].hooks[0].command' "$CLAUDE_SETTINGS")" "atamux-hook Notification"
check "existing hook kept"    "$(jq -r '.hooks.Stop[] | .hooks[].command' "$CLAUDE_SETTINGS" | grep -c keepme)" "1"
TMUX= bash "$ROOT/install.sh" >/dev/null 2>&1   # idempotent re-run
check "binding not duplicated" "$(grep -c 'atamux new' "$TMUX_CONF")" "1"
check "hook not duplicated"    "$(jq '[.hooks.Notification[]] | length' "$CLAUDE_SETTINGS")" "1"
TMUX= bash "$ROOT/uninstall.sh" >/dev/null 2>&1
check "binding removed"       "$(grep -c 'atamux' "$TMUX_CONF")" "0"
check "original conf kept"    "$(grep -c 'mouse on' "$TMUX_CONF")" "1"
check "atamux hook removed"   "$(jq -r '.hooks.Notification // "gone"' "$CLAUDE_SETTINGS")" "gone"
check "other hook survives"   "$(jq -r '.hooks.Stop[] | .hooks[].command' "$CLAUDE_SETTINGS" | grep -c keepme)" "1"

echo
echo "----- $PASS passed, $FAIL failed -----"
[ "$FAIL" -eq 0 ]
