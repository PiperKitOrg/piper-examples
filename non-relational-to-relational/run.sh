#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

if [[ ! -f .env ]]; then
  echo "missing .env — copy .env.example to .env and adjust if needed" >&2
  exit 1
fi

set -a
# shellcheck disable=SC1091
source .env
set +a

piper inspect
# shop_with_cycle has a users⇄teams relationship cycle; strict mode would fail planning.
piper plan --target postgres --cycle-mode defer_constraints
piper execute
