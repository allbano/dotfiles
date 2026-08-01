#!/usr/bin/env bash

set -Eeuo pipefail

readonly REPOSITORY_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
readonly HELPER="${REPOSITORY_ROOT}/scripts/change-terminal-font"
readonly TRANSPARENCY_HELPER="${REPOSITORY_ROOT}/scripts/toggle-terminal-transparency"
readonly KITTY_PROFILE="${REPOSITORY_ROOT}/scripts/kitty-font-profile"
readonly TMUX_CONFIG="${REPOSITORY_ROOT}/tmux/.tmux.conf"
readonly TEST_ROOT="$(mktemp -d)"
readonly MOCK_BIN="${REPOSITORY_ROOT}/tmux/tests/fixtures/bin"
readonly FONT_STATE_DIR="${TEST_ROOT}/font-state"
readonly GHOSTTY_STATE_DIR="${TEST_ROOT}/ghostty-state"
readonly ALACRITTY_CONFIG="${TEST_ROOT}/alacritty.toml"
readonly KITTY_CONFIG="${TEST_ROOT}/kitty.conf"
readonly MOCK_LOG="${TEST_ROOT}/commands.log"
readonly MOCK_ALACRITTY_OPACITY="${TEST_ROOT}/alacritty-opacity"

cleanup() {
    rm -rf -- "$TEST_ROOT"
}
trap cleanup EXIT

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

assert_contains() {
    local value="$1"
    local expected="$2"

    [[ "$value" == *"$expected"* ]] || fail "expected '$expected' in '$value'"
}

assert_file_contains() {
    local file="$1"
    local expected="$2"

    grep -Fq -- "$expected" "$file" || fail "expected '$expected' in $file"
}

assert_file_not_contains() {
    local file="$1"
    local unexpected="$2"

    if grep -Fq -- "$unexpected" "$file"; then
        fail "did not expect '$unexpected' in $file"
    fi
}

font_binding=$(grep -F 'change-terminal-font interactive' "$TMUX_CONFIG")
assert_contains "$font_binding" 'bind-key F run-shell -b'
assert_contains "$font_binding" '/usr/bin/tmux display-popup -c #{q:client_name}'
assert_contains "$font_binding" 'interactive #{q:client_termname} #{q:client_name} #{q:client_pid}'
assert_file_not_contains "$TMUX_CONFIG" \
    "bind-key F display-popup"

unset KITTY_LISTEN_ON KITTY_WINDOW_ID KITTY_PID ALACRITTY_SOCKET ALACRITTY_WINDOW_ID || true
mkdir -p "$FONT_STATE_DIR" "$GHOSTTY_STATE_DIR"
: >"$MOCK_LOG"
printf '0.8\n' >"$MOCK_ALACRITTY_OPACITY"
printf 'font_family monospace\n' >"$KITTY_CONFIG"
printf '%s\n' \
    '[general]' \
    '# BEGIN dotfiles terminal-font' \
    '[font]' \
    'size = 12.0' \
    'normal = { family = "CaskaydiaCove Nerd Font", style = "Semilight" }' \
    'bold = { family = "CaskaydiaCove Nerd Font", style = "Semibold" }' \
    'italic = { family = "CaskaydiaCove Nerd Font", style = "Italic" }' \
    '# END dotfiles terminal-font' \
    >"$ALACRITTY_CONFIG"

run_helper() {
    env \
        PATH="${MOCK_BIN}:${PATH}" \
        HOME="$TEST_ROOT" \
        XDG_CONFIG_HOME="$TEST_ROOT/config" \
        TERMINAL_FONT_STATE_DIR="$FONT_STATE_DIR" \
        TERMINAL_FONT_GHOSTTY_STATE_DIR="$GHOSTTY_STATE_DIR" \
        TERMINAL_FONT_ALACRITTY_CONFIG="$ALACRITTY_CONFIG" \
        TERMINAL_FONT_KITTY_CONFIG="$KITTY_CONFIG" \
        MOCK_LOG="$MOCK_LOG" \
        MOCK_ALACRITTY_OPACITY="$MOCK_ALACRITTY_OPACITY" \
        "$HELPER" "$@"
}

ghostty_output=$(run_helper family 'RecMonoCasual Nerd Font' xterm-ghostty)
assert_contains "$ghostty_output" 'Ghostty: fonte RecMonoCasual Nerd Font, 12 pt'
assert_file_contains "${FONT_STATE_DIR}/current.conf" 'family=RecMonoCasual Nerd Font'
assert_file_contains "${GHOSTTY_STATE_DIR}/ghostty.conf" 'background-opacity = 0.8'
assert_file_contains "${GHOSTTY_STATE_DIR}/ghostty.conf" 'font-family = "RecMonoCasual Nerd Font"'

env \
    PATH="${MOCK_BIN}:${PATH}" \
    HOME="$TEST_ROOT" \
    TERMINAL_TRANSPARENCY_STATE_DIR="$GHOSTTY_STATE_DIR" \
    MOCK_LOG="$MOCK_LOG" \
    "$TRANSPARENCY_HELPER" toggle xterm-ghostty >/dev/null
assert_file_contains "${GHOSTTY_STATE_DIR}/ghostty.conf" 'font-family = "RecMonoCasual Nerd Font"'

kitty_output=$(KITTY_LISTEN_ON='unix:/tmp/mock-kitty' run_helper size 14 xterm-kitty)
assert_contains "$kitty_output" 'Kitty: fonte RecMonoCasual Nerd Font, 14 pt'
assert_file_contains "$MOCK_LOG" "load-config $KITTY_CONFIG"
assert_file_contains "$MOCK_LOG" 'set-font-size 14'

kitty_profile_output=$(
    env \
        HOME="$TEST_ROOT" \
        XDG_CONFIG_HOME="$TEST_ROOT/config" \
        TERMINAL_FONT_STATE_DIR="$FONT_STATE_DIR" \
        "$KITTY_PROFILE"
)
assert_contains "$kitty_profile_output" 'font_family RecMonoCasual Nerd Font'
assert_contains "$kitty_profile_output" 'font_size 14'

alacritty_output=$(ALACRITTY_SOCKET='/tmp/mock-alacritty' ALACRITTY_WINDOW_ID=1 \
    run_helper family 'CaskaydiaCove Nerd Font' alacritty)
assert_contains "$alacritty_output" 'Alacritty: fonte CaskaydiaCove Nerd Font, 14 pt'
assert_file_contains "$ALACRITTY_CONFIG" 'normal = { family = "CaskaydiaCove Nerd Font", style = "Regular" }'
assert_file_contains "$MOCK_LOG" 'msg --socket /tmp/mock-alacritty config --window-id 1'
assert_file_contains "$MOCK_LOG" 'font.normal.family="CaskaydiaCove Nerd Font"'

config_before_failure=$(<"$ALACRITTY_CONFIG")
profile_before_failure=$(<"${FONT_STATE_DIR}/current.conf")
if MOCK_ALACRITTY_FAIL=1 ALACRITTY_SOCKET='/tmp/mock-alacritty' ALACRITTY_WINDOW_ID=1 \
    run_helper family 'RecMonoCasual Nerd Font' alacritty >/dev/null 2>&1; then
    fail 'falha simulada do IPC do Alacritty deveria falhar'
fi
[[ "$(<"$ALACRITTY_CONFIG")" == "$config_before_failure" ]] || \
    fail 'configuração do Alacritty não foi restaurada após falha de IPC'
[[ "$(<"${FONT_STATE_DIR}/current.conf")" == "$profile_before_failure" ]] || \
    fail 'perfil central não foi restaurado após falha de IPC'

ghostty_state_before_failure=$(<"${GHOSTTY_STATE_DIR}/ghostty.conf")
profile_before_failure=$(<"${FONT_STATE_DIR}/current.conf")
if MOCK_SYSTEMCTL_FAIL=1 run_helper family 'RecMonoCasual Nerd Font' xterm-ghostty >/dev/null 2>&1; then
    fail 'falha simulada do reload do Ghostty deveria falhar'
fi
[[ "$(<"${GHOSTTY_STATE_DIR}/ghostty.conf")" == "$ghostty_state_before_failure" ]] || \
    fail 'estado do Ghostty não foi restaurado após falha de reload'
[[ "$(<"${FONT_STATE_DIR}/current.conf")" == "$profile_before_failure" ]] || \
    fail 'perfil central não foi restaurado após falha do Ghostty'

status_output=$(run_helper status xterm-ghostty)
assert_contains "$status_output" 'Fonte: CaskaydiaCove Nerd Font, 14 pt (ghostty)'

minimal_path_dir=$(mktemp -d "$TEST_ROOT/minimal-path.XXXXXX")
ln -s -- "$(command -v bash)" "$minimal_path_dir/bash"
restricted_status=$(env \
    PATH="$minimal_path_dir" \
    HOME="$TEST_ROOT" \
    XDG_CONFIG_HOME="$TEST_ROOT/config" \
    TERMINAL_FONT_STATE_DIR="$FONT_STATE_DIR" \
    TERMINAL_FONT_GHOSTTY_STATE_DIR="$GHOSTTY_STATE_DIR" \
    TERMINAL_FONT_ALACRITTY_CONFIG="$ALACRITTY_CONFIG" \
    "$HELPER" status xterm-ghostty)
assert_contains "$restricted_status" 'Fonte: CaskaydiaCove Nerd Font, 14 pt (ghostty)'

alias_output=$(run_helper family 'CaskaydiaCove NF' xterm-ghostty)
assert_contains "$alias_output" 'Ghostty: fonte CaskaydiaCove NF, 14 pt'

interactive_output=$(
    MOCK_FZF_FAMILY='CaskaydiaCove NF' MOCK_FZF_SIZE=13 \
        run_helper interactive xterm-ghostty
)
assert_contains "$interactive_output" 'Ghostty: fonte CaskaydiaCove NF, 13 pt'
assert_file_contains "$MOCK_LOG" 'fzf --no-select-1 --no-exit-0 --layout=reverse --border'
assert_file_not_contains "$MOCK_LOG" '--height='

if run_helper family 'Fonte inexistente para teste' xterm-ghostty >/dev/null 2>&1; then
    fail 'família inexistente deveria falhar'
fi

if run_helper size 5 xterm-ghostty >/dev/null 2>&1; then
    fail 'tamanho fora do intervalo deveria falhar'
fi

printf 'PASS: change-terminal-font\n'
