source ~/.zsh/plugin.zsh
source ~/.zsh/theme.zsh

export ANDROID_HOME=${HOME}/Library/Android/sdk
export PATH=${PATH}:${ANDROID_HOME}/tools
export PATH=${PATH}:${ANDROID_HOME}/platform-tools

export PATH=${PATH}:~/.yarn/bin
export PATH=${PATH}:~/.cargo/bin

export N_PREFIX="$HOME/n"; [[ :$PATH: == *":$N_PREFIX/bin:"* ]] || PATH+=":$N_PREFIX/bin"  # Added by n-install (see http://git.io/n-install-repo).

alias lg='lazygit'

# bun completions
[ -s "/Users/ryanlyu/.bun/_bun" ] && source "/Users/ryanlyu/.bun/_bun"
export PATH="$HOME/.bun/bin:$PATH"

export CLAUDE_CODE_NO_FLICKER=1

alias cct="caffeinate -i claude --permission-mode bypassPermissions --channels plugin:telegram@claude-plugins-official"
alias ccd="caffeinate -i claude --permission-mode bypassPermissions --channels plugin:discord@claude-plugins-official"
alias cc="claude --permission-mode bypassPermissions"

eval "$(/Users/ryanlyu/.local/bin/mise activate zsh)"
