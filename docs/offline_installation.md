# 离线安装指南

当网络连接不稳定或无法访问PyPI时，可以使用以下方法进行离线安装。

## 方法1：使用国内镜像源

### 配置pip镜像源

```bash
# 创建pip配置目录
mkdir -p ~/.pip

# 创建配置文件
cat > ~/.pip/pip.conf << EOF
[global]
index-url = https://pypi.tuna.tsinghua.edu.cn/simple
trusted-host = pypi.tuna.tsinghua.edu.cn
timeout = 120
retries = 3
EOF
```

### 使用镜像源安装

```bash
# 升级pip
pip install --upgrade pip -i https://pypi.tuna.tsinghua.edu.cn/simple

# 安装Ansible
pip install ansible -i https://pypi.tuna.tsinghua.edu.cn/simple

# 安装其他依赖
pip install -r requirements-minimal.txt -i https://pypi.tuna.tsinghua.edu.cn/simple
```

## 方法2：下载离线包

### 在有网络的环境中下载包

```bash
# 创建下载目录
mkdir -p offline_packages

# 下载Ansible及其依赖
pip download ansible -d offline_packages

# 下载其他依赖
pip download -r requirements-minimal.txt -d offline_packages
```

### 在离线环境中安装

```bash
# 复制离线包到目标机器
scp -r offline_packages user@target-machine:/tmp/

# 在目标机器上安装
pip install --no-index --find-links /tmp/offline_packages ansible
```

## 方法3：使用系统包管理器

### CentOS/RHEL

```bash
# 启用EPEL仓库
sudo yum install -y epel-release

# 安装Ansible
sudo yum install -y ansible

# 安装nmap
sudo yum install -y nmap
```

### Ubuntu/Debian

```bash
# 更新包列表
sudo apt-get update

# 安装Ansible
sudo apt-get install -y ansible

# 安装nmap
sudo apt-get install -y nmap
```

### macOS

```bash
# 使用Homebrew
brew install ansible
brew install nmap
```

## 方法4：使用Docker

### 创建Dockerfile

```dockerfile
FROM python:3.9-slim

# 安装系统依赖
RUN apt-get update && apt-get install -y \
    nmap \
    openssh-client \
    && rm -rf /var/lib/apt/lists/*

# 配置pip镜像源
RUN mkdir -p ~/.pip && \
    echo "[global]" > ~/.pip/pip.conf && \
    echo "index-url = https://pypi.tuna.tsinghua.edu.cn/simple" >> ~/.pip/pip.conf && \
    echo "trusted-host = pypi.tuna.tsinghua.edu.cn" >> ~/.pip/pip.conf

# 安装Python依赖
COPY requirements-minimal.txt /tmp/
RUN pip install -r /tmp/requirements-minimal.txt

# 复制项目文件
COPY . /app
WORKDIR /app

# 设置入口点
ENTRYPOINT ["ansible-playbook"]
```

### 构建和运行

```bash
# 构建镜像
docker build -t ansible-batch .

# 运行扫描
docker run -v $(pwd):/app ansible-batch site.yml
```

## 故障排除

### 网络连接问题

1. **检查网络连接**
   ```bash
   ping pypi.org
   curl -I https://pypi.org
   ```

2. **使用代理**
   ```bash
   export HTTP_PROXY=http://proxy:port
   export HTTPS_PROXY=http://proxy:port
   pip install ansible
   ```

3. **增加超时时间**
   ```bash
   pip install ansible --timeout 300 --retries 5
   ```

### 编译错误

1. **安装编译工具**
   ```bash
   # CentOS/RHEL
   sudo yum groupinstall -y "Development Tools"
   
   # Ubuntu/Debian
   sudo apt-get install -y build-essential
   ```

2. **使用预编译包**
   ```bash
   pip install --only-binary=all ansible
   ```

### 权限问题

1. **使用用户安装**
   ```bash
   pip install --user ansible
   ```

2. **使用虚拟环境**
   ```bash
   python3 -m venv ansible_env
   source ansible_env/bin/activate
   pip install ansible
   ```

## 验证安装

```bash
# 检查Ansible版本
ansible --version

# 检查nmap版本
nmap --version

# 测试Ansible连接
ansible all -m ping
```

## 推荐方案

对于网络不稳定的环境，推荐使用以下方案：

1. **首选**：使用系统包管理器安装Ansible和nmap
2. **备选**：配置国内镜像源进行pip安装
3. **最后**：使用Docker容器运行

这样可以避免复杂的依赖编译问题，提高安装成功率。 