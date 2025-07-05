# Telegram Music Bot Dockerfile
FROM ubuntu:22.04

# Metadata
LABEL maintainer="Telegram Music Bot Team"
LABEL description="Telegram Music Bot with Glass Web Panel"
LABEL version="1.0.0"

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Tehran
ENV LANG=fa_IR.UTF-8
ENV LC_ALL=fa_IR.UTF-8

# Install system dependencies
RUN apt-get update && apt-get install -y \
    lua5.3 \
    luarocks \
    build-essential \
    libreadline-dev \
    libssl-dev \
    ffmpeg \
    python3 \
    python3-pip \
    git \
    curl \
    wget \
    locales \
    tzdata \
    && rm -rf /var/lib/apt/lists/*

# Set timezone
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Set locale
RUN locale-gen fa_IR.UTF-8

# Install Python dependencies
RUN python3 -m pip install --upgrade yt-dlp

# Install Lua dependencies
RUN luarocks install luasocket && \
    luarocks install lua-cjson && \
    luarocks install ltn12 && \
    luarocks install mime

# Create app directory
WORKDIR /app

# Create directories for the bot
RUN mkdir -p downloads logs web

# Copy application files
COPY main.lua .
COPY config.lua .
COPY bot.lua .
COPY web_server.lua .
COPY web/ ./web/

# Create a non-root user
RUN useradd -m -u 1001 musicbot && \
    chown -R musicbot:musicbot /app

# Switch to non-root user
USER musicbot

# Set environment variables for Lua
ENV LUA_PATH="/usr/local/share/lua/5.3/?.lua;/usr/local/share/lua/5.3/?/init.lua;;"
ENV LUA_CPATH="/usr/local/lib/lua/5.3/?.so;;"

# Expose web panel port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080 || exit 1

# Volume for persistent data
VOLUME ["/app/downloads", "/app/logs"]

# Start the bot
CMD ["lua", "main.lua"]