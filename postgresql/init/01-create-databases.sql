-- ============================================================
-- AiJiaS 数据库初始化脚本
-- 在 PostgreSQL 首次启动时自动执行
-- 为所有需要 PG 的服务创建专用 database 和用户
-- ============================================================

-- 1. 主数据库 — Hermes / LiteLLM / ntfy / 家庭关怀引擎
SELECT 'CREATE DATABASE aijias'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'aijias')\gexec

-- 2. Firefly III
SELECT 'CREATE DATABASE firefly'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'firefly')\gexec
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'firefly') THEN
    CREATE ROLE firefly LOGIN PASSWORD :'firefly_password';
  END IF;
END $$;

-- 3. Mealie
SELECT 'CREATE DATABASE mealie'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'mealie')\gexec
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'mealie') THEN
    CREATE ROLE mealie LOGIN PASSWORD :'mealie_password';
  END IF;
END $$;

-- 4. LubeLogger
SELECT 'CREATE DATABASE lubelogger'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'lubelogger')\gexec
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'lubelogger') THEN
    CREATE ROLE lubelogger LOGIN PASSWORD :'lubelogger_password';
  END IF;
END $$;

-- ============================================================
-- 注意：
-- Immich 有独立的 postgres 容器，不在此处初始化
-- Donetick / Homebox 仅支持 SQLite，不需要 PG
-- ============================================================
