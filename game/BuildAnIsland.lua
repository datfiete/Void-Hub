local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local RootPart = Character:WaitForChild("HumanoidRootPart")
local Executor = getexecutorname()
local VirtualInputManager = game:GetService("VirtualInputManager")

local Avatar = Players:GetUserThumbnailAsync(
    Player.UserId,
    Enum.ThumbnailType.HeadShot,
    Enum.ThumbnailSize.Size150x150
)

local CyberUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/datfiete/Void-Hub/main/CyberUI/load.lua"))()

CyberUI.Theme.Style = "Meng"

local window = CyberUI:CreateWindow({
    Title = "Build An Island! 🏝️",
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

local function isInTable(value, tbl)
    for _, v in ipairs(tbl) do
        if v == value then
            return true
        end
    end
    return false
end


-- ==================== DYNAMISCHE MATERIAL SAMMLUNG ====================
local function GetAllUniqueMaterials()
    local uniqueMats = {}
    local landFolder = workspace:FindFirstChild("Plots", true) 
                     and workspace.Plots:FindFirstChild("totehosenn") 
                     and workspace.Plots.totehosenn:FindFirstChild("Land")
    
    if not landFolder then
        warn("Land Folder nicht gefunden!")
        return {"Log", "Stone"} -- Fallback
    end

    for _, plot in ipairs(landFolder:GetChildren()) do
        -- Nur Plots wie S10, S108, S25 etc. berücksichtigen
        if plot.Name:match("^S%d") then
            local unlocks = plot:FindFirstChild("Unlocks")
            if unlocks then
                for _, unlockChild in ipairs(unlocks:GetChildren()) do
                    -- Gehe in die Kinder (wie [3] bei S10)
                    for _, mat in ipairs(unlockChild:GetChildren()) do
                        local name = mat.Name
                        if name and not uniqueMats[name] then
                            uniqueMats[name] = true
                        end
                    end
                end
            end
        end
    end

    local materialList = {}
    for matName, _ in pairs(uniqueMats) do
        table.insert(materialList, matName)
    end

    -- Alphabetisch sortieren (optional, sieht schöner aus)
    table.sort(materialList)
    
    return materialList
end

local AllMaterials = GetAllUniqueMaterials()

print("Gefundene einzigartige Materialien:", AllMaterials)

-- ==================== UI ====================
local Farmtab = window:CreateTab("Farm")
local Farmsection = Farmtab:CreateSection("Auto Farm")

local ToAutoFarm = {"Log"}
local AutoFarmMats = false

Farmsection:CreateDropdown({
    Name = "Auto Farm Material",
    Options = AllMaterials,
    CurrentOption = AllMaterials[1] or "Log",
    MultipleOptions = false,
    Flag = "AutoFarmMaterial",
    Save = true,
    Callback = function(value)
        print("Ausgewähltes Material:", value)
        ToAutoFarm = {value}  -- Für späteren Farm-Code
    end,
})

Farmsection:CreateToggle({
    Name = "Auto Farm selected Material",
    CurrentValue = false,
    Flag = "MyFeature",
    Save = false,
    Callback = function(value)
        print("Toggle changed:", value)
        AutoFarmMats = value
    end,
})

task.spawn(function ()
    while task.wait(1) do 
        if AutoFarmMats then 
            for i, v in pairs(workspace.Plots.totehosenn.Resources:GetChildren()) do 
                if isInTable(v:GetAttribute("Gain"), ToAutoFarm) and v:GetAttribute("HP") ~= 0 then 
                    Character:MoveTo(v.WorldPivot.Position + Vector3.new(3, -3, 0))
                    while v:GetAttribute("HP") ~= 0 do 
                        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
                        task.wait(0.07)
                        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
                        task.wait(0.1)
                    end
                end
            end
        end
    end
end)
