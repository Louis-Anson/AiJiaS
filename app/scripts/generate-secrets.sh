#!/bin/bash
# generate-secrets.sh — Generate all random passwords and tokens for AiJiaS
# Usage: bash generate-secrets.sh >> .env

echo "# ========== Database =========="
echo "POSTGRES_PASSWORD=$(openssl rand -base64 32)"
echo "REDIS_PASSWORD=$(openssl rand -base64 24)"
echo ""

echo "# ========== LiteLLM =========="
echo "LITELLM_MASTER_KEY=$(openssl rand -base64 32)"
echo "LITELLM_SALT_KEY=$(openssl rand -base64 32)"
echo ""

echo "# ========== ntfy =========="
echo "NTFY_TOKEN=ntfy_$(openssl rand -base64 24 | tr '/+' '_-')"
echo ""

echo "# ========== Service Database Passwords =========="
echo "FIREFLY_DB_PASSWORD=$(openssl rand -base64 16)"
echo "FIREFLY_APP_KEY=$(openssl rand -base64 32)"
echo "MEALIE_DB_PASSWORD=$(openssl rand -base64 16)"
echo "LUBELOGGER_DB_PASSWORD=$(openssl rand -base64 16)"
echo "IMMICH_DB_PASSWORD=$(openssl rand -base64 16)"
echo "HBOX_AUTH_API_KEY_PEPPER=$(openssl rand -base64 48)"
echo ""

echo "# ========== Vaultwarden =========="
echo "VAULT_ADMIN_TOKEN=$(openssl rand -base64 48)"
echo ""

echo "# ========== External API Keys (fill manually) =========="
echo "DEEPSEEK_API_KEY=your_deepseek_key_here"
echo "OPENAI_API_KEY=your_4sapi_key_here"
echo "KIMI_API_KEY=your_kimi_key_here"
echo "ZHIPU_API_KEY=your_zhipu_key_here"
echo "OPENROUTER_API_KEY=your_openrouter_key_here"
echo ""

echo "# ========== Home Assistant (generate in HA Web UI) =========="
echo "HA_LONG_LIVED_ACCESS_TOKEN=your_ha_token_here"
