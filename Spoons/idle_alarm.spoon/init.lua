-- IdleAlarm.spoon
local obj = {}
obj.__index = obj

obj.name = "idle_alarm"
obj.version = "0.1"
obj.author = "you"
obj.license = "MIT"

-- Defaults
obj.idleSeconds = 120
obj.soundName   = "Submarine"
obj.soundFile   = nil

obj._timer  = nil
obj._sound  = nil
obj._hotkey = nil   -- <— NEW

local function loadSound(self)
  if self._sound then return end
  if self.soundFile then
    self._sound = hs.sound.getByFile(self.soundFile)
  elseif self.soundName then
    self._sound = hs.sound.getByName(self.soundName)
  end
  if not self._sound then self._sound = hs.sound.getByName("Glass") end
end

-- NEW: simple helpers
function obj:isRunning()
  return self._timer ~= nil and self._timer:running()
end

function obj:toggle()
  if self:isRunning() then
    self:stop(); hs.alert.show("Idle alarm OFF")
  else
    self:start(); hs.alert.show("Idle alarm ON")
  end
end

function obj:start()
  loadSound(self)
  if self._timer then self._timer:stop(); self._timer = nil end

  self._timer = hs.timer.doEvery(1, function()
    local idle = hs.host.idleTime()
    if idle >= self.idleSeconds then
      if not self._sound:isPlaying() then self._sound:play() end
    else
      if self._sound:isPlaying() then self._sound:stop() end
    end
  end)

  -- NEW: bind Ctrl+Shift+T once
  if not self._hotkey then
    self._hotkey = hs.hotkey.bind({"ctrl","shift"}, "T", function() self:toggle() end)
  end

  return self
end

function obj:stop()
  if self._timer then self._timer:stop(); self._timer = nil end
  if self._sound and self._sound:isPlaying() then self._sound:stop() end
  return self
end

return obj

