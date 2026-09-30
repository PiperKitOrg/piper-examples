#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

compose down -v
printf 'Volumes removed. Load employees and pagila again after the next start.\n'
