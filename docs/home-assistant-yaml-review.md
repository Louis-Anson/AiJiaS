# Home Assistant YAML 作用确认

## 当前文件职责

| 文件 | 作用 | 当前调整 |
| :--- | :--- | :--- |
| `configuration.yaml` | Home Assistant 主入口配置，负责加载其他 YAML、配置反向代理信任、接入 recorder 数据库。 | 增加 `default_config`、时区/单位/国家设置；将 `customize` 放入 `homeassistant` 节点；recorder 改为 `!secret recorder_db_url`。 |
| `sensors.yaml` | 自定义传感器配置。 | 保留 `period-predictor` REST 传感器，补充 `unique_id`、扩展属性和更安全的 Jinja 引号。 |
| `input_datetime.yaml` | 时间输入实体。 | 新增 `input_datetime.last_period_start`，供经期预测传感器读取。 |
| `automations.yaml` | HA 自动化规则。 | 暂时留空；后续可加入经期前提醒、洗衣完成提醒、临期食材通知等自动化。 |
| `customize.yaml` | 实体展示名与图标定制。 | 为经期预测传感器和上次经期开始日期补充友好名称与图标。 |
| `secrets.example.yaml` | secrets 示例文件。 | 新增 recorder 数据库连接示例；真实 `secrets.yaml` 不应提交真实密码。 |

## 修改方案确认

1. HAOS 仍然作为独立虚拟机运行，通过桥接网络接入家庭内网。
2. Home Assistant 不直接暴露公网，由 AI Gateway / Service Adapter 使用长期访问令牌调用。
3. `period-predictor` 作为内网 Docker 服务，供 HA REST sensor 和 Hermes 健康 Skill 共同读取。
4. 涉及门锁、安防、大功率设备的 HA 调用，必须通过 Skill Registry 的高风险确认策略。
5. 后续若要让 HA recorder 连接 NAS Docker 内的 PostgreSQL，需要确保 HAOS 能解析并访问 `postgres` 或改成 NAS 内网 IP。