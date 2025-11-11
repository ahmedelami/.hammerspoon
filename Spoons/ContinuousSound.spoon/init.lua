-- ContinuousSound.spoon
local obj = {}
obj.__index = obj

obj.name = "ContinuousSound"
obj.version = "0.1"
obj.author = "you"
obj.license = "MIT"

-- Defaults
obj.soundName = "Submarine"
obj.soundFile = nil
obj.delaySeconds = 2  -- Delay between plays

obj._sound = nil
obj._hotkey = nil
obj._timer = nil
obj._lastPlayTime = 0
obj._borderCanvas = nil -- Single canvas overlay for glow
obj._isPulsing = false  -- Track if currently pulsing
obj._pulseTimers = {}  -- Track all pulse animation timers
obj.borderWidth = 36   -- Thickness of the glow band (outer stroke)
obj.cornerRadius = 28  -- Corner radius before glow stroke is applied
obj._borderCanvasMeta = nil

local function moment()
  if hs.timer and hs.timer.secondsSinceEpoch then
    return hs.timer.secondsSinceEpoch()
  end
  return os.time()
end

local function loadSound(self)
  if self._sound then return end
  if self.soundFile then
    self._sound = hs.sound.getByFile(self.soundFile)
  elseif self.soundName then
    self._sound = hs.sound.getByName(self.soundName)
  end
  if not self._sound then self._sound = hs.sound.getByName("Glass") end
end

local function cancelPulseTimers(self)
  for _, timer in ipairs(self._pulseTimers) do
    if timer:running() then
      timer:stop()
    end
  end
  self._pulseTimers = {}
  self._isPulsing = false
end

local function ensureBorderCanvas(self)
  local screen = hs.screen.mainScreen()
  if not screen then return end

  local frame = screen:frame()
  local borderWidth = self.borderWidth or 36
  local inset = (borderWidth / 2)

  local canvasFrame = {
    x = frame.x,
    y = frame.y,
    w = frame.w,
    h = frame.h
  }

  local corner = (self.cornerRadius or 28)

  local meta = self._borderCanvasMeta
  if self._borderCanvas and meta then
    local sameCanvas = meta.canvasFrame.x == canvasFrame.x
      and meta.canvasFrame.y == canvasFrame.y
      and meta.canvasFrame.w == canvasFrame.w
      and meta.canvasFrame.h == canvasFrame.h
    local sameBorder = meta.borderWidth == borderWidth
    local sameCorner = meta.corner == corner

    if sameCanvas and sameBorder and sameCorner then
      return
    end

    self._borderCanvas:hide()
    self._borderCanvas:delete()
    self._borderCanvas = nil
    self._borderCanvasMeta = nil
  end

  local canvas = hs.canvas.new(canvasFrame)
  canvas:level(hs.canvas.windowLevels.overlay)
  canvas:behavior(hs.canvas.windowBehaviors.canJoinAllSpaces)
  canvas:clickActivating(false)

  canvas[1] = {
    type = "rectangle",
    action = "fill",
    frame = {x = 0, y = 0, w = canvasFrame.w, h = canvasFrame.h},
    fillColor = {alpha = 0}
  }

  local baseStroke = {
    type = "rectangle",
    action = "stroke",
    frame = {
      x = inset,
      y = inset,
      w = math.max(0, canvasFrame.w - borderWidth),
      h = math.max(0, canvasFrame.h - borderWidth)
    },
    roundedRectRadii = {xRadius = corner, yRadius = corner},
    compositeRule = "plusLighter",
    strokeCapStyle = "round",
    strokeJoinStyle = "round",
    strokeColor = {red = 1, green = 0, blue = 0, alpha = 0}
  }

  canvas[2] = hs.fnutils.copy(baseStroke)
  canvas[2].strokeWidth = borderWidth
  canvas[2].withShadow = true
  canvas[2].shadow = {
    blurRadius = borderWidth * 1.6,
    color = {red = 1, green = 0, blue = 0, alpha = 0},
    offset = {x = 0, y = 0}
  }

  canvas[3] = hs.fnutils.copy(baseStroke)
  canvas[3].strokeWidth = borderWidth * 0.55

  canvas[4] = hs.fnutils.copy(baseStroke)
  canvas[4].strokeWidth = borderWidth * 0.25

  canvas:hide()
  self._borderCanvas = canvas
  self._borderCanvasMeta = {
    canvasFrame = hs.fnutils.copy(canvasFrame),
    borderWidth = borderWidth,
    corner = corner
  }
end

local function setGlow(self, innerAlpha, outerAlpha, shadowAlpha)
  if not self._borderCanvas then return end

  local borderWidth = self.borderWidth or 36

  self._borderCanvas[2].strokeColor = {red = 1, green = 0, blue = 0, alpha = outerAlpha}
  self._borderCanvas[2].shadow = {
    blurRadius = borderWidth * 1.6,
    color = {red = 1, green = 0, blue = 0, alpha = shadowAlpha},
    offset = {x = 0, y = 0}
  }

  if self._borderCanvas[3] then
    self._borderCanvas[3].strokeColor = {red = 1, green = 0, blue = 0, alpha = innerAlpha * 0.6}
  end

  if self._borderCanvas[4] then
    self._borderCanvas[4].strokeColor = {red = 1, green = 0, blue = 0, alpha = innerAlpha}
  end
end

local function pulseBorders(self)
  ensureBorderCanvas(self)
  if not self._borderCanvas then return end
  if self._isPulsing then return end

  cancelPulseTimers(self)
  self._isPulsing = true
  self._borderCanvas:show()
  setGlow(self, 0, 0, 0)

  local steps = 20
  local stepDuration = 0.02
  local holdTime = 0.05
  local maxInner = 0.9
  local maxOuter = 0.45
  local maxShadow = 0.35

  for i = 1, steps do
    local timer = hs.timer.doAfter(i * stepDuration, function()
      local progress = i / steps
      setGlow(self, maxInner * progress, maxOuter * progress, maxShadow * progress)
    end)
    table.insert(self._pulseTimers, timer)
  end

  for i = 1, steps do
    local timer = hs.timer.doAfter((steps * stepDuration) + holdTime + (i * stepDuration), function()
      local reverse = 1 - (i / steps)
      setGlow(self, maxInner * reverse, maxOuter * reverse, maxShadow * reverse)
      if i == steps then
        self._borderCanvas:hide()
        self._isPulsing = false
      end
    end)
    table.insert(self._pulseTimers, timer)
  end
end

function obj:isRunning()
  return self._timer ~= nil and self._timer:running()
end

function obj:toggle()
  if self:isRunning() then
    self:stop(); hs.alert.show("Continuous sound OFF")
  else
    self:start(); hs.alert.show("Continuous sound ON")
  end
end

function obj:start()
  loadSound(self)
  ensureBorderCanvas(self)
  
  if self._timer then self._timer:stop(); self._timer = nil end

  local delay = self.delaySeconds or 2

  local function trigger()
    ensureBorderCanvas(self)
    if not self._borderCanvas then return end
    cancelPulseTimers(self)
    if self._sound:isPlaying() then
      self._sound:stop()
    end
    if self._sound.currentTime then
      self._sound:currentTime(0)
    end
    self._sound:play()
    self._lastPlayTime = moment()
    pulseBorders(self)
  end

  trigger()

  self._timer = hs.timer.new(delay, function()
    trigger()
  end)
  self._timer:start()

  -- Bind hotkey once
  if not self._hotkey then
    self._hotkey = hs.hotkey.bind({"ctrl", "shift"}, "S", function() 
      self:toggle() 
    end)
  end

  return self
end

function obj:stop()
  if self._timer then self._timer:stop(); self._timer = nil end
  if self._sound and self._sound:isPlaying() then self._sound:stop() end
  
  -- Cancel any running pulse timers
  cancelPulseTimers(self)
  self._isPulsing = false
  
  -- Clean up border canvas
  if self._borderCanvas then
    self._borderCanvas:hide()
    self._borderCanvas:delete()
    self._borderCanvas = nil
    self._borderCanvasMeta = nil
  end
  
  return self
end

return obj







