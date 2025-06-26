#!/bin/bash

# 端口服务信息查看脚本
echo "=========================================="
echo "        服务器端口服务信息查看"
echo "=========================================="

# 检查是否有端口服务信息文件
echo "1. 检查端口服务信息文件:"
PORT_FILES=$(ls /tmp/port_service_ps_*.txt 2>/dev/null)
if [ -n "$PORT_FILES" ]; then
    echo "✓ 找到端口服务信息文件:"
    echo "$PORT_FILES"
else
    echo "✗ 未找到端口服务信息文件"
    echo "请先运行: ansible-playbook site_python27.yml --tags asset"
    exit 1
fi

echo ""
echo "2. 显示每台服务器的端口服务信息:"
echo "=========================================="

for file in $PORT_FILES; do
    echo ""
    echo "文件: $file"
    echo "=========================================="
    cat "$file"
    echo "=========================================="
done

echo ""
echo "3. 汇总端口服务统计:"
echo "=========================================="

# 统计监听端口
echo "监听端口统计:"
for file in $PORT_FILES; do
    hostname=$(basename "$file" | sed 's/port_service_ps_\(.*\)\.txt/\1/')
    listening_count=$(grep -c "LISTEN" "$file" 2>/dev/null || echo "0")
    echo "  $hostname: $listening_count 个监听端口"
done

# 统计运行服务
echo ""
echo "运行服务统计:"
for file in $PORT_FILES; do
    hostname=$(basename "$file" | sed 's/port_service_ps_\(.*\)\.txt/\1/')
    running_count=$(grep -c "running" "$file" 2>/dev/null || echo "0")
    echo "  $hostname: $running_count 个运行服务"
done

# 统计进程数
echo ""
echo "进程统计:"
for file in $PORT_FILES; do
    hostname=$(basename "$file" | sed 's/port_service_ps_\(.*\)\.txt/\1/')
    process_count=$(grep -c "^[^[:space:]]" "$file" 2>/dev/null || echo "0")
    echo "  $hostname: $process_count 个进程"
done

echo ""
echo "4. 常用端口服务映射:"
echo "=========================================="
echo "端口  服务名"
echo "22    SSH"
echo "80    HTTP"
echo "443   HTTPS"
echo "3306  MySQL"
echo "5432  PostgreSQL"
echo "6379  Redis"
echo "8080  HTTP Alt"
echo "9000  Jenkins"
echo "27017 MongoDB"

echo ""
echo "5. 查看特定端口的服务:"
echo "=========================================="
echo "要查看特定端口的服务，请运行:"
echo "  grep -r '端口号' /tmp/port_service_ps_*.txt"
echo ""
echo "例如查看SSH端口(22):"
echo "  grep -r ':22' /tmp/port_service_ps_*.txt"

echo ""
echo "查看完成！" 