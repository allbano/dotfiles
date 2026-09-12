#!/usr/bin/env bash

set -Eeuo pipefail

readonly REPOSITORY_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
readonly BASH_FUNCTIONS="${REPOSITORY_ROOT}/bash/bash_functions"
readonly MOCK_BIN="${REPOSITORY_ROOT}/bash/tests/fixtures/bin"
readonly TEST_ROOT="$(mktemp -d)"
readonly MOCK_LOG="${TEST_ROOT}/fzf.log"

readonly DEFAULT_CMDSH_FILE="${TEST_ROOT}/cmdsh_curated.txt"

extract_function() {
    local file="$1"
    local func="$2"
    awk -v name="$func" '
        $0 ~ "^[[:space:]]*" name "\\(\\)[[:space:]]*\\{" { found=1 }
        found { print }
        found && /^[[:space:]]*\}[[:space:]]*$/ { exit }
    ' "$file"
}

run_search() {
    env \
        PATH="${MOCK_BIN}:${PATH}" \
        CMDSH_FILE="${CMDSH_FILE-$DEFAULT_CMDSH_FILE}" \
        MOCK_LOG="$MOCK_LOG" \
        bash -c '
            source /dev/stdin
            _cmdsh_fzf_search
            rc=$?
            printf "READLINE_LINE=%s\n" "$READLINE_LINE"
            printf "READLINE_POINT=%s\n" "$READLINE_POINT"
            exit $rc
        ' bash <<< "$(extract_function "$BASH_FUNCTIONS" "_cmdsh_fzf_search")"
}

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

cleanup() {
    rm -rf -- "$TEST_ROOT"
}
trap cleanup EXIT

: >"$MOCK_LOG"

# Prepara arquivo curado com comandos variados para cobrir edge cases.
printf '%s\n' \
    'ls -la' \
    'echo "comando com    espaços e\ttabs"' \
    '123 inicia com número' \
    'printf "%s\n" "olá 🌍 mundo"' \
    'rm -rf /nao_execute' \
    >"$DEFAULT_CMDSH_FILE"

# --- Teste 1: seleção popula READLINE_LINE e READLINE_POINT ------------------
output=$(MOCK_FZF_LINE=4 run_search)
if [[ "$output" != *"READLINE_LINE=printf \"%s\\n\" \"olá 🌍 mundo\""* ]]; then
    fail "seleção não popula READLINE_LINE corretamente: $output"
fi
if [[ "$output" != *"READLINE_POINT=27"* ]]; then
    fail "READLINE_POINT não aponta para o final do comando selecionado: $output"
fi

# --- Teste 2: cancelamento (Esc) preserva READLINE_LINE ----------------------
output=$(READLINE_LINE="ja digitado" READLINE_POINT=11 MOCK_FZF_LINE= run_search)
if [[ "$output" != *"READLINE_LINE=ja digitado"* ]]; then
    fail "cancelamento do fzf não preservou READLINE_LINE: $output"
fi
if [[ "$output" != *"READLINE_POINT=11"* ]]; then
    fail "cancelamento do fzf não preservou READLINE_POINT: $output"
fi

# --- Teste 3: comando com espaços, tabs e número no início -------------------
output=$(MOCK_FZF_LINE=2 run_search)
if [[ "$output" != *"READLINE_LINE=echo \"comando com    espaços e\\ttabs\""* ]]; then
    fail "comando com espaços/tabs não foi preservado: $output"
fi

output=$(MOCK_FZF_LINE=3 run_search)
if [[ "$output" != *"READLINE_LINE=123 inicia com número"* ]]; then
    fail "comando iniciado com número não foi preservado: $output"
fi

# --- Teste 4: arquivo ausente gera mensagem clara e retorna erro -------------
output=$(CMDSH_FILE="${TEST_ROOT}/inexistente" MOCK_FZF_LINE=3 run_search 2>&1) && rc=$? || rc=$?
if [[ $rc -eq 0 ]]; then
    fail "arquivo ausente deveria retornar erro"
fi
if [[ "$output" != *"Arquivo não encontrado"* ]]; then
    fail "mensagem de arquivo ausente não foi emitida: $output"
fi

# --- Teste 5: CMDSH_FILE vazio gera mensagem clara e retorna erro ------------
output=$(CMDSH_FILE="" MOCK_FZF_LINE=3 run_search 2>&1) && rc=$? || rc=$?
if [[ $rc -eq 0 ]]; then
    fail "CMDSH_FILE vazio deveria retornar erro"
fi
if [[ "$output" != *"CMDSH_FILE não está definido"* ]]; then
    fail "mensagem de CMDSH_FILE não definido não foi emitida: $output"
fi

# --- Teste 6: variáveis Readline ausentes não quebram o shell ----------------
output=$(
    env -i PATH="${MOCK_BIN}:${PATH}" HOME="$TEST_ROOT" CMDSH_FILE="$DEFAULT_CMDSH_FILE" MOCK_LOG="$MOCK_LOG" MOCK_FZF_LINE=1 \
        bash -c '
            source /dev/stdin
            _cmdsh_fzf_search
            printf "READLINE_LINE=%s\n" "${READLINE_LINE-}"
            printf "READLINE_POINT=%s\n" "${READLINE_POINT-}"
        ' bash <<< "$(extract_function "$BASH_FUNCTIONS" "_cmdsh_fzf_search")"
)
if [[ "$output" != *"READLINE_LINE=ls -la"* ]]; then
    fail "variáveis Readline ausentes quebraram a função: $output"
fi

# --- Teste 7: fzf recebe a query atual de READLINE_LINE ----------------------
output=$(READLINE_LINE="ls" MOCK_FZF_LINE=2 run_search)
if ! grep -Fq -- '--query=ls' "$MOCK_LOG"; then
    fail "fzf não recebeu a query de READLINE_LINE"
fi

printf 'PASS: _cmdsh_fzf_search\n'
