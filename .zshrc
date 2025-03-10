# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000

bindkey -v
# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall
zstyle :compinstall filename '/home/kayp/.zshrc'

autoload -Uz compinit
compinit

alias vim=nvim

if command -v eza >/dev/null 2>&1; then
  alias ls="eza --icons"
  alias ll="eza --icons --long --header"
  alias lsa="eza --icons --long --all --header"
  alias lt="eza --icons --tree"
  alias lg="eza --icons --long --header --git"
fi

alias ..="cd .."
alias ...="cd ../.."

mkcd() { mkdir -p "$1" && cd "$1" }

if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

if [ -f /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
  source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# Enable autosuggestions if installed
if [ -f /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
  source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

# End of lines added by compinstall
