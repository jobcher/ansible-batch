#!/bin/bash

# 连接测试脚本
# 用于测试与目标服务器的连接

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 测试单个主机连接
test_host_connection() {
    local host=$1
    local ip=$2
    local user=$3
    
    log_info "测试主机: $host ($ip)"
    
    # 测试网络连通性
    if ping -c 1 -W 3 "$ip" > /dev/null 2>&1; then
        log_success "网络连通性: 正常"
    else
        log_error "网络连通性: 失败"
        return 1
    fi
    
    # 测试SSH端口
    if nc -z -w 3 "$ip" 22 > /dev/null 2>&1; then
        log_success "SSH端口: 开放"
    else
        log_error "SSH端口: 关闭或无法访问"
        return 1
    fi
    
    # 测试SSH连接
    if ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$user@$ip" "echo 'SSH连接成功'" 2>/dev/null; then
        log_success "SSH连接: 成功"
        
        # 检查Python解释器
        log_info "检查Python解释器..."
        if ssh -o ConnectTimeout=10 "$user@$ip" "which python3" 2>/dev/null; then
            log_success "Python3: 可用"
        elif ssh -o ConnectTimeout=10 "$user@$ip" "which python" 2>/dev/null; then
            log_warning "Python3: 不可用，但Python可用"
        else
            log_error "Python: 不可用"
        fi
        
        # 检查系统信息
        log_info "系统信息:"
        ssh -o ConnectTimeout=10 "$user@$ip" "cat /etc/os-release | head -3" 2>/dev/null || true
        
    else
        log_error "SSH连接: 失败"
        return 1
    fi
    
    echo ""
}

# 主函数
main() {
    echo "=========================================="
    echo "    服务器连接测试工具"
    echo "=========================================="
    echo ""
    
    # 检查inventory文件
    if [ ! -f "inventory/hosts.yml" ]; then
        log_error "主机清单文件不存在: inventory/hosts.yml"
        exit 1
    fi
    
    # 解析主机信息
    log_info "解析主机清单..."
    
    # 提取主机信息（简化版本）
    hosts=(
        "server1:192.168.20.98:admin"
        "server2:192.168.20.120:admin"
        "server3:192.168.20.99:admin"
    )
    
    # 测试每个主机
    for host_info in "${hosts[@]}"; do
        IFS=':' read -r hostname ip user <<< "$host_info"
        test_host_connection "$hostname" "$ip" "$user"
    done
    
    log_info "连接测试完成"
}

# 运行主函数
main "$@" 