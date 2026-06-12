
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
        Food[食材与菜谱<br/>Grocy + Tandoor / Mealie]
        Books[家庭账本<br/>ezBookkeeping]
        Assets[物品衣物<br/>Homebox]
        Media[照片与音乐<br/>Immich / Navidrome]
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
    class Devices device

    linkStyle default stroke:#d9c5b2,stroke-width:1.8px,color:#806b5c
```

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
              -> Grocy
              -> Mealie / Tandoor
              -> ezBookkeeping
              -> Homebox
              -> Home Assistant
              -> Immich
              -> Navidrome
              -> Period Predictor
      -> PostgreSQL
      -> Redis
      -> ntfy / 企业微信
```

这套结构把“家里的业务判断”和“成熟开源服务”分开：Traefik 只负责入口和证书；LiteLLM 只负责模型路由；Donetick、Grocy、Mealie、ezBookkeeping、Homebox、Immich 等只做各自擅长的事情；AiJiaS 自建层只负责家庭身份、权限、审计、技能与服务适配。

自建镜像的目录组织、Dockerfile 模板、构建命令和发布检查清单见 [self-built-images.md](self-built-images.md)。

## 镜像建设策略

| 类型 | 服务 | 策略 |
| :--- | :--- | :--- |
| 成熟底座 | Traefik、PostgreSQL、Redis、PgBouncer、ntfy、LiteLLM | 直接拉取官方或成熟镜像，稳定后固定版本或 digest。 |
| 家庭子系统 | Donetick、Grocy、Mealie、ezBookkeeping、Homebox、Immich、Navidrome | 直接使用上游镜像，默认只在内网暴露。 |
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
2. 启动家庭子系统：Donetick / Grocy / Mealie / ezBookkeeping / Homebox / Immich / Navidrome
3. 自建并启用 AI Assistant Gateway
4. 自建并启用 Service Adapter
5. 接入 Hermes Runtime
6. 再做 Skill Registry / Skill Miner / Period Predictor
```

## 自建镜像边界

`AI Assistant Gateway` 不只是普通反向代理，它需要理解企业微信身份、家庭成员、敏感操作确认、审计日志和回复链路；这部分不能完全交给 Traefik、Kong 或 APISIX。

`Service Adapter` 也不只是 API 转发，它负责把不同家庭系统的 API 统一成稳定工具，例如 `create_expense`、`create_task`、`query_inventory`、`call_home_assistant`。这样 Hermes 不需要直接面对每个系统的复杂 API，也不会绕过风险策略直接修改账本、门锁或健康数据。
