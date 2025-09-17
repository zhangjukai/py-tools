# Kafka Table Counter

一个用于消费Kafka消息并统计每个table出现次数的Python程序。

## 功能特性

- 消费Kafka JSON格式消息
- 统计每个table字段的出现次数
- 每分钟打印出现次数前10的table
- 支持多线程处理
- 完善的错误处理和日志记录

## 安装依赖

```bash
pip install -r requirements.txt
```

## 配置说明

编辑 `config.json` 文件配置Kafka连接参数：

```json
{
    "kafka": {
        "bootstrap_servers": ["localhost:9092"],
        "topic": "your_kafka_topic",
        "group_id": "table_counter_group"
    }
}
```

## 运行程序

### 方式一：使用启动脚本（推荐）
```bash
python run.py
```

### 方式二：直接运行主程序
```bash
python kafka_table_counter.py
```

启动脚本会自动检查并安装依赖。

## 消息格式要求

程序期望的Kafka消息格式为JSON，包含table字段：

```json
{
    "table": "table_name",
    "data": [...],
    "database": "...",
    // 其他字段...
}
```

## 输出示例

```
=== 2025-09-15 17:30:00 统计结果 ===
排名    表名            出现次数
----------------------------------------
1       sys_org         156
2       user_table      89
3       order_table     76
4       product_table   54
5       log_table       42
6       config_table    38
7       audit_table     31
8       temp_table      28
9       backup_table    25
10      test_table      22
========================================