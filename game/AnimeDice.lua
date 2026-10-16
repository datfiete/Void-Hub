local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Executor = "unknown"
pcall(function()
    if type(getexecutorname) == "function" then
        Executor = tostring(getexecutorname())
    elseif type(identifyexecutor) == "function" then
        Executor = tostring(identifyexecutor())
    end
end)

local Vaxorin = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/datfiete/Void-Hub/refs/heads/main/CyberUI%20-%20Kopie/load.lua"
))()

pcall(function()
    if Vaxorin.Theme then
        Vaxorin.Theme.Style = "Vaxorin"
    end
end)

local avatar = ""
pcall(function()
    avatar = Players:GetUserThumbnailAsync(
        LocalPlayer.UserId,
        Enum.ThumbnailType.HeadShot,
        Enum.ThumbnailSize.Size150x150
    )
end)

local window = Vaxorin:CreateWindow({
    Title = "[🎉UPD 8] Anime Dice",
    Subtitle = "by Fietewoozle",
    Logo = "rbxassetid://135320038058277",

    Badges = {
        { Text = "Vaxorin | v1.0" },
        { Text = "Executor : " .. Executor },
    },

    Footer = {
        Avatar = avatar,
        Username = LocalPlayer.Name,
        Status = "Ready",
    },

    DiscordLink = "https://discord.gg/nTHbCmDYWd",
    ShowSearch = true,
    ShowWindowControls = true,
    ToggleKey = Enum.KeyCode.RightControl,
    TopMost = true,

    Layout = "Vaxorin", -- Classic, Minecraft, Orbit, Aether, Nova, Vortex, Prism, Eclipse, Zenith

    ConfigurationSaving = {
        Enabled = true,
        AutoSave = true,
        FolderName = "Vaxorin",
        FileName = "MyScript",
    },
})

window:SetProfileStatus("Ready")
-- window:SetWatermarkEnabled(true)

local Farmtab = window:CreateTab("Main")
local Farmsection = Farmtab:CreateSection({
    Name = "Main",
    Description = "General settings.",
})

local UpgardeScreenPath = LocalPlayer.PlayerGui.Root.Upgrades.Screen
local AutoUpgrade = false
local UpgradePath = {}



Farmsection:CreateDropdown({
    Name = "Auto Upgrade Path",
    Options = {
        "Luck",
        "Fortune",
        "Money",
        "Sell",
        "Damage",
        "Roll Speed",
        "Unit Storage",
        "Health",
        "Walkspeed",
        "Trait Luck",
        "Grade Luck",
        "Grade Rolls",
        "Trait Rolls"
    },
    CurrentOption = "Luck",
    MultipleOptions = false,
    Flag = "Feature.Mode",
    Save = true,

    Callback = function(value)
        if type(value) == "table" then
            value = value[1]
        end

        if not value then
            return
        end

        getgenv().AutoUpgradePath = value

        print("Auto Upgrade Path: " .. value)
    end,
})

Farmsection:CreateToggle({
    Name = "Auto Upgrade Togle",
    CurrentValue = false,
    Flag = "Feature.Enabled",
    Save = true,
    -- FireOnLoad = false,
    Callback = function(value)
        
    end,
})