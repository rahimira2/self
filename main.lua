#!/usr/bin/env lua

-- Telegram Music Bot - Main Entry Point
print([[
🎵 ===============================================
   ربات موزیک تلگرام با پنل وب شیشه‌ای
   Telegram Music Bot with Glass Web Panel
=============================================== 🎵
]])

-- Load dependencies
local config = require('config')
local bot = require('bot')
local web_server = require('web_server')
local socket = require('socket')

-- Global state
local app = {
    bot_thread = nil,
    web_thread = nil,
    running = false
}

-- Utility functions
local function log(level, message)
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    print(string.format("[%s] [%s] %s", timestamp, level, message))
end

local function create_directories()
    log("INFO", "Creating necessary directories...")
    os.execute("mkdir -p " .. config.download_path)
    os.execute("mkdir -p " .. config.log_path)
    os.execute("mkdir -p ./web")
    log("INFO", "Directories created successfully")
end

local function check_dependencies()
    log("INFO", "Checking dependencies...")
    
    local dependencies = {
        "yt-dlp",
        "ffmpeg",
        "ffplay"
    }
    
    for _, dep in ipairs(dependencies) do
        local result = os.execute("which " .. dep .. " > /dev/null 2>&1")
        if result ~= 0 then
            log("WARNING", dep .. " not found. Some features may not work.")
        else
            log("INFO", dep .. " found ✓")
        end
    end
end

local function validate_config()
    log("INFO", "Validating configuration...")
    
    if not config.bot_token or config.bot_token == "YOUR_BOT_TOKEN" then
        log("ERROR", "Please set your bot token in config.lua")
        return false
    end
    
    if not config.api_id or config.api_id == "YOUR_API_ID" then
        log("ERROR", "Please set your API ID in config.lua")
        return false
    end
    
    if not config.api_hash or config.api_hash == "YOUR_API_HASH" then
        log("ERROR", "Please set your API hash in config.lua")
        return false
    end
    
    log("INFO", "Configuration validated ✓")
    return true
end

-- Bot thread function
local function bot_worker()
    log("INFO", "Starting bot thread...")
    bot.start_time = os.time()
    
    -- Start the bot
    bot.run()
end

-- Web server thread function
local function web_worker()
    log("INFO", "Starting web server thread...")
    
    -- Start web server
    web_server.start()
end

-- Signal handler for graceful shutdown
local function shutdown()
    log("INFO", "Shutting down...")
    app.running = false
    bot.is_running = false
    
    log("INFO", "Cleanup completed. Goodbye! 👋")
    os.exit(0)
end

-- Main application
local function main()
    log("INFO", "Starting Telegram Music Bot...")
    
    -- Validate configuration
    if not validate_config() then
        log("ERROR", "Configuration validation failed!")
        return 1
    end
    
    -- Create necessary directories
    create_directories()
    
    -- Check dependencies
    check_dependencies()
    
    -- Set application as running
    app.running = true
    
    -- Start bot in a coroutine
    app.bot_thread = coroutine.create(bot_worker)
    
    -- Start web server in a coroutine
    app.web_thread = coroutine.create(web_worker)
    
    log("INFO", "🚀 Bot and web panel started successfully!")
    log("INFO", "📱 Web Panel: http://localhost:" .. config.web_port)
    log("INFO", "🔑 Secret Token: " .. config.web_secret)
    log("INFO", "📋 Press Ctrl+C to stop")
    
    -- Main loop
    while app.running do
        -- Resume bot thread
        if app.bot_thread and coroutine.status(app.bot_thread) ~= "dead" then
            local ok, err = coroutine.resume(app.bot_thread)
            if not ok then
                log("ERROR", "Bot thread error: " .. tostring(err))
                app.bot_thread = coroutine.create(bot_worker)
            end
        end
        
        -- Resume web server thread
        if app.web_thread and coroutine.status(app.web_thread) ~= "dead" then
            local ok, err = coroutine.resume(app.web_thread)
            if not ok then
                log("ERROR", "Web server thread error: " .. tostring(err))
                app.web_thread = coroutine.create(web_worker)
            end
        end
        
        -- Small sleep to prevent busy waiting
        socket.sleep(0.1)
    end
    
    shutdown()
    return 0
end

-- Handle command line arguments
local function handle_args()
    if not arg then return end
    
    for i, argument in ipairs(arg) do
        if argument == "--help" or argument == "-h" then
            print([[
🎵 Telegram Music Bot Usage:

Options:
  --help, -h     Show this help message
  --config, -c   Specify config file (default: config.lua)
  --bot-only     Run only the bot (no web panel)
  --web-only     Run only the web panel (no bot)
  --version, -v  Show version information

Examples:
  lua main.lua                    # Run bot and web panel
  lua main.lua --bot-only         # Run only bot
  lua main.lua --web-only         # Run only web panel

Configuration:
  Edit config.lua to set your bot token, API credentials, and other settings.

Web Panel:
  Access at: http://localhost:8080?token=your_secret&chat=CHAT_ID
  
For more information, visit: https://github.com/yourusername/telegram-music-bot
            ]])
            os.exit(0)
        elseif argument == "--version" or argument == "-v" then
            print("Telegram Music Bot v1.0.0")
            print("Built with ❤️ using Lua")
            os.exit(0)
        elseif argument == "--bot-only" then
            log("INFO", "Running in bot-only mode")
            return bot_worker()
        elseif argument == "--web-only" then
            log("INFO", "Running in web-only mode")
            return web_worker()
        end
    end
end

-- Set signal handlers (Linux/Unix only)
if os.getenv("OS") ~= "Windows_NT" then
    -- This is a simplified signal handler
    -- In a real implementation, you'd use a proper signal handling library
    signal = require("posix.signal")
    if signal then
        signal.signal(signal.SIGINT, shutdown)
        signal.signal(signal.SIGTERM, shutdown)
    end
end

-- Run the application
if arg and arg[0] == "main.lua" then
    -- Handle command line arguments
    handle_args()
    
    -- Run main application
    local exit_code = main()
    os.exit(exit_code or 0)
end

return {
    main = main,
    bot = bot,
    web_server = web_server,
    config = config
}