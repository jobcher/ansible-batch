#!/bin/bash

# SSH连接测试脚本
# 用于测试与目标服务器的SSH连接

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

# 测试SSH连接
test_ssh_connection() {
    local host=$1
    local ip=$2
    local user=$3
    local key_file=$4
    
    echo "=========================================="
    log_info "测试SSH连接: $host ($ip)"
    echo "=========================================="
    
    # 检查SSH密钥文件
    if [ ! -f "$key_file" ]; then
        log_error "SSH密钥文件不存在: $key_file"
        return 1
    fi
    
    # 检查密钥文件权限
    local key_perms=$(stat -c %a "$key_file" 2>/dev/null || stat -f %Lp "$key_file" 2>/dev/null)
    if [ "$key_perms" != "600" ]; then
        log_warning "SSH密钥文件权限不正确: $key_perms (应该是600)"
        chmod 600 "$key_file"
        log_info "已修复密钥文件权限"
    fi
    
    # 测试网络连通性
    log_info "1. 测试网络连通性..."
    if ping -c 1 -W 3 "$ip" > /dev/null 2>&1; then
        log_success "网络连通性: 正常"
    else
        log_error "网络连通性: 失败"
        return 1
    fi
    
    # 测试SSH端口
    log_info "2. 测试SSH端口..."
    if nc -z -w 3 "$ip" 22 > /dev/null 2>&1; then
        log_success "SSH端口: 开放"
    else
        log_error "SSH端口: 关闭或无法访问"
        return 1
    fi
    
    # 测试SSH密钥连接
    log_info "3. 测试SSH密钥连接..."
    if ssh -i "$key_file" -o ConnectTimeout=10 -o StrictHostKeyChecking=no -o PasswordAuthentication=no "$user@$ip" "echo 'SSH密钥连接成功'" 2>/dev/null; then
        log_success "SSH密钥连接: 成功"
        
        # 检查Python解释器
        log_info "4. 检查Python解释器..."
        local python_path=$(ssh -i "$key_file" -o ConnectTimeout=10 "$user@$ip" "which python3 2>/dev/null || which python 2>/dev/null || echo 'not_found'")
        
        if [ "$python_path" != "not_found" ]; then
            log_success "Python解释器: $python_path"
            
            # 检查Python版本
            local python_version=$(ssh -i "$key_file" -o ConnectTimeout=10 "$user@$ip" "$python_path --version 2>&1")
            log_info "Python版本: $python_version"
        else
            log_error "Python解释器: 未找到"
        fi
        
        # 检查系统信息
        log_info "5. 系统信息:"
        ssh -i "$key_file" -o ConnectTimeout=10 "$user@$ip" "cat /etc/os-release | head -3" 2>/dev/null || log_warning "无法获取系统信息"
        
    else
        log_error "SSH密钥连接: 失败"
        
        # 尝试诊断问题
        log_info "诊断SSH连接问题..."
        ssh -i "$key_file" -o ConnectTimeout=10 -o StrictHostKeyChecking=no -o PasswordAuthentication=no -v "$user@$ip" "echo 'test'" 2>&1 | head -10
        
        return 1
    fi
    
    echo ""
}

# 主函数
main() {
    echo "=========================================="
    echo "        SSH连接测试工具"
    echo "=========================================="
    echo ""
    
    # 检查SSH密钥
    local key_file=~/.ssh/id_rsa
    if [ ! -f "$key_file" ]; then
        log_error "SSH密钥文件不存在: $key_file"
        echo ""
        echo "请先生成SSH密钥:"
        echo "  ssh-keygen -t rsa -b 4096"
        echo ""
        echo "然后将公钥复制到目标服务器:"
        echo "  ssh-copy-id user@target-server"
        exit 1
    fi
    
    log_success "SSH密钥文件存在: $key_file"
    
    # 检查网络工具
    if ! command -v nc > /dev/null 2>&1; then
        log_warning "netcat未安装，跳过端口测试"
    fi
    
    # 测试目标主机
    local hosts=(
        "server1:193.0.20.98:ddapiserver"
        "server2:193.0.20.120:user"
        "server3:193.0.30.94:root"
    )
    
    local failed_hosts=()
    
    for host_info in "${hosts[@]}"; do
        IFS=':' read -r hostname ip user <<< "$host_info"
        if ! test_ssh_connection "$hostname" "$ip" "$user" "$key_file"; then
            failed_hosts+=("$hostname")
        fi
    done
    
    # 显示结果
    echo "=========================================="
    log_info "测试完成"
    echo "=========================================="
    
    if [ ${#failed_hosts[@]} -eq 0 ]; then
        log_success "所有主机SSH连接正常！"
    else
        log_error "以下主机连接失败: ${failed_hosts[*]}"
        echo ""
        echo "建议的解决方案:"
        echo "1. 检查目标服务器SSH服务是否运行"
        echo "2. 确认SSH公钥已添加到目标服务器"
        echo "3. 检查防火墙设置"
        echo "4. 验证用户名和IP地址是否正确"
    fi
}

# 运行主函数
main "$@" 