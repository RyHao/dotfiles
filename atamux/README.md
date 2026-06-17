# atamux

Launch and switch between multiple `ata`-driven Claude Code sessions in tmux.

A small layer over tmux + fzf + Claude Code hooks, built specifically for the
[`ata`](https://www.npmjs.com/package/@amazingtalker/at-cli) launcher. All Claude
windows live in one dedicated tmux session (`ata`), one window per product, with
live status (running / waiting-for-you / idle) shown in an fzf overview and in the
window names.

## Install / uninstall

```bash
~/dotfiles/atamux/install.sh      # symlinks + tmux bindings + Claude hooks
~/dotfiles/atamux/uninstall.sh    # reverses all of the above
~/dotfiles/atamux/uninstall.sh --purge   # also delete cached state
```

Both are idempotent and only touch their own marker block in `~/.tmux.conf` and
their own entries in `~/.claude/settings.json` (a `*.atamux.bak` backup is written).

Requires: `tmux >= 3.0`, `fzf`, `jq`, and `ata` on PATH. `~/.local/bin` must be on PATH.

## Usage

| Key | Action |
|-----|--------|
| `prefix + C` | **Launcher** — fzf multi-select over `ata list`; each pick opens as a window running `ata <product>` |
| `prefix + g` | **Switcher** — fzf overview of running sessions + status; Enter jumps, Ctrl-X kills a window |

Window-name glyphs: `●` waiting for you · `◐` running · `○` idle · `✗` exited.

## How status works

`ata` launches Claude with `AT_AGENTS_PRODUCT=<product>` in the environment.
The Claude Code hooks installed by `install.sh` call `atamux-hook <event>`, which
inherits that variable, so it knows the product for free. It records status into
`~/.cache/atamux/<pane>` and renames the window. The hook is a no-op unless the
pane belongs to the dedicated `ata` session, so Claude sessions you run elsewhere
are never touched.

## Layout

```
bin/atamux        launcher + switcher (pure helpers are source-testable)
bin/atamux-hook   Claude hook → writes per-pane status (fast, never fails)
snippets/         tmux bindings + Claude hooks merged by the installer
install.sh        idempotent install
uninstall.sh      reversible uninstall
tests/smoke.sh    isolated tests (private tmux socket + stub ata)
```

## Tests

```bash
tests/smoke.sh    # runs against a private tmux socket; touches nothing real
```
