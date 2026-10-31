#!/usr/bin/env bash
# Shared names for the employees and pagila playground.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  printf 'Source playground/lib.sh from another script.\n' >&2
  exit 1
fi

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

PLAYGROUND_HOST=127.0.0.1
PG_USER=postgres
PG_PASSWORD=piper
PG_PORT=5432
PG_MAINTENANCE_DB=postgres
MYSQL_ROOT_PASSWORD=root
APP_USER=piper
APP_PASSWORD=piper
MYSQL_PORT=3306
MONGO_PORT=27017
MONGO_AUTH_DB=admin

EMPLOYEES_DATASET=employees
PAGILA_DATASET=pagila
SAMPLE_DATASET=sample
MYSQL_TARGET=mysql
POSTGRES_TARGET=postgres
MONGO_TARGET=mongo

EMPLOYEES_SOURCE_DB=employees
PAGILA_SOURCE_DB=pagila
PAGILA_CYCLE_MODE=defer_constraints

EMPLOYEES_DEPARTMENTS_ROWS=9
EMPLOYEES_DEPT_MANAGER_ROWS=24
EMPLOYEES_EMPLOYEES_ROWS=300024
EMPLOYEES_DEPT_EMP_ROWS=331603
EMPLOYEES_TITLES_ROWS=443308
EMPLOYEES_SALARIES_ROWS=2844047
PAGILA_FILM_ROWS=1000
PAGILA_RENTAL_ROWS=51805
PAGILA_PAYMENT_ROWS=51061
SAMPLE_SOURCE_DB=sample_mflix
SAMPLE_COMMENTS_ROWS=50304
SAMPLE_MOVIES_ROWS=23539
SAMPLE_SESSIONS_ROWS=1
SAMPLE_THEATERS_ROWS=1564
SAMPLE_USERS_ROWS=185

DATASETS=("$EMPLOYEES_DATASET" "$PAGILA_DATASET" "$SAMPLE_DATASET")
TARGETS=("$MYSQL_TARGET" "$POSTGRES_TARGET" "$MONGO_TARGET")

compose() {
  docker compose --project-directory "$ROOT" "$@"
}

require_dataset() {
  case "$1" in
    "$EMPLOYEES_DATASET"|"$PAGILA_DATASET"|"$SAMPLE_DATASET") return 0 ;;
  esac
  printf 'Dataset must be %s, %s, or %s.\n' "$EMPLOYEES_DATASET" "$PAGILA_DATASET" "$SAMPLE_DATASET" >&2
  return 1
}

require_target() {
  case "$1" in
    "$MYSQL_TARGET"|"$POSTGRES_TARGET"|"$MONGO_TARGET") return 0 ;;
  esac
  printf 'Target must be %s, %s, or %s.\n' "$MYSQL_TARGET" "$POSTGRES_TARGET" "$MONGO_TARGET" >&2
  return 1
}

# Piper rejects same-dialect migrations (six cross-engine directions only).
require_cross_dialect() {
  require_dataset "$1"
  require_target "$2"
  local source
  source="$(source_engine "$1")"
  if [[ "$source" == "$2" ]]; then
    printf 'Same-dialect migrations are unsupported (%s source -> %s).\n' "$source" "$2" >&2
    printf 'Use a different engine target. Supported playground cells are listed in README.md.\n' >&2
    return 1
  fi
}

source_engine() {
  case "$1" in
    "$EMPLOYEES_DATASET") printf '%s\n' "$MYSQL_TARGET" ;;
    "$PAGILA_DATASET") printf '%s\n' "$POSTGRES_TARGET" ;;
    "$SAMPLE_DATASET") printf '%s\n' "$MONGO_TARGET" ;;
    *) return 1 ;;
  esac
}

source_database() {
  case "$1" in
    "$EMPLOYEES_DATASET") printf '%s\n' "$EMPLOYEES_SOURCE_DB" ;;
    "$PAGILA_DATASET") printf '%s\n' "$PAGILA_SOURCE_DB" ;;
    "$SAMPLE_DATASET") printf '%s\n' "$SAMPLE_SOURCE_DB" ;;
    *) return 1 ;;
  esac
}

sample_databases() {
  printf '%s\n' \
    sample_airbnb \
    sample_analytics \
    sample_geospatial \
    sample_mflix \
    sample_supplies \
    sample_training \
    sample_weatherdata
}

require_sample_database() {
  local name
  while read -r name; do
    [[ "$name" == "$1" ]] && return 0
  done < <(sample_databases)
  printf 'Sample database must be one of:\n' >&2
  sample_databases >&2
  return 1
}

# Target DB name matches the source dataset name on the other engine.
# Same-dialect *_target names are gone — those pairs are unsupported.
resolved_target_database() {
  printf '%s\n' "$2"
}

target_database() {
  resolved_target_database "$(source_engine "$1")" "$(source_database "$1")" "$2"
}

probe_table() {
  case "$1" in
    "$EMPLOYEES_DATASET") printf '%s\n' employees ;;
    "$PAGILA_DATASET") printf '%s\n' film ;;
    "$SAMPLE_DATASET") printf '%s\n' movies ;;
    *) return 1 ;;
  esac
}

inspect_command() {
  if [[ "$(source_engine "$1")" == "$MONGO_TARGET" ]]; then
    printf 'inspect --sample-full\n'
    return 0
  fi
  printf 'inspect\n'
}

plan_command() {
  if [[ "$1" == "$PAGILA_DATASET" ]]; then
    printf 'plan --target %s --cycle-mode %s\n' "$2" "$PAGILA_CYCLE_MODE"
    return 0
  fi
  printf 'plan --target %s\n' "$2"
}

connection_url() {
  case "$1" in
    "$POSTGRES_TARGET")
      printf 'postgres://%s:%s@%s:%s/%s?sslmode=disable\n' \
        "$PG_USER" "$PG_PASSWORD" "$PLAYGROUND_HOST" "$PG_PORT" "$2"
      ;;
    "$MYSQL_TARGET")
      printf 'mysql://%s:%s@%s:%s/%s?sslmode=disable\n' \
        "$APP_USER" "$APP_PASSWORD" "$PLAYGROUND_HOST" "$MYSQL_PORT" "$2"
      ;;
    "$MONGO_TARGET")
      printf 'mongodb://%s:%s@%s:%s/%s?authSource=%s\n' \
        "$APP_USER" "$APP_PASSWORD" "$PLAYGROUND_HOST" "$MONGO_PORT" "$2" "$MONGO_AUTH_DB"
      ;;
    *) return 1 ;;
  esac
}

piper_bin() {
  if [[ -n "${PIPER_BIN:-}" ]]; then
    [[ -x "$PIPER_BIN" ]] || { printf 'PIPER_BIN is not executable: %s\n' "$PIPER_BIN" >&2; return 1; }
    printf '%s\n' "$PIPER_BIN"
    return 0
  fi
  local bundled="$ROOT/bin/piper"
  if [[ -x "$bundled" ]]; then
    printf '%s\n' "$bundled"
    return 0
  fi
  local sibling="$ROOT/../piper-go/piper"
  if [[ -x "$sibling" ]]; then
    printf '%s\n' "$sibling"
    return 0
  fi
  local found
  found="$(command -v piper || true)"
  if [[ -z "$found" ]]; then
    printf 'No piper binary. Copy it to %s and chmod +x.\n' "$bundled" >&2
    return 1
  fi
  printf '%s\n' "$found"
}

cell_dir() {
  printf '%s/runs/%s-to-%s\n' "$ROOT" "$1" "$2"
}

mysql_root() {
  compose exec -T mysql mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "$1"
}

grant_mysql_app_user() {
  mysql_root "CREATE USER IF NOT EXISTS '${APP_USER}'@'%' IDENTIFIED BY '${APP_PASSWORD}'; GRANT ALL PRIVILEGES ON *.* TO '${APP_USER}'@'%'; FLUSH PRIVILEGES;"
}

ensure_stack() {
  compose up -d --wait
  grant_mysql_app_user
}

# Identifiers passed here are playground-controlled (dataset/fixture names).
psql_maintenance_sql() {
  compose exec -T postgres psql -v ON_ERROR_STOP=1 -U "$PG_USER" -d "$PG_MAINTENANCE_DB" -c "$1"
}

terminate_postgres_database() {
  psql_maintenance_sql "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$1' AND pid <> pg_backend_pid();"
}

drop_postgres_database() {
  terminate_postgres_database "$1"
  psql_maintenance_sql "DROP DATABASE IF EXISTS \"$1\";"
}

recreate_postgres_database() {
  drop_postgres_database "$1"
  psql_maintenance_sql "CREATE DATABASE \"$1\";"
}

drop_mysql_database() {
  mysql_root "DROP DATABASE IF EXISTS \`$1\`;"
}

recreate_mysql_database() {
  mysql_root "DROP DATABASE IF EXISTS \`$1\`; CREATE DATABASE \`$1\`;"
}

drop_mongo_database() {
  compose exec -T mongo mongosh --quiet \
    -u "$APP_USER" -p "$APP_PASSWORD" --authenticationDatabase "$MONGO_AUTH_DB" \
    "$1" --eval 'db.dropDatabase()'
}

drop_sample_sources() {
  local database
  while read -r database; do
    drop_mongo_database "$database"
  done < <(sample_databases)
}

clear_source() {
  local dataset="$1"
  case "$(source_engine "$dataset")" in
    "$MYSQL_TARGET") drop_mysql_database "$(source_database "$dataset")" ;;
    "$POSTGRES_TARGET") drop_postgres_database "$(source_database "$dataset")" ;;
    "$MONGO_TARGET") drop_sample_sources ;;
  esac
}

clear_named_target() {
  case "$1" in
    "$MYSQL_TARGET") recreate_mysql_database "$2" ;;
    "$POSTGRES_TARGET") recreate_postgres_database "$2" ;;
    "$MONGO_TARGET") drop_mongo_database "$2" ;;
    *) return 1 ;;
  esac
}

clear_target() {
  clear_named_target "$2" "$(target_database "$1" "$2")"
}

count_table() {
  case "$1" in
    "$POSTGRES_TARGET")
      compose exec -T postgres psql -v ON_ERROR_STOP=1 -U "$PG_USER" -d "$2" -tAc "SELECT COUNT(*) FROM public.$3"
      ;;
    "$MYSQL_TARGET")
      compose exec -T mysql mysql -N -B -u"$APP_USER" -p"$APP_PASSWORD" "$2" -e "SELECT COUNT(*) FROM \`$3\`"
      ;;
    "$MONGO_TARGET")
      compose exec -T mongo mongosh --quiet \
        -u "$APP_USER" -p "$APP_PASSWORD" --authenticationDatabase "$MONGO_AUTH_DB" \
        "$2" --eval "db.getCollection('$3').countDocuments({})"
      ;;
    *) return 1 ;;
  esac
}

digits_only() {
  printf '%s' "$1" | tr -cd '0-9'
}

expected_rows() {
  case "$1" in
    "$EMPLOYEES_DATASET")
      printf '%s %s\n' \
        departments "$EMPLOYEES_DEPARTMENTS_ROWS" \
        dept_manager "$EMPLOYEES_DEPT_MANAGER_ROWS" \
        employees "$EMPLOYEES_EMPLOYEES_ROWS" \
        dept_emp "$EMPLOYEES_DEPT_EMP_ROWS" \
        titles "$EMPLOYEES_TITLES_ROWS" \
        salaries "$EMPLOYEES_SALARIES_ROWS"
      ;;
    "$PAGILA_DATASET")
      printf '%s %s\n' \
        film "$PAGILA_FILM_ROWS" \
        rental "$PAGILA_RENTAL_ROWS" \
        payment "$PAGILA_PAYMENT_ROWS"
      ;;
    "$SAMPLE_DATASET")
      printf '%s %s\n' \
        comments "$SAMPLE_COMMENTS_ROWS" \
        movies "$SAMPLE_MOVIES_ROWS" \
        sessions "$SAMPLE_SESSIONS_ROWS" \
        theaters "$SAMPLE_THEATERS_ROWS" \
        users "$SAMPLE_USERS_ROWS"
      ;;
    *) return 1 ;;
  esac
}

assert_source_loaded() {
  local dataset="$1" count
  if ! count="$(count_table "$(source_engine "$dataset")" "$(source_database "$dataset")" "$(probe_table "$dataset")" 2>/dev/null | tail -n 1)"; then
    printf 'Source %s is not loaded. Run ./playground/load.sh %s\n' "$dataset" "$dataset" >&2
    return 1
  fi
  count="$(digits_only "$count")"
  if [[ -z "$count" || "$count" == 0 ]]; then
    printf 'Source %s has no %s rows. Run ./playground/load.sh %s\n' "$dataset" "$(probe_table "$dataset")" "$dataset" >&2
    return 1
  fi
}
