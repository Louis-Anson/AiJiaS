
## 🗓️ 需求列表

<div align="center">

[![Project Status](https://img.shields.io/badge/Status-规划中-orange?style=flat-square)]()

</div>

| 需求层级 | 模块/子系统 | 功能描述 | 状态 | 优先级 | 推荐工具/方案 | 部署位置 | 关键配置/备注 |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 统一交互入口 | 企业微信/微信机器人对话入口 | 自然语言指令下达与结果反馈 | 未开发 | 高 | 企业微信应用/机器人 + AI Assistant Gateway | NAS Docker + 企业微信后台 | 对外只暴露 AI Assistant Gateway；负责企业微信验签、用户映射、限流、审计和高风险操作确认 |
| 统一交互入口 | 微信小程序前端 | 图形化查看数据、图表、手动录入 | 未开发 | 高 | uni-app 开发 + AI Assistant Gateway | NAS + 微信小程序后台 | 小程序仅调用统一业务网关，不直接暴露内部子系统 |
| AI调度中枢层 | 主 Agent 管家 | 解析自然语言、管理长期记忆、调用 Skills、拆解多步骤任务 | 未开发 | 高 | Hermes Agent | NAS Docker | 旧双 Agent 试用路线已放弃；Dify 暂不引入核心架构；Hermes 作为长期 AI 管家主线 |
| AI调度中枢层 | AI 业务网关 | 统一承接微信/小程序请求，完成鉴权、路由、审计、权限控制和执行确认 | 未开发 | 高 | 自建 AI Assistant Gateway | NAS Docker | Hermes 不直接暴露公网；所有内部 API 调用通过 Gateway/Service Adapter 管控 |
| AI调度中枢层 | AI 模型接口管理 | 统一管理 GPT、Claude、Gemini、DeepSeek、Qwen 等模型，提供路由、fallback、成本控制和日志 | 未开发 | 高 | LiteLLM | NAS Docker | 以逻辑模型名区分 daily_zh、tool_strict、planner、skill_evolver、deep_reasoner；不再使用旧模型网关作为主线 |
| AI调度中枢层 | 统一通知推送 | 将各子系统事件推送到微信 | 未开发 | 高 | ntfy + AI Assistant Gateway → 企业微信 | NAS Docker | 系统通知走企业微信主动推送；Hermes 负责生成自然语言摘要 |
| AI调度中枢层 | 家庭关怀引擎 | 评估家庭成员的任务负担、情绪、睡眠、经期和疲惫状态，生成温柔提醒与分担建议 | 未开发 | 高 | Hermes + Health Signals + Gateway + 企业微信 | NAS Docker | 不只管理事务，也关注家庭平衡；支持对伴侣、自己和群聊发送关怀提醒 |
| AI调度中枢层 | 可复用 Skill Registry | 统一保存技能定义、参数 schema、权限、确认策略、测试样例和版本历史 | 未开发 | 高 | 自建 Skill Registry | NAS Docker + PostgreSQL | Dify 不引入时必须补齐的核心能力；Hermes 从 Registry 读取可用 Skills |
| AI调度中枢层 | Skills 自动总结与进化 | 从日常微信调用、工具调用和用户修正中总结候选 Skills | 未开发 | 高 | Skill Miner + LLM 批处理 + 人工审批 | NAS Docker | 自动发现、自动草拟、自动测试；不自动扩权，不自动上线高风险技能 |
| AI调度中枢层 | 内部服务适配层 | 屏蔽各子系统 API 差异，向 Agent 暴露稳定工具接口 | 未开发 | 高 | Service Adapter | NAS Docker | Donetick/Mealie/Firefly III/Homebox/HA 等均通过 adapter 调用 |
| 家庭任务系统 | 菜谱录入与点餐 | 菜谱管理、膳食计划、根据食材推荐 | 未开发 | 高 | Tandoor Recipes | NAS Docker | 内网服务；与 Mealie 食材库存联动 |
| 食物状态系统 | 库存管理 | 品类、数量、采购日期、保质期管理 | 未开发 | 高 | Mealie + Homebox | NAS Docker | Mealie 管理食材库存和保质期；Homebox 管理物品资产；内网服务 |
| 食物状态系统 | 烹饪建议 | 根据现有食材推荐可制作菜肴 | 未开发 | 高 | Hermes Skill 调用 Mealie + Homebox API | NAS Docker | 通过 Service Adapter 调用内网 API；已选用 Mealie 作为菜谱和食材管理方案 |
| 家庭资产管理 | 衣物/鞋帽/床上用品管理 | 记录购买时间、使用状态、清洗周期，支持特殊衣物（冲锋衣/滑雪服）维护提醒 | 未开发 | 高 | Homebox | NAS Docker | 通过 API 与 AI 调度中枢集成，支持多用户；镜像：sysadminsmedia/homebox |
| 家用记账系统 | 收支记录与统计 | 收入/支出分类记录、图表分析、实时查询 | 未开发 | 高 | Firefly III | NAS Docker | 内网服务；支持微信/支付宝账单导入 |
| 家用记账系统 | 微信触发记账 | 通过微信消息自动添加记账条目 | 未开发 | 高 | Hermes Skill + Firefly III API | NAS Docker | 通过 Service Adapter 写入；大额、付款人不明确、分类低置信度时需要二次确认 |
| 多媒体系统 | 音乐下载与搜刮 | 聚合 10+ 平台搜索下载无损音乐，支持歌单导入与加密解密 | 未开发 | 中 | Go Music DL | NAS Docker | 提供 Web 界面，与 Navidrome 共享音乐目录 |
| 多媒体系统 | 私人音乐服务器 | 搭建私人曲库，多设备在线播放，支持 AirPlay 投送 HomePod | 未开发 | 中 | Navidrome | NAS Docker | 兼容 Subsonic API，通过 Hermes Skill 触发播放 |
| 多媒体系统 | 照片备份与管理 | 自动备份手机照片，支持人脸识别与多用户 | 未开发 | 高 | Immich | NAS Docker | 替代 Google Photos，数据完全本地化 |
| 智能家居控制 | 格力空调控制 | 开关、调温、模式切换 | 未开发 | 低 | HA + Gree 集成 | 集成于 HA | 局域网本地控制 |
| 智能家居控制 | 美的洗衣机/烘干机控制 | 启动/暂停、模式选择 | 未开发 | 低 | HA + Midea AC LAN 集成 | 集成于 HA | 可能需降级固件 |
| 安防监控接入 | 可视门铃/监控本地存储 | 视频流 24 小时录制到 NAS | 未开发 | 低 | Reolink / Aqara G410 (支持 RTSP) | 自家 | 通过 Frigate 进行 AI 分析 |
| 安防监控接入 | AI 人脸识别与联动 | 区分家人/陌生人并触发自动化 | 未开发 | 低 | Frigate + HA | NAS Docker (需 SSD) | 本地 AI 处理；可联动通知 |
| 健康监测集成 | 女性健康数据采集 | 持久化记录体温、饮食、作息、睡眠、心情、天气、季节、经期、痛感和 Apple Watch 指标 | 未开发 | 高 | Health Auto Export + Apple Health + 微信手动记录 + 天气 API | NAS + iPhone | 先建高质量个人时间序列数据库，为多年后训练个人模型做准备 |
| 健康监测集成 | 经期与痛感预测 | 预测周期规律、痛感风险、PMS 风险，并输出提前预防建议 | 未开发 | 高 | 规则引擎 + 统计模型 + LLM 解释 | NAS Docker | 第一阶段不训练大模型；用可解释规则/统计预测，积累 6-12 个月以上数据后再评估轻量个人模型 |
| 健康监测集成 | 中医养生与西医边界规则 | 结合中医生活调理和西医风险红线，生成饮食、作息、热敷、运动和就医提醒 | 未开发 | 高 | 健康规则库 + Hermes 健康 Skill | NAS Docker | 大模型只做解释和规划，不做医学诊断；剧烈疼痛、异常出血、怀孕期腹痛/出血等触发固定就医规则 |
| 健康监测集成 | 备孕/孕期营养与规划 | 备孕、怀孕期间饮食、营养、产检、体重和异常症状提醒 | 未开发 | 高 | Hermes 健康 Skill + 规则库 + Donetick | NAS Docker | 涉及药物、出血、剧痛、发热、胎动异常等仅提示联系医生，不自动给治疗建议 |
| 健康监测集成 | 个人健康预测模型 | 多年数据积累后训练个人专属周期、痛感、PMS 和营养风险模型 | 规划中 | 中 | LightGBM/XGBoost/时间序列模型，必要时再评估 LSTM/TFT | NAS Docker/ai-models | 不训练专属 LLM；优先训练可解释小模型，并保留模型版本、训练数据范围和评估指标 |
| 健康监测集成 | 经期提醒与养生茶饮任务 | 经期前提醒、痛感高风险提醒、养生茶饮/热敷/休息任务闭环 | 未开发 | 高 | Hermes → Donetick/HA/企业微信 | NAS Docker | 任务闭环管理；建议和执行均记录反馈，用于后续个性化模型训练 |
| 家庭关系与平衡 | 伴侣状态关怀提醒 | 当一方加班过多、任务堆积、心情烦躁或睡眠不好时，自动提醒另一方减负、分担和安抚 | 未开发 | 高 | Family Care Engine + Hermes + 企业微信 | NAS Docker | 面向夫妻共同使用；提醒以温柔、非指责方式输出，支持群聊与私聊 |
| 家庭关系与平衡 | 生理期前后协作提醒 | 当一方临近生理期、疲惫、睡眠差或烦躁时，提醒另一方提前接手家务和降低压力 | 未开发 | 高 | Family Care Engine + Health Signals + Donetick/企业微信 | NAS Docker | 强调照顾和协作，不做医学诊断；必要时只输出休息与就医提醒 |
| 家庭关系与平衡 | 家庭成员扩展 | 后续支持将双方父母纳入家庭成员体系，按角色控制可见范围和提醒内容 | 未开发 | 中 | Gateway 成员映射 + 角色权限 | NAS Docker + 企业微信后台 | 父母默认低频关怀模式，避免暴露过多家庭内部细节 |
| 数据存储层 | 统一数据库 | 存储各子系统结构化数据、交互日志、工具调用日志、Skill 元数据和健康时间序列 | 未开发 | 高 | PostgreSQL (主) + PgBouncer + SQLite (子系统内置) | NAS Docker (SSD 加速) | 健康数据、账本、用户行为日志需单独权限控制和备份策略 |
| 数据存储层 | AI 交互与训练数据归档 | 保存微信对话、意图识别、参数抽取、工具调用、执行结果、用户修正和 Skill 演化记录 | 未开发 | 高 | PostgreSQL + 对象存储/文件归档 | NAS Docker/HDD | 为 Skills 自动总结和未来个人模型训练提供可追溯数据；敏感字段需脱敏/访问控制 |
| 硬件平台 | NAS 设备 | QNAP TS-464C2: N5095/8GB RAM/4TB HDD + 128GB SSD | 已完成 | 高 | QNAP Container Station + Virtualization Station | 本地 | SSD 用于 Docker 热数据；HDD 用于存储 |
| 扩展性设计 | 新需求接入方式 | 任意带 API 的服务均可加入家庭 AI 系统 | 未开发 | 高 | Service Adapter + Skill Registry + Hermes Skill | NAS Docker | 遵循“部署服务 → 写 adapter → 定义 Skill manifest/schema/权限 → 测试 → 发布”的标准流程 |
