# AiJiaS 家庭技能本

这里保存 Hermes 可以调用的家庭 Skills 的 **API 接口定义**。
YAML 文件定义参数校验、风险等级、确认策略，
供 Service Adapter 和 AI Assistant Gateway 使用。

> Hermes 自身的 SKILL.md（行为层）由 Hermes Agent 自动从使用日志总结生成，
> 与本目录中的 API 定义互补而非替代。

## 目录约定

| 目录 | 用途 |
|------|------|
| `registry/` | 已人工确认的正式技能 API 定义 |
| `pending/` | Skill Miner 生成的候选技能草案，默认不执行 |
| `policies/` | 家庭级权限、确认和风险规则 |
| `templates/` | 新技能 manifest 模板 |

## Skill YAML 字段说明

| 字段 | 必需 | 说明 |
|------|------|------|
| `id` | ✅ | 唯一标识，格式 `domain.action` |
| `name` | ✅ | 中文名称 |
| `service` | ✅ | 目标微服务名 |
| `action` | ✅ | 调用的具体动作 |
| `description` | ✅ | 一句话描述 |
| `risk` | ✅ | `low` / `medium` / `high` |
| `input` | ✅ | 参数声明，`*`=必填，`[v]`=默认值，`enum[a,b]`=枚举 |
| `confirm` | ✅ | 执行前是否需确认（或说明原因） |
| `redlines` | ✅ | 安全红线列表，触发时系统硬拦截 |

## 文件格式

- **单技能文件**（1:1 服务映射）：直接写字段，如 `finance.yaml`、`health-care.yaml`
- **多技能文件**（同一服务多个 action）：用 `skills:` 列表，如 `mealie.yaml`、`family-tasks.yaml`、`media-memory.yaml`

## 安全原则

1. 模型不能直接写数据库、账本、门锁或健康结论
2. 所有动作通过 `Service Adapter` 调用内部服务
3. 涉及钱、门锁、健康、隐私的操作必须确认
4. `pending/` 里的技能只能审阅，不能执行
