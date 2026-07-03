# Nginx Proxy Manager — 迁移指南

## 为什么准备这个备选方案

Traefik 本身功能完备，但在 AiJiaS 混合架构（Docker + LXD + VM）中：
- Docker label 自动发现对 LXD/VM 服务无效 → 仍须手写 IP
- 多层抽象（provider → router → service）调试路径长
- 配置文件分散（5+ yml），排查问题需跨文件追踪

NPM 提供 **Web UI 管理** + **单容器** + **Nginx 直接转发**，更直观。

## 切换步骤

### 1. 停 Traefik，启 NPM

```bash
cd /File/project/AiJiaS

# 停 Traefik
docker compose -f traefik/docker-compose.yml -p traefik down

# 启 NPM
docker compose -f nginx/docker-compose.yml -p npm up -d
```

### 2. 首次登录 NPM

浏览器打开 `http://192.168.3.195:8181`

- 默认账号: `admin@example.com`
- 默认密码: `changeme`
- **登录后立即修改邮箱和密码**

### 3. 导入 SSL 证书

#### 方案 A：NPM 内置 Let's Encrypt（简单，但需公网 80 可达）

NPM Web UI → SSL Certificates → Add SSL Certificate → Let's Encrypt
- Domain: `*.aijias.xyz, aijias.xyz`
- Email: 你的邮箱
- 勾选 "Use a DNS Challenge"
- DNS Provider: 选择 Alibaba（如不可用，用方案 B）

#### 方案 B：外部 acme.sh（推荐，阿里云 DNS Challenge）

```bash
# 在 NAS 上一次性执行
bash /File/project/AiJiaS/scripts/acme-ssl.sh
```

然后在 NPM Web UI → SSL Certificates → Add → Custom:
- Name: `aijias-wildcard`
- Certificate: `/certs/fullchain.pem`
- Key: `/certs/privkey.pem`

### 4. 创建 Proxy Host

在 NPM Web UI → Hosts → Proxy Hosts → Add:

| # | Domain | Forward IP | Port | SSL | WebSocket |
|---|--------|-----------|------|-----|-----------|
| 1 | `hermes.aijias.xyz` | 192.168.3.198 | 3000 | ✅ | ✅ |
| 2 | `terminal.aijias.xyz` | 192.168.3.195 | 8086 | ✅ | ✅ |
| 3 | `llm.aijias.xyz` | 192.168.3.195 | 4000 | ✅ | — |
| 4 | `dns.aijias.xyz` | 192.168.3.195 | 3000 | ✅ | — |
| 5 | `npm.aijias.xyz` | 127.0.0.1 | 81 | ✅ | — |

> WebSocket 需要开启的服务：Hermes, Next Terminal
> SSL 选择步骤 3 导入的证书

### 5. 验证

```bash
curl -k https://hermes.aijias.xyz
curl -k https://terminal.aijias.xyz
curl -k https://llm.aijias.xyz/v1/models
curl -k https://dns.aijias.xyz
```

## 回退到 Traefik

```bash
docker compose -f nginx/docker-compose.yml -p npm down
docker compose -f traefik/docker-compose.yml -p traefik up -d
```

## 注意事项

- NPM 和 Traefik **不能同时运行**（端口 80/8443 冲突）
- NPM 数据持久化在 `/share/Container/npm/`（SSD）
- acme.sh 证书每 60 天自动续期，续期后需 `docker restart npm` 重载
- traefik-manager 在切换后不再需要，但可以保留不启
