
# 系统架构设计图

## AiJiaS / 家物 OS 总体架构

> 最新主线：对外只开放 AI Assistant Gateway；Hermes 负责长期记忆与任务拆解；LiteLLM 负责多模型路由；所有家庭服务只在内网通过 Skill Registry 与 Service Adapter 被安全调用。

```mermaid
flowchart TB
    %% ===== Everyday entrances =====
    subgraph Touchpoints[日常入口]
        direction LR
        WeChat[企业微信 / 微信<br/>自然语言指令]
        MiniApp[微信小程序<br/>数据查看与手动录入]
        WebAdmin[网页管理后台<br/>家庭设置与长期回顾]
    end

    %% ===== Single safe entrance =====
    subgraph Edge[对外只开这一扇门]
        direction LR
        Traefik[Traefik<br/>HTTPS / SSL / 反向代理]
        Gateway[AI Assistant Gateway<br/>验签 / 身份映射 / 限流 / 审计 / 高危确认]
        Manager[Traefik Manager<br/>内网可视化运维]
    end

    %% ===== AI brain =====
    subgraph Brain[家庭 AI 核心]
        direction LR
        Hermes[Hermes AI 管家<br/>对话 / 记忆 / 任务拆解 / 微代理]
        Skills[Skill Registry<br/>技能定义 / 参数 Schema / 权限 / 确认策略]
        LiteLLM[LiteLLM 模型中继<br/>GPT / Claude / Gemini / DeepSeek / Qwen]
    end

    subgraph Models[外部或本地模型池]
        direction LR
        Daily[daily_zh<br/>日常低成本模型]
        Planner[planner<br/>规划与总结模型]
        Evolve[skill_evolver<br/>离线技能进化模型]
    end

    Adapter[Service Adapter<br/>把各系统 API 封装成安全、稳定、可审计的家庭工具]

    %% ===== Internal capability bus =====
    subgraph HomeServices[内网家庭服务群 - Docker / VM]
        direction LR
        Tasks[家务任务<br/>Donetick]
        Food[食材与菜谱<br/>Mealie]
        Books[家庭账本<br/>Firefly III]
        Assets[物品衣物<br/>Homebox]
        Media[照片与音乐<br/>Immich / Navidrome]
        PwdMgr[密码管理<br/>Vaultwarden]
        Health[女性健康时间线<br/>规则引擎 + 统计模型]
        HA[智能家居中枢<br/>Home Assistant OS VM]
    end

    subgraph DataLayer[家庭记忆与演进底座]
        direction LR
        DB[(PostgreSQL<br/>业务数据 / 日志 / 健康时间线 / 技能元数据)]
        Files[(本地文件存储<br/>照片 / 音乐 / 备份 / 附件)]
        Predictor[个人健康预测模型<br/>长期数据成熟后训练]
    end

    subgraph Notify[主动提醒]
        direction LR
        Ntfy[ntfy<br/>系统事件通知]
        WeComBot[企业微信推送<br/>自然语言摘要]
    end

    subgraph FamilyCare[家庭关怀引擎]
        direction LR
        CareSignal[状态信号输入<br/>任务堆积 / 加班 / 睡眠 / 情绪 / 经期 / 疲惫]
        BalanceEval[平衡评估<br/>减负 / 分担 / 安抚 / 延后 / 休息]
        CareNotify[关怀提醒输出<br/>发给伴侣 / 自己 / 群聊]
    end

    Devices[家庭设备<br/>空调 / 洗衣机 / 门锁 / 传感器]

    %% ===== Clean top-down flows =====
    WeChat --> Traefik
    MiniApp --> Traefik
    WebAdmin --> Traefik
    Traefik --> Gateway
    Manager -.内网管理.-> Traefik

    Gateway --> Hermes
    Hermes <--> Skills
    Hermes --> LiteLLM
    LiteLLM --> Models
    Skills --> Adapter

    Adapter --> Tasks
    Adapter --> Food
    Adapter --> Books
    Adapter --> Assets
    Adapter --> Media
    Adapter --> Health
    Adapter --> HA

    Tasks --> DB
    Food --> DB
    Books --> DB
    Assets --> DB
    Health --> DB
    HA --> DB
    Media --> Files
    Files --> DB

    HA --> Devices
    Health --> Predictor
    DB --> Predictor

    Gateway --> Ntfy
    Hermes --> Ntfy
    Ntfy --> WeComBot
    WeComBot -.回复与提醒.-> WeChat

    DB -.使用日志与纠错样本.-> Evolve
    Evolve -.候选技能草案.-> Skills

    Hermes --> CareSignal
    Health --> CareSignal
    Tasks --> CareSignal
    CareSignal --> BalanceEval
    BalanceEval --> CareNotify
    CareNotify --> Gateway
    CareNotify --> Ntfy
    CareNotify -.家庭关怀提示.-> WeComBot

    %% ===== Warm visual style =====
    classDef touch fill:#fff5f5,stroke:#fecdd3,color:#4a3728,stroke-width:1.4px
    classDef edge fill:#fffbeb,stroke:#fed7aa,color:#4a3728,stroke-width:1.6px
    classDef brain fill:#faf5ff,stroke:#d8b4fe,color:#4a3728,stroke-width:1.8px
    classDef model fill:#eff6ff,stroke:#bfdbfe,color:#4a3728,stroke-width:1.4px
    classDef service fill:#f0fdf4,stroke:#bbf7d0,color:#4a3728,stroke-width:1.4px
    classDef data fill:#f8fafc,stroke:#cbd5e1,color:#4a3728,stroke-width:1.4px
    classDef notify fill:#ecfeff,stroke:#a5f3fc,color:#4a3728,stroke-width:1.4px
    classDef device fill:#fff1f2,stroke:#fecdd3,color:#4a3728,stroke-width:1.4px

    class WeChat,MiniApp,WebAdmin touch
    class Traefik,Gateway,Manager edge
    class Hermes,Skills,LiteLLM brain
    class Daily,Planner,Evolve model
    class Tasks,Food,Books,Assets,Media,Health,HA service
    class DB,Files,Predictor data
    class Ntfy,WeComBot notify
    class CareSignal,BalanceEval,CareNotify notify
    class Devices device

    linkStyle default stroke:#d9c5b2,stroke-width:1.8px,color:#806b5c
```

## Docker 网络拓扑（三层隔离）

> 三层网络实现数据库隔离：`aijias-public` 对外路由、`aijias-internal` 主数据库专用、`aijias-immich` Immich 内部专用。

```mermaid
flowchart TB
    subgraph Internet["🌐 公网"]
    end

    subgraph TPublic["aijias-public — 路由层"]
        direction LR
        T["Traefik :443"] --> GW["hermes-agent :3000"]
        T --> IM["immich-server :2283"]
        T --> VW["vaultwarden :80"]
        T --> ST["sillytavern :8000"]
        T --> TK["traefik-manager :8081"]
        NT["ntfy"] -.->|traefik.enable=false| T
        DT["donetick"] -.->|traefik.enable=false| T
        HB["homebox"] -.->|traefik.enable=false| T
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

    class T,GW,IM,VW,ST,TK,NT,DT,HB pub
    class PG,RD,PB db
    class IPG,IRD,ML imm
    class HA,LL,ML2,FF,LB app
```

### 网络隔离规则

| 网络 | 创建方式 | 成员 | 可以看到什么 |
|------|---------|------|------------|
| `aijias-public` | 手动 `docker network create` | Traefik + 需要对外暴露的服务 + 无 DB 依赖的轻量服务 | 所有同网络容器的端口 |
| `aijias-internal` | `database.yml` 自动创建 | PostgreSQL、Redis、PgBouncer + 需要主 DB 的应用 | 主数据库端口 5432/6379/6432 |
| `aijias-immich` | `media.yml` 自动创建 | 仅 Immich 4 个容器（server、postgres、redis、ml） | Immich 专属数据库端口 |

> **关键原则**：`immich-postgres` 不在 `aijias-internal` 网络中，主 PostgreSQL 不在 `aijias-immich` 中，两者物理隔离。Immich 升级/崩溃不影响家庭账本和菜谱数据。

## 长期最佳架构

AiJiaS 的长期架构原则是：**成熟基础设施用现成镜像，家庭专属逻辑自建镜像，自建服务尽量小而稳定，并通过 profiles 分阶段启用**。

```text
Traefik
  -> AI Assistant Gateway       自建，唯一公网业务入口
      -> Hermes Runtime         自建封装或官方镜像
          -> LiteLLM            官方镜像，多模型路由
          -> Skill Registry     后期自建，技能版本与权限管理
          -> Service Adapter    自建，统一封装家庭系统 API
              -> Donetick
              -> Mealie
              -> Firefly III
              -> Homebox
              -> Home Assistant
              -> Immich
              -> Navidrome
              -> Period Predictor
              -> Vaultwarden         Bitwarden 兼容密码管理器
      -> ntfy / 企业微信
```

这套结构把“家里的业务判断”和“成熟开源服务”分开：Traefik 只负责入口和证书；LiteLLM 只负责模型路由；Donetick、Mealie、Firefly III、Homebox、Immich 等只做各自擅长的事情；AiJiaS 自建层只负责家庭身份、权限、审计、技能与服务适配。

自建镜像的目录组织、Dockerfile 模板、构建命令和发布检查清单见 [self-built-images.md](self-built-images.md)。

## 镜像建设策略

| 类型 | 服务 | 策略 |
| :--- | :--- | :--- |
| 成熟底座 | Traefik、PostgreSQL、Redis、PgBouncer、ntfy、LiteLLM | 直接拉取官方或成熟镜像，稳定后固定版本或 digest。 |
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
1. 先启动基础设施：Traefik / PostgreSQL / Redis / PgBouncer / LiteLLM / ntfy
2. 启动家庭子系统：Donetick / Mealie / Firefly III / Homebox / Immich / Navidrome / Vaultwarden
3. 自建并启用 AI Assistant Gateway
4. 自建并启用 Service Adapter
5. 接入 Hermes Runtime
6. 再做 Skill Registry / Skill Miner / Period Predictor
## 自建镜像边界

`AI Assistant Gateway` 不只是普通反向代理，它需要理解企业微信身份、家庭成员、敏感操作确认、审计日志和回复链路；这部分不能完全交给 Traefik、Kong 或 APISIX。

`Service Adapter` 也不只是 API 转发，它负责把不同家庭系统的 API 统一成稳定工具，例如 `create_expense`、`create_task`、`query_inventory`、`call_home_assistant`。这样 Hermes 不需要直接面对每个系统的复杂 API，也不会绕过风险策略直接修改账本、门锁或健康数据。
