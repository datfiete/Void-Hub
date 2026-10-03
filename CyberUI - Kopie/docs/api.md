# Vaxorin / CyberUI Public API (summary)

See `DEVELOPER_MANUAL.md` and `developer-guide.md` for the complete reference.

## Loader

```lua
local Vaxorin = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/datfiete/Void-Hub/refs/heads/main/CyberUI%20-%20Kopie/load.lua"
))()
```

## Window

```lua
local window = Vaxorin:CreateWindow({
    Name = "My Script",
    LoadingTitle = "Loading...",
    LoadingSubtitle = "by Author",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "MyScript",
        FileName = "config",
    },
    Layout = "Vaxorin", -- or "Classic", "Minecraft"
})
```

## Tabs / Sections / Elements

```lua
local tab = window:CreateTab("Main", "home") -- optional icon key
local section = tab:CreateSection("General")

section:CreateToggle({ Name = "Enabled", Flag = "Enabled", Default = false, Callback = function(v) end })
section:CreateButton({ Name = "Run", Callback = function() end })
section:CreateSlider({ Name = "Speed", Min = 0, Max = 100, Default = 16, Flag = "Speed" })
section:CreateDropdown({ Name = "Mode", Options = {"A","B"}, Default = "A", Flag = "Mode" })
section:CreateInput({ Name = "Name", Placeholder = "...", Flag = "Name" })
section:CreateKeybind({ Name = "Toggle UI", Default = Enum.KeyCode.RightControl, Flag = "UIBind" })
section:CreateColorPicker({ Name = "Accent", Default = Color3.fromRGB(0,255,200), Flag = "Accent" })
section:CreateParagraph({ Title = "Info", Content = "Text here" })

-- 5.0 elements
section:CreateCard({ Title = "Card", Content = "Body" })
section:CreateBadge({ Text = "NEW", Color = Color3.fromRGB(0,255,200) })
section:CreateProgress({ Name = "Progress", Value = 0.4 })
section:CreateStatus({ Name = "Status", Text = "Ready", Status = "Success" })
section:CreateNotice({ Title = "Notice", Content = "Message", Type = "Info" })
section:CreateStat({ Name = "FPS", Value = "60" })
section:CreateDivider()
section:CreateIconButton({ Icon = "settings", Callback = function() end })
section:CreateWorldRadar({ FolderName = "Chests", Range = 250 })
```

## Notifications

```lua
Vaxorin:Notify({ Title = "Hello", Content = "World", Duration = 3, Type = "Success" })
```
