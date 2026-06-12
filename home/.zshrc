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

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
