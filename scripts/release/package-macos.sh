#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
VERSION="${1:-0.1.7}"
APP_SOURCE="$ROOT/src-tauri/target/universal-apple-darwin/release/bundle/macos/Codex Halo.app"
OUTPUT="$ROOT/dist/release"
STAGE="$OUTPUT/macos"
ZIP="$OUTPUT/Codex-Halo-macOS-Universal-v${VERSION}.zip"

cd "$ROOT"
printf "[1/4] Building the signed-resource-complete Tauri app bundle...\n"
pnpm tauri build --bundles app --target universal-apple-darwin

binary="$APP_SOURCE/Contents/MacOS/codex-halo-lite"
[[ -x "$binary" ]] || { printf "App binary is missing: %s\n" "$binary" >&2; exit 1; }
arches="$(lipo -archs "$binary")"
[[ "$arches" == *"x86_64"* && "$arches" == *"arm64"* ]] || {
  printf "Expected Universal binary, found: %s\n" "$arches" >&2
  exit 1
}
printf "[2/4] Universal binary verified: %s\n" "$arches"

/bin/rm -rf "$STAGE"
/bin/mkdir -p "$STAGE/hooks/macos" "$STAGE/support"
/usr/bin/ditto "$APP_SOURCE" "$STAGE/Codex Halo.app"
/bin/cp "$ROOT/scripts/macos/install.command" "$STAGE/Install Codex Halo.command"
/bin/cp "$ROOT/scripts/macos/uninstall.command" "$STAGE/Uninstall Codex Halo.command"
/bin/cp "$ROOT/scripts/macos/verify.command" "$STAGE/Verify Codex Halo.command"
/bin/cp "$ROOT/scripts/macos/test-state.sh" "$STAGE/Test State.sh"
/bin/cp "$ROOT/hooks/macos/codex-halo-hook.sh" "$STAGE/hooks/macos/"
/bin/cp "$ROOT/scripts/macos/manage-hooks.js" "$STAGE/support/"
/bin/cp "$ROOT/docs/RELEASE_README.txt" "$STAGE/README.txt"
/bin/chmod +x "$STAGE/"*.command "$STAGE/Test State.sh" "$STAGE/hooks/macos/codex-halo-hook.sh"
printf "[3/4] Self-contained installer staged\n"

/bin/rm -f "$ZIP"
(
  cd "$STAGE"
  COPYFILE_DISABLE=1 /usr/bin/zip -qry "$ZIP" .
)
printf "[4/4] Created %s (%s)\n" "$ZIP" "$(du -h "$ZIP" | awk '{print $1}')"
