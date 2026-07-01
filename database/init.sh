#!/bin/bash
# ============================================================
# Home Database — 初始化脚本
# 用法：source database/.env && bash database/init.sh
# 幂等：重复执行不报错，密码变更时自动更新
# ============================================================

set -euo pipefail

PSQL_USER="${POSTGRES_USER:-admin}"

echo "[init] 使用用户 $PSQL_USER 连接 PostgreSQL..."

# Run psql with variable substitution
docker exec -i postgres psql -U "$PSQL_USER" -d postgres -v firefly_pw="$FIREFLY_DB_PASSWORD" -v mealie_pw="$MEALIE_DB_PASSWORD" -v lubelogger_pw="$LUBELOGGER_DB_PASSWORD" -v litellm_pw="$LITELLM_DB_PASSWORD" -v ha_pw="$HA_DB_PASSWORD" -v nt_pw="$NEXT_TERMINAL_DB_PASSWORD" << 'SQL'
-- ===== firefly =====
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'firefly') THEN
    CREATE ROLE firefly LOGIN PASSWORD :'firefly_pw';
  ELSE
    ALTER ROLE firefly WITH LOGIN PASSWORD :'firefly_pw';
  END IF;
END $$;
SELECT 'CREATE DATABASE firefly OWNER firefly' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'firefly')\gexec
GRANT ALL PRIVILEGES ON DATABASE firefly TO firefly;
\c firefly
GRANT ALL ON SCHEMA public TO firefly;

-- ===== mealie =====
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'mealie') THEN
    CREATE ROLE mealie LOGIN PASSWORD :'mealie_pw';
  ELSE
    ALTER ROLE mealie WITH LOGIN PASSWORD :'mealie_pw';
  END IF;
END $$;
SELECT 'CREATE DATABASE mealie OWNER mealie' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'mealie')\gexec
GRANT ALL PRIVILEGES ON DATABASE mealie TO mealie;
\c mealie
GRANT ALL ON SCHEMA public TO mealie;

-- ===== lubelogger =====
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'lubelogger') THEN
    CREATE ROLE lubelogger LOGIN PASSWORD :'lubelogger_pw';
  ELSE
    ALTER ROLE lubelogger WITH LOGIN PASSWORD :'lubelogger_pw';
  END IF;
END $$;
SELECT 'CREATE DATABASE lubelogger OWNER lubelogger' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'lubelogger')\gexec
GRANT ALL PRIVILEGES ON DATABASE lubelogger TO lubelogger;
\c lubelogger
GRANT ALL ON SCHEMA public TO lubelogger;

-- ===== litellm =====
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'litellm') THEN
    CREATE ROLE litellm LOGIN PASSWORD :'litellm_pw';
  ELSE
    ALTER ROLE litellm WITH LOGIN PASSWORD :'litellm_pw';
  END IF;
END $$;
SELECT 'CREATE DATABASE litellm OWNER litellm' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'litellm')\gexec
GRANT ALL PRIVILEGES ON DATABASE litellm TO litellm;
\c litellm
GRANT ALL ON SCHEMA public TO litellm;

-- ===== homeassistant =====
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'homeassistant') THEN
    CREATE ROLE homeassistant LOGIN PASSWORD :'ha_pw';
  ELSE
    ALTER ROLE homeassistant WITH LOGIN PASSWORD :'ha_pw';
  END IF;
END $$;
SELECT 'CREATE DATABASE homeassistant OWNER homeassistant' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'homeassistant')\gexec
GRANT ALL PRIVILEGES ON DATABASE homeassistant TO homeassistant;
\c homeassistant
GRANT ALL ON SCHEMA public TO homeassistant;

-- ===== next-terminal =====
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'next-terminal') THEN
    CREATE ROLE "next-terminal" LOGIN PASSWORD :'nt_pw';
  ELSE
    ALTER ROLE "next-terminal" WITH LOGIN PASSWORD :'nt_pw';
  END IF;
END $$;
SELECT 'CREATE DATABASE "next-terminal" OWNER "next-terminal"' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'next-terminal')\gexec
GRANT ALL PRIVILEGES ON DATABASE "next-terminal" TO "next-terminal";
\c "next-terminal"
GRANT ALL ON SCHEMA public TO "next-terminal";

-- ===== 验证 =====
SELECT datname, datdba::regrole FROM pg_database WHERE datname IN ('firefly','mealie','lubelogger','litellm','homeassistant','next-terminal');
SQL

echo ""
echo "[init] 初始化完成。"
