#!/usr/bin/env bash
# Runs the migrations and schema tests against a throwaway local Postgres.
# Needs Postgres 15+ server binaries (initdb, pg_ctl) on the machine.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PGBIN="${PGBIN:-$(ls -d /usr/lib/postgresql/*/bin 2>/dev/null | sort -V | tail -1)}"
DATA="$(mktemp -d)"
PORT="${PGPORT_TEST:-54329}"
LOG="$DATA/server.log"

cleanup() {
  "$PGBIN/pg_ctl" -D "$DATA/db" -m immediate stop >/dev/null 2>&1 || true
  rm -rf "$DATA"
}
trap cleanup EXIT

RUN_AS=()
if [ "$(id -u)" = "0" ]; then
  chown -R postgres "$DATA"
  RUN_AS=(sudo -u postgres)
  command -v sudo >/dev/null || RUN_AS=(su postgres -s /bin/bash -c)
fi

run() {
  if [ "${RUN_AS[0]:-}" = "su" ]; then
    "${RUN_AS[@]}" "$(printf '%q ' "$@")"
  else
    "${RUN_AS[@]}" "$@"
  fi
}

run "$PGBIN/initdb" -D "$DATA/db" -A trust -U postgres >/dev/null
run "$PGBIN/pg_ctl" -D "$DATA/db" -o "-p $PORT -k $DATA -c listen_addresses=''" -l "$LOG" -w start >/dev/null

PSQL=(psql -h "$DATA" -p "$PORT" -U postgres -d postgres -v ON_ERROR_STOP=1 -q)

"${PSQL[@]}" -f "$ROOT/supabase/tests/local/supabase_stubs.sql"
for f in "$ROOT"/supabase/migrations/*.sql; do
  echo "migrating: $(basename "$f")"
  "${PSQL[@]}" -f "$f"
done
"${PSQL[@]}" -f "$ROOT/supabase/tests/local/schema_test.sql"
