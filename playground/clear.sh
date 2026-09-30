#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

usage() {
  cat <<'EOF'
Usage:
  ./playground/clear.sh source <employees|pagila>
  ./playground/clear.sh target <employees|pagila> <mysql|postgres|mongo>
EOF
}

clear_one_source() {
  clear_source "$1"
  printf 'Dropped source %s. Load it again with ./playground/load.sh %s\n' "$1" "$1"
}

clear_one_target() {
  local database
  database="$(target_database "$1" "$2")"
  clear_target "$1" "$2"
  printf 'Cleared target %s for %s -> %s.\n' "$database" "$1" "$2"
}

main() {
  case "${1:-}" in
    source)
      [[ $# -eq 2 ]] || { usage >&2; return 1; }
      require_dataset "$2"
      ensure_stack
      clear_one_source "$2"
      ;;
    target)
      [[ $# -eq 3 ]] || { usage >&2; return 1; }
      require_dataset "$2"
      require_target "$3"
      ensure_stack
      clear_one_target "$2" "$3"
      ;;
    *)
      usage >&2
      return 1
      ;;
  esac
}

main "$@"
