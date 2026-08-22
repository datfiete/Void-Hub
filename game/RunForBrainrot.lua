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
local Farmsection = Farmtab:CreateSection("Farm")

local Autofarm = false 

Farmsection:CreateToggle({
    Name = "Auto Farm",
    CurrentValue = false,
    Flag = "MyFeature",
    Save = true,
    Callback = function(value)
        Autofarm = value
    end,
})

Farmsection:CreateButton({
    Name = "Teleport back",
    Callback = function()
        print("Teleported back!")
        Character:MoveTo(Vector3.new(5, 19, -446))
    end,
})

task.spawn(function()
    while task.wait(2) do 
        if Autofarm then
            Character:MoveTo(Vector3.new(-5, 19, 5456))
            task.wait(1)
            for i, v in pairs(workspace.ItemSpawners:GetChildren()) do 
                if v.Name == "Divine" then 
                    print("Found Divine Egg")
                    for i, Brainrots in pairs(v:GetChildren()) do 
                        print(Brainrots.Name)
                        local Prompt = Brainrots:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if Prompt then 
                            Character:MoveTo(Brainrots.WorldPivot.Position + Vector3.new(0, 3, 0))
                            task.wait(0.5)
                            fireproximityprompt(Prompt)
                            task.wait(0.5)
                            Character:MoveTo(Vector3.new(5, 19, -446))
                            task.wait(1)
                        end
                    end
                end
            end
        end
    end
end
)

