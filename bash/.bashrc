# =========================================================================== #
#                           Arch Linux .bashrc                                #
#                        Consolidado & Refatorado                             #
# =========================================================================== #

# PROTEÇÃO DE SHELL NÃO-INTERATIVO
# =========================================================================== #
[[ $- != *i* ]] && return

# CARREGAMENTO DE FUNÇÕES (IMPORTANTE: Carregar antes de usar)
# =========================================================================== #
if [[ -f "$HOME/.bash_functions" ]]; then
    source "$HOME/.bash_functions"
fi

# VARIÁVEIS DE AMBIENTE GERAIS
# =========================================================================== #
export EDITOR="nvim"
export VISUAL="nvim"
export PAGER="less -R -s -M -Gg"
# Ghostty needed
export GTK_IM_MODULE=gtk-im-context-simple

# Configuração de Manpager
if command -v lvim &>/dev/null; then
    export MANPAGER="lvim +Man!"
    export AUR_PAGER="lvim"
else
    export MANPAGER="nvim +Man!"
    export AUR_PAGER="nvim"
fi

#export TERM="xterm-256color"
export LS_OPTIONS="--color=auto"

# Caminhos XDG e Pastas Padrão
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CONFIG_HOME="$HOME/.config"
export JUPYTERLAB_DIR="$XDG_DATA_HOME/jupyter/lab"

# Docker / Java / Go
export DOCKER_HOST="unix:///var/run/docker.sock"
export JAVA_HOME="/usr/lib/jvm/default"
export PIPX_DEFAULT_PYTHON="/usr/bin/python"
#export GOPATH="$HOME/go"

# Dotfiles
export DOTFILES="$HOME/github/dotfiles"
export DOTBASH="$DOTFILES/bash"

# PATH (CAMINHOS DO SISTEMA)
# =========================================================================== #
# Usa a função path_append definida em .bash_functions
path_append "$HOME/bin"
path_append "$HOME/.local/bin"
#path_append "$GOPATH/bin"
path_append "$HOME/.cargo/bin"
path_append "/usr/sbin"
#path_append "/sbin"

# CONFIGURAÇÃO DE HISTÓRICO
# =========================================================================== #
export HISTFILE="$HOME/.bash_history"
export HISTSIZE=100000
export HISTFILESIZE=100000
export HISTCONTROL=ignoreboth:erasedups

PROMPT_HISTORY="history -a; history -n;"

# CONFIGURAÇÕES DO BASH (OPTIONS)
# =========================================================================== #
shopt -s histappend       # Anexa ao histórico
shopt -s histreedit       # Re-editar falhas
shopt -s histverify       # Verificar antes de executar
shopt -s checkwinsize     # Atualiza tamanho da janela
shopt -s autocd           # cd sem digitar cd
shopt -s cdspell          # Corrige erros no cd
shopt -s cmdhist          # Comandos multi-linha únicos
shopt -s dotglob          # * inclui ocultos
shopt -s extglob          # Globbing estendido
shopt -s expand_aliases   # Expande aliases

# Autocomplete do sistema
if [[ -r /usr/share/bash-completion/bash_completion ]]; then
    source /usr/share/bash-completion/bash_completion
fi


# 7. FERRAMENTAS EXTERNAS E INTEGRAÇÕES
# =========================================================================== #

# Dircolors
if [[ -f "$HOME/.dircolors" ]]; then
    eval "$(dircolors -b "$HOME/.dircolors")"
else
    eval "$(dircolors -b)"
fi

# SSH Agent
if ! pgrep -u "$USER" ssh-agent > /dev/null; then
    ssh-agent -s > "$XDG_RUNTIME_DIR/ssh-agent.env"
fi

# FZF
[[ -f "$HOME/.fzf.bash" ]] && source "$HOME/.fzf.bash"

# Pipx
if command -v register-python-argcomplete &>/dev/null && command -v pipx &>/dev/null; then
    eval "$(register-python-argcomplete pipx)"
fi

# Go
if command -v go &>/dev/null; then
   [[ -x "$HOME/go/bin/gocomplete" ]] && complete -C "$HOME/go/bin/gocomplete" go
fi

# Mise (asdf replacement)
#[[ -x "$HOME/.local/bin/mise" ]] && eval "$($HOME/.local/bin/mise completion bash)" && eval "$($HOME/.local/bin/mise activate bash)"
if [[ -x "$HOME/.local/bin/mise" ]]; then
    eval "$($HOME/.local/bin/mise activate bash | tr -d '\000')"
    eval "$($HOME/.local/bin/mise completion bash | tr -d '\000')"
fi

# Angular
if command -v ng &>/dev/null; then
    source <(ng completion script)
fi

# 8. CARREGAMENTO DE EXTRAS (ALIASES E DOTFILES)
# =========================================================================== #
[[ -f "$DOTFILES/bash/bash_aliases" ]] && source "$DOTFILES/bash/bash_aliases"

# pull dotfiles
if [[ $SHLVL -eq 1 ]] && [[ $(tty 2>/dev/null) == /dev/pts/0 ]]; then
    pullDotfiles
fi

# Configuração do FZF para Ctrl+R
# --no-sort: Mantém ordem cronológica
# --exact: Busca exata (opcional)
export FZF_CTRL_R_OPTS="--no-sort --history-size=100000"

# 9. ATIVAÇÃO DO PROMPT
# =========================================================================== #
# A função build_prompt está em .bash_functions
# PROMPT_COMMAND="build_prompt; $PROMPT_COMMAND"
PROMPT_COMMAND="${PROMPT_HISTORY} build_prompt;"

export PROMPT_COMMAND

