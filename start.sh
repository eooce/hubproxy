#!/bin/bash

ARCH=$(uname -m)
FILE_NAME="hubproxy"

# 根据架构设置下载URL
if [ "$ARCH" = "arm64" ] || [ "$ARCH" = "aarch64" ]; then
    ARCH="arm64"
elif [ "$ARCH" = "amd64" ] || [ "$ARCH" = "x86_64" ]; then
    ARCH="amd64"
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

BASE_URL="https://github.com/eooce/hubproxy/releases/download/HubProxy"
FILE_URL="${BASE_URL}/hubproxy-linux-${ARCH}"

# 如果文件不存在，则下载
if [ ! -f "./$FILE_NAME" ]; then
    echo -e "\e[1;32mDownloading $FILE_NAME for $ARCH architecture...\e[0m"
    curl -L -sS -o "./$FILE_NAME" "$FILE_URL" || { echo -e "\e[1;31mFailed to download $FILE_URL\e[0m"; exit 1; }
    chmod +x "./$FILE_NAME"
fi

# 启动 webssh
echo -e "\e[1;34mStarting HubProxy...\e[0m"

# 判断启动参数组合
nohup "./$FILE_NAME" >/dev/null 2>&1 &

sleep 3

# 检查进程是否运行
if ps | grep -v grep | grep -q "./$FILE_NAME"; then
    echo -e "\e[1;32mHubProxy is running\e[0m"
else
    echo -e "\e[1;31mFailed to start HubProxy\e[0m"
    exit 1
fi

# 获取IP地址
IP=$(curl -s --max-time 1 ipv4.ip.sb || curl -s --max-time 1 api.ipify.org || {
    ipv6=$(curl -s --max-time 1 ipv6.ip.sb)
    echo "[$ipv6]"
} || echo "未能获取到IP")

# 显示访问信息
echo -e "\e[1;32mwebssh 已启动，访问 http://${IP}:5000\e[0m"
