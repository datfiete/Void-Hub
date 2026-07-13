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
    Title = "+1 Crunchy Wax Escape",
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

local Farmtab = window:CreateTab("Farm")
local Farmsection = Farmtab:CreateSection("Farm")

local Zone = 1
local AutoTrophies = false
local AutoSpeed = false

Farmsection:CreateSlider({
    Name = "Trophies Collect Zone",
    Min = 1,
    Max = 10,
    CurrentValue = 10,
    Rounding = 1,
    Flag = "SpeedValue",
    Save = true,
    Callback = function(value)
        print("Slider value:", value)
        Zone = value
    end,
})

Farmsection:CreateToggle({
    Name = "Auto Trophies",
    CurrentValue = false,
    Flag = "MyFeature",
    Save = false,
    Callback = function(value)
        print("Toggle changed:", value)
        AutoTrophies = value
    end,
})

task.spawn(function ()
    while task.wait(1) do 
        if AutoTrophies then 
           local TPZone = workspace.StageWinPaths.Normal:FindFirstChild(tostring(Zone))
           Character:MoveTo(TPZone:GetPivot().Position + Vector3.new(0, 3, 0))
        end
    end
end)

Farmsection:CreateToggle({
    Name = "Auto Speed",
    CurrentValue = false,
    Flag = "MyFeature",
    Save = false,
    Callback = function(value)
        print("Toggle changed:", value)
        AutoSpeed = value
    end,
})

task.spawn(function ()
    while task.wait(0.05) do 
        if AutoSpeed then 
            local Event = game:GetService("ReplicatedStorage").AddSpeed
            Event:InvokeServer()
        end
    end
end)
