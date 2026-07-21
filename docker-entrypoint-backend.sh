#!/bin/bash
set -e

if [ -f /app/.env.host ]; then
    cp /app/.env.host /app/.env
else
    cp /app/.env.example /app/.env
fi

sed -i 's/^BPMUSIC_HOST=.*/BPMUSIC_HOST=0.0.0.0/' /app/.env
sed -i 's/^BPMUSIC_PANEL_HOST=.*/BPMUSIC_PANEL_HOST=0.0.0.0/' /app/.env

echo "[entrypoint] 启动管理面板..."
python3 admin_panel.py &
PANEL_PID=$!

echo "[entrypoint] 启动音乐后端..."
exec python3 mds.py
