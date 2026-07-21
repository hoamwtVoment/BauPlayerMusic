# BauPlayerMusic 部署镜像
# 多阶段构建：编译 C++ 服务端 → Python 运行时

# ==================== 阶段 1: 编译 ====================
FROM ubuntu:latest AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential cmake pkg-config \
    libcurl4-openssl-dev \
    libfreetype-dev \
    libglew-dev \
    libogg-dev \
    libopus-dev \
    libopusfile-dev \
    libpng-dev \
    libsdl2-dev \
    libsqlite3-dev \
    libssl-dev \
    libwavpack-dev \
    zlib1g-dev \
    ca-certificates \
    curl \
    python3 \
    && rm -rf /var/lib/apt/lists/*

# Rust 工具链
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- --default-toolchain stable -y
ENV PATH="/root/.cargo/bin:${PATH}"

WORKDIR /build
COPY . .

# 编译服务端和地图缝合器
RUN cmake -S . -B build-server \
    -DCLIENT=OFF \
    -DWEBSOCKETS=OFF \
    -DMYSQL=OFF \
    -DPREFER_BUNDLED_LIBS=ON \
    -DCMAKE_BUILD_TYPE=Release \
    && cmake --build build-server --config Release --target game-server music_map_patcher -- -j$(nproc)

# ==================== 阶段 2: 运行时 ====================
FROM ubuntu:latest

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-pip python3-venv \
    ffmpeg \
    libcurl4t64 \
    libfreetype6 \
    libopus0 \
    libopusfile0 \
    libsdl2-2.0-0 \
    libsqlite3-0 \
    libssl3t64 \
    libwavpack1 \
    libzstd1 \
    ca-certificates \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 编译产物
COPY --from=builder /build/build-server/DDNet-Server .
COPY --from=builder /build/build-server/music_map_patcher .

# Python 依赖
COPY requirements.txt .
RUN pip install --no-cache-dir --break-system-packages -r requirements.txt

# 后端脚本
COPY mds.py .
COPY admin_panel.py .
COPY qqbot_bridge.py .
COPY music_stats.py .
COPY mds_aliyun.py .
COPY turtle_soup.py .
COPY undercover_game.py .
COPY admin_web/ admin_web/
COPY data/ data/

# 配置模板
COPY storage.cfg .
COPY .env.example .
COPY myServerconfig.example.cfg .

# 运行时目录
RUN mkdir -p data/musicso/covers data/musico/prepared_maps data/webmaps

# 入口脚本
COPY docker-entrypoint.sh .
RUN chmod +x docker-entrypoint.sh

EXPOSE 8303/udp

ENTRYPOINT ["./docker-entrypoint.sh"]
