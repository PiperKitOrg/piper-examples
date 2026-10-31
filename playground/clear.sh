#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

usage() {
  cat <<'EOF'
Usage:
  ./playground/clear.sh source <employees|pagila|sample>
  ./playground/clear.sh target <employees|pagila|sample> <mysql|postgres|mongo> [sample_database]
EOF
}

clear_one_source() {
  clear_source "$1"
  printf 'Dropped source %s. Load it again with ./playground/load.sh %s\n' "$1" "$1"
}

clear_one_target() {
  local database="$3"
  clear_named_target "$2" "$database"
  printf 'Cleared target %s for %s -> %s.\n' "$database" "$1" "$2"
}

target_database_for_clear() {
  if [[ $# -eq 4 ]]; then
    [[ "$2" == "$SAMPLE_DATASET" ]] || { printf 'A database name is only for %s.\n' "$SAMPLE_DATASET" >&2; return 1; }
    require_sample_database "$4"
    resolved_target_database "$(source_engine "$2")" "$4" "$3"
    return 0
  fi
  target_database "$2" "$3"
}

main() {
  local database=""
  case "${1:-}" in
    source)
      [[ $# -eq 2 ]] || { usage >&2; return 1; }
      require_dataset "$2"
      ensure_stack
      clear_one_source "$2"
      ;;
    target)
      [[ $# -eq 3 || $# -eq 4 ]] || { usage >&2; return 1; }
      require_cross_dialect "$2" "$3"
      database="$(target_database_for_clear "$@")"
      ensure_stack
      clear_one_target "$2" "$3" "$database"
      ;;
    *)
      usage >&2
      return 1
      ;;
  esac
}

main "$@"
