#!/bin/bash
# ============================================================
# AiJiaS PostgreSQL 数据库初始化脚本
# 在 PostgreSQL 首次启动时由 docker-entrypoint-initdb.d 自动执行
# 为每个需要 PG 的家庭服务创建独立 database + 专用 user + 完整授权
# ============================================================
#
# 说明：
#   - 官方 postgres 镜像执行本目录下的 *.sh 时会注入容器环境变量，
#     因此这里用 ${XXX_DB_PASSWORD} 读取 .env 中的密码（database.yml 已传入容器）。
#   - 幂等：重复建库/建角色不会报错（首次启动只执行一次，此处仍做防御）。
#   - PG15+ 默认收回 public schema 的 CREATE 权限，必须显式 GRANT，
#     否则 Mealie / Firefly / LubeLogger 建表会失败。
#   - Immich 使用独立 postgres 容器，不在此初始化。
#   - Donetick / Homebox 使用 SQLite，不需要 PG。
# ============================================================

set -euo pipefail

# 主连接使用超级用户 POSTGRES_USER（来自容器环境变量）
PSQL_SUPER=(psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB")

# ------------------------------------------------------------
# 工具函数：创建角色（幂等）
#   $1 = 角色名   $2 = 密码
# ------------------------------------------------------------
create_role() {
  local role="$1"
  local password="$2"
  "${PSQL_SUPER[@]}" <<-EOSQL
	DO \$\$
	BEGIN
	  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '${role}') THEN
	    CREATE ROLE ${role} LOGIN PASSWORD '${password}';
	  ELSE
	    ALTER ROLE ${role} WITH LOGIN PASSWORD '${password}';
	  END IF;
	END
	\$\$;
	EOSQL
}

# ------------------------------------------------------------
# 工具函数：创建数据库（幂等）并把所有权交给指定角色
#   $1 = 数据库名   $2 = owner 角色名
# ------------------------------------------------------------
create_database() {
  local db="$1"
  local owner="$2"
  # CREATE DATABASE 不能放在事务/DO 块里，用 \gexec 条件执行
  "${PSQL_SUPER[@]}" <<-EOSQL
	SELECT 'CREATE DATABASE ${db} OWNER ${owner}'
	WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '${db}')\gexec
	EOSQL
}

# ------------------------------------------------------------
# 工具函数：授予数据库 + public schema 完整权限（PG15+ 必需）
#   $1 = 数据库名   $2 = 角色名
# ------------------------------------------------------------
grant_all() {
  local db="$1"
  local role="$2"
  "${PSQL_SUPER[@]}" <<-EOSQL
	GRANT ALL PRIVILEGES ON DATABASE ${db} TO ${role};
	EOSQL
  # 切换到目标库授予 public schema 权限
  psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "${db}" <<-EOSQL
	GRANT ALL ON SCHEMA public TO ${role};
	ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO ${role};
	ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO ${role};
	EOSQL
}

# ------------------------------------------------------------
# 工具函数：完整初始化一个服务（建角色 -> 建库 -> 授权）
#   $1 = 服务名（同时作为 db 名和 role 名）   $2 = 密码
# ------------------------------------------------------------
provision_service() {
  local name="$1"
  local password="$2"
  if [ -z "${password:-}" ]; then
    echo "[init] WARNING: ${name} 的密码为空，跳过。请检查 .env 中对应的 *_DB_PASSWORD。"
    return
  fi
  echo "[init] provisioning service: ${name}"
  create_role     "${name}" "${password}"
  create_database "${name}" "${name}"
  grant_all       "${name}" "${name}"
}

echo "[init] AiJiaS PostgreSQL 初始化开始..."

# ------------------------------------------------------------
# 1. Firefly III（家庭记账）
# 2. Mealie（菜谱 + 食材库存）
# 3. LubeLogger（车辆保养）
# ------------------------------------------------------------
provision_service "firefly"    "${FIREFLY_DB_PASSWORD:-}"
provision_service "mealie"     "${MEALIE_DB_PASSWORD:-}"
provision_service "lubelogger" "${LUBELOGGER_DB_PASSWORD:-}"

# ------------------------------------------------------------
# LiteLLM 独立库（可选）
#   若需把 LiteLLM 的调用日志/spend 记录与家庭业务数据 aijias 分离，
#   在 .env 中设置 LITELLM_DB_PASSWORD 后，本段会自动创建 litellm 库。
#   未设置时跳过，LiteLLM 继续使用主库 aijias（保持当前行为）。
# ------------------------------------------------------------
if [ -n "${LITELLM_DB_PASSWORD:-}" ]; then
  provision_service "litellm" "${LITELLM_DB_PASSWORD}"
else
  echo "[init] LITELLM_DB_PASSWORD 未设置，LiteLLM 将继续使用主库 ${POSTGRES_DB}。"
fi

# ------------------------------------------------------------
# 注意：
#   - aijias 主库由镜像的 POSTGRES_DB 自动创建，无需在此处理。
#   - Immich 有独立 postgres 容器，不在此初始化。
#   - Donetick / Homebox 仅支持 SQLite，不需要 PG。
# ------------------------------------------------------------
echo "[init] AiJiaS PostgreSQL 初始化完成。"
