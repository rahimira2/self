# 🎵 ربات موزیک تلگرام با پنل شیشه‌ای

یک ربات موزیک قدرتمند برای تلگرام با پنل کنترل وب زیبا و مدرن که به زبان Lua نوشته شده است.

![Bot Demo](https://via.placeholder.com/800x400/667eea/ffffff?text=🎵+Telegram+Music+Bot)

## ✨ ویژگی‌ها

### 🎧 ویژگی‌های موزیک
- پخش موزیک از یوتیوب و سایر پلتفرم‌ها
- پخش در ویس چت گروه‌ها
- صف پخش هوشمند
- کنترل صدا
- جستجوی پیشرفته موزیک
- پشتیبانی از فرمت‌های مختلف صوتی

### 🌐 پنل وب شیشه‌ای
- طراحی مدرن با افکت شیشه‌ای (Glassmorphism)
- رابط کاربری تمام فارسی
- کنترل کامل ربات از طریق وب
- نمایش آمار زنده
- طراحی ریسپانسیو (موبایل فرندلی)

### ⚡ عملکرد
- پردازش موازی درخواست‌ها
- مدیریت حافظه بهینه
- ثبت لاگ کامل
- بازیابی خودکار از خطا

## 📋 پیش‌نیازها

### نرم‌افزارهای مورد نیاز
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install lua5.3 lua-socket lua-cjson ffmpeg yt-dlp

# CentOS/RHEL
sudo yum install lua lua-socket lua-cjson ffmpeg
pip3 install yt-dlp

# macOS
brew install lua ffmpeg yt-dlp
luarocks install luasocket lua-cjson
```

### کتابخانه‌های Lua
```bash
# نصب luarocks (اگر نصب نیست)
sudo apt install luarocks

# نصب کتابخانه‌ها
luarocks install luasocket
luarocks install lua-cjson
luarocks install ltn12
luarocks install mime
```

### API Credentials
1. ربات تلگرام از [@BotFather](https://t.me/BotFather) بسازید
2. API ID و Hash از [my.telegram.org](https://my.telegram.org) دریافت کنید

## 🚀 نصب و راه‌اندازی

### 1. کلون کردن پروژه
```bash
git clone https://github.com/yourusername/telegram-music-bot.git
cd telegram-music-bot
```

### 2. پیکربندی
فایل `config.lua` را ویرایش کنید:

```lua
-- Bot Configuration
config.bot_token = "YOUR_BOT_TOKEN_HERE"
config.api_id = "YOUR_API_ID_HERE"
config.api_hash = "YOUR_API_HASH_HERE"
config.phone_number = "YOUR_PHONE_NUMBER"

-- Bot Settings
config.owner_id = YOUR_USER_ID
config.sudo_users = {123456789, 987654321}  -- اختیاری

-- Web Panel
config.web_port = 8080
config.web_secret = "your_secure_secret_key"
```

### 3. اجرای ربات
```bash
# اجرای کامل (ربات + پنل وب)
lua main.lua

# فقط ربات
lua main.lua --bot-only

# فقط پنل وب
lua main.lua --web-only

# نمایش راهنما
lua main.lua --help
```

## 🎮 نحوه استفاده

### دستورات ربات

#### دستورات کاربری
- `/start` - شروع ربات و نمایش راهنما
- `/play [لینک/نام آهنگ]` - پخش موزیک
- `/queue` - نمایش صف پخش
- `/skip` - رد کردن آهنگ فعلی
- `/stop` - متوقف کردن پخش
- `/pause` - توقف موقت
- `/resume` - ادامه پخش
- `/volume [0-100]` - تنظیم صدا
- `/np` - آهنگ در حال پخش

#### دستورات مدیریت
- `/clear` - پاک کردن صف
- `/shuffle` - بهم زدن صف
- `/loop` - حالت تکرار
- `/panel` - لینک پنل وب

### پنل وب

پنل وب در آدرس زیر در دسترس است:
```
http://localhost:8080?token=your_secret&chat=CHAT_ID
```

#### ویژگی‌های پنل:
- 🎵 کنترل پخش (پلی/پاز/اسکیپ)
- 📋 مدیریت صف پخش
- 🔊 کنترل صدا
- 📊 نمایش آمار
- 🔍 جستجوی آهنگ
- 📱 طراحی موبایل فرندلی

### میانبرهای کیبورد
- `Space` - پلی/پاز
- `→` - آهنگ بعدی
- `←` - آهنگ قبلی
- `↑` - افزایش صدا
- `↓` - کاهش صدا

## 🏗️ ساختار پروژه

```
telegram-music-bot/
├── main.lua              # فایل اصلی
├── config.lua            # تنظیمات
├── bot.lua               # منطق ربات
├── web_server.lua        # سرور وب
├── web/                  # فایل‌های پنل وب
│   ├── index.html        # صفحه اصلی
│   ├── style.css         # استایل‌ها
│   └── script.js         # جاوااسکریپت
├── downloads/            # فایل‌های دانلود شده
├── logs/                 # لاگ‌ها
├── README.md             # این فایل
└── requirements.txt      # وابستگی‌ها
```

## ⚙️ پیکربندی پیشرفته

### تنظیمات موزیک
```lua
config.max_queue_size = 50        -- حداکثر تعداد آهنگ در صف
config.max_duration = 3600        -- حداکثر طول آهنگ (ثانیه)
config.default_volume = 50        -- صدای پیش‌فرض
config.download_path = "./downloads/"  -- مسیر دانلود
```

### تنظیمات یوتیوب
```lua
config.youtube = {
    quality = "best[height<=720]",  -- کیفیت دانلود
    extract_flat = false            -- استخراج سریع
}
```

### تنظیمات وب
```lua
config.web_host = "0.0.0.0"       -- آدرس سرور
config.web_port = 8080             -- پورت سرور
config.web_secret = "secret_key"   -- کلید امنیتی
```

## 🔒 امنیت

### نکات امنیتی مهم:
1. **Token ها را محرمانه نگه دارید**
2. **web_secret را تغییر دهید**
3. **فایروال را پیکربندی کنید**
4. **فقط به کاربران مورد اعتماد دسترسی دهید**

### محدود کردن دسترسی:
```lua
config.sudo_users = {123456789}  -- فقط این کاربران
config.allowed_chats = {-100123456789}  -- فقط این گروه‌ها
```

## 🐛 عیب‌یابی

### مشکلات رایج:

#### ربات اجرا نمی‌شود
```bash
# بررسی وابستگی‌ها
lua -e "require('socket'); print('socket: OK')"
lua -e "require('cjson'); print('cjson: OK')"

# بررسی ffmpeg
ffmpeg -version
yt-dlp --version
```

#### پنل وب کار نمی‌کند
```bash
# بررسی پورت
netstat -tulpn | grep 8080

# بررسی لاگ‌ها
tail -f logs/bot.log
```

#### موزیک پخش نمی‌شود
```bash
# بررسی مجوزهای فایل
ls -la downloads/

# تست دانلود دستی
yt-dlp "https://youtube.com/watch?v=VIDEO_ID"
```

### فعال کردن لاگ دیباگ:
```lua
config.debug_mode = true
config.log_level = "DEBUG"
```

## 📚 API Reference

### Bot API
```lua
-- افزودن آهنگ به صف
bot.music.add_to_queue(chat_id, track)

-- پخش آهنگ بعدی
bot.music.play_next(chat_id)

-- توقف پخش
bot.music.stop(chat_id)

-- دریافت صف
local queue = bot.queues[chat_id]
```

### Web API
```
GET  /api/status?token=SECRET              # وضعیت ربات
GET  /api/current?token=SECRET&chat=ID     # آهنگ فعلی
GET  /api/queue?token=SECRET&chat=ID       # صف پخش
POST /api/command?token=SECRET&chat=ID     # ارسال دستور
```

## 🤝 مشارکت

### نحوه مشارکت:
1. پروژه را Fork کنید
2. شاخه جدید بسازید (`git checkout -b feature/amazing-feature`)
3. تغییرات را Commit کنید (`git commit -m 'Add amazing feature'`)
4. به شاخه Push کنید (`git push origin feature/amazing-feature`)
5. Pull Request ایجاد کنید

### قوانین کد:
- از comment های فارسی استفاده کنید
- کد را تمیز و خوانا نگه دارید
- تست‌های لازم را اضافه کنید

## 📄 مجوز

این پروژه تحت مجوز MIT منتشر شده است. برای جزئیات بیشتر فایل [LICENSE](LICENSE) را مطالعه کنید.

## 📞 پشتیبانی

- 🐛 **گزارش باگ**: [Issues](https://github.com/yourusername/telegram-music-bot/issues)
- 💬 **سوالات**: [Discussions](https://github.com/yourusername/telegram-music-bot/discussions)
- 📧 **ایمیل**: support@yourdomain.com
- 💬 **تلگرام**: [@YourUsername](https://t.me/YourUsername)

## 🙏 تشکر

- [Telegram Bot API](https://core.telegram.org/bots/api)
- [yt-dlp](https://github.com/yt-dlp/yt-dlp)
- [FFmpeg](https://ffmpeg.org/)
- [LuaSocket](http://w3.impa.br/~diego/software/luasocket/)

---

<div align="center">
ساخته شده با ❤️ برای جامعه ایرانی

[⭐ Star](https://github.com/yourusername/telegram-music-bot) | [🍴 Fork](https://github.com/yourusername/telegram-music-bot/fork) | [🐛 Report Bug](https://github.com/yourusername/telegram-music-bot/issues)

</div>