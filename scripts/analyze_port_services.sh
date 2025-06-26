#!/bin/bash

# 分析端口服务并生成报告脚本
echo "=========================================="
echo "      服务器端口服务分析报告生成"
echo "=========================================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 创建报告目录
REPORT_DIR="/tmp/port_service_analysis"
mkdir -p "$REPORT_DIR"

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

# 生成时间戳
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
REPORT_FILE="$REPORT_DIR/port_service_analysis_$TIMESTAMP.txt"
JSON_REPORT="$REPORT_DIR/port_service_analysis_$TIMESTAMP.json"
CSV_REPORT="$REPORT_DIR/port_service_analysis_$TIMESTAMP.csv"

echo ""
echo "2. 开始分析端口服务信息..."
echo "报告将保存到: $REPORT_DIR"

# 初始化JSON报告
echo "{" > "$JSON_REPORT"
echo "  \"report_info\": {" >> "$JSON_REPORT"
echo "    \"generated_at\": \"$(date)\"," >> "$JSON_REPORT"
echo "    \"total_servers\": $(echo "$PORT_FILES" | wc -w)," >> "$JSON_REPORT"
echo "    \"report_type\": \"port_service_analysis\"" >> "$JSON_REPORT"
echo "  }," >> "$JSON_REPORT"
echo "  \"servers\": [" >> "$JSON_REPORT"

# 初始化CSV报告
echo "服务器名,IP地址,端口号,协议,服务名,进程名,PID,状态" > "$CSV_REPORT"

# 初始化文本报告
cat > "$REPORT_FILE" << EOF
==========================================
        服务器端口服务分析报告
==========================================

生成时间: $(date)
分析服务器数: $(echo "$PORT_FILES" | wc -w)

EOF

server_count=0
total_unique_ports=0
json_entries=0

for file in $PORT_FILES; do
    hostname=$(basename "$file" | sed 's/port_service_ps_\(.*\)\.txt/\1/')
    server_count=$((server_count + 1))
    
    echo -e "${BLUE}正在分析服务器: $hostname${NC}"
    
    # 提取IP地址
    ip_address=$(grep "服务器:" "$file" | head -1 | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+' || echo "未知")
    
    # 提取收集时间
    collection_time=$(grep "收集时间:" "$file" | head -1 | sed 's/.*收集时间: //')
    
    # 分析监听端口
    echo "  分析监听端口..."
    
    # 初始化当前服务器的端口跟踪数组
    declare -A current_server_ports
    
    # 提取监听端口信息
    if grep -A 50 "=== 所有监听端口及服务 ===" "$file" > /dev/null; then
        listening_section=$(sed -n '/=== 所有监听端口及服务 ===/,/^$/p' "$file" | grep -v "===" | grep -v "^$")
        
        if [ -n "$listening_section" ]; then
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
                        total_unique_ports=$((total_unique_ports + 1))
                        
                        # 添加到CSV报告
                        echo "$hostname,$ip_address,$port,$protocol,$service,$service,$process,监听" >> "$CSV_REPORT"
                        
                        # 添加到JSON报告
                        if [ $json_entries -gt 0 ]; then
                            echo "    ," >> "$JSON_REPORT"
                        fi
                        echo "    {" >> "$JSON_REPORT"
                        echo "      \"server\": \"$hostname\"," >> "$JSON_REPORT"
                        echo "      \"ip\": \"$ip_address\"," >> "$JSON_REPORT"
                        echo "      \"port\": \"$port\"," >> "$JSON_REPORT"
                        echo "      \"protocol\": \"$protocol\"," >> "$JSON_REPORT"
                        echo "      \"service\": \"$service\"," >> "$JSON_REPORT"
                        echo "      \"process\": \"$service\"," >> "$JSON_REPORT"
                        echo "      \"pid\": \"$process\"," >> "$JSON_REPORT"
                        echo "      \"status\": \"监听\"" >> "$JSON_REPORT"
                        echo "    }" >> "$JSON_REPORT"
                        
                        json_entries=$((json_entries + 1))
                    fi
                fi
            done
        fi
    fi
    
    # 分析运行服务
    echo "  分析运行服务..."
    running_services=""
    if grep -A 30 "=== 系统服务状态 ===" "$file" > /dev/null; then
        running_services=$(sed -n '/=== 系统服务状态 ===/,/^$/p' "$file" | grep "running" | head -10)
    fi
    
    # 分析端口与进程对应关系
    echo "  分析端口进程对应关系..."
    port_process_mapping=""
    if grep -A 20 "=== 端口与进程对应关系 (lsof) ===" "$file" > /dev/null; then
        lsof_info=$(sed -n '/=== 端口与进程对应关系 (lsof) ===/,/^$/p' "$file" | grep -v "===" | grep -v "^$" | head -10)
    fi
done

# 完成JSON报告
echo "  ]" >> "$JSON_REPORT"
echo "}" >> "$JSON_REPORT"

# 完成文本报告
cat >> "$REPORT_FILE" << EOF

==========================================
分析结果汇总 (去重统计)
==========================================
总服务器数: $server_count
总唯一端口数: $total_unique_ports

==========================================
详细分析结果
==========================================

EOF

# 添加详细分析到文本报告
for file in $PORT_FILES; do
    hostname=$(basename "$file" | sed 's/port_service_ps_\(.*\)\.txt/\1/')
    ip_address=$(grep "服务器:" "$file" | head -1 | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+' || echo "未知")
    
    cat >> "$REPORT_FILE" << EOF
=== 服务器: $hostname (IP: $ip_address) ===

监听端口列表 (去重):
EOF
    
    # 提取并格式化监听端口信息
    if grep -A 50 "=== 所有监听端口及服务 ===" "$file" > /dev/null; then
        listening_section=$(sed -n '/=== 所有监听端口及服务 ===/,/^$/p' "$file" | grep -v "===" | grep -v "^$")
        
        if [ -n "$listening_section" ]; then
            # 使用临时文件去重
            temp_file=$(mktemp)
            echo "$listening_section" | while IFS= read -r line; do
                if [[ "$line" =~ :[0-9]+ ]]; then
                    port=$(echo "$line" | grep -o ':[0-9]\+' | head -1 | sed 's/://')
                    protocol=$(echo "$line" | awk '{print $1}' | sed 's/.*://')
                    service=$(echo "$line" | grep -o '[^/]*$' | head -1)
                    process=$(echo "$line" | grep -o 'pid=[0-9]\+' | head -1 | sed 's/pid=//')
                    
                    if [ -n "$port" ]; then
                        echo "$port|$protocol|$service|$process" >> "$temp_file"
                    fi
                fi
            done
            
            # 去重并格式化输出
            if [ -s "$temp_file" ]; then
                sort -u "$temp_file" | while IFS='|' read -r port protocol service process; do
                    echo "  端口 $port ($protocol) -> $service (PID: $process)" >> "$REPORT_FILE"
                done
            fi
            
            rm -f "$temp_file"
        else
            echo "  未找到监听端口" >> "$REPORT_FILE"
        fi
    else
        echo "  未找到监听端口信息" >> "$REPORT_FILE"
    fi
    
    cat >> "$REPORT_FILE" << EOF

运行服务列表 (去重):
EOF
    
    # 提取运行服务信息
    if grep -A 30 "=== 系统服务状态 ===" "$file" > /dev/null; then
        running_services=$(sed -n '/=== 系统服务状态 ===/,/^$/p' "$file" | grep "running" | head -10)
        
        if [ -n "$running_services" ]; then
            # 使用临时文件去重
            temp_file=$(mktemp)
            echo "$running_services" | while IFS= read -r line; do
                service_name=$(echo "$line" | awk '{print $1}')
                status=$(echo "$line" | awk '{print $3}')
                if [ -n "$service_name" ]; then
                    echo "$service_name|$status" >> "$temp_file"
                fi
            done
            
            # 去重并格式化输出
            if [ -s "$temp_file" ]; then
                sort -u "$temp_file" | while IFS='|' read -r service_name status; do
                    echo "  $service_name -> $status" >> "$REPORT_FILE"
                done
            fi
            
            rm -f "$temp_file"
        else
            echo "  未找到运行服务" >> "$REPORT_FILE"
        fi
    else
        echo "  未找到服务状态信息" >> "$REPORT_FILE"
    fi
    
    cat >> "$REPORT_FILE" << EOF

------------------------------------------
EOF
done

# 添加端口服务映射表
cat >> "$REPORT_FILE" << EOF

==========================================
常用端口服务映射参考
==========================================
端口    服务名          说明
22      SSH            安全Shell
80      HTTP           Web服务
443     HTTPS          安全Web服务
3306    MySQL          MySQL数据库
5432    PostgreSQL     PostgreSQL数据库
6379    Redis          Redis缓存
8080    HTTP Alt       备用Web服务
9000    Jenkins        Jenkins CI/CD
27017   MongoDB        MongoDB数据库

==========================================
报告生成完成
==========================================
EOF

echo ""
echo "3. 报告生成完成！"
echo "=========================================="
echo -e "${GREEN}文本报告:${NC} $REPORT_FILE"
echo -e "${GREEN}JSON报告:${NC} $JSON_REPORT"
echo -e "${GREEN}CSV报告:${NC} $CSV_REPORT"
echo ""

echo "4. 快速查看命令:"
echo "=========================================="
echo -e "${YELLOW}查看文本报告:${NC}"
echo "  cat $REPORT_FILE"
echo ""
echo -e "${YELLOW}查看JSON报告:${NC}"
echo "  cat $JSON_REPORT"
echo ""
echo -e "${YELLOW}查看CSV报告:${NC}"
echo "  cat $CSV_REPORT"
echo ""
echo -e "${YELLOW}查看特定端口的服务:${NC}"
echo "  grep '端口 22' $REPORT_FILE"
echo "  grep '端口 80' $REPORT_FILE"
echo "  grep '端口 443' $REPORT_FILE"

echo ""
echo "分析完成！" 