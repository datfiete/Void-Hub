local CyberUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/fietewoozle-dot/MyHub/main/CyberUI/load.lua"))()

local window = CyberUI:CreateWindow({
    Name = "+1 Speed Evolve 🦊 [UPD 6]",
    Title = "+1 Speed Evolve 🦊 [UPD 6] Script",
    Subtitle = "by fietewoozle",
    Size = Vector2.new(700, 500),
    Center = true,
    ToggleKey = Enum.KeyCode.RightControl,
})

local Event = game:GetService("ReplicatedStorage").Modules.Shared.RemoteEventService.TreadmillRemoteEvent
firesignal(Event.OnClientEvent, 
    workspace.Treadmills:GetChildren()[36]
)

local Farmtab = window:CreateTab("Farm")
local Farmsection = Farmtab:CreateSection("Auto Farm")

local rootPart = game.Players.LocalPlayer.Character:WaitForChild("HumanoidRootPart")
local player = game.Players.LocalPlayer
local Character = player.Character or player.CharacterAdded:Wait()

local AutoWalk = false
local AutoEvolve = false
local AutoRebirth = false
local AutoWinStage = "14"
local AutoWins = false


Farmsection:CreateToggle({
    Name = "Auto gain walk speed",
    CurrentValue = false,
    Save = true,
    Callback = function(value)
        print("Toggle changed:", value)
        AutoWalk = value
    end,
})

task.spawn(function ()
    while task.wait(0.01) do 
        if AutoWalk then
            local Event = game:GetService("ReplicatedStorage").Modules.Shared.RemoteEventService.AddSpeedRemoteEvent
            Event:FireServer()
        end
    end
end)

Farmsection:CreateToggle({
    Name = "Auto Evolve",
    CurrentValue = false,
    Flag = "MyFeature",
    Callback = function(value)
        print("Toggle changed:", value)
        AutoEvolve = value
    end,
})

task.spawn(function ()
    while task.wait(2) do 
        if AutoEvolve then
            local Event = game:GetService("ReplicatedStorage").Modules.Shared.RemoteEventService.EvolutionRemoteEvent
            Event:FireServer(
                {
                    Action = "Evolve"
                }
            )
        end
    end
end)

Farmsection:CreateToggle({
    Name = "Auto Rebirth",
    CurrentValue = false,
    Flag = "MyFeature",
    Callback = function(value)
        print("Toggle changed:", value)
        AutoRebirth = value
    end,
})

task.spawn(function ()
    while task.wait(2) do 
        if AutoRebirth then
            local Event = game:GetService("ReplicatedStorage").Modules.Shared.RemoteEventService.RebirthRemoteEvent
            Event:FireServer()
        end
    end
end)

Farmsection:CreateDropdown({
    Name = "Auto Win Stage",
    Options = {"1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14"},
    CurrentOption = "14",
    Flag = "GameMode",
    Save = true,
    Callback = function(value)
        print("Selected mode:", value)
        AutoWinStage = value
    end,
})

Farmsection:CreateToggle({
    Name = "Auto Wins",
    CurrentValue = false,
    Flag = "MyFeature",
    Callback = function(value)
        print("Toggle changed:", value)
        AutoWins = value
    end,
})

task.spawn(function ()
    while task.wait(1) do 
        if AutoWins then 
            local Thingi = workspace.Wins:FindFirstChild(AutoWinStage)
            if Thingi then 
                Character:PivotTo(CFrame.new(Thingi.WorldPivot.Position))
            end
        end
    end
end)
