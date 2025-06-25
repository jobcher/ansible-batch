# Ansible 服务器资产扫描工具

这是一个基于Ansible的服务器资产扫描和发现工具，可以批量扫描网络中的服务器并获取详细的资产状态信息。

## 功能特性

- 🔍 **网络发现**: 自动扫描网络中的活跃主机
- 📊 **资产收集**: 收集服务器的硬件、软件、网络等详细信息
- 📈 **状态监控**: 监控服务器的运行状态和性能指标
- 📋 **报告生成**: 生成多种格式的资产报告（JSON、HTML、CSV、TXT）
- 🔧 **灵活配置**: 支持自定义扫描范围和参数

## 项目结构

```
ansible-batch/
├── inventory/
│   └── hosts.yml              # 主机清单文件
├── roles/
│   ├── asset_discovery/       # 资产发现角色
│   ├── network_scanner/       # 网络扫描角色
│   └── report_generator/      # 报告生成角色
├── site.yml                   # 主playbook
├── ansible.cfg               # Ansible配置文件
└── README.md                 # 项目说明
```

## 快速开始

### 1. 环境准备

确保您的系统已安装以下软件：
- Ansible 2.9+
- Python 3.6+
- nmap (用于网络扫描)

### 2. 配置主机清单

编辑 `inventory/hosts.yml` 文件，添加您要扫描的服务器：

```yaml
all:
  children:
    servers:
      hosts:
        server1:
          ansible_host: 192.168.1.10
          ansible_user: admin
          ansible_ssh_private_key_file: ~/.ssh/id_rsa
        server2:
          ansible_host: 192.168.1.11
          ansible_user: admin
          ansible_ssh_private_key_file: ~/.ssh/id_rsa
```

### 3. 配置SSH密钥

确保您有访问目标服务器的SSH密钥：

```bash
# 生成SSH密钥（如果还没有）
ssh-keygen -t rsa -b 4096

# 将公钥复制到目标服务器
ssh-copy-id admin@192.168.1.10
```

### 4. 运行扫描

```bash
# 运行完整的资产扫描
ansible-playbook site.yml

# 只运行资产发现
ansible-playbook site.yml --tags asset,discovery

# 只运行网络扫描
ansible-playbook site.yml --tags network,scanner

# 只生成报告
ansible-playbook site.yml --tags report,generator
```

## 配置选项

### 网络扫描配置

在 `roles/network_scanner/defaults/main.yml` 中配置：

```yaml
network_scanner:
  network_subnet: "192.168.1.0/24"  # 扫描网段
  scan_ports: [22, 80, 443, 3306]   # 扫描端口
  scan_timeout: 300                  # 扫描超时时间
```

### 资产收集配置

在 `roles/asset_discovery/defaults/main.yml` 中配置：

```yaml
asset_discovery:
  detailed_info: true      # 收集详细信息
  collect_network: true    # 收集网络信息
  collect_services: true   # 收集服务信息
  collect_security: true   # 收集安全信息
```

### 报告配置

在 `roles/report_generator/defaults/main.yml` 中配置：

```yaml
report_generator:
  report_path: "/tmp/asset_reports"  # 报告保存路径
  formats: [json, html, csv, txt]    # 报告格式
  include_details: true              # 包含详细信息
```

## 收集的信息

### 系统信息
- 操作系统类型和版本
- 内核版本
- 系统架构
- 主机名和域名

### 硬件信息
- CPU型号和核心数
- 内存容量和使用情况
- 磁盘空间和分区信息
- 网络接口信息

### 网络信息
- IP地址配置
- 网络接口状态
- 路由表信息
- 开放端口列表

### 系统状态
- 系统运行时间
- 负载平均值
- 运行的服务
- 用户登录信息

## 报告格式

### JSON格式
结构化的JSON数据，便于程序处理和分析。

### HTML格式
美观的网页报告，包含图表和详细信息。

### CSV格式
表格格式，便于在Excel等工具中分析。

### TXT格式
纯文本格式，便于查看和打印。

## 使用示例

### 扫描特定网段

```bash
# 设置环境变量
export NETWORK_SUBNET="10.0.0.0/24"

# 运行扫描
ansible-playbook site.yml -e "network_subnet=$NETWORK_SUBNET"
```

### 生成特定格式报告

```bash
# 只生成HTML报告
ansible-playbook site.yml --tags report,generator -e "report_formats=['html']"
```

### 并行扫描

```bash
# 增加并行度
ansible-playbook site.yml -f 20
```

## 故障排除

### 常见问题

1. **SSH连接失败**
   - 检查SSH密钥配置
   - 确认目标服务器SSH服务运行正常
   - 检查防火墙设置

2. **权限问题**
   - 确保用户有足够的权限执行命令
   - 检查sudo配置

3. **网络扫描失败**
   - 确认nmap已安装
   - 检查网络连接
   - 确认有扫描权限

### 调试模式

```bash
# 启用详细输出
ansible-playbook site.yml -vvv

# 测试连接
ansible all -m ping

# 检查主机清单
ansible-inventory --list
```

## 安全注意事项

- 确保只在授权的网络中进行扫描
- 遵守相关法律法规和公司政策
- 保护收集的敏感信息
- 定期更新SSH密钥和密码

## 贡献

欢迎提交Issue和Pull Request来改进这个项目。

## 许可证

MIT License 