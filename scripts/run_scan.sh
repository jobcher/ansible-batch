#!/bin/bash

# Ansible资产扫描主脚本
# 用于运行完整的服务器资产扫描流程

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置变量
SCAN_TYPE=${1:-"full"}
NETWORK_SUBNET=${2:-"192.168.1.0/24"}
PARALLEL_FORKS=${3:-"10"}
VERBOSE=${4:-"false"}

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

# 显示帮助信息
show_help() {
    echo "Ansible服务器资产扫描工具"
    echo ""
    echo "用法: $0 [扫描类型] [网段] [并行数] [详细模式]"
    echo ""
    echo "参数:"
    echo "  扫描类型: full|network|asset|report (默认: full)"
    echo "  网段: 要扫描的网络段 (默认: 192.168.1.0/24)"
    echo "  并行数: 并行执行的任务数 (默认: 10)"
    echo "  详细模式: true|false (默认: false)"
    echo ""
    echo "示例:"
    echo "  $0 full 192.168.1.0/24 20 true"
    echo "  $0 network 10.0.0.0/24"
    echo "  $0 asset"
    echo "  $0 report"
}

# 检查依赖
check_dependencies() {
    log_info "检查依赖..."
    
    if ! command -v ansible &> /dev/null; then
        log_error "Ansible未安装，请先安装Ansible"
        exit 1
    fi
    
    if ! command -v nmap &> /dev/null; then
        log_warning "nmap未安装，网络扫描功能将不可用"
    fi
    
    if [ ! -f "inventory/hosts.yml" ]; then
        log_warning "主机清单文件不存在，将使用网络发现"
    fi
    
    log_success "依赖检查完成"
}

# 网络发现
run_network_discovery() {
    log_info "开始网络发现..."
    
    if [ -f "scripts/network_discovery.sh" ]; then
        chmod +x scripts/network_discovery.sh
        ./scripts/network_discovery.sh "$NETWORK_SUBNET"
        log_success "网络发现完成"
    else
        log_error "网络发现脚本不存在"
        exit 1
    fi
}

# 运行Ansible playbook
run_ansible_playbook() {
    local tags=""
    local extra_vars=""
    
    case $SCAN_TYPE in
        "full")
            tags=""
            extra_vars="network_subnet=$NETWORK_SUBNET"
            ;;
        "network")
            tags="--tags network,scanner"
            extra_vars="network_subnet=$NETWORK_SUBNET"
            ;;
        "asset")
            tags="--tags asset,discovery"
            ;;
        "report")
            tags="--tags report,generator"
            ;;
        *)
            log_error "无效的扫描类型: $SCAN_TYPE"
            show_help
            exit 1
            ;;
    esac
    
    # 构建命令
    local cmd="ansible-playbook site.yml -f $PARALLEL_FORKS"
    
    if [ "$VERBOSE" = "true" ]; then
        cmd="$cmd -vvv"
    fi
    
    if [ -n "$tags" ]; then
        cmd="$cmd $tags"
    fi
    
    if [ -n "$extra_vars" ]; then
        cmd="$cmd -e \"$extra_vars\""
    fi
    
    log_info "执行命令: $cmd"
    eval $cmd
}

# 显示结果
show_results() {
    log_info "扫描完成，检查结果..."
    
    local report_dir="/tmp/asset_reports"
    if [ -d "$report_dir" ]; then
        log_success "报告已生成在: $report_dir"
        echo "生成的文件:"
        ls -la "$report_dir"/*.json 2>/dev/null || true
        ls -la "$report_dir"/*.html 2>/dev/null || true
        ls -la "$report_dir"/*.csv 2>/dev/null || true
        ls -la "$report_dir"/*.txt 2>/dev/null || true
    else
        log_warning "未找到报告目录"
    fi
}

# 主函数
main() {
    echo "=========================================="
    echo "    Ansible服务器资产扫描工具"
    echo "=========================================="
    echo ""
    
    # 显示参数
    log_info "扫描类型: $SCAN_TYPE"
    log_info "扫描网段: $NETWORK_SUBNET"
    log_info "并行数: $PARALLEL_FORKS"
    log_info "详细模式: $VERBOSE"
    echo ""
    
    # 检查依赖
    check_dependencies
    
    # 如果是网络发现或完整扫描，先运行网络发现
    if [ "$SCAN_TYPE" = "full" ] || [ "$SCAN_TYPE" = "network" ]; then
        run_network_discovery
    fi
    
    # 运行Ansible playbook
    log_info "开始执行Ansible playbook..."
    run_ansible_playbook
    
    # 显示结果
    show_results
    
    log_success "扫描流程完成！"
}

# 处理命令行参数
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_help
    exit 0
fi

# 运行主函数
main "$@" 