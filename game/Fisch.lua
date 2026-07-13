local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Fisch Hub v1.4",
    LoadingTitle = "Fisch Hub",
    LoadingSubtitle = "by Datfeite",
    Theme = "Default",
    ToggleUIKeybind = "K",
    ConfigurationSaving = {
      Enabled = true,
      FolderName = "Mis hud",
      FileName = "Fisch"
   },
})

local MainTab = Window:CreateTab("Main", 4483362458)
local InfTab = Window:CreateTab("Information", 4483362458)
local AppTab  = Window:CreateTab("Appraise", 4483362458)
local SellTab = Window:CreateTab("Sell", 4483362458)
local TeleTab = Window:CreateTab("Teleport", 4483362458)
local DevTab  = Window:CreateTab("Developer", 4483362458)

-- ==================== EXECUTOR DETECTOR ====================
local ExecutorSection = DevTab:CreateSection("Executor Info")

local ExecutorInfoParagraph = DevTab:CreateParagraph({
    Title = "Executor Detection",
    Content = "Detecting executor..."
})

task.spawn(function()
    local info = {}
    
    local executorName = "Unknown"
    
    local success, result = pcall(function()
        return identifyexecutor()
    end)
    if success and result then
        executorName = result
    else
        success, result = pcall(function()
            return getexecutorname()
        end)
        if success and result then
            executorName = result
        end
    end
    
    table.insert(info, "🔧 **Executor:** " .. executorName)
    
    table.insert(info, "📌 **Roblox Version:** " .. (version() or "Unknown"))
    
    local success2, http = pcall(function() 
        return game:GetService("HttpService"):GetAsync("https://httpbin.org/ip") 
    end)
    table.insert(info, "🌐 **HTTP Enabled:** " .. (success2 and "✅ Yes" or "❌ No"))
    
    local functions = {
        ["getgenv"] = getgenv ~= nil,
        ["getrenv"] = getrenv ~= nil,
        ["firesignal"] = firesignal ~= nil,
        ["firetouchinterest"] = firetouchinterest ~= nil,
        ["setsimulationradius"] = setsimulationradius ~= nil,
    }
    
    local funcList = {}
    for name, exists in pairs(functions) do
        table.insert(funcList, name .. (exists and " ✅" or " ❌"))
    end
    table.insert(info, "\n**Available Functions:**\n" .. table.concat(funcList, " | "))
    
    ExecutorInfoParagraph:Set({
        Title = "🔍 Executor Information",
        Content = table.concat(info, "\n")
    })
    
end)

local UIS = game:GetService("UserInputService")
local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local playerGui = player:WaitForChild("PlayerGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VIM = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local humanoid = character:WaitForChild("Humanoid")

-- Alte Variable nicht mehr nötig (wir suchen dynamisch)

local AutoEquipRod = false
local AutoReel = false
local AutoShake = false
local AutoCast = false
local AutoReelRisky = false
local AutoReelSafe = false
local AutoSell = false
local Frozen = false
local frozenCFrame = nil
local InfiniteOxygen = false
local AutoSellDelay = 100
local AutoCastPerfect = false
local IsSelling = false
local Fischsold = 0
local lastKnownStatus = "Noch kein Status gespeichert"
local ShakeVariant = "Function"
local isFocused = true
local AutoEquipBait = false
local playerStats = workspace:WaitForChild("PlayerStats")
local myStats = playerStats:WaitForChild(player.Name)
local IgnoreBait = {}
local OnlyEquipBait = {}
local AutoSpear = false
local Spear = game:GetService("ReplicatedStorage").packages.Net["RE/SpearFishing/Minigame"]
local fishingFolder = workspace:FindFirstChild("zones") and workspace.zones:FindFirstChild("fishing")
local shark = fishingFolder and fishingFolder:FindFirstChild("Great Hammerhead Shark")
local AutoCollectGrabCages = false
local AutoAppraise = false
local AutoAppraisedelay = 1
local AutoAppraiseSlot = 1
local StopWeight = 0
local STOP_KEYWORDS = {}

local slotToKey = {
    [1] = Enum.KeyCode.One, [2] = Enum.KeyCode.Two, [3] = Enum.KeyCode.Three,
    [4] = Enum.KeyCode.Four, [5] = Enum.KeyCode.Five, [6] = Enum.KeyCode.Six,
    [7] = Enum.KeyCode.Seven, [8] = Enum.KeyCode.Eight, [9] = Enum.KeyCode.Nine,
}

local connections = {}
local AntiAFK = false
local VirtualUser = game:GetService("VirtualUser")

local AutoCastPower = 100
local currentTP = "Moosewood"

local teleportLocations = {
    ["Roslit Bay"] = CFrame.new(-1452, 144, 633),
    ["Moosewood"] = CFrame.new(440, 158, 290),
    ["Snowcap Cave"] = CFrame.new(2816, 131, 2694),
    ["Snowcap Island"] = CFrame.new(2697, 153, 2399),
    ["Harvesters Spike"] = CFrame.new(-1324, 141, 1533),
    ["Forsaken Shores"] = CFrame.new(-2587, 158, 1561),
    ["Grand Reef"] = CFrame.new(-3564, 147, 544),
    ["Atlantis(Grand Reef)"] = CFrame.new(-4352, -576, 1828),
    ["Scoria Reach"] = CFrame.new(-4961, 183, -1443),
    ["Sunstone Island"] = CFrame.new(-1081, 214, -1122),
    ["Statue of Sovereignty"] = CFrame.new(18, 151, -1024),
    ["Lost Jungle"] = CFrame.new(-2589, 156, -2076),
    ["Keepers Altar"] = CFrame.new(1309, -802, -91),
    ["Castaway Cliffs"] = CFrame.new(395, 200, -1803),
    ["The Arch"] = CFrame.new(989, 131, -1239),
    ["Mushgrove Swamp"] = CFrame.new(2634, 130, -702),
    ["Vertigo"] = CFrame.new(-158, -515, 1157),
    ["The Depths"] = CFrame.new(953, -720, 1302),
    ["Desolate Deep"] = CFrame.new(-1518, -235, -2854),
    ["Everturn Island"] = CFrame.new(2563, 139, -2372),
    ["Desolated Brine Pool"] = CFrame.new(-1795, -142, -3407),
    ["Tide Fall"] = CFrame.new(3138, -1100, 782),
    ["Crystal Crove"] = CFrame.new(1368, -604, 2338),
}

local function getBaitFolder()
    return myStats
        :WaitForChild("T")
        :WaitForChild(player.Name)
        :WaitForChild("Stats")
        :WaitForChild("bait")
end

local function buildOptions()
    local options = {}

    local baitFolder = getBaitFolder()

    for _, v in pairs(baitFolder:GetChildren()) do
        if v:IsA("NumberValue") then
            local name = v.Name:gsub("bait_", "")
            local amount = v.Value

            options[#options + 1] = name .. " (" .. amount .. ")"
        end
    end

    return options
end

local function equipSlot(slot)
    local keyCode = slotToKey[slot]
    if keyCode then
        VIM:SendKeyEvent(true, keyCode, false, game)
        task.wait(0.05)
        VIM:SendKeyEvent(false, keyCode, false, game)
    end
end

local function safeTonumber(str)
    if not str or typeof(str) ~= "string" then return 0 end
    str = str:gsub("[^%d%.%-]", ""):gsub("%s+", "")
    return tonumber(str) or 0
end

local function getMatchedKeywords(rawText)
    local cleanText = rawText:gsub("<[^>]+>", "")
    local found = {}
    for _, keyword in ipairs(STOP_KEYWORDS) do
        if cleanText:find(keyword, 1, true) then
            table.insert(found, keyword)
        end
    end
    return found, cleanText
end

local function checkHotbarSlot(slot)
    local hotbar = player.PlayerGui:FindFirstChild("backpack") and player.PlayerGui.backpack:FindFirstChild("hotbar")
    if not hotbar then return false, {}, "", 0 end

    for _, item in ipairs(hotbar:GetChildren()) do
        if item.Name == "ItemTemplate" then
            local textLabel = item:FindFirstChild("TextLabel")
            local itemName = item:FindFirstChild("ItemName")
            local weightLabel = item:FindFirstChild("Weight")

            local slotNum = 0
            if textLabel and textLabel.Text then
                slotNum = safeTonumber(textLabel.Text)
            end

            if slotNum == slot then
                local rawText = itemName and itemName.Text or ""
                local matched, cleanText = getMatchedKeywords(rawText)

                local weight = 0
                if weightLabel and weightLabel.Text then
                    weight = safeTonumber(weightLabel.Text)
                end

                local weightStop = StopWeight > 0 and weight >= StopWeight

                if #matched > 0 or weightStop then
                    return true, matched, cleanText, weight
                end
            end
        end
    end
    return false, {}, "", 0
end

-- ==================== UPDATE / CHANGELOG ====================
local updateParagraph = MainTab:CreateParagraph({
    Title = "Update: v1.4",
    Content = "• Added Auto Auto Crab Cages and Auto Spear to Developer Tab\n• Fixed Anti AFK\n• Added Bait Auto Equip with Options\n• Added more Teleport locations\n• Added Information Tab "
})

-- ==================== SESSION STATS ====================
local statsParagraph = MainTab:CreateParagraph({Title = "Session Stats", Content = "Loading..."})

task.spawn(function()
    local startTime = tick()
    local startCash = player.leaderstats["C$"].Value
    
    while task.wait(1) do
        local elapsed = tick() - startTime
        local hours = elapsed / 3600
        local cashPerHour = (player.leaderstats["C$"].Value - startCash) / math.max(hours, 0.01)
        
        statsParagraph:Set({
            Title = "📊 Session Stats",
            Content = string.format(
                "💰 Cash: %s C$\n⭐ Level: %s\n⏱ Session: %02d:%02d:%02d\n💸 C$/h: %d",
                player.leaderstats["C$"].Value,
                player.leaderstats.Level.Value,
                math.floor(elapsed/3600),
                math.floor((elapsed%3600)/60),
                math.floor(elapsed%60),
                math.floor(cashPerHour)
            )
        })
    end
end)

-- ==================== AUTO SELL STATUS ====================
local AutoSellStatusParagraph = SellTab:CreateParagraph({
    Title = "AutoSell - Aktive Seltenheiten",
    Content = "⏳ Lade Status..."
})


local function GetAllSellOptionsStatus()
    local container = game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("optionContainer", true)
    if not container then return nil end

    local statusLines = {}
    local desiredOrder = {"Crates", "Trash", "Common", "Uncommon", "Unusual", "Rare", "Legendary", "Mythical", "Exotic", "Secret", "Limited", "Relic", "Fragment", "Seed", "Gemstone", "Apex", "Extinct", "Special", "Divine Secret"}
    
    for _, desiredName in ipairs(desiredOrder) do
        for _, child in ipairs(container:GetChildren()) do
            if child:IsA("TextButton") then
                local displayName = child.Text or ""
                
                local textLabel = child:FindFirstChildWhichIsA("TextLabel")
                if textLabel and textLabel.Text and textLabel.Text ~= "" then
                    displayName = textLabel.Text
                end
                
                if displayName ~= "" and (child.Name == desiredName or displayName:find(desiredName)) then
                    local stroke = child:FindFirstChildWhichIsA("UIStroke")
                    if stroke then
                        if stroke.Transparency == 0 then
                            table.insert(statusLines, "✅ **" .. displayName .. "**")
                        else
                            table.insert(statusLines, "❌ " .. displayName)
                        end
                        break
                    end
                end
            end
        end
    end

    return #statusLines > 0 and table.concat(statusLines, "\n") or nil
end

task.spawn(function()
    task.wait(1.6)
    
    local mainMenu = game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("hud", true) 
                  and game:GetService("Players").LocalPlayer.PlayerGui.hud.safezone.topbar:FindFirstChild("MainMenu")
    if mainMenu then
        pcall(function() firesignal(mainMenu.Activated) end)
    end
    
    for i = 1, 7 do
        task.wait(0.55)
        local status = GetAllSellOptionsStatus()
        if status then
            lastKnownStatus = status
            AutoSellStatusParagraph:Set({
                Title = "AutoSell - Aktive Seltenheiten",
                Content = status
            })
            break
        end
    end
end)

task.spawn(function()
    task.wait(3)
    while task.wait(0.9) do
        pcall(function()
            local currentStatus = GetAllSellOptionsStatus()
            
            if currentStatus then
                lastKnownStatus = currentStatus
                AutoSellStatusParagraph:Set({
                    Title = "AutoSell - Aktive Seltenheiten",
                    Content = currentStatus
                })
            else
                AutoSellStatusParagraph:Set({
                    Title = "AutoSell - Aktive Seltenheiten",
                    Content = lastKnownStatus
                })
            end
        end)
    end
end)

-- ==================== Information Tab ====================

local ZONES_PATH = workspace:WaitForChild("zones"):WaitForChild("fishing")

local lastStates = {}

local Paragraph = InfTab:CreateParagraph({
    Title = "Fishing Check",
    Content = "Scanning..."
})

local trackedEntities = {
    ["Great Hammerhead Shark"] = {
        label = "Great Hammerhead Shark",
        notify = true
    },
    ["Baby Bloop Fish"] = {
        label = "Baby Bloop Fish",
        notify = true
    },
    ["Whale Shark"] = {
        label = "Whale Shark",
        notify = true
    },
    ["Orcas Pool"] = {
        label = "Orcas Pool",
        notify = true
    },
    ["Isonade"] = {
        label = "Isonade",
        notify = true
    },
    ["Great White Shark"] = {
        label = "Great White Shark",
        notify = true
    },
}

local function getZone()
    local zones = workspace:FindFirstChild("zones")
    if not zones then return nil end
    return zones:FindFirstChild("fishing")
end

local function scan()
    local folder = getZone()

    if not folder then
        Paragraph:Set({
            Title = "Fishing Check",
            Content = "Fishing zone not found."
        })
        return
    end

    local lines = {}

    for name, config in pairs(trackedEntities) do
        local exists = folder:FindFirstChild(name) ~= nil

        lines[#lines + 1] = config.label .. ": " .. (exists and "✅" or "❌")

        -- state change tracking
        if lastStates[name] ~= exists then
            lastStates[name] = exists

            if config.notify then
                Rayfield:Notify({
                    Title = "Fishing Alert",
                    Content = config.label .. (exists and " is now ACTIVE! ✅" or " has ended. ❌"),
                    Duration = 5
                })
            end
        end
    end

    Paragraph:Set({
        Title = "Fishing Check",
        Content = table.concat(lines, "\n")
    })
end

task.spawn(function()
    while true do
        scan()
        task.wait(5)
    end
end)

-- ==================== AUTO EQUIP ROD ====================
local AutoEquipRodSection = MainTab:CreateSection("Equip Rod")

local function equipAnyRod()
    if not humanoid then return end
    
    for _, tool in ipairs(player.Backpack:GetChildren()) do
        if tool:IsA("Tool") and tool.Name:find("Rod") then
            humanoid:EquipTool(tool)
            return true
        end
    end
    
    for _, tool in ipairs(character:GetChildren()) do
        if tool:IsA("Tool") and tool.Name:find("Rod") then
            return true
        end
    end
    
    return false
end

local Toggle = MainTab:CreateToggle({
   Name = "AUTO EQUIP ROD",
   CurrentValue = false,
   Callback = function(AUTOEQUIPRODToggle1)
    AutoEquipRod = AUTOEQUIPRODToggle1 
   end,
})


task.spawn(function()
    while true do 
        if AutoEquipRod then 
            equipAnyRod()
        end
    task.wait(1)
    end
end)

-- ==================== AUTO CAST ====================
local AutoCastSection = MainTab:CreateSection("Auto Cast")

MainTab:CreateSlider({
    Name = "Cast Power (%)",
    Range = {1, 100},
    Increment = 1,
    CurrentValue = 100,
    Callback = function(v)
        AutoCastPower = math.clamp(v + math.random(-5, 5), 1, 100)
    end
})

local Toggle = MainTab:CreateToggle({
   Name = "Auto Cast Perfect",
   CurrentValue = false,
   Callback = function(AutoCastPerfectToggle1)
    AutoCastPerfect = AutoCastPerfectToggle1
   end,
})

MainTab:CreateToggle({ Name = "Auto Cast", CurrentValue = false, Callback = function(v) AutoCast = v end })

task.spawn(function()
    while task.wait(0.7) do
        if AutoCast then
            if not playerGui:FindFirstChild("reel") and not playerGui:FindFirstChild("shakeui") then
                local castEvent = ReplicatedStorage.packages.Net["RF/FishingRod/Cast"]
                if castEvent then 
                    castEvent:InvokeServer(AutoCastPower, AutoCastPerfect)
                end
            end
        end
    end
end)

local Toggle = MainTab:CreateToggle({
    Name = "Auto Equip Bait",
    CurrentValue = false,
    Flag = "Toggle1",
    Callback = function(Value)
        AutoEquipBait = Value
    end,
})

local OnlyDropdown = MainTab:CreateDropdown({
    Name = "Only Equip Bait",
    Options = buildOptions(),
    CurrentOption = {},
    MultipleOptions = true,
    Flag = "OnlyEquipBaitDropdown",

    Callback = function(Selected)
        OnlyEquipBait = {}

        for _, raw in pairs(Selected) do
            local cleaned = raw:gsub("%s%(%d+%)", "")
            OnlyEquipBait[cleaned] = true
        end
    end,
})


Dropdown = MainTab:CreateDropdown({
    Name = "Ignore Bait",
    Options = buildOptions(),
    CurrentOption = {},
    MultipleOptions = true,
    Flag = "IgnoreBaitDropdown",

    Callback = function(Selected)
        IgnoreBait = {}

        for _, raw in pairs(Selected) do
            local cleaned = raw:gsub("%s%(%d+%)", "")
            IgnoreBait[cleaned] = true
        end
    end,
})

task.spawn(function()
    while task.wait(2) do

        local newOptions = buildOptions()

        -- Ignore Bait dropdown
        if Dropdown then
            if Dropdown.Refresh then
                Dropdown:Refresh(newOptions, true)
            elseif Dropdown.SetOptions then
                Dropdown:SetOptions(newOptions)
            end
        end

        -- Only Equip dropdown
        if OnlyDropdown then
            if OnlyDropdown.Refresh then
                OnlyDropdown:Refresh(newOptions, true)
            elseif OnlyDropdown.SetOptions then
                OnlyDropdown:SetOptions(newOptions)
            end
        end

    end
end)

task.spawn(function()
    while task.wait(0.5) do

        if AutoEquipBait then

            local baitFolder = getBaitFolder()
            local hasWhitelist = next(OnlyEquipBait) ~= nil

            for _, v in pairs(baitFolder:GetChildren()) do

                if v:IsA("NumberValue") and v.Value ~= 0 then

                    local baitName = v.Name:gsub("bait_", "")

                    local shouldEquip =
                        (not hasWhitelist and not IgnoreBait[baitName])
                        or (hasWhitelist and OnlyEquipBait[baitName] and not IgnoreBait[baitName])

                    if shouldEquip then

                        ReplicatedStorage
                            .packages.Net["RE/Bait/Equip"]
                            :FireServer(baitName)

                    end
                end
            end
        end
    end
end)

-- ==================== AUTO SHAKE ====================
local AutoShakeSection = MainTab:CreateSection("Auto Shake")

MainTab:CreateDropdown({
    Name = "Shake Variant",
    Options = {"Function", "VirtualInputManager"},
    CurrentOption = {"Function"},
    MultipleOptions = false,
    Callback = function(Option)
        ShakeVariant = Option[1]
    end,
})

MainTab:CreateToggle({
    Name = "Auto Shake",
    CurrentValue = false,
    Callback = function(v) AutoShake = v end
})

task.spawn(function()
    while true do
        if AutoShake then
            local shakeui = playerGui:FindFirstChild("shakeui")
            if shakeui and shakeui:FindFirstChild("safezone") then
                local btn = shakeui.safezone:FindFirstChild("button")
                if btn then
                    if ShakeVariant == "Function" then
                        pcall(firesignal, btn.Activated)
                    else
                        VIM:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
                        task.wait(0.05) -- slightly shorter press
                        VIM:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
                    end
                end
            end
        end
        task.wait(0.07)
    end
end)

-- ==================== AUTO CAST(Risky) ====================
local AutoReelSection = MainTab:CreateSection("Auto Reel")
local Toggle = MainTab:CreateToggle({
   Name = "Auto Reel(Risky?)",
   CurrentValue = false,
   Callback = function(AutoReelRiskyToggle1)
    AutoReel = AutoReelRiskyToggle1
   end,
})

task.spawn(function()
    while true do 
        if AutoReel then 
            local reelui = playerGui:FindFirstChild("reel")
            if reelui then 
                wait(3)
                local Event = game:GetService("ReplicatedStorage").packages.Net["RE/Reel/Finish"]
                Event:FireServer({
                    e = 100.18742129207,
                    p = false,
                    l = {},
                    d = {}
                })
                task.wait(0.5)
                local reelui2 = playerGui:FindFirstChild("reel")
                if reelui2 then
                    reelui2:Destroy()
                end
            end
        end
        task.wait(0.5)
    end
end)

-- ==================== AUTO REEL SAFE ====================
MainTab:CreateToggle({
    Name = "Auto Reel Safe",
    CurrentValue = false,
    Callback = function(v) AutoReelSafe = v end
})

task.spawn(function()
    local holding = false
    local lastRodPos = 0
    local lastFishPos = 0
    local rodVelocity = 0
    local fishVelocity = 0

    while true do 
        if AutoReelSafe then 
            local reelui = playerGui:FindFirstChild("reel")
            if reelui and reelui:FindFirstChild("bar") then 
                local Rod  = reelui.bar.playerbar
                local Fish = reelui.bar.fish

                local RodCenter  = Rod.AbsolutePosition.X + Rod.AbsoluteSize.X / 2
                local FishCenter = Fish.AbsolutePosition.X + Fish.AbsoluteSize.X / 2

                local newRodVel  = RodCenter  - lastRodPos
                local newFishVel = FishCenter - lastFishPos
                rodVelocity  = rodVelocity  * 0.6 + newRodVel  * 0.4
                fishVelocity = fishVelocity * 0.6 + newFishVel * 0.4
                lastRodPos  = RodCenter
                lastFishPos = FishCenter

                local damping = math.clamp(math.abs(rodVelocity) * 2, 1, 6)

                local predictedRod  = RodCenter  + rodVelocity  * damping
                local predictedFish = FishCenter + fishVelocity * 2

                local diff = predictedFish - predictedRod

                local totalSpeed = math.abs(rodVelocity) + math.abs(fishVelocity)
                local deadzone = math.clamp(totalSpeed * 0.5, 0.1, 3)

                if diff > deadzone then
                    if not holding then
                        VIM:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                        holding = true
                    end
                elseif diff < -deadzone then
                    if holding then
                        VIM:SendMouseButtonEvent(0, 0, 0, false, game, 0)
                        holding = false
                    end
                end
            else
                if holding then
                    VIM:SendMouseButtonEvent(0, 0, 0, false, game, 0)
                    holding = false
                end
                lastRodPos = 0
                lastFishPos = 0
                rodVelocity = 0
                fishVelocity = 0
            end
        else
            if holding then
                VIM:SendMouseButtonEvent(0, 0, 0, false, game, 0)
                holding = false
            end
            lastRodPos = 0
            lastFishPos = 0
            rodVelocity = 0
            fishVelocity = 0
        end
        task.wait(0.016)
    end
end)

-- ==================== AUTO SELL ====================
local Slider = SellTab:CreateSlider({
   Name = "How often Sell?",
   Range = {10, 1000},
   Increment = 10,
   Suffix = "sec",
   CurrentValue = 100,
   Callback = function(HowoftenSellSlider1)
    AutoSellDelay = HowoftenSellSlider1
   end,
})

SellTab:CreateToggle({ 
    Name = "Auto Sell Inventory", 
    CurrentValue = false, 
    Callback = function(v) 
        AutoSell = v 
    end 
})

local Fischsold = 0  -- Sell Counter

-- Sell Counter Paragraph
local sellCountParagraph = SellTab:CreateParagraph({
    Title = "📈 Sell Statistics",
    Content = "Total Sells: 0"
})

task.spawn(function()
    while task.wait(AutoSellDelay + math.random(1,5)) do
        if AutoSell and not IsSelling then
            IsSelling = true
            
            pcall(function()
                local char = player.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if not hrp then 
                    IsSelling = false
                    return 
                end

                local savedCFrame = hrp.CFrame
                
                hrp.CFrame = CFrame.new(492, 163, 233)
                task.wait(1.2)

                local sellEvent = ReplicatedStorage:FindFirstChild("events", true) and ReplicatedStorage.events:FindFirstChild("SellAll")
                if sellEvent then
                    sellEvent:InvokeServer({
                        voice = 12,
                        uid = "merchant_moosewood",
                        npc = workspace.world.npcs:FindFirstChild("Marc Merchant")
                    })
                    
                    Fischsold = Fischsold + 1
                    
                    -- Update Paragraph
                    sellCountParagraph:Set({
                        Title = "📈 Sell Statistics",
                        Content = "Total Sells: " .. Fischsold
                    })
                    
                end

                local startWait = tick()
                repeat
                    task.wait(0.3)
                until tick() - startWait > 8 or not playerGui:FindFirstChild("sell")
                    
                task.wait(0.7)
                
                if hrp and hrp.Parent then
                    hrp.CFrame = savedCFrame
                end
            end)
            
            IsSelling = false
        end
    end
end)

-- ==================== TELEPORTS ====================
TeleTab:CreateDropdown({
    Name = "Teleport Location",
    Options = {"Moosewood", "Roslit Bay", "Snowcap Island", "Snowcap Cave", "Harvesters Spike", "Forsaken Shores", "Grand Reef", "Atlantis", "Scoria Reach", "Sunstone Island", "Statue of Sovereignty", "Lost Jungle", "Mushgrove Swamp", "Castaway Cliffs", "The Arch", "Keepers Altar", "Vertigo", "The Depths", "Everturn Island", "Desolated Brine Pool", "Tide Fall", "Crystal Crove"},
    CurrentOption = {"Moosewood"},
    MultipleOptions = false,
    Callback = function(opt) currentTP = opt[1] end
})

TeleTab:CreateButton({
    Name = "Teleport Now",
    Callback = function()
        local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if hrp and teleportLocations[currentTP] then
            hrp.CFrame = teleportLocations[currentTP]
            Rayfield:Notify({Title = "Teleport", Content = "✅ Teleportiert zu " .. currentTP, Duration = 3})
        end
    end
})

-- ==================== AKF Freeze ====================
local AutoAFKFreezeSection = MainTab:CreateSection("AFK")

MainTab:CreateToggle({
    Name = "AFK Freeze",
    CurrentValue = false,
    Callback = function(v)
        Frozen = v

        local char = player.Character
        if not char then return end

        local hum = char:FindFirstChildOfClass("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")

        if hum then
            hum.WalkSpeed = v and 0 or 16
            hum.JumpPower = v and 0 or 50

            if not v then
                hum:ChangeState(Enum.HumanoidStateType.Landed)
                hum:Move(Vector3.zero, true)
            end
        end

        if hrp then
            if v then
                frozenCFrame = hrp.CFrame
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
            else
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
            end
        end
    end
})

-- ================== Anti AFK =======================

MainTab:CreateToggle({
    Name = "Anti AFK (Prevent + Hide)",
    CurrentValue = false,
    Callback = function(state)
        AntiAFK = state
    end
})

UserInputService.WindowFocusReleased:Connect(function()
    isFocused = false
end)

UserInputService.WindowFocused:Connect(function()
    isFocused = true
end)

task.spawn(function()
    local hasFired = false
    while true do
        if AntiAFK then
            if not isFocused and not hasFired then
                local Event = game:GetService("ReplicatedStorage").events.afk
                Event:FireServer(false)
                print("Ch")
                hasFired = true
            end
            
            -- Reset wenn wieder fokussiert
            if isFocused then
                hasFired = false
            end
        end
        task.wait(math.random(2, 5))
    end
end)

-- ================== MISC =======================
task.spawn(function()
    while task.wait(0.016) do
        if Frozen and frozenCFrame then
            local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.CFrame = frozenCFrame
                hrp.Velocity = Vector3.zero
                hrp.RotVelocity = Vector3.zero
            end
        end
    end
end)

DevTab:CreateToggle({ Name = "Infinite Oxygen", CurrentValue = false, Callback = function(v) InfiniteOxygen = v end })

task.spawn(function()
    while task.wait(0.1) do
        if InfiniteOxygen then
            local char = player.Character
            if char then
                for _, obj in ipairs(char:GetDescendants()) do
                    if obj.Name:lower():find("oxygen") or obj.Name:lower():find("air") or obj.Name:lower():find("breath") then
                        if typeof(obj.Value) == "number" then
                            obj.Value = 999999
                        end
                    end
                end
            end
        end
    end
end)

local Toggle = DevTab:CreateToggle({
   Name = "Auto Spear",
   CurrentValue = false,
   Callback = function(AutoSpearToggle1)
    AutoSpear = AutoSpearToggle1
   end,
})

local Spear = game:GetService("ReplicatedStorage").packages.Net["RE/SpearFishing/Minigame"]

task.spawn(function()
    while true do
        if AutoSpear then
            local water = workspace["Spearfishing Water"]
            local zones = water:GetChildren()

            if #zones == 0 then
                print("Not in Lost Jungle")
            else
                for _, zone in ipairs(zones) do
                    local zoneFish = zone:FindFirstChild("ZoneFish")

                    if zoneFish then
                        for _, fish in ipairs(zoneFish:GetChildren()) do
                            local uid = fish:GetAttribute("UID")

                            if uid and AutoSpear then
                                print(fish.Name, uid)

                                Spear:FireServer(uid)
                                task.wait(1.5)

                                Spear:FireServer(uid, true)
                                task.wait(0.2)
                            end
                        end
                    end
                end
            end
        end

        task.wait(0.5)
    end
end)

local Toggle = DevTab:CreateToggle({
    Name = "Auto Collect Crab Cages",
    CurrentValue = false,
    Callback = function(Value)
        AutoCollectGrabCages = Value
    end,
})

task.spawn(function()
    while true do
        task.wait(0.2)

        if AutoCollectGrabCages then
            local character = player.Character
            if not character then continue end

            local cageFolder = workspace:FindFirstChild("active")
                and workspace.active:FindFirstChild("crabcages")

            if cageFolder then
                for _, cage in ipairs(cageFolder:GetChildren()) do

                    local promptHolder = cage:FindFirstChild("PromptHolder")
                    local prompt = promptHolder and promptHolder:FindFirstChildWhichIsA("ProximityPrompt")

                    -- ONLY act if prompt exists AND is enabled
                    if prompt and prompt.Enabled then
                        character:PivotTo(cage:GetPivot())
                        task.wait(0.2)

                        fireproximityprompt(prompt)
                        task.wait(0.5)
                    end
                end
            end
        end
    end
end)

DevTab:CreateButton({
    Name = "Show/Hide Buy Boat UI",
    Callback = function()
        local shipwrightUI = playerGui:WaitForChild("hud"):WaitForChild("safezone"):FindFirstChild("shipwright")
        if shipwrightUI and shipwrightUI:IsA("GuiObject") then
            shipwrightUI.Visible = not shipwrightUI.Visible
            Rayfield:Notify({
                Title = "UI Status",
                Content = shipwrightUI.Visible and "Buy Boat UI is now visible!" or "Buy Boat UI is now hidden!",
                Duration = 5
            })
        else
            Rayfield:Notify({ Title = "Error!", Content = "Shipwright UI not found!", Duration = 5 })
        end
    end
})

DevTab:CreateButton({
    Name = "Remove Fog",
    Callback = function()
        local lighting = game:GetService("Lighting")
        local sky = lighting:FindFirstChild("Sky")
        if sky then
            sky.Parent = lighting:FindFirstChild("bloom") or lighting
            Rayfield:Notify({ Title = "Fog Removed", Content = "Fog has been successfully removed from the environment.", Duration = 5 })
        else
            Rayfield:Notify({ Title = "Remove Fog Failed", Content = "Sky object not found in Lighting!", Duration = 5 })
        end
    end
})

DevTab:CreateButton({
    Name = "FPS Boost",
    Callback = function()
        local decalsyeeted = false
        local g = game
        local w = g.Workspace
        local l = g.Lighting
        local t = w.Terrain
        t.WaterWaveSize = 0
        t.WaterWaveSpeed = 0
        t.WaterReflectance = 0
        t.WaterTransparency = 0
        l.GlobalShadows = false
        l.FogEnd = 9e9
        l.Brightness = 0
        settings().Rendering.QualityLevel = "Level01"
        for i, v in pairs(g:GetDescendants()) do
            if v:IsA("Part") or v:IsA("Union") or v:IsA("CornerWedgePart") or v:IsA("TrussPart") then 
                v.Material = "Plastic"
                v.Reflectance = 0
            elseif v:IsA("Decal") or v:IsA("Texture") and decalsyeeted then
                v.Transparency = 1
            elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
                v.Lifetime = NumberRange.new(0)
            elseif v:IsA("Explosion") then
                v.BlastPressure = 1
                v.BlastRadius = 1
            elseif v:IsA("Fire") or v:IsA("SpotLight") or v:IsA("Smoke") or v:IsA("Sparkles") then
                v.Enabled = false
            elseif v:IsA("MeshPart") then
                v.Material = "Plastic"
                v.Reflectance = 0
                v.TextureID = 10385902758728957
            end
        end
        for i, e in pairs(l:GetChildren()) do
            if e:IsA("BlurEffect") or e:IsA("SunRaysEffect") or e:IsA("ColorCorrectionEffect") or e:IsA("BloomEffect") or e:IsA("DepthOfFieldEffect") then
                e.Enabled = false
            end
        end
        Rayfield:Notify({ Title = "FPS Boost", Content = "FPS Boost applied!", Duration = 4 })
    end
})

local Dropdown = AppTab:CreateDropdown({
    Name = "Stop bei",
    Options = {"Shiny", "Midas", "Sparkling", "Mythic", "Exotic", "Prismatic"},
    CurrentOption = {},
    MultipleOptions = true,
    Flag = "AutoAppraiseStopDropdown1",
    Callback = function(selected)
        STOP_KEYWORDS = selected
    end,
})

local WeightInput = AppTab:CreateInput({
    Name = "Stop ab Gewicht (0 oder leer = deaktiviert)",
    PlaceholderText = "z.B. 25.5 oder 30",
    RemoveTextOnFocus = false,
    Callback = function(text)
        local val = safeTonumber(text)
        StopWeight = val
        if val > 0 then
            print("✅ Gewichtsstop aktiviert: " .. val .. " Kg")
        else
            print("✅ Gewichtsstop deaktiviert")
        end
    end,
})

local Slider = AppTab:CreateSlider({
    Name = "Auto Appraise delay",
    Range = {0.1, 5},
    Increment = 0.1,
    Suffix = "sec",
    CurrentValue = 1,
    Flag = "AutoAppraisedelaySlider1",
    Callback = function(val)
        AutoAppraisedelay = val
    end,
})

local SlotSlider = AppTab:CreateSlider({
    Name = "Hotbar Slot to check",
    Range = {1, 9},
    Increment = 1,
    CurrentValue = 1,
    Flag = "AutoAppraiseSlotSlider1",
    Callback = function(val)
        AutoAppraiseSlot = val
        equipSlot(val)
    end,
})

local Toggle = AppTab:CreateToggle({
    Name = "Auto Appraise",
    CurrentValue = false,
    Flag = "AutoAppraiseToggle1",
    Callback = function(state)
        AutoAppraise = state
        if not state then return end

        task.spawn(function()
            while AutoAppraise do
                local shouldStop, matched, cleanText, weight = checkHotbarSlot(AutoAppraiseSlot)

                if shouldStop then
                    AutoAppraise = false
                    local reason = {}
                    if #matched > 0 then
                        table.insert(reason, "Keywords: " .. table.concat(matched, ", "))
                    end
                    if StopWeight > 0 and weight >= StopWeight then
                        table.insert(reason, "Gewicht: " .. weight .. "Kg")
                    end
                    
                    Rayfield:Notify({
                        Title = "Auto Appraise Stopped!",
                        Content = table.concat(reason, " | ") .. "\nItem: " .. cleanText,
                        Duration = 8,
                    })
                    print("STOP! " .. table.concat(reason, " | ") .. " | Item: " .. cleanText)
                    break
                end

                local Event = ReplicatedStorage.packages.Net["RF/DialogInteract"]
                if Event then
                    Event:InvokeServer(1, 1)
                    task.wait(0.1)
                    Event:InvokeServer(6, 1)
                end

                task.wait(AutoAppraisedelay)
            end
        end)
    end,
})

Rayfield:Notify({Title = "Fisch Hub", Content = "Script Loaded", Duration = 5})
