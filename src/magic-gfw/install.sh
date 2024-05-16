#!/usr/bin/env bash
#-------------------------------------------------------------------------------------------------------------
# 修改更新源为国内镜像并安装必要的包
#-------------------------------------------------------------------------------------------------------------
set -e

# 检查是否以 root 身份运行
if [ "$(id -u)" -ne 0 ]; then
    echo '脚本必须以 root 身份运行。'
    exit 1
fi

# 检测系统类型
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VERSION=$VERSION_ID
elif [ -f /etc/debian_version ]; then
    OS=debian
    VERSION=$(cat /etc/debian_version)
else
    echo "无法检测系统类型。"
    exit 1
fi

echo "检测到的操作系统：$OS 版本：$VERSION"

# 根据系统类型修改源
case "$OS" in
    debian)
        if [[ "$VERSION" == 9* ]]; then
            echo "deb http://archive.debian.org/debian/ stretch main contrib non-free" > /etc/apt/sources.list
            echo "deb http://archive.debian.org/debian/ stretch-proposed-updates main contrib non-free" >> /etc/apt/sources.list
            echo "deb http://archive.debian.org/debian-security stretch/updates main contrib non-free" >> /etc/apt/sources.list
        fi
        sed -i "s@http://\(deb\|security\).debian.org@http://mirrors.aliyun.com@g" /etc/apt/sources.list
        ;;
    ubuntu)
        sed -i "s@\(archive\|security\).ubuntu.com@mirrors.aliyun.com@g" /etc/apt/sources.list
        ;;
    alpine)
        sed -i "s@dl-cdn.alpinelinux.org@mirrors.aliyun.com@g" /etc/apk/repositories
        ;;
    *)
        echo "不支持的操作系统：$OS"
        exit 1
        ;;
esac

# 更新包列表
case "$OS" in
    debian|ubuntu)
        apt-get update
        ;;
    alpine)
        apk update
        ;;
    *)
        echo "无法更新包列表，不支持的操作系统：$OS"
        exit 1
        ;;
esac

echo "源已成功更改并更新了包列表。"