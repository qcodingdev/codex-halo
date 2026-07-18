#!/bin/bash
# Codex Halo lifecycle adapter for macOS.
# Reads only the documented hook_event_name field and writes no prompt/tool data.

set -u

HALO_DIR="$HOME/.codex-halo"
STATE_FILE="$HALO_DIR/state.json"
INPUT="$(/bin/cat 2>/dev/null || true)"
EVENT_TYPE="$(
  /usr/bin/printf '%s' "$INPUT" \
    | /usr/bin/plutil -extract hook_event_name raw -o - -- - 2>/dev/null \
    || true
)"

case "$EVENT_TYPE" in
  UserPromptSubmit|PreToolUse|PostToolUse)
    HALO_STATE="working"
    ;;
  PermissionRequest)
    HALO_STATE="attention"
    ;;
  Stop)
    HALO_STATE="completed"
    ;;
  *)
    exit 0
    ;;
esac

if ! /bin/mkdir -p "$HALO_DIR" 2>/dev/null; then
  [[ "$EVENT_TYPE" == "Stop" ]] && /usr/bin/printf '{}\n'
  exit 0
fi

TIMESTAMP="$(($(date +%s) * 1000))"
PREVIOUS_TIMESTAMP="$(
  /usr/bin/plutil -extract updatedAt raw -o - -- "$STATE_FILE" 2>/dev/null || true
)"
if [[ "$PREVIOUS_TIMESTAMP" =~ ^[0-9]+$ ]] && ((PREVIOUS_TIMESTAMP >= TIMESTAMP)); then
  TIMESTAMP=$((PREVIOUS_TIMESTAMP + 1))
fi
TEMP_FILE="$HALO_DIR/state.json.$$.$RANDOM.tmp"
trap '/bin/rm -f "$TEMP_FILE"' EXIT

if /usr/bin/printf '{"state":"%s","updatedAt":%s,"event":"%s"}\n' \
  "$HALO_STATE" "$TIMESTAMP" "$EVENT_TYPE" >"$TEMP_FILE" \
  && /bin/mv -f "$TEMP_FILE" "$STATE_FILE"; then
  :
fi

# Stop requires valid JSON on stdout. An empty object means "do not continue the turn".
[[ "$EVENT_TYPE" == "Stop" ]] && /usr/bin/printf '{}\n'
exit 0
