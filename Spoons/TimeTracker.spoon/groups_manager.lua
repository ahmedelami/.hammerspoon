-- Groups Manager Module
-- Handles group storage, deletion, and management

local M = {}

function M.initGroupsCSV(groupsPath)
    local file = io.open(groupsPath, "r")
    if not file then
        file = io.open(groupsPath, "w")
        if file then
            file:write("Path\n")
            file:close()
        end
    else
        file:close()
    end
end

function M.loadGroups(groupsPath)
    local groups = {}
    local file = io.open(groupsPath, "r")
    if not file then return groups end

    local firstLine = true
    for line in file:lines() do
        if not firstLine then
            line = line:gsub("^%s+", ""):gsub("%s+$", "")
            if line ~= "" then
                table.insert(groups, line)
            end
        end
        firstLine = false
    end
    file:close()
    
    return groups
end

function M.saveGroup(groupsPath, groups, path)
    -- Enforce flat groups: remove any :: separators
    path = path:gsub("::", " ")
    
    for _, existing in ipairs(groups) do
        if existing == path then return groups end
    end

    table.insert(groups, path)
    table.sort(groups)

    local file = io.open(groupsPath, "a")
    if file then
        file:write(path .. "\n")
        file:close()
    end
    
    return groups
end

function M.deleteGroup(groupsPath, csvPath, groups, pathToDelete)
    -- Remove from groups array
    local newGroups = {}
    local deletedCount = 0
    
    for _, group in ipairs(groups) do
        -- Delete exact match only (no subpaths since we're flat now)
        if group ~= pathToDelete then
            table.insert(newGroups, group)
        else
            deletedCount = deletedCount + 1
        end
    end
    
    -- Rewrite groups CSV
    local file = io.open(groupsPath, "w")
    if file then
        file:write("Path\n")
        for _, group in ipairs(newGroups) do
            file:write(group .. "\n")
        end
        file:close()
    end
    
    -- Remove all time entries with this path from time_tracking.csv
    M.deleteTimeEntries(csvPath, pathToDelete)
    
    return newGroups, deletedCount
end

function M.deleteTimeEntries(csvPath, pathToDelete)
    local tempPath = csvPath .. ".tmp"
    local inputFile = io.open(csvPath, "r")
    if not inputFile then return 0 end
    
    local outputFile = io.open(tempPath, "w")
    if not outputFile then
        inputFile:close()
        return 0
    end
    
    local firstLine = true
    local deletedCount = 0
    
    for line in inputFile:lines() do
        if firstLine then
            -- Keep header
            outputFile:write(line .. "\n")
            firstLine = false
        else
            -- Check if this line contains the path to delete
            local pathInLine = line:match("^[^,]*,[^,]*,[^,]*,([^,]*),")
            
            -- Remove quotes if present
            if pathInLine then
                pathInLine = pathInLine:gsub('^"', ''):gsub('"$', ''):gsub('""', '"')
            end
            
            -- Keep line if it doesn't match the path (exact match only)
            if pathInLine and pathInLine ~= pathToDelete then
                outputFile:write(line .. "\n")
            else
                deletedCount = deletedCount + 1
            end
        end
    end
    
    inputFile:close()
    outputFile:close()
    
    -- Replace original file with temp file
    os.remove(csvPath)
    os.rename(tempPath, csvPath)
    
    return deletedCount
end

return M

