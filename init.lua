-- ============== HAMMERSPOON CONFIGURATION ==============

-- Enable IPC for command-line control (allows `hs -c "hs.reload()"`)
hs.ipc.cliInstall()

-- ============== LOAD SPOONS ==============

-- Mouse drag with Alt+`
hs.loadSpoon("MouseDrag")
spoon.MouseDrag:start()

-- Time tracker with Cmd+Esc
hs.loadSpoon("TimeTracker")
spoon.TimeTracker:start()

-- ============== DONE ==============

hs.alert.show("🔄 Hammerspoon Config Loaded", 2)
