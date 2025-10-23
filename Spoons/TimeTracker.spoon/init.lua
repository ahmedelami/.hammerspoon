--- === TimeTracker ===
---
--- Time tracking system with hierarchical groups and CSV logging
---
--- Download: N/A
--- Author: Ahmed Elamin
--- License: MIT

local obj = {}
obj.__index = obj

-- Load modules
local spoonPath = hs.spoons.scriptPath()
package.path = package.path .. ";" .. spoonPath .. "/?.lua"
local csvManager = require("csv_manager")
local groupsManager = require("groups_manager")
local uiChooser = require("ui_chooser")

-- Metadata
obj.name = "TimeTracker"
obj.version = "1.0"
obj.author = "Ahmed Elamin"
obj.license = "MIT"

-- State variables
obj.csvPath = nil
obj.groupsPath = nil
obj.currentTask = nil
obj.startTime = nil
obj.groups = {}
obj.chooser = nil
obj.menubar = nil
obj.timerObj = nil
obj.currentTabHotkey = nil
obj.currentShiftTabHotkey = nil
obj.currentDeleteHotkey = nil
obj.currentMarkHotkey = nil
obj.markedForDeletion = {}

-- Configurable options
obj.hotkey = {{"cmd"}, "escape"}
obj.dashboardHotkey = {{"cmd", "shift"}, "escape"}
obj.dashboardTemplatePath = hs.spoons.scriptPath() .. "/dashboard/index.html"

-- ============== UTILITIES ==============

function obj:formatDuration(seconds)
    if seconds < 60 then
        return string.format("%d seconds", seconds)
    elseif seconds < 3600 then
        local minutes = math.floor(seconds / 60)
        local secs = seconds % 60
        return secs > 0 and string.format("%d min %d sec", minutes, secs) or string.format("%d minutes", minutes)
    elseif seconds < 86400 then
        local hours = math.floor(seconds / 3600)
        local minutes = math.floor((seconds % 3600) / 60)
        return minutes > 0 and string.format("%d hr %d min", hours, minutes) or string.format("%d hours", hours)
    else
        local days = math.floor(seconds / 86400)
        local hours = math.floor((seconds % 86400) / 3600)
        return hours > 0 and string.format("%d days %d hr", days, hours) or string.format("%d days", days)
    end
end

function obj:notify(title, message)
    hs.notify.new({title=title, informativeText=message}):send()
end

-- ============== MENUBAR ==============

function obj:updateMenubar()
    if not self.currentTask or not self.startTime then
        if self.menubar then
            self.menubar:delete()
            self.menubar = nil
        end
        if self.timerObj then
            self.timerObj:stop()
            self.timerObj = nil
        end
        return
    end
    
    local elapsed = os.time() - self.startTime
    local hours = math.floor(elapsed / 3600)
    local minutes = math.floor((elapsed % 3600) / 60)
    local seconds = elapsed % 60
    local timeStr = string.format("%02d:%02d:%02d", hours, minutes, seconds)
    
    -- Get only the tail end of the path
    local taskName = self.currentTask.path:match("::([^:]+)$") or self.currentTask.path
    if #taskName > 20 then
        taskName = taskName:sub(1, 17) .. "..."
    end
    
    local displayText = "⏱ " .. taskName .. " " .. timeStr
    
    if not self.menubar then
        self.menubar = hs.menubar.new()
    end
    
    self.menubar:setTitle(displayText)
    self.menubar:setTooltip("Click to stop task\n" .. self.currentTask.path)
    self.menubar:setClickCallback(function() self:stopTask() end)
end

function obj:startMenubarTimer()
    if self.timerObj then
        self.timerObj:stop()
    end
    
    self.timerObj = hs.timer.new(1, function() self:updateMenubar() end)
    self.timerObj:start()
    self:updateMenubar()
end

-- ============== TASK MANAGEMENT ==============

function obj:stopTask()
    if not self.currentTask or not self.startTime then
        hs.alert.show("⚠️ No task running")
        return
    end

    local endTime = os.time()
    local durationSeconds = endTime - self.startTime

    csvManager.logToCSV(self.csvPath, self.startTime, endTime, self.currentTask.path, self.currentTask.description)

    local durationText = self:formatDuration(durationSeconds)
    hs.alert.show("⏹ Task Stopped\n" .. self.currentTask.path .. "\n⏱ " .. durationText, 3)
    self:notify("Task Stopped ⏹", string.format("%s\n⏱ %s", self.currentTask.path, durationText))

    self.currentTask = nil
    self.startTime = nil
    self:updateMenubar()
end

function obj:startTask(path, description)
    self.currentTask = {path = path, description = description}
    self.startTime = os.time()

    local taskName = description and description ~= "" and (path .. "\n" .. description) or path
    hs.alert.show("▶️ Task Started\n" .. taskName, 2)
    self:notify("Task Started ▶️", taskName)
    self:startMenubarTimer()
end

-- ============== CHOOSER UI ==============

function obj:cleanupChooserHotkeys()
    if self.currentTabHotkey then self.currentTabHotkey:delete(); self.currentTabHotkey = nil end
    if self.currentShiftTabHotkey then self.currentShiftTabHotkey:delete(); self.currentShiftTabHotkey = nil end
    if self.currentDeleteHotkey then self.currentDeleteHotkey:delete(); self.currentDeleteHotkey = nil end
    if self.currentMarkHotkey then self.currentMarkHotkey:delete(); self.currentMarkHotkey = nil end
end

function obj:showChooser()
    local allChoices = uiChooser.getAllChoices(self.groups, self.markedForDeletion)
    
    if not self.chooser then
        self.chooser = hs.chooser.new(function(choice)
            self:cleanupChooserHotkeys()
            if choice then
                self:showDescriptionDialog(choice.path)
            end
        end)
    end

    self.chooser:placeholderText("Type to filter... Tab: autocomplete | Space: mark | Cmd+Shift+Del: delete")
    self.chooser:searchSubText(true)
    self.chooser:choices(allChoices)
    
    self.chooser:queryChangedCallback(function(query)
        local filtered = (not query or query == "") and allChoices or uiChooser.filterChoices(allChoices, query)
        
        if #filtered == 0 and query and query ~= "" then
            filtered = {{text = "✨ Create: " .. query, subText = "Press Enter to create", path = query, fullPath = query}}
        end
        
        self.chooser:choices(filtered)
    end)
    
    self.chooser:show()
    self:setupChooserHotkeys(allChoices)
end

function obj:setupChooserHotkeys(allChoices)
    -- Tab: autocomplete
    self.currentTabHotkey = hs.hotkey.bind({}, "tab", function()
        local query = self.chooser:query() or ""
        local filtered = uiChooser.filterChoices(allChoices, query)
        
        if #filtered == 0 then return end
        if #filtered == 1 then
            self.chooser:query(filtered[1].path)
            return
        end
        
        -- Find common prefix
        local commonPrefix = filtered[1].path
        for _, choice in ipairs(filtered) do
            local i = 1
            while i <= #commonPrefix and i <= #choice.path and commonPrefix:sub(i, i) == choice.path:sub(i, i) do
                i = i + 1
            end
            commonPrefix = commonPrefix:sub(1, i - 1)
        end
        
        if #commonPrefix > #query then
            local nextBoundary = commonPrefix:find("::", #query + 1)
            self.chooser:query(nextBoundary and commonPrefix:sub(1, nextBoundary + 1) or commonPrefix)
        else
            self.chooser:query(filtered[1].path)
        end
    end)
    
    -- Shift+Tab: full autocomplete
    self.currentShiftTabHotkey = hs.hotkey.bind({"shift"}, "tab", function()
        local filtered = uiChooser.filterChoices(allChoices, self.chooser:query() or "")
        if #filtered > 0 then
            self.chooser:query(filtered[1].path)
        end
    end)
    
    -- Space: mark/unmark
    self.currentMarkHotkey = hs.hotkey.bind({}, "space", function()
        local query = self.chooser:query() or ""
        if query ~= "" then return false end
        
        local filtered = uiChooser.filterChoices(allChoices, query)
        if #filtered == 0 then return end
        
        local selectedRow = self.chooser:selectedRow() or 1
        if selectedRow < 1 then selectedRow = 1 end
        
        local item = filtered[selectedRow]
        if not item or item.path:find("^✨") then return end
        
        self.markedForDeletion[item.path] = not self.markedForDeletion[item.path]
        
        allChoices = uiChooser.getAllChoices(self.groups, self.markedForDeletion)
        self.chooser:choices(uiChooser.filterChoices(allChoices, query))
        self.chooser:selectedRow(selectedRow)
        
        return true
    end)
    
    -- Cmd+Shift+Delete: delete marked/current
    self.currentDeleteHotkey = hs.hotkey.bind({"cmd", "shift"}, "delete", function()
        local markedPaths = {}
        for path, isMarked in pairs(self.markedForDeletion) do
            if isMarked then table.insert(markedPaths, path) end
        end
        
        if #markedPaths == 0 then
            local filtered = uiChooser.filterChoices(allChoices, self.chooser:query() or "")
            if #filtered > 0 and not filtered[1].path:find("^✨") then
                table.insert(markedPaths, filtered[1].path)
            end
        end
        
        if #markedPaths == 0 then return end
        
        self.chooser:hide()
        
        local deleteMessage = "Delete " .. #markedPaths .. " group(s):\n\n"
        for i, path in ipairs(markedPaths) do
            deleteMessage = deleteMessage .. "• " .. path .. "\n"
            if i >= 5 then
                deleteMessage = deleteMessage .. "• ... and " .. (#markedPaths - 5) .. " more\n"
                break
            end
        end
        deleteMessage = deleteMessage .. "\nThis will remove groups, subgroups, and all time entries."
        
        if hs.dialog.blockAlert("Delete Groups?", deleteMessage, "Delete", "Cancel") == "Delete" then
            local totalDeleted = 0
            for _, path in ipairs(markedPaths) do
                local newGroups, groupsDeleted = groupsManager.deleteGroup(self.groupsPath, self.csvPath, self.groups, path)
                self.groups = newGroups
                totalDeleted = totalDeleted + groupsDeleted
            end
            
            hs.alert.show("🗑️ Deleted " .. totalDeleted .. " group(s)", 2)
            self.markedForDeletion = {}
            self.groups = groupsManager.loadGroups(self.groupsPath)
            
            if #self.groups > 0 then
                self:showChooser()
            else
                self:cleanupChooserHotkeys()
                hs.alert.show("No groups remaining")
            end
        else
            self:showChooser()
        end
    end)
end

function obj:showDescriptionDialog(path)
    self:cleanupChooserHotkeys()
    
    local button, description = hs.dialog.textPrompt(
        "Task Description (Optional)",
        "Path: " .. path .. "\n\nAdd details:",
        "",
        "Start", "Cancel"
    )

    if button == "Start" then
        self.groups = groupsManager.saveGroup(self.groupsPath, self.groups, path)
        self:startTask(path, description or "")
    end
end

function obj:showDialog()
    if self.currentTask then
        self:stopTask()
    else
        self:cleanupChooserHotkeys()
        self:showChooser()
    end
end

-- ============== DASHBOARD ==============

function obj:openDashboard()
    -- Read the CSV file
    local csvFile = io.open(self.csvPath, "r")
    if not csvFile then
        hs.alert.show("⚠️ No time tracking data found")
        return
    end
    
    local csvData = csvFile:read("*all")
    csvFile:close()
    
    -- Escape the CSV data for JavaScript (only backticks and backslashes)
    csvData = csvData:gsub("\\", "\\\\"):gsub("`", "\\`")
    
    -- Read the template HTML
    local templateFile = io.open(self.dashboardTemplatePath, "r")
    if not templateFile then
        hs.alert.show("⚠️ Dashboard template not found")
        return
    end
    
    local htmlContent = templateFile:read("*all")
    templateFile:close()
    
    -- Inject CSV data and override loadData function
    local injectedScript = [[<script>
        // Embedded CSV data - injected by Hammerspoon
        const EMBEDDED_CSV_DATA = `]] .. csvData .. [[`;
        
        // Prevent the original loadData from running
        window.loadData = async function() { /* Overridden by Hammerspoon */ };
        
        // Load embedded data immediately
        window.addEventListener('DOMContentLoaded', async function() {
            try {
                const text = EMBEDDED_CSV_DATA;
                const lines = text.split('\n').filter(line => line.trim());
                const dataLines = lines.slice(1);
                
                allData = dataLines.map(line => {
                    const parts = parseCSVLine(line);
                    if (parts.length === 5) {
                        return {
                            startTime: parts[0],
                            endTime: parts[1],
                            duration: parseInt(parts[2]) || 0,
                            path: parts[3],
                            description: parts[4] || ''
                        };
                    } else if (parts.length === 6) {
                        const path = parts[3] + (parts[4] ? '::' + parts[4] : '');
                        return {
                            startTime: parts[0],
                            endTime: parts[1],
                            duration: parseInt(parts[2]) || 0,
                            path: path,
                            description: parts[5] || ''
                        };
                    }
                    return null;
                }).filter(d => d !== null);

                filteredData = [...allData];
                updateDashboard();
                populateGroupFilter();
            } catch (error) {
                showError('Failed to load embedded data: ' + error.message);
                console.error('Error loading embedded data:', error);
            }
        });
    </script>]]
    
    -- Insert the embedded data and script right before </body> tag
    htmlContent = htmlContent:gsub("(</body>)", injectedScript .. "\n%1")
    
    -- Write to temp file (simpler and more reliable than data: URL)
    local tempPath = os.tmpname() .. ".html"
    local tempFile = io.open(tempPath, "w")
    if not tempFile then
        hs.alert.show("⚠️ Could not create dashboard")
        return
    end
    
    tempFile:write(htmlContent)
    tempFile:close()
    
    -- Open in browser
    hs.execute("open '" .. tempPath .. "'")
    hs.alert.show("📊 Opening dashboard...")
end

-- ============== INITIALIZATION ==============

function obj:init()
    self.csvPath = os.getenv("HOME") .. "/time_tracking.csv"
    self.groupsPath = os.getenv("HOME") .. "/time_tracking_groups.csv"
    return self
end

function obj:start()
    groupsManager.initGroupsCSV(self.groupsPath)
    self.groups = groupsManager.loadGroups(self.groupsPath)
    csvManager.initCSV(self.csvPath)

    hs.hotkey.bind(self.hotkey[1], self.hotkey[2], function() self:showDialog() end)
    hs.hotkey.bind(self.dashboardHotkey[1], self.dashboardHotkey[2], function() self:openDashboard() end)

    hs.alert.show("⏱ Time Tracker Ready\nCmd+Esc: Start/Stop | Cmd+Shift+Esc: Dashboard", 3)
    self:notify("Time Tracker Ready", "Cmd+Esc: Start/Stop\nCmd+Shift+Esc: Dashboard")
    
    return self
end

function obj:stop()
    if self.currentTask then self:stopTask() end
    if self.menubar then self.menubar:delete(); self.menubar = nil end
    if self.timerObj then self.timerObj:stop(); self.timerObj = nil end
    self:cleanupChooserHotkeys()
    return self
end

return obj

