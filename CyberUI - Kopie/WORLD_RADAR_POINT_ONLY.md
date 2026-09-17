# WorldRadar (point-only)

A normal Section/Tab element; it draws a top-down relative point field (no island/map image). It is visual-only and does not control character movement or trigger prompts.

```lua
local tab = window:CreateTab("World")
local section = tab:CreateSection("Radar")
section:CreateWorldRadar({
    FolderName = "Chests", -- scans Workspace.Chests by default
    Range = 250,
    DefaultActive = true,
})
```

Alternatively pass `Targets = function() return workspace.Chests:GetChildren() end` or a table/Folder. Each target should be a BasePart or contain a BasePart.
