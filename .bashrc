#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

# Set background color
xsetroot -solid "#000000"

# Set language keyboard layouts
setxkbmap us,ru 

# Add GHCup to PATH
export PATH="$HOME/.ghcup/bin:$PATH"

# Add NVM to PATH
source /usr/share/nvm/init-nvm.sh

# Add dotfiles alias
alias dotfiles='/usr/bin/git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME"'

# SSH Agent (silence)
if [ -z "$SSH_AUTH_SOCK" ] ; then
  eval `ssh-agent -s` > /dev/null
fi
