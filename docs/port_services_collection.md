# 端口服务信息收集功能

## 功能说明

此功能可以收集每台服务器上的所有端口、对应的服务以及进程信息，包括：

- **监听端口**: 服务器上所有监听的端口
- **连接端口**: 当前建立的连接
- **端口与进程对应关系**: 使用 `lsof` 命令获取
- **进程详细信息**: 包括按CPU和内存排序的进程列表
- **服务状态**: 系统服务的运行状态

## 收集的信息类型

### 1. 端口服务信息
```bash
# 监听端口
ss -tulnp 或 netstat -tulnp

# 连接端口
ss -tunp 或 netstat -tunp
```

### 2. 端口进程对应关系
```bash
# 使用lsof获取端口与进程的对应关系
lsof -i -Pn
```

### 3. 进程详细信息
```bash
# 所有进程
ps aux

# 按CPU使用率排序的前20个进程
ps aux --sort=-%cpu | head -20

# 按内存使用率排序的前20个进程
ps aux --sort=-%mem | head -20
```

### 4. 服务状态信息
```bash
# systemd系统
systemctl list-units --type=service --all

# 传统init系统
service --status-all
```

## 使用方法

### 1. 收集端口服务信息

```bash
# 收集所有资产信息（包括端口服务）
ansible-playbook site_python27.yml --tags asset

# 仅收集端口服务信息
ansible-playbook site_python27.yml --tags ports,services,processes
```

### 2. 查看端口服务信息

```bash
# 使用专用脚本查看
./scripts/view_port_services.sh

# 直接查看生成的文件
ls /tmp/port_service_ps_*.txt
cat /tmp/port_service_ps_服务器名.txt
```

### 3. 在报告中查看

端口服务信息已集成到所有报告格式中：

- **JSON报告**: 包含完整的端口服务信息
- **CSV报告**: 包含端口数、服务数、进程数统计
- **汇总报告**: 包含详细的端口服务信息和统计

## 生成的文件

### 1. 端口服务信息文件
位置: `/tmp/port_service_ps_服务器名.txt`

内容包含：
- 服务器基本信息
- 端口与服务信息
- 端口与进程对应关系
- 进程详细信息
- 服务状态信息

### 2. 报告文件
位置: `/tmp/asset_reports/`

包含端口服务信息的各种格式报告。

## 常用端口服务映射

| 端口 | 服务名 | 说明 |
|------|--------|------|
| 22 | SSH | 安全Shell |
| 80 | HTTP | Web服务 |
| 443 | HTTPS | 安全Web服务 |
| 3306 | MySQL | MySQL数据库 |
| 5432 | PostgreSQL | PostgreSQL数据库 |
| 6379 | Redis | Redis缓存 |
| 8080 | HTTP Alt | 备用Web服务 |
| 9000 | Jenkins | Jenkins CI/CD |
| 27017 | MongoDB | MongoDB数据库 |

## 查看特定端口

```bash
# 查看SSH端口(22)
grep -r ':22' /tmp/port_service_ps_*.txt

# 查看Web服务端口(80,443)
grep -r ':80\|:443' /tmp/port_service_ps_*.txt

# 查看数据库端口
grep -r ':3306\|:5432\|:6379\|:27017' /tmp/port_service_ps_*.txt
```

## 统计信息

脚本会自动统计：
- 每台服务器的监听端口数
- 每台服务器的运行服务数
- 每台服务器的进程数
- 所有服务器的汇总统计

## 注意事项

1. **权限要求**: 某些端口信息可能需要管理员权限才能查看
2. **命令可用性**: 脚本会自动检测可用的命令（ss/netstat, lsof等）
3. **数据量**: 进程信息可能很大，报告中使用截断显示
4. **实时性**: 收集的信息是执行时的快照，不是实时数据

## 故障排除

### 1. 端口信息为空
- 检查是否有网络连接
- 确认目标服务器可访问
- 检查SSH连接权限

### 2. lsof命令不可用
- 在CentOS/RHEL上安装: `yum install lsof`
- 在Ubuntu/Debian上安装: `apt install lsof`

### 3. 进程信息不完整
- 检查是否有足够的权限
- 确认Python解释器路径正确 