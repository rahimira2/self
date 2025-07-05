--[[
  Telegram Music VoiceChat Bot (Lua)
  نویسنده: ChatGPT نمونه – ۱۴۰۴/۰۴
  -------------------------------------------------------------
  این اسکریپت دو بخش دارد:
    1. ربات Bot API برای دریافت دستورات و نمایش پنل دکمه‌های شیشه‌ای
    2. کاربر معمولی (TDLib) جهت جوین شدن به ویس‌چت و استریم صدا

  لایبرری‌های مورد نیاز (با luarocks نصب کنید):
    luarocks install luasocket
    luarocks install lua-sec
    luarocks install luajson
    luarocks install cqueues
    luarocks install tdlua       -- کامپایل از سورس؛ به README مراجعه کنید

  اجرای برنامه:
    $ lua bot.lua

  توجه: در اولین اجرا TDLib از شما کد لاگین (OTP) می‌خواهد که در ترمینال
  نشان داده می‌شود. بعد از یک بار لاگین، سشن ذخیره و دفعات بعد بدون
  مداخله کار می‌کند.
]]

local cfg = require("config")

-- Dependencies --------------------------------------------------------------
local https     = require("ssl.https")
local ltn12     = require("ltn12")
local json      = require("cjson.safe")
local tdlua_ok, tdlua = pcall(require, "tdlua")
if not tdlua_ok then
  io.stderr:write("[!] tdlua library not found. Please build & install tdlua.\n")
  os.exit(1)
end
local voice     = require("voice_player")

-- ===============  Bot API helper ==========================================
local BOT_API   = "https://api.telegram.org/bot" .. cfg.bot_token .. "/"
local offset    = 0

local function bot_call(method, data)
  local body = json.encode(data or {})
  local response = {}
  local res, code, headers = https.request{
    url     = BOT_API .. method,
    method  = "POST",
    headers = {
      ["Content-Type"]   = "application/json",
      ["Content-Length"] = #body
    },
    source  = ltn12.source.string(body),
    sink    = ltn12.sink.table(response)
  }
  if not res then
    return nil, "HTTP error: " .. tostring(code)
  end
  local decoded = json.decode(table.concat(response))
  if not decoded then
    return nil, "JSON decode failed"
  end
  if not decoded.ok then
    return nil, decoded.description or "API error"
  end
  return decoded.result
end

local function send_message(chat_id, text, opts)
  opts = opts or {}
  opts.chat_id = chat_id
  opts.text    = text
  opts.parse_mode = opts.parse_mode or "Markdown"
  return bot_call("sendMessage", opts)
end

local function send_panel(chat_id, text)
  local keyboard = {
    inline_keyboard = {
      {
        {text = "▶️ پخش",  callback_data = "play"},
        {text = "⏸️ توقف موقت",  callback_data = "pause"},
        {text = "⏹️ توقف", callback_data = "stop"}
      }
    }
  }
  return send_message(chat_id, text, {reply_markup = keyboard})
end

-- =============== TDLib client =============================================
local client = tdlua.create({
  api_id            = cfg.api_id,
  api_hash          = cfg.api_hash,
  use_message_db    = false,
  use_secret_chats  = false,
  system_language_code = "en",
  device_model      = "LuaMusicBot",
  application_version = "1.0",
  database_directory = cfg.session_name,
  files_directory    = cfg.session_name .. "/files"
})

-- Handle TDLib auth state ---------------------------------------------------
local function on_update(update)
  if update["@type"] == "updateAuthorizationState" then
    local st = update.authorization_state["@type"]
    if st == "authorizationStateClosed" then
      os.exit()
    elseif st == "authorizationStateWaitCode" then
      io.write("[*] لطفاً کد ارسال شده در تلگرام را وارد کنید: ")
      local code = io.read()
      client:send({"checkAuthenticationCode", code = code})
    elseif st == "authorizationStateWaitPassword" then
      io.write("[*] پسورد ۲مرحله‌ای را وارد کنید: ")
      local pwd = io.read()
      client:send({"checkAuthenticationPassword", password = pwd})
    elseif st == "authorizationStateWaitPhoneNumber" then
      client:send({"setAuthenticationPhoneNumber", phone_number = cfg.phone_number})
    end
  end
end

-- یک نخ برای TDLib ----------------------------------------------------------
local copas = require("cqueues").new()

copas:wrap(function()
  while true do
    local update = client:receive(0.1)
    if update then
      on_update(update)
    end
  end
end)

-- ===============  Bot polling loop  =======================================
local function handle_message(msg)
  local text  = msg.text and msg.text
  local chat  = msg.chat.id
  if not text then return end

  if text:match("^/start") then
    send_panel(chat, "🎵 به ربات موزیک ویس‌چت خوش آمدید!\nیک لینک بده یا از دکمه‌ها استفاده کن.")
  elseif text:match("^/play%s+(.+)") then
    local url = text:match("^/play%s+(.+)")
    send_message(chat, "🔄 در حال پردازش لینک ...")
    voice.enqueue(chat, url)
  end
end

local function handle_callback(cb)
  local data = cb.data
  local chat_id = cb.message.chat.id
  if data == "pause" then
    voice.pause(chat_id)
  elseif data == "stop" then
    voice.stop(chat_id)
  elseif data == "play" then
    voice.resume(chat_id)
  end
  -- پاسخ به CallbackQuery (حذف ساعت شنی)
  bot_call("answerCallbackQuery", {callback_query_id = cb.id})
end

copas:wrap(function()
  while true do
    local res, err = bot_call("getUpdates", {
      offset   = offset,
      timeout  = 25,
      allowed_updates = {"message", "callback_query"}
    })
    if not res then
      print("Bot API error: " .. tostring(err))
    else
      for _, upd in ipairs(res) do
        offset = upd.update_id + 1
        if upd.message then
          handle_message(upd.message)
        elseif upd.callback_query then
          handle_callback(upd.callback_query)
        end
      end
    end
  end
end)

-- ===============  Main loop  ==============================================
print("[+] Bot is running ...")
while true do
  -- اجرای حلقهٔ رویداد اصلی
  assert(copas:step())
  -- اجرای حلقهٔ ماژول پخش در پس‌زمینه
  voice.loop_step()
end