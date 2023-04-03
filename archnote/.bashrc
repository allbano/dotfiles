# =========================================================================== #
#                              Meu .bashrc                                    #
# =========================================================================== #


### Sources ###
source "$HOME/.config/user-dirs.dirs"
source "/usr/share/nvm/init-nvm.sh"

### Exports and variables ###
# Modificando o PATH do sistema
#export PATH="$PATH:$HOME/.local/bin:$HOME/.cargo/bin:/usr/local/bin"
export XDG_DATA_HOME="/home/$USER/.local/share"
export EDITOR="nvim"
export TERM="xterm-256color"
export MANPAGER="less"
#export MANPAGER="most -s"
#export PAGER="cat"
export LESSHISTFILE="-"
export LS_OPTIONS='--color=auto'

HISTCONTROL=ignoreboth:erasedups
HISTFILE="$XDG_DATA_HOME/bash/history"
HISTSIZE=10000
HISTFILESIZE=2000
ALIASES="$XDG_DATA_HOME/bash/aliases"

## Colorir Manual
man() {
    env \
    LESS_TERMCAP_mb="$(printf "\e[1;32m")" \
    LESS_TERMCAP_md="$(printf "\e[1;32m")" \
    LESS_TERMCAP_me="$(printf "\e[0m")" \
    LESS_TERMCAP_se="$(printf "\e[0m")" \
    LESS_TERMCAP_so="$(printf "\e[1;33m")" \
    LESS_TERMCAP_ue="$(printf "\e[0m")" \
    LESS_TERMCAP_us="$(printf "\e[1;4;31m")" \
    man "${@}"
}


### Options ###
# set -o vi
shopt -s histappend
shopt -s expand_aliases
shopt -s checkwinsize
shopt -s autocd # change to named directory
shopt -s cdspell # autocorrects ced misspellings
shopt -s cmdhist # save multi-line commands in history as single line
shopt -s dotglob

[ -r /usr/share/bash-completion/bash_completion   ] && . /usr/share/bash-completion/bash_completion

#ignore upper and lowercase when TAB completion
#bind 'set completion-ignore-case on'

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

### Change window title ###
case "$TERM" in
	xterm*|rxvt*|Eterm*|aterm|kterm|gnome*|alacritty|st-256color|konsole*)
		PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME%%.*}:${PWD/#$HOME/\~}\007"'
		;;
	screen*)
		PROMPT_COMMAND='echo -ne "\033_${USER}@${HOSTNAME%%.*}:${PWD/#$HOME/\~}\033\\"'
		;;
esac


# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.
if [ -f "$XDG_DATA_HOME/bash/aliases" ]; then
    source "$XDG_DATA_HOME"/bash/aliases
fi

eval "`dircolors`"


# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
#[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
# if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
#    debian_chroot=$(cat /etc/debian_chroot)
# fi

FMT_BOLD="\[\e[1m\]"
FMT_DIM="\[\e[2m\]"
FMT_RESET="\[\e[0m\]"
FMT_UNBOLD="\[\e[22m\]"
FMT_UNDIM="\[\e[22m\]"
FG_BLACK="\[\e[30m\]"
FG_BLUE="\[\e[34m\]"
FG_CYAN="\[\e[36m\]"
FG_GREEN="\[\e[32m\]"
FG_GREY="\[\e[37m\]"
FG_MAGENTA="\[\e[35m\]"
FG_AZUL_VIVO="\[\e[79m\]"
FG_RED="\[\e[31m\]"
FG_WHITE="\[\e[97m\]"
BG_BLACK="\[\e[40m\]"
BG_BLUE="\[\e[44m\]"
BG_CYAN="\[\e[46m\]"
BG_GREEN="\[\e[42m\]"
BG_MAGENTA="\[\e[45m\]"
BG_YELLOW="\[\e[43m\]"
BG_GREY="\[\e[48;5;242m\]"
BG_GREY10="\[\e[48;5;239m\]"



PS1="\n${FG_WHITE}\342\224\214\342\224\200" # begin arrow to prompt
PS1+="${BG_GREY10}${FG_WHITE} \u " # print username
PS1+="${BG_BLUE}${FG_WHITE} \w " # print directory
PS1+="${FG_BLUE}${BG_GREY10}${FG_WHITE} " # end DIRECTORY container / begin FILES container
PS1+="D[\$(find . -mindepth 1 -maxdepth 1 -type d | wc -l)] " # print number of folders
PS1+="A[\$(find . -mindepth 1 -maxdepth 1 -type f | wc -l)] " # print number of files
PS1+="L[\$(find . -mindepth 1 -maxdepth 1 -type l | wc -l)] " # print number of symlinks
PS1+="${FMT_RESET}${BG_GREEN}${FG_WHITE}"
#PS1+="\$(git branch 2> /dev/null | grep '^*' | colrm 1 2 | xargs -I BRANCH echo -n \"( BRANCH )\")" 
PS1+="\$(git branch 2> /dev/null | grep '^*' | colrm 1 2 | xargs -I BRANCH echo -n \"( BRANCH )\")"
PS1+="${FMT_RESET}${FG_WHITE}" # print current git branch
PS1+="${FMT_RESET}${BG_GREEN}${FG_WHITE}"
PS1+="\$(git status -s 2> /dev/null | grep '^ M' | wc -l | sed 's/0//' | xargs -I MD echo -n \" !MD\")" 
PS1+="${FMT_RESET}${FG_WHITE}"
PS1+="${FMT_RESET}${BG_GREEN}${FG_WHITE}"
PS1+="\$(git status -s 2> /dev/null | grep '^?' | wc -l | sed 's/0//' | xargs -I MD echo -n \" ?MD\")" 
PS1+="${FMT_RESET}${FG_WHITE}"
PS1+="${FG_WHITE} - ${BG_GREY}${FG_WHITE}[\t]${FMT_RESET}\n" # end last container (either FILES or BRANCH)
PS1+="${FG_WHITE}\342\224\224\342\224\200\342\224\200\342\225\274 " # end arrow to prompt
PS1+="\[\e[1;37m\] \$ $FMT_RESET" # print prompt
export PS1

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias dir='dir --color=auto'
    alias grep='grep --color=auto'
    alias egrep='grep -E --color=auto'
fi


# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# Configure completion for doas
# -c : Complete arguments as if they were commands
#     (eg: `doas emer<tab>` -> `doas emerge`)
#     (eg: `doas dd status=p<tab>` -> `doas dd status=progress`)
# -f : Complete arguments as if they were directory names (default behaviour)
#     (eg: `doas /bi<tab>` -> `doas /bin/`)
complete -cf doas



# Load Angular CLI autocompletion.
source <(ng completion script)
