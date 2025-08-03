#!/bin/bash

ARCH=$(uname -m)
FILE_NAME="hubproxy"
CONFIG_FILE="config.toml"
LOG_FILE="hubproxy.log"
PORT=5000  # 默认端口

# 根据架构设置下载URL
case "$ARCH" in
    arm64|aarch64) ARCH="arm64" ;;
    amd64|x86_64)  ARCH="amd64" ;;
    *) 
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

BASE_URL="https://github.com/eooce/hubproxy/releases/download/HubProxy"
FILE_URL="${BASE_URL}/hubproxy-linux-${ARCH}"

# 下载文件（如果不存在）
if [ ! -f "./$FILE_NAME" ]; then
    echo -e "\e[1;32mDownloading $FILE_NAME for $ARCH architecture...\e[0m"
    if ! curl -L -sS -o "./$FILE_NAME" "$FILE_URL"; then
        echo -e "\e[1;31mFailed to download $FILE_URL\e[0m"
        exit 1
    fi
    chmod +x "./$FILE_NAME"
fi

# 下载配置文件（如果不存在）
if [ ! -f "./$CONFIG_FILE" ]; then
    echo -e "\e[1;32mDownloading default config file...\e[0m"
    if ! curl -L -sS -o "./$CONFIG_FILE" "${BASE_URL}/config.toml"; then
        echo -e "\e[1;33mWarning: Failed to download config file, using default settings\e[0m"
    fi
fi

# 检查是否已运行（兼容Alpine的检查方式）
is_process_running() {
    # 方法1：检查/proc目录（最可靠）
    for pid in /proc/[0-9]*; do
        if [ -f "$pid/cmdline" ] && grep -q "$FILE_NAME" "$pid/cmdline" 2>/dev/null; then
            return 0
        fi
    done
    
    # 方法2：使用ps（Alpine的ps支持这些选项）
    if ps -o args | grep -v grep | grep -q "./$FILE_NAME"; then
        return 0
    fi
    
    # 方法3：检查端口占用（如果知道端口号）
    if netstat -tuln 2>/dev/null | grep -q ":$PORT "; then
        return 0
    fi
    
    return 1
}

if is_process_running; then
    echo -e "\e[1;33mHubProxy is already running\e[0m"
    exit 0
fi

# 启动服务
echo -e "\e[1;34mStarting HubProxy...\e[0m"
nohup "./$FILE_NAME" > "$LOG_FILE" 2>&1 &

# 等待并检查是否启动成功
sleep 3
if ! is_process_running; then
    echo -e "\e[1;31mFailed to start HubProxy. Check $LOG_FILE for details.\e[0m"
    exit 1
fi

# 获取IP地址
get_local_ip() {
    # 方法1：使用ip命令（Alpine默认有iproute2）
    ip=$(ip -o -4 addr show scope global 2>/dev/null | awk '{print $4}' | cut -d'/' -f1 | head -n1)
    
    # 方法2：使用ifconfig（Alpine默认有busybox ifconfig）
    [ -z "$ip" ] && ip=$(ifconfig 2>/dev/null | grep -oE 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -oE '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1' | head -n1)
    
    # 方法3：使用hostname
    [ -z "$ip" ] && ip=$(hostname -i 2>/dev/null | awk '{print $1}')
    
    echo "${ip:-localhost}"
}

IP=$(get_local_ip)

echo -e "\e[1;32mHubProxy started successfully\e[0m"
echo -e "\e[1;32mAccess URL: http://${IP}:${PORT}\e[0m"
echo -e "\e[1;33mLogs are being written to $LOG_FILE\e[0m"
