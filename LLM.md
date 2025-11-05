# AI Development Guide - Hammerspoon Configuration

## ⚠️ Critical: Worktree vs Production Setup

This repository uses **Git worktrees**, which creates a confusing dual-directory situation:

### Directory Structure
```
/Users/ahmedelamin/.cursor/worktrees/.hammerspoon/oPHxg/
  ↳ This is the GIT WORKTREE (version control only)
  ↳ Files here are NOT used by Hammerspoon
  ↳ This is where we edit and commit code

/Users/ahmedelamin/.hammerspoon/
  ↳ This is the ACTUAL Hammerspoon config directory
  ↳ Files here are ACTIVELY USED by Hammerspoon
  ↳ Changes here take effect immediately
```

## 🔄 Workflow for Making Changes

### When editing Spoons or init.lua:

1. **Edit files in the worktree** (this directory):
   ```
   /Users/ahmedelamin/.cursor/worktrees/.hammerspoon/oPHxg/
   ```

2. **Copy changes to the production directory**:
   ```bash
   # For Spoons
   cp Spoons/SpoonName.spoon/init.lua /Users/ahmedelamin/.hammerspoon/Spoons/SpoonName.spoon/init.lua
   
   # For main config
   cp init.lua /Users/ahmedelamin/.hammerspoon/init.lua
   ```

3. **Reload Hammerspoon**:
   ```bash
   hs -c "hs.reload()" 2>/dev/null
   ```

4. **If a spoon doesn't load automatically**, manually load it:
   ```bash
   hs -c "spoon.SpoonName = dofile(hs.configdir .. '/Spoons/SpoonName.spoon/init.lua'); spoon.SpoonName:start()"
   ```

## 📋 Current Spoons

### BatteryTimer
- **Location**: `/Users/ahmedelamin/.hammerspoon/Spoons/BatteryTimer.spoon/`
- **Hotkey**: Ctrl+Alt+B (⌃⌥B)
- **Description**: Visual battery timer for study/focus sessions
- **Loading**: Uses `dofile` instead of `hs.loadSpoon` due to loading issues
- **Manual load**: 
  ```bash
  hs -c "spoon.BatteryTimer = dofile(hs.configdir .. '/Spoons/BatteryTimer.spoon/init.lua'); spoon.BatteryTimer:start()"
  ```

### MouseDrag
- **Hotkey**: Alt+` (⌥`)
- **Description**: Drag mouse without clicking

### TimeTracker
- **Hotkey**: Cmd+Esc (⌘⎋) and Cmd+Shift+Esc (⌘⇧⎋)
- **Description**: Track time and sync to Notion

### idle_alarm
- **Hotkey**: Ctrl+Shift+T (⌃⇧T)
- **Description**: Alert when idle too long

## 🐛 Common Issues

### Spoon not loading after reload
**Symptom**: After editing a spoon and reloading Hammerspoon, the spoon doesn't work.

**Common Cause**: `init.lua` was NOT copied to production directory!

**Solution**:
1. **First, verify init.lua was copied**: `grep "SpoonName" /Users/ahmedelamin/.hammerspoon/init.lua`
2. If missing, copy it: `cp init.lua /Users/ahmedelamin/.hammerspoon/init.lua`
3. Verify spoon files were copied to `/Users/ahmedelamin/.hammerspoon/Spoons/`
4. Reload: `hs -c "hs.reload()"`
5. If still not working, manually load:
   ```bash
   hs -c "spoon.SpoonName = dofile(hs.configdir .. '/Spoons/SpoonName.spoon/init.lua'); spoon.SpoonName:start()"
   ```

### Changes not appearing even after copying files
**Symptom**: You copied new files and reloaded, but the behavior hasn't changed at all.

**Common Cause**: **Lua module caching!** When a spoon uses `require()` to load modules, Lua caches them in `package.loaded`. Even if you update the files, `require()` returns the cached version.

**Solution - Clear the module cache**:
```bash
hs -c "
-- Clear module cache for the spoon
package.loaded['module_name'] = nil

-- Then reload the spoon
if spoon.SpoonName then spoon.SpoonName:stop() end
spoon.SpoonName = dofile(hs.configdir .. '/Spoons/SpoonName.spoon/init.lua')
spoon.SpoonName:init()
spoon.SpoonName:start()
"
```

**Example for BatteryTimer**:
```bash
hs -c "
package.loaded['battery_display'] = nil
package.loaded['timer_manager'] = nil
package.loaded['time_parser'] = nil

if spoon.BatteryTimer then spoon.BatteryTimer:stop() end
spoon.BatteryTimer = dofile(hs.configdir .. '/Spoons/BatteryTimer.spoon/init.lua')
spoon.BatteryTimer:init()
spoon.BatteryTimer:start()
"
```

**Pro tip**: If you're not sure which modules to clear, just do a full `hs.reload()` from Hammerspoon GUI - it clears all caches.

### Changes not taking effect
**Symptom**: You edit a file but nothing changes.

**Cause**: You edited the worktree copy but didn't copy to production.

**Solution**: Always copy **ALL** changed files from worktree to `/Users/ahmedelamin/.hammerspoon/`
- If you changed a Spoon → copy the Spoon
- If you changed init.lua → copy init.lua  
- If you changed BOTH → copy BOTH (don't forget!)

## 🤖 Instructions for AI Assistants

When asked to edit Hammerspoon configuration:

1. **Always edit files in THIS directory** (the worktree)
2. **Always copy changes to** `/Users/ahmedelamin/.hammerspoon/`
   - ⚠️ **CRITICAL**: If you modify `init.lua`, you MUST copy it to production!
   - ⚠️ **CRITICAL**: If you modify any Spoon files, you MUST copy them to production!
   - **Don't forget BOTH**: Spoon files AND init.lua if both changed
3. **Always reload** after making changes
4. **If spoon doesn't load**, use manual `dofile` method
5. **Remember**: The worktree is for git, the home directory is for execution
6. **Verify your work**: After copying, confirm the spoon loads with `hs -c "if spoon.SpoonName then print('Success') end"`

### Quick Command Reference
```bash
# Copy all changes and reload
cp init.lua /Users/ahmedelamin/.hammerspoon/init.lua
cp -r Spoons/* /Users/ahmedelamin/.hammerspoon/Spoons/
hs -c "hs.reload()" 2>/dev/null

# Manual load a specific spoon
hs -c "spoon.SpoonName = dofile(hs.configdir .. '/Spoons/SpoonName.spoon/init.lua'); spoon.SpoonName:start()"
```

## 📝 Best Practices

1. **Always keep both directories in sync**
2. **Test changes in production before committing**
3. **Document new hotkeys to avoid conflicts**
4. **Use unique hotkey combinations**: Ctrl+Alt+Letter is usually safe
5. **Check Hammerspoon console for errors**: Click menubar icon → Console

## 🔑 Reserved Hotkeys

- ⌥` - MouseDrag
- ⌘⎋ - TimeTracker start
- ⌘⇧⎋ - TimeTracker stop
- ⌃⇧T - idle_alarm toggle
- ⌃⌥B - BatteryTimer toggle

Avoid using these combinations for new spoons.

