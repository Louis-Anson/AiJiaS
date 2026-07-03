#!/bin/bash
# ============================================================
# acme.sh — 阿里云 DNS Challenge 签发通配符证书
# 用于 Nginx Proxy Manager 的 SSL 证书
# ============================================================
# 前置条件:
#   1. 已在阿里云 RAM 创建 AccessKey（需 AliyunDNSFullAccess 权限）
#   2. 域名 aijias.xyz 的 DNS 托管在阿里云
# ============================================================

set -e

DOMAIN="aijias.xyz"
CERT_DIR="/share/Container/npm/certs"
ACME_EMAIL="${ACME_EMAIL:-admin@aijias.xyz}"

# ---------- 检查阿里云 API 凭证 ----------
if [ -z "$Ali_Key" ] || [ -z "$Ali_Secret" ]; then
    echo "错误: 请设置 Ali_Key 和 Ali_Secret 环境变量"
    echo ""
    echo "  export Ali_Key=\"LTAI5t...\""
    echo "  export Ali_Secret=\"...\""
    echo ""
    echo "或者从 .env 文件读取:"
    echo "  source traefik/.env && export Ali_Key=\"\$ALIBABA_ACCESS_KEY_ID\" Ali_Secret=\"\$ALIBABA_ACCESS_KEY_SECRET\""
    exit 1
fi

# ---------- 安装 acme.sh ----------
if [ ! -f "$HOME/.acme.sh/acme.sh" ]; then
    echo "==> 安装 acme.sh ..."
    curl https://get.acme.sh | sh -s email="$ACME_EMAIL"
fi

ACME_SH="$HOME/.acme.sh/acme.sh"

# ---------- 签发通配符证书 ----------
echo "==> 签发通配符证书: *.$DOMAIN + $DOMAIN ..."
$ACME_SH --issue \
    --dns dns_ali \
    -d "$DOMAIN" \
    -d "*.$DOMAIN" \
    --force

# ---------- 安装证书到 NPM 挂载目录 ----------
echo "==> 安装证书到 $CERT_DIR ..."
mkdir -p "$CERT_DIR"

$ACME_SH --install-cert -d "$DOMAIN" \
    --key-file       "$CERT_DIR/privkey.pem" \
    --fullchain-file "$CERT_DIR/fullchain.pem" \
    --reloadcmd      "docker restart npm 2>/dev/null || true"

# ---------- 设置权限 ----------
chmod 644 "$CERT_DIR"/*.pem

echo ""
echo "============================================"
echo "  证书签发完成！"
echo "  Key:  $CERT_DIR/privkey.pem"
echo "  Cert: $CERT_DIR/fullchain.pem"
echo ""
echo "  在 NPM Web UI 中导入:"
echo "    SSL Certificates → Add → Custom"
echo "    Certificate: /certs/fullchain.pem"
echo "    Key:         /certs/privkey.pem"
echo "============================================"
echo ""
echo "  证书将在 60 天后自动续期"
echo "  续期后会自动 docker restart npm 重载"
