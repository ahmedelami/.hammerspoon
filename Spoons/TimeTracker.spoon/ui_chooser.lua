-- UI Chooser Module
-- Handles the task selection interface with filtering and autocomplete

local M = {}

function M.getAllChoices(groups, markedForDeletion)
    local choices = {}
    for _, group in ipairs(groups) do
        local isMarked = markedForDeletion[group] or false
        local displayText = isMarked and "✓ " .. group or group
        
        table.insert(choices, {
            text = displayText,
            subText = isMarked and "Marked for deletion" or "Full path",
            path = group,
            fullPath = group,
            marked = isMarked
        })
    end
    return choices
end

function M.filterChoices(allChoices, query)
    if not query or query == "" then
        return allChoices
    end
    
    local filtered = {}
    local lowerQuery = string.lower(query)
    
    for _, choice in ipairs(allChoices) do
        local lowerText = string.lower(choice.text)
        
        -- Match if query appears anywhere in path
        if lowerText:find(lowerQuery, 1, true) then
            table.insert(filtered, choice)
        end
    end
    
    return filtered
end

return M

