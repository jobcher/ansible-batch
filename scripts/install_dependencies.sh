#!/bin/bash

# Ansible服务器资产扫描工具依赖安装脚本
# 适用于 macOS、Ubuntu、CentOS 等系统

set -e

echo "开始安装 Ansible 服务器资产扫描工具依赖..."

# 检测操作系统
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
    echo "检测到 macOS 系统"
elif [[ -f /etc/debian_version ]]; then
    OS="debian"
    echo "检测到 Debian/Ubuntu 系统"
elif [[ -f /etc/redhat-release ]]; then
    OS="redhat"
    echo "检测到 CentOS/RHEL 系统"
else
    echo "不支持的操作系统: $OSTYPE"
    exit 1
fi

# 安装系统依赖
echo "安装系统依赖..."
case $OS in
    "macos")
        # 检查是否安装了 Homebrew
        if ! command -v brew &> /dev/null; then
            echo "正在安装 Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        
        # 安装 Python 和 nmap
        brew install python nmap
        ;;
    "debian")
        sudo apt update
        sudo apt install -y python3 python3-pip nmap
        ;;
    "redhat")
        sudo yum install -y python3 python3-pip nmap
        ;;
esac

# 安装 Python 依赖
echo "安装 Python 依赖..."
pip3 install -r requirements.txt

# 安装 Ansible 集合
echo "安装 Ansible 集合..."
ansible-galaxy collection install community.general

echo "依赖安装完成！"
echo ""
echo "验证安装:"
echo "1. Python: $(python3 --version)"
echo "2. Ansible: $(ansible --version | head -1)"
echo "3. nmap: $(nmap --version | head -1)"
echo "4. Ansible 集合: ansible-galaxy collection list | grep community.general" 