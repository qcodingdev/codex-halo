#!/bin/bash
set -u

HALO_DIR="$HOME/.codex-halo"
APP_PATH="$HOME/Applications/Codex Halo.app"
APP_BINARY="$APP_PATH/Contents/MacOS/codex-halo-lite"
CONFIG_FILE="$HOME/.codex/config.toml"
LEGACY_HOOKS_FILE="$HOME/.codex/hooks.json"
MANAGER="$HALO_DIR/manage-hooks.js"
PASS=0
FAIL=0

pass() { printf "\033[0;32m[PASS]\033[0m %s\n" "$1"; PASS=$((PASS + 1)); }
fail() { printf "\033[0;31m[FAIL]\033[0m %s — %s\n" "$1" "$2"; FAIL=$((FAIL + 1)); }
warn() { printf "\033[1;33m[WARN]\033[0m %s\n" "$1"; }

printf "Codex Halo — installation verification\n\n"

if [[ -x "$APP_BINARY" ]]; then
  pass "Application installed"
  arches="$(lipo -archs "$APP_BINARY" 2>/dev/null || true)"
  [[ "$arches" == *"x86_64"* ]] && [[ "$arches" == *"arm64"* ]] \
    && pass "Universal binary contains x86_64 and arm64" \
    || fail "Application is not Universal" "Reinstall the Universal release"
else
  fail "Application is missing" "Run Install Codex Halo.command"
fi

if [[ -d "$HALO_DIR" ]] && probe="$(mktemp "$HALO_DIR/.write-test.XXXXXX" 2>/dev/null)"; then
  /bin/rm -f "$probe"
  pass "State directory is writable"
else
  fail "State directory is not writable" "Check $HALO_DIR permissions"
fi

[[ -x "$HALO_DIR/codex-halo-hook.sh" ]] \
  && pass "Hook adapter installed" \
  || fail "Hook adapter missing" "Re-run the installer"

if [[ -f "$CONFIG_FILE" ]] && [[ -f "$MANAGER" ]]; then
  count="$(/usr/bin/osascript -l JavaScript "$MANAGER" verify "$CONFIG_FILE" 2>/dev/null || printf invalid)"
  [[ "$count" == "5" ]] \
    && pass "Exactly 5 Codex Halo hooks installed in config.toml (no duplicates)" \
    || fail "Codex Halo hook configuration is invalid" "Re-run the installer; found $count handlers"
else
  fail "Codex hook configuration missing" "Re-run the installer"
fi

if [[ -f "$LEGACY_HOOKS_FILE" ]] && [[ -f "$MANAGER" ]]; then
  legacy_count="$(/usr/bin/osascript -l JavaScript "$MANAGER" verify "$LEGACY_HOOKS_FILE" 2>/dev/null || printf invalid)"
  [[ "$legacy_count" == "0" ]] \
    && pass "No legacy Halo hooks remain in hooks.json" \
    || fail "Legacy Halo hooks are still present" "Re-run the installer; found $legacy_count handlers"
fi

test_script="$(cd "$(dirname "$0")" && pwd)/Test State.sh"
[[ -x "$test_script" ]] || test_script="$(cd "$(dirname "$0")" && pwd)/test-state.sh"
if [[ -x "$test_script" ]] && "$test_script" idle >/dev/null 2>&1; then
  pass "Atomic state test succeeded"
else
  fail "State test failed" "Check the extracted release and directory permissions"
fi

if /usr/bin/pgrep -x codex-halo-lite >/dev/null 2>&1; then
  pass "Codex Halo is running; Demo Mode is available from the menu bar"
else
  warn "Codex Halo is not running; open the app before testing Demo Mode"
fi

settings="$HOME/Library/Application Support/Codex Halo/settings.json"
if [[ -f "$settings" ]] && /usr/bin/plutil -extract startAtLogin raw "$settings" >/dev/null 2>&1; then
  desired="$(/usr/bin/plutil -extract startAtLogin raw "$settings")"
  login_item="$HOME/Library/LaunchAgents/Codex Halo.plist"
  actual="false"
  [[ -f "$login_item" ]] && actual="true"
  if [[ "$desired" != "$actual" ]]; then
    fail "Start at Login setting is out of sync" "Toggle it off and on from the tray"
  else
    pass "Start at Login configuration matches settings"
  fi
else
  warn "Start at Login has not been configured yet"
fi

printf "\nResults: %d passed, %d failed\n" "$PASS" "$FAIL"
[[ "$FAIL" -eq 0 ]]
