# Brewfile — packages this dotfiles setup actually uses.
# Install with:  brew bundle --file=~/dotfiles/Brewfile

# --- shell / version manager ---
brew "git"
brew "mise"            # runtime version manager (node/bun/pnpm/yarn); see ~/.config/mise/config.toml
brew "zoxide"          # smart cd; powers sesh + tmux-session jumps
brew "lazygit"         # `lg` alias in zshrc

# --- tmux + status bar ---
brew "tmux"
brew "fzf"             # used by sesh, tmux popups, fuzzy pickers
brew "sesh"            # session manager (prefix+T popup)
brew "gitmux"          # git status segment (config: ~/.gitmux.conf)
brew "jq"              # tokyo-night + atamux hook merge

# tokyo-night-tmux needs modern bash + GNU coreutils (its git widget calls `stat -c`)
brew "bash"            # macOS ships bash 3.2; theme scripts need 4+/5+
brew "coreutils"       # GNU stat/date for the git widget (gnubin on PATH via tmux.conf)
brew "gnu-sed"
brew "gawk"
brew "nowplaying-cli"  # tokyo-night music widget

# --- fonts (Nerd Font v3 + symbol fallback for the status bar glyphs) ---
cask "font-meslo-lg-nerd-font"
cask "font-monaspice-nerd-font"   # renamed from font-monaspace-nerd-font
cask "font-noto-sans-symbols-2"
