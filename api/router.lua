-- NSBoot API Router
-- Routes HTTP requests to appropriate handlers

local api = require("api.init")

local _M = {}

-- Route table
local routes = {
    ["GET /api/system/info"] = function()
        local info = api.get_system_info()
        api.json_response(info)
    end,
    
    ["GET /api/images"] = function()
        local images = api.get_images()
        api.json_response(images)
    end,
    
    ["GET /api/clients"] = function()
        local clients = api.get_clients()
        api.json_response(clients)
    end,
    
    ["POST /api/clients/:mac/wake"] = function(params)
        local mac = params.mac
        local result = api.wake_client(mac)
        if result.success then
            api.json_response(result)
        else
            api.error_response(result.message, 500)
        end
    end,
    
    ["GET /api/snapshots"] = function()
        local snapshots = api.get_snapshots()
        api.json_response(snapshots)
    end,
    
    ["POST /api/images/:id/snapshot"] = function(params)
        ngx.req.read_body()
        local body = ngx.req.get_body_data()
        
        if not body then
            api.error_response("Missing request body", 400)
            return
        end
        
        local ok, data = pcall(require("cjson").decode, body)
        if not ok or not data.name then
            api.error_response("Invalid request body", 400)
            return
        end
        
        local result = api.create_snapshot(params.id, data.name)
        if result.success then
            api.json_response(result)
        else
            api.error_response(result.message, 500)
        end
    end,
    
    ["GET /api/metrics"] = function()
        ngx.header["Content-Type"] = "text/plain"
        ngx.say(api.get_metrics())
        ngx.exit(200)
    end,
    
    ["GET /api/health"] = function()
        api.json_response({
            status = "healthy",
            timestamp = os.time()
        })
    end
}

-- Match route pattern with parameters
function _M.match_route(method, path)
    -- Try exact match first
    local route_key = method .. " " .. path
    if routes[route_key] then
        return routes[route_key], {}
    end
    
    -- Try pattern matching
    for pattern, handler in pairs(routes) do
        local pattern_method, pattern_path = pattern:match("^(%S+)%s+(.+)$")
        if pattern_method == method then
            -- Convert :param to capture pattern
            local regex_pattern = "^" .. pattern_path:gsub(":(%w+)", "([^/]+)") .. "$"
            local matches = {path:match(regex_pattern)}
            
            if #matches > 0 then
                -- Extract parameter names
                local params = {}
                local param_names = {}
                for param_name in pattern_path:gmatch(":(%w+)") do
                    table.insert(param_names, param_name)
                end
                
                for i, value in ipairs(matches) do
                    params[param_names[i]] = value
                end
                
                return handler, params
            end
        end
    end
    
    return nil, {}
end

-- Main request handler
function _M.handle_request()
    local method = ngx.req.get_method()
    local path = ngx.var.uri
    
    -- CORS headers
    ngx.header["Access-Control-Allow-Origin"] = "*"
    ngx.header["Access-Control-Allow-Methods"] = "GET, POST, PUT, DELETE, OPTIONS"
    ngx.header["Access-Control-Allow-Headers"] = "Content-Type, Authorization"
    
    -- Handle OPTIONS preflight
    if method == "OPTIONS" then
        ngx.exit(200)
        return
    end
    
    -- Find and execute handler
    local handler, params = _M.match_route(method, path)
    
    if handler then
        local ok, err = pcall(handler, params)
        if not ok then
            ngx.log(ngx.ERR, "Handler error: ", err)
            api.error_response("Internal server error", 500)
        end
    else
        api.error_response("Route not found", 404)
    end
end

return _M
