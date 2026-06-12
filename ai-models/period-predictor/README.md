# Period Predictor

女性健康预测服务的预留目录。

第一阶段以规则引擎和可解释统计模型为主，不训练专属大语言模型。服务应提供：

- `POST /predict`: 根据上次经期、周期历史、症状和睡眠等输入返回预测日期、置信度和护理建议。
- `GET /health`: 给 Home Assistant / Gateway 做健康检查。

数据原则：健康数据默认保存在家庭内网 PostgreSQL 中，敏感字段需要单独权限控制和备份策略。
