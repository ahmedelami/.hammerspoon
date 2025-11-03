-- Simple .env file loader for Hammerspoon
local M = {}

function M.load(path)
    local env = {}
    local file = io.open(path, "r")
    if not file then
        return env
    end
    
    for line in file:lines() do
        -- Skip comments and empty lines
        if not line:match("^%s*#") and not line:match("^%s*$") then
            local key, value = line:match("^%s*([%w_]+)%s*=%s*(.+)%s*$")
            if key and value then
                env[key] = value
            end
        end
    end
    
    file:close()
    return env
end

return M

