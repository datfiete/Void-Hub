local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Cut Grass for Anime",
    Icon = 0,
    LoadingTitle = "Cut Grass for Anime script",
    LoadingSubtitle = "by Datfeite",
    ShowText = "Cut Grass for Anime",
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

local TokenFarmEnabled = false
local Player = game.Players.LocalPlayer

local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local RootPart = Character:WaitForChild("HumanoidRootPart")

local AutoCollect = false
local AutoCollectTeleport = false
local plotsFolder = workspace:WaitForChild("Plots")
local specificPlot = plotsFolder:WaitForChild("7328503147")
local brainrotSlots = specificPlot:WaitForChild("BrainrotSlots")
local MadiumAutoCollect = false
local EquipBestCharacter = false
local TeleportZones = {"Green"}
local SelectedCharacter = nil
local Geteverycharacter = false


local PlatFormsCoordinates = {
    Green  = workspace:FindFirstChild("GrassZones") and workspace.GrassZones:FindFirstChild("Green") and workspace.GrassZones.Green:FindFirstChild("Part"),
    Blue   = workspace:FindFirstChild("GrassZones") and workspace.GrassZones:FindFirstChild("Blue") and workspace.GrassZones.Blue:FindFirstChild("Part"),
    Purple = workspace:FindFirstChild("GrassZones") and workspace.GrassZones:FindFirstChild("Purple") and workspace.GrassZones.Purple:FindFirstChild("Part"),
    Yellow = workspace:FindFirstChild("GrassZones") and workspace.GrassZones:FindFirstChild("Yellow") and workspace.GrassZones.Yellow:FindFirstChild("Part"),
    Red    = workspace:FindFirstChild("GrassZones") and workspace.GrassZones:FindFirstChild("Red") and workspace.GrassZones.Red:FindFirstChild("Part"),
    DarkPurple = workspace:FindFirstChild("GrassZones") and workspace.GrassZones:FindFirstChild("DarkPurple") and workspace.GrassZones.DarkPurple:FindFirstChild("Part"),
    WhiteBlack = workspace:FindFirstChild("GrassZones") and workspace.GrassZones:FindFirstChild("WhiteBlack") and workspace.GrassZones.WhiteBlack:FindFirstChild("Part"),
}

local SelectedPlatforms = {"Green"}

local PlatformColors = {}
for color, _ in pairs(PlatFormsCoordinates) do
    table.insert(PlatformColors, color)
end
table.sort(PlatformColors)


local function GetTokenPosition(obj)
    if not obj then return nil end

    if obj:IsA("BasePart") then
        return obj.Position
    end

    if obj:IsA("Model") then
        return obj:GetPivot().Position
    end

    -- fallback: search inside
    local part = obj:FindFirstChildWhichIsA("BasePart", true)
    if part then
        return part.Position
    end

    return nil
end

local function GetCharacterNames()
    local Names = {}

    for _, Char in ipairs(workspace.AvailableCharacters:GetChildren()) do
        table.insert(Names, Char.Name)
    end

    return Names
end

local function FindCharacterByName(Name)
    for _, Char in ipairs(workspace.AvailableCharacters:GetChildren()) do
        if Char.Name == Name then
            return Char
        end
    end

    return nil
end

local CharacterNames = GetCharacterNames()

if #CharacterNames > 0 then
    SelectedCharacter = FindCharacterByName(CharacterNames[1])
end

CharacterDropdown = MainTab:CreateDropdown({
    Name = "Characters",
    Options = CharacterNames,
    CurrentOption = #CharacterNames > 0 and {CharacterNames[1]} or {},
    MultipleOptions = false,
    Flag = "CharacterDropdown",

    Callback = function(Option)
        local SelectedName = Option[1]
        SelectedCharacter = FindCharacterByName(SelectedName)

        if SelectedCharacter then
            print("Selected:", SelectedCharacter.Name)
        end
    end,
})

MainTab:CreateButton({
    Name = "Refresh Character List",
    Callback = function()
        local NewNames = GetCharacterNames()

        CharacterDropdown:Refresh(NewNames)

        if #NewNames > 0 then
            SelectedCharacter = FindCharacterByName(NewNames[1])
        end

        print("Character list refreshed.")

        for _, Name in ipairs(NewNames) do
            print(Name)
        end
    end,
})

MainTab:CreateButton({
    Name = "Teleport To Selected Character",
    Callback = function()
        if not SelectedCharacter then
            warn("No character selected.")
            return
        end

        RootPart.CFrame = SelectedCharacter:GetPivot() * CFrame.new(0, 5, 0)
    end,
})

DevTab:CreateToggle({
    Name = "Auto Teleport To Token",
    CurrentValue = false,
    Flag = "AutoTeleportToken",

    Callback = function(Value)
        TokenFarmEnabled = Value

        if Value then
            task.spawn(function()
                while TokenFarmEnabled do
                    local token = workspace:FindFirstChild("LocalTokenSpawnTelegraph")

                    if token then
                        -- refresh character safety (important if you respawn)
                        local char = game.Players.LocalPlayer.Character
                        local root = char and char:FindFirstChild("HumanoidRootPart")

                        local pos = GetTokenPosition(token)

                        if root and pos then
                            root.CFrame = CFrame.new(pos + Vector3.new(0, 2, 0))
                        end
                    end

                    task.wait(2)
                end
            end)
        end
    end,
})

local Toggle = DevTab:CreateToggle({
   Name = "Auto Collect Cash",
   CurrentValue = false,
   Flag = "AutoCollectCashToggle1",
   Callback = function(sdafgsagsdg)
    AutoCollect = sdafgsagsdg
   end,
})

task.spawn(function()
    while true do
        if AutoCollect then
            for _, slot in ipairs(brainrotSlots:GetChildren()) do
                if slot:IsA("Model") or slot:IsA("Folder") then  -- Adjust if needed based on slot type
                    local success, err = pcall(function()
                        local cashButton = slot:FindFirstChild("CashButton")
                        if cashButton then
                            local touchPart = cashButton:GetChildren()[3]  -- Assuming this is still the correct index
                            if touchPart and touchPart:IsA("BasePart") then
                                firetouchinterest(game.Players.LocalPlayer.Character:WaitForChild("HumanoidRootPart"), touchPart, 0)
                                wait(0.05)  -- Small delay between touch events
                                firetouchinterest(game.Players.LocalPlayer.Character:WaitForChild("HumanoidRootPart"), touchPart, 1)
                            end
                        end
                    end)

                    if not success then
                        warn("Error collecting from slot " .. slot.Name .. ":", err)
                    end
                end
            end
        end

        wait(5)  -- Main loop delay (adjust as needed)
    end
end)

local Toggle = DevTab:CreateToggle({
    Name = "Auto Collect Cash Teleport",
    CurrentValue = false,
    Flag = "AutoCollectCashTeleportToggle1",
    Callback = function(value)
        AutoCollectTeleport = value
    end,
})

task.spawn(function()
    while true do 
        if AutoCollectTeleport then 
            for _, slot in ipairs(brainrotSlots:GetChildren()) do
                if slot:IsA("Model") or slot:IsA("Folder") then  -- Adjust if needed based on slot type
                    local success, err = pcall(function()
                        local cashButton = slot:FindFirstChild("CashButton")
                        if cashButton then
                            local touchPart = cashButton:GetChildren()[3]  -- Assuming this is still the correct index
                            if touchPart and touchPart:IsA("BasePart") then
                                RootPart.CFrame = touchPart.CFrame + Vector3.new(0, 2, 0)  -- Teleport above the button
                                wait(0.1)  -- Small delay to ensure teleportation before touching
                                firetouchinterest(game.Players.LocalPlayer.Character:WaitForChild("HumanoidRootPart"), touchPart, 0)
                                wait(0.05)  -- Small delay between touch events
                                firetouchinterest(game.Players.LocalPlayer.Character:WaitForChild("HumanoidRootPart"), touchPart, 1)
                            end
                        end
                    end)

                    if not success then
                        warn("Error collecting from slot " .. slot.Name .. ":", err)
                    end
                end
            end
        end
        task.wait(5)  -- Main loop delay (adjust as needed)
    end
end
)

local Toggle = MainTab:CreateToggle({
   Name = "Madium Auto Collect",
   CurrentValue = false,
   Flag = "MadiumAutoCollectToggle1", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   Callback = function(MadiumAutoCollectToggle1)
   MadiumAutoCollect = MadiumAutoCollectToggle1
   end,
})

task.spawn(function()
    while true do
        if MadiumAutoCollect then
            for i = 1, 20 do  
                local Event = game:GetService("ReplicatedStorage").Remotes.GamestateEvent
                Event:FireServer(
                    "ClaimCharacterCash",
                    i
                )
                task.wait(0.25)
            end
        end
    task.wait(5)
    end
end
)

local Toggle = MainTab:CreateToggle({
   Name = "Equip Best Character",
   CurrentValue = false,
   Flag = "EquipBestCharacterToggle1", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   Callback = function(EquipBestCharacterToggle1)
   EquipBestCharacter = EquipBestCharacterToggle1
   end,
})

task.spawn(function()
    while true do
        if EquipBestCharacter then
            local Event = game:GetService("ReplicatedStorage").Remotes.GamestateEvent
            Event:FireServer(
                "EquipBestBrainrots"
            )
            print("equipped best character")
        end
    task.wait(10)
    end
end)

local Dropdown = MainTab:CreateDropdown({
   Name = "Teleport to",
   Options = {"Green", "Blue", "Purple", "Yellow", "Red", "DarkPurple", "WhiteBlack"},
   CurrentOption = {"Green"},
   MultipleOptions = false,
   Flag = "TeleporttoDropdown1", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   Callback = function(TeleporttoDropdown1)
    TeleportZones = TeleporttoDropdown1
   end,
})

local Button = MainTab:CreateButton({
    Name = "Teleport",
    Callback = function()
        local zoneName = TeleportZones and TeleportZones[1]
        if not zoneName then
            warn("No teleport zone selected")
            return
        end

        local grassZones = workspace:FindFirstChild("GrassZones")
        if not grassZones then
            warn("GrassZones not found")
            return
        end

        local zone = grassZones:FindFirstChild(zoneName)
        if not zone then
            warn("Zone not found: " .. tostring(zoneName))
            return
        end

        local part = zone:FindFirstChild("Part")
        if not (part and part:IsA("BasePart")) then
            warn("Part not found for " .. zoneName)
            return
        end

        local character = game.Players.LocalPlayer.Character
        if not character then
            warn("Character not loaded")
            return
        end

        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if not rootPart then
            warn("HumanoidRootPart not found")
            return
        end

        rootPart.CFrame = part.CFrame + Vector3.new(0, 5, 0)
        print("Teleported to " .. zoneName)
    end
})

local Dropdown = DevTab:CreateDropdown({
   Name = "Get Specific Area",
   Options = {"Green", "Blue", "Purple", "Yellow", "Red", "DarkPurple", "WhiteBlack"},
   CurrentOption = {"Green"},
   MultipleOptions = false,           -- ← Changed to single
   Flag = "Dropdown_PlatformArea",
   Callback = function(SelectedOptions)
       SelectedPlatforms = SelectedOptions  -- Will be a table with 1 item
       print("Selected Platform Updated:", table.concat(SelectedOptions, ", "))
   end,
})

local Toggle = DevTab:CreateToggle({
   Name = "Get every character",
   CurrentValue = false,
   Flag = "GeteverycharacterToggle1", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   Callback = function(GeteverycharacterToggle1)
    Geteverycharacter = GeteverycharacterToggle1
   end,
})

local function GetPlatformFromPosition(pos)
    if not pos then return nil end
    local grassZones = workspace:FindFirstChild("GrassZones")
    if not grassZones then return nil end
    
    for _, color in ipairs({"Green", "Blue", "Purple", "Yellow", "Red", "DarkPurple", "WhiteBlack"}) do
        local zone = grassZones:FindFirstChild(color)
        local part = zone and zone:FindFirstChild("Part")
        if part then
            local posPart = part.Position
            local size = part.Size
            if math.abs(pos.X - posPart.X) < size.X/2 + 50 and
               math.abs(pos.Y - posPart.Y) < size.Y/2 + 50 and
               math.abs(pos.Z - posPart.Z) < size.Z/2 + 50 then
                return color
            end
        end
    end
    return nil
end

local function FindBestCharacter()
    local bestChar = nil
    local bestValue = -1
    local candidates = 0
    
    print("🔍 Scanning for characters in selected area:", table.concat(SelectedPlatforms, ", "))
    
    for _, v in pairs(workspace.AvailableCharacters:GetChildren()) do
        local wholePart = v:FindFirstChild("WholePart")
        if not wholePart or not wholePart.Parent then continue end
        
        local currentPos = wholePart.Position
        local platform = GetPlatformFromPosition(currentPos)
        
        local isSelectedArea = false
        for _, selected in ipairs(SelectedPlatforms) do
            if selected == platform then
                isSelectedArea = true
                break
            end
        end
        
        if isSelectedArea then
            candidates += 1
            
            -- Safe MoneyPerSec reading (handles both Value and TextLabel)
            local moneyPerSec = 0
            local brainrotInfo = v:FindFirstChild("BrainrotInfo")
            if brainrotInfo then
                local content = brainrotInfo:FindFirstChild("Content")
                if content then
                    local mps = content:FindFirstChild("MoneyPerSec")
                    if mps then
                        if mps:IsA("NumberValue") or mps:IsA("IntValue") then
                            moneyPerSec = mps.Value
                        elseif mps:IsA("TextLabel") then
                            -- Extract number from text like "$20,943/s"
                            local numStr = mps.Text:gsub("[^%d]", "")  -- remove non-digits
                            moneyPerSec = tonumber(numStr) or 0
                        end
                    end
                end
            end
            
            print(string.format("   → %s | Platform: %s | $/s: %d", v.Name, platform or "Unknown", moneyPerSec))
            
            if moneyPerSec > bestValue then
                bestValue = moneyPerSec
                bestChar = v
            end
        end
    end
    
    print("📊 Scan complete. Candidates:", candidates, "| Best:", bestChar and bestChar.Name or "None")
    return bestChar, bestValue
end

-- Main farming loop
task.spawn(function()
    while true do 
        if Geteverycharacter and #SelectedPlatforms > 0 then 
            
            -- Zone preparation
            print("=== Preparing areas ===")
            for _, selectedColor in ipairs(SelectedPlatforms) do
                local zonePart = PlatFormsCoordinates[selectedColor]
                if zonePart and zonePart:IsA("BasePart") then
                    RootPart.CFrame = zonePart.CFrame * CFrame.new(0, 12, 0)
                    print("Teleported to:", selectedColor)
                    task.wait(1.5)
                end
            end
            
            -- Find best
            local bestCharacter, bestValue = FindBestCharacter()
            
            if bestCharacter then
                local wholePart = bestCharacter:FindFirstChild("WholePart")
                local Back = workspace.Map.Comeback:FindFirstChild("ComebackPart")
                
                if wholePart and Back then
                    print("🎯 Collecting Best:", bestCharacter.Name, "| $/s:", bestValue)
                    
                    RootPart.CFrame = wholePart.CFrame * CFrame.new(0, 8, 0)
                    task.wait(0.25)
                    
                    game:GetService("VirtualInputManager"):SendKeyEvent(true, Enum.KeyCode.E, false, game)
                    task.wait(0.7)
                    game:GetService("VirtualInputManager"):SendKeyEvent(false, Enum.KeyCode.E, false, game)
                    task.wait(0.2)
                    
                    RootPart.CFrame = Back.CFrame + Vector3.new(70, 0, 0)
                    task.wait(0.25)
                    
                    for _, key in ipairs({Enum.KeyCode.D, Enum.KeyCode.S, Enum.KeyCode.A, Enum.KeyCode.W}) do
                        game:GetService("VirtualInputManager"):SendKeyEvent(true, key, false, game)
                        task.wait(0.18)
                        game:GetService("VirtualInputManager"):SendKeyEvent(false, key, false, game)
                        task.wait(0.08)
                    end
                end
            else
                print("⚠️ No valid characters found in selected areas")
            end
        end
        task.wait(0.5)
    end
end)
