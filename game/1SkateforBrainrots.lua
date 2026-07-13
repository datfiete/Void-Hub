local CyberUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/datfiete/Void-Hub/main/CyberUI/load.lua"))()

local window = CyberUI:CreateWindow({
    Name = "+1 Skate for Brainrots",
    Title = "+1 Skate for Brainrots",
    Subtitle = "by fietewoozle",
    Size = Vector2.new(760, 620),
    ToggleKey = Enum.KeyCode.RightControl,
})

local Farm = window:CreateTab("Farm")
local AutoFarmSection = Farm:CreateSection("Auto Farm")
local CollectMoneySection = Farm:CreateSection("Collect Money")

-- Services & Variables
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")

local plotName = "Plot_" .. player.Name
local YouPlot = workspace:FindFirstChild(plotName)
print(YouPlot)

local AutoFarm = false
local RaritySelect = {"Common"}
local AutoCollectMoney = false
local CollectMoneyDelay = 5


player.CharacterAdded:Connect(function(newChar)
    character = newChar
    rootPart = newChar:WaitForChild("HumanoidRootPart")
    humanoid = newChar:WaitForChild("Humanoid")
end)

local function isInTable(value, tbl)
    for _, v in ipairs(tbl) do
        if v == value then
            return true
        end
    end
    return false
end

AutoFarmSection:CreateDropdown({
    Name = "Rarity to Only Farm",
    Options = {"Common", "Exclusive", "Secret", "Godly", "Mythical"},
    CurrentOption = {"Exclusive"},
    Default = {"Exclusive"},
    MultipleOptions = true,
    Flag = "RarityDropdownFlag",
    Save = true,
    Callback = function(value)
        SelectedRarities = typeof(value) == "table" and value or {value}
        print("Rarities:", table.concat(SelectedRarities, ", "))
    end,
})

AutoFarmSection:CreateToggle({
    Name = "Auto Farm",
    CurrentValue = false,
    Flag = "AutoFarmToggleFlag",
    Callback = function(value)
        AutoFarm = value
        print("Auto Farm:", value and "ENABLED" or "DISABLED")
    end,
})

-- ==================== MAIN LOOP ====================
task.spawn(function()
    while task.wait(1) do
        if not AutoFarm then continue end
        if not rootPart or humanoid.Health <= 0 then continue end

        rootPart.CFrame = CFrame.new(5, 3296, 2334)
        task.wait(1.2)

        local folder = workspace.ItemSpawns:FindFirstChild("11")
        if not folder then continue end

        for _, model in ipairs(folder:GetChildren()) do
            if not AutoFarm then break end
            if not model:IsA("Model") then continue end

            local rarity = model:GetAttribute("Rarity")
            if not isInTable(rarity, SelectedRarities) then continue end

            local promptPart = model:FindFirstChild("Part") or model:FindFirstChildWhichIsA("BasePart")
            local prompt = promptPart and promptPart:FindFirstChildWhichIsA("ProximityPrompt")

            if prompt then
                print("→ Targeting:", model.Name, "| Rarity:", rarity)

                -- Better targeting method
                local targetPos = model:GetPivot().Position + Vector3.new(0, 5, 0)
                
                rootPart.CFrame = CFrame.new(targetPos)
                task.wait(0.4)

                -- Extra safety: make sure we're close
                if (rootPart.Position - targetPos).Magnitude > 15 then
                    rootPart.CFrame = CFrame.new(targetPos)
                    task.wait(0.3)
                end

                fireproximityprompt(prompt, 0)
                task.wait(0.3)

                -- Optional small cooldown
                rootPart.CFrame = CFrame.new(-84, 3, -75)
                task.wait(0.25)
            end
        end

        rootPart.CFrame = CFrame.new(-84, 3, -75)
    end
end)

CollectMoneySection:CreateSlider({
    Name = "Collect Money Delay",
    Min = 0,
    Max = 200,
    CurrentValue = 5,
    Rounding = 1,
    Flag = "CollectMoneyDelaySliderFlag",
    Save = true,
    Callback = function(value)
        print("Slider value:", value)
        CollectMoneyDelay = value
    end,
})

CollectMoneySection:CreateToggle({
    Name = "Auto Collect Money",
    CurrentValue = false,
    Default = false,
    Flag = "AutoCollectMoneyToggleFlag",
    Save = true,
    Callback = function(value)
        print("Toggle changed:", value)
        AutoCollectMoney = value
    end,
})

task.spawn(function ()
    while task.wait(CollectMoneyDelay) do 
        if AutoCollectMoney then 
            for i, v in pairs(YouPlot:GetChildren()) do 
                if v:FindFirstChild("Slots") then
                    local Ch1 = v:FindFirstChild("Slots")
                    for x, z in pairs(Ch1:GetChildren()) do 
                        if z:FindFirstChild("CollectTouch") then
                            local Ch2 = z:FindFirstChild("CollectTouch")
                            if Ch2:FindFirstChild("TouchInterest") then
                                local Ch3 = Ch2:FindFirstChild("TouchInterest")
                                firetouchinterest(rootPart, Ch2, 0)
                                task.wait(0.01)
                                firetouchinterest(rootPart, Ch2, 1)
                            end
                        end
                    end
                end
            end
        end
    end
end)
