#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

usage() {
  printf 'Usage: ./playground/run.sh <employees|pagila|sample> <mysql|postgres|mongo>\n' >&2
}

run_argv() {
  local piper="$1" command_line="$2"
  local args=()
  read -r -a args <<< "$command_line"
  "$piper" "${args[@]}"
}

prepare_cell() {
  local dir="$1" source_url="$2" target_url="$3"
  ensure_cell_piper "$dir"
  printf 'PIPER_SOURCE_URL=%s\nPIPER_TARGET_URL=%s\n' "$source_url" "$target_url" > "$dir/.env"
  rm -rf "$dir/.piper"
}

run_piper() {
  local dir="$1" piper="$2" dataset="$3" target="$4"
  (
    cd "$dir"
    set -a
    # shellcheck disable=SC1091
    source .env
    set +a
    run_argv "$piper" "$(inspect_command "$dataset")"
    run_argv "$piper" "$(plan_command "$dataset" "$target")"
    "$piper" --yes execute
  )
}

run_cell() {
  local dataset="$1" target="$2" dir source_url target_url piper
  dir="$(cell_dir "$dataset" "$target")"
  source_url="$(connection_url "$(source_engine "$dataset")" "$(source_database "$dataset")")"
  target_url="$(connection_url "$target" "$(target_database "$dataset" "$target")")"
  piper="$(piper_bin)"
  prepare_cell "$dir" "$source_url" "$target_url"
  run_piper "$dir" "$piper" "$dataset" "$target"
}

main() {
  [[ $# -eq 2 ]] || { usage; return 1; }
  require_cross_dialect "$1" "$2"
  ensure_stack
  assert_source_loaded "$1"
  clear_target "$1" "$2"
  printf '=== %s -> %s ===\n' "$1" "$2"
  run_cell "$1" "$2"
  "$ROOT/playground/check.sh" "$1" "$2"
}

main "$@"
