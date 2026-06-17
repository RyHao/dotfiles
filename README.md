# dotfiles

Personal macOS dev environment — zsh, tmux (tokyo-night), git, and tools.
Config files are symlinked into `$HOME`; packages and bootstrap are one command.

## Fresh machine

```bash
git clone git@github.com:RyHao/dotfiles.git ~/dotfiles
~/dotfiles/install.sh
```

`install.sh` is idempotent and staged:

| Command | Does |
|---|---|
| `install.sh` | everything below, then prints manual steps |
| `install.sh links` | symlink config files into `$HOME` (backs up existing to `*.pre-dotfiles.bak`) |
| `install.sh packages` | `brew bundle` from [`Brewfile`](./Brewfile) |
| `install.sh bootstrap` | tpm + tmux plugins, `mise install`, gitmux, [atamux](./atamux), ata |

A few things can't be scripted (printed at the end): iTerm2 font + color preset,
default shell, Node runtime (intentionally not pinned), `ata` (needs company npm
auth), and the `claude` CLI.

## What's linked

| Repo | → | `$HOME` |
|---|---|---|
| `zsh/zshrc.zsh` | → | `~/.zshrc` |
| `zsh/` | → | `~/.zsh` |
| `git/.gitconfig` | → | `~/.gitconfig` |
| `tmux/.tmux.conf` | → | `~/.tmux.conf` |
| `misc/.gitmux.conf` | → | `~/.gitmux.conf` |

The map lives in [`lib/symlink.sh`](./lib/symlink.sh). Run `lib/symlink.sh` alone
to (re)link, `lib/symlink.sh unlink` to remove just the managed symlinks.

## Layout

```
install.sh        one-key bootstrap (links + packages + bootstrap)
Brewfile          brew formulae + fonts this setup uses
lib/symlink.sh    declarative symlink map + linker
zsh/  git/  tmux/ shell, git, tmux config
misc/             ~/.gitmux.conf
theme/            iTerm2 color preset
atamux/           multi-session Claude Code launcher (own install.sh; called by bootstrap)
```

## tmux

tokyo-night theme + plugins (resurrect, continuum, yank, pain-control, fuzzback,
notify) via tpm. Requires a Nerd Font + GNU coreutils (the git widget uses
`stat -c`); both come from the `Brewfile`. See [atamux](./atamux) for the
Claude Code session launcher bound to `prefix+C` / `prefix+g`.
