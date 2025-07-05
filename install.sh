#!/bin/bash

# Telegram Music Bot Auto Installer
# ================================

set -e

echo "🎵 ==============================================="
echo "   نصب خودکار ربات موزیک تلگرام"
echo "   Telegram Music Bot Auto Installer"
echo "=============================================== 🎵"
echo

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   log_error "این اسکریپت را با root اجرا نکنید!"
   echo "لطفاً با کاربر عادی اجرا کنید:"
   echo "bash install.sh"
   exit 1
fi

# Detect OS
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if [[ -f /etc/debian_version ]]; then
        OS="debian"
        log_info "سیستم عامل: Debian/Ubuntu"
    elif [[ -f /etc/redhat-release ]]; then
        OS="redhat"
        log_info "سیستم عامل: RedHat/CentOS"
    else
        OS="linux"
        log_info "سیستم عامل: Linux (ناشناخته)"
    fi
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
    log_info "سیستم عامل: macOS"
else
    OS="unknown"
    log_warning "سیستم عامل ناشناخته: $OSTYPE"
fi

# Check internet connection
log_info "بررسی اتصال اینترنت..."
if ! ping -c 1 google.com &> /dev/null; then
    log_error "اتصال اینترنت موجود نیست!"
    exit 1
fi
log_success "اتصال اینترنت برقرار است"

# Update system packages
log_info "بروزرسانی بسته‌های سیستم..."
case $OS in
    "debian")
        sudo apt update && sudo apt upgrade -y
        ;;
    "redhat")
        sudo yum update -y
        ;;
    "macos")
        # Update Homebrew if installed
        if command -v brew &> /dev/null; then
            brew update
        fi
        ;;
esac
log_success "بسته‌های سیستم بروزرسانی شدند"

# Install system dependencies
log_info "نصب وابستگی‌های سیستم..."
case $OS in
    "debian")
        sudo apt install -y \
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
            wget
        ;;
    "redhat")
        sudo yum install -y \
            lua \
            luarocks \
            gcc \
            gcc-c++ \
            make \
            readline-devel \
            openssl-devel \
            ffmpeg \
            python3 \
            python3-pip \
            git \
            curl \
            wget
        ;;
    "macos")
        if ! command -v brew &> /dev/null; then
            log_info "نصب Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        brew install lua luarocks ffmpeg python3 git curl wget
        ;;
esac
log_success "وابستگی‌های سیستم نصب شدند"

# Install yt-dlp
log_info "نصب yt-dlp..."
python3 -m pip install --upgrade yt-dlp
log_success "yt-dlp نصب شد"

# Install Lua packages
log_info "نصب کتابخانه‌های Lua..."
luarocks install --local luasocket
luarocks install --local lua-cjson
luarocks install --local ltn12
luarocks install --local mime
log_success "کتابخانه‌های Lua نصب شدند"

# Add local luarocks to PATH
echo 'export PATH="$HOME/.luarocks/bin:$PATH"' >> ~/.bashrc
echo 'export LUA_PATH="$HOME/.luarocks/share/lua/5.3/?.lua;$HOME/.luarocks/share/lua/5.3/?/init.lua;;"' >> ~/.bashrc
echo 'export LUA_CPATH="$HOME/.luarocks/lib/lua/5.3/?.so;;"' >> ~/.bashrc

# Create project directories
log_info "ایجاد پوشه‌های پروژه..."
mkdir -p downloads logs web
log_success "پوشه‌های پروژه ایجاد شدند"

# Set permissions
chmod +x main.lua
chmod +x bot.lua
chmod +x web_server.lua

# Check if config needs setup
if [[ ! -f "config.lua" ]] || grep -q "YOUR_BOT_TOKEN" config.lua; then
    log_warning "نیاز به پیکربندی config.lua"
    echo
    echo "برای تکمیل نصب، لطفاً مراحل زیر را انجام دهید:"
    echo
    echo "1. ربات تلگرام از @BotFather بسازید"
    echo "2. API ID و Hash از my.telegram.org دریافت کنید"
    echo "3. فایل config.lua را ویرایش کنید:"
    echo "   nano config.lua"
    echo
    echo "4. مقادیر زیر را تنظیم کنید:"
    echo "   - bot_token"
    echo "   - api_id"
    echo "   - api_hash"
    echo "   - phone_number"
    echo "   - owner_id"
    echo
fi

# Test installation
log_info "تست نصب..."

# Test Lua
if lua -e "print('Lua works!')" &> /dev/null; then
    log_success "Lua کار می‌کند"
else
    log_error "مشکل در نصب Lua"
    exit 1
fi

# Test required packages
for pkg in socket cjson ltn12 mime; do
    if lua -e "require('$pkg'); print('$pkg: OK')" &> /dev/null; then
        log_success "$pkg نصب شده"
    else
        log_error "مشکل در نصب $pkg"
        exit 1
    fi
done

# Test external tools
for tool in ffmpeg yt-dlp; do
    if command -v $tool &> /dev/null; then
        log_success "$tool در دسترس است"
    else
        log_error "$tool در دسترس نیست"
        exit 1
    fi
done

echo
log_success "نصب با موفقیت تکمیل شد! 🎉"
echo
echo "📋 مراحل بعدی:"
echo "1. فایل config.lua را ویرایش کنید"
echo "2. ربات را اجرا کنید:"
echo "   source ~/.bashrc"
echo "   lua main.lua"
echo
echo "🌐 پنل وب در آدرس زیر در دسترس خواهد بود:"
echo "   http://localhost:8080"
echo
echo "📚 برای راهنمای کامل README.md را مطالعه کنید"
echo
echo "🆘 در صورت بروز مشکل، issue در GitHub ایجاد کنید"

# Create a simple start script
cat > start.sh << 'EOF'
#!/bin/bash
echo "🎵 Starting Telegram Music Bot..."
source ~/.bashrc
lua main.lua
EOF

chmod +x start.sh
log_success "اسکریپت start.sh ایجاد شد"

echo
echo "برای شروع: ./start.sh"