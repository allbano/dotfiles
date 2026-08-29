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
export PAGER="cat"
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

# Prevenção na captura: comandos triviais não entram no histórico.
# A deduplicação esparsa fica a cargo do cmdsh (alias hsync).
# HISTIGNORE: padrões seguros (evita recursão do bash com padrões como 'lscpu')
# Nunca use padrões simples que colidem com comandos comuns (ex: lscpu, ls, cd)
# pois causam loop infinito de expansão de histórico.
export HISTIGNORE="&:exit:clear:bg:fg:jobs"
export HISTIGNORE="${HISTIGNORE}:cd:cd *:pwd:his:history:history *"
export HISTIGNORE="${HISTIGNORE}:ls:ls *:ll:ll *:la:la *:l:l *:e:e *:ea:ea *"
export HISTIGNORE="${HISTIGNORE}:dir:dirs:pushHis:pullDotfiles"
export HISTIGNORE="${HISTIGNORE}:ff:fastfetch:fd:fd *:find:findmnt:mv *"
export HISTIGNORE="${HISTIGNORE}:nproc:pidof:rg:du:du *:dust:dust *"
export HISTIGNORE="${HISTIGNORE}:echo *:export *:ips:which *:man *:mkdir *"
export HISTIGNORE="${HISTIGNORE}:ns *:nu:fish:zsh:bootctl"
export HISTIGNORE="${HISTIGNORE}:cpufetch:* version:* --version:* help:* --help:* -h"
export HISTIGNORE="${HISTIGNORE}:flatpak:flatpak *:mise *:python:python *"
export HISTIGNORE="${HISTIGNORE}:rclone:rclone *:rsync:fdisk:fdisk *:fmt:fmt *"
export HISTIGNORE="${HISTIGNORE}:sudo systemctl status:systemctl --user status"
export HISTIGNORE="${HISTIGNORE}:distro:distrobox:cat *:alias:alias *"
export HISTIGNORE="${HISTIGNORE}:cargo:cargo *:go:go *:node:node *:npm:npm *"
export HISTIGNORE="${HISTIGNORE}:pip:pip *:pipx:pipx *:code:code ."
export HISTIGNORE="${HISTIGNORE}:codium:codium .:codium-insiders:codium-insiders ."
export HISTIGNORE="${HISTIGNORE}:ps:ps aux:ss:ip:ip -c a:ip -c r:wc -l *"
export HISTIGNORE="${HISTIGNORE}:docker images:docker image:docker container"
export HISTIGNORE="${HISTIGNORE}:docker ps:docker volume:docker network"
export HISTIGNORE="${HISTIGNORE}:docker events:docker history:docker plugin"
export HISTIGNORE="${HISTIGNORE}:docker buildx:docker compose up"
export HISTIGNORE="${HISTIGNORE}:docker compose up --force-recreate"
export HISTIGNORE="${HISTIGNORE}:docker compose down:docker compose down *"
export HISTIGNORE="${HISTIGNORE}:git status:git status --short:gst:gss:gsb"
export HISTIGNORE="${HISTIGNORE}:glol:glol *:glod:glod *:git add *:gaa"
export HISTIGNORE="${HISTIGNORE}:git branch *:git commit *:git config"
export HISTIGNORE="${HISTIGNORE}:git push *:git pull *:git restore *"
export HISTIGNORE="${HISTIGNORE}:git shortlog:git stash *:ud:un:ldk:lsku"
export HISTIGNORE="${HISTIGNORE}:sct:sct status:sct status *:./*"
export HISTIGNORE="${HISTIGNORE}:paru -Syu:paru -Ss*:paru -Ss *"
export HISTIGNORE="${HISTIGNORE}:yay -Syu:yay -Ss*:yay -Ss *"
export HISTIGNORE="${HISTIGNORE}:sudo pacman -Syu:sudo-rs pacman -Syu:srs pacman -Syu"
export HISTIGNORE="${HISTIGNORE}:sudo pacman -Ss*:sudo-rs pacman -Ss*:srs pacman -Ss*"

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
shopt -u lithist
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
# Carrega o ambiente de um agente já em execução; só inicia um novo se não houver.
_ssh_agent_env="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/ssh-agent.env"
if pgrep -u "$USER" ssh-agent > /dev/null; then
    # Agente já existe: carrega SSH_AUTH_SOCK/SSH_AGENT_PID se ainda não definidos
    if [[ -z "$SSH_AUTH_SOCK" && -r "$_ssh_agent_env" ]]; then
        source "$_ssh_agent_env" > /dev/null
    fi
else
    # Nenhum agente: inicia e já exporta no shell atual (não apenas no arquivo)
    ssh-agent -s > "$_ssh_agent_env"
    source "$_ssh_agent_env" > /dev/null
fi
unset _ssh_agent_env

# FZF
[[ -f "$HOME/.fzf.bash" ]] && source "$HOME/.fzf.bash"

# Pipx (com timeout: interpretador Python pode ser lento/travar)
if command -v register-python-argcomplete &>/dev/null && command -v pipx &>/dev/null; then
    _pipx_compl="$(timeout 3 register-python-argcomplete pipx 2>/dev/null)"
    [[ -n "$_pipx_compl" ]] && eval "$_pipx_compl"
    unset _pipx_compl
fi

# Go
if command -v go &>/dev/null; then
   [[ -x "$HOME/go/bin/gocomplete" ]] && complete -C "$HOME/go/bin/gocomplete" go
fi

# Mise (asdf replacement)
#[[ -x "$HOME/.local/bin/mise" ]] && eval "$($HOME/.local/bin/mise completion bash)" && eval "$($HOME/.local/bin/mise activate bash)"
# Mise (com timeout: se travar ou demorar >3s, o shell abre normalmente sem ele)
if [[ -x "$HOME/.local/bin/mise" ]]; then
    _mise_out="$(timeout 3 "$HOME/.local/bin/mise" activate bash 2>/dev/null | tr -d '\000')"
    [[ -n "$_mise_out" ]] && eval "$_mise_out"
    _mise_out="$(timeout 3 "$HOME/.local/bin/mise" completion bash 2>/dev/null | tr -d '\000')"
    [[ -n "$_mise_out" ]] && eval "$_mise_out"
    unset _mise_out
fi

# Angular (lazy load: 'ng completion script' é muito lento para rodar a cada shell)
# Gera o script de completion uma vez em cache; regenera com: _ng_completion_refresh
_ng_completion_cache="${XDG_CACHE_HOME:-$HOME/.cache}/ng-completion.bash"
_ng_completion_refresh() {
    command -v ng &>/dev/null && ng completion script > "$_ng_completion_cache" 2>/dev/null
}
if command -v ng &>/dev/null; then
    if [[ -r "$_ng_completion_cache" ]]; then
        source "$_ng_completion_cache"
    else
        # Cache ainda não existe: gera em background para não travar a abertura
        ( _ng_completion_refresh && touch "$_ng_completion_cache.done" ) &>/dev/null &
    fi
fi

# 8. CARREGAMENTO DE EXTRAS (ALIASES E DOTFILES)
# =========================================================================== #
[[ -f "$DOTFILES/bash/bash_aliases" ]] && source "$DOTFILES/bash/bash_aliases"

# pull dotfiles (não-bloqueante: roda em background após o shell abrir)
if [[ $SHLVL -eq 1 ]] && [[ $(tty 2>/dev/null) == /dev/pts/0 ]]; then
    ( pullDotfiles > "${XDG_RUNTIME_DIR:-/tmp}/pullDotfiles.log" 2>&1 & )
fi


# Configuração do FZF para Ctrl+R
# --no-sort: Mantém ordem cronológica
# --exact: Busca exata (opcional)
export FZF_CTRL_R_OPTS="--no-sort --history-size=100000"

bind -x '"\C-f": _cmdsh_fzf_search'

# 9. ATIVAÇÃO DO PROMPT
# =========================================================================== #
# A função build_prompt está em .bash_functions
# PROMPT_COMMAND="build_prompt; $PROMPT_COMMAND"
PROMPT_COMMAND="${PROMPT_HISTORY} build_prompt;"

export PROMPT_COMMAND

