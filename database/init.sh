#!/bin/bash
# Home Database — init script (runs inside container)
# Auto-executed by docker-entrypoint-initdb.d on first start
set -euo pipefail
echo "[init] PostgreSQL init start..."

for svc in firefly mealie lubelogger litellm homeassistant next-terminal; do
  pw_var="${svc^^}_DB_PASSWORD"
  [ "$svc" = "next-terminal" ] && pw_var="NEXT_TERMINAL_DB_PASSWORD"
  pw="${!pw_var}"
  db="$svc"
  role="$svc"
  [ "$svc" = "next-terminal" ] && db='"'"next-terminal"'"' && role='"'"next-terminal"'"'
  
  echo "[init] provisioning $svc..."
  psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" -d postgres -c "
    DO \$\$
    BEGIN
      IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '$role') THEN
        CREATE ROLE $role LOGIN PASSWORD '$pw';
      ELSE
        ALTER ROLE $role WITH LOGIN PASSWORD '$pw';
      END IF;
    END \$\$;
  "
  psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" -d postgres -c "CREATE DATABASE $db OWNER $role" 2>/dev/null || true
  psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" -d "$db" -c "GRANT ALL ON SCHEMA public TO $role" 2>/dev/null || true
done

echo "[init] Done."
