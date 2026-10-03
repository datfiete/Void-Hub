# WorldRadar (point-only)

A normal Section/Tab element that draws a top-down relative point field (no island/map image).

```lua
local tab = window:CreateTab("World")
local section = tab:CreateSection("Radar")
section:CreateWorldRadar({
    FolderName = "Chests", -- scans Workspace.Chests by default
    Range = 250,
    DefaultActive = true,
    -- Optional AutoFly (flies local character toward targets):
    -- AutoFly = true,
    -- AutoFlyMode = "Nearest", -- or "SkipVisited", "WaitUntilGone"
    -- FlySpeed = 50,
})
```

Alternatively pass `Targets = function() return workspace.Chests:GetChildren() end` or a table/Folder. Each target should be a BasePart or contain a BasePart.

## AutoFly modes
- **Nearest** – always fly to the closest target (re-evaluates every frame)
- **SkipVisited** – on arrival mark target as visited; never go there again while it still exists
- **WaitUntilGone** – lock onto a target and stay until it is destroyed/removed, then pick next
