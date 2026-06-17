#!/usr/bin/env bash
# atamux uninstaller — reverses install.sh.
#   - removes ~/.local/bin/atamux{,-hook} symlinks
#   - strips the marker block from ~/.tmux.conf
#   - removes atamux hooks from ~/.claude/settings.json (leaves other hooks intact)
#   - with --purge, also deletes the state dir ~/.cache/atamux
#
# Override targets via env: BIN_DST, TMUX_CONF, CLAUDE_SETTINGS, ATAMUX_STATE_DIR.
set -euo pipefail

BIN_DST="${BIN_DST:-$HOME/.local/bin}"
TMUX_CONF="${TMUX_CONF:-$HOME/.tmux.conf}"
CLAUDE_SETTINGS="${CLAUDE_SETTINGS:-$HOME/.claude/settings.json}"
STATE_DIR="${ATAMUX_STATE_DIR:-$HOME/.cache/atamux}"
MARK_BEGIN="# >>> atamux >>>"
MARK_END="# <<< atamux <<<"
PURGE=0
[ "${1:-}" = "--purge" ] && PURGE=1

info() { printf '  \033[32m✓\033[0m %s\n' "$1"; }

echo "Uninstalling atamux"

# 1) Remove symlinks ----------------------------------------------------------
rm -f "$BIN_DST/atamux" "$BIN_DST/atamux-hook"
info "removed symlinks from $BIN_DST"

# 2) Strip tmux marker block --------------------------------------------------
if [ -f "$TMUX_CONF" ] && grep -qF "$MARK_BEGIN" "$TMUX_CONF"; then
  tmp="$(mktemp)"
  awk -v b="$MARK_BEGIN" -v e="$MARK_END" '
    $0==b{skip=1} !skip{print} $0==e{skip=0}
  ' "$TMUX_CONF" > "$tmp"
  cat "$tmp" > "$TMUX_CONF"; rm -f "$tmp"   # follow symlink, don't replace it
  info "removed tmux bindings from $TMUX_CONF"
fi

# 3) Remove Claude hooks ------------------------------------------------------
if command -v jq >/dev/null 2>&1 && [ -f "$CLAUDE_SETTINGS" ]; then
  cp "$CLAUDE_SETTINGS" "$CLAUDE_SETTINGS.atamux.bak"
  tmp="$(mktemp)"
  jq '
    if (.hooks | type) == "object" then
      .hooks |= ( with_entries(
                    .value |= ( map(.hooks |= map(select(((.command // "") | startswith("atamux-hook")) | not)))
                              | map(select((.hooks | length) > 0)) )
                  )
                | with_entries(select((.value | length) > 0)) )
      | (if (.hooks | length) == 0 then del(.hooks) else . end)
    else . end
  ' "$CLAUDE_SETTINGS" > "$tmp" && mv "$tmp" "$CLAUDE_SETTINGS"
  info "removed atamux hooks from $CLAUDE_SETTINGS"
fi

# 4) Optionally purge state ---------------------------------------------------
if [ "$PURGE" = "1" ]; then
  rm -rf "$STATE_DIR"
  info "purged state dir $STATE_DIR"
fi

# 5) Reload tmux --------------------------------------------------------------
if [ -n "${TMUX:-}" ] || tmux info >/dev/null 2>&1; then
  tmux source-file "$TMUX_CONF" 2>/dev/null && info "reloaded tmux config" || true
fi

echo "Done. (The dedicated 'ata' tmux session, if running, is left untouched.)"
