# Vaxorin Developer Guide

## 1. Loading

```lua
local Vaxorin = loadstring(game:HttpGet("https://raw.githubusercontent.com/datfiete/Void-Hub/refs/heads/main/CyberUI%20-%20Kopie/load.lua"))()
```

## 2. Create a window

```lua
local window = Vaxorin:CreateWindow({
    Title = "My Vaxorin Script",
    Subtitle = "by Vaxiron Officials",
    Logo = "rbxassetid://135320038058277",
    Badges = {
        { Text = "Void Hub | v1.0" },
        { Text = "Executor: " .. getexecutorname() },
    },
    Footer = {
        Avatar = avatarUrl,
        Username = game.Players.LocalPlayer.Name,
    },
    DiscordLink = "https://discord.gg/9jZTsy7Wtb",
    ShowSearch = true,
    ShowWindowControls = true,
    ToggleKey = Enum.KeyCode.RightControl,
})
```

The Vaxorin logo is clickable and copies the configured Discord invite, then sends a built-in notification.

## 3. Tabs and sections

```lua
local tab = window:CreateTab("Combat")
local section = tab:CreateSection("Aim Assist")
```

Sections automatically arrange into two columns when a page has multiple sections. The content area is width-safe so the right column stays inside the window.

## 4. Elements

```lua
section:CreateToggle({
    Name = "Enabled",
    CurrentValue = false,
    Flag = "Combat.Enabled",
    Save = true,
    Callback = function(value)
        print(value)
    end,
})

section:CreateSlider({
    Name = "FOV",
    Min = 1,
    Max = 180,
    CurrentValue = 90,
    Rounding = 1,
    Flag = "Combat.FOV",
    Save = true,
    Callback = function(value)
        print(value)
    end,
})

section:CreateDropdown({
    Name = "Mode",
    Options = {"Closest", "FOV", "Distance"},
    CurrentOption = "Closest",
    Flag = "Combat.Mode",
    Save = true,
    Callback = function(value)
        print(value)
    end,
})
```

Available element helpers include toggles, buttons, sliders, dropdowns, inputs, keybinds, color pickers, and paragraphs.

## 5. Notifications

```lua
window:Notify({
    Title = "Saved",
    Content = "Your configuration was saved.",
    Type = "Success",
    Duration = 3,
})
```

Types: `Info`, `Success`, `Warning`, `Error`.

## 6. Theme

```lua
Vaxorin.Theme.Style = "Vaxorin"
```

`Meng` remains available as a backwards-compatible alias.

## 7. Configuration

```lua
ConfigurationSaving = {
    Enabled = true,
    AutoSave = true,
}
```

Use flags and `Save = true` on elements you want persisted.

## 8. Window controls

The UI is draggable from the header, resizable from the lower-right corner, and can be toggled with the configured keybind. The window automatically clamps its size to the current viewport so it works on emulators and smaller displays.

## 9. Watermark

The optional watermark is independent from the header and lives at the lower-right of the screen. It can be enabled with the built-in `Show Watermark` option. It can be dragged without moving the main window.

## 10. Design guidelines

Vaxorin is intentionally restrained: dark surfaces, small purple accents, subtle glow, clear spacing, and readable hierarchy. Avoid adding large decorative neon effects around ordinary controls; use the accent as light rather than as a full background.
