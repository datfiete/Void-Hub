local CyberUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/fietewoozle-dot/MyHub/main/CyberUI/load.lua"))()

local window = CyberUI:CreateWindow({
    Name = "Roller for Brainrots script",
    Title = "Roller for Brainrots",
    Subtitle = "by fietewoozle",
    Size = Vector2.new(700, 500),
    Center = true,
    ToggleKey = Enum.KeyCode.RightControl,
})

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

local Farmtab = window:CreateTab("Farm")
local Farmsection = Farmtab:CreateSection("Auto Farm")

local Autofarm = false
local AutoMoney = false
local MoneyCollectDelay = 5

character:MoveTo(Vector3.new(-4, 1680, 4200))
task.wait(1)


local validNames = {
    ["Zone11.1"] = true,
    ["Zone11.2"] = true,
    ["Zone11.3"] = true,
    ["Zone11.4"] = true,
    ["Zone11.5"] = true,
}

-- Richtigen SpawnedBrainrots-Ordner finden
local spawnedBrainrots

for _, obj in ipairs(workspace:GetDescendants()) do
    if obj.Name == "SpawnedBrainrots" and obj:IsA("Folder") then
        for _, child in ipairs(obj:GetChildren()) do
            if validNames[child.Name] then
                spawnedBrainrots = obj
                break
            end
        end
        if spawnedBrainrots then
            break
        end
    end
end

if not spawnedBrainrots then
    warn("Kein gültiger SpawnedBrainrots-Ordner gefunden!")
    return
end

local zoneFolder = spawnedBrainrots:FindFirstChild("Zone11.1")

if not zoneFolder then
    warn("Could not find Zone11.1 folder!")
    return
end

character:MoveTo(Vector3.new(-1, 70, -79))

Farmsection:CreateToggle({
    Name = "Auto Brainrots",
    CurrentValue = false,
    Flag = "AutoBrainrotsMyFeature",
    Save = false,
    Callback = function(value)
        print("Toggle changed:", value)
        Autofarm = value
    end,
})

task.spawn(function()
    while task.wait(1) do 
        if Autofarm then 
            for _, x in ipairs(spawnedBrainrots:GetChildren()) do
                if validNames[x.Name] then
                    for _, v in ipairs(zoneFolder:GetDescendants()) do
                        if v:GetAttribute("ZoneName") == "Zone11.1" and v.PrimaryPart then
                            local proximityPrompt =
                                v.PrimaryPart:FindFirstChildOfClass("ProximityPrompt")

                            if proximityPrompt and Autofarm then
                                -- Zum Objekt teleportieren
                                humanoidRootPart:PivotTo(
                                    v.WorldPivot * CFrame.new(0, 5, 0)
                                )

                                task.wait(0.3)

                                -- Prompt auslösen
                                fireproximityprompt(proximityPrompt)
                                print("Activated prompt in:", v.Name)

                                task.wait(0.5)

                                character:MoveTo(Vector3.new(-1, 70, -79))
                                task.wait(0.5)
                            end
                        end
                    end
                end
            end
        end
    end
end)

Farmsection:CreateSlider({
    Name = "Money Collect Delay",
    Min = 1,
    Max = 1000,
    CurrentValue = 5,
    Rounding = 1,
    Save = true,
    Callback = function(value)
        print("Slider value:", value)
        MoneyCollectDelay = value
    end,
})

Farmsection:CreateToggle({
    Name = "Auto Money",
    CurrentValue = false,
    Save = false,
    Callback = function(value)
        print("Toggle changed:", value)
        AutoMoney = value
    end,
})

task.spawn(function ()
    while true do 
        if AutoMoney then 
            for _, plot in ipairs(workspace.Plots:GetChildren()) do
                if plot:GetAttribute("OccupiedByUserId") == player.UserId then
                    print("Found my plot:", plot.Name)

                    local slots = plot:FindFirstChild("Slots")
                    if not slots then return end

                    for _, slot in ipairs(slots:GetDescendants()) do
                        local cashButton = slot:FindFirstChild("CashButton")
                        if cashButton then
                            local floor = cashButton:FindFirstChild("CashButtonFloor")
                            if floor and floor:IsA("BasePart") then
                                firetouchinterest(humanoidRootPart, floor, 0)
                                task.wait()
                                firetouchinterest(humanoidRootPart, floor, 1)
                                task.wait(0.02)
                            end
                        end
                    end
                end
            end
        task.wait(MoneyCollectDelay - 1)
        end
    task.wait(1)
    end
end)
