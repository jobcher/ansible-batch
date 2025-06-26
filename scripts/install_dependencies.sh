#!/bin/bash

# 依赖安装脚本
# 处理pip安装时的网络问题

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

# 配置pip镜像源
setup_pip_mirrors() {
    log_info "配置pip镜像源..."
    
    # 创建pip配置目录
    mkdir -p ~/.pip
    
    # 复制配置文件
    if [ -f "pip.conf" ]; then
        cp pip.conf ~/.pip/
        log_success "pip配置文件已复制"
    else
        # 创建默认配置
        cat > ~/.pip/pip.conf << EOF
[global]
index-url = https://pypi.tuna.tsinghua.edu.cn/simple
trusted-host = pypi.tuna.tsinghua.edu.cn
timeout = 120
retries = 3
EOF
        log_success "创建默认pip配置"
    fi
}

# 升级pip
upgrade_pip() {
    log_info "升级pip..."
    python3 -m pip install --upgrade pip --timeout 120 --retries 3
    log_success "pip升级完成"
}

# 安装基础依赖
install_basic_deps() {
    log_info "安装基础依赖..."
    
    # 安装基础包
    pip install --upgrade setuptools wheel --timeout 120 --retries 3
    
    # 安装编译工具
    if command -v yum > /dev/null 2>&1; then
        # CentOS/RHEL
        sudo yum install -y gcc gcc-c++ make python3-devel
    elif command -v apt-get > /dev/null 2>&1; then
        # Ubuntu/Debian
        sudo apt-get update
        sudo apt-get install -y build-essential python3-dev
    fi
    
    log_success "基础依赖安装完成"
}

# 安装项目依赖
install_project_deps() {
    log_info "安装项目依赖..."
    
    # 检查requirements.txt
    if [ ! -f "requirements.txt" ]; then
        log_error "requirements.txt文件不存在"
        exit 1
    fi
    
    # 逐个安装依赖，处理网络问题
    while IFS= read -r package; do
        # 跳过注释和空行
        if [[ "$package" =~ ^[[:space:]]*# ]] || [[ -z "$package" ]]; then
            continue
        fi
        
        log_info "安装: $package"
        
        # 尝试安装，如果失败则重试
        for attempt in {1..3}; do
            if pip install "$package" --timeout 120 --retries 3; then
                log_success "安装成功: $package"
                break
            else
                log_warning "安装失败 (尝试 $attempt/3): $package"
                if [ $attempt -eq 3 ]; then
                    log_error "安装失败: $package"
                    return 1
                fi
                sleep 5
            fi
        done
    done < requirements.txt
    
    log_success "项目依赖安装完成"
}

# 安装Ansible
install_ansible() {
    log_info "安装Ansible..."
    
    # 检查Ansible是否已安装
    if command -v ansible > /dev/null 2>&1; then
        log_info "Ansible已安装，版本: $(ansible --version | head -1)"
        return 0
    fi
    
    # 安装Ansible
    pip install ansible --timeout 120 --retries 3
    log_success "Ansible安装完成"
}

# 安装nmap
install_nmap() {
    log_info "安装nmap..."
    
    # 检查nmap是否已安装
    if command -v nmap > /dev/null 2>&1; then
        log_info "nmap已安装，版本: $(nmap --version | head -1)"
        return 0
    fi
    
    # 根据系统类型安装nmap
    if command -v yum > /dev/null 2>&1; then
        # CentOS/RHEL
        sudo yum install -y nmap
    elif command -v apt-get > /dev/null 2>&1; then
        # Ubuntu/Debian
        sudo apt-get install -y nmap
    elif command -v brew > /dev/null 2>&1; then
        # macOS
        brew install nmap
    else
        log_warning "无法自动安装nmap，请手动安装"
        return 1
    fi
    
    log_success "nmap安装完成"
}

# 验证安装
verify_installation() {
    log_info "验证安装..."
    
    # 检查Ansible
    if command -v ansible > /dev/null 2>&1; then
        log_success "Ansible: 已安装"
        ansible --version | head -1
    else
        log_error "Ansible: 未安装"
    fi
    
    # 检查nmap
    if command -v nmap > /dev/null 2>&1; then
        log_success "nmap: 已安装"
        nmap --version | head -1
    else
        log_warning "nmap: 未安装"
    fi
    
    # 检查Python包
    log_info "检查Python包..."
    pip list | grep -E "(ansible|nmap|pandas|jinja2|pyyaml)" || log_warning "部分Python包可能未安装"
}

# 主函数
main() {
    echo "=========================================="
    echo "    依赖安装工具"
    echo "=========================================="
    echo ""
    
    # 配置pip镜像源
    setup_pip_mirrors
    
    # 升级pip
    upgrade_pip
    
    # 安装基础依赖
    install_basic_deps
    
    # 安装Ansible
    install_ansible
    
    # 安装nmap
    install_nmap
    
    # 安装项目依赖
    install_project_deps
    
    # 验证安装
    verify_installation
    
    echo ""
    log_success "依赖安装完成！"
    echo ""
    echo "下一步:"
    echo "1. 配置主机清单: inventory/hosts.yml"
    echo "2. 运行连接测试: ./scripts/test_connection.sh"
    echo "3. 运行资产扫描: ansible-playbook site.yml"
}

# 运行主函数
main "$@" 