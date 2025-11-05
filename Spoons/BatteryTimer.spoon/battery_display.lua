--- Battery Display Module
--- Handles drawing the battery icon at different fill levels

local M = {}

-- Battery drawing parameters
local BATTERY_WIDTH = 50
local BATTERY_HEIGHT = 20
local TERMINAL_WIDTH = 3
local TERMINAL_HEIGHT = 10

--- Draw battery icon with fill percentage
--- @param percentage number The fill percentage (0-100)
--- @return hs.image The battery icon image
function M.drawBattery(percentage)
    -- Create canvas for drawing (reduced width padding for tighter spacing)
    local canvas = hs.canvas.new({x = 0, y = 0, w = BATTERY_WIDTH + TERMINAL_WIDTH + 4, h = BATTERY_HEIGHT + 4})
    
    -- Background (transparent)
    canvas[1] = {
        type = "rectangle",
        action = "fill",
        fillColor = {alpha = 0},
        frame = {x = 0, y = 0, w = BATTERY_WIDTH + TERMINAL_WIDTH + 4, h = BATTERY_HEIGHT + 4}
    }
    
    -- Battery terminal (positive end) - now on LEFT side
    canvas[2] = {
        type = "rectangle",
        action = "fill",
        fillColor = {white = 1.0},
        roundedRectRadii = {xRadius = 2, yRadius = 2},
        frame = {
            x = 2,
            y = (BATTERY_HEIGHT - TERMINAL_HEIGHT) / 2 + 2,
            w = TERMINAL_WIDTH,
            h = TERMINAL_HEIGHT
        }
    }
    
    -- Battery body outline - shifted right to accommodate left terminal
    canvas[3] = {
        type = "rectangle",
        action = "stroke",
        strokeColor = {white = 1.0},
        strokeWidth = 2,
        roundedRectRadii = {xRadius = 3, yRadius = 3},
        frame = {x = TERMINAL_WIDTH + 2, y = 2, w = BATTERY_WIDTH, h = BATTERY_HEIGHT}
    }
    
    -- Battery fill (color changes based on percentage)
    -- Fill from LEFT (full) to RIGHT (empty) by starting from left edge
    local fillWidth = (BATTERY_WIDTH - 8) * (percentage / 100)
    local fillColor
    
    if percentage > 60 then
        fillColor = {red = 0.3, green = 0.8, blue = 0.3} -- Green
    elseif percentage > 30 then
        fillColor = {red = 1.0, green = 0.8, blue = 0.0} -- Yellow/Orange
    else
        fillColor = {red = 1.0, green = 0.3, blue = 0.3} -- Red
    end
    
    canvas[4] = {
        type = "rectangle",
        action = "fill",
        fillColor = fillColor,
        roundedRectRadii = {xRadius = 2, yRadius = 2},
        frame = {x = TERMINAL_WIDTH + 6, y = 6, w = fillWidth, h = BATTERY_HEIGHT - 8}
    }
    
    -- Get image from canvas
    local image = canvas:imageFromCanvas()
    canvas:delete()
    
    return image
end

return M

