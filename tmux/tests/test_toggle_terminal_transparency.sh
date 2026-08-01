#!/usr/bin/env bash

set -Eeuo pipefail

readonly REPOSITORY_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
readonly HELPER="${REPOSITORY_ROOT}/scripts/toggle-terminal-transparency"
readonly KITTY_PROFILE="${REPOSITORY_ROOT}/scripts/kitty-font-profile"
TEST_ROOT="$(mktemp -d)"
readonly TEST_ROOT
readonly MOCK_BIN="${REPOSITORY_ROOT}/tmux/tests/fixtures/bin"
readonly MOCK_STATE="${TEST_ROOT}/state"
readonly MOCK_ALACRITTY_OPACITY="${TEST_ROOT}/alacritty-opacity"
readonly MOCK_ALACRITTY_CONFIG="${TEST_ROOT}/alacritty.toml"
readonly MOCK_LOG="${TEST_ROOT}/commands.log"
CLIENT_ENV_PID=""

cleanup() {
    if [[ -n "$CLIENT_ENV_PID" ]]; then
        kill "$CLIENT_ENV_PID" 2>/dev/null || true
        wait "$CLIENT_ENV_PID" 2>/dev/null || true
    fi
    rm -rf -- "$TEST_ROOT"
}
trap cleanup EXIT

# O ambiente real pode vir de uma sessão Kitty; os casos abaixo precisam
# controlar explicitamente a presença ou ausência dos sockets.
unset KITTY_LISTEN_ON KITTY_WINDOW_ID KITTY_PID KITTY_PUBLIC_KEY \
    KITTY_INSTALLATION_DIR ALACRITTY_SOCKET ALACRITTY_WINDOW_ID || true

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

mkdir -p "$MOCK_STATE"
printf '0.8\n' >"$MOCK_ALACRITTY_OPACITY"
printf '%s\n' \
    '[window]' \
    '# BEGIN dotfiles terminal-opacity' \
    'opacity = 0.8' \
    '# END dotfiles terminal-opacity' \
    >"$MOCK_ALACRITTY_CONFIG"
: >"$MOCK_LOG"

run_helper() {
    env \
        PATH="${MOCK_BIN}:${PATH}" \
        HOME="$TEST_ROOT" \
        TERMINAL_TRANSPARENCY_STATE_DIR="$MOCK_STATE" \
        TERMINAL_TRANSPARENCY_ALACRITTY_CONFIG="$MOCK_ALACRITTY_CONFIG" \
        MOCK_LOG="$MOCK_LOG" \
        MOCK_ALACRITTY_OPACITY="$MOCK_ALACRITTY_OPACITY" \
        "$HELPER" "$@"
}

kitty_output=$(KITTY_LISTEN_ON='unix:/tmp/mock-kitty' run_helper toggle xterm-kitty)
assert_contains "$kitty_output" 'Kitty: opaco 1.0'
assert_file_contains "$MOCK_LOG" 'set-background-opacity 1.0'
assert_file_contains "${MOCK_STATE}/kitty.conf" 'opacity=1.0'

if run_helper toggle xterm-kitty >/dev/null 2>&1; then
    fail 'kitty without KITTY_LISTEN_ON should fail'
fi

env KITTY_LISTEN_ON='unix:/tmp/mock-kitty-from-client' /usr/bin/sleep 30 &
CLIENT_ENV_PID=$!
kitty_output=$(
    unset KITTY_LISTEN_ON
    run_helper toggle xterm-kitty '' "$CLIENT_ENV_PID"
)
kill "$CLIENT_ENV_PID"
wait "$CLIENT_ENV_PID" 2>/dev/null || true
CLIENT_ENV_PID=""
assert_contains "$kitty_output" 'Kitty: transparência 0.8'
assert_file_contains "$MOCK_LOG" 'unix:/tmp/mock-kitty-from-client'
assert_file_contains "${MOCK_STATE}/kitty.conf" 'opacity=0.8'

kitty_profile_output=$(
    env \
        HOME="$TEST_ROOT" \
        TERMINAL_FONT_STATE_DIR="${TEST_ROOT}/missing-font-state" \
        TERMINAL_TRANSPARENCY_STATE_DIR="$MOCK_STATE" \
        "$KITTY_PROFILE"
)
assert_contains "$kitty_profile_output" 'background_opacity 0.8'

if MOCK_KITTEN_FAIL=1 KITTY_LISTEN_ON='unix:/tmp/mock-kitty' \
    run_helper toggle xterm-kitty >/dev/null 2>&1; then
    fail 'kitty remote control failure should fail'
fi
assert_file_contains "${MOCK_STATE}/kitty.conf" 'opacity=0.8'

alacritty_output=$(ALACRITTY_SOCKET='/tmp/mock-alacritty' ALACRITTY_WINDOW_ID=1 \
    run_helper toggle alacritty)
assert_contains "$alacritty_output" 'Alacritty: opaco 1.0'
assert_file_contains "$MOCK_ALACRITTY_OPACITY" '1.0'
assert_file_contains "$MOCK_ALACRITTY_CONFIG" 'opacity = 1.0'
assert_file_contains "$MOCK_LOG" 'msg --socket /tmp/mock-alacritty get-config --window-id 1'

alacritty_output=$(ALACRITTY_SOCKET='/tmp/mock-alacritty' ALACRITTY_WINDOW_ID=1 \
    run_helper toggle alacritty)
assert_contains "$alacritty_output" 'Alacritty: transparência 0.8'
assert_file_contains "$MOCK_ALACRITTY_OPACITY" '0.8'
assert_file_contains "$MOCK_ALACRITTY_CONFIG" 'opacity = 0.8'

config_before_failure=$(<"$MOCK_ALACRITTY_CONFIG")
if MOCK_ALACRITTY_FAIL=1 ALACRITTY_SOCKET='/tmp/mock-alacritty' ALACRITTY_WINDOW_ID=1 \
    run_helper toggle alacritty >/dev/null 2>&1; then
    fail 'alacritty IPC failure should fail'
fi
[[ "$(<"$MOCK_ALACRITTY_CONFIG")" == "$config_before_failure" ]] || \
    fail 'alacritty opacity config was not restored after IPC failure'

ghostty_output=$(run_helper toggle xterm-ghostty)
assert_contains "$ghostty_output" 'Ghostty: opaco 1.0'
assert_file_contains "${MOCK_STATE}/ghostty.conf" 'background-opacity = 1.0'

ghostty_output=$(run_helper toggle xterm-ghostty)
assert_contains "$ghostty_output" 'Ghostty: transparência 0.8'
assert_file_contains "${MOCK_STATE}/ghostty.conf" 'background-opacity = 0.8'

ghostty_status=$(run_helper status xterm-ghostty)
assert_contains "$ghostty_status" 'Ghostty: opacidade configurada 0.8'

if MOCK_SYSTEMCTL_FAIL=1 run_helper toggle xterm-ghostty >/dev/null 2>&1; then
    fail 'ghostty reload failure should fail'
fi
assert_file_contains "${MOCK_STATE}/ghostty.conf" 'background-opacity = 0.8'

if run_helper toggle unsupported-terminal >/dev/null 2>&1; then
    fail 'unsupported terminal should fail'
fi

printf 'PASS: toggle-terminal-transparency\n'
