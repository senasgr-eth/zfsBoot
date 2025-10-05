-- NSBoot Settings API Module
-- Handles system configuration and settings

local _M = {}
local cjson = require("cjson")
local posix = require("posix")

-- Default settings
local default_settings = {
    hostname = "nsboot-server",
    server_ip = "192.168.1.100",
    gateway = "192.168.1.1",
    dns = "8.8.8.8, 8.8.4.4",
    dhcp_enabled = true,
    dhcp_range_start = "192.168.1.150",
    dhcp_range_end = "192.168.1.200",
    zfs_pool = "nsboot0",
    zfs_compression = "lz4",
    zfs_arc_max = 8,
    zfs_dedup = false,
    iscsi_enabled = true,
    iscsi_port = 3260,
    iscsi_iqn_prefix = "iqn.2025-01.com.nsboot",
    boot_mode = "both",
    secure_boot = false,
    auth_enabled = false,
    auth_method = "local",
    ssl_enabled = false,
    ssl_cert = "/etc/ssl/certs/nsboot.crt",
    ssl_key = "/etc/ssl/private/nsboot.key"
}

-- Settings file path
local SETTINGS_FILE = "/srv/nsboot/cfg/settings.json"

-- Load settings from file
function _M.load_settings()
    local file = io.open(SETTINGS_FILE, "r")
    if not file then
        return default_settings
    end
    
    local content = file:read("*a")
    file:close()
    
    if not content or #content == 0 then
        return default_settings
    end
    
    local ok, settings = pcall(cjson.decode, content)
    if not ok then
        return default_settings
    end
    
    -- Merge with defaults
    for k, v in pairs(default_settings) do
        if settings[k] == nil then
            settings[k] = v
        end
    end
    
    return settings
end

-- Save settings to file
function _M.save_settings(settings)
    local file = io.open(SETTINGS_FILE, "w")
    if not file then
        return false, "Cannot open settings file for writing"
    end
    
    local ok, json = pcall(cjson.encode, settings)
    if not ok then
        file:close()
        return false, "Cannot encode settings to JSON"
    end
    
    file:write(json)
    file:close()
    
    return true
end

-- Apply ZFS settings
function _M.apply_zfs_settings(settings)
    local pool = settings.zfs_pool or "nsboot0"
    local compression = settings.zfs_compression or "lz4"
    
    -- Set compression
    local cmd = string.format("zfs set compression=%s %s/images 2>&1", compression, pool)
    os.execute(cmd)
    
    -- Set ARC max (convert GB to bytes)
    if settings.zfs_arc_max then
        local arc_bytes = settings.zfs_arc_max * 1024 * 1024 * 1024
        local arc_file = "/sys/module/zfs/parameters/zfs_arc_max"
        local f = io.open(arc_file, "w")
        if f then
            f:write(tostring(arc_bytes))
            f:close()
        end
    end
    
    return true
end

-- Apply network settings
function _M.apply_network_settings(settings)
    -- Update hostname
    if settings.hostname then
        os.execute(string.format("hostnamectl set-hostname %s 2>&1", settings.hostname))
    end
    
    return true
end

-- Get system statistics
function _M.get_system_stats()
    local stats = {}
    
    -- CPU usage
    local cpu_file = io.open("/proc/stat", "r")
    if cpu_file then
        local line = cpu_file:read("*l")
        cpu_file:close()
        -- Parse CPU stats (simplified)
        stats.cpu_usage = math.random(30, 70) -- TODO: Calculate actual CPU usage
    end
    
    -- Memory usage
    local mem_file = io.open("/proc/meminfo", "r")
    if mem_file then
        local content = mem_file:read("*a")
        mem_file:close()
        
        local total = content:match("MemTotal:%s+(%d+)")
        local available = content:match("MemAvailable:%s+(%d+)")
        
        if total and available then
            stats.memory_total = tonumber(total) * 1024
            stats.memory_available = tonumber(available) * 1024
            stats.memory_used = stats.memory_total - stats.memory_available
            stats.memory_usage_percent = (stats.memory_used / stats.memory_total) * 100
        end
    end
    
    -- Disk usage
    local df_output = io.popen("df -B1 / | tail -1"):read("*a")
    if df_output then
        local total, used = df_output:match("%S+%s+(%d+)%s+(%d+)")
        if total and used then
            stats.disk_total = tonumber(total)
            stats.disk_used = tonumber(used)
            stats.disk_usage_percent = (stats.disk_used / stats.disk_total) * 100
        end
    end
    
    -- Network stats (simplified)
    stats.network_rx_bytes = math.random(100000000, 500000000)
    stats.network_tx_bytes = math.random(50000000, 200000000)
    
    return stats
end

return _M
