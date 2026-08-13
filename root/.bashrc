# ~/.bashrc
# =============================================================================
# Arquivo de configuração do Bash para sessões interativas não-login
# Arch Linux - Configuração atualizada e otimizada
# =============================================================================

# -----------------------------------------------------------------------------
# SEÇÃO 1: CONFIGURAÇÕES BÁSICAS E SEGURANÇA
# -----------------------------------------------------------------------------

# Não carregar se não for sessão interativa
[[ $- != *i* ]] && return

# Histórico aprimorado
HISTFILE=~/.bash_history          # Arquivo do histórico
HISTSIZE=100000                    # Número de comandos em memória
HISTFILESIZE=100000                # Número de comandos no arquivo
HISTCONTROL=ignoreboth:erasedups  # Ignorar duplicados e comandos começando com espaço
HISTIGNORE="&:ls:exit:history"    # Comandos a não salvar no histórico
HISTTIMEFORMAT="%d/%m/%y %T "     # Formato de data/hora no histórico

# Ativar opções do shell
shopt -s histappend              # Anexar ao invés de sobrescrever histórico
shopt -s checkwinsize            # Verificar tamanho da janela após cada comando
shopt -s cmdhist                 # Salvar comandos multi-linha corretamente
shopt -s extglob                 # Ativar pattern matching estendido
#shopt -s nocaseglob              # Case-insensitive globbing
shopt -s autocd                  # Mudar diretório digitando apenas o nome
shopt -s cdspell                 # Corrigir erros de digitação no cd
shopt -s dirspell                # Corrigir erros na tab-completion
shopt -s globstar                # Permitir ** para recursão
shopt -s dotglob                 # Incluir arquivos ocultos no globbing

# -----------------------------------------------------------------------------
# SEÇÃO 2: VARIÁVEIS DE AMBIENTE IMPORTANTES
# -----------------------------------------------------------------------------

# Editor padrão (prioridade: neovim > vim > nano)
if command -v nvim &> /dev/null; then
    export EDITOR='nvim'
    export VISUAL='nvim'
elif command -v vim &> /dev/null; then
    export EDITOR='vim'
    export VISUAL='vim'
else
    export EDITOR='nano'
    export VISUAL='nano'
fi

# Paginador
export PAGER='less'
export LESS='-R -F -X'  # -R: cores, -F: sair se uma tela, -X: não limpar tela

# Linguagem
export LANG='en_US.UTF-8'
export LC_ALL='en_US.UTF-8'

# PATH personalizado
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

export LS_OPTIONS="--color=auto"

# Para desenvolvimento Python
#export PYTHONDONTWRITEBYTECODE=1  # Não criar arquivos .pyc
#export PYTHONUNBUFFERED=1         # Saída não bufferizada para Python

# Configurações do Java (se instalado)
[ -d "/usr/lib/jvm/default/bin" ] && export JAVA_HOME="/usr/lib/jvm/default/bin"

# Configurações do Go (se instalado)
[ -d "$HOME/go" ] && export GOPATH="$HOME/go"
[ -d "$HOME/go/bin" ] && export PATH="$HOME/go/bin:$PATH"

# Configurações do Rust (se instalado)
[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"

# -----------------------------------------------------------------------------
# SEÇÃO 3: ALIASES DE SEGURAÇA / ÚTEIS
# -----------------------------------------------------------------------------

# Navegação
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'
alias -- -='cd -'

# ls com cores e formatação
#if command -v exa &> /dev/null; then
#    # Usar exa se disponível (modern replacement for ls)
#    alias ls='exa --group-directories-first'
#    alias ll='exa -l --group-directories-first --git'
#    alias la='exa -la --group-directories-first --git'
#    alias lt='exa -T --group-directories-first'
#    alias l='exa -l --group-directories-first'
#else
#    # Fallback para ls tradicional
#    alias ls='ls --color=auto --group-directories-first'
#    alias ll='ls -lh --color=auto --group-directories-first'
#    alias la='ls -lAh --color=auto --group-directories-first'
#    alias l='ls -CF --color=auto --group-directories-first'
#fi

# Atalhos de segurança
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias ln='ln -i'

# Sistema
alias df='df -h'
alias du='du -h'
alias free='free -h'
alias psg='ps aux | grep -i'
alias mkdir='mkdir -pv'
alias wget='wget -c'  # Continuar downloads

# Pacman (gerenciador de pacotes do Arch)
alias pac='pacman'
alias update='pacman -Syu'
alias paclean='pacman -Sc'
alias pacorphans='pacman -Rns $(pacman -Qtdq)'

# Docker
alias d='docker'
alias dc='docker-compose'
alias dps='docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"'

# Carrega arquivo de aliases personalizado
# Carrega aliases se existirem
[[ -f ~/.bash_aliases ]] && source ~/.bash_aliases

# -----------------------------------------------------------------------------
# SEÇÃO 4: FUNÇÕES PERSONALIZADAS
# -----------------------------------------------------------------------------

# Criar diretório e entrar nele
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Extrair arquivos compactados
extract() {
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.bz2)  tar xjf "$1"      ;;
            *.tar.gz)   tar xzf "$1"      ;;
            *.bz2)      bunzip2 "$1"      ;;
            *.rar)      unrar x "$1"      ;;
            *.gz)       gunzip "$1"       ;;
            *.tar)      tar xf "$1"       ;;
            *.tbz2)     tar xjf "$1"      ;;
            *.tgz)      tar xzf "$1"      ;;
            *.zip)      unzip "$1"        ;;
            *.Z)        uncompress "$1"   ;;
            *.7z)       7z x "$1"         ;;
            *.deb)      ar x "$1"         ;;
            *.tar.xz)   tar xf "$1"       ;;
            *.tar.zst)  tar xf "$1"       ;;
            *)          echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Encontrar arquivo
ff() {
    find . -type f -iname "*$1*" 2>/dev/null
}

# Encontrar diretório
fd() {
    find . -type d -iname "*$1*" 2>/dev/null
}

# Histórico de comandos com grep
hg() {
    history | grep -i "$1"
}

# Limpar tela e mostrar header
cls() {
    clear
    if command -v fastfetch &> /dev/null; then
        fastfetch; echo ''
    elif command -v screenfetch &> /dev/null; then
        screenfetch; echo ''
    else
        echo "=== $(whoami)@$(hostname) ==="
        echo "Distro: $(cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2 | tr -d '\"')"
        echo "Kernel: $(uname -r)"
        echo "Shell: $SHELL"
        echo ""
    fi
}

# -----------------------------------------------------------------------------
# SEÇÃO 5: PROMPT PERSONALIZADO
# -----------------------------------------------------------------------------

# Função para determinar se estamos em Git repo
parse_git_branch() {
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}

# Função para determinar se Git repo tem modificações
parse_git_dirty() {
    if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
        echo "*"
    fi
}

# Cores para o prompt (sem escape codes hardcoded)
if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
    # Terminal com suporte a cores
    color_reset='\[\033[0m\]'
    color_user='\[\033[01;32m\]'    # Verde
    color_host='\[\033[01;36m\]'    # Ciano
    color_path='\[\033[01;34m\]'    # Azul
    color_git='\[\033[01;33m\]'     # Amarelo
    color_dirty='\[\033[01;31m\]'   # Vermelho
    color_prompt='\[\033[01;35m\]'  # Magenta
else
    # Terminal sem cores
    color_reset=''
    color_user=''
    color_host=''
    color_path=''
    color_git=''
    color_dirty=''
    color_prompt=''
fi

# Configurar PS1
set_prompt() {
    local user_part="${color_user}\u${color_reset}"
    local arroba="${color_host}@${color_reset}"
    local host_part="${color_git}\h${color_reset}"
    local path_part="${color_path}\w${color_reset}"
    local git_part=""
    
    if git branch &>/dev/null; then
        git_part="${color_git}$(parse_git_branch)${color_dirty}$(parse_git_dirty)${color_reset}"
    fi
    
    local prompt_char="${color_prompt}\$${color_reset}"
    
    # PS1 final
    PS1="[${user_part}${arroba}${host_part}] ${path_part}${git_part}\n${prompt_char} "
}

PROMPT_COMMAND=set_prompt

# PS2 para comandos multi-linha
PS2='> '

# -----------------------------------------------------------------------------
# SEÇÃO 6: COMPLETION E AUTO-SUGESTÕES
# -----------------------------------------------------------------------------

# Completions do sistema
if [ -f /usr/share/bash-completion/bash_completion ]; then
    source /usr/share/bash-completion/bash_completion
elif [ -f /etc/bash_completion ]; then
    source /etc/bash_completion
fi

# Completions específicas
#if command -v kubectl &> /dev/null; then
#    source <(kubectl completion bash)
#fi

#if command -v helm &> /dev/null; then
#    source <(helm completion bash)
#fi

if command -v docker &> /dev/null; then
    source /usr/share/bash-completion/completions/docker
fi

# Auto-sugestões (fish-like) se disponível
if [ -f /usr/share/bash-completion/completions/git ]; then
    source /usr/share/bash-completion/completions/git
fi

# -----------------------------------------------------------------------------
# SEÇÃO 7: CONFIGURAÇÕES ESPECÍFICAS DO ARCH
# -----------------------------------------------------------------------------

# Configuração específica do Arch
export ARCHFLAGS="-march=x86-64 -mtune=generic -O2 -pipe -fno-plt"

# GPG
export GPG_TTY=$(tty)

# SSH agent (se necessário)
if ! pgrep -u "$USER" ssh-agent > /dev/null; then
    ssh-agent -t 1h > "$XDG_RUNTIME_DIR/ssh-agent.env"
fi
if [[ ! -f "$SSH_AUTH_SOCK" ]]; then
    source "$XDG_RUNTIME_DIR/ssh-agent.env" >/dev/null
fi

# -----------------------------------------------------------------------------
# SEÇÃO 8: MENSAGES DE BOAS-VINDAS E ÚTEIS
# -----------------------------------------------------------------------------

# Mostrar mensagem de boas-vindas apenas no primeiro terminal
if [ -z "$BASHRC_FIRST_RUN" ]; then
    export BASHRC_FIRST_RUN=1
    
    echo "=== Arch Linux Bash Config ==="
    echo "Usuário: $(whoami)"
    echo "Host: $(hostnamectl hostname)"
    echo "Data: $(date '+%d/%m/%Y %H:%M:%S')"
    echo "Terminal: $TERM"
    echo ""
    
    # Verificar atualizações (apenas uma vez por dia)
    UPDATE_CHECK_FILE="$HOME/.last_update_check"
    if [[ ! -f "$UPDATE_CHECK_FILE" || $(find "$UPDATE_CHECK_FILE" -mtime +0) ]]; then
        if checkupdates &>/dev/null; then
            echo "📦 Atualizações disponíveis! Use 'update' para atualizar."
        fi
        touch "$UPDATE_CHECK_FILE"
    fi
    
    # Mostrar espaço em disco
    echo "💾 Espaço em disco:"
    df --human-readable --print-type --exclude-type=tmpfs --exclude-type=devtmpfs --exclude-type=efivarfs
    #df -h / /home 2>/dev/null | tail -n +2
    
    echo ""
    echo "Comandos úteis: 'cls' para limpar, 'mkcd' para criar dir, 'extract' para extrair"
    echo "================================================================================"
fi

# -----------------------------------------------------------------------------
# SEÇÃO 9: CONFIGURAÇÕES FINAIS
# -----------------------------------------------------------------------------

# Configurar título da janela do terminal
case "$TERM" in
    xterm*|rxvt*|alacritty*|kitty*)
        PROMPT_COMMAND="$PROMPT_COMMAND; echo -ne '\033]0;${USER}@${HOSTNAME%%.*}:${PWD/#$HOME/\~}\007'"
        ;;
esac

# Desabilitar Ctrl+S (freeze screen) para permitir pesquisa incremental
stty -ixon

unset -f fastfetch

# Salva o histórico ao sair / versão simples - trap captura o sinal de saída
# trap 'history -a' EXIT
# Versão completa
trap 'history -a; history -c; history -r' EXIT

# Finalização
echo "Config bash carregada com sucesso às $(date '+%H:%M:%S')"

