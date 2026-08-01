#!/usr/bin/env bash

set -Eeuo pipefail

readonly REPOSITORY_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
readonly HELPER="${REPOSITORY_ROOT}/scripts/toggle-terminal-transparency"
TEST_ROOT="$(mktemp -d)"
readonly TEST_ROOT
readonly MOCK_BIN="${REPOSITORY_ROOT}/tmux/tests/fixtures/bin"
readonly MOCK_STATE="${TEST_ROOT}/state"
readonly MOCK_ALACRITTY_OPACITY="${TEST_ROOT}/alacritty-opacity"
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
: >"$MOCK_LOG"

run_helper() {
    env \
        PATH="${MOCK_BIN}:${PATH}" \
        HOME="$TEST_ROOT" \
        TERMINAL_TRANSPARENCY_STATE_DIR="$MOCK_STATE" \
        MOCK_LOG="$MOCK_LOG" \
        MOCK_ALACRITTY_OPACITY="$MOCK_ALACRITTY_OPACITY" \
        "$HELPER" "$@"
}

kitty_output=$(KITTY_LISTEN_ON='unix:/tmp/mock-kitty' run_helper toggle xterm-kitty)
assert_contains "$kitty_output" 'Kitty: transparência alternada'
assert_file_contains "$MOCK_LOG" 'set-background-opacity --toggle 1.0'

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
assert_contains "$kitty_output" 'Kitty: transparência alternada'
assert_file_contains "$MOCK_LOG" 'unix:/tmp/mock-kitty-from-client'

alacritty_output=$(ALACRITTY_SOCKET='/tmp/mock-alacritty' ALACRITTY_WINDOW_ID=1 \
    run_helper toggle alacritty)
assert_contains "$alacritty_output" 'Alacritty: opaco 1.0'
assert_file_contains "$MOCK_ALACRITTY_OPACITY" '1.0'

alacritty_output=$(ALACRITTY_SOCKET='/tmp/mock-alacritty' ALACRITTY_WINDOW_ID=1 \
    run_helper toggle alacritty)
assert_contains "$alacritty_output" 'Alacritty: transparência 0.8'
assert_file_contains "$MOCK_ALACRITTY_OPACITY" '0.8'

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
