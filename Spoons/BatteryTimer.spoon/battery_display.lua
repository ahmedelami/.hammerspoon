--- Battery Display Module
--- Handles drawing the battery icon at different fill levels

local M = {}

-- Battery drawing parameters
local BATTERY_WIDTH = 50
local BATTERY_HEIGHT = 20
local TERMINAL_WIDTH = 3
local TERMINAL_HEIGHT = 10
local BATTERY_STROKE_WIDTH = 2

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
    local idx = 1

    -- Background (transparent)
    canvas[idx] = {
        type = "rectangle",
        action = "fill",
        fillColor = {alpha = 0},
        frame = {x = 0, y = 0, w = totalWidth, h = BATTERY_HEIGHT + 4}
    }
    idx = idx + 1

    -- Draw timer text on the LEFT if provided
    if timeText then
        canvas[idx] = {
            type = "text",
            text = timeText,
            textColor = {white = 0.0, alpha = 1.0},
            textSize = 14,
            textAlignment = "right",
            frame = {x = 0, y = 4, w = timeWidth - 5, h = BATTERY_HEIGHT}
        }
        idx = idx + 1
    end

    -- Determine gradient colors based on percentage using warm tones
    local gradientStart
    local gradientFinish
    if percentage >= 80 then
        gradientStart = {red = 0.25, green = 0.95, blue = 0.45, alpha = 1.0}
        gradientFinish = {red = 0.1, green = 0.65, blue = 0.2, alpha = 1.0}
    elseif percentage >= 30 then
        gradientStart = {red = 1.0, green = 0.82, blue = 0.35, alpha = 1.0}
        gradientFinish = {red = 0.95, green = 0.65, blue = 0.1, alpha = 1.0}
    else
        gradientStart = {red = 1.0, green = 0.55, blue = 0.15, alpha = 1.0}
        gradientFinish = {red = 0.95, green = 0.32, blue = 0.05, alpha = 1.0}
    end

    -- Battery terminal (positive end) - shifted right for timer text
    local batteryStartX = timeWidth
    local outlineColor = {white = 0.0, alpha = 1.0}

    canvas[idx] = {
        type = "rectangle",
        action = "fill",
        fillColor = outlineColor,
        roundedRectRadii = {xRadius = 2, yRadius = 2},
        frame = {
            x = batteryStartX + 2,
            y = (BATTERY_HEIGHT - TERMINAL_HEIGHT) / 2 + 2,
            w = TERMINAL_WIDTH,
            h = TERMINAL_HEIGHT
        }
    }
    idx = idx + 1

    -- Battery body outline
    local outlineFrame = {x = batteryStartX + TERMINAL_WIDTH + 2, y = 2, w = BATTERY_WIDTH, h = BATTERY_HEIGHT}
    canvas[idx] = {
        type = "rectangle",
        action = "stroke",
        strokeColor = outlineColor,
        strokeWidth = BATTERY_STROKE_WIDTH,
        roundedRectRadii = {xRadius = 3, yRadius = 3},
        frame = outlineFrame
    }
    idx = idx + 1

    -- Solid interior base to ensure margin is black
    local baseInset = BATTERY_STROKE_WIDTH / 2
    local baseFrame = {
        x = outlineFrame.x + baseInset,
        y = outlineFrame.y + baseInset,
        w = BATTERY_WIDTH - baseInset * 2,
        h = BATTERY_HEIGHT - baseInset * 2
    }
    canvas[idx] = {
        type = "rectangle",
        action = "fill",
        fillColor = {white = 0.0, alpha = 1.0},
        roundedRectRadii = {xRadius = 2, yRadius = 2},
        frame = baseFrame
    }
    idx = idx + 1

    -- Battery fill - fill now shrinks from RIGHT towards LEFT like a system battery icon
    local INNER_PADDING = 4
    local innerWidth = BATTERY_WIDTH - (INNER_PADDING * 2)
    local fillWidth = math.max(innerWidth * (percentage / 100), 0)
    local fillStartX = outlineFrame.x + INNER_PADDING
    local innerEndX = fillStartX + innerWidth
    local fillHeight = BATTERY_HEIGHT - (INNER_PADDING * 2)
    local fillY = outlineFrame.y + INNER_PADDING

    if fillWidth > 0 then
        local fillX = innerEndX - fillWidth
        canvas[idx] = {
            type = "rectangle",
            action = "fill",
            fillColor = gradientStart,
            roundedRectRadii = {xRadius = 2, yRadius = 2},
            frame = {x = fillX, y = fillY, w = fillWidth, h = fillHeight},
            fillGradient = {
                type = "linear",
                from = {x = fillX, y = fillY},
                to = {x = fillX + fillWidth, y = fillY},
                stops = {
                    {position = 0, color = gradientStart},
                    {position = 1, color = gradientFinish}
                }
            }
        }
        idx = idx + 1
    end

    -- Get image from canvas
    local image = canvas:imageFromCanvas()
    canvas:delete()

    return image
end

return M
