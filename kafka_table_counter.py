#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import json
import time
from collections import defaultdict
from datetime import datetime
from kafka import KafkaConsumer
from threading import Thread, Event
import logging

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class KafkaTableCounter:
    def __init__(self, bootstrap_servers, topic, group_id):
        self.bootstrap_servers = bootstrap_servers
        self.topic = topic
        self.group_id = group_id
        self.table_counter = defaultdict(int)
        self.stop_event = Event()
        
        # 创建Kafka消费者
        self.consumer = KafkaConsumer(
            topic,
            bootstrap_servers=bootstrap_servers,
            group_id=group_id,
            auto_offset_reset='earliest',
            enable_auto_commit=True,
            value_deserializer=lambda x: json.loads(x.decode('utf-8'))
        )
        
    def start_consuming(self):
        """启动消费消息"""
        logger.info(f"开始消费Kafka主题: {self.topic}")
        
        # 启动统计打印线程
        printer_thread = Thread(target=self._print_statistics)
        printer_thread.daemon = True
        printer_thread.start()
        
        try:
            for message in self.consumer:
                if self.stop_event.is_set():
                    break
                    
                try:
                    self._process_message(message.value)
                except Exception as e:
                    logger.error(f"处理消息时出错: {e}")
                    
        except KeyboardInterrupt:
            logger.info("收到中断信号，停止消费")
        except Exception as e:
            logger.error(f"消费过程中发生错误: {e}")
        finally:
            self.stop()
    
    def _process_message(self, message):
        """处理单条消息"""
        if not isinstance(message, dict):
            return
            
        # 提取table字段
        table_name = message.get('table')
        if table_name:
            self.table_counter[table_name] += 1
    
    def _print_statistics(self):
        """每分钟打印统计结果"""
        while not self.stop_event.is_set():
            time.sleep(60)  # 等待60秒
            
            if not self.table_counter:
                continue
                
            # 获取前10个出现次数最多的table
            sorted_tables = sorted(
                self.table_counter.items(), 
                key=lambda x: x[1], 
                reverse=True
            )[:10]
            
            current_time = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            print(f"\n=== {current_time} 统计结果 ===")
            print("排名\t表名\t\t出现次数")
            print("-" * 40)
            
            for i, (table, count) in enumerate(sorted_tables, 1):
                print(f"{i}\t{table:<15}\t{count}")
            
            print("=" * 40)
    
    def stop(self):
        """停止消费"""
        self.stop_event.set()
        self.consumer.close()
        logger.info("Kafka消费者已停止")

def load_config():
    """从配置文件加载配置"""
    try:
        with open('config.json', 'r', encoding='utf-8') as f:
            config = json.load(f)
        return config
    except FileNotFoundError:
        logger.warning("配置文件不存在，使用默认配置")
        return {
            'kafka': {
                'bootstrap_servers': ['localhost:9092'],
                'topic': 'your_kafka_topic',
                'group_id': 'table_counter_group'
            }
        }
    except json.JSONDecodeError:
        logger.error("配置文件格式错误，使用默认配置")
        return {
            'kafka': {
                'bootstrap_servers': ['localhost:9092'],
                'topic': 'your_kafka_topic',
                'group_id': 'table_counter_group'
            }
        }

def main():
    # 加载配置
    config = load_config()
    kafka_config = config.get('kafka', {})
    
    # 创建并启动计数器
    counter = KafkaTableCounter(
        bootstrap_servers=kafka_config.get('bootstrap_servers', ['localhost:9092']),
        topic=kafka_config.get('topic', 'your_kafka_topic'),
        group_id=kafka_config.get('group_id', 'table_counter_group')
    )
    
    logger.info("程序启动，按 Ctrl+C 停止")
    try:
        counter.start_consuming()
    except KeyboardInterrupt:
        logger.info("程序被用户中断")
    except Exception as e:
        logger.error(f"程序执行出错: {e}")
    finally:
        counter.stop()

if __name__ == "__main__":
    main()