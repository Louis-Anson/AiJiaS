# 自建镜像构建指南

AiJiaS 的长期策略不是把所有东西都自己重写，而是只自建“家里独有的那一层”：入口、身份、权限、审计、技能、服务适配和个人健康模型。成熟服务继续使用官方镜像，自建镜像通过 Docker Compose profiles 分阶段启用。

## 需要自建的镜像

| 镜像 | Compose 服务 | Profile | 构建优先级 | 职责 |
| :--- | :--- | :--- | :--- | :--- |
| `aijias/ai-assistant-gateway` | `ai-gateway` | `gateway` | 高 | 企业微信/微信入口、验签、家庭成员映射、限流、审计、高危操作确认。 |
| `aijias/service-adapter` | `service-adapter` | `gateway`、`agent` | 高 | 把 Donetick、Grocy、Mealie、Homebox、Home Assistant 等服务封装成稳定内部工具。 |
| `aijias/hermes-runtime` | `hermes-agent` | `agent` | 中 | 封装 Hermes 运行时、家庭记忆、任务拆解和工具调用策略。 |
| `aijias/skill-registry` | `skill-registry` | `skills` | 中 | 管理技能 manifest、参数 schema、权限策略、版本和启用状态。 |
| `aijias/skill-miner` | `skill-miner` | `skills` | 低 | 从调用日志和纠错记录中总结候选技能，写入 `skills/pending`。 |
| `aijias/period-predictor` | `period-predictor` | `health` | 低 | 女性健康周期、痛感、PMS 风险等个人化预测。 |

第一阶段最值得先做的是 `ai-assistant-gateway` 和 `service-adapter`。它们完成后，AiJiaS 就能安全地从微信入口调用家庭服务；Hermes、Skill Miner 和健康模型可以在后面逐步增强。

## 推荐源码目录

当前仓库已经有 `skills/`、`ai-models/` 和 compose 配置。后续实现自建服务时，建议把服务代码放在 `services/` 下：

```text
services/
  ai-assistant-gateway/
    Dockerfile
    src/
  service-adapter/
    Dockerfile
    src/
  hermes-runtime/
    Dockerfile
    src/
  skill-registry/
    Dockerfile
    src/
  skill-miner/
    Dockerfile
    src/
ai-models/
  period-predictor/
    Dockerfile
    inference/
    training/
    models/
    rules/
```

这样做的好处是：业务服务和 compose 编排分开，镜像构建上下文清晰，未来也更容易接入 GitHub Actions、NAS 本地构建或私有镜像仓库。

## Dockerfile 基本原则

每个自建镜像都遵循这些原则：

| 原则 | 说明 |
| :--- | :--- |
| 多阶段构建 | 编译依赖留在 builder 阶段，运行镜像尽量小。 |
| 不写入密钥 | API Key、Token、数据库密码只通过 `.env` 和运行时环境变量注入。 |
| 非 root 用户运行 | 降低容器被突破后的破坏范围。 |
| 固定基础镜像版本 | 避免 `latest` 在无感升级后引入不兼容变化。 |
| 提供健康检查接口 | 服务至少提供 `/healthz`，便于 compose、Traefik 和脚本判断状态。 |
| 日志输出到 stdout | 让 Docker、NAS 面板和后续日志分析可以统一收集。 |

Node.js / TypeScript 服务可以参考：

```dockerfile
FROM node:22-alpine AS deps
WORKDIR /app
COPY package*.json ./
RUN npm ci

FROM node:22-alpine AS build
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm run build

FROM node:22-alpine AS runtime
WORKDIR /app
ENV NODE_ENV=production
RUN addgroup -S aijias && adduser -S aijias -G aijias
COPY package*.json ./
RUN npm ci --omit=dev && npm cache clean --force
COPY --from=build /app/dist ./dist
USER aijias
EXPOSE 8080
CMD ["node", "dist/index.js"]
```

Python 服务可以参考：

```dockerfile
FROM python:3.12-slim AS runtime
WORKDIR /app
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1
RUN useradd --create-home --shell /usr/sbin/nologin aijias
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
USER aijias
EXPOSE 5000
CMD ["python", "-m", "inference.app"]
```

## 本地构建命令

在 Windows PowerShell 里，换行符用反引号 `` ` ``，不要用 Linux 的 `\`。

```powershell
$Version = "0.1.0"

docker buildx create --name aijias-builder --use

docker buildx build --load `
  -t "aijias/ai-assistant-gateway:$Version" `
  -t "aijias/ai-assistant-gateway:latest" `
  ./services/ai-assistant-gateway

docker buildx build --load `
  -t "aijias/service-adapter:$Version" `
  -t "aijias/service-adapter:latest" `
  ./services/service-adapter
```

Linux / NAS Shell 写法：

```bash
VERSION=0.1.0

docker buildx create --name aijias-builder --use

docker buildx build --load \
  -t "aijias/ai-assistant-gateway:${VERSION}" \
  -t "aijias/ai-assistant-gateway:latest" \
  ./services/ai-assistant-gateway

docker buildx build --load \
  -t "aijias/service-adapter:${VERSION}" \
  -t "aijias/service-adapter:latest" \
  ./services/service-adapter
```

构建完成后，把 [docker-compose/.env.example](../docker-compose/.env.example) 复制成 `.env`，并把镜像名固定到明确版本：

```env
AI_GATEWAY_IMAGE=aijias/ai-assistant-gateway:0.1.0
SERVICE_ADAPTER_IMAGE=aijias/service-adapter:0.1.0
HERMES_IMAGE=aijias/hermes-runtime:0.1.0
SKILL_REGISTRY_IMAGE=aijias/skill-registry:0.1.0
SKILL_MINER_IMAGE=aijias/skill-miner:0.1.0
PERIOD_PREDICTOR_IMAGE=aijias/period-predictor:0.1.0
```

## 按阶段启动

基础设施和成熟家庭服务可以先启动；自建镜像完成后，再打开对应 profile。

第一阶段，只启用入口和服务适配：

```powershell
docker compose `
  -f docker-compose/traefik.yml `
  -f docker-compose/core-service.yml `
  -f docker-compose/family-systems.yml `
  -f docker-compose/media.yml `
  --profile gateway `
  up -d
```

第二阶段，接入 Hermes Runtime：

```powershell
docker compose `
  -f docker-compose/traefik.yml `
  -f docker-compose/core-service.yml `
  -f docker-compose/family-systems.yml `
  -f docker-compose/media.yml `
  --profile gateway `
  --profile agent `
  up -d
```

第三阶段，启用技能演进和健康预测：

```powershell
docker compose `
  -f docker-compose/traefik.yml `
  -f docker-compose/core-service.yml `
  -f docker-compose/family-systems.yml `
  -f docker-compose/media.yml `
  -f docker-compose/ai-models.yml `
  --profile gateway `
  --profile agent `
  --profile skills `
  --profile health `
  up -d
```

如果在 NAS 的 Linux Shell 里运行，把上面的反引号换成 `\`。

## 推送到镜像仓库

如果 NAS 和开发机不是同一台机器，建议把自建镜像推送到 GHCR、Docker Hub 或 NAS 自带私有 Registry。

以 GHCR 为例：

```powershell
$Version = "0.1.0"
$Registry = "ghcr.io/your-name/aijias"

docker login ghcr.io

docker buildx build --push `
  -t "$Registry/ai-assistant-gateway:$Version" `
  -t "$Registry/ai-assistant-gateway:latest" `
  ./services/ai-assistant-gateway
```

然后在 `.env` 中改为：

```env
AI_GATEWAY_IMAGE=ghcr.io/your-name/aijias/ai-assistant-gateway:0.1.0
```

## 发布前检查清单

每个自建镜像发布前至少检查这些项：

| 检查项 | 命令或要求 |
| :--- | :--- |
| 能构建 | `docker buildx build --load -t image-name:tag ./service-dir` |
| 能启动 | `docker run --rm --env-file docker-compose/.env image-name:tag` |
| 健康接口正常 | `GET /healthz` 返回 `200`。 |
| 不含密钥 | 镜像内不复制 `.env`、token、私钥、证书原文。 |
| 日志可读 | 容器日志能说明启动、配置缺失、调用失败原因。 |
| profile 可启动 | `docker compose --profile 对应profile up -d` 能拉起依赖服务。 |

长期使用时，`latest` 只适合开发测试；家里真正运行的 `.env` 建议固定到版本号，例如 `0.1.0`、`0.2.0`，这样回滚和排查都会轻很多。