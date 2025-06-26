#!/bin/bash

# 基于hosts.yml的报告生成测试脚本
echo "测试基于hosts.yml的报告生成功能..."

# 检查hosts.yml文件
echo "1. 检查hosts.yml文件:"
if [ -f "inventory/hosts.yml" ]; then
    echo "✓ hosts.yml文件存在"
    echo "配置的主机数量: $(grep -c "ansible_host:" inventory/hosts.yml)"
else
    echo "✗ hosts.yml文件不存在"
    exit 1
fi

# 显示配置的主机信息
echo ""
echo "2. 配置的主机信息:"
grep -A 5 "ansible_host:" inventory/hosts.yml | grep -E "(server[0-9]+|ansible_host|ansible_user)" | head -15

# 测试playbook语法
echo ""
echo "3. 测试playbook语法:"
if ansible-playbook site_python27.yml --check --tags report; then
    echo "✓ playbook语法检查通过"
else
    echo "✗ playbook语法检查失败"
    exit 1
fi

# 测试报告生成（仅生成报告部分）
echo ""
echo "4. 测试报告生成:"
if ansible-playbook site_python27.yml --tags report; then
    echo "✓ 报告生成成功"
    
    # 检查生成的文件
    echo ""
    echo "5. 检查生成的文件:"
    if [ -d "/tmp/asset_reports" ]; then
        echo "✓ 报告目录存在"
        ls -la /tmp/asset_reports/
    else
        echo "✗ 报告目录不存在"
    fi
else
    echo "✗ 报告生成失败"
    exit 1
fi

echo ""
echo "测试完成！" 