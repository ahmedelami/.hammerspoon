--- Timer Manager Module
--- Manages the countdown timer logic and state

local M = {}

--- Create a new timer manager instance
--- @return table Timer manager object
function M.new()
    local tm = {
        startTime = nil,
        duration = nil,  -- duration in seconds
        timer = nil,
        updateCallback = nil,
        flashState = false  -- tracks odd/even seconds for flashing
    }
    
    --- Start the timer
    --- @param minutes number Duration in minutes
    --- @param callback function Function to call on each update
    function tm:start(minutes, callback)
        -- Stop any existing timer
        if self.timer then
            self.timer:stop()
        end
        
        self.duration = minutes * 60
        self.startTime = os.time()
        self.updateCallback = callback
        
        -- Create update timer (update every second)
        self.timer = hs.timer.new(1, function()
            self:update()
        end)
        self.timer:start()
        
        -- Initial update
        self:update()
        
    end
    
    --- Update the timer state
    function tm:update()
        if not self.startTime or not self.duration then
            return
        end
        
        local elapsed = os.time() - self.startTime
        local remaining = self.duration - elapsed
        
        -- Keep flash state false (disable flashing)
        self.flashState = false
        
        if remaining <= 0 then
            -- Timer finished
            self:stop()
            if self.updateCallback then
                self.updateCallback({
                    finished = true,
                    remaining = 0,
                    percentage = 0,
                    flashState = false
                })
            end
            return
        end
        
        local percentage = (remaining / self.duration) * 100
        local state = {
            finished = false,
            remaining = remaining,
            percentage = percentage,
            flashState = self.flashState
        }
        if self.updateCallback then
            self.updateCallback(state)
        end
    end

    --- Stop the timer
    function tm:stop()
        if self.timer then
            self.timer:stop()
            self.timer = nil
        end
        self.startTime = nil
        self.duration = nil
    end
    
    --- Check if timer is running
    --- @return boolean True if timer is running
    function tm:isRunning()
        return self.startTime ~= nil and self.duration ~= nil
    end
    
    return tm
end

return M
