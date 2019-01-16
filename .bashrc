# .bashrc
# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

PS1="${PS1::-3} \n$ "

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=
export EDITOR=nano
export VISUAL=vim
export GIT_EDITOR=nano

# User specific aliases and functions

alias cdheute='cd `mkdir_heute.sh`'
alias rainbowstream='source venv/bin/activate && rainbowstream -iot'
alias ls='ls -aslhtr'
alias rclone-gd_btrfs='rclone mount --allow-other --allow-non-empty gd-rclone: /mnt/btrfs/gd &'

if [ -f `which powerline-daemon` ]; then
  powerline-daemon -q
  POWERLINE_BASH_CONTINUATION=1
  POWERLINE_BASH_SELECT=1
  . /usr/share/powerline/bash/powerline.sh
fi

if [ -z "$TMUX" ]; then
   mux default          
fi   
