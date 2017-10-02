#!/bin/bash

shopt -s extglob nullglob globstar
shopt -s histverify checkwinsize
set -o vi
set +H

# toggle keymaps
ama() {
  [[ $DISPLAY ]] || return
  if setxkbmap -print | grep -q 'dvorak'; then
    setxkbmap us -option compose:ralt
  else
    setxkbmap us -variant dvorak -option compose:ralt
  fi
}

# stupidly simple calculator
calc() {
  awk "@include \"math.awk\"; BEGIN {print $*}"
}

# run dd and send USR1 every minute
dd_progress() {
  local pid

  dd "$@" & pid=$!
  while sleep 1m; do
    kill -USR1 "$pid" || break
  done
}

# sorted human readable dd
du_h() {
  du -sk "$@" |
  sort -n |
  awk -F '\t' -v OFS='\t' '
    {
      if ($1 > 1048576) {
        $1 = sprintf("%.1fG", $1 / 1048576);
      } else if ($1 > 1024) {
        $1 = sprintf("%.1fM", $1 / 1024);
      } else {
        $1 = sprintf("%sK", $1);
      }

      print;
    }
  ' | column -ts $'\t'
}

# check if a dir is in PATH
is_dir_in_path() {
  local path d t=$1

  IFS=: read -ra path <<<"$PATH"
  for d in "${path[@]}"; do
    [[ $d -ef "$t" ]] && return
  done

  return 1
}

# adds '.N' to a filename, sans extension, until it doesn't exist
noclobber() {
  local out=$1 i=0

  if [[ $out = *+([^/]).*([^/]) ]]; then
    local base=${1%.*} ext=${1##*.}

    while [[ -e $out ]]; do
      out=$base.$((++i)).$ext
    done
  else
    while [[ -e $out ]]; do
      out=$1.$((++i))
    done
  fi

  printf '%s\n' "$out"
}

sprunge() {
  if (($# > 1)); then
    local f

    for f; do
      if [[ ! -f $f ]]; then
        continue
      fi

      printf '%s: ' "$f"
      curl -F 'sprunge=<-' http://sprunge.us < "$f"
    done
  elif (($#)); then
    curl -F 'sprunge=<-' http://sprunge.us < "$1"
  else
    curl -F 'sprunge=<-' http://sprunge.us
  fi
}

alias sudo='sudo '
alias grep='grep --color=auto'
alias pacman='pacman --color=auto'
alias cower='cower -c'
alias ls='ls --color=auto'
alias vinfo='info --vi-keys'
alias moar='less'
alias udate='TZ=UTC date'
alias pac_removed='pac_removed -- -c'
alias alsaequal='alsamixer -D equal'

# set PS1
# colors
_i=0
for _c in _black _red _green _yellow _blue _magenta _cyan _white; do
  printf -v "$_c" %s "$(tput setaf "$_i")"
  ((_i++))
done
unset _i _c
_bold=$(tput bold)
_reset=$(tput sgr0)
# colors for exit status
_ret_cols=("$_red" "$_reset")

## don't use » in tty
#if [[ $(tty) = /dev/tty* ]]; then
#  PS1='\[$_cyan\]\u@\h:\w\n\[${_ret_cols[!$?]}\]\$\[$_reset\] '
#else
#  PS1='\[$_cyan\]\u@\h:\w\n\[${_ret_cols[!$?]}\]»\[$_reset\] '
#fi
PROMPT_COMMAND='history -a'
PS1='\[$_cyan\]\u@\h:\w\n\[${_ret_cols[!$?]}\]»\[$_reset\] '
