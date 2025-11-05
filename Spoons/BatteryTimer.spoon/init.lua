--- === BatteryTimer ===
---
--- A visual "battery of effort" timer for the menu bar
--- Shows a draining battery with countdown timer
--- Perfect for tracking study sessions or med focus time
---
--- Download: N/A
--- License: MIT

local obj = {}
obj.__index = obj

-- Load modules
local spoonPath = hs.spoons.scriptPath()
package.path = package.path .. ";" .. spoonPath .. "/?.lua"
local batteryDisplay = require("battery_display")
local timeParser = require("time_parser")
local timerManager = require("timer_manager")
local inputDialog = require("input_dialog")

-- Metadata
obj.name = "BatteryTimer"
obj.version = "1.0"
obj.author = "Custom"
obj.license = "MIT"

-- State
obj.hotkey = nil
obj.menubar = nil
obj.timerManager = nil

-- Configuration
obj.hotkeyMods = {"ctrl", "alt"}
obj.hotkeyKey = "b"

--- Initialize the spoon
function obj:init()
    self.timerManager = timerManager.new()
    return self
end

--- Update the menu bar display
function obj:updateDisplay(state)
    if not self.menubar then return end
    
    if state.finished then
        -- Timer finished - combined image with timer on LEFT
        local batteryIcon = batteryDisplay.drawBattery(0, "0:00")
        self.menubar:setIcon(batteryIcon, false)
        
        hs.alert.show("⚡ Battery depleted! Time's up!", 3)
        
        -- Remove menu bar after a short delay
        hs.timer.doAfter(2, function()
            if self.menubar then
                self.menubar:delete()
                self.menubar = nil
            end
        end)
    else
        -- Timer running - combined image with timer on LEFT, battery on RIGHT
        local timeString = timeParser.formatTime(state.remaining)
        local batteryIcon = batteryDisplay.drawBattery(state.percentage, timeString)
        
        self.menubar:setIcon(batteryIcon, false)
    end
end

--- Start a timer with given duration (in minutes)
--- @param minutes number Duration in minutes
function obj:startTimer(minutes)
    self.timerManager:start(minutes, function(state)
        self:updateDisplay(state)
    end)
    
    hs.alert.show(string.format("⚡ Battery timer started: %d minutes", minutes), 2)
end

--- Stop the timer
function obj:stopTimer()
    self.timerManager:stop()
    
    if self.menubar then
        local batteryIcon = batteryDisplay.drawBattery(0, "0:00")
        self.menubar:setIcon(batteryIcon, false)
        
        -- Remove menu bar after a short delay
        hs.timer.doAfter(2, function()
            if self.menubar then
                self.menubar:delete()
                self.menubar = nil
            end
        end)
    end
end

--- Show menu to select time duration
function obj:showTimerMenu()
    if self.timerManager:isRunning() then
        -- Timer is running, show stop option
        local menu = {
            {
                title = "Stop Timer",
                fn = function()
                    self:stopTimer()
                    hs.alert.show("⚡ Battery timer stopped", 1.5)
                end
            }
        }
        self.menubar:setMenu(menu)
        self.menubar:popupMenu(hs.mouse.absolutePosition())
    else
        -- No timer running, show custom input dialog with auto-focus
        inputDialog.show(function(text)
            if text and text ~= "" then
                local mins = timeParser.parseTimeInput(text)
                if mins and mins > 0 then
                    self:startTimer(mins)
                else
                    hs.alert.show("⚠️ Invalid format. Try: 90min, 2hr, or 45s", 3)
                end
            end
        end)
    end
end

--- Toggle the battery timer on/off
function obj:toggle()
    if self.menubar then
        -- If timer is running, stop it
        if self.timerManager:isRunning() then
            self:stopTimer()
        else
            -- Just hide the menu bar
            self.menubar:delete()
            self.menubar = nil
        end
        hs.alert.show("⚡ Battery timer hidden", 1)
    else
        -- Show the menu bar - combined image with timer on LEFT, battery on RIGHT
        self.menubar = hs.menubar.new()
        local batteryIcon = batteryDisplay.drawBattery(100, "--:--")
        self.menubar:setIcon(batteryIcon, false)
        self.menubar:setClickCallback(function()
            self:showTimerMenu()
        end)
        hs.alert.show("⚡ Battery timer ready - click to set time", 2)
    end
end

--- Start the spoon
function obj:start()
    -- Bind hotkey (Ctrl+Alt+B)
    self.hotkey = hs.hotkey.bind(self.hotkeyMods, self.hotkeyKey, function()
        self:toggle()
    end)
    
    return self
end

--- Stop the spoon
function obj:stop()
    if self.hotkey then
        self.hotkey:delete()
        self.hotkey = nil
    end
    
    if self.timerManager then
        self.timerManager:stop()
    end
    
    if self.menubar then
        self.menubar:delete()
        self.menubar = nil
    end
    
    return self
end

return obj
