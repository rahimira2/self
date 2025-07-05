#!/usr/bin/env lua

-- Telegram Music Bot Main File
-- Dependencies
local json = require('cjson')
local http = require('socket.http')
local ltn12 = require('ltn12')
local socket = require('socket')
local os = require('os')
local io = require('io')

-- Load configuration
local config = require('config')

-- Bot state
local bot = {
    is_running = false,
    queues = {},  -- Music queues for each chat
    current_playing = {},  -- Current playing track for each chat
    voice_clients = {},  -- Voice chat connections
    update_offset = 0
}

-- Utility functions
local utils = {}

function utils.log(level, message)
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    local log_message = string.format("[%s] [%s] %s", timestamp, level, message)
    print(log_message)
    
    -- Write to log file
    local log_file = io.open(config.log_path .. "bot.log", "a")
    if log_file then
        log_file:write(log_message .. "\n")
        log_file:close()
    end
end

function utils.escape_markdown(text)
    return text:gsub("[_*%[%]()~`>#+=|{}.!-]", "\\%1")
end

function utils.format_duration(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60
    
    if hours > 0 then
        return string.format("%d:%02d:%02d", hours, minutes, secs)
    else
        return string.format("%d:%02d", minutes, secs)
    end
end

-- Telegram API functions
local telegram = {}

function telegram.send_request(method, params)
    local url = string.format("https://api.telegram.org/bot%s/%s", config.bot_token, method)
    local body = json.encode(params or {})
    
    local response_body = {}
    local result, status = http.request{
        url = url,
        method = "POST",
        headers = {
            ["Content-Type"] = "application/json",
            ["Content-Length"] = tostring(#body)
        },
        source = ltn12.source.string(body),
        sink = ltn12.sink.table(response_body)
    }
    
    if status == 200 then
        local response = json.decode(table.concat(response_body))
        return response.ok and response.result or nil
    end
    
    return nil
end

function telegram.send_message(chat_id, text, parse_mode, reply_markup)
    return telegram.send_request("sendMessage", {
        chat_id = chat_id,
        text = text,
        parse_mode = parse_mode or "Markdown",
        reply_markup = reply_markup
    })
end

function telegram.edit_message(chat_id, message_id, text, parse_mode, reply_markup)
    return telegram.send_request("editMessageText", {
        chat_id = chat_id,
        message_id = message_id,
        text = text,
        parse_mode = parse_mode or "Markdown",
        reply_markup = reply_markup
    })
end

function telegram.answer_callback_query(callback_query_id, text, show_alert)
    return telegram.send_request("answerCallbackQuery", {
        callback_query_id = callback_query_id,
        text = text,
        show_alert = show_alert or false
    })
end

function telegram.join_voice_chat(chat_id)
    -- This would use MTProto for voice chat functionality
    utils.log("INFO", "Joining voice chat in " .. chat_id)
    return true
end

function telegram.leave_voice_chat(chat_id)
    utils.log("INFO", "Leaving voice chat in " .. chat_id)
    return true
end

-- Music functions
local music = {}

function music.download_audio(url, chat_id)
    local filename = string.format("%s/%s_%s.mp3", config.download_path, chat_id, os.time())
    local command = string.format("yt-dlp -x --audio-format mp3 --audio-quality 0 -o '%s' '%s'", filename, url)
    
    utils.log("INFO", "Downloading: " .. url)
    local result = os.execute(command)
    
    if result == 0 then
        return filename
    else
        return nil
    end
end

function music.get_audio_info(url)
    local command = string.format("yt-dlp --print '%%(title)s|%%(duration)s|%%(uploader)s' '%s'", url)
    local handle = io.popen(command)
    local result = handle:read("*a")
    handle:close()
    
    if result then
        local title, duration, uploader = result:match("([^|]*)|([^|]*)|([^|]*)")
        return {
            title = title,
            duration = tonumber(duration) or 0,
            uploader = uploader
        }
    end
    
    return nil
end

function music.add_to_queue(chat_id, track)
    if not bot.queues[chat_id] then
        bot.queues[chat_id] = {}
    end
    
    if #bot.queues[chat_id] >= config.max_queue_size then
        return false, "صف پخش پر است!"
    end
    
    table.insert(bot.queues[chat_id], track)
    return true, "آهنگ به صف اضافه شد"
end

function music.play_next(chat_id)
    if not bot.queues[chat_id] or #bot.queues[chat_id] == 0 then
        bot.current_playing[chat_id] = nil
        return false
    end
    
    local track = table.remove(bot.queues[chat_id], 1)
    bot.current_playing[chat_id] = track
    
    -- Start playing the track
    local command = string.format("ffplay -nodisp -autoexit '%s'", track.file_path)
    os.execute(command .. " &")
    
    utils.log("INFO", "Playing: " .. track.title .. " in chat " .. chat_id)
    return true
end

function music.stop(chat_id)
    bot.current_playing[chat_id] = nil
    os.execute("pkill -f ffplay")
    utils.log("INFO", "Music stopped in chat " .. chat_id)
end

function music.skip(chat_id)
    music.stop(chat_id)
    return music.play_next(chat_id)
end

function music.get_queue_text(chat_id)
    if not bot.queues[chat_id] or #bot.queues[chat_id] == 0 then
        return "صف پخش خالی است"
    end
    
    local text = "🎵 *صف پخش موزیک:*\n\n"
    
    -- Current playing
    if bot.current_playing[chat_id] then
        text = text .. "🎧 *در حال پخش:*\n"
        text = text .. string.format("▶️ %s\n", utils.escape_markdown(bot.current_playing[chat_id].title))
        text = text .. string.format("👤 %s\n", utils.escape_markdown(bot.current_playing[chat_id].uploader or "نامعلوم"))
        text = text .. string.format("⏰ %s\n\n", utils.format_duration(bot.current_playing[chat_id].duration))
    end
    
    -- Queue
    text = text .. "📋 *آهنگ‌های بعدی:*\n"
    for i, track in ipairs(bot.queues[chat_id]) do
        text = text .. string.format("%d. %s\n", i, utils.escape_markdown(track.title))
        text = text .. string.format("   ⏰ %s\n", utils.format_duration(track.duration))
    end
    
    return text
end

-- Command handlers
local commands = {}

function commands.start(message)
    local text = [[
🎵 *سلام! من ربات پخش موزیک هستم*

با استفاده از دستورات زیر می‌توانید موزیک پخش کنید:

🎧 *دستورات کاربری:*
/play [لینک یا نام آهنگ] - پخش موزیک
/pause - توقف موزیک
/resume - ادامه پخش
/skip - رد کردن آهنگ
/stop - متوقف کردن کامل
/queue - نمایش صف پخش
/np - آهنگ در حال پخش

🔧 *دستورات مدیریت:*
/volume [0-100] - تنظیم صدا
/shuffle - به هم زدن صف
/clear - پاک کردن صف
/loop - حالت تکرار

📱 *پنل وب:* /panel

برای شروع، من را به گروه اضافه کرده و ادمین کنید!
]]
    
    telegram.send_message(message.chat.id, text)
end

function commands.play(message, args)
    if not args or args == "" then
        telegram.send_message(message.chat.id, "❌ لطفاً لینک یا نام آهنگ را وارد کنید")
        return
    end
    
    -- Send "searching" message
    local search_msg = telegram.send_message(message.chat.id, "🔍 در حال جستجو...")
    
    -- Get audio info
    local info = music.get_audio_info(args)
    if not info then
        telegram.edit_message(message.chat.id, search_msg.message_id, "❌ آهنگ پیدا نشد!")
        return
    end
    
    if info.duration > config.max_duration then
        telegram.edit_message(message.chat.id, search_msg.message_id, "❌ آهنگ بیش از حد طولانی است!")
        return
    end
    
    -- Download audio
    telegram.edit_message(message.chat.id, search_msg.message_id, "⬇️ در حال دانلود...")
    local file_path = music.download_audio(args, message.chat.id)
    
    if not file_path then
        telegram.edit_message(message.chat.id, search_msg.message_id, "❌ خطا در دانلود!")
        return
    end
    
    -- Add to queue
    local track = {
        title = info.title,
        duration = info.duration,
        uploader = info.uploader,
        file_path = file_path,
        requested_by = message.from.first_name
    }
    
    local success, msg = music.add_to_queue(message.chat.id, track)
    if not success then
        telegram.edit_message(message.chat.id, search_msg.message_id, "❌ " .. msg)
        return
    end
    
    -- Join voice chat if not connected
    if not bot.voice_clients[message.chat.id] then
        telegram.join_voice_chat(message.chat.id)
        bot.voice_clients[message.chat.id] = true
    end
    
    -- Start playing if nothing is playing
    if not bot.current_playing[message.chat.id] then
        music.play_next(message.chat.id)
        telegram.edit_message(message.chat.id, search_msg.message_id, "🎵 پخش شروع شد!")
    else
        telegram.edit_message(message.chat.id, search_msg.message_id, "✅ " .. msg)
    end
end

function commands.queue(message)
    local text = music.get_queue_text(message.chat.id)
    
    local keyboard = {
        inline_keyboard = {
            {
                {text = "⏭️ بعدی", callback_data = "skip"},
                {text = "⏸️ توقف", callback_data = "pause"},
                {text = "🔀 بهم زدن", callback_data = "shuffle"}
            },
            {
                {text = "🔇 بی‌صدا", callback_data = "mute"},
                {text = "🗑️ پاک کردن", callback_data = "clear"},
                {text = "🔄 بروزرسانی", callback_data = "refresh_queue"}
            }
        }
    }
    
    telegram.send_message(message.chat.id, text, "Markdown", keyboard)
end

function commands.skip(message)
    if music.skip(message.chat.id) then
        telegram.send_message(message.chat.id, "⏭️ آهنگ رد شد!")
    else
        telegram.send_message(message.chat.id, "❌ آهنگی برای رد کردن وجود ندارد")
    end
end

function commands.stop(message)
    music.stop(message.chat.id)
    bot.queues[message.chat.id] = {}
    telegram.leave_voice_chat(message.chat.id)
    bot.voice_clients[message.chat.id] = nil
    telegram.send_message(message.chat.id, "⏹️ پخش متوقف شد و صف پاک شد")
end

function commands.panel(message)
    local panel_url = string.format("http://localhost:%d?token=%s&chat=%s", 
        config.web_port, config.web_secret, message.chat.id)
    
    local text = string.format("🌐 *پنل کنترل وب*\n\n[🔗 باز کردن پنل](%s)", panel_url)
    telegram.send_message(message.chat.id, text)
end

-- Message handler
function handle_message(message)
    if not message.text then return end
    
    local text = message.text
    local command, args = text:match("^/([%w_]+)%s*(.*)")
    
    if command then
        if commands[command] then
            commands[command](message, args)
        end
    end
end

-- Callback query handler
function handle_callback_query(callback_query)
    local data = callback_query.data
    local chat_id = callback_query.message.chat.id
    
    if data == "skip" then
        if music.skip(chat_id) then
            telegram.answer_callback_query(callback_query.id, "آهنگ رد شد!")
        else
            telegram.answer_callback_query(callback_query.id, "آهنگی برای رد کردن وجود ندارد", true)
        end
    elseif data == "pause" then
        music.stop(chat_id)
        telegram.answer_callback_query(callback_query.id, "پخش متوقف شد")
    elseif data == "clear" then
        bot.queues[chat_id] = {}
        telegram.answer_callback_query(callback_query.id, "صف پاک شد")
    elseif data == "refresh_queue" then
        local text = music.get_queue_text(chat_id)
        telegram.edit_message(callback_query.message.chat.id, callback_query.message.message_id, text)
        telegram.answer_callback_query(callback_query.id, "بروزرسانی شد")
    end
end

-- Main update handler
function handle_update(update)
    if update.message then
        handle_message(update.message)
    elseif update.callback_query then
        handle_callback_query(update.callback_query)
    end
end

-- Main bot loop
function bot.run()
    utils.log("INFO", "ربات شروع شد...")
    bot.is_running = true
    
    -- Create directories
    os.execute("mkdir -p " .. config.download_path)
    os.execute("mkdir -p " .. config.log_path)
    
    while bot.is_running do
        local updates = telegram.send_request("getUpdates", {
            offset = bot.update_offset,
            timeout = 30
        })
        
        if updates then
            for _, update in ipairs(updates) do
                bot.update_offset = update.update_id + 1
                handle_update(update)
            end
        end
        
        socket.sleep(0.1)
    end
end

-- Start the bot
if arg and arg[0] == "bot.lua" then
    bot.run()
end

return bot