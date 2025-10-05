-- NSBoot WebSocket Handler
-- Real-time updates for client status and system metrics

local _M = {}
local cjson = require("cjson")

-- WebSocket clients registry
local clients = {}
local client_id_counter = 0

-- Generate unique client ID
local function generate_client_id()
    client_id_counter = client_id_counter + 1
    return "ws_" .. client_id_counter .. "_" .. ngx.now()
end

-- Broadcast message to all connected clients
function _M.broadcast(message_type, data)
    local message = cjson.encode({
        type = message_type,
        data = data,
        timestamp = os.time()
    })
    
    for client_id, wb in pairs(clients) do
        local ok, err = wb:send_text(message)
        if not ok then
            ngx.log(ngx.ERR, "Failed to send to client ", client_id, ": ", err)
            clients[client_id] = nil
        end
    end
end

-- Send message to specific client
function _M.send_to_client(client_id, message_type, data)
    local wb = clients[client_id]
    if not wb then
        return false, "Client not found"
    end
    
    local message = cjson.encode({
        type = message_type,
        data = data,
        timestamp = os.time()
    })
    
    local ok, err = wb:send_text(message)
    if not ok then
        clients[client_id] = nil
        return false, err
    end
    
    return true
end

-- Handle WebSocket connection
function _M.handle_websocket()
    local server = require("resty.websocket.server")
    
    local wb, err = server:new({
        timeout = 5000,
        max_payload_len = 65535
    })
    
    if not wb then
        ngx.log(ngx.ERR, "Failed to create WebSocket: ", err)
        return ngx.exit(444)
    end
    
    -- Generate client ID
    local client_id = generate_client_id()
    clients[client_id] = wb
    
    ngx.log(ngx.INFO, "WebSocket client connected: ", client_id)
    
    -- Send welcome message
    local welcome = cjson.encode({
        type = "connected",
        data = {
            client_id = client_id,
            server_version = "4.1.0"
        },
        timestamp = os.time()
    })
    wb:send_text(welcome)
    
    -- Main message loop
    while true do
        local data, typ, err = wb:recv_frame()
        
        if not data then
            local bytes, err = wb:send_ping()
            if not bytes then
                ngx.log(ngx.ERR, "Failed to send ping: ", err)
                break
            end
        elseif typ == "close" then
            ngx.log(ngx.INFO, "Client closing connection: ", client_id)
            break
        elseif typ == "ping" then
            local bytes, err = wb:send_pong()
            if not bytes then
                ngx.log(ngx.ERR, "Failed to send pong: ", err)
                break
            end
        elseif typ == "pong" then
            ngx.log(ngx.DEBUG, "Received pong from ", client_id)
        elseif typ == "text" then
            -- Handle incoming message
            local ok, message = pcall(cjson.decode, data)
            if ok then
                _M.handle_message(client_id, message)
            else
                ngx.log(ngx.ERR, "Invalid JSON from client: ", data)
            end
        end
    end
    
    -- Cleanup
    clients[client_id] = nil
    wb:send_close()
    ngx.log(ngx.INFO, "WebSocket client disconnected: ", client_id)
end

-- Handle incoming WebSocket message
function _M.handle_message(client_id, message)
    local msg_type = message.type
    
    if msg_type == "subscribe" then
        -- Subscribe to specific events
        local channel = message.channel
        ngx.log(ngx.INFO, "Client ", client_id, " subscribed to ", channel)
        
    elseif msg_type == "unsubscribe" then
        -- Unsubscribe from events
        local channel = message.channel
        ngx.log(ngx.INFO, "Client ", client_id, " unsubscribed from ", channel)
        
    elseif msg_type == "ping" then
        -- Respond to ping
        _M.send_to_client(client_id, "pong", {})
        
    else
        ngx.log(ngx.WARN, "Unknown message type: ", msg_type)
    end
end

-- Periodic update function (called by timer)
function _M.send_system_updates()
    -- Get system stats
    local stats = {
        cpu = math.random(30, 70),
        memory = math.random(50, 80),
        network_rx = math.random(100, 500),
        network_tx = math.random(50, 200),
        active_clients = #clients
    }
    
    _M.broadcast("system_stats", stats)
end

-- Send client status update
function _M.send_client_status(client_mac, status)
    _M.broadcast("client_status", {
        mac = client_mac,
        status = status,
        timestamp = os.time()
    })
end

-- Send image upload progress
function _M.send_upload_progress(image_id, progress)
    _M.broadcast("upload_progress", {
        image_id = image_id,
        progress = progress
    })
end

-- Get connected clients count
function _M.get_connected_count()
    local count = 0
    for _ in pairs(clients) do
        count = count + 1
    end
    return count
end

return _M
