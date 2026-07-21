#!/bin/bash
set -e

# 首次启动时从模板复制配置（如果未挂载）
if [ ! -f /app/.env ]; then
    echo "[entrypoint] 初始化 .env 配置..."
    cp /app/.env.example /app/.env
fi

if [ ! -f /app/myServerconfig.cfg ]; then
    echo "[entrypoint] 初始化 myServerconfig.cfg..."
    cp /app/myServerconfig.example.cfg /app/myServerconfig.cfg
fi

cleanup() {
    echo "[entrypoint] 正在停止所有服务..."
    kill $SERVER_PID 2>/dev/null || true
    kill $BACKEND_PID 2>/dev/null || true
    wait $SERVER_PID 2>/dev/null || true
    wait $BACKEND_PID 2>/dev/null || true
    echo "[entrypoint] 已停止"
}
trap cleanup EXIT SIGTERM SIGINT SIGQUIT

echo "[entrypoint] 启动 Python 后端..."
python3 mds.py &
BACKEND_PID=$!

# 等待后端健康检查
echo "[entrypoint] 等待后端就绪..."
for i in $(seq 1 30); do
    if curl -s http://127.0.0.1:5000/health > /dev/null 2>&1; then
        echo "[entrypoint] 后端就绪 (PID=$BACKEND_PID)"
        break
    fi
    sleep 1
done

echo "[entrypoint] 启动 DDNet 服务端..."
./DDNet-Server &
SERVER_PID=$!

wait $SERVER_PID
cleanup
