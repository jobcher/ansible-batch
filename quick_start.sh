#!/bin/bash

# 快速启动脚本
# 用于快速配置和运行Ansible资产扫描

echo "=========================================="
echo "    Ansible服务器资产扫描工具 - 快速启动"
echo "=========================================="
echo ""

# 检查Ansible是否安装
if ! command -v ansible &> /dev/null; then
    echo "❌ Ansible未安装，请先安装Ansible:"
    echo "   Ubuntu/Debian: sudo apt install ansible"
    echo "   CentOS/RHEL: sudo yum install ansible"
    echo "   macOS: brew install ansible"
    exit 1
fi

echo "✅ Ansible已安装"

# 检查nmap是否安装
if ! command -v nmap &> /dev/null; then
    echo "⚠️  nmap未安装，网络扫描功能将不可用"
    echo "   建议安装nmap:"
    echo "   Ubuntu/Debian: sudo apt install nmap"
    echo "   CentOS/RHEL: sudo yum install nmap"
    echo "   macOS: brew install nmap"
else
    echo "✅ nmap已安装"
fi

# 检查SSH密钥
if [ ! -f ~/.ssh/id_rsa ]; then
    echo "⚠️  SSH密钥不存在，请先生成SSH密钥:"
    echo "   ssh-keygen -t rsa -b 4096"
    echo "   然后将公钥复制到目标服务器:"
    echo "   ssh-copy-id user@target-server"
else
    echo "✅ SSH密钥已存在"
fi

echo ""
echo "📋 使用说明:"
echo ""
echo "1. 编辑 inventory/hosts.yml 文件，添加要扫描的服务器"
echo "2. 运行完整扫描:"
echo "   ansible-playbook site.yml"
echo ""
echo "3. 或者使用便捷脚本:"
echo "   ./scripts/run_scan.sh full 192.168.1.0/24"
echo ""
echo "4. 查看生成的报告:"
echo "   ls -la /tmp/asset_reports/"
echo ""

# 询问是否要运行测试
read -p "是否要运行连接测试？(y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🔍 测试Ansible连接..."
    ansible all -m ping
fi

echo ""
echo "🎉 快速启动完成！"
echo "   详细文档请查看 README.md" 