#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

usage() {
  printf 'Usage: ./playground/load.sh <employees|pagila|sample>\n' >&2
}

load_employees() {
  clear_source "$EMPLOYEES_DATASET"
  compose exec -T mysql bash -lc \
    "cd /datasets/mysql && mysql -uroot -p${MYSQL_ROOT_PASSWORD} < employees.sql"
}

load_pagila() {
  recreate_postgres_database "$PAGILA_SOURCE_DB"
  compose exec -T postgres psql -v ON_ERROR_STOP=1 -U "$PG_USER" -d "$PAGILA_SOURCE_DB" \
    -f /datasets/postgres/pagila-schema.sql
  compose exec -T postgres psql -v ON_ERROR_STOP=1 -U "$PG_USER" -d "$PAGILA_SOURCE_DB" \
    -f /datasets/postgres/pagila-data.sql
}

load_sample() {
  clear_source "$SAMPLE_DATASET"
  compose exec -T mongo mongosh --quiet \
    -u "$APP_USER" -p "$APP_PASSWORD" --authenticationDatabase "$MONGO_AUTH_DB" \
    --file /datasets/import-sample.js
}

report_loaded() {
  local count
  count="$(count_table "$(source_engine "$1")" "$(source_database "$1")" "$(probe_table "$1")" | tail -n 1)"
  printf 'Loaded %s. %s rows in %s.\n' "$1" "$(digits_only "$count")" "$(probe_table "$1")"
}

main() {
  [[ $# -eq 1 ]] || { usage; return 1; }
  require_dataset "$1"
  ensure_stack
  case "$1" in
    "$EMPLOYEES_DATASET") load_employees ;;
    "$PAGILA_DATASET") load_pagila ;;
    "$SAMPLE_DATASET") load_sample ;;
  esac
  report_loaded "$1"
}

main "$@"
