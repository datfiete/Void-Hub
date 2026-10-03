# Vaxorin — Developers Start Here

## Start here

Open `examples/developer_example.lua` first. It is the copyable reference script.

## Full explanation

Read `docs/DEVELOPER_MANUAL.md` for the complete public API and usage guide.

## Public loader

```lua
local Vaxorin = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/datfiete/Void-Hub/refs/heads/main/CyberUI%20-%20Kopie/load.lua"
))()
```

Developers should normally use the public API and should not need to edit the framework internals under `src/`.
