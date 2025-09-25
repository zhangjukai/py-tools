#!/bin/bash

# Full GC监控脚本
# 支持Java 8和11版本
# 通过jps检测运行中的Java进程并检查Full GC情况

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数（输出到stderr，避免干扰管道处理）
log_info() {
    echo -e "${BLUE}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1" >&2
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1" >&2
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1" >&2
}

# 检查Java环境
check_java_env() {
    if ! command -v java &> /dev/null; then
        log_error "Java未安装或未在PATH中"
        return 1
    fi
    
    JAVA_VERSION=$(java -version 2>&1 | head -n1 | cut -d'"' -f2)
    log_info "检测到Java版本: $JAVA_VERSION"
    
    if ! command -v jps &> /dev/null; then
        log_error "jps命令不可用，请检查JDK安装"
        return 1
    fi
    
    return 0
}

# 获取Java进程列表
get_java_processes() {
    # 使用jps获取进程信息，排除Jps进程
    jps -l 2>/dev/null | grep -v Jps | while read pid main_class; do
        # 确保pid是数字且不为空，且main_class不是日志信息
        if [[ "$pid" =~ ^[0-9]+$ ]] && [[ -n "$main_class" ]] && [[ ! "$main_class" =~ \[INFO\]|\[WARN\]|\[ERROR\]|\[SUCCESS\] ]]; then
            echo "$pid $main_class"
        fi
    done
}

# 检查单个进程的Full GC情况
check_process_full_gc() {
    local pid=$1
    local main_class=$2
    
    log_info "检查进程 $pid ($main_class) 的GC情况..."
    
    # 根据Java版本选择不同的GC日志参数
    if [[ $JAVA_VERSION == 1.8* ]]; then
        # Java 8
        GC_CMD="jstat -gc $pid 1 1"
    else
        # Java 11+
        GC_CMD="jstat -gc $pid 1 1"
    fi
    
    # 执行GC统计
    GC_OUTPUT=$($GC_CMD 2>/dev/null)
    
    if [ $? -ne 0 ]; then
        log_warn "无法获取进程 $pid 的GC信息（可能权限不足或进程不存在）"
        return 1
    fi
    
    # 解析GC输出
    if [[ $JAVA_VERSION == 1.8* ]]; then
        # Java 8的jstat输出格式
        FULL_GC_COUNT=$(echo "$GC_OUTPUT" | tail -1 | awk '{print $15}')
        FULL_GC_TIME=$(echo "$GC_OUTPUT" | tail -1 | awk '{print $16}')
    else
        # Java 11的jstat输出格式
        FULL_GC_COUNT=$(echo "$GC_OUTPUT" | tail -1 | awk '{print $15}')
        FULL_GC_TIME=$(echo "$GC_OUTPUT" | tail -1 | awk '{print $16}')
    fi
    
    # 输出结果
    if [ -n "$FULL_GC_COUNT" ] && [ "$FULL_GC_COUNT" != "FGC" ]; then
        if [ "$FULL_GC_COUNT" -gt 0 ]; then
            log_warn "进程 $pid ($main_class) 检测到Full GC:"
            echo "  - Full GC次数: $FULL_GC_COUNT"
            echo "  - Full GC总时间: ${FULL_GC_TIME}秒"
        else
            log_success "进程 $pid ($main_class) 未检测到Full GC"
        fi
    else
        log_error "无法解析进程 $pid 的GC数据"
    fi
}

# 检查jstat可用性
check_jstat_availability() {
    if ! command -v jstat &> /dev/null; then
        log_error "jstat命令不可用，无法进行GC监控"
        return 1
    fi
    return 0
}

# 主监控函数
monitor_full_gc() {
    log_info "开始Full GC监控检查..."
    
    # 检查环境
    if ! check_java_env; then
        return 1
    fi
    
    # 检查jstat可用性
    if ! check_jstat_availability; then
        return 1
    fi
    
    # 获取进程列表（不输出日志到stdout）
    PROCESSES=$(get_java_processes)
    
    if [ -z "$PROCESSES" ]; then
        log_warn "未找到运行的Java进程"
        return 0
    fi
    
    PROCESS_COUNT=$(echo "$PROCESSES" | wc -l)
    log_info "发现 $PROCESS_COUNT 个Java进程"
    
    # 检查每个进程
    echo "$PROCESSES" | while read pid main_class; do
        check_process_full_gc "$pid" "$main_class"
        echo "----------------------------------------"
    done
}

# 帮助信息
show_help() {
    echo "Full GC监控脚本"
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -h, --help    显示此帮助信息"
    echo "  -v, --version 显示版本信息"
    echo ""
    echo "功能:"
    echo "  1. 自动检测Java版本（支持8和11）"
    echo "  2. 通过jps获取所有Java进程"
    echo "  3. 使用jstat检查每个进程的Full GC情况"
    echo "  4. 生成详细的监控报告"
}

# 版本信息
show_version() {
    echo "Full GC监控脚本 v1.0"
    echo "支持Java 8和11版本"
}

# 参数解析
case "$1" in
    -h|--help)
        show_help
        exit 0
        ;;
    -v|--version)
        show_version
        exit 0
        ;;
    *)
        # 默认执行监控
        monitor_full_gc
        exit $?
        ;;
esac