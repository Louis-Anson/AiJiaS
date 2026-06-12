# AiJiaS 家庭技能本

这里保存 Hermes 可以调用的家庭 Skills。它是 AiJiaS 自己的 Skill Registry 数据源。

## 目录约定

- `registry/`: 已人工确认、可以被 Hermes 读取的正式技能。
- `pending/`: Skill Miner 从日常使用日志里总结出的候选技能草案，默认不能上线。
- `policies/`: 家庭级权限、确认和风险规则。
- `templates/`: 新技能 manifest 模板。

## 安全原则

1. 模型不能直接写数据库、账本、门锁或健康结论。
2. 所有动作必须通过 `Service Adapter` 调用内部服务。
3. 涉及钱、门锁、健康、隐私和批量修改的技能，必须配置 `confirmation.required: true`。
4. `pending/` 里的技能只能被审阅，不能被 Hermes 自动执行。
