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
    Title = "[UPD] Parkour For Brainrots!",
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
local Farmsection = Farmtab:CreateSection("Auto Farm")
local Moneysection = Farmtab:CreateSection("Money")


local MyPlot = nil 

for i, v in pairs(workspace.Plots:GetChildren()) do 
    if v:GetAttribute("TakenBy") == Player.Name then 
        print(v)
        MyPlot = v.Name
    end
end

local AutoBR = false
local Zone = 12
local AutoMoneyDelay = 5
local AutoMoney = false

Farmsection:CreateSlider({
    Name = "Zone to collect Brainrots",
    Min = 1,
    Max = 12,
    CurrentValue = 12,
    Rounding = 1,
    Flag = "SpeedValue",
    Save = true,
    Callback = function(value)
        print("Slider value:", value)
        Zone = value
    end,
})

Farmsection:CreateToggle({
    Name = "Auto Collect on selected Zone",
    CurrentValue = false,
    Flag = "MyFeature",
    Save = false,
    Callback = function(value)
        print("Toggle changed:", value)
        AutoBR = value
    end,
})

task.spawn(function ()
    while task.wait(1) do 
        if AutoBR then 
            for i, v in pairs(workspace.Brainrots["Zone" .. Zone]:GetChildren()) do 
                Character:MoveTo(v.WorldPivot.Position + Vector3.new(0, 3, 0))
                local Prompt = v:FindFirstChildOfClass("ProximityPrompt")
                task.wait(0.3) 
                if Prompt then 
                    fireproximityprompt(Prompt)
                    task.wait(0.1)
                    Character:MoveTo(workspace.Plots[MyPlot].WorldPivot.Position + Vector3.new(0, 3, 0))
                    task.wait(0.2)
                end
            end
        end
    end
end)

Moneysection:CreateSlider({
    Name = "Money Collect Delay",
    Min = 1,
    Max = 100,
    CurrentValue = 5,
    Rounding = 1,
    Flag = "SpeedValue",
    Save = true,
    Callback = function(value)
        print("Slider value:", value)
        AutoMoneyDelay = value
    end,
})

Moneysection:CreateToggle({
    Name = "Auto Collect Money",
    CurrentValue = false,
    Flag = "MyFeature",
    Save = false,
    Callback = function(value)
        print("Toggle changed:", value)
        AutoMoney = value 
    end,
})

task.spawn(function ()
    while task.wait(AutoMoneyDelay) do 
        if AutoMoney then 
            for i, v in pairs(workspace.Plots[MyPlot].Collect:GetChildren()) do 
                local Prompt = v:FindFirstChild("TouchInterest", true)
                if Prompt then 
                    local Parent = Prompt.Parent
                    if Parent then 
                        firetouchinterest(RootPart, Parent, 0)
                        task.wait(0.05)
                        firetouchinterest(RootPart, Parent, 1)
                    end
                end
            end
        end
    end
end)