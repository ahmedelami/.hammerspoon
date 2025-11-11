--- === MenuBarText ===
---
--- Display custom text in the menu bar
--- Shows user-entered text in ALL CAPS with a character limit
---
--- Download: N/A
--- License: MIT

local obj = {}
obj.__index = obj

-- No need for custom input dialog - using native dialog for copy/paste support

-- Metadata
obj.name = "MenuBarText"
obj.version = "1.0"
obj.author = "Custom"
obj.license = "MIT"

-- State
obj.hotkey = nil
obj.menubar = nil
obj.currentText = nil

-- Configuration
obj.hotkeyMods = {"ctrl", "alt"}
obj.hotkeyKey = "j"
obj.maxLength = 30  -- Character limit

--- Initialize the spoon
function obj:init()
    return self
end

--- Show input dialog to enter text
function obj:showInputDialog()
    -- Use native dialog for guaranteed copy/paste support (including Arabic)
    local button, text = hs.dialog.textPrompt(
        "Menu Bar Text",
        "Enter text to display (max " .. self.maxLength .. " characters):",
        self.currentText or "",
        "OK",
        "Cancel"
    )
    
    if button == "OK" and text and text ~= "" then
        -- Trim to max length and convert to uppercase
        local trimmedText = text:sub(1, self.maxLength):upper()
        self:setText(trimmedText)
        hs.alert.show("📝 Menu bar text updated", 1.5)
    elseif button == "Cancel" then
        -- User cancelled - clear the menu bar if it exists
        if self.menubar then
            self.menubar:delete()
            self.menubar = nil
            self.currentText = nil
            hs.alert.show("📝 Menu bar text cleared", 1.5)
        end
    end
end

--- Set the text to display
function obj:setText(text)
    self.currentText = text
    
    -- Create or update menu bar
    if not self.menubar then
        self.menubar = hs.menubar.new()
        self.menubar:setClickCallback(function()
            self:showMenu()
        end)
    end
    
    -- Create styled text with bold font and spacing (no left space, normal right space)
    local styledText = hs.styledtext.new(text .. "", {
        font = {name = ".AppleSystemUIFontBold", size = 36},  -- Maximum size to fill menu bar
        paragraphStyle = {
            alignment = "left",
            lineSpacing = 0,
            paragraphSpacing = 0,
            paragraphSpacingBefore = 0,
            minimumLineHeight = 0,
            maximumLineHeight = 36
        },
        baselineOffset = -8,  -- Push text down to remove bottom space (negative = down)
        color = {white = 0.0, alpha = 1.0}
    })
    
    self.menubar:setTitle(styledText)
end

--- Show menu when clicking the menu bar item
function obj:showMenu()
    local menu = {
        {
            title = "Edit Text",
            fn = function()
                self:showInputDialog()
            end
        },
        {
            title = "Clear",
            fn = function()
                if self.menubar then
                    self.menubar:delete()
                    self.menubar = nil
                    self.currentText = nil
                    hs.alert.show("📝 Menu bar text cleared", 1.5)
                end
            end
        }
    }
    self.menubar:setMenu(menu)
end

--- Toggle the menu bar text display
function obj:toggle()
    self:showInputDialog()
end

--- Start the spoon
function obj:start()
    -- Bind hotkey (Ctrl+Alt+J)
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
    
    if self.menubar then
        self.menubar:delete()
        self.menubar = nil
    end
    
    self.currentText = nil
    
    return self
end

return obj

