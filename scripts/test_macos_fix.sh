#!/bin/bash

# macOS 修复测试脚本
echo "测试 macOS 修复..."

# 检查 Ansible 版本
echo "1. 检查 Ansible 版本:"
ansible --version | head -1

# 检查 community.general 集合
echo ""
echo "2. 检查 community.general 集合:"
if ansible-galaxy collection list | grep -q "community.general"; then
    echo "✓ community.general 集合已安装"
else
    echo "✗ community.general 集合未安装"
    echo "请运行: ansible-galaxy collection install community.general"
fi

# 检查 nmap
echo ""
echo "3. 检查 nmap:"
if command -v nmap &> /dev/null; then
    echo "✓ nmap 已安装: $(nmap --version | head -1)"
else
    echo "✗ nmap 未安装"
    echo "请运行: brew install nmap"
fi

# 测试变量定义
echo ""
echo "4. 测试 playbook 语法:"
if ansible-playbook site_python27.yml --check --tags network; then
    echo "✓ playbook 语法检查通过"
else
    echo "✗ playbook 语法检查失败"
fi

echo ""
echo "测试完成！" 