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

local CyberUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/datfiete/Void-Hub/main/CyberUI/load.lua"))()

CyberUI.Theme.Style = "Meng"

local window = CyberUI:CreateWindow({
    Title = "Swing Obby for Brainrots!",
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

local YourPlot = nil

for _, plot in workspace.Plots:GetChildren() do
	if plot:GetAttribute("OwnerName") == Player.Name then
		YourPlot = plot
		print("Found your plot:", plot.Name)
		break
	end
end

local Autofarm = false 

Farmsection:CreateToggle({
    Name = "Auto Collect",
    CurrentValue = false,
    Flag = "MyFeature",
    Save = false,
    Callback = function(value)
        print("Auto Collect changed:", value)
        Autofarm = value
    end,
})

task.spawn(function ()
    while task.wait(1) do 
        if Autofarm then 
            for i, v in pairs(workspace.ActiveBrainrots:GetChildren()) do 
                if v:GetAttribute("Zone") == 13 then 
                    RootPart.CFrame = v.CFrame + Vector3.new(0, 3, 0)
                    task.wait(0.35)
                    local prompt = v:FindFirstChild("ProximityPrompt", true)
                    if prompt then 
                        fireproximityprompt(prompt)
                    end
                end
            end
        end
    end
end)

Farmsection:CreateButton({
    Name = "Teleport Back",
    Callback = function()
        print("Teleported to Base!")
        local targetPosition = YourPlot.WorldPivot.Position + Vector3.new(0, 5, 0)
        Character:MoveTo(targetPosition)
    end,
})
