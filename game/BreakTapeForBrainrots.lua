local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local Executor = getexecutorname()

local Avatar = Players:GetUserThumbnailAsync(
    Player.UserId,
    Enum.ThumbnailType.HeadShot,
    Enum.ThumbnailSize.Size150x150
)

local CyberUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/datfiete/Void-Hub/main/CyberUI/load.lua"))()

CyberUI.Theme.Style = "Meng"

local window = CyberUI:CreateWindow({
    Title = "Break Tape for Brainrots",
    Subtitle = "by fietewoozle",

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
local AutoFarmsection = Farmtab:CreateSection("AutoFarm")

local Character = Player.Character or Player.CharacterAdded:Wait()
local RootPart = Character:WaitForChild("HumanoidRootPart")

local AutoFarmBest = false
local Plot1 = workspace.Plots["1"]

AutoFarmsection:CreateToggle({
    Name = "Auto Farm Best",
    CurrentValue = false,
    Flag = "MyFeature",
    Save = false,
    Callback = function(value)
        print("Toggle changed:", value)
        AutoFarmBest = value
    end,
})

task.spawn(function()
    while task.wait(0.5) do 
        if AutoFarmBest then 
            for i, v in pairs(workspace.Bases.Base20.Slots:GetChildren()) do 
                local Spawn = v:FindFirstChild("Spawn")
                local SpawnedItem = Spawn:FindFirstChild("SpawnedItem")
                local Proximity = SpawnedItem:FindFirstChild("ProximityPrompt", true)
                if Spawn and SpawnedItem and Proximity then 
                    Character:MoveTo(SpawnedItem.WorldPivot.Position + Vector3.new(0, 3, 0))
                    task.wait(0.2)
                    fireproximityprompt(Proximity)
                    RootPart.CFrame = CFrame.new(Plot1.Position + Vector3.new(0, 3, 0))
                    task.wait(0.5)
                else 
                    print("Not Found")
                end
            end
        end
    end
end
)
