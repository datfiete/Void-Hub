# CyberUI

Roblox UI library with a Rayfield-like API.

## Loadstring (executors)

Push `load.lua` to your repo, then run:

```lua
local CyberUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/fietewoozle-dot/MyHub/main/CyberUI/load.lua"))()
```

Then build your UI:

```lua
local window = CyberUI:CreateWindow({
    Title = "My Hub",
    Subtitle = "Game name here",
})

local tab = window:CreateTab("Main")
local section = tab:CreateSection("General")

section:CreateToggle({
    Name = "Enabled",
    Flag = "Enabled",
    Default = false,
    Callback = function(value)
        print(value)
    end,
})
```

## Important

- Do **not** load `src/init.lua` directly with loadstring. CyberUI is multi-file and uses `require()`.
- Root `Loader.lua` in MyHub is for **game scripts**, not CyberUI.
- `examples/showcase.lua` is for local ModuleScript testing, not loadstring.

## Flags

```lua
print(CyberUI.Flags.Enabled)
```

## Notifications

```lua
CyberUI:Notify({
    Title = "Hello",
    Content = "World",
    Type = "Success", -- Info | Success | Warning | Error
    Duration = 4,
})

-- or
window:Notify({ ... })
```

## Rayfield comparison

| Rayfield | CyberUI |
|----------|---------|
| `Rayfield:CreateWindow({ Name = "..." })` | `CyberUI:CreateWindow({ Title = "..." })` |
| `LoadingTitle` / `LoadingSubtitle` | Not yet |
| `ConfigurationSaving` | `CyberUI.Config` (manual Save/Load) |
| `Window:CreateTab("Name", iconId)` | `window:CreateTab("Name")` — no icon yet |
| `Tab:CreateSection("Name")` | `tab:CreateSection("Name")` |
| `CurrentValue` | `Default` or `CurrentValue` |
| `Range = {0,100}`, `Increment` | `Min`, `Max`, `Rounding` |
| `Suffix` on slider | Not yet |
| `PlaceholderText` | `Placeholder` |
| `Color` on color picker | `Default` or `CurrentValue` |
| `CreateLabel("text")` | `CreateParagraph({ Title, Content })` |
| `Rayfield:Notify({ Image = id })` | No image support yet |
| `Rayfield.Flags` | `CyberUI.Flags` |

## Local testing (Studio / folder inject)

Place the `src` folder as a ModuleScript tree and run:

```lua
local CyberUI = require(path.to.src)
```

Or use `examples/showcase.lua` as a LocalScript sibling of `src`.
