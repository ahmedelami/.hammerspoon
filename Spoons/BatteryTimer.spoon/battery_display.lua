--- Battery Display Module
--- Handles drawing the battery icon at different fill levels

local M = {}

-- Battery drawing parameters
local BATTERY_WIDTH = 50
local BATTERY_HEIGHT = 20
local TERMINAL_WIDTH = 3
local TERMINAL_HEIGHT = 10

--- Draw battery icon with fill percentage and timer text
--- @param percentage number The fill percentage (0-100)
--- @param timeText string Optional timer text to show on the LEFT
--- @return hs.image The battery icon image
function M.drawBattery(percentage, timeText)
    -- Calculate total width including time text on LEFT
    local timeWidth = timeText and 70 or 0
    local totalWidth = timeWidth + BATTERY_WIDTH + TERMINAL_WIDTH + 4
    
    -- Create canvas for drawing
    local canvas = hs.canvas.new({x = 0, y = 0, w = totalWidth, h = BATTERY_HEIGHT + 4})
    
    -- Background (transparent)
    canvas[1] = {
        type = "rectangle",
        action = "fill",
        fillColor = {alpha = 0},
        frame = {x = 0, y = 0, w = totalWidth, h = BATTERY_HEIGHT + 4}
    }
    
    -- Draw timer text on the LEFT if provided
    if timeText then
        canvas[2] = {
            type = "text",
            text = timeText,
            textColor = {white = 1.0, alpha = 1.0},
            textSize = 14,
            textAlignment = "right",
            frame = {x = 0, y = 4, w = timeWidth - 5, h = BATTERY_HEIGHT}
        }
    end
    
    -- Determine color based on percentage FIRST
    -- Colors: Green (100-75%), Yellow (74-40%), Red (39-0%)
    local batteryColor
    
    if percentage >= 75 then
        batteryColor = {red = 0.2, green = 0.8, blue = 0.2, alpha = 1.0} -- Green
        print("DEBUG: Drawing battery at " .. percentage .. "% - GREEN")
    elseif percentage >= 40 then
        batteryColor = {red = 0.9, green = 0.65, blue = 0.0, alpha = 1.0} -- Darker Yellow/Orange
        print("DEBUG: Drawing battery at " .. percentage .. "% - YELLOW")
    else
        batteryColor = {red = 1.0, green = 0.2, blue = 0.2, alpha = 1.0} -- Red
        print("DEBUG: Drawing battery at " .. percentage .. "% - RED")
    end
    
    -- Battery terminal (positive end) - shifted right for timer text, BLACK to match border
    local batteryStartX = timeWidth
    canvas[3] = {
        type = "rectangle",
        action = "fill",
        fillColor = {white = 0.0, alpha = 1.0},
        roundedRectRadii = {xRadius = 2, yRadius = 2},
        frame = {
            x = batteryStartX + 2,
            y = (BATTERY_HEIGHT - TERMINAL_HEIGHT) / 2 + 2,
            w = TERMINAL_WIDTH,
            h = TERMINAL_HEIGHT
        }
    }
    
    -- Battery body outline - stays BLACK
    canvas[4] = {
        type = "rectangle",
        action = "stroke",
        strokeColor = {white = 0.0, alpha = 1.0},
        strokeWidth = 2,
        roundedRectRadii = {xRadius = 3, yRadius = 3},
        frame = {x = batteryStartX + TERMINAL_WIDTH + 2, y = 2, w = BATTERY_WIDTH, h = BATTERY_HEIGHT}
    }
    
    -- Battery fill - same color as outline
    -- Fill stays on RIGHT, empty grows from LEFT
    local fillWidth = (BATTERY_WIDTH - 8) * (percentage / 100)
    local rightEdgeX = batteryStartX + TERMINAL_WIDTH + 6 + (BATTERY_WIDTH - 8)
    local fillStartX = rightEdgeX - fillWidth
    
    canvas[5] = {
        type = "rectangle",
        action = "fill",
        fillColor = batteryColor,
        roundedRectRadii = {xRadius = 2, yRadius = 2},
        frame = {x = fillStartX, y = 6, w = fillWidth, h = BATTERY_HEIGHT - 8}
    }
    
    -- Get image from canvas
    local image = canvas:imageFromCanvas()
    canvas:delete()
    
    return image
end

return M

