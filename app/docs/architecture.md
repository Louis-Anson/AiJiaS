
> 2026.06 当前主线：Hermes Agent（Ubuntu Server VM）原生支持企业微信/微信/飞书 Gateway，无需自建 AI Assistant Gateway 和 Service Adapter。
n## AiJiaS 当前架构

```text
┌──────────────────────────────────────────────────────────┐
│  QNAP NAS (192.168.3.195) — 裸金属 Docker               │
│                                                          │
│  ┌── Docker ──────────────────────────────────────┐      │
│  │ LiteLLM :4000 ←── 多模型路由（VM 通过 NAS_IP 访问）│      │
│  │ PostgreSQL :5432 / PgBouncer :6432               │      │
│  │ Redis :6379                                      │      │
│  │ Donetick / Mealie / Firefly / Homebox / Immich   │      │
│  │ Navidrome / SillyTavern / Vaultwarden / ntfy     │      │
│  └──────────────────────────────────────────────────┘      │
│                                                          │
│  ┌── Ubuntu Server VM ────────────────────────────┐       │
│  │ Hermes Agent (192.168.3.198)                   │       │
│  │   ├─ Profile: family  ← 家庭管家               │       │
│  │   │   └─ Gateway: WeCom（企业微信）             │       │
│  │   └─ Profile: wife    ← 老婆个人助理            │       │
│  │       └─ Gateway: WeChat（微信）                │       │
│  └──────────────────────────────────────────────────┘      │
│                                                          │
│  ┌── VM（Virtualization Station）─────────────────┐      │
│  │ Home Assistant OS (192.168.3.196)               │       │
│  └──────────────────────────────────────────────────┘      │
└──────────────────────────────────────────────────────────┘
```
> Hermes 自身具备对话、记忆、技能自动发现、Gateway 多平台接入。

## Docker 网络拓扑（三层隔离）

> 三层网络实现数据库隔离：`aijias-public` 对外路由、`aijias-internal` 主数据库专用、`aijias-immich` Immich 内部专用。

```mermaid
flowchart TB
    subgraph Internet["🌐 公网"]
    end

    subgraph TPublic["aijias-public — 路由层"]
        direction LR
        T --> IM["immich-server :2283"]
        T --> VW["vaultwarden :80"]
        T --> ST["sillytavern :8000"]
    end

    subgraph Internal["internal — 主数据库层"]
        direction LR
        PG["(PostgreSQL :5432)"]
        RD["(Redis :6379)"]
        PB["PgBouncer :6432"]
    end

    subgraph ImmichNet["aijias-immich — 照片服务专属"]
        direction LR
        IPG["immich-postgres
PG17+pgvector"]
        IRD["immich-redis
LRU 临时队列"]
        ML["immich-machine-learning
人脸识别模型"]
    end

    subgraph Apps["需要主数据库的应用"]
        direction LR
        HA["hermes-agent"]
        LL["litellm"]
        ML2["mealie"]
        FF["firefly"]
        LB["lubelogger"]
    end

    Internet --> T
    HA --> PB
    LL --> PG
    LL --> RD
    ML2 --> PG
    FF --> PG
    LB --> PG
    IM --> IPG
    IM --> IRD
    IM --> ML

    classDef pub fill:#e8f5e9,stroke:#81c784,color:#333
    classDef db fill:#fff3e0,stroke:#ffb74d,color:#333
    classDef imm fill:#e3f2fd,stroke:#64b5f6,color:#333
    classDef app fill:#f3e5f5,stroke:#ba68c8,color:#333

### 网络隔离规则

| 网络 | 创建方式 | 成员 | 可以看到什么 |
|------|---------|------|------------|
| `aijias-internal` | `database.yml` 自动创建 | PostgreSQL、Redis、PgBouncer + 需要主 DB 的应用 | 主数据库端口 5432/6379/6432 |
| `aijias-immich` | `media.yml` 自动创建 | 仅 Immich 4 个容器（server、postgres、redis、ml） | Immich 专属数据库端口 |

> **关键原则**：`immich-postgres` 不在 `aijias-internal` 网络中，主 PostgreSQL 不在 `aijias-immich` 中，两者物理隔离。Immich 升级/崩溃不影响家庭账本和菜谱数据。

## 长期最佳架构

```text
  -> Hermes Agent (Ubuntu VM)    Agent API :3000 + Dashboard :9119
      ├── Gateway (WeCom/WeChat/Feishu/ntfy)  原生支持 21+ 平台
      ├── Skills (built-in)                   自动发现 + 人工确认
      └── Memory (PostgreSQL)                 长期家庭记忆
  -> LiteLLM (Docker)           多模型路由，VM 通过 NAS_IP:4000 访问
  -> PostgreSQL / Redis (Docker) VM 通过 NAS_IP:5432/6379 访问
  -> Donetick / Mealie / Firefly III / Homebox (Docker)
  -> Immich / Navidrome (Docker)
  -> Home Assistant (VM)
  -> Vaultwarden (Docker)

Hermes 官方 Gateway 自带企业微信/微信/飞书接入、家庭成员权限、审计日志，无需自建 AI Assistant Gateway 和 Service Adapter。

自建镜像的目录组织、Dockerfile 模板、构建命令和发布检查清单见 [self-built-images.md](self-built-images.md)。

## 镜像建设策略

| 类型 | 服务 | 策略 |
| :--- | :--- | :--- |
| 家庭子系统 | Donetick、Mealie、Firefly III、Homebox、Immich、Navidrome | 直接使用上游镜像，默认只在内网暴露。 |
| 家庭子系统 | Vaultwarden | 直接使用上游镜像，默认只在内网暴露。 |
| 必须自建 | AI Assistant Gateway、Service Adapter | 长期必须自建，因为它们包含家庭成员映射、权限、审计、高危确认和统一 API 适配。 |
| 可后期自建 | Hermes Runtime、Skill Registry、Skill Miner、Period Predictor | 用 profiles 延后启用，避免未完成镜像阻塞基础设施启动。 |

## 分阶段启动策略

默认启动只应该包含已经稳定可拉取的基础设施，以及已经完成构建的自建服务。尚未完成的模块通过 Docker Compose profiles 控制：

| Profile | 服务 | 何时启用 |
| :--- | :--- | :--- |
| `gateway` | `ai-gateway`、`service-adapter` | 完成第一版企业微信入口和内部 API 适配后启用。 |
| `agent` | `hermes-agent` | Hermes Runtime 镜像确定后启用。 |
| `skills` | `skill-registry`、`skill-miner` | 技能目录稳定、有真实调用日志后启用。 |
| `health` | `period-predictor` | 健康记录数据结构稳定后启用。 |
| `local-llm` | `ollama` | NAS 性能允许并需要本地模型时启用。 |

推荐落地顺序：

```text
2. 启动家庭子系统：Donetick / Mealie / Firefly III / Homebox / Immich / Navidrome / Vaultwarden
3. 自建并启用 AI Assistant Gateway
4. 自建并启用 Service Adapter
5. 接入 Hermes Runtime
6. 再做 Skill Registry / Skill Miner / Period Predictor
## 自建镜像边界

`AI Assistant Gateway` 不只是普通反向代理，它需要理解企业微信身份、家庭成员、敏感操作确认、审计日志和回复链路；这部分不能完全交给 Traefik、Kong 或 APISIX。

`Service Adapter` 也不只是 API 转发，它负责把不同家庭系统的 API 统一成稳定工具，例如 `create_expense`、`create_task`、`query_inventory`、`call_home_assistant`。这样 Hermes 不需要直接面对每个系统的复杂 API，也不会绕过风险策略直接修改账本、门锁或健康数据。
