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
FRONTEND_PORT="${FRONTEND_PORT:-8080}"

if [[ ! -d "$ROOT/backend/node_modules" ]]; then
  npm ci --prefix "$ROOT/backend"
fi

supabase() {
  (cd "$ROOT/backend" && npx supabase --workdir "$SUPABASE_WORKDIR" "$@")
}

supabase start

eval "$(supabase status -o env 2>/dev/null | grep -E '^[A-Z_]+=' | sed 's/^/SB_/')"

export VITE_SUPABASE_URL="${VITE_SUPABASE_URL:-${SB_API_URL:-}}"
export VITE_SUPABASE_PUBLISHABLE_DEFAULT_KEY="${VITE_SUPABASE_PUBLISHABLE_DEFAULT_KEY:-${SB_PUBLISHABLE_KEY:-${SB_ANON_KEY:-}}}"
export VITE_AUTH_REDIRECT_URL="${VITE_AUTH_REDIRECT_URL:-http://localhost:$FRONTEND_PORT}"
export FRONTEND_PORT

if [[ -z "$VITE_SUPABASE_URL" || -z "$VITE_SUPABASE_PUBLISHABLE_DEFAULT_KEY" ]]; then
  echo "No se pudo obtener la URL o la llave de Supabase; definelas en .env" >&2
  exit 1
fi

docker compose up -d --build

echo "Frontend: http://localhost:$FRONTEND_PORT"
echo "API:      $VITE_SUPABASE_URL"
echo "Supabase: $SUPABASE_WORKDIR"
