#!/usr/bin/env bash

# 加载环境变量
# ls -la
# cat ./.devcontainer/.env
if [ -f ./.devcontainer/.env ]; then
  # 从 .env 文件加载环境变量
  export $(grep -v '^#' ./.devcontainer/.env | xargs)
fi

# 启动你的应用程序
exec "$@"


# npm install -g @devcontainers/cli

# pipx install shfmt-py
# 
# this will add hover annotations in shell script files, assuming mads-hartmann.bash-ide-vscod is installed
# docker container run --name explainshell --restart always -p 5000:5000 -d spaceinvaderone/explainshell

