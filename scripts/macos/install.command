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
CONFIG_FILE="$CODEX_DIR/config.toml"
LEGACY_HOOKS_FILE="$CODEX_DIR/hooks.json"
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
[[ -f "$MANAGER_SOURCE" ]] || fail "The safe hook configuration manager is missing."
if ! lipo -archs "$APP_BINARY" 2>/dev/null | tr ' ' '\n' | grep -qx "$arch"; then
  fail "The application does not contain the required $arch architecture."
fi
pass "Application bundle contains $arch"

mkdir -p "$INSTALL_DIR" "$HALO_DIR" "$CODEX_DIR"
cp -p "$MANAGER_SOURCE" "$MANAGER_DEST"
chmod 600 "$MANAGER_DEST"

existing_count="$(/usr/bin/osascript -l JavaScript "$MANAGER_DEST" verify "$CONFIG_FILE")"
if [[ "$existing_count" != "0" && -f "$CONFIG_FILE" ]]; then
  backup="$CONFIG_FILE.backup.$(date +%Y%m%d-%H%M%S)"
  cp -p "$CONFIG_FILE" "$backup"
  pass "Backed up config.toml to $(basename "$backup")"
fi

if [[ "$existing_count" != "0" ]]; then
  if ! count="$(/usr/bin/osascript -l JavaScript "$MANAGER_DEST" uninstall "$CONFIG_FILE" 2>&1)"; then
    fail "Codex config.toml is not safe to modify: $count"
  fi
  [[ "$count" == "0" ]] || fail "Legacy Halo hook removal was incomplete."
  pass "Removed obsolete Halo hooks; desktop lifecycle detection is built in"
fi
/bin/rm -f "$HALO_DIR/codex-halo-hook.sh"

# Migrate an older Codex Halo install away from the pre-config.toml hook file.
if [[ -f "$LEGACY_HOOKS_FILE" ]]; then
  legacy_backup="$LEGACY_HOOKS_FILE.backup.$(date +%Y%m%d-%H%M%S)"
  cp -p "$LEGACY_HOOKS_FILE" "$legacy_backup"
  if ! legacy_count="$(/usr/bin/osascript -l JavaScript "$MANAGER_DEST" uninstall "$LEGACY_HOOKS_FILE" 2>&1)"; then
    fail "Could not safely remove legacy Halo hooks: $legacy_count"
  fi
  [[ "$legacy_count" == "0" ]] || fail "Legacy Halo hook migration was incomplete."
  pass "Removed legacy Halo hooks from hooks.json; other hooks were preserved"
fi

if [[ -d "$APP_DEST" ]]; then
  /usr/bin/pkill -x codex-halo-lite 2>/dev/null || true
  /bin/rm -rf "$APP_DEST"
fi
/usr/bin/ditto "$APP_SOURCE" "$APP_DEST"
pass "Installed application to $APP_DEST"

/usr/bin/open "$APP_DEST" || warn "The app could not be launched automatically."

printf "\nInstallation complete.\n"
printf "1. On first launch, right-click Codex Halo.app and choose Open.\n"
printf "2. Open Codex normally — Halo detects local lifecycle events automatically.\n"
printf "3. Use the menu-bar icon → Demo Mode for the 8-second preview.\n"
printf "\nState data: %s\n" "$HALO_DIR"
