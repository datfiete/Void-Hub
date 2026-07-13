local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Build Bridge For Brainrot",
    Icon = 0,
    LoadingTitle = "Build Bridge For Brainrot script",
    LoadingSubtitle = "by Datfeite",
    ShowText = "Build Bridge For Brainrot",
    Theme = "Default",

    ToggleUIKeybind = "K",

    DisableRayfieldPrompts = false,
    DisableBuildWarnings = false,

    ConfigurationSaving = {
        Enabled = false,
        FolderName = nil,
        FileName = "Big Hub"
    },

    Discord = {
        Enabled = false,
        Invite = "noinvitelink",
        RememberJoins = true
    },

    KeySystem = false,
    KeySettings = {
        Title = "Untitled",
        Subtitle = "Key System",
        Note = "No method of obtaining the key is provided",
        FileName = "Key",
        SaveKey = true,
        GrabKeyFromSite = false,
        Key = {"Hello"}
    }
})

local MainTab = Window:CreateTab("Main", 4483362458)
local FarmTab = Window:CreateTab("Farm", 4483362458)
local DevTab = Window:CreateTab("Developer", 4483362458)

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HRP = Character:WaitForChild("HumanoidRootPart")


local function getBase()
    for _, v in ipairs(workspace.Bases:GetChildren()) do
        local owner = v:GetAttribute("Owner")

        if owner == Player.Name then
            return v
        end
    end
    return nil
end

local YourBase = getBase()

while not YourBase do
    task.wait(0.5)
    YourBase = getBase()
end

print("Final:", YourBase.Name)

local char = game.Players.LocalPlayer.Character
local hrp = char and char:FindFirstChild("HumanoidRootPart")
if not hrp then return end


local Brainrots = workspace:WaitForChild("Brainrots")

local AutoGetOGGod = false
local AutoCollectPlotMoney = false
local AutoCollectGroundMoney = false

-- Update target function
local function getNearestTarget()
    local nearest = nil
    local nearestDist = math.huge

    for _, v in ipairs(Brainrots:GetChildren()) do
        if v:GetAttribute("RarityType") == "God" or v:GetAttribute("RarityType") == "OG" then
            local part = v:FindFirstChildWhichIsA("BasePart")
            if part and part:FindFirstChild("PickupPrompt") then
                local dist = (HRP.Position - part.Position).Magnitude
                if dist < nearestDist then
                    nearestDist = dist
                    nearest = part
                end
            end
        end
    end

    return nearest
end

-- Toggle
MainTab:CreateToggle({
    Name = "Auto Get God/OG",
    CurrentValue = false,
    Flag = "AutoGetGodandOGToggle1",
    Callback = function(Value)
        AutoGetOGGod = Value
    end,
})

-- Main loop
task.spawn(function()
    while true do
        if AutoGetOGGod then
            -- Refresh character references
            if not Character or not Character.Parent or not HRP or not HRP.Parent then
                Character = Player.Character or Player.CharacterAdded:Wait()
                Humanoid = Character:WaitForChild("Humanoid")
                HRP = Character:WaitForChild("HumanoidRootPart")
            end

            local target = getNearestTarget()

            if target then
                -- Teleport to the brainrot
                HRP.CFrame = CFrame.new(target.Position + Vector3.new(0, 3, 0))
                task.wait(0.3)

                -- Fire prompt
                local prompt = target:FindFirstChild("PickupPrompt")
                if prompt then
                    fireproximityprompt(prompt)
                end

                task.wait(0.6)

                -- Return to safe position
                Character:MoveTo(Vector3.new(-169, 12, -115))
                task.wait(1.5) -- Give time to actually move back
            end
        end
        task.wait(0.8) -- Main loop delay
    end
end)

local Toggle = MainTab:CreateToggle({
   Name = "Auto Collect Money",
   CurrentValue = false,
   Flag = "AutoCollectMoneyToggle1", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   Callback = function(AutoCollectMoneyToggle1)
    AutoCollectPlotMoney = AutoCollectMoneyToggle1 
   end,
})

task.spawn(function()
    while true do 
        if AutoCollectPlotMoney then 

            local base = getBase()
            if base then

                for floorIndex = 1, 10 do
                    local floor = base:FindFirstChild("Floor" .. floorIndex)

                    if floor and floor:FindFirstChild("Platforms") then
                        local platforms = floor.Platforms:GetChildren()

                        for i = 1, #platforms do
                            local collect = platforms[i]:FindFirstChild("Collect")

                            if collect then
                                firetouchinterest(hrp, collect, 0)
                                task.wait(0.1)
                                firetouchinterest(hrp, collect, 1)
                            end
                        end
                    end
                end
            end
        end

        task.wait(5)
    end
end)

local Toggle = MainTab:CreateToggle({
   Name = "Collect Money on ground",
   CurrentValue = false,
   Callback = function(Value)
    AutoCollectGroundMoney = Value
   end,
})
task.spawn(function()
    while true do 
        if AutoCollectGroundMoney then 
            for _, v in pairs(workspace.Cash:GetChildren()) do
                if v:IsA("MeshPart") then
                    local touch = v:FindFirstChildWhichIsA("TouchTransmitter")

                    if touch then
                        firetouchinterest(HRP, v, 0)
                        task.wait(0.1)
                        firetouchinterest(HRP, v, 1)
                    end
                end
            end
        end

        task.wait(5)
    end
end)
