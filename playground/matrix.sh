#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

run_pair() {
  "$ROOT/playground/run.sh" "$1" "$2"
}

main() {
  ensure_stack
  run_pair "$EMPLOYEES_DATASET" "$MYSQL_TARGET"
  run_pair "$EMPLOYEES_DATASET" "$POSTGRES_TARGET"
  run_pair "$EMPLOYEES_DATASET" "$MONGO_TARGET"
  run_pair "$PAGILA_DATASET" "$MYSQL_TARGET"
  run_pair "$PAGILA_DATASET" "$POSTGRES_TARGET"
  run_pair "$PAGILA_DATASET" "$MONGO_TARGET"
  printf 'All six cells passed.\n'
}

main "$@"
