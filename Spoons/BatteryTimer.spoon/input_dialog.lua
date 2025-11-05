--- Custom Input Dialog Module
--- Creates a custom text input dialog with auto-focus

local M = {}

--- Show a custom text input dialog
--- @param callback function Callback function that receives the text input
function M.show(callback)
    local screen = hs.mouse.getCurrentScreen()
    local frame = screen:frame()
    
    -- Dialog dimensions
    local dialogW = 400
    local dialogH = 150
    local dialogX = (frame.w - dialogW) / 2 + frame.x
    local dialogY = (frame.h - dialogH) / 2 + frame.y
    
    -- Create canvas
    local canvas = hs.canvas.new({x = dialogX, y = dialogY, w = dialogW, h = dialogH})
    canvas:level("floating")
    canvas:behavior(hs.canvas.windowBehaviors.canJoinAllSpaces)
    
    -- Background
    canvas[1] = {
        type = "rectangle",
        action = "fill",
        fillColor = {red = 0.15, green = 0.15, blue = 0.15, alpha = 0.98},
        roundedRectRadii = {xRadius = 10, yRadius = 10}
    }
    
    -- Title
    canvas[2] = {
        type = "text",
        text = "⚡ Set Battery Timer",
        textColor = {white = 1.0},
        textSize = 18,
        textAlignment = "center",
        frame = {x = 20, y = 15, w = dialogW - 40, h = 30}
    }
    
    -- Instructions
    canvas[3] = {
        type = "text",
        text = "Examples: 90min, 2hr, 45s, or just 120",
        textColor = {white = 0.7},
        textSize = 12,
        textAlignment = "center",
        frame = {x = 20, y = 45, w = dialogW - 40, h = 20}
    }
    
    -- Input box background
    canvas[4] = {
        type = "rectangle",
        action = "fill",
        fillColor = {white = 0.2},
        roundedRectRadii = {xRadius = 5, yRadius = 5},
        frame = {x = 30, y = 75, w = dialogW - 60, h = 35}
    }
    
    -- Input text (will be updated)
    canvas[5] = {
        type = "text",
        text = "",
        textColor = {white = 1.0},
        textSize = 16,
        textAlignment = "left",
        frame = {x = 40, y = 78, w = dialogW - 80, h = 30}
    }
    
    canvas:show()
    
    -- Input state
    local inputText = ""
    
    -- Update display
    local function updateDisplay()
        canvas[5].text = inputText
    end
    
    -- Cleanup function
    local function cleanup()
        canvas:hide()
        canvas:delete()
    end
    
    -- Key handler
    local eventtap = hs.eventtap.new({hs.eventtap.event.types.keyDown}, function(event)
        local keyCode = event:getKeyCode()
        local chars = event:getCharacters()
        local flags = event:getFlags()
        
        -- Enter key
        if keyCode == 36 or keyCode == 76 then
            cleanup()
            callback(inputText)
            return true
        end
        
        -- Escape key
        if keyCode == 53 then
            cleanup()
            callback(nil)
            return true
        end
        
        -- Cmd+Delete or Cmd+Backspace - clear entire line
        if (keyCode == 51 or keyCode == 117) and flags.cmd then
            inputText = ""
            updateDisplay()
            return true
        end
        
        -- Cmd+A - select all (we'll just clear for simplicity)
        if keyCode == 0 and flags.cmd then
            inputText = ""
            updateDisplay()
            return true
        end
        
        -- Delete/Backspace
        if keyCode == 51 then
            if #inputText > 0 then
                inputText = inputText:sub(1, -2)
                updateDisplay()
            end
            return true
        end
        
        -- Forward delete
        if keyCode == 117 then
            -- Just treat like backspace for now
            if #inputText > 0 then
                inputText = inputText:sub(1, -2)
                updateDisplay()
            end
            return true
        end
        
        -- Regular character input
        if chars and #chars > 0 and not flags.cmd and not flags.ctrl then
            inputText = inputText .. chars
            updateDisplay()
            return true
        end
        
        return false
    end)
    
    eventtap:start()
    
    -- Also cleanup eventtap on canvas delete
    local originalCleanup = cleanup
    cleanup = function()
        if eventtap then
            eventtap:stop()
            eventtap = nil
        end
        originalCleanup()
    end
    
    updateDisplay()
end

return M

