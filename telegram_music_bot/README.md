# ربات تلگرام پخش موزیک در ویس‌چت (Lua)

این پروژه یک نمونه‌ی ساده از ربات تلگرامی است که با زبان **لوا** نوشته شده است و با استفاده از یک اکانت کاربری و یک ربات، امکان پخش موسیقی در Voice Chat گروه یا کانال را فراهم می‌کند. رابط کاربری ربات به شکل «پنل شیشه‌ای» (Inline Keyboard) طراحی شده و دستورات زیر را ارائه می‌دهد:

* `▶️ پخش`
* `⏸️ توقف موقت`
* `⏹️ توقف کامل`

> توجه: استریم واقعی صدا در Voice Chat به دلیل پیچیدگی‌های فنی (اتصال به \`libtgvoip\` در TDLib) در این مخزن **به صورت اسکلت (Stub)** پیاده‌سازی شده است تا شما بتوانید آن را مطابق نیاز توسعه دهید.

---

## وابستگی‌ها

| نام | روش نصب |
|------|-------------------------------|
| Lua ≥ 5.3 | بسته `lua` یا `luajit` |
| luarocks | مدیر بسته‌های Lua |
| lua-sec  | `luarocks install lua-sec` |
| luasocket | `luarocks install luasocket` |
| cqueues   | `luarocks install cqueues` |
| cjson     | `luarocks install lua-cjson` |
| luafilesystem | `luarocks install luafilesystem` |
| **tdlua** | باید از سورس کامپایل شود؛ به [tdlua](https://github.com/giuseppeM99/tdlua) مراجعه کنید |
| ffmpeg    | ابزاری برای تبدیل صدا (`apt install ffmpeg`) |
| yt-dlp    | دانلود از یوتیوب (`pip install -U yt-dlp`) |

---

## راه‌اندازی

1. مخزن را کلون کنید و وارد آن شوید:
   ```bash
   git clone https://github.com/you/telegram-music-bot-lua.git
   cd telegram-music-bot-lua/telegram_music_bot
   ```
2. فایل `config.lua` را باز کرده و مقادیر زیر را تنظیم کنید:
   * `bot_token`
   * `api_id` و `api_hash` (از my.telegram.org)
   * `phone_number` (شماره اکانت کمکی)
3. کتابخانه‌ی tdlua را طبق راهنمای مخزن اصلی کامپایل و نصب کنید.
4. وابستگی‌های Lua را با `luarocks` نصب کنید (بخش «وابستگی‌ها»).
5. اسکریپت را اجرا نمایید:
   ```bash
   lua bot.lua
   ```
   در اجرای نخست، TDLib کد پیامک تأییدیه را دریافت کرده و از شما درخواست می‌کند.

---

## توسعه‌ی ماژول استریم (voice_player.lua)

در حال حاضر متد `stream_to_voice` تنها یک لاگ چاپ می‌کند. برای اجرای واقعی می‌توانید یکی از مسیرهای زیر را دنبال کنید:

1. **libtgvoip** را به tdlua متصل کنید و بایت‌استریم اُپس تولیدشده توسط FFmpeg را به صدا‌ی ویس‌چت تزریق کنید.
2. از یک ابزار جانبی (مثل [Grishka/Call] یا پروژه‌های مشابه در Node/Python) استفاده کرده و آن را از طریق `os.execute()` فراخوانی کنید.

---

## مجوز

MIT © 2025 