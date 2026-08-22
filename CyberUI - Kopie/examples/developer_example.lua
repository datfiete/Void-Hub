--[[
    VAXORIN DEVELOPER EXAMPLE
    ==========================

    This is the public-facing reference script for Vaxorin developers.
    It demonstrates the supported UI API without requiring access to the
    framework internals.
]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Vaxorin = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/datfiete/Void-Hub/refs/heads/main/CyberUI%20-%20Kopie/load.lua"
))()

Vaxorin.Theme.Style = "Vaxorin"

local avatar = ""
pcall(function()
    avatar = Players:GetUserThumbnailAsync(
        LocalPlayer.UserId,
        Enum.ThumbnailType.HeadShot,
        Enum.ThumbnailSize.Size150x150
    )
end)

local window = Vaxorin:CreateWindow({
    Title = "My Script",
    Subtitle = "by Your Developer Team",
    Logo = "rbxassetid://135320038058277",

    Badges = {
        { Text = "Vaxorin | v1.0" },
        { Text = "Developer Build" },
    },

    Footer = {
        Avatar = avatar,
        Username = LocalPlayer.Name,
        Status = "Developer",
    },

    DiscordLink = "https://discord.gg/9jZTsy7Wtb",
    ShowSearch = true,
    ShowWindowControls = true,
    ToggleKey = Enum.KeyCode.RightControl,

    ConfigurationSaving = {
        Enabled = true,
        AutoSave = true,
        FolderName = "VaxorinExample",
        FileName = "settings",
    },
})

window:SetProfileStatus("Developer")
window:SetWatermarkEnabled(true)

-- Built-in Options tab is created by Vaxorin automatically.

local mainTab = window:CreateTab("Main")

local overview = mainTab:CreateSection({
    Name = "Overview",
    Description = "A short description of what this page is for.",
})

overview:CreateParagraph({
    Title = "Welcome to Vaxorin",
    Content = "Use paragraphs for instructions, status information, or feature explanations.",
})

overview:CreateParagraph({
    Title = "Built-in Search",
    Content = "The search box finds tabs, sections, and elements, then jumps to the selected result.",
})

local stateSection = mainTab:CreateSection({
    Name = "State",
    Description = "Demonstrates toggles and sliders.",
})

local enabled = stateSection:CreateToggle({
    Name = "Enabled",
    CurrentValue = true,
    Flag = "Main.Enabled",
    Save = true,
    Callback = function(value)
        print("Enabled:", value)
    end,
})

local speed = stateSection:CreateSlider({
    Name = "Speed",
    Min = 0,
    Max = 100,
    CurrentValue = 50,
    Rounding = 1,
    Flag = "Main.Speed",
    Save = true,
    Callback = function(value)
        print("Speed:", value)
    end,
})

print("Enabled value:", enabled:Get())
print("Speed value:", speed:Get())

enabled:OnChanged(function(value)
    print("Enabled changed:", value)
end)

speed:OnChanged(function(value)
    print("Speed changed:", value)
end)

local selectionSection = mainTab:CreateSection({
    Name = "Selections",
    Description = "Single-select and multi-select dropdowns.",
})

local mode = selectionSection:CreateDropdown({
    Name = "Mode",
    Options = { "Safe", "Balanced", "Fast" },
    CurrentOption = "Balanced",
    Flag = "Main.Mode",
    Save = true,
    Callback = function(value)
        print("Mode:", value)
    end,
})

local categories = selectionSection:CreateDropdown({
    Name = "Categories",
    Options = { "Combat", "Visuals", "Movement", "Utility" },
    CurrentOption = { "Visuals" },
    MultipleOptions = true,
    Flag = "Main.Categories",
    Save = true,
})

print("Selected mode:", mode:Get())

local inputSection = mainTab:CreateSection({
    Name = "Text Input",
    Description = "Use inputs for developer-defined strings.",
})

local usernameInput = inputSection:CreateInput({
    Name = "Username",
    Placeholder = "Enter a username...",
    CurrentValue = "",
    Flag = "Main.Username",
    Save = true,
    Callback = function(value)
        print("Username:", value)
    end,
})

usernameInput:OnChanged(function(value)
    print("Input changed:", value)
end)

local actionSection = mainTab:CreateSection({
    Name = "Actions",
    Description = "Buttons and notifications for immediate feedback.",
})

actionSection:CreateButton({
    Name = "Show Success Notification",
    Callback = function()
        window:Notify({
            Title = "Vaxorin",
            Content = "Everything is working correctly.",
            Type = "Success",
            Duration = 3,
        })
    end,
})

actionSection:CreateButton({
    Name = "Show Warning Notification",
    Callback = function()
        Vaxorin:Notify({
            Title = "Warning",
            Content = "This is an example warning.",
            Type = "Warning",
            Duration = 3,
        })
    end,
})

actionSection:CreateButton({
    Name = "Show Error Notification",
    Callback = function()
        window:Notify({
            Title = "Error",
            Content = "This is an example error.",
            Type = "Error",
            Duration = 3,
        })
    end,
})

local keybindSection = mainTab:CreateSection({
    Name = "Keybinds",
    Description = "User-rebindable keyboard or supported controller shortcuts.",
})

local exampleKeybind = keybindSection:CreateKeybind({
    Name = "Example Action",
    Default = Enum.KeyCode.G,
    Flag = "Main.ExampleKeybind",
    Save = true,
    Callback = function(key)
        print("Keybind pressed:", key)
    end,
})

exampleKeybind:OnChanged(function(key)
    print("Keybind changed:", key)
end)

local colorSection = mainTab:CreateSection({
    Name = "Colors",
    Description = "ColorPicker example for user-defined colors.",
})

local accent = colorSection:CreateColorPicker({
    Name = "Accent Color",
    Default = Color3.fromRGB(155, 92, 255),
    Flag = "Main.AccentColor",
    Save = true,
    Callback = function(color)
        print("Accent color:", color)
    end,
})

accent:OnChanged(function(color)
    print("Color changed:", color)
end)

-- Runtime helpers. These are examples; do not run all of them automatically.
-- enabled:Set(false)
-- speed:Set(75)
-- mode:Set("Fast")
-- usernameInput:Set("ExampleUser")
-- exampleKeybind:Set(Enum.KeyCode.H)
-- accent:Set(Color3.fromRGB(120, 80, 255))
-- stateSection:SetDescription("Changed at runtime.")
-- window:SetProfileStatus("Owner")
-- window:SetProfile("PlayerName", "VIP", avatar)
-- window:SetVisible(false)
-- window:Toggle()
-- window:SetOpen(true)
-- window:SetBackgroundImage("rbxassetid://123456789")
-- window:SetBackgroundOverlayTransparency(0.35)
-- window:SetCornerRadius(10)
-- Vaxorin:SaveConfiguration()
-- Vaxorin:LoadConfiguration()

-- Destroy when the developer's script is unloaded.
-- window:Destroy()
-- Vaxorin:Destroy()

print("[Vaxorin] Developer example loaded successfully.")
