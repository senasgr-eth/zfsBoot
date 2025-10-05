-- NSBoot Authentication Module
-- JWT-based authentication for API endpoints

local _M = {}
local jwt = require("resty.jwt")
local cjson = require("cjson")

-- Configuration
local JWT_SECRET = os.getenv("JWT_SECRET") or "nsboot_secret_change_in_production"
local JWT_EXPIRY = tonumber(os.getenv("JWT_EXPIRY")) or 86400  -- 24 hours

-- User database (in production, use external database)
local users = {
    admin = {
        username = "admin",
        password_hash = "240be518fabd2724ddb6f04eeb1da5967448d7e831c08c8fa822809f74c720a9",  -- sha256("admin")
        role = "admin"
    }
}

-- Hash password (simple SHA256 for demo)
local function hash_password(password)
    local sha256 = require("resty.sha256")
    local str = require("resty.string")
    
    local hasher = sha256:new()
    hasher:update(password)
    local digest = hasher:final()
    
    return str.to_hex(digest)
end

-- Verify password
local function verify_password(username, password)
    local user = users[username]
    if not user then
        return false
    end
    
    local password_hash = hash_password(password)
    return password_hash == user.password_hash
end

-- Generate JWT token
function _M.generate_token(username)
    local user = users[username]
    if not user then
        return nil, "User not found"
    end
    
    local payload = {
        sub = username,
        role = user.role,
        iat = os.time(),
        exp = os.time() + JWT_EXPIRY
    }
    
    local token = jwt:sign(JWT_SECRET, {
        header = {typ = "JWT", alg = "HS256"},
        payload = payload
    })
    
    return token
end

-- Verify JWT token
function _M.verify_token(token)
    if not token then
        return false, "No token provided"
    end
    
    local jwt_obj = jwt:verify(JWT_SECRET, token)
    
    if not jwt_obj.verified then
        return false, jwt_obj.reason
    end
    
    -- Check expiry
    if jwt_obj.payload.exp < os.time() then
        return false, "Token expired"
    end
    
    return true, jwt_obj.payload
end

-- Login endpoint
function _M.login(username, password)
    if not username or not password then
        return {
            success = false,
            message = "Username and password required"
        }
    end
    
    if not verify_password(username, password) then
        return {
            success = false,
            message = "Invalid credentials"
        }
    end
    
    local token, err = _M.generate_token(username)
    if not token then
        return {
            success = false,
            message = err
        }
    end
    
    local user = users[username]
    return {
        success = true,
        token = token,
        user = {
            username = user.username,
            role = user.role
        },
        expires_in = JWT_EXPIRY
    }
end

-- Middleware to check authentication
function _M.require_auth()
    local auth_header = ngx.var.http_authorization
    
    if not auth_header then
        ngx.status = 401
        ngx.header["Content-Type"] = "application/json"
        ngx.say(cjson.encode({
            error = "Unauthorized",
            message = "No authorization header"
        }))
        return ngx.exit(401)
    end
    
    -- Extract token from "Bearer <token>"
    local token = auth_header:match("Bearer%s+(.+)")
    if not token then
        ngx.status = 401
        ngx.header["Content-Type"] = "application/json"
        ngx.say(cjson.encode({
            error = "Unauthorized",
            message = "Invalid authorization header format"
        }))
        return ngx.exit(401)
    end
    
    local verified, payload_or_err = _M.verify_token(token)
    if not verified then
        ngx.status = 401
        ngx.header["Content-Type"] = "application/json"
        ngx.say(cjson.encode({
            error = "Unauthorized",
            message = payload_or_err
        }))
        return ngx.exit(401)
    end
    
    -- Store user info in ngx.ctx for later use
    ngx.ctx.user = payload_or_err
    return true
end

-- Check if user has required role
function _M.require_role(required_role)
    if not ngx.ctx.user then
        ngx.status = 403
        ngx.header["Content-Type"] = "application/json"
        ngx.say(cjson.encode({
            error = "Forbidden",
            message = "Authentication required"
        }))
        return ngx.exit(403)
    end
    
    if ngx.ctx.user.role ~= required_role and ngx.ctx.user.role ~= "admin" then
        ngx.status = 403
        ngx.header["Content-Type"] = "application/json"
        ngx.say(cjson.encode({
            error = "Forbidden",
            message = "Insufficient permissions"
        }))
        return ngx.exit(403)
    end
    
    return true
end

-- Refresh token
function _M.refresh_token(old_token)
    local verified, payload = _M.verify_token(old_token)
    if not verified then
        return {
            success = false,
            message = "Invalid token"
        }
    end
    
    local new_token = _M.generate_token(payload.sub)
    return {
        success = true,
        token = new_token,
        expires_in = JWT_EXPIRY
    }
end

-- Logout (in stateless JWT, just return success)
function _M.logout()
    return {
        success = true,
        message = "Logged out successfully"
    }
end

return _M
