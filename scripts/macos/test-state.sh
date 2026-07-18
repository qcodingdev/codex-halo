#!/bin/bash
set -euo pipefail

state="${1:-}"
case "$state" in
  idle|working|attention|completed) ;;
  *) printf "Usage: %s idle|working|attention|completed\n" "$0" >&2; exit 1 ;;
esac

halo_dir="$HOME/.codex-halo"
state_file="$halo_dir/state.json"
mkdir -p "$halo_dir"
timestamp="$(($(date +%s) * 1000))"
if [[ -f "$state_file" ]]; then
  previous="$(/usr/bin/plutil -extract updatedAt raw "$state_file" 2>/dev/null || printf 0)"
  [[ "$previous" =~ ^[0-9]+$ ]] || previous=0
  (( timestamp <= previous )) && timestamp=$((previous + 1))
fi
temp_file="$(mktemp "$halo_dir/state.json.XXXXXX")"
trap '/bin/rm -f "$temp_file"' EXIT
printf '{"state":"%s","updatedAt":%s,"event":"ManualTest"}\n' "$state" "$timestamp" > "$temp_file"
/bin/mv -f "$temp_file" "$state_file"
trap - EXIT
printf "[OK] %s → %s\n" "$state" "$state_file"
