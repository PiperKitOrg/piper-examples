#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

usage() {
  printf 'Usage: ./playground/check.sh <employees|pagila> <mysql|postgres|mongo>\n' >&2
}

check_table() {
  local dataset="$1" target="$2" database="$3" table="$4" want="$5" got
  got="$(count_table "$target" "$database" "$table" | tail -n 1)"
  got="$(digits_only "$got")"
  if [[ "$got" == "$want" ]]; then
    printf '%s %s: %s\n' "$dataset" "$table" "$got"
    return 0
  fi
  printf '%s %s: count %s, expected %s\n' "$dataset" "$table" "${got:-empty}" "$want" >&2
  return 1
}

main() {
  [[ $# -eq 2 ]] || { usage; return 1; }
  require_dataset "$1"
  require_target "$2"
  local database failed=0 table want
  database="$(target_database "$1" "$2")"
  while read -r table want; do
    check_table "$1" "$2" "$database" "$table" "$want" || failed=1
  done < <(expected_rows "$1")
  return "$failed"
}

main "$@"
