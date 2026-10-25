#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

if [[ -f .env ]]; then
  set -a
  source <(tr -d '\r' < .env)
  set +a
fi

SUPABASE_WORKDIR="$(cd "${SUPABASE_WORKDIR:-$ROOT/backend}" && pwd)"

docker compose down
(cd "$ROOT/backend" && npx supabase --workdir "$SUPABASE_WORKDIR" stop)
