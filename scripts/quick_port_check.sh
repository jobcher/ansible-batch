#!/bin/bash

# 快速端口服务查看脚本
echo "=========================================="
echo "      快速端口服务查看"
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
echo "2. 每台服务器的实际使用端口和服务:"
echo "=========================================="

# 初始化全局统计变量
declare -A global_port_count
declare -A global_service_count
total_servers=$(echo "$PORT_FILES" | wc -w)

for file in $PORT_FILES; do
    hostname=$(basename "$file" | sed 's/port_service_ps_\(.*\)\.txt/\1/')
    ip_address=$(grep "服务器:" "$file" | head -1 | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+' || echo "未知")
    
    echo ""
    echo -e "${BLUE}=== 服务器: $hostname (IP: $ip_address) ===${NC}"
    
    # 初始化当前服务器的端口跟踪数组
    declare -A current_server_ports
    
    # 提取监听端口信息
    echo -e "${YELLOW}【实际监听的端口】${NC}"
    echo "----------------------------------------"
    
    if grep -A 50 "=== 所有监听端口及服务 ===" "$file" > /dev/null; then
        listening_section=$(sed -n '/=== 所有监听端口及服务 ===/,/^$/p' "$file" | grep -v "===" | grep -v "^$")
        
        if [ -n "$listening_section" ]; then
            port_count=0
            echo "$listening_section" | while IFS= read -r line; do
                if [[ "$line" =~ :[0-9]+ ]]; then
                    # 解析端口信息
                    port=$(echo "$line" | grep -o ':[0-9]\+' | head -1 | sed 's/://')
                    protocol=$(echo "$line" | awk '{print $1}' | sed 's/.*://')
                    service=$(echo "$line" | grep -o '[^/]*$' | head -1)
                    process=$(echo "$line" | grep -o 'pid=[0-9]\+' | head -1 | sed 's/pid=//')
                    
                    if [ -n "$port" ] && [ -z "${current_server_ports[$port]}" ]; then
                        # 标记端口已处理，避免重复
                        current_server_ports[$port]=1
                        port_count=$((port_count + 1))
                        
                        # 更新全局端口统计
                        if [ -z "${global_port_count[$port]}" ]; then
                            global_port_count[$port]=1
                        else
                            global_port_count[$port]=$((${global_port_count[$port]} + 1))
                        fi
                        
                        # 根据端口号判断常见服务
                        service_name=""
                        case $port in
                            22) service_name="SSH" ;;
                            80) service_name="HTTP" ;;
                            443) service_name="HTTPS" ;;
                            3306) service_name="MySQL" ;;
                            5432) service_name="PostgreSQL" ;;
                            6379) service_name="Redis" ;;
                            8080) service_name="HTTP Alt" ;;
                            9000) service_name="Jenkins" ;;
                            27017) service_name="MongoDB" ;;
                            *) service_name="未知服务" ;;
                        esac
                        
                        echo -e "${GREEN}端口 $port${NC} (${CYAN}$protocol${NC}) -> ${PURPLE}$service${NC} (PID: $process)"
                        if [ "$service_name" != "未知服务" ]; then
                            echo -e "        ${YELLOW}常见服务: $service_name${NC}"
                        fi
                    fi
                fi
            done
            
            if [ $port_count -eq 0 ]; then
                echo -e "${RED}未找到监听端口${NC}"
            else
                echo -e "${CYAN}总计: $port_count 个唯一端口${NC}"
            fi
        else
            echo -e "${RED}未找到监听端口信息${NC}"
        fi
    else
        echo -e "${RED}未找到监听端口信息${NC}"
    fi
    
    # 提取运行服务信息
    echo ""
    echo -e "${YELLOW}【运行的系统服务】${NC}"
    echo "----------------------------------------"
    
    if grep -A 30 "=== 系统服务状态 ===" "$file" > /dev/null; then
        running_services=$(sed -n '/=== 系统服务状态 ===/,/^$/p' "$file" | grep "running" | head -10)
        
        if [ -n "$running_services" ]; then
            service_count=0
            declare -A current_server_services
            
            echo "$running_services" | while IFS= read -r line; do
                service_name=$(echo "$line" | awk '{print $1}')
                status=$(echo "$line" | awk '{print $3}')
                
                if [ -n "$service_name" ] && [ -z "${current_server_services[$service_name]}" ]; then
                    # 标记服务已处理，避免重复
                    current_server_services[$service_name]=1
                    service_count=$((service_count + 1))
                    
                    # 更新全局服务统计
                    if [ -z "${global_service_count[$service_name]}" ]; then
                        global_service_count[$service_name]=1
                    else
                        global_service_count[$service_name]=$((${global_service_count[$service_name]} + 1))
                    fi
                    
                    echo -e "${GREEN}$service_name${NC} -> ${PURPLE}$status${NC}"
                fi
            done
            
            if [ $service_count -eq 0 ]; then
                echo -e "${RED}未找到运行服务${NC}"
            else
                echo -e "${CYAN}总计: $service_count 个唯一服务${NC}"
            fi
        else
            echo -e "${RED}未找到运行服务信息${NC}"
        fi
    else
        echo -e "${RED}未找到服务状态信息${NC}"
    fi
done

echo ""
echo "3. 端口服务统计 (去重):"
echo "=========================================="

# 计算总端口数和服务数
total_unique_ports=0
total_unique_services=0

for file in $PORT_FILES; do
    hostname=$(basename "$file" | sed 's/port_service_ps_\(.*\)\.txt/\1/')
    
    # 统计唯一端口数
    if grep -A 50 "=== 所有监听端口及服务 ===" "$file" > /dev/null; then
        listening_section=$(sed -n '/=== 所有监听端口及服务 ===/,/^$/p' "$file" | grep -v "===" | grep -v "^$")
        # 使用sort和uniq去重
        unique_ports=$(echo "$listening_section" | grep -o ':[0-9]\+' | sed 's/://' | sort -u | wc -l)
        total_unique_ports=$((total_unique_ports + unique_ports))
        echo -e "${CYAN}$hostname${NC}: $unique_ports 个唯一监听端口"
    fi
    
    # 统计唯一服务数
    if grep -A 30 "=== 系统服务状态 ===" "$file" > /dev/null; then
        running_services=$(sed -n '/=== 系统服务状态 ===/,/^$/p' "$file" | grep "running")
        # 使用sort和uniq去重
        unique_services=$(echo "$running_services" | awk '{print $1}' | sort -u | wc -l)
        total_unique_services=$((total_unique_services + unique_services))
        echo -e "${CYAN}$hostname${NC}: $unique_services 个唯一运行服务"
    fi
done

echo ""
echo -e "${GREEN}总计 (去重):${NC}"
echo -e "  服务器数: $total_servers"
echo -e "  总唯一端口数: $total_unique_ports"
echo -e "  总唯一服务数: $total_unique_services"

# 显示端口使用频率
echo ""
echo -e "${YELLOW}端口使用频率统计:${NC}"
echo "----------------------------------------"
for port in "${!global_port_count[@]}"; do
    count=${global_port_count[$port]}
    if [ "$count" -gt 1 ]; then
        echo -e "端口 ${GREEN}$port${NC}: 在 $count 台服务器上使用"
    fi
done

# 显示服务使用频率
echo ""
echo -e "${YELLOW}服务使用频率统计:${NC}"
echo "----------------------------------------"
for service in "${!global_service_count[@]}"; do
    count=${global_service_count[$service]}
    if [ "$count" -gt 1 ]; then
        echo -e "服务 ${GREEN}$service${NC}: 在 $count 台服务器上运行"
    fi
done

echo ""
echo "4. 快速查询命令:"
echo "=========================================="
echo -e "${YELLOW}查看所有SSH端口:${NC}"
echo "  grep -r ':22' /tmp/port_service_ps_*.txt"
echo ""
echo -e "${YELLOW}查看所有Web服务端口:${NC}"
echo "  grep -r ':80\|:443' /tmp/port_service_ps_*.txt"
echo ""
echo -e "${YELLOW}查看所有数据库端口:${NC}"
echo "  grep -r ':3306\|:5432\|:6379\|:27017' /tmp/port_service_ps_*.txt"
echo ""
echo -e "${YELLOW}查看所有监听端口:${NC}"
echo "  grep -r 'LISTEN' /tmp/port_service_ps_*.txt"

echo ""
echo "查看完成！" 