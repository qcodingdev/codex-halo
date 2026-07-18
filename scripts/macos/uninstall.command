#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HALO_DIR="$HOME/.codex-halo"
HOOKS_FILE="$HOME/.codex/hooks.json"
MANAGER="$HALO_DIR/manage-hooks.js"
[[ -f "$MANAGER" ]] || MANAGER="$SCRIPT_DIR/support/manage-hooks.js"
APP_DEST="$HOME/Applications/Codex Halo.app"
SETTINGS_DIR="$HOME/Library/Application Support/Codex Halo"

green=$'\033[0;32m'
yellow=$'\033[1;33m'
red=$'\033[0;31m'
reset=$'\033[0m'
pass() { printf "%s[PASS]%s %s\n" "$green" "$reset" "$1"; }
warn() { printf "%s[WARN]%s %s\n" "$yellow" "$reset" "$1"; }
fail() { printf "%s[FAIL]%s %s\n" "$red" "$reset" "$1" >&2; exit 1; }

printf "Codex Halo — macOS uninstaller\n\n"

if [[ -f "$HOOKS_FILE" ]]; then
  [[ -f "$MANAGER" ]] || fail "Hook manager is missing; stopping before removing the app."
  backup="$HOOKS_FILE.backup.$(date +%Y%m%d-%H%M%S)"
  cp -p "$HOOKS_FILE" "$backup"
  if ! count="$(/usr/bin/osascript -l JavaScript "$MANAGER" uninstall "$HOOKS_FILE" 2>&1)"; then
    fail "Could not safely remove Halo hooks: $count"
  fi
  [[ "$count" == "0" ]] || fail "Halo hook removal was incomplete."
  pass "Removed only Codex Halo hooks; other hooks were preserved"
fi

/usr/bin/pkill -x codex-halo-lite 2>/dev/null || true
pass "Stopped Codex Halo"

for plist in \
  "$HOME/Library/LaunchAgents/Codex Halo.plist" \
  "$HOME/Library/LaunchAgents/codex-halo-lite.plist" \
  "$HOME/Library/LaunchAgents/com.codex-halo.plist"; do
  if [[ -f "$plist" ]]; then
    /bin/launchctl bootout "gui/$(id -u)" "$plist" 2>/dev/null || true
    /bin/rm -f "$plist"
  fi
done
pass "Removed Halo login items"

[[ ! -d "$APP_DEST" ]] || /bin/rm -rf "$APP_DEST"
pass "Removed $APP_DEST"

if [[ "${1:-}" == "--purge" ]]; then
  /bin/rm -rf "$HALO_DIR" "$SETTINGS_DIR"
  pass "Removed settings, state, and logs"
else
  /bin/rm -f "$HALO_DIR/codex-halo-hook.sh" "$HALO_DIR/manage-hooks.js" "$HALO_DIR/state.json"
  warn "Preferences and logs were kept. Re-run with --purge to delete them."
fi

printf "\nUninstall complete. Codex and all non-Halo hooks were left untouched.\n"
