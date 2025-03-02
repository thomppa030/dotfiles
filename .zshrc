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
alias yay=paru

eval "$(starship init zsh)"
# End of lines added by compinstall
