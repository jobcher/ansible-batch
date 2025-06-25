#!/bin/bash

# 网络发现脚本
# 用于自动发现网络中的服务器并更新Ansible主机清单

set -e

# 配置变量
NETWORK_SUBNET=${1:-"192.168.1.0/24"}
OUTPUT_FILE="inventory/discovered_hosts.yml"
SSH_USER=${2:-"admin"}
SSH_KEY=${3:-"~/.ssh/id_rsa"}

echo "开始网络发现扫描..."
echo "扫描网段: $NETWORK_SUBNET"

# 检查nmap是否安装
if ! command -v nmap &> /dev/null; then
    echo "错误: nmap未安装，请先安装nmap"
    exit 1
fi

# 创建输出目录
mkdir -p inventory

# 扫描网络中的活跃主机
echo "正在扫描网络中的活跃主机..."
nmap -sn "$NETWORK_SUBNET" | grep -E "Nmap scan report" | awk '{print $5}' > /tmp/discovered_hosts.txt

# 检查是否发现主机
if [ ! -s /tmp/discovered_hosts.txt ]; then
    echo "未发现任何活跃主机"
    exit 0
fi

echo "发现的主机:"
cat /tmp/discovered_hosts.txt

# 生成Ansible主机清单
echo "生成Ansible主机清单..."
cat > "$OUTPUT_FILE" << EOF
all:
  children:
    discovered_servers:
      hosts:
EOF

# 为每个发现的主机添加配置
while IFS= read -r host; do
    if [ -n "$host" ]; then
        cat >> "$OUTPUT_FILE" << EOF
        discovered_${host//\./_}:
          ansible_host: $host
          ansible_user: $SSH_USER
          ansible_ssh_private_key_file: $SSH_KEY
          ansible_ssh_common_args: '-o StrictHostKeyChecking=no'
EOF
    fi
done < /tmp/discovered_hosts.txt

# 添加全局变量
cat >> "$OUTPUT_FILE" << EOF
      vars:
        ansible_python_interpreter: /usr/bin/python3
        ansible_ssh_timeout: 30
        ansible_command_timeout: 30
EOF

echo "主机清单已生成: $OUTPUT_FILE"
echo "发现主机数量: $(wc -l < /tmp/discovered_hosts.txt)"

# 清理临时文件
 