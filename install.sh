#!/usr/bin/env bash
# One-key dotfiles bootstrap for a fresh macOS machine.
#
#   ./install.sh            run every stage (idempotent, safe to re-run)
#   ./install.sh links      only (re)create symlinks
#   ./install.sh packages   only brew bundle
#   ./install.sh bootstrap  only tpm / mise / atamux / etc.
#
# Stages are independent and idempotent. Nothing here is destructive: existing
# real dotfiles are backed up to *.pre-dotfiles.bak before being symlinked.
set -uo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTFILES
source "$DOTFILES/lib/symlink.sh"

hdr()  { printf '\n\033[1m== %s ==\033[0m\n' "$1"; }
info() { printf '  \033[32m✓\033[0m %s\n' "$1"; }
warn() { printf '  \033[33m!\033[0m %s\n' "$1"; }

ensure_brew() {
  if command -v brew >/dev/null 2>&1; then return 0; fi
  hdr "Homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)" 2>/dev/null || true
}

stage_links() {
  hdr "Symlinks"
  link_all
}

stage_packages() {
  hdr "Packages (brew bundle)"
  ensure_brew
  brew bundle --file="$DOTFILES/Brewfile" && info "Brewfile installed" || warn "brew bundle had issues"
}

stage_bootstrap() {
  hdr "Bootstrap"

  # tmux plugin manager + plugins
  if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    git clone --depth 1 https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm" && info "cloned tpm"
  else
    info "tpm already present"
  fi
  [ -x "$HOME/.tmux/plugins/tpm/bin/install_plugins" ] && \
    "$HOME/.tmux/plugins/tpm/bin/install_plugins" >/dev/null 2>&1 && info "tmux plugins installed"

  # mise runtimes from ~/.config/mise/config.toml (node intentionally NOT pinned)
  if command -v mise >/dev/null 2>&1; then
    mise install >/dev/null 2>&1 && info "mise runtimes installed" || warn "mise install had issues"
  fi

  # gitmux default config (only if missing; ours is symlinked from misc/)
  [ -e "$HOME/.gitmux.conf" ] || { command -v gitmux >/dev/null 2>&1 && gitmux -printcfg > "$HOME/.gitmux.conf" && info "wrote ~/.gitmux.conf"; }

  # atamux (its own idempotent installer: bindings + Claude hooks + ~/.local/bin links)
  if [ -x "$DOTFILES/atamux/install.sh" ]; then
    "$DOTFILES/atamux/install.sh" >/dev/null 2>&1 && info "atamux installed" || warn "atamux install had issues"
  fi

  # ata (private @amazingtalker CLI) — best effort; needs node + company npm auth
  if command -v mise >/dev/null 2>&1 && ! command -v ata >/dev/null 2>&1; then
    mise exec -- npm install -g @amazingtalker/at-cli >/dev/null 2>&1 \
      && info "installed ata" || warn "could not auto-install ata (see manual steps)"
  fi
}

checklist() {
  hdr "Manual steps (can't be scripted)"
  cat <<'EOF'
  • iTerm2 → Settings → Profiles → Text → Font: choose "MonaspiceNe Nerd Font"
  • iTerm2 → Settings → Profiles → Colors → Color Presets → Import:
        ~/dotfiles/theme/materialshell-dark.itermcolors
  • Default shell to zsh (if needed):   chsh -s "$(command -v zsh)"
  • Node runtime (not pinned by design): e.g.  mise use -g node@lts
  • ata needs Node + AmazingTalker npm auth if it didn't auto-install:
        mise exec -- npm install -g @amazingtalker/at-cli
  • claude CLI:  install per Anthropic docs (expected at ~/.local/bin/claude)
  • Open a new terminal so antigen pulls zsh plugins on first run.
EOF
}

main() {
  case "${1:-all}" in
    links)     stage_links ;;
    packages)  stage_packages ;;
    bootstrap) stage_bootstrap ;;
    all)       stage_links; stage_packages; stage_bootstrap; checklist ;;
    *) echo "usage: install.sh [all|links|packages|bootstrap]" >&2; exit 1 ;;
  esac
  printf '\nDone.\n'
}

main "$@"
