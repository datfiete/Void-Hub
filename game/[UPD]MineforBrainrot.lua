local CyberUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/fietewoozle-dot/MyHub/main/CyberUI/load.lua"))()

local window = CyberUI:CreateWindow({
    Name = "[UPD] Mine for Brainrot! ⛏️",
    Title = "[UPD] Mine for Brainrot! ⛏️ Script",
    Subtitle = "by fietewoozle",
    Size = Vector2.new(700, 500),
    Center = true,
    ToggleKey = Enum.KeyCode.RightControl,
})

local FarmTab = window:CreateTab("Farm")
local Farmsection = FarmTab:CreateSection("Farm")
local MovementSection = FarmTab:CreateSection("Movement")

local player = game.Players.LocalPlayer

--// STATE
local Options = {"Hacker"}
local AutoFarm = false
local FlyEnabled = false
local NoclipEnabled = false

---------------------------------------------------
--// CHARACTER SAFE ACCESS
---------------------------------------------------
local function getCharacter()
    return player.Character or player.CharacterAdded:Wait()
end

local function getRoot()
    local char = getCharacter()
    return char:WaitForChild("HumanoidRootPart")
end

---------------------------------------------------
--// TABLE CHECK
---------------------------------------------------
local function isInTable(value, tbl)
    for _, v in ipairs(tbl) do
        if v == value then
            return true
        end
    end
    return false
end

---------------------------------------------------
--// DROPDOWN
---------------------------------------------------
Farmsection:CreateDropdown({
    Name = "Farm Rarity",
    Options = {"Uncommon", "Common", "Rare", "Epic", "Legendary", "Mythic", "Hacker", "OG"},
    CurrentOption = "Hacker",
    MultipleOptions = true,
    Flag = "FarmRarity",
    Save = true,
    Callback = function(value)
        if typeof(value) == "table" then
            Options = value
        else
            Options = {value}
        end
    end,
})

---------------------------------------------------
--// AUTO FARM TOGGLE
---------------------------------------------------
Farmsection:CreateToggle({
    Name = "Auto Farm",
    CurrentValue = false,
    Flag = "AutoFarm",
    Save = true,
    Callback = function(value)
        AutoFarm = value
    end,
})

---------------------------------------------------
--// NOCLIP TOGGLE
---------------------------------------------------
MovementSection:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Flag = "Noclip",
    Save = true,
    Callback = function(value)
        NoclipEnabled = value

        task.spawn(function()
            game:GetService("RunService").Stepped:Connect(function()
                if not NoclipEnabled then return end

                local char = getCharacter()
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end)
        end)
    end,
})

---------------------------------------------------
--// AUTO FARM LOOP (OPTIMIZED)
---------------------------------------------------
task.spawn(function()
    while task.wait(1) do
        if AutoFarm then
            for _, model in pairs(workspace.LocalSpawnedBrainrots:GetChildren()) do

                local prompt = model:FindFirstChildWhichIsA("ProximityPrompt", true)
                local gui = model:FindFirstChildWhichIsA("BillboardGui", true)

                if prompt and gui then
                    local frame = gui:FindFirstChild("Frame")
                    local rarity = frame and frame:FindFirstChild("CharacterRarity")

                    if rarity and rarity:IsA("TextLabel") then
                        if isInTable(rarity.Text, Options) then
                            local char = getCharacter()

                            char:PivotTo(CFrame.new(model.WorldPivot.Position))
                            task.wait(1)

                            fireproximityprompt(prompt)

                            task.wait(0.2)
                            char:PivotTo(CFrame.new(-359, -9, -662))
                            task.wait(1)
                        end
                    end
                end
            end
        end
    end
end)
