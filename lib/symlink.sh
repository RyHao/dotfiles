#!/usr/bin/env bash
# Declarative dotfiles → $HOME symlink map + linker.
# Sourced by install.sh; can also be run directly to (re)link only.

DOTFILES="${DOTFILES:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

# "<repo path>|<target under $HOME>"
LINKS=(
  "zsh/zshrc.zsh|.zshrc"
  "zsh|.zsh"
  "git/.gitconfig|.gitconfig"
  "tmux/.tmux.conf|.tmux.conf"
  "misc/.gitmux.conf|.gitmux.conf"
)

_sl_info() { printf '  \033[32m✓\033[0m %s\n' "$1"; }
_sl_warn() { printf '  \033[33m!\033[0m %s\n' "$1"; }

# Link everything in LINKS using absolute paths. Existing real files/dirs are
# backed up to *.pre-dotfiles.bak; existing symlinks are replaced in place.
link_all() {
  local entry src dst
  for entry in "${LINKS[@]}"; do
    src="$DOTFILES/${entry%%|*}"
    dst="$HOME/${entry##*|}"
    if [ ! -e "$src" ]; then
      _sl_warn "skip (missing in repo): ${entry%%|*}"
      continue
    fi
    if [ -e "$dst" ] && [ ! -L "$dst" ]; then
      mv "$dst" "$dst.pre-dotfiles.bak"
      _sl_warn "backed up existing $dst → $dst.pre-dotfiles.bak"
    fi
    ln -sfn "$src" "$dst"          # -n: don't descend into an existing dir symlink
    _sl_info "$dst → $src"
  done
}

# Remove only the symlinks we manage (leaves *.pre-dotfiles.bak untouched).
unlink_all() {
  local entry dst
  for entry in "${LINKS[@]}"; do
    dst="$HOME/${entry##*|}"
    if [ -L "$dst" ]; then rm -f "$dst"; _sl_info "unlinked $dst"; fi
  done
}

# Allow running this file directly: `lib/symlink.sh` links, `lib/symlink.sh unlink` unlinks.
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  case "${1:-link}" in
    link)   link_all ;;
    unlink) unlink_all ;;
    *) echo "usage: symlink.sh [link|unlink]" >&2; exit 1 ;;
  esac
fi
