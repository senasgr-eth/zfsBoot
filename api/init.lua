-- NSBoot API v4.1.0
-- Modern REST API layer using OpenResty/Lua

local cjson = require("cjson")
local posix = require("posix")

local _M = {}

-- Helper function to send JSON response
function _M.json_response(data, status)
    status = status or 200
    ngx.status = status
    ngx.header["Content-Type"] = "application/json"
    ngx.say(cjson.encode(data))
    ngx.exit(status)
end

-- Helper function to send error response
function _M.error_response(message, status)
    status = status or 500
    _M.json_response({
        error = true,
        message = message,
        timestamp = os.time()
    }, status)
end

-- Helper function to execute shell command and capture output
function _M.exec_command(cmd)
    local handle = io.popen(cmd)
    if not handle then
        return nil, "Failed to execute command"
    end
    local result = handle:read("*a")
    handle:close()
    return result
end

-- Get system information
function _M.get_system_info()
    local info = {
        version = "4.1.0",
        hostname = _M.exec_command("hostname"):gsub("%s+", ""),
        uptime = tonumber(_M.exec_command("cat /proc/uptime | awk '{print $1}'")),
        clients_active = 0,
        clients_total = 0,
        zfs_pool_usage = 0,
        zfs_pool_size = 0,
        zfs_pool_available = 0
    }
    
    -- Get ZFS pool information
    local zfs_output = _M.exec_command("zpool list -H -o size,alloc,free nsboot0 2>/dev/null")
    if zfs_output and #zfs_output > 0 then
        local size, alloc, free = zfs_output:match("(%S+)%s+(%S+)%s+(%S+)")
        info.zfs_pool_size = _M.parse_size(size)
        info.zfs_pool_usage = _M.parse_size(alloc)
        info.zfs_pool_available = _M.parse_size(free)
    end
    
    return info
end

-- Parse size string (e.g., "100G", "1.5T") to bytes
function _M.parse_size(size_str)
    if not size_str then return 0 end
    
    local num = tonumber(size_str:match("^([%d%.]+)"))
    local unit = size_str:match("([KMGT])$")
    
    if not num then return 0 end
    
    local multipliers = {
        K = 1024,
        M = 1024^2,
        G = 1024^3,
        T = 1024^4
    }
    
    return num * (multipliers[unit] or 1)
end

-- Get list of images
function _M.get_images()
    local images = {}
    local base_path = "/srv/images/storages"
    
    local cmd = string.format("find %s -maxdepth 1 -type f \\( -name '*.qcow2' -o -name '*.vhd' -o -name '*.vhdx' -o -name '*.vmdk' -o -name '*.iso' \\)", base_path)
    local output = _M.exec_command(cmd)
    
    if output then
        for line in output:gmatch("[^\r\n]+") do
            local stat = posix.stat(line)
            if stat then
                local name = line:match("([^/]+)$")
                local ext = name:match("%.([^%.]+)$")
                
                table.insert(images, {
                    id = name,
                    name = name,
                    type = ext or "unknown",
                    size = stat.size,
                    created = os.date("%Y-%m-%d %H:%M:%S", stat.ctime),
                    modified = os.date("%Y-%m-%d %H:%M:%S", stat.mtime),
                    path = line,
                    in_use = false,
                    snapshots = 0
                })
            end
        end
    end
    
    return images
end

-- Get list of clients
function _M.get_clients()
    local clients = {}
    
    -- Get active iSCSI targets
    local tgt_output = _M.exec_command("tgtadm --lld iscsi --op show --mode target 2>/dev/null")
    
    if tgt_output then
        for target_block in tgt_output:gmatch("Target %d+:.-\n") do
            local tid = target_block:match("Target (%d+):")
            local iqn = target_block:match("Target %d+: ([^\n]+)")
            
            if tid and iqn then
                -- Extract client info from IQN (format: iqn.2025-01.com.nsboot:hostname)
                local hostname = iqn:match(":(.+)$") or "unknown"
                
                table.insert(clients, {
                    id = tid,
                    hostname = hostname,
                    mac_address = "00:00:00:00:00:00",
                    ip_address = "0.0.0.0",
                    status = "online",
                    image = "unknown",
                    target_id = tonumber(tid),
                    last_seen = os.date("%Y-%m-%d %H:%M:%S")
                })
            end
        end
    end
    
    return clients
end

-- Wake on LAN
function _M.wake_client(mac_address)
    local cmd = string.format("etherwake %s 2>&1", mac_address)
    local result = _M.exec_command(cmd)
    
    if result and not result:match("error") then
        return { success = true, message = "WOL packet sent" }
    else
        return { success = false, message = "Failed to send WOL packet" }
    end
end

-- Create ZFS snapshot
function _M.create_snapshot(image_id, snapshot_name)
    local dataset = string.format("nsboot0/images/storages/%s", image_id)
    local snap_name = string.format("%s@%s", dataset, snapshot_name)
    
    local cmd = string.format("zfs snapshot %s 2>&1", snap_name)
    local result = _M.exec_command(cmd)
    
    if result and not result:match("error") then
        return { success = true, snapshot = snap_name }
    else
        return { success = false, message = result }
    end
end

-- Get ZFS snapshots
function _M.get_snapshots()
    local snapshots = {}
    
    local cmd = "zfs list -t snapshot -H -o name,used,creation nsboot0/images 2>/dev/null"
    local output = _M.exec_command(cmd)
    
    if output then
        for line in output:gmatch("[^\r\n]+") do
            local name, used, creation = line:match("(%S+)%s+(%S+)%s+(.+)")
            if name then
                local dataset, snap = name:match("(.+)@(.+)")
                table.insert(snapshots, {
                    name = snap,
                    dataset = dataset,
                    size = used,
                    created = creation
                })
            end
        end
    end
    
    return snapshots
end

-- Get metrics for Prometheus
function _M.get_metrics()
    local metrics = {}
    
    -- System info
    local info = _M.get_system_info()
    table.insert(metrics, string.format("nsboot_version_info{version=\"%s\"} 1", info.version))
    table.insert(metrics, string.format("nsboot_uptime_seconds %d", info.uptime or 0))
    
    -- ZFS metrics
    table.insert(metrics, string.format("nsboot_zfs_pool_size_bytes %d", info.zfs_pool_size))
    table.insert(metrics, string.format("nsboot_zfs_pool_used_bytes %d", info.zfs_pool_usage))
    table.insert(metrics, string.format("nsboot_zfs_pool_available_bytes %d", info.zfs_pool_available))
    
    -- Client metrics
    local clients = _M.get_clients()
    table.insert(metrics, string.format("nsboot_active_clients %d", #clients))
    
    -- Image metrics
    local images = _M.get_images()
    table.insert(metrics, string.format("nsboot_total_images %d", #images))
    
    return table.concat(metrics, "\n") .. "\n"
end

return _M
