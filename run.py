#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import sys
import subprocess

def check_dependencies():
    """检查依赖是否已安装"""
    try:
        import kafka
        return True
    except ImportError:
        return False

def install_dependencies():
    """安装依赖"""
    print("正在安装依赖...")
    try:
        subprocess.check_call([sys.executable, "-m", "pip", "install", "-r", "requirements.txt"])
        print("依赖安装成功！")
        return True
    except subprocess.CalledProcessError:
        print("依赖安装失败，请手动运行: pip install -r requirements.txt")
        return False

def main():
    print("=" * 50)
    print("Kafka Table Counter 启动器")
    print("=" * 50)
    
    # 检查依赖
    if not check_dependencies():
        print("检测到未安装依赖")
        if input("是否立即安装？(y/n): ").lower() == 'y':
            if not install_dependencies():
                return
        else:
            print("请手动安装依赖后重新运行")
            return
    
    # 检查配置文件
    if not os.path.exists('config.json'):
        print("警告: 配置文件 config.json 不存在")
        print("将使用默认配置运行")
    
    # 运行主程序
    print("\n启动Kafka消费者...")
    try:
        from kafka_table_counter import main as kafka_main
        kafka_main()
    except KeyboardInterrupt:
        print("\n程序已停止")
    except Exception as e:
        print(f"程序运行出错: {e}")

if __name__ == "__main__":
    main()