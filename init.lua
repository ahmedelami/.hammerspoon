-- ============== HAMMERSPOON CONFIGURATION ==============

-- Enable IPC for command-line control (allows `hs -c "hs.reload()"`)
hs.ipc.cliInstall()

-- ============== LOAD SPOONS ==============

-- Mouse drag with Alt+`
hs.loadSpoon("MouseDrag")
spoon.MouseDrag:start()

-- Time tracker with Cmd+Esc
hs.loadSpoon("TimeTracker")

-- Load Notion credentials from .env file
local envLoader = require("env_loader")
local env = envLoader.load(hs.configdir .. "/.env")
if env.NOTION_API_TOKEN and env.NOTION_DATABASE_ID then
    spoon.TimeTracker.notionApiToken = env.NOTION_API_TOKEN
    spoon.TimeTracker.notionDatabaseId = env.NOTION_DATABASE_ID
end

spoon.TimeTracker:start()

hs.loadSpoon("idle_alarm")
spoon.idle_alarm:start()

-- Battery Timer with Ctrl+Alt+B
spoon.BatteryTimer = dofile(hs.configdir .. "/Spoons/BatteryTimer.spoon/init.lua")
spoon.BatteryTimer:start()

-- ============== DONE ==============

hs.alert.show("🔄 Hammerspoon Config Loaded", 2)
