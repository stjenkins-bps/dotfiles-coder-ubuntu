# Enable Powerlevel10k instant prompt — keep near top
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# History settings
HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000

# Zsh completion
autoload -Uz compinit
compinit

# Source Powerlevel10k theme
source ~/powerlevel10k/powerlevel10k.zsh-theme

# If you have a ~/.p10k.zsh from a prior config, source it
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

# Load zoxide
eval "$(zoxide init zsh)"

# Load zsh-vi-mode plugin
source ~/.zsh-vi-mode/zsh-vi-mode.plugin.zsh

# Custom exports
export EDITOR=nvim
export KUBE_EDITOR=nvim
export PATH="$HOME/.npm-global/bin:$HOME/.local/bin:$PATH"
export ARM_USE_MSI="false"

# Helpers
npmg() {
  npm --prefix "$HOME/.npm-global" "$@"
}

# Aliases
alias tf='terraform'
alias vi='nvim'
alias vim='nvim'
alias nv='nvim'
alias cd='z'
alias ls='lsd --icon always'
alias azauth='az login --use-device-code'
alias tree='lsd --tree --icon always'
alias wtree='watch --color "lsd --tree --icon always --color=always"'
alias wgits='watch --color "git -c color.status=true status -s "'

if [[ -z "${NVM_DIR:-}" ]]; then
  if [[ -s "$HOME/.nvm/nvm.sh" ]]; then
    export NVM_DIR="$HOME/.nvm"
  elif [[ -s /usr/local/nvm/nvm.sh ]]; then
    export NVM_DIR=/usr/local/nvm
  fi
fi

[ -n "${NVM_DIR:-}" ] && [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -n "${NVM_DIR:-}" ] && [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Execute Herdr (only when attached to a real interactive terminal;
# herdr panics without a TTY, which was crashing non-interactive/
# shell-integration login paths).
if [[ -t 0 && -t 1 && -z "${HERDR_ENV:-}" ]]; then
  herdr
fi
