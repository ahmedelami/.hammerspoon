--- === MouseDrag ===
---
--- Hold a hotkey to enable mouse dragging without clicking
---
--- Download: N/A
--- Author: Ahmed Elamin
--- License: MIT

local obj = {}
obj.__index = obj

-- Metadata
obj.name = "MouseDrag"
obj.version = "1.0"
obj.author = "Ahmed Elamin"
obj.license = "MIT"

-- State variables
obj.T = nil
obj.UD = nil
obj.hot = false
obj.down = false
obj.guard = nil
obj.mover = nil

-- Configurable options
obj.hotkey = {{"alt"}, "`"}

-- ============== HELPERS ==============

function obj:post(t)
    local e = hs.eventtap.event.newMouseEvent(t, hs.mouse.absolutePosition())
    e:setProperty(self.UD, 42):post()
end

function obj:startDrag()
    if self.hot then return end
    self.hot = true
    self.guard:start()
    self.mover:start()
    self.down = true
    self:post(self.T.leftMouseDown)
end

function obj:stopDrag()
    if not self.hot then return end
    self.hot = false
    self.mover:stop()
    self.guard:stop()
    if self.down then
        self.down = false
        self:post(self.T.leftMouseUp)
    end
end

-- ============== INITIALIZATION ==============

function obj:init()
    self.T = hs.eventtap.event.types
    self.UD = hs.eventtap.event.properties.eventSourceUserData
    
    self.guard = hs.eventtap.new({self.T.leftMouseDown, self.T.leftMouseUp}, function(e)
        if not self.hot then return false end
        if (e:getProperty(self.UD) or 0) == 42 then return false end
        return true
    end)
    
    self.mover = hs.eventtap.new({self.T.mouseMoved}, function(e)
        if self.hot and self.down then
            local c = e:copy()
            c:setType(self.T.leftMouseDragged)
            c:setProperty(self.UD, 42)
            c:post()
            return true
        end
        return false
    end)
    
    return self
end

function obj:start()
    hs.hotkey.bind(
        self.hotkey[1],
        self.hotkey[2],
        function() self:startDrag() end,
        function() self:stopDrag() end
    )
    
    return self
end

function obj:stop()
    if self.hot then
        self:stopDrag()
    end
    
    if self.guard then
        self.guard:stop()
    end
    
    if self.mover then
        self.mover:stop()
    end
    
    return self
end

return obj

