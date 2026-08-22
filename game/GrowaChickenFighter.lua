local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local RootPart = Character:WaitForChild("HumanoidRootPart")
local Executor = getexecutorname()

local Avatar = Players:GetUserThumbnailAsync(
    Player.UserId,
    Enum.ThumbnailType.HeadShot,
    Enum.ThumbnailSize.Size150x150
)

local CyberUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/datfiete/Void-Hub/refs/heads/main/CyberUI%20-%20Kopie/load.lua"))()

CyberUI.Theme.Style = "Meng"

local window = CyberUI:CreateWindow({
    Title = "Grow a Chicken Fighter",
    Subtitle = "by fietewoozle",
    BackgroundImage = "rbxassetid://106318186489675",

    Logo = "rbxassetid://128228297210141",
    Badges = {
        { Text = "Vaxorin | v1.0" },
        { Text = "Executor: " .. Executor },
    },

    Footer = {
        Avatar = Avatar,
        Username = Player.Name,
    },


    ConfigurationSaving = {
        Enabled = true,
        AutoSave = true,
    },

    ShowSearch = true,
    ShowWindowControls = true,
    ToggleKey = Enum.KeyCode.RightControl,
})

local Farmtab = window:CreateTab("Farm")
local eggsection = Farmtab:CreateSection("Eggs")

local AutoEggscollect = false

eggsection:CreateToggle({
    Name = "Enable Feature",
    CurrentValue = false,
    Flag = "MyFeature",
    Save = true,
    Callback = function(value)
        AutoEggscollect = value
    end,
})

task.spawn(function()
    while task.wait(2) do 
        if AutoEggscollect then 
            for i, v in pairs(workspace.NestEggs:GetChildren()) do 
                if v:GetAttribute("owner") == Player.UserId then 
                    firetouchinterest(RootPart, v, 0)
                    task.wait(0.08)
                    firetouchinterest(RootPart, v, 1)
                end
            end
        end
    end
end
)
