#!/bin/bash

# Python版本检测脚本
# 用于检测目标服务器的Python版本和可用性

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

# 检测单个主机的Python
check_host_python() {
    local host=$1
    local ip=$2
    local user=$3
    local key_file=$4
    
    echo "=========================================="
    log_info "检测主机: $host ($ip)"
    echo "=========================================="
    
    # 检查Python3
    log_info "检查Python3..."
    local python3_path=$(ssh -i "$key_file" -o ConnectTimeout=10 "$user@$ip" "which python3 2>/dev/null || echo 'not_found'")
    
    if [ "$python3_path" != "not_found" ]; then
        local python3_version=$(ssh -i "$key_file" -o ConnectTimeout=10 "$user@$ip" "$python3_path --version 2>&1")
        log_success "Python3: $python3_path - $python3_version"
        
        # 检查Python3版本是否支持f-string
        local major_version=$(echo "$python3_version" | grep -oE '[0-9]+\.[0-9]+' | head -1 | cut -d. -f1)
        local minor_version=$(echo "$python3_version" | grep -oE '[0-9]+\.[0-9]+' | head -1 | cut -d. -f2)
        
        if [ "$major_version" -ge 3 ] && [ "$minor_version" -ge 6 ]; then
            log_success "Python3版本支持f-string (>=3.6)"
        else
            log_warning "Python3版本过低，不支持f-string (<3.6)"
        fi
    else
        log_warning "Python3: 未找到"
    fi
    
    # 检查Python2
    log_info "检查Python2..."
    local python2_path=$(ssh -i "$key_file" -o ConnectTimeout=10 "$user@$ip" "which python 2>/dev/null || echo 'not_found'")
    
    if [ "$python2_path" != "not_found" ]; then
        local python2_version=$(ssh -i "$key_file" -o ConnectTimeout=10 "$user@$ip" "$python2_path --version 2>&1")
        log_success "Python2: $python2_path - $python2_version"
    else
        log_error "Python2: 未找到"
    fi
    
    # 检查系统信息
    log_info "系统信息:"
    ssh -i "$key_file" -o ConnectTimeout=10 "$user@$ip" "cat /etc/os-release | head -3" 2>/dev/null || log_warning "无法获取系统信息"
    
    # 检查可用的Python解释器
    log_info "可用的Python解释器:"
    ssh -i "$key_file" -o ConnectTimeout=10 "$user@$ip" "ls -la /usr/bin/python* 2>/dev/null || echo '未找到Python解释器'" 2>/dev/null || true
    
    echo ""
}

# 主函数
main() {
    echo "=========================================="
    echo "        Python版本检测工具"
    echo "=========================================="
    echo ""
    
    # 检查SSH密钥
    local key_file=~/.ssh/id_rsa
    if [ ! -f "$key_file" ]; then
        log_error "SSH密钥文件不存在: $key_file"
        exit 1
    fi
    
    log_success "SSH密钥文件存在: $key_file"
    
    # 检测目标主机
    local hosts=(
        "server1:193.0.20.98:ddapiserver"
        "server2:193.0.20.120:user"
        "server3:193.0.30.94:root"
    )
    
    for host_info in "${hosts[@]}"; do
        IFS=':' read -r hostname ip user <<< "$host_info"
        check_host_python "$hostname" "$ip" "$user" "$key_file"
    done
    
    log_info "Python版本检测完成"
}

# 运行主函数
main "$@" 