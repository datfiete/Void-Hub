local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Drill Blocks for Brainrots",
    Icon = 0,
    LoadingTitle = "Drill Blocks for Brainrots script",
    LoadingSubtitle = "by Datfeite",
    ShowText = "Drill Blocks for Brainrots",
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
local DevTab = Window:CreateTab("Developer", 4483362458)

local Rarity = "Secret"
local AutoFarm = false

local Players = game:GetService("Players")
local player = Players.LocalPlayer

local function getCharacter()
    return player.Character or player.CharacterAdded:Wait()
end

-- Find all Items folders
local itemsFolders = {}

for _, obj in ipairs(workspace:GetDescendants()) do
    if obj:IsA("Folder") and obj.Name == "Items" then
        table.insert(itemsFolders, obj)
    end
end

-- Score folders
local function scoreFolder(folder)
    local score = 0

    for _, child in ipairs(folder:GetChildren()) do
        if child:IsA("Model") then
            local prompt = child:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt then
                score += 1
            end
        end
    end

    return score
end

-- Pick best folder
local bestFolder = nil
local bestScore = 0

for _, f in ipairs(itemsFolders) do
    local s = scoreFolder(f)
    if s > bestScore then
        bestScore = s
        bestFolder = f
    end
end

if not bestFolder then
    warn("No valid Items folder found")
    return
end

print("Using folder:", bestFolder:GetFullName())

local selectedRarities = {Secret = true}

local Dropdown = MainTab:CreateDropdown({
   Name = "Pick Rarity",
   Options = {"Eternal", "Transcendent", "Ancient", "Celestial", "OG", "Secret", "Divine", "Mythic", "Legendary", "Epic", "Rare", "Common"},
   CurrentOption = {"Secret"},
   MultipleOptions = true,
   Callback = function(Options)
        -- reset table
        selectedRarities = {}

        for _, v in ipairs(Options) do
            selectedRarities[v] = true
        end
   end,
})

-- 🔥 FUNCTION: check rarity
local function isAllowedRarity(item)
    local ok, rarity = pcall(function()

        local mesh = item:FindFirstChildWhichIsA("MeshPart", true)
            or item:FindFirstChildWhichIsA("Part", true)
            or item:FindFirstChildWhichIsA("UnionOperation", true)

        if not mesh then return nil end

        return mesh
            :FindFirstChild("ItemAttachment", true)
            .ItemGUI
            .Frame
            .Rarity
            .Text
    end)

    if not ok or type(rarity) ~= "string" then
        return false
    end

    for name, enabled in pairs(selectedRarities) do
        if enabled and string.find(rarity, name) then
            return true
        end
    end

    return false
end

local Toggle = MainTab:CreateToggle({
   Name = "Auto Farm",
   CurrentValue = false,
   Callback = function(Value)
    AutoFarm = Value
   end,
})

task.spawn(function ()
    while true do 
        if AutoFarm then 
            for _, v in ipairs(bestFolder:GetChildren()) do
                local Character = getCharacter()

                -- 🔥 FILTER: only Secret
                if not isAllowedRarity(v) then
                    continue
                end

                local pos
                if v:IsA("Model") then
                    pos = v:GetPivot().Position
                elseif v:IsA("BasePart") then
                    pos = v.Position
                end

                if pos then
                    Character:PivotTo(CFrame.new(pos + Vector3.new(0, 5, 0)))

                    local prompt = v:FindFirstChildWhichIsA("ProximityPrompt", true)

                    if prompt then
                        task.wait(1)
                        fireproximityprompt(prompt)
                        task.wait(1)

                        Character:PivotTo(workspace.Zones.SafeZone.CFrame)
                        task.wait(0.3)
                    end

                    task.wait(1)
                end
            end
        end
    task.wait(1)
    end
end)
