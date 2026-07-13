local CyberUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/datfiete/Void-Hub/main/CyberUI/load.lua"))()

local window = CyberUI:CreateWindow({
    Name = "[UPD] +1 Wings for Brainrots",
    Title = "[UPD] +1 Wings for Brainrots Script",
    Subtitle = "by fietewoozle",
    Size = Vector2.new(700, 500),
    Center = true,
    ToggleKey = Enum.KeyCode.RightControl,
})

local Farmtab = window:CreateTab("Farm")
local Farmsection = Farmtab:CreateSection("Auto Farm")

local player = game.Players.LocalPlayer
local Character = player.Character or player.CharacterAdded:Wait()

local AutoFarm = false
local Delay = 5
local AutoPlaceBest = false

Farmsection:CreateToggle({
    Name = "Auto Farm",
    CurrentValue = false,
    Flag = "AutoFarmMyFeature",
    Save = false,
    Callback = function(value)
        print("Toggle changed:", value)
        AutoFarm = value
    end,
})

task.spawn(function ()
    while wait(1) do 
        if AutoFarm then 
            for i, v in pairs(workspace.ItemSpawners:GetChildren()) do
                if v.Name == "Cosmic" then
                    for q, w in pairs(v:GetChildren()) do

                        Character:PivotTo(CFrame.new(29, 3, 6125))
                        task.wait(1)

                        Character:PivotTo(CFrame.new(w.WorldPivot.Position))

                        local Mesh = w:FindFirstChildWhichIsA("MeshPart")
                        if Mesh then
                            local Prompt = Mesh:FindFirstChildWhichIsA("ProximityPrompt")

                            if Prompt then
                                task.wait(0.5)
                                fireproximityprompt(Prompt)
                                task.wait(0.5)

                                Character:PivotTo(CFrame.new(6, 3, -112))
                                task.wait(1)
                            else
                                print("No Prompt")
                            end
                        else
                            print("No Mesh")
                        end
                    end
                end
            end
        end
    end
end)

Farmsection:CreateSlider({
    Name = "Place delay",
    Min = 1,
    Max = 1000,
    CurrentValue = 5,
    Rounding = 1,
    Flag = "SpeedValue",
    Save = true,
    Callback = function(value)
        print("Slider value:", value)
        Delay = value
    end,
})

Farmsection:CreateToggle({
    Name = "Auto Place Best",
    CurrentValue = false,
    Flag = "MyFeature",
    Save = false,
    Callback = function(value)
        print("Toggle changed:", value)
        AutoPlaceBest = value
    end,
})

task.spawn(function()
    while wait(Delay) do
        if AutoPlaceBest then
            local Event = game:GetService("ReplicatedStorage").Remotes.PlaceBestRequested
            Event:FireServer()
        end
    end
end)
