-- Blox Fruits Auto Farm – Full Feature + Simple Fruit Notifier
-- Includes boss detection, quest stack, auto equip, stats, and fruit notifier.

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

-- Load Vaxorin (or fallback UI)
local useVaxorin = false
local window = nil
local notifierLabel = nil  -- fallback notification label

local function notifyUser(title, content)
    if window and window.Notify then
        window:Notify({ Title = title, Content = content, Type = "Info", Duration = 3 })
    elseif notifierLabel then
        notifierLabel.Text = title .. ": " .. content
    else
        print("[" .. title .. "] " .. content)
    end
end

-- =============================================
-- VAXORIN OR FALLBACK UI
-- =============================================
local success, err = pcall(function()
    local Vaxorin = loadstring(game:HttpGet(
        "https://raw.githubusercontent.com/datfiete/Void-Hub/refs/heads/main/CyberUI%20-%20Kopie/load.lua"
    ))()
    if Vaxorin then
        Vaxorin.Theme.Style = "Vaxorin"
        window = Vaxorin:CreateWindow({
            Title = "Blox Fruits Auto Farm",
            Subtitle = "Full Feature",
            Logo = "rbxassetid://135320038058277",
            Badges = {{Text = "Blox Fruits"}, {Text = "v1.0"}},
            Footer = {Username = LocalPlayer.Name, Status = "Ready"},
            DiscordLink = "https://discord.gg/example",
            ShowSearch = true,
            ShowWindowControls = true,
            ToggleKey = Enum.KeyCode.RightControl,
            TopMost = true,
            HideCoreUI = true,
            ConfigurationSaving = { Enabled = false, AutoSave = false },
        })
        useVaxorin = true
    end
end)

-- =============================================
-- CONFIG (user settings)
-- =============================================
local config = {
    flySpeed = 120,
    attackMode = "Melee",
    autoHeal = false,
    healThreshold = 30,
    aboveHeight = 20,
    attackRange = 30,
    attackSpeed = 0.005,
    bossAttackSpeed = 0.002,
    hitsPerCycle = 15,
    bossHitsPerCycle = 25,
    clusterEnabled = true,
    clusterHeight = 15,
    maxClusterSize = 15,
    statEnabled = false,
    statsToAdd = {"Melee", "Defense"},
    pointsPerStat = 1,
    bossPriority = true,
    autoEquip = false,
    preferredWeapon = "Melee",
    questStack = false,
    stackCount = 3,
    fruitNotifier = true,        -- fruit notifier toggle
    fruitAutoCollect = false,
}

-- =============================================
-- COMBAT REMOTES
-- =============================================
local Net = ReplicatedStorage:FindFirstChild("Modules")
    and ReplicatedStorage.Modules:FindFirstChild("Net")
local RegisterAttack = Net and Net:FindFirstChild("RE/RegisterAttack")
local RegisterHit = Net and Net:FindFirstChild("RE/RegisterHit")

local function fireCombatHit(targets)
    if not RegisterAttack or not RegisterHit or #targets == 0 then
        return false
    end
    local first = targets[1]
    local head = first and first:FindFirstChild("Head")
    if not head then
        return false
    end
    local hitList = {}
    for _, enemy in ipairs(targets) do
        local enemyHead = enemy:FindFirstChild("Head")
        local humanoid = enemy:FindFirstChildOfClass("Humanoid")
        if enemyHead and humanoid and humanoid.Health > 0 then
            table.insert(hitList, {enemy, enemyHead})
        end
    end
    if #hitList == 0 then
        return false
    end
    pcall(function()
        RegisterAttack:FireServer(0)
        RegisterHit:FireServer(head, hitList)
    end)
    return true
end

-- =============================================
-- ISLAND DATA (full list)
-- =============================================
local islands = {
    -- Normal Guys
    {Name = "Pirate Starter",     Min = 0,   Max = 10,  Pos = Vector3.new(944, 51, 1401), Quest = {"StartQuest","BanditQuest1",1}, EnemyPatterns = {"Bandit"}, isBoss = false},
    {Name = "Marine Starter",     Min = 0,   Max = 10,  Pos = Vector3.new(0,0,0), Quest = {"StartQuest","MarineQuest1",1}, EnemyPatterns = {"Trainee","Marine"}, isBoss = false},
    {Name = "Jungle (Normal)",    Min = 10,  Max = 15,  Pos = Vector3.new(-1620, 37, 144), Quest = {"StartQuest","JungleQuest",1}, EnemyPatterns = {"Monkey"}, isBoss = false},
    {Name = "Jungle (Stage 2)",   Min = 15,  Max = 20,  Pos = Vector3.new(-1206, 8, -448), Quest = {"StartQuest","JungleQuest",2}, EnemyPatterns = {"Gorilla"}, isBoss = false},
    {Name = "Pirate Village",     Min = 30,  Max = 40,  Pos = Vector3.new(-1151, 45, 3868), Quest = {"StartQuest","BuggyQuest1",1}, EnemyPatterns = {"Pirate"}, isBoss = false},
    {Name = "Pirate Village Stage 2", Min = 40, Max = 55, Pos = Vector3.new(-1151, 45, 3868), Quest = {"StartQuest","BuggyQuest1",2}, EnemyPatterns = {"Brute"}, isBoss = false},
    {Name = "Desert 1",           Min = 60, Max = 75, Pos = Vector3.new(938, 21, 4379), Quest = {"StartQuest","DesertQuest",1}, EnemyPatterns = {"Desert Bandit"}, isBoss = false},
    {Name = "Desert 2",           Min = 75, Max = 90, Pos = Vector3.new(1554, 15, 4391), Quest = {"StartQuest","DesertQuest",2}, EnemyPatterns = {"Desert Officer"}, isBoss = false},
    {Name = "Snow 1",             Min = 90, Max = 100, Pos = Vector3.new(1375, 106, -1408), Quest = {"StartQuest","SnowQuest",1}, EnemyPatterns = {"Snow Bandit"}, isBoss = false},
    {Name = "Snow 2",             Min = 100, Max = 120, Pos = Vector3.new(1375, 106, -1408), Quest = {"StartQuest","SnowQuest",2}, EnemyPatterns = {"Snowman"}, isBoss = false},
    {Name = "Fortress ding",      Min = 120, Max = 150, Pos = Vector3.new(-4884, 23, 4270), Quest = {"StartQuest","MarineQuest2",1}, EnemyPatterns = {"Chief Petty Officer"}, isBoss = false},
    {Name = "Sky 1",              Min = 150, Max = 175, Pos = Vector3.new(-4956, 296, -2893), Quest = {"StartQuest","SkyQuest",1}, EnemyPatterns = {"Sky Bandit"}, isBoss = false},
    {Name = "Sky 2",              Min = 175, Max = 190, Pos = Vector3.new(-5267, 389, -2283), Quest = {"StartQuest","SkyQuest",2}, EnemyPatterns = {"Dark Master"}, isBoss = false},
    {Name = "Prison 1",           Min = 190, Max = 210, Pos = Vector3.new(5117, 2, 483), Quest = {"StartQuest","PrisonerQuest",1}, EnemyPatterns = {"Prisoner"}, isBoss = false},
    {Name = "Prison 2",           Min = 210, Max = 250, Pos = Vector3.new(5117, 2, 483), Quest = {"StartQuest","PrisonerQuest",2}, EnemyPatterns = {"Dangerous Prisoner"}, isBoss = false},
    {Name = "Collosium 1",        Min = 250, Max = 299, Pos = Vector3.new(-1953, 7, -2752), Quest = {"StartQuest","ColosseumQuest",1}, EnemyPatterns = {"Toga Warrior"}, isBoss = false},
    {Name = "Vulcano 1",          Min = 300, Max = 324, Pos = Vector3.new(-5464, 9, 8449), Quest = {"StartQuest","MagmaQuest",1}, EnemyPatterns = {"Military Soldier"}, isBoss = false},
    {Name = "Vulcano 2",          Min = 325, Max = 374, Pos = Vector3.new(-5804, 98, 8797), Quest = {"StartQuest","MagmaQuest",2}, EnemyPatterns = {"Military Spy"}, isBoss = false},
    {Name = "Underwater 1",       Min = 375, Max = 400, Pos = Vector3.new(60856, 24, 1374), Quest = {"StartQuest","FishmanQuest",1}, EnemyPatterns = {"Fishman Warrior"}, isBoss = false},
    {Name = "Underwater 2",       Min = 400, Max = 450, Pos = Vector3.new(61898, 19, 1464), Quest = {"StartQuest","FishmanQuest",2}, EnemyPatterns = {"Fishman Commando"}, isBoss = false},
    {Name = "Lower Upper Sky 1",  Min = 450, Max = 475, Pos = Vector3.new(-4705, 845, -1916), Quest = {"StartQuest","SkyExp1Quest",1}, EnemyPatterns = {"God\'s Guard"}, isBoss = false},
	{Name = "Lower Upper Sky 2",  Min = 475, Max = 525, Pos = Vector3.new(-7637, 5546, -515), Quest = {"StartQuest","SkyExp1Quest",2}, EnemyPatterns = {"Shanda"}, isBoss = false},
    {Name = "Upper Sky 1",        Min = 525, Max = 550, Pos = Vector3.new(-7680, 5607, -1445), Quest = {"StartQuest","SkyExp2Quest",1}, EnemyPatterns = {"Royal Squad"}, isBoss = false},
    {Name = "Upper Sky 2",        Min = 550, Max = 625, Pos = Vector3.new(-7806, 5607, -1753), Quest = {"StartQuest","SkyExp2Quest",2}, EnemyPatterns = {"Royal Soldier"}, isBoss = false},
    {Name = "Fountain 1",         Min = 625, Max = 650, Pos = Vector3.new(5586, 54, 4031), Quest = {"StartQuest","FountainQuest",1}, EnemyPatterns = {"Galley Pirate"}, isBoss = false},
    {Name = "Fountain 2",         Min = 650, Max = 700, Pos = Vector3.new(5702, 39, 4920), Quest = {"StartQuest","FountainQuest",2}, EnemyPatterns = {"Galley Captain"}, isBoss = false},
    -- Tuff Guys
    {Name = "Jungle (Boss)",      Min = 20,  Max = 30,  Pos = Vector3.new(-1620, 37, -448), 
        Quest = {"StartQuest","JungleQuest",2}, EnemyPatterns = {"Gorilla"},
        BossQuest = {"StartQuest","JungleQuest",3}, BossPatterns = {"The Gorilla King"},
        isBoss = true},
    {Name = "Pirate Village Boss", Min = 55, Max = 60, Pos = Vector3.new(-1151, 45, 3868),
        Quest = {"StartQuest","BuggyQuest1",2}, EnemyPatterns = {"Brute"},
        BossQuest = {"StartQuest","BuggyQuest1",3}, BossPatterns = {"Chef"},
        isBoss = true},
    {Name = "Snow Boss",          Min = 105, Max = 120, Pos = Vector3.new(1375, 106, -1408),
        Quest = {"StartQuest","SnowQuest",2}, EnemyPatterns = {"Snowman"},
        BossQuest = {"StartQuest","SnowQuest",3}, BossPatterns = {"Yeti"},
        isBoss = true},
    {Name = "Marine Boss",        Min = 130, Max = 150, Pos = Vector3.new(-4884, 23, 4270),
        Quest = {"StartQuest","MarineQuest2",1}, EnemyPatterns = {"Chief Petty Officer"},
        BossQuest = {"StartQuest","MarineQuest2",2}, BossPatterns = {"Vice Admiral"},
        isBoss = true},
    {Name = "Warden",             Min = 220, Max = 250, Pos = Vector3.new(5117, 2, 483),
        Quest = {"StartQuest","PrisonerQuest",2}, EnemyPatterns = {"Dangerous Prisoner"},
        BossQuest = {"StartQuest","ImpelQuest",1}, BossPatterns = {"Warden"},
        isBoss = true},
    {Name = "Chief Warden",       Min = 230, Max = 250, Pos = Vector3.new(5117, 2, 483),
        Quest = {"StartQuest","PrisonerQuest",2}, EnemyPatterns = {"Dangerous Prisoner"},
        BossQuest = {"StartQuest","ImpelQuest",2}, BossPatterns = {"Chief Warden"},
        isBoss = true},
    {Name = "Swan",               Min = 240, Max = 250, Pos = Vector3.new(5117, 2, 483),
        Quest = {"StartQuest","PrisonerQuest",2}, EnemyPatterns = {"Dangerous Prisoner"},
        BossQuest = {"StartQuest","ImpelQuest",3}, BossPatterns = {"Swan"},
        isBoss = true},
    {Name = "Magma Admiral",               Min = 350, Max = 374, Pos = Vector3.new(-5804, 98, 8797),
        Quest = {"StartQuest","MagmaQuest",2}, EnemyPatterns = {"Military Spy"},
        BossQuest = {"StartQuest","MagmaQuest",3}, BossPatterns = {"Magma Admiral"},
        isBoss = true},
    {Name = "Fishman Lord",               Min = 425, Max = 450, Pos = Vector3.new(61898, 19, 1464),
        Quest = {"StartQuest","FishmanQuest",2}, EnemyPatterns = {"Fishman Commando"},
        BossQuest = {"StartQuest","FishmanQuest",3}, BossPatterns = {"Fishman Lord"},
        isBoss = true},
    {Name = "Wysper",               Min = 500, Max = 525, Pos = Vector3.new(-7637, 5546, -515),
        Quest = {"StartQuest","SkyExp1Quest",2}, EnemyPatterns = {"Shanda"},
        BossQuest = {"StartQuest","SkyExp1Quest",3}, BossPatterns = {"Wysper"},
        isBoss = true},
    {Name = "Thunder God",               Min = 575, Max = 625, Pos = Vector3.new(-7806, 5607, -1753),
        Quest = {"StartQuest","SkyExp2Quest",2}, EnemyPatterns = {"Royal Soldier"},
        BossQuest = {"StartQuest","SkyExp2Quest",3}, BossPatterns = {"Thunder God"},
        isBoss = true},
    {Name = "Cyborg",               Min = 675, Max = 700, Pos = Vector3.new(5702, 39, 4920),
        Quest = {"StartQuest","FountainQuest",2}, EnemyPatterns = {"Galley Captain"},
        BossQuest = {"StartQuest","FountainQuest",3}, BossPatterns = {"Cyborg"},
        isBoss = true},
        
}

table.sort(islands, function(a,b) return a.Min < b.Min end)

-- =============================================
-- NOCLIP & FLY
-- =============================================
local noclipConnection = nil

local function enableNoclip()
    if noclipConnection then return end
    noclipConnection = RunService.Heartbeat:Connect(function()
        local character = LocalPlayer.Character
        if not character then return end
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end)
end

local function disableNoclip()
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end
    local character = LocalPlayer.Character
    if character then
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end
end

local flyTarget = nil
local flyConnection = nil
local flying = false
local hoverY = nil

-- Keep the player on a stable horizontal flight plane.  The old implementation
-- always added upward velocity, which made the character arc and slowly sink.
local function enableFly()
    if flying then return end
    local character = LocalPlayer.Character
    if not character then return end
    local humanoid = character:FindFirstChild("Humanoid")
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not hrp then return end

    flying = true
    hoverY = hrp.Position.Y
    humanoid.PlatformStand = true
    enableNoclip()

    flyConnection = RunService.Heartbeat:Connect(function()
        if not flying then return end

        local currentCharacter = LocalPlayer.Character
        local currentHrp = currentCharacter and currentCharacter:FindFirstChild("HumanoidRootPart")
        local currentHumanoid = currentCharacter and currentCharacter:FindFirstChild("Humanoid")
        if not currentHrp or not currentHumanoid or currentHumanoid.Health <= 0 then return end

        if not hoverY then hoverY = currentHrp.Position.Y end

        local target = flyTarget
        if target then
            local delta = target - currentHrp.Position
            local horizontal = Vector3.new(delta.X, 0, delta.Z)
            local horizontalDistance = horizontal.Magnitude
            local verticalError = delta.Y

            local horizontalVelocity = Vector3.zero
            if horizontalDistance > 0.5 then
                local horizontalSpeed = math.min(config.flySpeed, math.max(20, horizontalDistance * 5))
                horizontalVelocity = horizontal.Unit * horizontalSpeed
            end

            -- Controlled vertical movement; no permanent +Y velocity.
            local verticalVelocity = math.clamp(verticalError * 5, -config.flySpeed, config.flySpeed)
            if math.abs(verticalError) < 0.75 then
                verticalVelocity = 0
            end

            currentHrp.AssemblyLinearVelocity = Vector3.new(
                horizontalVelocity.X,
                verticalVelocity,
                horizontalVelocity.Z
            )
            currentHrp.AssemblyAngularVelocity = Vector3.zero
        else
            -- Hover exactly where we are instead of using a fixed upward velocity.
            hoverY = hoverY or currentHrp.Position.Y
            local verticalError = hoverY - currentHrp.Position.Y
            currentHrp.AssemblyLinearVelocity = Vector3.new(0, math.clamp(verticalError * 6, -20, 20), 0)
            currentHrp.AssemblyAngularVelocity = Vector3.zero
        end
    end)
end

local function disableFly()
    if not flying then return end
    flying = false
    if flyConnection then
        flyConnection:Disconnect()
        flyConnection = nil
    end
    flyTarget = nil
    hoverY = nil

    local character = LocalPlayer.Character
    if character then
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        end
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then humanoid.PlatformStand = false end
    end
    disableNoclip()
end

local function setFlyTarget(position, preserveHeight)
    if not flying then enableFly() end
    if not position then
        flyTarget = nil
        return
    end

    if preserveHeight and hoverY then
        position = Vector3.new(position.X, hoverY, position.Z)
    else
        hoverY = position.Y
    end
    flyTarget = position
end

local function setHoverHeight(y)
    hoverY = y
    if flyTarget then
        flyTarget = Vector3.new(flyTarget.X, y, flyTarget.Z)
    end
end

-- Blox Fruits has an underwater entrance/whirlpool.  Servers can name the
-- object differently, so check both parts and models for common whirlpool names.
local function findWhirlpool()
    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local best = nil
    local bestDistance = math.huge
    local keywords = {"whirlpool", "vortex", "maelstrom", "swirl"}

    for _, obj in ipairs(Workspace:GetDescendants()) do
        local name = obj.Name:lower()
        local matches = false
        for _, keyword in ipairs(keywords) do
            if name:find(keyword, 1, true) then
                matches = true
                break
            end
        end

        if matches then
            local position = nil
            if obj:IsA("BasePart") then
                position = obj.Position
            elseif obj:IsA("Model") then
                local primary = obj.PrimaryPart
                if primary then
                    position = primary.Position
                else
                    local part = obj:FindFirstChildWhichIsA("BasePart", true)
                    if part then position = part.Position end
                end
            end

            if position then
                local distance = (position - hrp.Position).Magnitude
                if distance < bestDistance then
                    bestDistance = distance
                    best = {Object = obj, Position = position, Distance = distance}
                end
            end
        end
    end
    return best
end

local function isUnderwaterIsland(island)
    if not island then return false end
    return island.Name:lower():find("underwater", 1, true) ~= nil
        or island.Name:lower():find("submerged", 1, true) ~= nil
end

-- =============================================
-- QUEST STACK & HELPERS
-- =============================================
local function acceptQuest(questArgs)
    if not questArgs then return false end
    local remote = ReplicatedStorage:FindFirstChild("Remotes")
    if remote then
        local commF = remote:FindFirstChild("CommF_")
        if commF then
            commF:InvokeServer(unpack(questArgs))
            return true
        end
    end
    return false
end

local function stackQuest(questArgs, count)
    if not questArgs or count < 1 then return false end
    local remote = ReplicatedStorage:FindFirstChild("Remotes")
    if not remote then return false end
    local commF = remote:FindFirstChild("CommF_")
    if not commF then return false end
    for i = 1, count do
        pcall(function() commF:InvokeServer(unpack(questArgs)) end)
        task.wait(0.05)
    end
    return true
end

local function acceptQuestWrapper(questArgs)
    if config.questStack and questArgs then
        return stackQuest(questArgs, config.stackCount)
    else
        return acceptQuest(questArgs)
    end
end

local function abandonQuest()
    local remote = ReplicatedStorage:FindFirstChild("Remotes")
    if remote then
        local commF = remote:FindFirstChild("CommF_")
        if commF then
            pcall(function() commF:InvokeServer("AbandonQuest") end)
            return true
        end
    end
    return false
end

-- =============================================
-- AUTO EQUIP
-- =============================================
local function autoEquipWeapon()
    if not config.autoEquip then return end
    local character = LocalPlayer.Character
    if not character then return end
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end
    local currentTool = character:FindFirstChildOfClass("Tool")
    local currentType = currentTool and currentTool:GetAttribute("WeaponType")
    local preferred = config.preferredWeapon
    if preferred == "Any" and currentType then return end
    if preferred ~= "Any" and currentType == preferred then return end

    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not backpack then return end
    for _, tool in ipairs(backpack:GetChildren()) do
        if tool:IsA("Tool") then
            local wType = tool:GetAttribute("WeaponType")
            if wType then
                if preferred == "Any" or wType == preferred then
                    humanoid:EquipTool(tool)
                    return
                end
            end
        end
    end
end

-- =============================================
-- FRUIT NOTIFIER (SIMPLE)
-- =============================================
local fruitNotifierRunning = false
local fruitConnection = nil

local function fruitScan()
    if not config.fruitNotifier then return end
    for _, v in pairs(Workspace:GetChildren()) do
        if v:IsA("Tool") and v:FindFirstChild("Handle") or v.Name == "Fruit" and v:FindFirstChild("Handle") then
            -- Check if fruit is in a player's inventory (skip)
            local parent = v.Parent
            if parent and parent:IsA("Model") and parent:FindFirstChild("Humanoid") then
                continue
            end
            if parent and parent:IsA("Backpack") then
                continue
            end
            local fruitName = v.Name

            window:Notify({
                Title = "Fruit Detected",
                Content = "A " .. fruitName .. " has spawned!",
                Type = "Info",
                Duration = 0.1,
            })
            if config.fruitAutoCollect then
                -- Auto-collect: fly to fruit
                local pos = v.Handle.Position
                setFlyTarget(pos + Vector3.new(0, 5, 0))
                task.wait(0.5)
                local character = LocalPlayer.Character
                if character then
                    local hrp = character:FindFirstChild("HumanoidRootPart")
                    if hrp and (hrp.Position - pos).Magnitude < 15 then
                        VirtualInputManager:SendKeyEvent(true, "E", false, game)
                        task.wait(0.1)
                        VirtualInputManager:SendKeyEvent(false, "E", false, game)
                        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                        task.wait(0.1)
                        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
                        notifyUser("✅ Collected", fruitName .. " picked up!")
                    end
                end
            end
            break -- only notify once per scan
        end
    end
end

local function startFruitNotifier()
    if fruitNotifierRunning then return end
    fruitNotifierRunning = true
    fruitConnection = RunService.Heartbeat:Connect(function()
        if not fruitNotifierRunning then return end
        fruitScan()
        -- rate limit: scan every 2 seconds
        task.wait(2)
    end)
end

local function stopFruitNotifier()
    fruitNotifierRunning = false
    if fruitConnection then
        fruitConnection:Disconnect()
        fruitConnection = nil
    end
end

-- =============================================
-- HELPERS
-- =============================================
local function getPlayerLevel()
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    if leaderstats then
        local level = leaderstats:FindFirstChild("Level")
        if level then return level.Value end
    end
    local data = LocalPlayer:FindFirstChild("Data")
    if data then
        local level = data:FindFirstChild("Level")
        if level then return level.Value end
    end
    local attr = LocalPlayer:GetAttribute("Level")
    if attr then return attr end
    return 0
end

local function getAvailableStatPoints()
    local data = LocalPlayer:FindFirstChild("Data")
    if data then
        local points = data:FindFirstChild("Points")
        if points then return points.Value end
    end
    return 0
end

local function getIslandForLevel(level)
    local candidates = {}
    for _, island in ipairs(islands) do
        if level >= island.Min and level <= island.Max then
            if island.Pos.Magnitude > 0.1 then
                table.insert(candidates, island)
            end
        end
    end
    if #candidates == 0 then return islands[#islands] end
    local bossCandidates, normalCandidates = {}, {}
    for _, island in ipairs(candidates) do
        if island.isBoss then table.insert(bossCandidates, island) else table.insert(normalCandidates, island) end
    end
    local selectedList
    if config.bossPriority then
        selectedList = #bossCandidates > 0 and bossCandidates or normalCandidates
    else
        selectedList = #normalCandidates > 0 and normalCandidates or bossCandidates
    end
    table.sort(selectedList, function(a,b)
        if a.Max ~= b.Max then return a.Max > b.Max end
        return a.Min > b.Min
    end)
    return selectedList[1]
end

local function hasActiveQuest()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return false end
    local main = playerGui:FindFirstChild("Main")
    if not main then return false end
    local quest = main:FindFirstChild("Quest")
    if not quest then return false end
    return quest.Visible == true
end

-- =============================================
-- BOSS DETECTION
-- =============================================
local function findBossInWorkspace(island)
    if not island.isBoss then return nil end
    local container = Workspace:FindFirstChild("Enemies")
    if not container then return nil end
    for _, enemy in ipairs(container:GetChildren()) do
        if enemy:IsA("Model") then
            local humanoid = enemy:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                if enemy:GetAttribute("isBoss") == true then return enemy end
                for _, pattern in ipairs(island.BossPatterns) do
                    if enemy.Name:lower():find(pattern:lower()) then return enemy end
                end
            end
        end
    end
    return nil
end

local function bossExists(island)
    return findBossInWorkspace(island) ~= nil
end

local function getDesiredQuestType(island)
    if not island.isBoss then return "normal" end
    if bossExists(island) then return "boss" else return "normal" end
end

local function getQuestArgs(island, questType)
    if questType == "boss" then return island.BossQuest else return island.Quest end
end

local function getPatterns(island, questType)
    if questType == "boss" then
        return { patterns = island.BossPatterns, includeBossAttr = true }
    else
        return { patterns = island.EnemyPatterns, includeBossAttr = false }
    end
end

-- =============================================
-- ENEMY TARGETING
-- =============================================
local function enemyMatchesPatterns(enemy, patternInfo)
    if not enemy or not enemy:IsA("Model") then return false end
    local humanoid = enemy:FindFirstChildOfClass("Humanoid")
    local root = enemy:FindFirstChild("HumanoidRootPart")
    local head = enemy:FindFirstChild("Head")
    if not humanoid or humanoid.Health <= 0 or not root or not head then return false end
    if patternInfo.includeBossAttr and enemy:GetAttribute("isBoss") == true then return true end
    for _, pattern in ipairs(patternInfo.patterns) do
        if enemy.Name:lower():find(pattern:lower()) then return true end
    end
    return false
end

local function getMatchingEnemies(island, patternInfo)
    local container = Workspace:FindFirstChild("Enemies")
    if not container then return {} end
    local enemies = {}
    for _, enemy in ipairs(container:GetChildren()) do
        if enemyMatchesPatterns(enemy, patternInfo) then
            table.insert(enemies, enemy)
        end
    end
    return enemies
end

-- =============================================
-- FAST REMOTE ATTACK (no mouse)
-- =============================================
local function selectAttackWeapon()
    if config.attackMode == "Sword" then
        VirtualInputManager:SendKeyEvent(true, "1", false, game)
        task.wait(0.01)
        VirtualInputManager:SendKeyEvent(false, "1", false, game)
    elseif config.attackMode == "Gun" then
        VirtualInputManager:SendKeyEvent(true, "2", false, game)
        task.wait(0.01)
        VirtualInputManager:SendKeyEvent(false, "2", false, game)
    elseif config.attackMode == "Fruit" then
        VirtualInputManager:SendKeyEvent(true, "Z", false, game)
        task.wait(0.01)
        VirtualInputManager:SendKeyEvent(false, "Z", false, game)
    end
end

local function attackTargets(targets, speed, hits)
    if not targets or #targets == 0 then return end

    local validTargets = {}
    for _, target in ipairs(targets) do
        if target and target.Parent then
            local hum = target:FindFirstChildOfClass("Humanoid")
            local head = target:FindFirstChild("Head")
            if hum and hum.Health > 0 and head then
                table.insert(validTargets, target)
            end
        end
    end
    if #validTargets == 0 then return end

    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if hrp then
        local firstHead = validTargets[1]:FindFirstChild("Head")
        if firstHead then
            hrp.CFrame = CFrame.new(hrp.Position, firstHead.Position)
        end
    end

    selectAttackWeapon()

    for _ = 1, hits do
        local alive = {}
        for _, target in ipairs(validTargets) do
            local hum = target:FindFirstChildOfClass("Humanoid")
            local head = target:FindFirstChild("Head")
            if target.Parent and hum and hum.Health > 0 and head then
                table.insert(alive, target)
            end
        end
        if #alive == 0 then break end
        fireCombatHit(alive)
        task.wait(speed)
    end
end

local function attackEnemy(target, speed, hits)
    attackTargets({target}, speed, hits)
end

local function heal()
    local character = LocalPlayer.Character
    if not character then return end
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end
    if (humanoid.Health / humanoid.MaxHealth) * 100 < config.healThreshold then
        VirtualInputManager:SendKeyEvent(true, "H", false, game)
        task.wait(0.1)
        VirtualInputManager:SendKeyEvent(false, "H", false, game)
    end
end

-- =============================================
-- STATS SYSTEM
-- =============================================
local function addStatPoints(statName, points)
    if points <= 0 then return end
    local remote = ReplicatedStorage:FindFirstChild("Remotes")
    if remote then
        local commF = remote:FindFirstChild("CommF_")
        if commF then
            pcall(function() commF:InvokeServer("AddPoint", statName, points) end)
        end
    end
end

local function distributeStats(statsList, pointsPerStat, silent)
    if not statsList or #statsList == 0 then
        if not silent then notifyUser("Stats Error", "No stats selected.") end
        return
    end
    local available = getAvailableStatPoints()
    if available <= 0 then
        if not silent then notifyUser("No Stat Points", "You have 0 stat points available.") end
        return
    end
    local totalNeeded = #statsList * pointsPerStat
    local pointsToAdd = pointsPerStat
    if totalNeeded > available then
        pointsToAdd = math.floor(available / #statsList)
        if pointsToAdd == 0 then
            if not silent then notifyUser("Not Enough Points", "You have " .. available .. " points, need at least " .. #statsList .. " to add 1 to each stat.") end
            return
        end
    end
    local added = 0
    for _, stat in ipairs(statsList) do
        if available >= added + pointsToAdd then
            addStatPoints(stat, pointsToAdd)
            added = added + pointsToAdd
        else
            break
        end
    end
    local remaining = available - added
    if not silent and added > 0 then
        notifyUser("Stats Added", "Added " .. pointsToAdd .. " to " .. table.concat(statsList, ", ") .. ". Remaining: " .. remaining)
    end
end

-- =============================================
-- STATE MACHINE (FARMING)
-- =============================================
local farmRunning = false
local farmTask = nil
local lastIslandName = ""
local respawnConnection = nil
local equipCheckConnection = nil

local function setupRespawnRecovery()
    if respawnConnection then respawnConnection:Disconnect() end
    respawnConnection = LocalPlayer.CharacterAdded:Connect(function(character)
        if not farmRunning then return end
        local humanoid = character:WaitForChild("Humanoid", 10)
        local hrp = character:WaitForChild("HumanoidRootPart", 10)
        if humanoid and hrp and farmRunning then
            task.wait(0.5)
            if flying then disableFly() end
            enableFly()
        end
    end)
end

function startFarm()
    if farmRunning then return end
    farmRunning = true
    setupRespawnRecovery()
    enableFly()
    if config.fruitNotifier then startFruitNotifier() end

    if config.autoEquip then
        equipCheckConnection = RunService.Heartbeat:Connect(function()
            if farmRunning then autoEquipWeapon() end
        end)
    end

    farmTask = task.spawn(function()
        local state = "ISLAND"
        local questAccepted = false
        local currentLevel = getPlayerLevel()
        local lockedEnemy = nil
        local heightLocked = false
        local lockedY = 0
        local currentQuestType = "normal"
        local lastLevelForStats = currentLevel
        local isBossTarget = false
        local underwaterEntryDone = false
        local underwaterEntryStarted = false

        while farmRunning do
            local character = LocalPlayer.Character
            if not character then task.wait(0.5) continue end
            local humanoid = character:FindFirstChild("Humanoid")
            if not humanoid or humanoid.Health <= 0 then task.wait(0.5) continue end
            if not flying then enableFly() end
            if config.autoHeal then heal() end
            local characters = workspace:FindFirstChild("Characters")
            local localCharacter = characters and characters:FindFirstChild(LocalPlayer.Name)
            local busoHumanoid = localCharacter and localCharacter:FindFirstChild("Humanoid")
            if busoHumanoid and not busoHumanoid:FindFirstChild("LeftHand_BusoLayer1") then
                local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                local commF = remotes and remotes:FindFirstChild("CommF_")
                if commF then pcall(function() commF:InvokeServer("Buso") end) end
            end

            local level = getPlayerLevel()
            local island = getIslandForLevel(level)
            local hrp = character:FindFirstChild("HumanoidRootPart")
            if not hrp then task.wait(0.5) continue end

            if level ~= currentLevel then
                currentLevel = level
                if config.statEnabled and level > lastLevelForStats then
                    distributeStats(config.statsToAdd, config.pointsPerStat, false)
                end
                lastLevelForStats = level
                questAccepted = false
                state = "ISLAND"
                lockedEnemy = nil
                heightLocked = false
                currentQuestType = "normal"
                isBossTarget = false
                underwaterEntryDone = false
                underwaterEntryStarted = false
                if island.Name ~= lastIslandName then
                    lastIslandName = island.Name
                    notifyUser("New Island", "Now farming: " .. island.Name)
                end
            end

            if state == "ISLAND" then
                local underwater = isUnderwaterIsland(island)

                -- Underwater route: deliberately visit the whirlpool first rather
                -- than flying directly across the ocean to the island coordinates.
                if underwater and not underwaterEntryDone then
                    local whirlpool = findWhirlpool()
                    if whirlpool then
                        underwaterEntryStarted = true
                        if whirlpool.Distance > 65 then
                            setFlyTarget(whirlpool.Position + Vector3.new(0, 6, 0), false)
                            task.wait(0.08)
                            continue
                        end

                        -- Stay over the whirlpool briefly so its entrance/teleport
                        -- trigger has time to fire. Do not fly away immediately.
                        setFlyTarget(whirlpool.Position + Vector3.new(0, 4, 0), false)
                        task.wait(0.6)
                        underwaterEntryDone = true
                        setHoverHeight(hrp.Position.Y)
                        continue
                    else
                        -- If the server has no named whirlpool object, fall back to
                        -- the known island position instead of getting stuck forever.
                        underwaterEntryDone = true
                    end
                end

                local targetPos = island.Pos + Vector3.new(0, 25, 0)
                if (hrp.Position - targetPos).Magnitude > 50 then
                    setFlyTarget(targetPos, false)
                    task.wait(0.08)
                    continue
                else
                    setHoverHeight(hrp.Position.Y)
                    state = "QUEST"
                    continue
                end
            end

            if state == "QUEST" then
                if hasActiveQuest() then
                    questAccepted = true
                    state = "COMBAT"
                    continue
                end

                local bossEnemy = nil
                if island.isBoss then bossEnemy = findBossInWorkspace(island) end
                local desiredType = bossEnemy and "boss" or "normal"
                local questArgs = getQuestArgs(island, desiredType)

                if questArgs then
                    local success = acceptQuestWrapper(questArgs)
                    if success then
                        currentQuestType = desiredType
                        questAccepted = true
                        state = "COMBAT"
                        if desiredType == "boss" then
                            notifyUser("Boss Quest", "Boss detected – switched to boss quest.")
                        end
                        task.wait(0.5)
                    else
                        task.wait(2)
                    end
                else
                    state = "COMBAT"
                end
                continue
            end

            if state == "COMBAT" then
                if not hasActiveQuest() then
                    questAccepted = false
                    state = "QUEST"
                    lockedEnemy = nil
                    heightLocked = false
                    isBossTarget = false
                    continue
                end

                local bossEnemy = nil
                if island.isBoss then bossEnemy = findBossInWorkspace(island) end
                if bossEnemy and currentQuestType ~= "boss" then
                    abandonQuest()
                    questAccepted = false
                    state = "QUEST"
                    continue
                end

                if bossEnemy and bossEnemy.Parent and bossEnemy:FindFirstChildOfClass("Humanoid")
                    and bossEnemy:FindFirstChildOfClass("Humanoid").Health > 0 then
                    lockedEnemy = bossEnemy
                    isBossTarget = true
                else
                    isBossTarget = false
                    local patternInfo = getPatterns(island, currentQuestType)
                    local allTargets = getMatchingEnemies(island, patternInfo)
                    if #allTargets == 0 then
                        lockedEnemy = nil
                        state = "PATROL"
                        task.wait(0.15)
                        continue
                    end

                    if not lockedEnemy or not lockedEnemy.Parent
                        or not lockedEnemy:FindFirstChildOfClass("Humanoid")
                        or lockedEnemy:FindFirstChildOfClass("Humanoid").Health <= 0 then
                        local closest, closestDist = nil, math.huge
                        for _, enemy in ipairs(allTargets) do
                            local root = enemy:FindFirstChild("HumanoidRootPart")
                            if root then
                                local d = (root.Position - hrp.Position).Magnitude
                                if d < closestDist then
                                    closestDist = d
                                    closest = enemy
                                end
                            end
                        end
                        lockedEnemy = closest
                    end

                    if not lockedEnemy then
                        state = "PATROL"
                        continue
                    end
                end

                if lockedEnemy and lockedEnemy.Parent then
                    local targetHumanoid = lockedEnemy:FindFirstChildOfClass("Humanoid")
                    local targetRoot = lockedEnemy:FindFirstChild("HumanoidRootPart")
                    if targetHumanoid and targetRoot and targetHumanoid.Health > 0 then
                        local targetPos = targetRoot.Position
                        local distToTarget = (hrp.Position - targetPos).Magnitude

                        if distToTarget > config.attackRange then
                            setFlyTarget(targetPos + Vector3.new(0, config.aboveHeight, 0), false)
                            heightLocked = false
                            task.wait(0.03)
                        else
                            local speed = isBossTarget and config.bossAttackSpeed or config.attackSpeed
                            local hits = isBossTarget and config.bossHitsPerCycle or config.hitsPerCycle

                            if config.clusterEnabled and not isBossTarget then
                                local playerRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                                if playerRoot then
                                    if not heightLocked then
                                        lockedY = playerRoot.Position.Y
                                        heightLocked = true
                                    end

                                    local clusterTargets = {}
                                    local patternInfo = getPatterns(island, currentQuestType)
                                    local allTargets = getMatchingEnemies(island, patternInfo)
                                    local maxPull = config.maxClusterSize
                                    local pullCount = 0
                                    local clusterCenter = Vector3.new(playerRoot.Position.X, lockedY - config.clusterHeight, playerRoot.Position.Z)

                                    for _, enemy in ipairs(allTargets) do
                                        if maxPull > 0 and pullCount >= maxPull then break end
                                        local root = enemy:FindFirstChild("HumanoidRootPart")
                                        local head = enemy:FindFirstChild("Head")
                                        local hum = enemy:FindFirstChildOfClass("Humanoid")
                                        if root and hum and hum.Health > 0 then
                                            local spreadX = ((pullCount % 4) - 1.5) * 1.5
                                            local spreadZ = (math.floor(pullCount / 4) % 2) * 1.5
                                            pcall(function()
                                                root.CanCollide = false
                                                if head then head.CanCollide = false end
                                                root.AssemblyLinearVelocity = Vector3.zero
                                                root.CFrame = CFrame.new(clusterCenter + Vector3.new(spreadX, 0, spreadZ))
                                                hum.WalkSpeed = 0
                                                hum.JumpPower = 0
                                            end)
                                            table.insert(clusterTargets, enemy)
                                            pullCount = pullCount + 1
                                        end
                                    end

                                    setFlyTarget(Vector3.new(playerRoot.Position.X, lockedY, playerRoot.Position.Z), false)

                                    -- IMPORTANT: attack the entire cluster in one
                                    -- remote call instead of repeatedly attacking
                                    -- only lockedEnemy.
                                    if #clusterTargets > 0 then
                                        attackTargets(clusterTargets, speed, hits)
                                    else
                                        attackEnemy(lockedEnemy, speed, hits)
                                    end
                                end
                            else
                                setFlyTarget(targetPos + Vector3.new(0, config.aboveHeight, 0), false)
                                attackEnemy(lockedEnemy, speed, hits)
                            end
                            task.wait(0.01)
                        end
                    else
                        lockedEnemy = nil
                    end
                else
                    lockedEnemy = nil
                end
                continue
            end

            if state == "PATROL" then
                if not hasActiveQuest() then
                    questAccepted = false
                    state = "QUEST"
                    continue
                end

                -- No enemy: stay at the current safe Y. The old code used a
                -- target of nil plus a fixed +Y velocity, which caused the slow fall.
                if heightLocked then
                    setFlyTarget(Vector3.new(hrp.Position.X, lockedY, hrp.Position.Z), false)
                else
                    if not hoverY then hoverY = hrp.Position.Y end
                    setFlyTarget(Vector3.new(hrp.Position.X, hoverY, hrp.Position.Z), false)
                end

                local bossEnemy = nil
                if island.isBoss then bossEnemy = findBossInWorkspace(island) end
                if bossEnemy then
                    lockedEnemy = bossEnemy
                    isBossTarget = true
                    state = "COMBAT"
                else
                    local patternInfo = getPatterns(island, currentQuestType)
                    local enemies = getMatchingEnemies(island, patternInfo)
                    if #enemies > 0 then
                        state = "COMBAT"
                    else
                        task.wait(0.2)
                    end
                end
                continue
            end

            task.wait(0.1)
        end

        if equipCheckConnection then
            equipCheckConnection:Disconnect()
            equipCheckConnection = nil
        end
        if fruitNotifierRunning then stopFruitNotifier() end
        disableFly()
    end)
end

function stopFarm()
    farmRunning = false
    if farmTask then task.cancel(farmTask) farmTask = nil end
    if respawnConnection then respawnConnection:Disconnect() end
    if equipCheckConnection then equipCheckConnection:Disconnect() equipCheckConnection = nil end
    if fruitNotifierRunning then stopFruitNotifier() end
    fruitTarget = nil
    disableFly()
    notifyUser("Stopped", "Farm stopped.")
end

-- =============================================
-- VAXORIN UI CREATION (if successful)
-- =============================================
if useVaxorin and window then
    local mainTab = window:CreateTab("Farm")
    local combatTab = window:CreateTab("Combat")
    local statsTab = window:CreateTab("Stats")
    local equipTab = window:CreateTab("Equipment")
    local fruitTab = window:CreateTab("Fruits")

    local mainSection = mainTab:CreateSection({Name = "Farm Controls"})
    mainSection:CreateToggle({
        Name = "Auto Farm",
        CurrentValue = false,
        Flag = "Farm.Enabled", Save = true,
        Callback = function(v)
            if v then startFarm() else stopFarm() end
        end,
    })
    mainSection:CreateToggle({
        Name = "Boss Priority",
        CurrentValue = config.bossPriority,
        Flag = "Farm.BossPriority", Save = true,
        Callback = function(v) config.bossPriority = v end,
    })
    mainSection:CreateToggle({
        Name = "Quest Stack (Glitch)",
        CurrentValue = config.questStack,
        Flag = "Farm.QuestStack", Save = true,
        Callback = function(v) config.questStack = v end,
    })
    mainSection:CreateSlider({
        Name = "Stack Count",
        Min = 2, Max = 10, CurrentValue = config.stackCount, Rounding = 1,
        Flag = "Farm.StackCount", Save = true,
        Callback = function(v) config.stackCount = v end,
    })
    mainSection:CreateToggle({
        Name = "Cluster Enemies",
        CurrentValue = config.clusterEnabled,
        Flag = "Farm.ClusterEnabled", Save = true,
        Callback = function(v) config.clusterEnabled = v end,
    })
    mainSection:CreateSlider({
        Name = "Max Cluster Size",
        Min = 0, Max = 30, CurrentValue = config.maxClusterSize, Rounding = 1,
        Flag = "Farm.MaxClusterSize", Save = true,
        Callback = function(v) config.maxClusterSize = v end,
    })
    mainSection:CreateSlider({
        Name = "Fly Speed",
        Min = 30, Max = 200, CurrentValue = config.flySpeed, Rounding = 5,
        Flag = "Farm.FlySpeed", Save = true,
        Callback = function(v) config.flySpeed = v end,
    })
    mainSection:CreateSlider({
        Name = "Safe Height",
        Min = 6, Max = 25, CurrentValue = config.aboveHeight, Rounding = 1,
        Flag = "Farm.AboveHeight", Save = true,
        Callback = function(v) config.aboveHeight = v end,
    })
    mainSection:CreateSlider({
        Name = "Attack Radius",
        Min = 8, Max = 30, CurrentValue = config.attackRange, Rounding = 1,
        Flag = "Farm.AttackRange", Save = true,
        Callback = function(v) config.attackRange = v end,
    })
    mainSection:CreateSlider({
        Name = "Cluster Height",
        Min = 6, Max = 20, CurrentValue = config.clusterHeight, Rounding = 1,
        Flag = "Farm.ClusterHeight", Save = true,
        Callback = function(v) config.clusterHeight = v end,
    })
    mainSection:CreateButton({
        Name = "Emergency Stop",
        Callback = function()
            stopFarm()
            notifyUser("Stopped", "Landed.")
        end,
    })

    local combatSection = combatTab:CreateSection({Name = "Combat Settings"})
    combatSection:CreateDropdown({
        Name = "Attack Mode (key bind)",
        Options = {"Melee", "Sword", "Gun", "Fruit"},
        CurrentOption = config.attackMode,
        Flag = "Combat.AttackMode", Save = true,
        Callback = function(v) config.attackMode = v end,
    })
    combatSection:CreateSlider({
        Name = "Attack Speed (normal)",
        Min = 0.001, Max = 0.05, CurrentValue = config.attackSpeed, Rounding = 0.001,
        Flag = "Combat.AttackSpeed", Save = true,
        Callback = function(v) config.attackSpeed = v end,
    })
    combatSection:CreateSlider({
        Name = "Boss Attack Speed (faster)",
        Min = 0.001, Max = 0.05, CurrentValue = config.bossAttackSpeed, Rounding = 0.001,
        Flag = "Combat.BossAttackSpeed", Save = true,
        Callback = function(v) config.bossAttackSpeed = v end,
    })
    combatSection:CreateSlider({
        Name = "Hits per Cycle (normal)",
        Min = 5, Max = 30, CurrentValue = config.hitsPerCycle, Rounding = 1,
        Flag = "Combat.HitsPerCycle", Save = true,
        Callback = function(v) config.hitsPerCycle = v end,
    })
    combatSection:CreateSlider({
        Name = "Hits per Cycle (boss)",
        Min = 5, Max = 40, CurrentValue = config.bossHitsPerCycle, Rounding = 1,
        Flag = "Combat.BossHitsPerCycle", Save = true,
        Callback = function(v) config.bossHitsPerCycle = v end,
    })
    combatSection:CreateToggle({
        Name = "Auto Heal",
        CurrentValue = config.autoHeal,
        Flag = "Combat.AutoHeal", Save = true,
        Callback = function(v) config.autoHeal = v end,
    })
    combatSection:CreateSlider({
        Name = "Heal Threshold (%)",
        Min = 10, Max = 80, CurrentValue = config.healThreshold, Rounding = 5,
        Flag = "Combat.HealThreshold", Save = true,
        Callback = function(v) config.healThreshold = v end,
    })

    local statsSection = statsTab:CreateSection({Name = "Auto Stats"})
    statsSection:CreateToggle({
        Name = "Enable Auto Stats",
        CurrentValue = config.statEnabled,
        Flag = "Stats.Enabled", Save = true,
        Callback = function(v) config.statEnabled = v end,
    })
    statsSection:CreateDropdown({
        Name = "Stats to Add",
        Options = {"Melee", "Defense", "Sword", "Gun", "Fruit"},
        MultipleOptions = true,
        CurrentOption = config.statsToAdd,
        Flag = "Stats.StatsList", Save = true,
        Callback = function(v) config.statsToAdd = v end,
    })
    statsSection:CreateSlider({
        Name = "Points per Stat per Level",
        Min = 1, Max = 10, CurrentValue = config.pointsPerStat, Rounding = 1,
        Flag = "Stats.PointsPerStat", Save = true,
        Callback = function(v) config.pointsPerStat = v end,
    })
    statsSection:CreateButton({
        Name = "Add Points Now",
        Callback = function()
            distributeStats(config.statsToAdd, config.pointsPerStat, false)
        end,
    })

    local equipSection = equipTab:CreateSection({Name = "Auto Equip"})
    equipSection:CreateToggle({
        Name = "Auto Equip",
        CurrentValue = config.autoEquip,
        Flag = "Equip.AutoEquip", Save = true,
        Callback = function(v) config.autoEquip = v end,
    })
    equipSection:CreateDropdown({
        Name = "Preferred Weapon",
        Options = {"Melee", "Sword", "Gun", "Fruit", "Any"},
        CurrentOption = config.preferredWeapon,
        Flag = "Equip.PreferredWeapon", Save = true,
        Callback = function(v) config.preferredWeapon = v end,
    })

    local fruitSection = fruitTab:CreateSection({Name = "Fruit Notifier"})
    fruitSection:CreateToggle({
        Name = "Fruit Notifier",
        CurrentValue = config.fruitNotifier,
        Flag = "Fruit.Notifier", Save = true,
        Callback = function(v)
            config.fruitNotifier = v
            if v then
                if farmRunning then startFruitNotifier() end
            else
                stopFruitNotifier()
            end
        end,
    })
    fruitSection:CreateToggle({
        Name = "Auto Collect",
        CurrentValue = config.fruitAutoCollect,
        Flag = "Fruit.AutoCollect", Save = true,
        Callback = function(v) config.fruitAutoCollect = v end,
    })

    window:SetWatermarkEnabled(true)
    notifyUser("Loaded", "Vaxorin UI active. Toggle farm.")
else
    notifyUser("Loaded", "Fallback UI active. Use the button to start/stop.")
end

-- Keep script alive
while task.wait(1) do end
