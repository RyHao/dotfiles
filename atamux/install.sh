#!/usr/bin/env bash
# atamux installer — idempotent, reversible (see uninstall.sh).
#   - symlinks bin/atamux, bin/atamux-hook into ~/.local/bin
#   - injects tmux bindings into ~/.tmux.conf inside a marker block
#   - merges Claude hooks into ~/.claude/settings.json via jq (preserves existing)
#
# Override targets via env: BIN_DST, TMUX_CONF, CLAUDE_SETTINGS (used by tests).
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DST="${BIN_DST:-$HOME/.local/bin}"
TMUX_CONF="${TMUX_CONF:-$HOME/.tmux.conf}"
CLAUDE_SETTINGS="${CLAUDE_SETTINGS:-$HOME/.claude/settings.json}"
MARK_BEGIN="# >>> atamux >>>"
MARK_END="# <<< atamux <<<"

info() { printf '  \033[32m✓\033[0m %s\n' "$1"; }
warn() { printf '  \033[33m!\033[0m %s\n' "$1"; }

# Write stdin to a file, following symlinks (so editing a symlinked dotfile
# updates its target instead of replacing the link with a regular file).
write_through() { cat > "$1"; }

echo "Installing atamux from $HERE"

# 1) Symlink scripts onto PATH ------------------------------------------------
chmod +x "$HERE/bin/atamux" "$HERE/bin/atamux-hook"
mkdir -p "$BIN_DST"
ln -sf "$HERE/bin/atamux"      "$BIN_DST/atamux"
ln -sf "$HERE/bin/atamux-hook" "$BIN_DST/atamux-hook"
info "linked atamux, atamux-hook → $BIN_DST"
case ":$PATH:" in
  *":$BIN_DST:"*) ;;
  *) warn "$BIN_DST is not in your PATH — add it so the tmux popup can find atamux" ;;
esac

# 2) tmux bindings (marker block) --------------------------------------------
touch "$TMUX_CONF"
if grep -qF "$MARK_BEGIN" "$TMUX_CONF"; then
  tmp="$(mktemp)"
  awk -v b="$MARK_BEGIN" -v e="$MARK_END" '
    $0==b{skip=1} !skip{print} $0==e{skip=0}
  ' "$TMUX_CONF" > "$tmp"
  write_through "$TMUX_CONF" < "$tmp"; rm -f "$tmp"
fi
{
  echo "$MARK_BEGIN"
  cat "$HERE/snippets/tmux.conf"
  echo "$MARK_END"
} >> "$TMUX_CONF"
info "tmux bindings written to $TMUX_CONF (prefix+C launch, prefix+g switch)"

# 3) Claude hooks (jq merge) --------------------------------------------------
if command -v jq >/dev/null 2>&1; then
  mkdir -p "$(dirname "$CLAUDE_SETTINGS")"
  [ -f "$CLAUDE_SETTINGS" ] || echo '{}' > "$CLAUDE_SETTINGS"
  cp "$CLAUDE_SETTINGS" "$CLAUDE_SETTINGS.atamux.bak"
  tmp="$(mktemp)"
  jq '
    def ensure($e; $c):
      .hooks[$e] = ((.hooks[$e] // [])
        | if any(.[]?; ((.hooks // [])[]?.command) == $c) then .
          else . + [{"hooks":[{"type":"command","command":$c}]}] end);
    (.hooks //= {})
    | ensure("SessionStart";    "atamux-hook SessionStart")
    | ensure("UserPromptSubmit";"atamux-hook UserPromptSubmit")
    | ensure("Notification";    "atamux-hook Notification")
    | ensure("Stop";            "atamux-hook Stop")
  ' "$CLAUDE_SETTINGS" > "$tmp" && mv "$tmp" "$CLAUDE_SETTINGS"
  info "Claude hooks merged into $CLAUDE_SETTINGS (backup: *.atamux.bak)"
else
  warn "jq not found — skipped Claude hooks (status detection). brew install jq, then re-run."
fi

# 4) Reload tmux if a server is running --------------------------------------
if [ -n "${TMUX:-}" ] || tmux info >/dev/null 2>&1; then
  tmux source-file "$TMUX_CONF" 2>/dev/null && info "reloaded tmux config" || true
fi

echo "Done. Use prefix+C to launch products, prefix+g to switch."
