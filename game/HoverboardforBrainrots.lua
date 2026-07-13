local CyberUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/datfiete/Void-Hub/main/CyberUI/load.lua"))()

local window = CyberUI:CreateWindow({
    Name = "Hoverboard for Brainrots!",
    Title = "Hoverboard for Brainrots! Script",
    Subtitle = "by fietewoozle",
    Size = Vector2.new(700, 500),
    Center = true,
    ToggleKey = Enum.KeyCode.RightControl,
})

local Farmtab = window:CreateTab("Farm")
local Farmsection = Farmtab:CreateSection("Auto Farm")

local rootPart = game.Players.LocalPlayer.Character:WaitForChild("HumanoidRootPart")
local player = game.Players.LocalPlayer
local Character = player.Character or player.CharacterAdded:Wait()

local Rarityies = {"Secret", "Yur"}
local AutoFarm = false

local function isInTable(value, tbl)
    for _, v in ipairs(tbl) do
        if v == value then
            return true
        end
    end
    return false
end

local function getCharacter()
    return player.Character
end

local function dumpTable(t, indent)
    indent = indent or 0
    local prefix = string.rep("  ", indent)

    for k, v in pairs(t) do
        if type(v) == "table" then
            print(prefix .. tostring(k) .. ":")
            dumpTable(v, indent + 1)
        else
            print(prefix .. tostring(k) .. " = " .. tostring(v))
        end
    end
end


Farmsection:CreateDropdown({
    Name = "Auto Farm Rarity",
    Options = (function()
        local t = {}
        for _, v in ipairs(workspace.SpawnedFolder:GetChildren()) do
            table.insert(t, v.Name)
        end
        return t
    end)(),

    CurrentOption = "Secret", -- ensure it exists
    MultipleOptions = true,
    Flag = "AutoFarmRarity",
    Save = true,

    Callback = function(value)
        Rarityies = value
        print("Selected:", table.concat(value, ", "))
    end,
})

Farmsection:CreateToggle({
    Name = "Auto Farm",
    CurrentValue = false,
    Flag = "MyFeature",
    Save = false,
    Callback = function(value)
        print("Toggle changed:", value)
        AutoFarm = value
    end,
})

task.spawn(function ()
    while task.wait(0.5) do 
        if AutoFarm then
            for i, v in pairs(workspace.SpawnedFolder:GetChildren()) do 
                if isInTable(v.Name, Rarityies) then 
                    print("Found object:", v.Name)
                    Character:PivotTo(CFrame.new(486, 2153, -310))
                    task.wait(0.2)
                    for q, e in pairs(v:GetChildren()) do 
                        getCharacter()
                        Character:PivotTo(CFrame.new(e.WorldPivot.Position))
                        local Mesh = e:FindFirstChildOfClass("MeshPart")
                        local Prompt = Mesh:FindFirstChildOfClass("ProximityPrompt")
                        if Mesh and Prompt then 
                            task.wait(0.2)
                            fireproximityprompt(Prompt)
                            task.wait(0.2)
                            Character:PivotTo(CFrame.new(453, 1605, 1536))
                            task.wait(0.2)
                        end
                    end
                end
            end
        end
    end
end)
