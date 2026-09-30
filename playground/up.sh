#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

ensure_stack
printf 'Ready. PostgreSQL %s, MySQL %s, MongoDB %s.\n' "$PG_PORT" "$MYSQL_PORT" "$MONGO_PORT"
