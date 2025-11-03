# TimeTracker Spoon

Simple time tracking with optional Notion sync.

## Hotkeys

- `Cmd+Esc` - Start/Stop task
- `Cmd+Shift+Esc` - Open dashboard

## Usage

**Create new group:**
- `Cmd+Esc` → type new name → Enter (creates group only)

**Start task (existing group):**
- `Cmd+Esc` → type group → Enter (starts immediately)
- With note: `Cmd+Esc` → type `group | note here` → Enter
- Tab to autocomplete existing groups

**Stop task:**
- `Cmd+Esc` (or click menubar timer) → add end note → Stop

## Deleting Tasks

**Single task:**
- `Cmd+Esc` → filter to task → `Cmd+Shift+Delete`

**Multiple tasks:**
- `Cmd+Esc` → press `Shift+Space` to mark each task → `Cmd+Shift+Delete`

⚠️ Deletes all time entries for that task.

## Files

- `~/time_tracking.csv` - Your time data
- `~/time_tracking_groups.csv` - Task list

## Notion Sync (Optional)

**Setup:**

1. Create integration at https://www.notion.so/my-integrations → copy token
2. Create database with properties: Name (Title), Start Time (Date), End Time (Date), Duration (Number), Start Note (Text), End Note (Text)
3. Share database with integration
4. Get database ID from URL: `notion.so/workspace/DATABASE_ID?v=...`
5. Add to `~/.hammerspoon/init.lua`:

```lua
spoon.TimeTracker.notionApiToken = "secret_YOUR_TOKEN"
spoon.TimeTracker.notionDatabaseId = "YOUR_DATABASE_ID"
```

6. Reload Hammerspoon

Done.
