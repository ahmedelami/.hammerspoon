-- Notion Sync Module
-- Handles syncing time entries to Notion database

local M = {}

-- Configuration
M.enabled = false
M.apiToken = nil
M.databaseId = nil

function M.configure(apiToken, databaseId)
    M.apiToken = apiToken
    M.databaseId = databaseId
    M.enabled = (apiToken ~= nil and apiToken ~= "" and databaseId ~= nil and databaseId ~= "")
end

function M.isEnabled()
    return M.enabled
end

function M.syncToNotion(startTime, endTime, path, startNote, endNote)
    if not M.enabled then
        return false, "Notion sync not configured"
    end
    
    -- Format duration in minutes
    local durationMinutes = math.floor((endTime - startTime) / 60)
    
    -- Format dates for Notion
    local startISO = os.date("!%Y-%m-%dT%H:%M:%S.000Z", startTime)
    local endISO = os.date("!%Y-%m-%dT%H:%M:%S.000Z", endTime)
    
    -- Build the JSON payload
    local payload = {
        parent = {
            database_id = M.databaseId
        },
        properties = {
            Name = {
                title = {
                    {
                        text = {
                            content = path
                        }
                    }
                }
            },
            ["Start Time"] = {
                date = {
                    start = startISO
                }
            },
            ["End Time"] = {
                date = {
                    start = endISO
                }
            },
            Duration = {
                number = durationMinutes
            },
            ["Start Note"] = {
                rich_text = {
                    {
                        text = {
                            content = startNote or ""
                        }
                    }
                }
            },
            ["End Note"] = {
                rich_text = {
                    {
                        text = {
                            content = endNote or ""
                        }
                    }
                }
            }
        }
    }
    
    -- Convert payload to JSON
    local json = hs.json.encode(payload)
    
    -- Create curl command to send to Notion API
    local curlCmd = string.format(
        [[curl -s -X POST 'https://api.notion.com/v1/pages' \
        -H 'Authorization: Bearer %s' \
        -H 'Content-Type: application/json' \
        -H 'Notion-Version: 2022-06-28' \
        -d '%s']],
        M.apiToken,
        json:gsub("'", "'\\''")  -- Escape single quotes for shell
    )
    
    -- Execute async to not block UI
    hs.task.new("/bin/sh", function(exitCode, stdOut, stdErr)
        if exitCode == 0 then
            print("✅ Synced to Notion: " .. path)
        else
            print("❌ Failed to sync to Notion: " .. stdErr)
        end
    end, {"-c", curlCmd}):start()
    
    return true, "Syncing to Notion..."
end

return M

