#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

usage() {
  cat <<'EOF' >&2
Usage:
  ./playground/commands.sh <employees|pagila|sample> <mysql|postgres|mongo>
  ./playground/commands.sh sample <mysql|postgres|mongo> <sample_database>
EOF
}

chosen_source_database() {
  if [[ -z "${2:-}" ]]; then
    source_database "$1"
    return 0
  fi
  [[ "$1" == "$SAMPLE_DATASET" ]] || { printf 'A database name is only for %s.\n' "$SAMPLE_DATASET" >&2; return 1; }
  require_sample_database "$2"
  printf '%s\n' "$2"
}

cell_label() {
  if [[ "$2" == "$(source_database "$1")" ]]; then
    printf '%s\n' "$1"
    return 0
  fi
  printf '%s\n' "$2"
}

write_cell_env() {
  local dir="$1" source_url="$2" target_url="$3"
  ensure_cell_piper "$dir"
  printf 'PIPER_SOURCE_URL=%s\nPIPER_TARGET_URL=%s\n' "$source_url" "$target_url" > "$dir/.env"
}

clear_line() {
  if [[ "$2" == "$(source_database "$1")" ]]; then
    printf './playground/clear.sh target %s %s\n' "$1" "$3"
    return 0
  fi
  printf './playground/clear.sh target %s %s %s\n' "$1" "$3" "$2"
}

print_commands() {
  local dataset="$1" target="$2" source_db="$3" target_db="$4" relative="$5"
  cat <<EOF
# ${dataset} -> ${target}
# Source ${source_db} on $(source_engine "$dataset"). Target database ${target_db}.
# Run from the piper-example directory. The binary is bin/piper.

$(clear_line "$dataset" "$source_db" "$target")
cd ${relative}
rm -rf .piper
set -a
source .env
set +a
./piper $(inspect_command "$dataset")
./piper $(plan_command "$dataset" "$target")
./piper --yes execute
cd ../..
EOF
}

main() {
  [[ $# -eq 2 || $# -eq 3 ]] || { usage; return 1; }
  require_cross_dialect "$1" "$2"
  local source_db target_db label relative dir
  source_db="$(chosen_source_database "$1" "${3:-}")"
  target_db="$(resolved_target_database "$(source_engine "$1")" "$source_db" "$2")"
  label="$(cell_label "$1" "$source_db")"
  relative="runs/${label}-to-${2}"
  dir="$(cell_dir "$label" "$2")"
  write_cell_env "$dir" \
    "$(connection_url "$(source_engine "$1")" "$source_db")" \
    "$(connection_url "$2" "$target_db")"
  if [[ ! -x "$ROOT/bin/piper" ]]; then
    printf 'bin/piper is not there yet. Copy the binary to bin/piper and chmod +x bin/piper.\n' >&2
  fi
  printf 'Wrote %s/.env\n' "$relative" >&2
  print_commands "$1" "$2" "$source_db" "$target_db" "$relative"
}

main "$@"
