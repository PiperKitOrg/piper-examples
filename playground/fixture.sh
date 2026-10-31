#!/usr/bin/env bash
# Load e2e fixtures into the playground stack for manual piper migrations.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

FIXTURE_ROOT="$ROOT/datasets/e2e-fixtures"
CATALOG="$FIXTURE_ROOT/catalog.json"
CONTAINER_ROOT=/datasets/e2e-fixtures

usage() {
  cat <<'EOF' >&2
Usage:
  ./playground/fixture.sh list
  ./playground/fixture.sh load <fixture_id>
  ./playground/fixture.sh commands <fixture_id> <mysql|postgres|mongo>
  ./playground/fixture.sh clear-target-db <mysql|postgres|mongo> <database>

Examples:
  ./playground/fixture.sh load production_weird
  ./playground/fixture.sh commands production_weird mysql
EOF
}

require_catalog() {
  [[ -f "$CATALOG" ]] || {
    printf 'Missing %s\n' "$CATALOG" >&2
    return 1
  }
}

catalog_list() {
  require_catalog
  python3 - "$CATALOG" <<'PY'
import json, sys
from pathlib import Path
catalog = json.loads(Path(sys.argv[1]).read_text())
print(f"{'ID':32} {'DIALECT':8} DIR")
for row in catalog:
    note = (row.get("notes") or "").strip()
    print(f"{row['id']:32} {row['dialect']:8} {row['dir']}")
    if note:
        print(f"  {note}")
PY
}

catalog_row() {
  require_catalog
  python3 - "$CATALOG" "$1" <<'PY'
import json, sys
from pathlib import Path
catalog = json.loads(Path(sys.argv[1]).read_text())
want = sys.argv[2]
row = next((r for r in catalog if r["id"] == want), None)
if row is None:
    ids = ", ".join(r["id"] for r in catalog)
    print(f"unknown fixture {want!r}; choose one of: {ids}", file=sys.stderr)
    raise SystemExit(1)
print(json.dumps(row))
PY
}

fixture_db_name() {
  printf '%s\n' "$1" | tr '-' '_'
}

recreate_source_db() {
  case "$1" in
    postgres) recreate_postgres_database "$2" ;;
    mysql) recreate_mysql_database "$2" ;;
    mongo) drop_mongo_database "$2" ;;
    *) return 1 ;;
  esac
}

import_sql() {
  local dialect="$1" db="$2" host_path="$3" container_path="$4"
  case "$dialect" in
    postgres)
      compose exec -T postgres psql -v ON_ERROR_STOP=1 -U "$PG_USER" -d "$db" \
        -f "$container_path"
      ;;
    mysql)
      # Feed the host file on stdin; avoid shell quoting inside the container.
      compose exec -T mysql mysql -uroot -p"$MYSQL_ROOT_PASSWORD" "$db" <"$host_path"
      ;;
    *)
      printf 'SQL import not supported for %s\n' "$dialect" >&2
      return 1
      ;;
  esac
}

import_mongo_json() {
  local db="$1" collection="$2" host_path="$3" container_path="$4"
  local args=(
    exec -T mongo mongoimport
    --username "$APP_USER"
    --password "$APP_PASSWORD"
    --authenticationDatabase "$MONGO_AUTH_DB"
    --db "$db"
    --collection "$collection"
    --drop
    --file "$container_path"
  )
  if [[ "$(head -c 1 "$host_path")" == "[" ]]; then
    args+=(--jsonArray)
  fi
  compose "${args[@]}"
}

load_steps() {
  local dialect="$1" db="$2" dir="$3" id="$4"
  local typ path collection host_path container_path
  while IFS=$'\t' read -r typ path collection; do
    host_path="$FIXTURE_ROOT/$dir/$path"
    container_path="$CONTAINER_ROOT/$dir/$path"
    [[ -f "$host_path" ]] || {
      printf 'missing fixture file %s\n' "$host_path" >&2
      return 1
    }
    case "$typ" in
      fixture_sql|psql_file|mysql_file)
        import_sql "$dialect" "$db" "$host_path" "$container_path"
        ;;
      fixture_json|mongo_import)
        [[ -n "$collection" ]] || {
          printf 'mongo step missing collection\n' >&2
          return 1
        }
        import_mongo_json "$db" "$collection" "$host_path" "$container_path"
        ;;
      *)
        printf 'unknown step type %s\n' "$typ" >&2
        return 1
        ;;
    esac
  done < <(python3 - "$CATALOG" "$id" <<'PY'
import json, sys
from pathlib import Path
catalog = json.loads(Path(sys.argv[1]).read_text())
row = next(r for r in catalog if r["id"] == sys.argv[2])
for step in row["steps"]:
    print("\t".join([
        step["type"],
        step.get("path", ""),
        step.get("collection", ""),
    ]))
PY
)
}

load_fixture() {
  local id="$1" meta dialect dir db
  meta="$(catalog_row "$id")"
  dialect="$(python3 -c 'import json,sys; print(json.load(sys.stdin)["dialect"])' <<<"$meta")"
  dir="$(python3 -c 'import json,sys; print(json.load(sys.stdin)["dir"])' <<<"$meta")"
  db="$(fixture_db_name "$id")"
  ensure_stack
  printf 'Loading fixture %s (%s) into database %s…\n' "$id" "$dialect" "$db"
  recreate_source_db "$dialect" "$db"
  load_steps "$dialect" "$db" "$dir" "$id"
  printf 'Loaded. Source dialect=%s database=%s\n' "$dialect" "$db"
  printf 'Next: ./playground/fixture.sh commands %s <mysql|postgres|mongo>\n' "$id"
}

print_fixture_commands() {
  local id="$1" target="$2" meta dialect db relative inspect plan
  meta="$(catalog_row "$id")"
  dialect="$(python3 -c 'import json,sys; print(json.load(sys.stdin)["dialect"])' <<<"$meta")"
  db="$(fixture_db_name "$id")"
  require_target "$target"
  if [[ "$dialect" == "$target" ]]; then
    printf 'Same-dialect migrations are unsupported (%s -> %s).\n' "$dialect" "$target" >&2
    return 1
  fi
  relative="runs/fixture-${id}-to-${target}"
  mkdir -p "$ROOT/$relative"
  printf 'PIPER_SOURCE_URL=%s\nPIPER_TARGET_URL=%s\n' \
    "$(connection_url "$dialect" "$db")" \
    "$(connection_url "$target" "$db")" >"$ROOT/$relative/.env"
  inspect="inspect"
  [[ "$dialect" == mongo ]] && inspect="inspect --sample-full"
  plan="plan --target ${target}"
  cat <<EOF
# Fixture ${id} (${dialect} -> ${target})
# Source/target database name: ${db}
# Prerequisite: ./playground/fixture.sh load ${id}

./playground/fixture.sh clear-target-db ${target} ${db}
cd ${relative}
rm -rf .piper
set -a
source .env
set +a
../../bin/piper ${inspect}
../../bin/piper ${plan}
../../bin/piper --yes execute
cd ../..
EOF
  printf 'Wrote %s/.env\n' "$relative" >&2
}

main() {
  case "${1:-}" in
    list)
      catalog_list
      ;;
    load)
      [[ $# -eq 2 ]] || { usage; return 1; }
      load_fixture "$2"
      ;;
    commands)
      [[ $# -eq 3 ]] || { usage; return 1; }
      print_fixture_commands "$2" "$3"
      ;;
    clear-target-db)
      [[ $# -eq 3 ]] || { usage; return 1; }
      require_target "$2"
      ensure_stack
      clear_named_target "$2" "$3"
      printf 'Cleared %s database %s.\n' "$2" "$3"
      ;;
    *)
      usage
      return 1
      ;;
  esac
}

main "$@"
