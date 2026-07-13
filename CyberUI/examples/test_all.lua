-- CyberUI full test script
-- Place this in a LocalScript under StarterPlayerScripts or run it directly in a LocalScript.

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local Executor = getexecutorname()

local Avatar = Players:GetUserThumbnailAsync(
    Player.UserId,
    Enum.ThumbnailType.HeadShot,
    Enum.ThumbnailSize.Size150x150
)

local CyberUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/fietewoozle-dot/MyHub/main/CyberUI/load.lua"))()

CyberUI.Theme.Style = "Meng"

local window = CyberUI:CreateWindow({
    Title = "Void Hub",
    Subtitle = "Your game name",
    BackgroundImage = "rbxassetid://106318186489675",

    Logo = "rbxassetid://128228297210141",
    Badges = {
        { Text = "My Hub | v1.0" },
        { Text = "Executor: " .. Executor },
    },
    Footer = {
        Avatar = Avatar,
        Username = Player.Name,
    },
    ShowSearch = true,
    ShowWindowControls = true,
})

local mainTab = window:CreateTab("Main")

local generalSection = mainTab:CreateSection("General")
local actionSection = mainTab:CreateSection("Actions")

local function notify(options)
    return window:Notify(options)
end

local function getCurrentBind()
    return CyberUI.Flags.ToggleUI or Enum.KeyCode.RightControl
end

local enabledToggle = generalSection:CreateToggle({
    Name = "Enabled",
    Flag = "Enabled",
    Default = false,
    Callback = function(value)
        notify({
            Title = "Enabled",
            Content = value and "Feature enabled." or "Feature disabled.",
            Type = "Info",
            Duration = 2,
        })
        print("Enabled:", value)
    end,
})

local speedSlider = generalSection:CreateSlider({
    Name = "Walk Speed",
    Flag = "WalkSpeed",
    Min = 16,
    Max = 100,
    Default = 16,
    Rounding = 1,
    Callback = function(value)
        notify({
            Title = "Walk Speed",
            Content = string.format("New speed: %.0f", value),
            Type = "Info",
            Duration = 2,
        })
        print("Walk Speed:", value)
    end,
})

local modeDropdown = generalSection:CreateDropdown({
    Name = "Mode",
    Flag = "Mode",
    Options = { "Legit", "Rage", "Custom" },
    Default = "Legit",
    Callback = function(value)
        notify({
            Title = "Mode Selected",
            Content = "Mode set to " .. value,
            Type = "Info",
            Duration = 2,
        })
        print("Mode:", value)
    end,
})

local usernameInput = generalSection:CreateInput({
    Name = "Username",
    Flag = "Username",
    Placeholder = "Enter username...",
    Default = "Player",
    Callback = function(value)
        notify({
            Title = "Username",
            Content = "Username saved: " .. value,
            Type = "Info",
            Duration = 2,
        })
        print("Username:", value)
    end,
})

actionSection:CreateButton({
    Name = "Send Notification",
    Callback = function()
        window:Notify({
            Title = "Notification Test",
            Content = "This notification should appear in the top-right.",
            Type = "Success",
            Duration = 3,
        })
    end,
})


print("CyberUI test script loaded. Toggle key:", getCurrentBind().Name)


