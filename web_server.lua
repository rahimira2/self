#!/usr/bin/env lua

-- Web Server for Music Bot Panel
local socket = require('socket')
local ltn12 = require('ltn12')
local mime = require('mime')
local json = require('cjson')
local config = require('config')
local bot = require('bot')

local web_server = {}

-- MIME types
local mime_types = {
    ['.html'] = 'text/html; charset=utf-8',
    ['.css'] = 'text/css; charset=utf-8',
    ['.js'] = 'application/javascript; charset=utf-8',
    ['.json'] = 'application/json; charset=utf-8',
    ['.png'] = 'image/png',
    ['.jpg'] = 'image/jpeg',
    ['.jpeg'] = 'image/jpeg',
    ['.gif'] = 'image/gif',
    ['.svg'] = 'image/svg+xml',
    ['.ico'] = 'image/x-icon'
}

-- Get file extension
function web_server.get_extension(path)
    return path:match("%.([^.]*)$") and "." .. path:match("%.([^.]*)$") or ""
end

-- Get MIME type
function web_server.get_mime_type(path)
    local ext = web_server.get_extension(path)
    return mime_types[ext] or 'text/plain'
end

-- Read file content
function web_server.read_file(path)
    local file = io.open(path, 'rb')
    if not file then
        return nil
    end
    
    local content = file:read('*a')
    file:close()
    return content
end

-- URL decode
function web_server.url_decode(str)
    if not str then return nil end
    str = str:gsub('+', ' ')
    str = str:gsub('%%(%x%x)', function(h)
        return string.char(tonumber(h, 16))
    end)
    return str
end

-- Parse query string
function web_server.parse_query(query)
    local params = {}
    if not query then return params end
    
    for pair in query:gmatch('[^&]+') do
        local key, value = pair:match('([^=]+)=?(.*)')
        if key then
            params[web_server.url_decode(key)] = web_server.url_decode(value)
        end
    end
    return params
end

-- Parse HTTP request
function web_server.parse_request(request)
    local lines = {}
    for line in request:gmatch('[^\r\n]+') do
        table.insert(lines, line)
    end
    
    if #lines == 0 then return nil end
    
    local method, path, version = lines[1]:match('(%S+)%s+(%S+)%s+(%S+)')
    local url, query = path:match('([^?]*)%??(.*)')
    
    local headers = {}
    for i = 2, #lines do
        if lines[i] == '' then break end
        local key, value = lines[i]:match('([^:]+):%s*(.*)')
        if key then
            headers[key:lower()] = value
        end
    end
    
    return {
        method = method,
        url = url or path,
        query = web_server.parse_query(query),
        headers = headers,
        version = version
    }
end

-- Generate HTTP response
function web_server.http_response(status, headers, body)
    local response = string.format("HTTP/1.1 %d %s\r\n", status, 
        status == 200 and "OK" or 
        status == 404 and "Not Found" or
        status == 403 and "Forbidden" or
        status == 500 and "Internal Server Error" or "Unknown")
    
    headers = headers or {}
    headers['Server'] = 'Lua Music Bot Server/1.0'
    headers['Connection'] = 'close'
    
    if body then
        headers['Content-Length'] = tostring(#body)
    end
    
    for key, value in pairs(headers) do
        response = response .. string.format("%s: %s\r\n", key, value)
    end
    
    response = response .. "\r\n"
    if body then
        response = response .. body
    end
    
    return response
end

-- Handle static files
function web_server.serve_static(url)
    local file_path = "./web" .. url
    
    -- Default to index.html
    if url == "/" then
        file_path = "./web/index.html"
    end
    
    local content = web_server.read_file(file_path)
    if not content then
        return web_server.http_response(404, {['Content-Type'] = 'text/plain'}, 'File not found')
    end
    
    local mime_type = web_server.get_mime_type(file_path)
    return web_server.http_response(200, {['Content-Type'] = mime_type}, content)
end

-- API handlers
local api_handlers = {}

-- Get bot status
function api_handlers.status(query)
    local status = {
        online = bot.is_running,
        connected_chats = 0,
        total_tracks_played = 0,
        uptime = os.time() - (bot.start_time or os.time())
    }
    
    for chat_id, _ in pairs(bot.voice_clients or {}) do
        status.connected_chats = status.connected_chats + 1
    end
    
    return json.encode(status)
end

-- Get current playing
function api_handlers.current(query)
    local chat_id = query.chat
    if not chat_id then
        return json.encode({error = "Chat ID required"})
    end
    
    local current = bot.current_playing[chat_id]
    if not current then
        return json.encode({playing = false})
    end
    
    return json.encode({
        playing = true,
        track = current,
        progress = 0  -- This would be calculated based on actual playback time
    })
end

-- Get queue
function api_handlers.queue(query)
    local chat_id = query.chat
    if not chat_id then
        return json.encode({error = "Chat ID required"})
    end
    
    local queue = bot.queues[chat_id] or {}
    return json.encode({
        queue = queue,
        total = #queue
    })
end

-- Send command to bot
function api_handlers.command(query)
    local chat_id = query.chat
    local command = query.cmd
    local data = query.data
    
    if not chat_id or not command then
        return json.encode({error = "Chat ID and command required"})
    end
    
    -- Execute command
    local success = false
    local message = "Unknown command"
    
    if command == "play" and data then
        -- Add to queue logic would go here
        success = true
        message = "Track added to queue"
    elseif command == "skip" then
        success = bot.music and bot.music.skip(chat_id) or false
        message = success and "Track skipped" or "No track to skip"
    elseif command == "pause" then
        if bot.music then bot.music.stop(chat_id) end
        success = true
        message = "Playback paused"
    elseif command == "clear" then
        bot.queues[chat_id] = {}
        success = true
        message = "Queue cleared"
    elseif command == "volume" and data then
        -- Volume control would go here
        success = true
        message = "Volume set to " .. data .. "%"
    end
    
    return json.encode({
        success = success,
        message = message
    })
end

-- Handle API requests
function web_server.handle_api(url, query)
    local endpoint = url:match("/api/(.+)")
    if not endpoint then
        return web_server.http_response(404, {['Content-Type'] = 'application/json'}, 
            json.encode({error = "Endpoint not found"}))
    end
    
    -- Check authentication
    if not query.token or query.token ~= config.web_secret then
        return web_server.http_response(403, {['Content-Type'] = 'application/json'}, 
            json.encode({error = "Invalid token"}))
    end
    
    local handler = api_handlers[endpoint]
    if not handler then
        return web_server.http_response(404, {['Content-Type'] = 'application/json'}, 
            json.encode({error = "Unknown endpoint"}))
    end
    
    local response_data = handler(query)
    return web_server.http_response(200, {
        ['Content-Type'] = 'application/json',
        ['Access-Control-Allow-Origin'] = '*'
    }, response_data)
end

-- Handle client connection
function web_server.handle_client(client)
    local request_data = ""
    local timeout = socket.gettime() + 10  -- 10 second timeout
    
    while socket.gettime() < timeout do
        local chunk, err = client:receive(1024)
        if not chunk then
            if err == "timeout" then
                socket.sleep(0.01)
            else
                break
            end
        else
            request_data = request_data .. chunk
            if request_data:find("\r\n\r\n") then
                break
            end
        end
    end
    
    if request_data == "" then
        client:close()
        return
    end
    
    local request = web_server.parse_request(request_data)
    if not request then
        client:send(web_server.http_response(400, {['Content-Type'] = 'text/plain'}, 'Bad Request'))
        client:close()
        return
    end
    
    print(string.format("[WEB] %s %s", request.method, request.url))
    
    local response
    if request.url:match("^/api/") then
        response = web_server.handle_api(request.url, request.query)
    else
        response = web_server.serve_static(request.url)
    end
    
    client:send(response)
    client:close()
end

-- Start web server
function web_server.start()
    local server = socket.bind(config.web_host, config.web_port)
    if not server then
        print("❌ Failed to start web server on " .. config.web_host .. ":" .. config.web_port)
        return false
    end
    
    print("🌐 Web server started on http://" .. config.web_host .. ":" .. config.web_port)
    print("📱 Panel URL: http://localhost:" .. config.web_port .. "?token=" .. config.web_secret .. "&chat=YOUR_CHAT_ID")
    
    server:settimeout(0.1)
    
    while true do
        local client = server:accept()
        if client then
            client:settimeout(5)
            
            -- Handle client in coroutine for better performance
            local co = coroutine.create(function()
                web_server.handle_client(client)
            end)
            
            local ok, err = coroutine.resume(co)
            if not ok then
                print("❌ Error handling client: " .. tostring(err))
                client:close()
            end
        end
        
        socket.sleep(0.01)
    end
end

-- Run web server if called directly
if arg and arg[0] == "web_server.lua" then
    web_server.start()
end

return web_server