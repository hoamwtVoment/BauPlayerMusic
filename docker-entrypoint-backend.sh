#!/bin/bash
set -e

if [ ! -f /app/.env ]; then
    cp /app/.env.example /app/.env
fi

# 容器间通信需要监听 0.0.0.0
sed -i 's/^BPMUSIC_HOST=.*/BPMUSIC_HOST=0.0.0.0/' /app/.env
# 管理面板也监听 0.0.0.0
sed -i 's/^BPMUSIC_PANEL_HOST=.*/BPMUSIC_PANEL_HOST=0.0.0.0/' /app/.env

exec python3 mds.py
