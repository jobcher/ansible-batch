#!/bin/bash

# 查看运行服务和端口号脚本
echo "=========================================="
echo "      服务器运行服务和端口号查看"
echo "=========================================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 检查是否有端口服务信息文件
echo "1. 检查端口服务信息文件:"
PORT_FILES=$(ls /tmp/port_service_ps_*.txt 2>/dev/null)
if [ -n "$PORT_FILES" ]; then
    echo -e "${GREEN}✓ 找到端口服务信息文件:${NC}"
    echo "$PORT_FILES"
else
    echo -e "${RED}✗ 未找到端口服务信息文件${NC}"
    echo "请先运行: ansible-playbook site_python27.yml --tags asset"
    exit 1
fi

echo ""
echo "2. 每台服务器的运行服务和端口号:"
echo "=========================================="

for file in $PORT_FILES; do
    hostname=$(basename "$file" | sed 's/port_service_ps_\(.*\)\.txt/\1/')
    echo ""
    echo -e "${BLUE}=== 服务器: $hostname ===${NC}"
    
    # 提取IP地址
    ip_address=$(grep "服务器:" "$file" | head -1 | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+' || echo "未知")
    echo -e "${CYAN}IP地址: $ip_address${NC}"
    
    # 提取收集时间
    collection_time=$(grep "收集时间:" "$file" | head -1 | sed 's/.*收集时间: //')
    echo -e "${CYAN}收集时间: $collection_time${NC}"
    
    echo ""
    echo -e "${YELLOW}【监听端口和服务】${NC}"
    echo "----------------------------------------"
    
    # 提取监听端口信息
    if grep -A 50 "=== 所有监听端口及服务 ===" "$file" > /dev/null; then
        # 提取监听端口部分
        listening_section=$(sed -n '/=== 所有监听端口及服务 ===/,/^$/p' "$file" | grep -v "===" | grep -v "^$")
        
        if [ -n "$listening_section" ]; then
            echo "$listening_section" | while IFS= read -r line; do
                if [[ "$line" =~ :[0-9]+ ]]; then
                    # 提取端口号
                    port=$(echo "$line" | grep -o ':[0-9]\+' | head -1 | sed 's/://')
                    # 提取服务名
                    service=$(echo "$line" | grep -o '[^/]*$' | head -1)
                    # 提取进程信息
                    process=$(echo "$line" | grep -o 'pid=[0-9]\+' | head -1 | sed 's/pid=//')
                    
                    if [ -n "$port" ]; then
                        echo -e "${GREEN}端口 $port${NC} -> ${PURPLE}服务: $service${NC} (PID: $process)"
                    fi
                fi
            done
        else
            echo -e "${RED}未找到监听端口信息${NC}"
        fi
    else
        echo -e "${RED}未找到监听端口信息${NC}"
    fi
    
    echo ""
    echo -e "${YELLOW}【运行服务状态】${NC}"
    echo "----------------------------------------"
    
    # 提取运行服务信息
    if grep -A 30 "=== 系统服务状态 ===" "$file" > /dev/null; then
        running_services=$(sed -n '/=== 系统服务状态 ===/,/^$/p' "$file" | grep "running" | head -10)
        
        if [ -n "$running_services" ]; then
            echo "$running_services" | while IFS= read -r line; do
                service_name=$(echo "$line" | awk '{print $1}')
                status=$(echo "$line" | awk '{print $3}')
                echo -e "${GREEN}$service_name${NC} -> ${PURPLE}$status${NC}"
            done
        else
            echo -e "${RED}未找到运行服务信息${NC}"
        fi
    else
        echo -e "${RED}未找到服务状态信息${NC}"
    fi
    
    echo ""
    echo -e "${YELLOW}【端口与进程对应关系】${NC}"
    echo "----------------------------------------"
    
    # 提取lsof信息
    if grep -A 20 "=== 端口与进程对应关系 (lsof) ===" "$file" > /dev/null; then
        lsof_info=$(sed -n '/=== 端口与进程对应关系 (lsof) ===/,/^$/p' "$file" | grep -v "===" | grep -v "^$" | head -10)
        
        if [ -n "$lsof_info" ]; then
            echo "$lsof_info" | while IFS= read -r line; do
                if [[ "$line" =~ :[0-9]+ ]]; then
                    # 提取进程名和端口
                    process=$(echo "$line" | awk '{print $1}')
                    port=$(echo "$line" | grep -o ':[0-9]\+' | head -1 | sed 's/://')
                    if [ -n "$port" ]; then
                        echo -e "${GREEN}进程: $process${NC} -> ${PURPLE}端口: $port${NC}"
                    fi
                fi
            done
        else
            echo -e "${RED}未找到端口进程对应关系${NC}"
        fi
    else
        echo -e "${RED}未找到端口进程对应关系${NC}"
    fi
done

echo ""
echo "3. 常用端口服务映射:"
echo "=========================================="
echo -e "${CYAN}端口  服务名          说明${NC}"
echo -e "${GREEN}22    SSH            安全Shell${NC}"
echo -e "${GREEN}80    HTTP           Web服务${NC}"
echo -e "${GREEN}443   HTTPS          安全Web服务${NC}"
echo -e "${GREEN}3306  MySQL          MySQL数据库${NC}"
echo -e "${GREEN}5432  PostgreSQL     PostgreSQL数据库${NC}"
echo -e "${GREEN}6379  Redis          Redis缓存${NC}"
echo -e "${GREEN}8080  HTTP Alt       备用Web服务${NC}"
echo -e "${GREEN}9000  Jenkins        Jenkins CI/CD${NC}"
echo -e "${GREEN}27017 MongoDB        MongoDB数据库${NC}"

echo ""
echo "4. 快速查询命令:"
echo "=========================================="
echo -e "${YELLOW}查看SSH端口(22):${NC}"
echo "  grep -r ':22' /tmp/port_service_ps_*.txt"
echo ""
echo -e "${YELLOW}查看Web服务端口(80,443):${NC}"
echo "  grep -r ':80\|:443' /tmp/port_service_ps_*.txt"
echo ""
echo -e "${YELLOW}查看数据库端口:${NC}"
echo "  grep -r ':3306\|:5432\|:6379\|:27017' /tmp/port_service_ps_*.txt"
echo ""
echo -e "${YELLOW}查看所有监听端口:${NC}"
echo "  grep -r 'LISTEN' /tmp/port_service_ps_*.txt"

echo ""
echo "查看完成！" 