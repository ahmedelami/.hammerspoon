-- CSV Manager Module
-- Handles all CSV operations for TimeTracker

local M = {}

function M.escapeCSV(str)
    if not str then return "" end
    if str:find('[,"]') then
        return '"' .. str:gsub('"', '""') .. '"'
    end
    return str
end

function M.initCSV(csvPath)
    local file = io.open(csvPath, "r")
    if not file then
        file = io.open(csvPath, "w")
        if file then
            file:write("Start Time,End Time,Duration (minutes),Path,Start Note,End Note\n")
            file:close()
        end
    else
        file:close()
    end
end

function M.logToCSV(csvPath, startTime, endTime, path, startNote, endNote)
    local duration = math.floor((endTime - startTime) / 60)

    local file = io.open(csvPath, "a")
    if file then
        local startStr = os.date("%Y-%m-%d %H:%M:%S", startTime)
        local endStr = os.date("%Y-%m-%d %H:%M:%S", endTime)

        file:write(string.format("%s,%s,%d,%s,%s,%s\n",
            startStr, endStr, duration,
            M.escapeCSV(path),
            M.escapeCSV(startNote or ""),
            M.escapeCSV(endNote or "")
        ))
        file:close()

        return duration
    end
    return 0
end

return M

