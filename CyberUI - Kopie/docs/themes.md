# Themes

Vaxorin ships with a built-in cyber / dark theme controlled by `src/Core/Theme.lua`.

## Runtime

The active theme table lives on the library instance:

```lua
print(Vaxorin.Theme.Accent)
print(Vaxorin.Theme.Background)
```

After changing theme fields, call:

```lua
Vaxorin:RefreshTheme()
```

## Layout variants (5.0)

In addition to the default **Vaxorin** shell you can switch the whole interface:

```lua
window:SetLayout("Classic")   -- full-screen category menu
window:SetLayout("Minecraft") -- player card + hotbar style
window:SetLayout("Vaxorin")   -- default
```

These are true shell switches, not simple resize presets.
