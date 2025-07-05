-- voice_player.lua
-- ماژول پخش صدا در ویس‌چت (نسخهٔ ساده/نمونه)
-- ---------------------------------------------------------------------------
-- این ماژول وظیفهٔ دریافت لینک، دانلود صدا (با yt-dlp) و تبدیل/استریم به
-- ویس‌چت را بر عهده دارد. در این نمونه فقط اسکلت کد آورده شده است تا بتوانید
-- بر اساس نیاز خود توسعه دهید.
-- ---------------------------------------------------------------------------
local cfg        = require("config")
local json       = require("cjson.safe")
local tdlua      = require("tdlua")
local lfs_ok, lfs = pcall(require, "lfs")

local M = {}
local q = {}

-- TDLib client که در bot.lua ساخته شد را از پکیج جهانی بگیریم
local client = tdlua.get_client and tdlua.get_client() or nil

local function warn(msg)
  io.stderr:write("[voice_player] " .. msg .. "\n")
end

-- Util: دانلود/استخراج استریم صوتی با yt-dlp و برگرداندن مسیر فایل
local function fetch_audio(url)
  if not lfs_ok then
    warn("LuaFileSystem را نصب کنید (luarocks install luafilesystem)")
    return nil
  end
  local tmpdir = "tmp_audio"
  lfs.mkdir(tmpdir)
  local outfile = tmpdir .. "/track.webm"
  local cmd = string.format('yt-dlp -q -f bestaudio -o "%s" "%s"', outfile, url)
  warn("دانلود: " .. cmd)
  os.execute(cmd)
  return outfile
end

-- Util: استریم فایل صوتی به ویس‌چت با ffmpeg + libtgvoip (TDLib)
local function stream_to_voice(chat_id, filepath)
  -- پیاده‌سازی کامل نیازمند تابع‌بندی libtgvoip در tdlua است.
  -- این تابع فقط یک لاگ نمونه چاپ می‌کند.
  warn(string.format("[DEV] Streaming %s to chat %s (not implemented)", filepath, chat_id))
end

-- صف پخش -------------------------------------------------------
function M.enqueue(chat_id, url)
  table.insert(q, {chat_id = chat_id, url = url})
end

function M.pause(chat_id)
  warn("Pause pressed (stub)")
end

function M.resume(chat_id)
  warn("Resume pressed (stub)")
end

function M.stop(chat_id)
  warn("Stop pressed (stub)")
end

-- حلقهٔ پردازش صف (کوروتین مجزا)
local cq = require("cqueues").new()

cq:wrap(function()
  while true do
    if #q > 0 then
      local item = table.remove(q, 1)
      local file = fetch_audio(item.url)
      if file then
        stream_to_voice(item.chat_id, file)
      end
    end
    -- خواب کوتاه برای جلوگیری از مصرف CPU
    require("cqueues").sleep(1)
  end
end)

function M.loop_step()
  return cq:step()
end

return M