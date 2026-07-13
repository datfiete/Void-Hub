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

local CyberUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/fietewoozle-dot/MyHub/main/CyberUI/load.lua"))()

CyberUI.Theme.Style = "Meng"

local window = CyberUI:CreateWindow({
    Title = "Collect A Meme [🔍138]",
    Subtitle = "by fietewoozle",
    BackgroundImage = "rbxassetid://106318186489675",

    Logo = "rbxassetid://128228297210141",
    Badges = {
        { Text = "Void Hub | v1.0" },
        { Text = "Executor: " .. Executor },
    },

    Footer = {
        Avatar = Avatar,
        Username = Player.Name,
    },

    ShowSearch = true,
    ShowWindowControls = true,
})

local Farmtab = window:CreateTab("Main")
local Farmsection = Farmtab:CreateSection("Main Section")

Farmsection:CreateButton({
    Name = "Collect 133/138(dunno where the others are)",
    Callback = function()
        print("Button clicked!")
        for i, v in pairs(workspace.Pals:GetChildren()) do 
        firetouchinterest(RootPart, v, 0)
        task.wait(0.05)
        firetouchinterest(RootPart, v, 1)
        task.wait(0.1)
        end
    end,
})
