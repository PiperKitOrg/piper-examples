#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

run_pair() {
  "$ROOT/playground/run.sh" "$1" "$2"
}

main() {
  ensure_stack
  # Six supported cross-dialect cells only (same-engine pairs are rejected by Piper).
  run_pair "$EMPLOYEES_DATASET" "$POSTGRES_TARGET"
  run_pair "$EMPLOYEES_DATASET" "$MONGO_TARGET"
  run_pair "$PAGILA_DATASET" "$MYSQL_TARGET"
  run_pair "$PAGILA_DATASET" "$MONGO_TARGET"
  run_pair "$SAMPLE_DATASET" "$MYSQL_TARGET"
  run_pair "$SAMPLE_DATASET" "$POSTGRES_TARGET"
  printf 'All six cross-dialect cells passed.\n'
}

main "$@"
