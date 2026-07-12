#!/bin/bash
# Home Database — init script (runs inside container)
# Auto-executed by docker-entrypoint-initdb.d on first start
set -euo pipefail
echo "[init] PostgreSQL init start..."

provision() {
  local svc=$1 pw_var=$2
  local pw="${!pw_var}"
  local db="$svc" role="$svc"

  echo "[init] provisioning $svc..."
  psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d postgres -c "
    DO \$\$
    BEGIN
      IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '$role') THEN
        CREATE ROLE \"$role\" LOGIN PASSWORD '$pw';
      ELSE
        ALTER ROLE \"$role\" WITH LOGIN PASSWORD '$pw';
      END IF;
    END \$\$;
  "
  psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d postgres -c "CREATE DATABASE \"$db\" OWNER \"$role\"" 2>/dev/null || true
  psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$db" -c "GRANT ALL ON SCHEMA public TO \"$role\"" 2>/dev/null || true
}

provision firefly       FIREFLY_DB_PASSWORD
provision ezbookkeeping EZBOOKKEEPING_DB_PASSWORD
provision mealie        MEALIE_DB_PASSWORD
provision lubelogger LUBELOGGER_DB_PASSWORD
provision litellm    LITELLM_DB_PASSWORD
provision homeassistant HOMEASSISTANT_DB_PASSWORD
provision next-terminal NEXT_TERMINAL_DB_PASSWORD

echo "[init] Done."
