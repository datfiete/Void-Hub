# Vaxorin Developer Manual

This is the **public API guide** for developers building scripts with Vaxorin. Developers should normally use `load.lua` plus the methods shown in `examples/developer_example.lua`; they should not need to edit the framework internals under `src/`.

## 1. Basic workflow

A Vaxorin script normally follows this pattern:

1. Load Vaxorin.
2. Set the Vaxorin theme.
3. Create one window.
4. Create tabs.
5. Create sections.
6. Add UI elements.
7. Connect callbacks to your feature logic.
8. Add `Flag` + `Save = true` for settings that should persist.
9. Use notifications for important feedback.
10. Destroy the window when your script is unloaded.

Minimal example:

```lua
local Vaxorin = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/datfiete/Void-Hub/refs/heads/main/CyberUI%20-%20Kopie/load.lua"
))()

Vaxorin.Theme.Style = "Vaxorin"

local window = Vaxorin:CreateWindow({
    Title = "My Script",
    Subtitle = "by My Team",
})

local tab = window:CreateTab("Main")
local section = tab:CreateSection({
    Name = "General",
    Description = "General settings for this feature.",
})

section:CreateToggle({
    Name = "Enabled",
    CurrentValue = false,
    Callback = function(value)
        print("Enabled:", value)
    end,
})
```

## 2. Loading Vaxorin

Use the public loader:

```lua
local Vaxorin = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/datfiete/Void-Hub/refs/heads/main/CyberUI%20-%20Kopie/load.lua"
))()
```

For local testing inside the repository, an example can use `require(script.Parent.src)`, but a shipped developer script should use the public loader.

## 3. Theme

```lua
Vaxorin.Theme.Style = "Vaxorin"
```

`Meng` remains available as a backwards-compatible style name.

## 4. Window setup

A complete setup can look like this:

```lua
local window = Vaxorin:CreateWindow({
    Title = "My Script",
    Subtitle = "by My Team",
    Logo = "rbxassetid://135320038058277",
    Badges = {
        { Text = "v1.0" },
        { Text = "Developer" },
    },
    Footer = {
        Avatar = avatar,
        Username = game.Players.LocalPlayer.Name,
        Status = "Developer",
    },
    DiscordLink = "https://discord.gg/9jZTsy7Wtb",
    ShowSearch = true,
    ShowWindowControls = true,
    ToggleKey = Enum.KeyCode.RightControl,
    ConfigurationSaving = {
        Enabled = true,
        AutoSave = true,
        FolderName = "MyScript",
        FileName = "settings",
    },
})
```

### Logo and Discord

Use a valid image asset for `Logo`.

The Vaxorin logo is clickable. When `DiscordLink` is set, clicking the logo attempts to copy the invite and shows a built-in success notification.

### Badges

Badges are compact header labels. Keep them short because header width is limited.

```lua
Badges = {
    { Text = "My Hub | v1.0" },
    { Text = "Beta" },
}
```

### Profile

```lua
Footer = {
    Avatar = avatar,
    Username = player.Name,
    Status = "Developer",
}
```

Status can be changed later:

```lua
window:SetProfileStatus("Owner")
window:SetProfile("PlayerName", "VIP", avatar)
```

`Role` and `Badge` are accepted aliases for `Status` in the current window options.

## 5. Tabs

```lua
local combatTab = window:CreateTab("Combat")
local visualsTab = window:CreateTab("Visuals")
```

Vaxorin already supplies the built-in Options tab, so developers normally do not need to create another Options tab.

Vaxorin automatically gives common tab names compact text icons. This avoids emoji blocks on environments with limited glyph support.

## 6. Sections

Preferred form:

```lua
local section = combatTab:CreateSection({
    Name = "Aim Assist",
    Description = "Control targeting behavior and FOV.",
})
```

Simple form:

```lua
local section = combatTab:CreateSection("Aim Assist")
```

Without a description, Vaxorin uses a fallback such as `Configure aim assist`.

Change it later:

```lua
section:SetDescription("New description text.")
```

Multiple sections on a page are automatically arranged into two columns.

## 7. Toggle

```lua
local enabled = section:CreateToggle({
    Name = "Enabled",
    CurrentValue = false,
    Flag = "Combat.Enabled",
    Save = true,
    Callback = function(value)
        print(value)
    end,
})
```

Available fields:

- `Name`
- `CurrentValue` or `Default`
- `Flag`
- `Save`
- `Callback(value)`

Runtime API:

```lua
enabled:Set(true)
local value = enabled:Get()
enabled:OnChanged(function(value)
    print(value)
end)
enabled:Destroy()
```

## 8. Slider

```lua
local speed = section:CreateSlider({
    Name = "Speed",
    Min = 0,
    Max = 100,
    CurrentValue = 50,
    Rounding = 1,
    Flag = "Combat.Speed",
    Save = true,
    Callback = function(value)
        print(value)
    end,
})
```

Runtime API:

```lua
speed:Set(75)
print(speed:Get())
speed:OnChanged(function(value)
    print(value)
end)
```

## 9. Dropdown

### Single select

```lua
local mode = section:CreateDropdown({
    Name = "Mode",
    Options = { "Legit", "Balanced", "Fast" },
    CurrentOption = "Balanced",
    Flag = "Combat.Mode",
    Save = true,
    Callback = function(value)
        print(value)
    end,
})
```

### Multiple select

```lua
local categories = section:CreateDropdown({
    Name = "Categories",
    Options = { "Combat", "Visuals", "Movement", "Utility" },
    CurrentOption = { "Combat", "Visuals" },
    MultipleOptions = true,
    Flag = "General.Categories",
    Save = true,
})
```

Runtime API:

```lua
mode:Set("Fast")
print(mode:Get())
mode:OnChanged(function(value)
    print(value)
end)
```

## 10. Input

```lua
local input = section:CreateInput({
    Name = "Username",
    Placeholder = "Enter a username...",
    CurrentValue = "",
    Flag = "General.Username",
    Save = true,
    Callback = function(value)
        print(value)
    end,
})
```

Runtime API:

```lua
input:Set("NewName")
print(input:Get())
input:OnChanged(function(value)
    print(value)
end)
```

## 11. Keybind

```lua
local bind = section:CreateKeybind({
    Name = "Toggle Feature",
    Default = Enum.KeyCode.G,
    Flag = "Combat.ToggleKey",
    Save = true,
    Callback = function(key)
        print(key)
    end,
})
```

Runtime API:

```lua
bind:Set(Enum.KeyCode.H)
print(bind:Get())
bind:OnChanged(function(key)
    print(key)
end)
```

## 12. ColorPicker

```lua
local picker = section:CreateColorPicker({
    Name = "Accent Color",
    Default = Color3.fromRGB(155, 92, 255),
    Flag = "Visuals.AccentColor",
    Save = true,
    Callback = function(color)
        print(color)
    end,
})
```

Runtime API:

```lua
picker:Set(Color3.fromRGB(120, 80, 255))
print(picker:Get())
picker:OnChanged(function(color)
    print(color)
end)
```

## 13. Paragraphs, labels, and info

```lua
local info = section:CreateParagraph({
    Title = "How this works",
    Content = "This feature controls the main automation loop.",
})
```

`CreateLabel()` and `CreateInfo()` are aliases for `CreateParagraph()`.

Runtime API:

```lua
info:Set("Updated information")
info:SetTitle("New title")
print(info:Get())
print(info:GetTitle())
```

## 14. Buttons

```lua
section:CreateButton({
    Name = "Reset Settings",
    Callback = function()
        print("Resetting...")
    end,
})
```

Use buttons for immediate actions rather than persistent values.

## 15. Notifications

Window or library:

```lua
window:Notify({
    Title = "Saved",
    Content = "Your configuration was saved.",
    Type = "Success",
    Duration = 3,
})
```

Valid types:

- `Info`
- `Success`
- `Warning`
- `Error`

Use short, meaningful notification messages.

## 16. Configuration saving

Enable saving:

```lua
ConfigurationSaving = {
    Enabled = true,
    AutoSave = true,
    FolderName = "MyScript",
    FileName = "settings",
}
```

Then opt an element into saving:

```lua
Flag = "Combat.Enabled",
Save = true,
```

Manual operations:

```lua
Vaxorin:SaveConfiguration()
Vaxorin:LoadConfiguration()
```

Use stable, descriptive flag names. Changing a flag name creates a new saved entry.

## 17. Search

The built-in search can find:

- tab names
- section names
- element names

Selecting a result switches to the relevant tab and scrolls to the section or element.

For that reason, developers should use descriptive element names such as `Auto Collect Eggs`, `Movement Speed`, and `Collect Delay` instead of `Toggle 1` or `Option`.

## 18. Watermark

The watermark is independent from the main window.

```lua
window:SetWatermarkEnabled(true)
```

The user can move it without moving the main UI. The built-in Options tab also contains the watermark toggle.

## 19. Window helpers

Useful public methods:

```lua
window:Toggle()
window:SetOpen(true)
window:SetVisible(false)
window:SetBackgroundImage("rbxassetid://123456789")
window:SetBackgroundOverlayTransparency(0.35)
window:SetCornerRadius(10)
```

## 20. Runtime handles and callbacks

The most common pattern is:

```lua
local toggle = section:CreateToggle({...})

toggle:Set(true)
print(toggle:Get())

toggle:OnChanged(function(value)
    -- update your feature here
end)
```

Value elements generally provide `Set`, `Get`, `OnChanged`, and `Destroy`.

Buttons provide `Set`, `Get`, and `Destroy`.

Paragraphs provide `Set`, `Get`, `SetTitle`, `GetTitle`, and `Destroy`.

Sections provide `SetDescription` and `Destroy`.

## 21. Keep feature logic separate

Prefer this pattern:

```lua
local autoFarm = false
local delay = 2

local toggle = section:CreateToggle({
    Name = "Auto Farm",
    Flag = "Farm.Enabled",
    Save = true,
    Callback = function(value)
        autoFarm = value
    end,
})

local slider = section:CreateSlider({
    Name = "Delay",
    Min = 0.5,
    Max = 10,
    Default = 2,
    Rounding = 0.1,
    Flag = "Farm.Delay",
    Save = true,
    Callback = function(value)
        delay = value
    end,
})

-- A separate feature loop can then use autoFarm and delay.
```

Avoid placing a huge feature system inside a single UI callback.

## 22. Cleanup

When the script is unloaded:

```lua
window:Destroy()
```

If you own the entire Vaxorin instance:

```lua
Vaxorin:Destroy()
```

## 23. What developers should not edit

Normal script developers should not need to edit:

- `src/Core/Window.lua`
- `src/Core/Tab.lua`
- `src/Core/Section.lua`
- `src/Elements/*`
- `src/Utils/*`
- theme implementation files

Those are framework internals. Use the public API instead.

## 24. Recommended developer layout

```text
YourScript
├── main.lua
├── Features
│   ├── Combat.lua
│   ├── Player.lua
│   ├── Visuals.lua
│   └── Misc.lua
└── Utils
    └── Helpers.lua
```

Keep the Vaxorin construction in one place and keep feature logic in feature modules when the project grows.

## 25. Full reference

Open `examples/developer_example.lua`. It demonstrates the complete public surface in one script, including:

- loading
- theme
- window configuration
- logo / Discord link
- badges
- profile and status
- watermark
- tabs
- section descriptions
- paragraphs
- toggles
- sliders
- dropdowns
- multi-select dropdowns
- inputs
- buttons
- notifications
- keybinds
- color pickers
- flags and configuration saving
- `Get` / `Set` / `OnChanged`
- runtime profile helpers
- window helpers
- cleanup
