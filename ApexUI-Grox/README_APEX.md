# Apex UI — Visual Redesign of CyberUI / Vaxorin

A **complete visual overhaul** of the original CyberUI library.

Same public API → your existing scripts keep working.  
Only the look & feel changed.

---

## What changed (the BANGER part)

| Element       | New look |
|---------------|----------|
| **Theme**     | New default style **`Apex`** — deep black + electric cyan + hot magenta |
| **Toggle**    | Larger glass pill, glowing track, smoother spring animation |
| **Slider**    | Thicker track, gradient fill, glowing white knob with accent ring |
| **Button**    | Soft gradient overlay + strong accent glow on hover |
| **Dropdown**  | Cleaner header, accent selected text |
| **Window**    | Slightly larger, rounder corners, more padding |
| **Loader**    | Cyan accent, "Apex UI" branding |

All other features (ESP, Weather, Layouts, Favorites, Config saving, multi-dropdown, ColorPicker, Keybind, Notifications, Search, Window controls …) remain 100 % intact.

---

## How to use

### 1. Local test (from this folder)

```lua
-- Point the loadstring to your own host or use a local require if you bundle it
local Library = loadstring(game:HttpGet("YOUR_HOST/ApexUI/load.lua"))()
```

Or if you keep the original structure:

```lua
Library.Theme.Style = "Apex"   -- or "Meng", "Neon", "Deep", etc.
```

### 2. Example (same as your original script)

```lua
--!strict
local Library = loadstring(game:HttpGet("YOUR_HOST/ApexUI/load.lua"))()

Library.Theme.Style = "Apex"   -- the new banger theme

local Window = Library:CreateWindow({
    Title = "Vaxorin",
    Subtitle = "Universal Script Hub",
    BackgroundImage = "rbxassetid://106318186489675",
    -- ... rest of your options stay identical
})
```

Everything else in your example (CreateTab, CreateSection, CreateToggle, CreateSlider, CreateDropdown with MultipleOptions, CreateButton, CreateKeybind, CreateColorPicker, CreateInput, CreateParagraph, Notify, ConfigurationSaving, Footer, Badges, ShowSearch, ToggleKey …) works unchanged.

---

## Available styles

`Apex` (default), `Vaxorin`, `Meng`, `Deep`, `Sakura`, `Midnight`, `Ocean`, `Neon`, `Sunset`, `Forest`, `Slate`, `Dark`, `Light`, `Cyber`, …

```lua
Library.Theme.Style = "Apex"
```

---

## Files

- `load.lua`          – remote loader (bootstrap + module download)
- `src/`              – full source (Theme, Window, all Elements, ESP, etc.)
- `examples/`         – original examples still work

Enjoy the new look.
