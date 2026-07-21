#!/bin/bash
set -e

if [ -f /app/myServerconfig.cfg ]; then
    cp /app/myServerconfig.cfg /tmp/myServerconfig.cfg
else
    cp /app/myServerconfig.example.cfg /tmp/myServerconfig.cfg
fi

sed -i 's|sv_music_backend_url ".*"|sv_music_backend_url "http://backend:5000"|' /tmp/myServerconfig.cfg

# 替换到 app 目录，服务端启动后自动加载
cp /tmp/myServerconfig.cfg /app/myServerconfig.cfg

exec ./DDNet-Server
