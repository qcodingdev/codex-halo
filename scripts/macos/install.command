#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="Codex Halo.app"
APP_SOURCE="$SCRIPT_DIR/$APP_NAME"
INSTALL_DIR="$HOME/Applications"
APP_DEST="$INSTALL_DIR/$APP_NAME"
APP_BINARY="$APP_SOURCE/Contents/MacOS/codex-halo-lite"
HALO_DIR="$HOME/.codex-halo"
CODEX_DIR="$HOME/.codex"
HOOKS_FILE="$CODEX_DIR/hooks.json"
HOOK_SOURCE="$SCRIPT_DIR/hooks/macos/codex-halo-hook.sh"
HOOK_DEST="$HALO_DIR/codex-halo-hook.sh"
MANAGER_SOURCE="$SCRIPT_DIR/support/manage-hooks.js"
MANAGER_DEST="$HALO_DIR/manage-hooks.js"

green=$'\033[0;32m'
yellow=$'\033[1;33m'
red=$'\033[0;31m'
reset=$'\033[0m'
pass() { printf "%s[PASS]%s %s\n" "$green" "$reset" "$1"; }
warn() { printf "%s[WARN]%s %s\n" "$yellow" "$reset" "$1"; }
fail() { printf "%s[FAIL]%s %s\n" "$red" "$reset" "$1" >&2; exit 1; }

printf "Codex Halo — macOS installer\n\n"
[[ "$(uname -s)" == "Darwin" ]] || fail "This installer only supports macOS."
arch="$(uname -m)"
printf "System: macOS (%s)\n" "$arch"

[[ -d "$APP_SOURCE" ]] || fail "$APP_NAME is missing from the extracted release."
[[ -x "$APP_BINARY" ]] || fail "The application bundle is incomplete."
[[ -f "$HOOK_SOURCE" ]] || fail "The Codex hook adapter is missing."
[[ -f "$MANAGER_SOURCE" ]] || fail "The safe hook configuration manager is missing."
if ! lipo -archs "$APP_BINARY" 2>/dev/null | tr ' ' '\n' | grep -qx "$arch"; then
  fail "The application does not contain the required $arch architecture."
fi
pass "Application bundle contains $arch"

mkdir -p "$INSTALL_DIR" "$HALO_DIR" "$CODEX_DIR"
cp -p "$HOOK_SOURCE" "$HOOK_DEST"
cp -p "$MANAGER_SOURCE" "$MANAGER_DEST"
chmod 700 "$HOOK_DEST"
chmod 600 "$MANAGER_DEST"

if [[ -f "$HOOKS_FILE" ]]; then
  backup="$HOOKS_FILE.backup.$(date +%Y%m%d-%H%M%S)"
  cp -p "$HOOKS_FILE" "$backup"
  pass "Backed up hooks.json to $(basename "$backup")"
fi

hook_command="/bin/bash \"$HOOK_DEST\""
if ! count="$(/usr/bin/osascript -l JavaScript "$MANAGER_DEST" install "$HOOKS_FILE" "$hook_command" 2>&1)"; then
  fail "Codex hooks.json is not safe to modify: $count"
fi
[[ "$count" == "5" ]] || fail "Expected 5 Halo lifecycle hooks, found $count."
pass "Installed 5 idempotent Codex lifecycle hooks"

if [[ -d "$APP_DEST" ]]; then
  /usr/bin/pkill -x codex-halo-lite 2>/dev/null || true
  /bin/rm -rf "$APP_DEST"
fi
/usr/bin/ditto "$APP_SOURCE" "$APP_DEST"
pass "Installed application to $APP_DEST"

/usr/bin/open "$APP_DEST" || warn "The app could not be launched automatically."

printf "\nInstallation complete.\n"
printf "1. On first launch, right-click Codex Halo.app and choose Open.\n"
printf "2. In Codex, open /hooks and review/trust the Halo command hooks.\n"
printf "3. Use the menu-bar icon → Demo Mode for the 8-second preview.\n"
printf "\nState data: %s\n" "$HALO_DIR"
