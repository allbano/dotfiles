# =========================================================================== #
#                           Arch Linux .bashrc                                #
#                        Consolidado & Refatorado                             #
# =========================================================================== #

# 1. PROTEÇÃO DE SHELL NÃO-INTERATIVO
# =========================================================================== #
# Se não estiver rodando interativamente, não faça nada.
[[ $- != *i* ]] && return

# 2. VARIÁVEIS DE AMBIENTE GERAIS
# =========================================================================== #
export EDITOR="nvim"
export VISUAL="nvim"
export PAGER="less -R -s -M -Gg"
# Verifica se lvim existe antes de definir como manpager, senão usa less/nvim
if command -v lvim &>/dev/null; then
    export MANPAGER="lvim +Man!"
    export AUR_PAGER="lvim"
else
    export MANPAGER="nvim +Man!"
    export AUR_PAGER="nvim"
fi
export TERM="xterm-256color"
export LS_OPTIONS="--color=auto"

# Caminhos XDG e Pastas Padrão
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CONFIG_HOME="$HOME/.config"
export JUPYTERLAB_DIR="$XDG_DATA_HOME/jupyter/lab"

# Docker e Java
export DOCKER_HOST="unix:///var/run/docker.sock" # Consolidado (removido duplicidade)
export JAVA_HOME="/usr/lib/jvm/default"          # Removido /bin para apontar para a home correta
export PIPX_DEFAULT_PYTHON="/usr/bin/python"

# Dotfiles
export DOTFILES="$HOME/github/dotfiles"
export DOTBASH="$DOTFILES/bash"

# 3. PATH (CAMINHOS DO SISTEMA)
# =========================================================================== #
# Função auxiliar para adicionar ao PATH se o diretório existir e não estiver lá
path_append() {
    if [[ -d "$1" ]] && [[ ":$PATH:" != *":$1:"* ]]; then
        export PATH="$1:$PATH" # Prepend para prioridade (user > system)
    fi
}

path_append "$HOME/bin"
path_append "$HOME/.local/bin"
path_append "$HOME/go/bin"
path_append "$HOME/.cargo/bin"
path_append "/usr/sbin"
path_append "/sbin"

unset -f path_append

# 4. CONFIGURAÇÕES DO BASH (OPTIONS)
# =========================================================================== #
shopt -s histappend       # Anexa ao histórico, não sobrescreve
shopt -s histreedit       # Permite re-editar falhas de substituição de histórico
shopt -s histverify       # Permite verificar a substituição antes de executar
shopt -s checkwinsize     # Atualiza linhas/colunas ao redimensionar janela
shopt -s autocd           # Muda de diretório apenas digitando o nome
shopt -s cdspell          # Corrige pequenos erros de digitação no cd
shopt -s cmdhist          # Salva comandos multi-linha como uma entrada única
shopt -s dotglob          # * inclui arquivos ocultos (exceto . e ..)
shopt -s extglob          # Habilita padrões estendidos de globbing
shopt -s expand_aliases   # Expande aliases

# Autocomplete programável
if [[ -r /usr/share/bash-completion/bash_completion ]]; then
    source /usr/share/bash-completion/bash_completion
fi

# 5. CONFIGURAÇÃO DE HISTÓRICO
# =========================================================================== #
# Ignora espaço inicial e duplicatas consecutivas
#export HISTCONTROL=ignoreboth:erasedups
export HISTCONTROL=erasedups
export HISTFILE="$HOME/.bash_history"
export HISTSIZE=25000
export HISTFILESIZE=25000

# Lista de ignorados (Refatorado para legibilidade)
#_HIST_IGNORE_LIST=(
#    "ls" "l *" "ll" "cd" "cd *" "pwd" "exit" "clear" "history"
#    "bg" "fg" "man *"
#    "htop" "nvtop" "bashtop" "btop"
#    "du *" "ncdu" "dust"
#    "ip -c a" "fastfetch" "neofetch"
#    "git status" "gst" "ga ." "gaa" "gp" "gl"
#    "vim" "nvim" "lvim"
#    "..*" 
#    "nvm" "nvm version" "npm version" "ng version"
#)

# Une o array em uma string separada por dois pontos
#printf -v HISTIGNORE "%s:" "${_HIST_IGNORE_LIST[@]}"
#export HISTIGNORE="${HISTIGNORE%:}" # Remove o último :
#unset _HIST_IGNORE_LIST

# Sincronização imediata do histórico entre terminais
# append (-a), new lines (-n), write (-w), clear list (-c), read file (-r)
export PROMPT_COMMAND="history -a; history -n; ${PROMPT_COMMAND}"

# 6. FERRAMENTAS EXTERNAS E INTEGRAÇÕES
# =========================================================================== #

# Cores do LS (Dircolors)
if command -v dircolors &>/dev/null; then
    if [[ -r "$HOME/.dircolors" ]]; then
        eval "$(dircolors -b "$HOME/.dircolors")"
    else
        eval "$(dircolors -b)"
    fi
fi

# SSH Agent (Refatorado para não criar múltiplos agentes)
if ! pgrep -u "$USER" ssh-agent > /dev/null; then
    ssh-agent -s > "$XDG_RUNTIME_DIR/ssh-agent.env"
fi
if [[ ! -f "$SSH_AUTH_SOCK" ]]; then
    [ -f "$XDG_RUNTIME_DIR/ssh-agent.env" ] && source "$XDG_RUNTIME_DIR/ssh-agent.env" >/dev/null
fi

# FZF (Fuzzy Finder)
[ -f "$HOME/.fzf.bash" ] && source "$HOME/.fzf.bash"

# Pipx Autocomplete
if command -v register-python-argcomplete &>/dev/null && command -v pipx &>/dev/null; then
    eval "$(register-python-argcomplete pipx)"
fi

# Go (Lang)
if command -v go &>/dev/null; then
   # Verifica se gocomplete existe antes de configurar
   [[ -x "$HOME/go/bin/gocomplete" ]] && complete -C "$HOME/go/bin/gocomplete" go
fi

# Mise (Gerenciador de versões - substituto asdf)
# Autocomplete do Mise
[[ -x "$HOME/.local/bin/mise" ]] && eval "$($HOME/.local/bin/mise completion bash)" && eval "$($HOME/.local/bin/mise activate bash)"


# Angular CLI Autocomplete
if command -v ng &>/dev/null; then
    source <(ng completion script)
fi

# 7. CARREGAMENTO DE ARQUIVOS EXTERNOS (ALIASES E FUNÇÕES)
# =========================================================================== #
# Se os arquivos existirem no seu repositório dotfiles, carrega-os.
# Caso contrário, não gera erro.
[[ -f "$DOTFILES/bash/bash_aliases" ]] && source "$DOTFILES/bash/bash_aliases"

# Funções personalizadas
[[ -r "$DOTBASH/functions/00_init_functions" ]] && source "$DOTBASH/functions/00_init_functions"
[[ -r "$DOTBASH/functions/functionsInitBash" ]] && source "$DOTBASH/functions/functionsInitBash"


# Custom Startup (Lógica do arquivo 99_custom_startup)
# Verifica se a função pullDotfiles existe antes de tentar rodar
if [[ "$SHLVL" -eq 1 ]] && command -v pullDotfiles &>/dev/null; then
    # Verifica se não é um pseudo-terminal secundário para evitar loops
    if [[ $(ps -o tty= -p$$ | sed 's/pts\///') -eq 2 ]]; then
         pullDotfiles
    fi
fi

# 8. CONFIGURAÇÃO DO PROMPT (PS1)
# =========================================================================== #
# Definição de cores
FMT_BOLD="\[\e[1m\]"
FMT_RESET="\[\e[0m\]"
FG_RED="\[\e[1;31m\]"
FG_GREEN="\[\e[1;32m\]"
FG_YELLOW="\[\e[1;33m\]"
FG_BLUE="\[\e[1;34m\]"
FG_CYAN="\[\e[1;36m\]"
FG_WHITE="\[\e[97m\]"
BG_BLUE="\[\e[44m\]"
BG_CYAN_ESC="\[\e[46m\]"
BG_GREY10="\[\e[48;5;239m\]"

# Função para construir o prompt dinamicamente
build_prompt() {
    local EXIT_CODE=$? # Captura o erro do último comando imediatamente

    # Executa prompt_status se existir (era chamado no PROMPT_COMMAND antigo)
    if command -v prompt_status &>/dev/null; then
        prompt_status
    fi

    PS1=""
    # 1. Usuário e Host
    PS1+="${BG_GREY10}${FG_CYAN} \u${FG_WHITE}@${FG_YELLOW}\H "
    
    # 2. Diretório Atual
    PS1+="${BG_BLUE}${FG_YELLOW} \w "
    
    # 3. Contagem de arquivos (apenas se find for rápido o suficiente)
    # Nota: Isso pode causar lentidão em diretórios de rede ou muito grandes.
    PS1+="${BG_GREY10}${FG_WHITE} "
    PS1+="[$(find . -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)]D "
    PS1+="[$(find . -mindepth 1 -maxdepth 1 -type f 2>/dev/null | wc -l)]F "
    PS1+="[$(find . -mindepth 1 -maxdepth 1 -type l 2>/dev/null | wc -l)]SL "
    
    # 4. Git Info
    # Checamos se estamos num repo git para não chamar comandos desnecessariamente
    if git rev-parse --is-inside-work-tree &>/dev/null; then
        PS1+="${FMT_RESET}${BG_CYAN_ESC}${FG_WHITE}"
        
        # Branch
        local BRANCH=$(git branch --show-current 2>/dev/null)
        PS1+="( ${BRANCH} )"
        
        # Status simplificado
        # Nota: Otimizado para não rodar git status 4 vezes
        local GSTATUS=$(git status --porcelain 2>/dev/null)
        
        if [[ -n "$GSTATUS" ]]; then
            local ADDED=$(echo "$GSTATUS" | grep '^A' | wc -l)
            local MODIFIED=$(echo "$GSTATUS" | grep '^ M' | wc -l) # Modificado mas não staged
            local STAGED=$(echo "$GSTATUS" | grep '^M' | wc -l)   # Modificado e staged
            local UNTRACKED=$(echo "$GSTATUS" | grep '^??' | wc -l)
            
            [[ $ADDED -gt 0 ]] && PS1+=" A($ADDED)"
            [[ $STAGED -gt 0 ]] && PS1+=" M($STAGED)"
            [[ $MODIFIED -gt 0 ]] && PS1+=" UM($MODIFIED)"
            [[ $UNTRACKED -gt 0 ]] && PS1+=" U($UNTRACKED)"
        fi
    fi

    # 5. Finalização e quebra de linha
    PS1+="${FMT_RESET}\n"
    
    # Seta indicadora (Vermelha se erro anterior, Ciano se sucesso)
    # Assume SYMBOL definido externamente ou usa exit code
    if [[ $EXIT_CODE -eq 0 ]]; then
        PS1+="${FG_CYAN}⟩⟩ ${FMT_RESET}"
    else
        PS1+="${FG_RED}⟩⟩ ${FMT_RESET}"
    fi
}

# Define o PROMPT_COMMAND para construir o prompt a cada interação
PROMPT_COMMAND="build_prompt; $PROMPT_COMMAND"


[[ $SHLVL -eq 1 || $(ps -o tty= -p$$ | sed 's/pts\///') -eq 0 ]] && pullDotfiles
# =========================================================================== #
# Fim do .bashrc
# =========================================================================== #
