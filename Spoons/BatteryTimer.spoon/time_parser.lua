--- Time Parser Module
--- Parses custom time input like "90min", "2hr", "45s"

local M = {}

--- Parse custom time input and convert to minutes
--- @param input string Input like "90min", "2hr", "45s", or just "120"
--- @return number|nil Minutes, or nil if invalid
function M.parseTimeInput(input)
    if not input or input == "" then return nil end
    
    -- Try to match patterns like "90min", "2hr", "45s"
    local num, unit = input:match("^(%d+)(%a+)$")
    
    if not num then
        -- Maybe just a number? assume minutes
        num = input:match("^(%d+)$")
        if num then
            return tonumber(num)
        end
        return nil
    end
    
    num = tonumber(num)
    unit = unit:lower()
    
    -- Convert to minutes
    if unit == "s" or unit == "sec" or unit == "second" or unit == "seconds" then
        return num / 60
    elseif unit == "m" or unit == "min" or unit == "minute" or unit == "minutes" then
        return num
    elseif unit == "h" or unit == "hr" or unit == "hour" or unit == "hours" then
        return num * 60
    else
        return nil
    end
end

--- Format time in seconds to a display string (HH:MM:SS or MM:SS)
--- @param seconds number Time in seconds
--- @return string Formatted time string
function M.formatTime(seconds)
    local hours = math.floor(seconds / 3600)
    local mins = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60
    
    if hours > 0 then
        return string.format("%d:%02d:%02d", hours, mins, secs)
    else
        return string.format("%d:%02d", mins, secs)
    end
end

return M

