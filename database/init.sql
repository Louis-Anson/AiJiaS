-- ============================================================
-- Home Database — 初始化脚本
-- 部署后手动执行一次：docker exec -i postgres psql -U admin < init.sql
-- 幂等：重复执行不报错，密码变更时自动更新
-- ============================================================

-- ==== 1. 创建服务专用数据库 & 角色 ====
-- 每个服务一个独立 database + user，互不干扰

DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'firefly') THEN
    CREATE ROLE firefly LOGIN PASSWORD 'change-me-firefly';
  ELSE
    ALTER ROLE firefly WITH LOGIN PASSWORD 'change-me-firefly';
  END IF;
END $$;
SELECT 'CREATE DATABASE firefly OWNER firefly'
 WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'firefly')\gexec
GRANT ALL PRIVILEGES ON DATABASE firefly TO firefly;

DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'mealie') THEN
    CREATE ROLE mealie LOGIN PASSWORD 'change-me-mealie';
  ELSE
    ALTER ROLE mealie WITH LOGIN PASSWORD 'change-me-mealie';
  END IF;
END $$;
SELECT 'CREATE DATABASE mealie OWNER mealie'
 WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'mealie')\gexec
GRANT ALL PRIVILEGES ON DATABASE mealie TO mealie;

DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'lubelogger') THEN
    CREATE ROLE lubelogger LOGIN PASSWORD 'change-me-lubelogger';
  ELSE
    ALTER ROLE lubelogger WITH LOGIN PASSWORD 'change-me-lubelogger';
  END IF;
END $$;
SELECT 'CREATE DATABASE lubelogger OWNER lubelogger'
 WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'lubelogger')\gexec
GRANT ALL PRIVILEGES ON DATABASE lubelogger TO lubelogger;

DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'litellm') THEN
    CREATE ROLE litellm LOGIN PASSWORD 'change-me-litellm';
  ELSE
    ALTER ROLE litellm WITH LOGIN PASSWORD 'change-me-litellm';
  END IF;
END $$;
SELECT 'CREATE DATABASE litellm OWNER litellm'
 WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'litellm')\gexec
GRANT ALL PRIVILEGES ON DATABASE litellm TO litellm;

DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'homeassistant') THEN
    CREATE ROLE homeassistant LOGIN PASSWORD 'change-me-ha';
  ELSE
    ALTER ROLE homeassistant WITH LOGIN PASSWORD 'change-me-ha';
  END IF;
END $$;
SELECT 'CREATE DATABASE homeassistant OWNER homeassistant'
 WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'homeassistant')\gexec
GRANT ALL PRIVILEGES ON DATABASE homeassistant TO homeassistant;

-- ==== 2. 授予 public schema 权限（PG15+ 必须，否则建表失败） ====
\c firefly
GRANT ALL ON SCHEMA public TO firefly;

\c mealie
GRANT ALL ON SCHEMA public TO mealie;

\c lubelogger
GRANT ALL ON SCHEMA public TO lubelogger;

\c litellm
GRANT ALL ON SCHEMA public TO litellm;

\c homeassistant
GRANT ALL ON SCHEMA public TO homeassistant;

-- ==== 3. 验证 ====
SELECT datname, datdba::regrole FROM pg_database WHERE datname IN ('firefly','mealie','lubelogger','litellm','homeassistant');
