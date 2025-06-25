#!/bin/bash

# 网络诊断脚本
# 用于诊断网络连接问题

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

# 诊断单个IP
diagnose_ip() {
    local ip=$1
    local description=$2
    
    echo "=========================================="
    log_info "诊断: $description ($ip)"
    echo "=========================================="
    
    # 1. 基本连通性测试
    log_info "1. 基本连通性测试..."
    if ping -c 3 -W 2 "$ip" > /dev/null 2>&1; then
        log_success "Ping测试: 成功"
    else
        log_error "Ping测试: 失败"
    fi
    
    # 2. 端口扫描
    log_info "2. SSH端口测试..."
    if command -v nc > /dev/null 2>&1; then
        if nc -z -w 3 "$ip" 22 > /dev/null 2>&1; then
            log_success "SSH端口(22): 开放"
        else
            log_error "SSH端口(22): 关闭或无法访问"
        fi
    else
        log_warning "netcat未安装，跳过端口测试"
    fi
    
    # 3. 路由跟踪
    log_info "3. 路由跟踪..."
    if command -v traceroute > /dev/null 2>&1; then
        echo "路由跟踪结果:"
        traceroute -m 10 "$ip" 2>/dev/null | head -5 || log_warning "路由跟踪失败"
    elif command -v tracert > /dev/null 2>&1; then
        echo "路由跟踪结果:"
        tracert -h 10 "$ip" 2>/dev/null | head -5 || log_warning "路由跟踪失败"
    else
        log_warning "traceroute未安装，跳过路由跟踪"
    fi
    
    # 4. DNS解析
    log_info "4. DNS解析测试..."
    if nslookup "$ip" > /dev/null 2>&1; then
        log_success "DNS解析: 正常"
    else
        log_warning "DNS解析: 可能有问题"
    fi
    
    echo ""
}

# 主函数
main() {
    echo "=========================================="
    echo "        网络连接诊断工具"
    echo "=========================================="
    echo ""
    
    # 检查网络工具
    log_info "检查网络诊断工具..."
    
    tools=("ping" "nc" "traceroute" "nslookup")
    for tool in "${tools[@]}"; do
        if command -v "$tool" > /dev/null 2>&1; then
            log_success "$tool: 可用"
        else
            log_warning "$tool: 不可用"
        fi
    done
    
    echo ""
    
    # 诊断目标IP
    targets=(
        "192.168.20.98:server1"
        "192.168.20.120:server2"
        "192.168.20.99:server3"
    )
    
    for target in "${targets[@]}"; do
        IFS=':' read -r ip description <<< "$target"
        diagnose_ip "$ip" "$description"
    done
    
    # 网络配置信息
    log_info "本地网络配置:"
    echo "本机IP地址:"
    ip addr show | grep -E "inet.*scope global" || ifconfig | grep -E "inet.*broadcast" || log_warning "无法获取IP地址"
    
    echo ""
    echo "路由表:"
    ip route show | head -5 || route -n | head -5 || log_warning "无法获取路由表"
    
    echo ""
    log_info "诊断完成"
}

# 运行主函数
main "$@" 