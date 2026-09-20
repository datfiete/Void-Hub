local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Executor = "unknown"
pcall(function()
    if type(getexecutorname) == "function" then Executor = tostring(getexecutorname())
    elseif type(identifyexecutor) == "function" then Executor = tostring(identifyexecutor()) end
end)
print("[BF] load ok")

-- Load Vaxorin (or fallback UI)
local useVaxorin = false
local window = nil
local notifierLabel = nil  -- fallback notification label

-- Notification helper:
--   notifyUser(title, content)
--   notifyUser(title, content, duration)           -- seconds (default 3)
--   notifyUser(title, content, 0) or "sticky"     -- stays until closed / replaced
-- Flood protection: same title+content won't re-fire within 2.5s
local _notifyLast = {} -- key -> os.clock()
local function notifyUser(title, content, duration)
    title = tostring(title or "")
    content = tostring(content or "")
    local sticky = false
    if duration == "sticky" or duration == 0 then
        sticky = true
        duration = 999999
    elseif type(duration) ~= "number" then
        duration = 3
    end

    local key = title .. "|" .. content
    local now = os.clock()
    local last = _notifyLast[key]
    if last and (now - last) < 2.5 and not sticky then
        return -- throttle spam
    end
    _notifyLast[key] = now

    if window and window.Notify then
        window:Notify({
            Title = title,
            Content = content,
            Type = "Info",
            Duration = duration,
        })
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
            Subtitle = "by Fietewoozle",
            Logo = "rbxassetid://135320038058277",
            Badges = {{Text = "Vaxorin | v1.0"}, {Text = "Executor : " .. Executor}},
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

-- If Vaxorin failed, create a simple fallback UI with notifications
if not useVaxorin or not window then
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "FallbackUI"
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 400, 0, 200)
    frame.Position = UDim2.new(0.5, -200, 0.5, -100)
    frame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.15)
    frame.BorderSizePixel = 0
    frame.Parent = screenGui

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 35)
    title.Position = UDim2.new(0, 0, 0, 5)
    title.BackgroundTransparency = 1
    title.Text = "Blox Fruits Auto Farm"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.Parent = frame

    notifierLabel = Instance.new("TextLabel")
    notifierLabel.Size = UDim2.new(1, -20, 1, -50)
    notifierLabel.Position = UDim2.new(0, 10, 0, 45)
    notifierLabel.BackgroundTransparency = 1
    notifierLabel.Text = "Ready"
    notifierLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
    notifierLabel.TextWrapped = true
    notifierLabel.TextScaled = true
    notifierLabel.Font = Enum.Font.Gotham
    notifierLabel.Parent = frame

    -- Simple toggle button (Start/Stop farm) – we'll just use the same functions later
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 120, 0, 40)
    toggleBtn.Position = UDim2.new(0.5, -60, 0, 150)
    toggleBtn.BackgroundColor3 = Color3.new(0.2, 0.8, 0.2)
    toggleBtn.Text = "Start Farm"
    toggleBtn.TextColor3 = Color3.new(1, 1, 1)
    toggleBtn.TextScaled = true
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.Parent = frame
    toggleBtn.MouseButton1Click:Connect(function()
        if farmRunning then
            stopFarm()
            toggleBtn.Text = "Start Farm"
            toggleBtn.BackgroundColor3 = Color3.new(0.2, 0.8, 0.2)
            notifierLabel.Text = "Farm stopped"
        else
            startFarm()
            toggleBtn.Text = "Stop Farm"
            toggleBtn.BackgroundColor3 = Color3.new(0.8, 0.2, 0.2)
            notifierLabel.Text = "Farming..."
        end
    end)

    notifyUser("UI Loaded", "Fallback UI active (Vaxorin unavailable).")
end

-- =============================================
-- CONFIG (user settings)
-- =============================================
local config = {
    flySpeed = 180,
    attackMode = "Melee",
    autoHeal = false,
    healThreshold = 30,
    aboveHeight = 15,
    attackRange = 30,
    attackSpeed = 0.002,
    bossAttackSpeed = 0.001,
    hitsPerCycle = 25,
    bossHitsPerCycle = 35,
    clusterEnabled = true,
    clusterHeight = 12,
    maxClusterSize = 15,
    clusterRange = 300, -- how far to pull mobs into cluster
    statEnabled = false,
    statsToAdd = {"Melee", "Defense"},
    pointsPerStat = 1,
    bossPriority = true,
    autoEquip = true,
    preferredWeapon = "Melee",
    questStack = false,
    stackCount = 3,
    fruitNotifier = true,        -- fruit notifier toggle
    fruitAutoCollect = false,
    bossTimersEnabled = true,    -- show boss respawn board
    bossSpawnNotify = true,
    autoSeaProgress = false, -- off by default until stable
}

-- =============================================
-- COMBAT REMOTES
-- =============================================
local function getCombatRemotes()
    local modules = ReplicatedStorage:FindFirstChild("Modules")
    local net = modules and modules:FindFirstChild("Net")
    if not net then
        return nil, nil
    end
    return net:FindFirstChild("RE/RegisterAttack"), net:FindFirstChild("RE/RegisterHit")
end

-- Multi-hit like:
-- RegisterHit:FireServer(primaryHead, { {enemy, head}, {enemy2, head2}, ... })
local function fireCombatHit(targets)
    if not targets or #targets == 0 then
        return false
    end
    local RegisterAttack, RegisterHit = getCombatRemotes()
    if not RegisterHit then
        return false
    end

    local hitList = {}
    local primaryHead = nil
    for _, enemy in ipairs(targets) do
        if enemy and enemy.Parent then
            local enemyHead = enemy:FindFirstChild("Head")
            local humanoid = enemy:FindFirstChildOfClass("Humanoid")
            if enemyHead and humanoid and humanoid.Health > 0 then
                table.insert(hitList, { enemy, enemyHead })
                if not primaryHead then
                    primaryHead = enemyHead
                end
            end
        end
    end
    if not primaryHead or #hitList == 0 then
        return false
    end

    pcall(function()
        if RegisterAttack then
            RegisterAttack:FireServer(0)
        end
        -- primary head first arg, full multi-target list second (your working format)
        RegisterHit:FireServer(primaryHead, hitList)
    end)
    return true
end

-- Cluster / Bring (hub-style, less immortal desync):
-- 1) sethiddenproperty SimulationRadius so client can own NPC physics
-- 2) Bring same-name mobs to a FIXED stack point (first target), not under flying player
-- 3) Player stands above that point and multi-hits
-- Constant CFrame under a moving flyer = server position desync = red markers, 0 damage
local clusterStackPos = nil
local lastBringAt = 0

local function ensureSimRadius()
    pcall(function()
        sethiddenproperty(LocalPlayer, "SimulationRadius", 10000)
    end)
    pcall(function()
        sethiddenproperty(LocalPlayer, "MaxSimulationRadius", 10000)
    end)
end

local function collectNearbyTargets(allTargets, playerRoot, lockedEnemy, maxCount, radius)
    ensureSimRadius()
    local list = {}
    local seen = {}
    local now = os.clock()
    local shouldBring = (now - lastBringAt) >= 0.12
    if shouldBring then
        lastBringAt = now
    end

    -- Fixed stack: locked enemy position (or first valid target), refresh slowly
    if lockedEnemy and lockedEnemy.Parent then
        local lr = lockedEnemy:FindFirstChild("HumanoidRootPart")
        if lr then
            if not clusterStackPos or (clusterStackPos - lr.Position).Magnitude > 40 then
                clusterStackPos = lr.Position
            end
        end
    end
    if not clusterStackPos then
        clusterStackPos = playerRoot.Position - Vector3.new(0, 6, 0)
    end

    local function add(enemy, index, doPull)
        if not enemy or seen[enemy] or not enemy.Parent then
            return
        end
        local root = enemy:FindFirstChild("HumanoidRootPart")
        local head = enemy:FindFirstChild("Head")
        local hum = enemy:FindFirstChildOfClass("Humanoid")
        if not root or not head or not hum or hum.Health <= 0 then
            return
        end
        local dist = (root.Position - clusterStackPos).Magnitude
        if dist > radius then
            return
        end
        if doPull and shouldBring then
            local sx = ((index % 4) - 1.5) * 1.2
            local sz = (math.floor(index / 4) % 3) * 1.2
            pcall(function()
                -- Prefer network owner when available
                local can = true
                if isnetworkowner then
                    can = isnetworkowner(root)
                end
                if can then
                    root.CFrame = CFrame.new(clusterStackPos + Vector3.new(sx, 0, sz))
                    root.AssemblyLinearVelocity = Vector3.zero
                    root.AssemblyAngularVelocity = Vector3.zero
                    if hum then
                        hum.WalkSpeed = 0
                        hum.JumpPower = 0
                    end
                end
            end)
        end
        seen[enemy] = true
        table.insert(list, enemy)
    end

    local idx = 0
    if lockedEnemy then
        add(lockedEnemy, idx, true)
        idx = idx + 1
    end
    local scored = {}
    for _, enemy in ipairs(allTargets or {}) do
        local root = enemy and enemy:FindFirstChild("HumanoidRootPart")
        if root then
            table.insert(scored, {
                enemy = enemy,
                d = (root.Position - clusterStackPos).Magnitude,
            })
        end
    end
    table.sort(scored, function(a, b)
        return a.d < b.d
    end)
    for _, item in ipairs(scored) do
        if maxCount > 0 and #list >= maxCount then
            break
        end
        add(item.enemy, idx, true)
        idx = idx + 1
    end
    return list
end


-- =============================================
-- ISLAND DATA (full list)
-- =============================================
local islands = {
    -- ========== SEA 1 — Normal ==========
    {Name = "Pirate Starter",     Min = 0,   Max = 10,  Pos = Vector3.new(944, 51, 1401), Quest = {"StartQuest","BanditQuest1",1}, EnemyPatterns = {"Bandit"}, isBoss = false},
    {Name = "Marine Starter",     Min = 0,   Max = 10,  Pos = Vector3.new(-2723, 32, 2090), Quest = {"StartQuest","MarineQuest1",1}, EnemyPatterns = {"Trainee"}, isBoss = false},
    {Name = "Jungle (Normal)",    Min = 10,  Max = 15,  Pos = Vector3.new(-1620, 37, 144), Quest = {"StartQuest","JungleQuest",1}, EnemyPatterns = {"Monkey"}, isBoss = false},
    {Name = "Jungle (Stage 2)",   Min = 15,  Max = 20,  Pos = Vector3.new(-1206, 8, -448), Quest = {"StartQuest","JungleQuest",2}, EnemyPatterns = {"Gorilla"}, isBoss = false},
    {Name = "Pirate Village",     Min = 30,  Max = 40,  Pos = Vector3.new(-1151, 45, 3868), Quest = {"StartQuest","BuggyQuest1",1}, EnemyPatterns = {"Pirate"}, isBoss = false},
    {Name = "Pirate Village Stage 2", Min = 40, Max = 55, Pos = Vector3.new(-1151, 45, 3868), Quest = {"StartQuest","BuggyQuest1",2}, EnemyPatterns = {"Brute"}, isBoss = false},
    {Name = "Desert 1",           Min = 60, Max = 75, Pos = Vector3.new(924, 8, 4514), Quest = {"StartQuest","DesertQuest",1}, EnemyPatterns = {"Desert Bandit"}, isBoss = false},
    {Name = "Desert 2",           Min = 75, Max = 90, Pos = Vector3.new(1573, 14, 4159), Quest = {"StartQuest","DesertQuest",2}, EnemyPatterns = {"Desert Officer"}, isBoss = false},
    {Name = "Snow 1",             Min = 90, Max = 100, Pos = Vector3.new(1364, 78, -1430), Quest = {"StartQuest","SnowQuest",1}, EnemyPatterns = {"Snow Bandit"}, isBoss = false},
    {Name = "Snow 2",             Min = 100, Max = 120, Pos = Vector3.new(1375, 106, -1408), Quest = {"StartQuest","SnowQuest",2}, EnemyPatterns = {"Snowman"}, isBoss = false},
    {Name = "Marine Fortress",    Min = 120, Max = 150, Pos = Vector3.new(-4834, 13, 4277), Quest = {"StartQuest","MarineQuest2",1}, EnemyPatterns = {"Chief Petty Officer"}, isBoss = false},
    {Name = "Sky 1",              Min = 150, Max = 175, Pos = Vector3.new(-5092, 281, -1019), Quest = {"StartQuest","SkyQuest",1}, EnemyPatterns = {"Sky Bandit"}, isBoss = false},
    {Name = "Sky 2",              Min = 175, Max = 190, Pos = Vector3.new(-5293, 505, -351), Quest = {"StartQuest","SkyQuest",2}, EnemyPatterns = {"Dark Master"}, isBoss = false},
    {Name = "Prison 1",           Min = 190, Max = 210, Pos = Vector3.new(5272, 7, 468), Quest = {"StartQuest","PrisonerQuest",1}, EnemyPatterns = {"Prisoner"}, isBoss = false},
    {Name = "Prison 2",           Min = 210, Max = 250, Pos = Vector3.new(5252, 20, 865), Quest = {"StartQuest","PrisonerQuest",2}, EnemyPatterns = {"Dangerous Prisoner"}, isBoss = false},
    {Name = "Colosseum",          Min = 250, Max = 299, Pos = Vector3.new(-1685, 10, -2765), Quest = {"StartQuest","ColosseumQuest",1}, EnemyPatterns = {"Toga Warrior"}, isBoss = false},
    {Name = "Colosseum 2",        Min = 275, Max = 299, Pos = Vector3.new(-1175, 12, -3214), Quest = {"StartQuest","ColosseumQuest",2}, EnemyPatterns = {"Gladiator"}, isBoss = false},
    {Name = "Volcano 1",          Min = 300, Max = 324, Pos = Vector3.new(-5445, 17, 8434), Quest = {"StartQuest","MagmaQuest",1}, EnemyPatterns = {"Military Soldier"}, isBoss = false},
    {Name = "Volcano 2",          Min = 325, Max = 374, Pos = Vector3.new(-5842, 77, 8773), Quest = {"StartQuest","MagmaQuest",2}, EnemyPatterns = {"Military Spy"}, isBoss = false},
    {Name = "Underwater 1",       Min = 375, Max = 399, Pos = Vector3.new(60793, 24, 1361), Quest = {"StartQuest","FishmanQuest",1}, EnemyPatterns = {"Fishman Warrior"}, isBoss = false},
    {Name = "Underwater 2",       Min = 400, Max = 449, Pos = Vector3.new(61928, 25, 1331), Quest = {"StartQuest","FishmanQuest",2}, EnemyPatterns = {"Fishman Commando"}, isBoss = false},
    {Name = "Lower Upper Sky 1",  Min = 450, Max = 474, Pos = Vector3.new(-4705, 845, -1916), Quest = {"StartQuest","SkyExp1Quest",1}, EnemyPatterns = {"God's Guard"}, isBoss = false},
    {Name = "Lower Upper Sky 2",  Min = 475, Max = 524, Pos = Vector3.new(-7637, 5546, -515), Quest = {"StartQuest","SkyExp1Quest",2}, EnemyPatterns = {"Shanda"}, isBoss = false},
    {Name = "Upper Sky 1",        Min = 525, Max = 549, Pos = Vector3.new(-7680, 5607, -1445), Quest = {"StartQuest","SkyExp2Quest",1}, EnemyPatterns = {"Royal Squad"}, isBoss = false},
    {Name = "Upper Sky 2",        Min = 550, Max = 624, Pos = Vector3.new(-7137, 5541, 893), Quest = {"StartQuest","SkyExp2Quest",2}, EnemyPatterns = {"Royal Soldier"}, isBoss = false},
    {Name = "Fountain 1",         Min = 625, Max = 649, Pos = Vector3.new(5577, 78, 3968), Quest = {"StartQuest","FountainQuest",1}, EnemyPatterns = {"Galley Pirate"}, isBoss = false},
    {Name = "Fountain 2",         Min = 650, Max = 700, Pos = Vector3.new(5572, 78, 4780), Quest = {"StartQuest","FountainQuest",2}, EnemyPatterns = {"Galley Captain"}, isBoss = false},

    -- ========== SEA 2 — Normal ==========
    {Name = "Area1 Raider",       Min = 700, Max = 724, Pos = Vector3.new(-189, 40, 2354), Quest = {"StartQuest","Area1Quest",1}, EnemyPatterns = {"Raider"}, isBoss = false},
    {Name = "Area1 Mercenary",    Min = 725, Max = 774, Pos = Vector3.new(-1043, 73, 1411), Quest = {"StartQuest","Area1Quest",2}, EnemyPatterns = {"Mercenary"}, isBoss = false},
    {Name = "Area2 Swan Pirate",  Min = 775, Max = 799, Pos = Vector3.new(1019, 73, 1221), Quest = {"StartQuest","Area2Quest",1}, EnemyPatterns = {"Swan Pirate","Factory Staff"}, isBoss = false},
    {Name = "Factory Staff",      Min = 800, Max = 874, Pos = Vector3.new(231, 73, -137), Quest = {"StartQuest","Area2Quest",2}, EnemyPatterns = {"Factory Staff"}, isBoss = false},
    {Name = "Marine Lieutenant",  Min = 875, Max = 899, Pos = Vector3.new(-2911, 71, -2940), Quest = {"StartQuest","MarineQuest3",1}, EnemyPatterns = {"Marine Lieutenant"}, isBoss = false},
    {Name = "Marine Captain",     Min = 900, Max = 949, Pos = Vector3.new(-1916, 73, -3293), Quest = {"StartQuest","MarineQuest3",2}, EnemyPatterns = {"Marine Captain"}, isBoss = false},
    {Name = "Zombie",             Min = 950, Max = 974, Pos = Vector3.new(-5685, 53, -755), Quest = {"StartQuest","ZombieQuest",1}, EnemyPatterns = {"Zombie"}, isBoss = false},
    {Name = "Vampire",            Min = 975, Max = 999, Pos = Vector3.new(-6036, 9, -1355), Quest = {"StartQuest","ZombieQuest",2}, EnemyPatterns = {"Vampire"}, isBoss = false},
    {Name = "Snow Trooper",       Min = 1000, Max = 1049, Pos = Vector3.new(483, 411, -5425), Quest = {"StartQuest","SnowMountainQuest",1}, EnemyPatterns = {"Snow Trooper"}, isBoss = false},
    {Name = "Winter Warrior",     Min = 1050, Max = 1099, Pos = Vector3.new(1216, 429, -5307), Quest = {"StartQuest","SnowMountainQuest",2}, EnemyPatterns = {"Winter Warrior"}, isBoss = false},
    {Name = "Lab Subordinate",    Min = 1100, Max = 1124, Pos = Vector3.new(-5821, 84, -4409), Quest = {"StartQuest","IceSideQuest",1}, EnemyPatterns = {"Lab Subordinate"}, isBoss = false},
    {Name = "Horned Warrior",     Min = 1125, Max = 1150, Pos = Vector3.new(-6342, 29, -5818), Quest = {"StartQuest","IceSideQuest",2}, EnemyPatterns = {"Horned Warrior"}, isBoss = false},
    {Name = "Magma Ninja",        Min = 1175, Max = 1199, Pos = Vector3.new(-5784, 37, -5559), Quest = {"StartQuest","FireSideQuest",1}, EnemyPatterns = {"Magma Ninja"}, isBoss = false},
    {Name = "Lava Pirate",        Min = 1200, Max = 1249, Pos = Vector3.new(-5078, 29, -4934), Quest = {"StartQuest","FireSideQuest",2}, EnemyPatterns = {"Lava Pirate"}, isBoss = false},
    {Name = "Ship Deckhand",      Min = 1250, Max = 1274, Pos = Vector3.new(861, 126, 33085), Quest = {"StartQuest","ShipQuest1",1}, EnemyPatterns = {"Ship Deckhand"}, isBoss = false},
    {Name = "Ship Engineer",      Min = 1275, Max = 1299, Pos = Vector3.new(793, 44, 32928), Quest = {"StartQuest","ShipQuest1",2}, EnemyPatterns = {"Ship Engineer"}, isBoss = false},
    {Name = "Ship Steward",       Min = 1300, Max = 1324, Pos = Vector3.new(911, 126, 33453), Quest = {"StartQuest","ShipQuest1",3}, EnemyPatterns = {"Ship Steward"}, isBoss = false},
    {Name = "Ship Officer",       Min = 1325, Max = 1349, Pos = Vector3.new(914, 180, 33298), Quest = {"StartQuest","ShipQuest2",1}, EnemyPatterns = {"Ship Officer"}, isBoss = false},
    {Name = "Arctic Warrior",     Min = 1350, Max = 1374, Pos = Vector3.new(6271, 28, -6152), Quest = {"StartQuest","FrostQuest",1}, EnemyPatterns = {"Arctic Warrior"}, isBoss = false},
    {Name = "Snow Lurker",        Min = 1375, Max = 1424, Pos = Vector3.new(5557, 28, -6784), Quest = {"StartQuest","FrostQuest",2}, EnemyPatterns = {"Snow Lurker"}, isBoss = false},
    {Name = "Sea Soldier",        Min = 1425, Max = 1449, Pos = Vector3.new(-3147, 22, -9793), Quest = {"StartQuest","ForgottenQuest",1}, EnemyPatterns = {"Sea Soldier"}, isBoss = false},
    {Name = "Water Fighter",      Min = 1450, Max = 1500, Pos = Vector3.new(-3414, 239, -10335), Quest = {"StartQuest","ForgottenQuest",2}, EnemyPatterns = {"Water Fighter"}, isBoss = false},

    -- ========== SEA 1 — Bosses ==========
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
    {Name = "Marine Boss",        Min = 130, Max = 150, Pos = Vector3.new(-5011, 15, 4384),
        Quest = {"StartQuest","MarineQuest2",1}, EnemyPatterns = {"Chief Petty Officer"},
        BossQuest = {"StartQuest","MarineQuest2",2}, BossPatterns = {"Vice Admiral"},
        isBoss = true},
    {Name = "Warden",             Min = 220, Max = 250, Pos = Vector3.new(5623, 1, 734),
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
    {Name = "Magma Admiral",      Min = 350, Max = 374, Pos = Vector3.new(-5804, 98, 8797),
        Quest = {"StartQuest","MagmaQuest",2}, EnemyPatterns = {"Military Spy"},
        BossQuest = {"StartQuest","MagmaQuest",3}, BossPatterns = {"Magma Admiral"},
        isBoss = true},
    {Name = "Fishman Lord",       Min = 425, Max = 450, Pos = Vector3.new(61353, 67, 1029),
        Quest = {"StartQuest","FishmanQuest",2}, EnemyPatterns = {"Fishman Commando"},
        BossQuest = {"StartQuest","FishmanQuest",3}, BossPatterns = {"Fishman Lord"},
        isBoss = true},
    {Name = "Wysper / Sky Warlord", Min = 500, Max = 525, Pos = Vector3.new(-7637, 5546, -515),
        Quest = {"StartQuest","SkyExp1Quest",2}, EnemyPatterns = {"Shanda"},
        BossQuest = {"StartQuest","SkyExp1Quest",3}, BossPatterns = {"Wysper","Sky Warlord"},
        isBoss = true},
    {Name = "Thunder God",        Min = 575, Max = 625, Pos = Vector3.new(-7806, 5607, -1753),
        Quest = {"StartQuest","SkyExp2Quest",2}, EnemyPatterns = {"Royal Soldier"},
        BossQuest = {"StartQuest","SkyExp2Quest",3}, BossPatterns = {"Thunder God","Lightning God"},
        isBoss = true},
    {Name = "Cyborg",             Min = 675, Max = 700, Pos = Vector3.new(6252, 9, 4941),
        Quest = {"StartQuest","FountainQuest",2}, EnemyPatterns = {"Galley Captain"},
        BossQuest = {"StartQuest","FountainQuest",3}, BossPatterns = {"Cyborg"},
        isBoss = true},

    -- ========== SEA 2 — Bosses ==========
    {Name = "Diamond",            Min = 750, Max = 775, Pos = Vector3.new(-1711, 206, -97),
        Quest = {"StartQuest","Area1Quest",2}, EnemyPatterns = {"Mercenary"},
        BossQuest = {"StartQuest","Area1Quest",3}, BossPatterns = {"Diamond"},
        isBoss = true},
    {Name = "Jeremy",             Min = 850, Max = 875, Pos = Vector3.new(2338, 451, 700),
        Quest = {"StartQuest","Area2Quest",1}, EnemyPatterns = {"Swan Pirate","Factory Staff"},
        BossQuest = {"StartQuest","Area2Quest",3}, BossPatterns = {"Jeremy"},
        isBoss = true},
    {Name = "Smoke Admiral",      Min = 1150, Max = 1175, Pos = Vector3.new(-6342, 29, -5818),
        Quest = {"StartQuest","IceSideQuest",2}, EnemyPatterns = {"Horned Warrior"},
        BossQuest = {"StartQuest","IceSideQuest",3}, BossPatterns = {"Smoke Admiral"},
        isBoss = true},
    {Name = "Tide Keeper",        Min = 1475, Max = 1500, Pos = Vector3.new(-3760, 78, -11586),
        Quest = {"StartQuest","ForgottenQuest",2}, EnemyPatterns = {"Water Fighter"},
        BossQuest = {"StartQuest","ForgottenQuest",3}, BossPatterns = {"Tide Keeper"},
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
local _bossFlyUnlock = false

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
    -- While a selected boss is UP/? and hunt is active, Auto Farm must not steal the target.
    -- Boss hunt sets _bossFlyUnlock for its own calls.
    if bossHuntOwnsFly and type(bossHuntOwnsFly) == "function" and bossHuntOwnsFly() then
        if not _bossFlyUnlock then
            return
        end
    end
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
    if bossHuntOwnsFly and type(bossHuntOwnsFly) == "function" and bossHuntOwnsFly() then
        if not _bossFlyUnlock then
            return
        end
    end
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
    if questArgs and questArgs[2] and type(activeQuestMatches) == "function" then
        local ok, matched = pcall(function()
            return activeQuestMatches(tostring(questArgs[2]))
        end)
        if ok and matched then
            return true
        end
    end
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
local fruitNotified = {} -- instance or name key -> true (already announced)

local function fruitScan()
    if not config.fruitNotifier then return end
    for _, v in pairs(Workspace:GetChildren()) do
        local handle = v:FindFirstChild("Handle")
        local isFruit = (v:IsA("Tool") and handle ~= nil) or (v.Name == "Fruit" and handle ~= nil)
        if isFruit then
            local parent = v.Parent
            if parent and parent:IsA("Model") and parent:FindFirstChildOfClass("Humanoid") then
                -- player holding it
            elseif parent and parent:IsA("Backpack") then
                -- in backpack
            else
                local key = tostring(v) .. "|" .. v.Name
                if not fruitNotified[key] then
                    fruitNotified[key] = true
                    -- one notify, longer duration, throttled helper
                    notifyUser("Fruit Detected", v.Name .. " spawned", 4)
                end
                if config.fruitAutoCollect and not bossHuntOwnsFly() then
                    local pos = handle.Position
                    setFlyTarget(pos + Vector3.new(0, 5, 0), false)
                    task.wait(0.5)
                    local character = LocalPlayer.Character
                    local hrp = character and character:FindFirstChild("HumanoidRootPart")
                    if hrp and (hrp.Position - pos).Magnitude < 15 then
                        pcall(function()
                            VirtualInputManager:SendKeyEvent(true, "E", false, game)
                            task.wait(0.1)
                            VirtualInputManager:SendKeyEvent(false, "E", false, game)
                        end)
                        notifyUser("Fruit", "Collected " .. v.Name, 2)
                    end
                end
                break
            end
        end
    end
    -- prune dead keys occasionally
    if os.clock() % 30 < 2 then
        for k in pairs(fruitNotified) do
            fruitNotified[k] = nil
        end
    end
end

local function startFruitNotifier()
    if fruitNotifierRunning then return end
    fruitNotifierRunning = true
    task.spawn(function()
        while fruitNotifierRunning do
            pcall(fruitScan)
            task.wait(2) -- never Heartbeat+wait spam
        end
    end)
end

local function stopFruitNotifier()
    fruitNotifierRunning = false
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

local function getActiveQuestInfo()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return false, "", "" end
    local main = playerGui:FindFirstChild("Main")
    if not main then return false, "", "" end
    local quest = main:FindFirstChild("Quest")
    if not quest or quest.Visible ~= true then return false, "", "" end
    local title, body = "", ""
    pcall(function()
        for _, d in ipairs(quest:GetDescendants()) do
            if d:IsA("TextLabel") and d.Visible and d.Text and #d.Text > 0 then
                if title == "" then title = d.Text else body = body .. " " .. d.Text end
            end
        end
    end)
    return true, title, body
end

local function hasActiveQuest()
    local a = getActiveQuestInfo()
    return a == true
end

local function activeQuestMatches(...)
    local active, title, body = getActiveQuestInfo()
    if not active then return false end
    local hay = string.lower(title .. " " .. body)
    for i = 1, select("#", ...) do
        local n = string.lower(tostring(select(i, ...)))
        if n ~= "" and string.find(hay, n, 1, true) then return true end
    end
    return false
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

    -- speed is delay between multi-hit packets; clamp so it never stalls
    local delay = tonumber(speed) or 0.01
    if delay < 0.001 then delay = 0.001 end
    if delay > 0.05 then delay = 0.05 end
    local n = math.max(1, math.floor(tonumber(hits) or 1))

    for _ = 1, n do
        local alive = {}
        for _, target in ipairs(validTargets) do
            local hum = target:FindFirstChildOfClass("Humanoid")
            local head = target:FindFirstChild("Head")
            if target.Parent and hum and hum.Health > 0 and head then
                table.insert(alive, target)
            end
        end
        if #alive == 0 then break end
        -- one RegisterHit packet hits the WHOLE cluster
        fireCombatHit(alive)
        task.wait(delay)
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
-- SEA + BOSS RESPAWN TIMERS (_WorldOrigin markers)
-- =============================================
-- workspace:GetAttribute("MAP") -> "Sea1" / "Sea2" / "Sea3"
-- Markers: workspace._WorldOrigin["NAME Respawn Marker"]
-- CD text: Marker.RespawnTimer.Frame.Timer (TextLabel, may contain HTML)
-- No timer UI => treat as SPAWNED if we only have the marker, or check Enemies.

local BOSS_CATALOG = {
    -- From workspace._WorldOrigin.EnemySpawns (Sea1 dump) + extras
    Sea1 = {
        "The Gorilla King",
        "Chef",
        "Yeti",
        "Mob Boss",
        "Vice Admiral",
        "Saber Expert",
        "Warden",
        "Fishman Lord",
        "Sky Warlord",
        "Lightning God",
        "Cyborg",
        "Ice Admiral",
        -- extras / markers (may not always be in EnemySpawns):
        "Chief Warden",
        "Swan",
        "Magma Admiral",
        "Wysper",
        "Thunder God",
        "Greybeard",
        "The Saw",
        "Bobby",
    },
    -- From workspace._WorldOrigin.EnemySpawns (Sea2 dump) + known extras without spawn parts
    Sea2 = {
        "Diamond",
        "Jeremy",
        "Don Swan",
        "Smoke Admiral",
        "Tide Keeper",
        "rip_indra",
        -- often marker-only / not always in EnemySpawns:
        "Awakened Ice Admiral",
        "Orbitus",
        "Fajita",
        "Cursed Captain",
        "Darkbeard",
        "Core",
        "Order",
    },
    Sea3 = {
        "Stone",
        "Hydra Leader",
        "Island Empress",
        "Kilo Admiral",
        "Captain Elephant",
        "Beautiful Pirate",
        "Soul Reaper",
        "Cake Queen",
        "Cake Prince",
        "Dough King",
        "Longma",
        "rip_indra",
    },
}

-- optional aliases: catalog name -> marker substrings / enemy name patterns
local BOSS_ALIASES = {
    ["Orbitus"] = { "Orbitus", "Fajita" },
    ["Fajita"] = { "Fajita", "Orbitus" },
    ["Don Swan"] = { "Don Swan", "Swan" },
    ["Awakened Ice Admiral"] = { "Awakened Ice Admiral", "Ice Admiral" },
    ["Ice Admiral"] = { "Ice Admiral", "Awakened Ice Admiral" },
    ["Lightning God"] = { "Lightning God", "Thunder God" },
    ["Thunder God"] = { "Thunder God", "Lightning God" },
    ["rip_indra"] = { "rip_indra", "Rip Indra", "Indra" },
    ["Core"] = { "Core", "CORE" },
    ["Hydra Leader"] = { "Hydra Leader", "Island Empress" },
    ["Island Empress"] = { "Island Empress", "Hydra Leader" },
    ["The Gorilla King"] = { "The Gorilla King", "Gorilla King" },
    ["Sky Warlord"] = { "Sky Warlord", "Wysper" },
}

local function stripEnemyLabel(name)
    -- "Diamond [Lv. 750] [Boss]" -> "Diamond"
    name = tostring(name or "")
    name = string.gsub(name, "%s*%[Lv%.%s*%d+%]%s*", " ")
    name = string.gsub(name, "%s*%[Boss%]%s*", " ")
    name = string.gsub(name, "%s+", " ")
    return (string.match(name, "^%s*(.-)%s*$")) or name
end

local function collectBossesFromEnemySpawns()
    local list = {}
    local seen = {}
    local origin = workspace:FindFirstChild("_WorldOrigin")
    local spawns = origin and origin:FindFirstChild("EnemySpawns")
    if not spawns then
        return list
    end
    for _, part in ipairs(spawns:GetChildren()) do
        local n = part.Name
        local display = nil
        pcall(function()
            display = part:GetAttribute("DisplayName")
        end)
        local label = display or n
        if type(label) == "string" and string.find(label, "[Boss]", 1, true) then
            local short = stripEnemyLabel(label)
            if short ~= "" and not seen[string.lower(short)] then
                seen[string.lower(short)] = true
                table.insert(list, short)
            end
        end
    end
    table.sort(list)
    return list
end

local function averageSpawnPosition(enemyShortName)
    local origin = workspace:FindFirstChild("_WorldOrigin")
    local spawns = origin and origin:FindFirstChild("EnemySpawns")
    if not spawns then
        return nil
    end
    local want = string.lower(tostring(enemyShortName or ""))
    local sum = Vector3.zero
    local count = 0
    for _, part in ipairs(spawns:GetChildren()) do
        if part:IsA("BasePart") then
            local label = part.Name
            pcall(function()
                local d = part:GetAttribute("DisplayName")
                if d then label = d end
            end)
            local short = string.lower(stripEnemyLabel(label))
            if short == want or string.find(short, want, 1, true) or string.find(want, short, 1, true) then
                sum = sum + part.Position
                count = count + 1
            end
        end
    end
    if count == 0 then
        return nil
    end
    return sum / count
end

local bossTimerGui = nil
local bossTimerLabel = nil
local bossTimerRunning = false
local bossTimerTask = nil
local lastBossStatus = {} -- name -> "SPAWNED" | "RESPAWNING" | "UNKNOWN"
-- Timer UI can blink out of workspace for a frame; require stable absence before SPAWNED
local pendingSpawnConfirm = {} -- name -> os.clock() when timer first disappeared while we thought CD
local SPAWN_CONFIRM_DELAY = 1.0
local selectedBosses = {}
local unknownProbeDone = {}
local bossListFrame = nil
local bossAutoHuntEnabled = true
local activeBossHuntTask = nil
local activeBossHuntName = nil

local function normalizeSea(mapAttr)
    local s = string.lower(tostring(mapAttr or ""))
    if string.find(s, "3", 1, true) or s == "sea3" or string.find(s, "third", 1, true) then
        return "Sea3"
    end
    if string.find(s, "2", 1, true) or s == "sea2" or string.find(s, "second", 1, true) then
        return "Sea2"
    end
    if string.find(s, "1", 1, true) or s == "sea1" or string.find(s, "first", 1, true) then
        return "Sea1"
    end
    if s == "" then
        return "Unknown"
    end
    return tostring(mapAttr)
end

local function getCurrentSea()
    return normalizeSea(workspace:GetAttribute("MAP"))
end

local function cleanTimerText(raw)
    local s = tostring(raw or "")
    -- strip rich-text / html-like tags from TextLabel
    s = string.gsub(s, "<[^>]+>", "")
    s = string.gsub(s, "&nbsp;", " ")
    s = string.gsub(s, "%s+", " ")
    -- prefer bracket time like [13:43] or [1:27:05]
    local bracket = string.match(s, "%[([^%]]+)%]")
    if bracket and bracket ~= "" then
        return bracket
    end
    s = string.match(s, "^%s*(.-)%s*$") or s
    return s
end

local function findBossTimerLabel(marker)
    if not marker then
        return nil
    end
    local rt = marker:FindFirstChild("RespawnTimer")
    if rt then
        local frame = rt:FindFirstChild("Frame")
        if frame then
            local timer = frame:FindFirstChild("Timer")
            if timer and timer:IsA("TextLabel") then
                return timer
            end
        end
        local timer2 = rt:FindFirstChild("Timer", true)
        if timer2 and timer2:IsA("TextLabel") then
            return timer2
        end
    end
    local deep = marker:FindFirstChild("Timer", true)
    if deep and deep:IsA("TextLabel") then
        return deep
    end
    return nil
end

local function nameMatches(bossName, candidate)
    if not candidate then
        return false
    end
    local a = string.lower(bossName)
    local b = string.lower(tostring(candidate))
    if a == b then
        return true
    end
    if string.find(b, a, 1, true) or string.find(a, b, 1, true) then
        return true
    end
    local aliases = BOSS_ALIASES[bossName]
    if aliases then
        for _, al in ipairs(aliases) do
            local alow = string.lower(al)
            if b == alow or string.find(b, alow, 1, true) then
                return true
            end
        end
    end
    return false
end

local function scanMarkerMap()
    -- returns map: upperKey -> { status, time, markerName }
    local map = {}
    local origin = workspace:FindFirstChild("_WorldOrigin")
    if not origin then
        return map
    end
    for _, child in ipairs(origin:GetChildren()) do
        local name = child.Name
        if type(name) == "string" and string.find(name, "Respawn Marker", 1, true) then
            local bossFromMarker = string.gsub(name, "%s*Respawn Marker%s*$", "")
            local timerLabel = findBossTimerLabel(child)
            local status, timeText
            if timerLabel and timerLabel.Parent then
                local cleaned = cleanTimerText(timerLabel.Text)
                if cleaned ~= "" then
                    status = "RESPAWNING"
                    timeText = cleaned
                else
                    status = "SPAWNED"
                    timeText = "-"
                end
            else
                status = "SPAWNED"
                timeText = "-"
            end
            map[string.upper(bossFromMarker)] = {
                Status = status,
                Time = timeText,
                MarkerName = bossFromMarker,
            }
            -- also index raw
            map[bossFromMarker] = map[string.upper(bossFromMarker)]
        end
    end
    return map
end

local function enemyAliveMatching(bossName)
    local enemies = workspace:FindFirstChild("Enemies")
    if not enemies then
        return false
    end
    for _, model in ipairs(enemies:GetChildren()) do
        if nameMatches(bossName, model.Name) then
            local hum = model:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                return true
            end
        end
    end
    return false
end

local function lookupMarker(markerMap, bossName)
    for key, data in pairs(markerMap) do
        if type(data) == "table" and data.Status and nameMatches(bossName, data.MarkerName or key) then
            return data
        end
    end
    return nil
end

local function scanBossesForSea()
    local sea = getCurrentSea()
    local catalog = {}
    local seen = {}

    local function addBoss(name)
        if not name or name == "" then
            return
        end
        local key = string.lower(name)
        if seen[key] then
            return
        end
        seen[key] = true
        table.insert(catalog, name)
    end

    -- 1) live from EnemySpawns ([Boss] parts) — authoritative for this server/sea
    for _, name in ipairs(collectBossesFromEnemySpawns()) do
        addBoss(name)
    end

    -- 2) static catalog extras (marker-only bosses etc.)
    local staticList = BOSS_CATALOG[sea]
    if staticList then
        for _, name in ipairs(staticList) do
            addBoss(name)
        end
    end

    -- 3) still empty: markers only
    if #catalog == 0 then
        local origin = workspace:FindFirstChild("_WorldOrigin")
        if origin then
            for _, child in ipairs(origin:GetChildren()) do
                if string.find(child.Name, "Respawn Marker", 1, true) then
                    addBoss(string.gsub(child.Name, "%s*Respawn Marker%s*$", ""))
                end
            end
        end
    end

    local markerMap = scanMarkerMap()
    local results = {}
    local now = os.clock()
    for _, bossName in ipairs(catalog) do
        local status, timeText
        if enemyAliveMatching(bossName) then
            status = "SPAWNED"
            timeText = "-"
            pendingSpawnConfirm[bossName] = nil
        else
            local m = lookupMarker(markerMap, bossName)
            if m then
                if m.Status == "RESPAWNING" then
                    -- timer visible again -> cancel any pending spawn confirm
                    status = "RESPAWNING"
                    timeText = m.Time
                    pendingSpawnConfirm[bossName] = nil
                else
                    -- marker exists but no timer text (often "SPAWNED", but can be a 1-frame glitch)
                    local prev = lastBossStatus[bossName]
                    if prev == "RESPAWNING" or pendingSpawnConfirm[bossName] then
                        local t0 = pendingSpawnConfirm[bossName]
                        if not t0 then
                            pendingSpawnConfirm[bossName] = now
                            status = "RESPAWNING"
                            timeText = "..."
                        elseif (now - t0) < SPAWN_CONFIRM_DELAY then
                            status = "RESPAWNING"
                            timeText = "..."
                        else
                            status = "SPAWNED"
                            timeText = "-"
                            pendingSpawnConfirm[bossName] = nil
                        end
                    else
                        status = "SPAWNED"
                        timeText = "-"
                        pendingSpawnConfirm[bossName] = nil
                    end
                end
            else
                -- no marker at all
                local prev = lastBossStatus[bossName]
                if prev == "RESPAWNING" or pendingSpawnConfirm[bossName] then
                    local t0 = pendingSpawnConfirm[bossName]
                    if not t0 then
                        pendingSpawnConfirm[bossName] = now
                        status = "RESPAWNING"
                        timeText = "..."
                    elseif (now - t0) < SPAWN_CONFIRM_DELAY then
                        status = "RESPAWNING"
                        timeText = "..."
                    else
                        -- confirmed gone: SPAWNED (sticky), not ?
                        status = "SPAWNED"
                        timeText = "-"
                        pendingSpawnConfirm[bossName] = nil
                    end
                elseif prev == "SPAWNED" then
                    status = "SPAWNED"
                    timeText = "-"
                else
                    status = "UNKNOWN"
                    timeText = "-"
                    pendingSpawnConfirm[bossName] = nil
                end
            end
        end
        table.insert(results, {
            Name = bossName,
            Status = status,
            Time = timeText,
            Sea = sea,
        })
    end

    table.sort(results, function(a, b)
        local rank = { SPAWNED = 1, UNKNOWN = 2, RESPAWNING = 3 }
        local ra, rb = rank[a.Status] or 9, rank[b.Status] or 9
        if ra ~= rb then
            return ra < rb
        end
        return a.Name < b.Name
    end)
    return { List = results, Sea = sea }
end

-- keep old name used by UI buttons
local function scanBossMarkers()
    local pack = scanBossesForSea()
    return pack.List, pack.Sea
end

local function formatBossBoard(list, sea)
    sea = sea or getCurrentSea()
    local lines = {}
    table.insert(lines, "Sea: " .. tostring(sea))
    table.insert(lines, string.rep("-", 32))
    if not list or #list == 0 then
        table.insert(lines, "No bosses in catalog")
    else
        local up, cd, unk = 0, 0, 0
        for _, row in ipairs(list) do
            if row.Status == "SPAWNED" then
                up = up + 1
                table.insert(lines, "[UP] " .. row.Name)
            elseif row.Status == "RESPAWNING" then
                cd = cd + 1
                table.insert(lines, "[CD] " .. row.Name .. "  " .. tostring(row.Time))
            else
                unk = unk + 1
                table.insert(lines, "[?]  " .. row.Name)
            end
        end
        table.insert(lines, string.rep("-", 32))
        table.insert(lines, string.format("UP %d | CD %d | ? %d", up, cd, unk))
    end
    return table.concat(lines, "\n")
end

local function makeDraggable(handle, target)
    -- Stable drag: use UserInputService so it does not fight ScrollingFrame
    local UserInputService = game:GetService("UserInputService")
    local dragging = false
    local dragStart = nil
    local startPos = nil

    handle.Active = true
    handle.AutoButtonColor = false

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = target.Position
        end
    end)

    handle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging or not dragStart or not startPos then
            return
        end
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            target.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

-- True while a selected boss is UP/? and hunt owns movement
local function bossHuntOwnsFly()
    if not bossAutoHuntEnabled then
        return false
    end
    if activeBossHuntName and selectedBosses[activeBossHuntName] then
        return true
    end
    return false
end

local function flyToBossPosition(bossName)
    _bossFlyUnlock = true
    local pos = averageSpawnPosition(bossName)
    if not pos then
        local origin = workspace:FindFirstChild("_WorldOrigin")
        if origin then
            for _, child in ipairs(origin:GetChildren()) do
                if string.find(child.Name, "Respawn Marker", 1, true) then
                    local bn = string.gsub(child.Name, "%s*Respawn Marker%s*$", "")
                    if nameMatches(bossName, bn) then
                        local part = child:IsA("BasePart") and child or child:FindFirstChildWhichIsA("BasePart", true)
                        if part then
                            pos = part.Position
                            break
                        end
                    end
                end
            end
        end
    end
    if not pos then
        _bossFlyUnlock = false
        notifyUser("Boss Hunt", bossName .. ": no position", 2)
        return false
    end
    setFlyTarget(pos + Vector3.new(0, 12, 0), false)
    _bossFlyUnlock = false
    return true
end

-- Try accept boss quest from islands table BossQuest / patterns
local function tryAcceptBossQuest(bossName)
    for _, island in ipairs(islands) do
        local patterns = island.BossPatterns or (island.isBoss and island.EnemyPatterns) or {}
        local hit = false
        for _, p in ipairs(patterns) do
            if nameMatches(bossName, p) then
                hit = true
                break
            end
        end
        if not hit and nameMatches(bossName, island.Name) then
            hit = true
        end
        if hit then
            local args = island.BossQuest or island.Quest
            if args then
                pcall(function()
                    acceptQuestWrapper(args)
                end)
                return true
            end
        end
    end
    return false
end

local function findBossModelByName(bossName)
    local enemies = workspace:FindFirstChild("Enemies")
    if not enemies then
        return nil
    end
    local best, bestDist = nil, math.huge
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local origin = hrp and hrp.Position or Vector3.zero
    for _, model in ipairs(enemies:GetChildren()) do
        if nameMatches(bossName, model.Name) then
            local hum = model:FindFirstChildOfClass("Humanoid")
            local root = model:FindFirstChild("HumanoidRootPart")
            if hum and hum.Health > 0 and root then
                local d = (root.Position - origin).Magnitude
                if d < bestDist then
                    bestDist = d
                    best = model
                end
            end
        end
    end
    return best
end

local function stopActiveBossHunt(reason)
    if activeBossHuntTask then
        pcall(function()
            task.cancel(activeBossHuntTask)
        end)
    end
    activeBossHuntTask = nil
    if activeBossHuntName and selectedBosses[activeBossHuntName] == "hunting" then
        selectedBosses[activeBossHuntName] = true
    end
    activeBossHuntName = nil
end

local function startBossHuntCombat(bossName)
    if activeBossHuntName == bossName and activeBossHuntTask then
        return
    end
    stopActiveBossHunt(nil)
    activeBossHuntName = bossName
    selectedBosses[bossName] = "hunting"
    flyToBossPosition(bossName)
    tryAcceptBossQuest(bossName)
    notifyUser("Boss Hunt", "Engaging " .. bossName, 2)

    activeBossHuntTask = task.spawn(function()
        local deadline = os.clock() + 180
        local speed = (config and config.bossAttackSpeed) or 0.002
        local hits = (config and config.bossHitsPerCycle) or 35
        local above = math.clamp((config and config.aboveHeight) or 8, 4, 14)
        local questTriedAt = 0

        while bossTimerRunning and selectedBosses[bossName] and os.clock() < deadline do
            if not flying then
                pcall(enableFly)
            end
            -- re-try quest every ~8s while hunting
            if os.clock() - questTriedAt > 8 then
                questTriedAt = os.clock()
                tryAcceptBossQuest(bossName)
            end

            local boss = findBossModelByName(bossName)
            if boss then
                local root = boss:FindFirstChild("HumanoidRootPart")
                local hum = boss:FindFirstChildOfClass("Humanoid")
                if root and hum and hum.Health > 0 then
                    local character = LocalPlayer.Character
                    local hrp = character and character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local dist = (hrp.Position - root.Position).Magnitude
                        _bossFlyUnlock = true
                        setFlyTarget(root.Position + Vector3.new(0, above, 0), false)
                        _bossFlyUnlock = false
                        if dist <= ((config and config.attackRange) or 30) + 10 then
                            pcall(function()
                                attackEnemy(boss, speed, hits)
                            end)
                        end
                    end
                else
                    break
                end
            else
                flyToBossPosition(bossName)
                task.wait(0.35)
            end
            task.wait(0.05)
        end

        if selectedBosses[bossName] == "hunting" then
            selectedBosses[bossName] = true
        end
        if activeBossHuntName == bossName then
            activeBossHuntTask = nil
            activeBossHuntName = nil
        end
        notifyUser("Boss Hunt", bossName .. " hunt ended", 2)
    end)
end

-- Stable list: create buttons once, only update text/colors (fixes click delay)
local bossRowButtons = {} -- name -> TextButton

local function rebuildBossListRows(list)
    if not bossListFrame then
        return
    end

    local seen = {}
    local y = 0
    for _, row in ipairs(list or {}) do
        seen[row.Name] = true
        local sel = selectedBosses[row.Name] ~= nil
        local hunting = selectedBosses[row.Name] == "hunting"
        local tag = "[?]"
        local tagColor = Color3.fromRGB(180, 180, 100)
        if row.Status == "SPAWNED" then
            tag = "[UP]"
            tagColor = Color3.fromRGB(80, 220, 120)
        elseif row.Status == "RESPAWNING" then
            tag = "[CD] " .. tostring(row.Time)
            tagColor = Color3.fromRGB(220, 120, 100)
        end
        local mark = sel and "[x]" or "[ ]"

        local btn = bossRowButtons[row.Name]
        if not btn or not btn.Parent then
            btn = Instance.new("TextButton")
            btn.Name = row.Name
            btn.Size = UDim2.new(1, -6, 0, 26)
            btn.BackgroundColor3 = Color3.fromRGB(24, 26, 34)
            btn.BorderSizePixel = 0
            btn.AutoButtonColor = true
            btn.Font = Enum.Font.Code
            btn.TextSize = 13
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.TextColor3 = Color3.fromRGB(230, 230, 235)
            btn.Parent = bossListFrame
            local c = Instance.new("UICorner")
            c.CornerRadius = UDim.new(0, 5)
            c.Parent = btn
            local name = row.Name
            btn.MouseButton1Click:Connect(function()
                if selectedBosses[name] then
                    selectedBosses[name] = nil
                    unknownProbeDone[name] = nil
                    if activeBossHuntName == name then
                        stopActiveBossHunt("deselected")
                    end
                else
                    selectedBosses[name] = true
                    unknownProbeDone[name] = nil
                end
                -- instant visual feedback
                local isOn = selectedBosses[name] ~= nil
                btn.BackgroundColor3 = isOn and Color3.fromRGB(40, 90, 55) or Color3.fromRGB(24, 26, 34)
                local t = btn.Text
                if isOn then
                    btn.Text = (t:gsub("%[ %]", "[x]", 1):gsub("^ %[ %]", " [x]"))
                    if not btn.Text:find("%[x%]", 1) then
                        btn.Text = " [x] " .. name
                    end
                end
            end)
            bossRowButtons[row.Name] = btn
        end

        btn.Position = UDim2.new(0, 2, 0, y)
        btn.Text = " " .. mark .. " " .. tag .. "  " .. row.Name
        btn.BackgroundColor3 = (sel or hunting) and Color3.fromRGB(40, 90, 55) or Color3.fromRGB(24, 26, 34)
        y = y + 28
    end

    -- remove rows no longer in list
    for name, btn in pairs(bossRowButtons) do
        if not seen[name] then
            pcall(function() btn:Destroy() end)
            bossRowButtons[name] = nil
        end
    end
    bossListFrame.CanvasSize = UDim2.new(0, 0, 0, y + 10)
end

local function processBossHuntActions(list)
    if not bossAutoHuntEnabled then
        return
    end
    for _, row in ipairs(list or {}) do
        local sel = selectedBosses[row.Name]
        if sel then
            if row.Status == "SPAWNED" then
                -- UP: take control from farm, fight
                if sel ~= "hunting" or activeBossHuntName ~= row.Name then
                    startBossHuntCombat(row.Name)
                end
            elseif row.Status == "UNKNOWN" then
                -- ?: probe once (fly + try attack if found)
                if not unknownProbeDone[row.Name] then
                    unknownProbeDone[row.Name] = true
                    startBossHuntCombat(row.Name)
                end
            elseif row.Status == "RESPAWNING" then
                -- DOWN / on CD: release fly to Auto Farm
                if activeBossHuntName == row.Name then
                    stopActiveBossHunt("on cooldown")
                end
                if sel == "hunting" then
                    selectedBosses[row.Name] = true
                end
                -- allow a new probe next time it goes ?
                unknownProbeDone[row.Name] = nil
            end
        elseif activeBossHuntName == row.Name then
            stopActiveBossHunt("deselected")
        end
    end
end

local function ensureBossTimerGui()
    local pg = LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 5)
    if not pg then return end
    if bossTimerGui and bossTimerGui.Parent then return end
    local sg = Instance.new("ScreenGui")
    sg.Name = "BF_BossTimers"
    sg.ResetOnSpawn = false
    sg.DisplayOrder = 50
    sg.IgnoreGuiInset = true
    sg.Parent = pg

    local frame = Instance.new("Frame")
    frame.Name = "Board"
    frame.Size = UDim2.new(0, 320, 0, 400)
    frame.Position = UDim2.new(0, 12, 0.18, 0)
    frame.BackgroundColor3 = Color3.fromRGB(12, 14, 20)
    frame.BackgroundTransparency = 0.1
    frame.BorderSizePixel = 0
    frame.Parent = sg
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame

    local title = Instance.new("TextButton")
    title.Name = "TitleDrag"
    title.Size = UDim2.new(1, -12, 0, 26)
    title.Position = UDim2.new(0, 6, 0, 4)
    title.BackgroundColor3 = Color3.fromRGB(30, 28, 48)
    title.BorderSizePixel = 0
    title.Font = Enum.Font.GothamBold
    title.TextSize = 12
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextColor3 = Color3.fromRGB(200, 180, 255)
    title.Text = "  Boss Timers (drag) | click = select hunt"
    title.Parent = frame
    local tc = Instance.new("UICorner")
    tc.CornerRadius = UDim.new(0, 6)
    tc.Parent = title
    makeDraggable(title, frame)

    local hint = Instance.new("TextLabel")
    hint.Size = UDim2.new(1, -12, 0, 30)
    hint.Position = UDim2.new(0, 6, 0, 32)
    hint.BackgroundTransparency = 1
    hint.Font = Enum.Font.Gotham
    hint.TextSize = 11
    hint.TextWrapped = true
    hint.TextXAlignment = Enum.TextXAlignment.Left
    hint.TextColor3 = Color3.fromRGB(160, 160, 175)
    hint.Text = "[x] + [UP] = fly to boss. [x] + [?] = probe once."
    hint.Parent = frame

    local scroll = Instance.new("ScrollingFrame")
    scroll.Name = "Scroll"
    scroll.Size = UDim2.new(1, -12, 1, -68)
    scroll.Position = UDim2.new(0, 6, 0, 62)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 5
    scroll.CanvasSize = UDim2.new(0, 0, 0, 600)
    scroll.Parent = frame

    bossTimerGui = sg
    bossListFrame = scroll
    bossTimerLabel = nil
end

local function destroyBossTimerGui()
    if bossTimerGui then
        pcall(function()
            bossTimerGui:Destroy()
        end)
    end
    bossTimerGui = nil
    bossTimerLabel = nil
    bossListFrame = nil
    bossRowButtons = {}
end

local function stopBossTimers()
    bossTimerRunning = false
    bossTimerTask = nil
    stopActiveBossHunt("timers off")
    destroyBossTimerGui()
end

local function startBossTimers()
    if bossTimerRunning then
        return
    end
    bossTimerRunning = true
    ensureBossTimerGui()
    bossTimerTask = task.spawn(function()
        while bossTimerRunning do
            local list, sea = {}, getCurrentSea()
            local ok, pack = pcall(scanBossesForSea)
            if ok and type(pack) == "table" then
                list = pack.List or {}
                sea = pack.Sea or getCurrentSea()
            end
            pcall(rebuildBossListRows, list)
            pcall(processBossHuntActions, list)
            if config.bossSpawnNotify then
                for _, row in ipairs(list or {}) do
                    local prev = lastBossStatus[row.Name]
                    if row.Status == "SPAWNED" and prev == "RESPAWNING" then
                        notifyUser("Boss Spawned", row.Name .. " is UP!")
                    end
                    lastBossStatus[row.Name] = row.Status
                end
            else
                for _, row in ipairs(list or {}) do
                    lastBossStatus[row.Name] = row.Status
                end
            end
            task.wait(1)
        end
    end)
end

-- =============================================
-- STATE MACHINE (FARMING)
-- =============================================

-- ========== AUTO SEA (minimal, staged) ==========
local seaProgressRunning = false
local sea1Stage, sea2Stage = "idle", "idle"

local function _seaFly(pos)
    if not pos then return end
    pcall(function()
        if not flying then enableFly() end
        setFlyTarget(pos + Vector3.new(0, 8, 0), false)
    end)
    task.wait(3)
end

local function _seaComm(...)
    local args = { ... }
    local r = ReplicatedStorage:FindFirstChild("Remotes")
    local f = r and r:FindFirstChild("CommF_")
    if f then
        pcall(function()
            f:InvokeServer(unpack(args))
        end)
    end
end

local function _seaKill(nameSub, seconds)
    local t0 = os.clock()
    while os.clock() - t0 < (seconds or 60) and seaProgressRunning do
        local en = workspace:FindFirstChild("Enemies")
        local tgt = nil
        if en then
            for _, m in ipairs(en:GetChildren()) do
                if string.find(string.lower(m.Name), string.lower(nameSub), 1, true) then
                    local h = m:FindFirstChildOfClass("Humanoid")
                    if h and h.Health > 0 then tgt = m break end
                end
            end
        end
        if tgt then
            local root = tgt:FindFirstChild("HumanoidRootPart")
            if root then
                pcall(function()
                    if not flying then enableFly() end
                    setFlyTarget(root.Position + Vector3.new(0, 10, 0), false)
                    attackEnemy(tgt, config.bossAttackSpeed or 0.002, config.bossHitsPerCycle or 35)
                end)
            end
        end
        task.wait(0.15)
    end
end

local function startSeaProgress()
    if seaProgressRunning then return end
    seaProgressRunning = true
    task.spawn(function()
        while seaProgressRunning do
            local ok, err = pcall(function()
                if not config.autoSeaProgress then return end
                local level = getPlayerLevel()
                local map = tostring(workspace:GetAttribute("MAP") or "")
                local sea = string.lower(map)

                -- Sea1 -> 2
                if level >= 700 and (sea == "" or sea == "sea1" or string.find(sea, "1")) and not string.find(sea, "2") and not string.find(sea, "3") and sea1Stage ~= "done" then
                    if sea1Stage == "idle" then
                        notifyUser("Sea", "Detective / Ice Admiral", 3)
                        _seaFly(Vector3.new(4850, 20, 750))
                        _seaComm("TalkDetective")
                        sea1Stage = "ice"
                    elseif sea1Stage == "ice" then
                        _seaFly(Vector3.new(-1166, 13, -2447))
                        _seaKill("Ice Admiral", 90)
                        sea1Stage = "cap"
                    elseif sea1Stage == "cap" then
                        _seaFly(Vector3.new(-285, 9, 5360))
                        _seaComm("TravelDressrosa")
                        _seaComm("TravelToSea2")
                        task.wait(2)
                        map = tostring(workspace:GetAttribute("MAP") or "")
                        if string.find(string.lower(map), "2") then
                            sea1Stage = "done"
                            notifyUser("Sea", "Sea 2!", 4)
                        end
                    end
                end

                -- Sea2 Bartilo (only advance stages; never jump back)
                if string.find(sea, "2") and sea2Stage ~= "done" then
                    -- Bartilo flow (user):
                    -- 1) StartQuest BartiloQuest 1 → kill Swan Pirates
                    -- 2) When done: talk Bartilo, then JUST KILL Jeremy (no real "Jeremy quest")
                    -- 3) Then kill Don Swan
                    if level >= 850 then
                        if sea2Stage == "idle" then
                            if hasActiveQuest() and not activeQuestMatches("swan", "bartilo", "50", "pirate") then
                                -- other farm quest active: don't steal it
                            else
                                if not activeQuestMatches("swan", "50") then
                                    _seaComm("StartQuest", "BartiloQuest", 1)
                                    task.wait(0.5)
                                end
                                sea2Stage = "swan"
                                notifyUser("Sea", "Bartilo 1: Swan Pirates", 3)
                            end
                        elseif sea2Stage == "swan" then
                            if activeQuestMatches("swan", "50", "pirate") then
                                _seaFly(Vector3.new(1019, 73, 1221))
                                _seaKill("Swan Pirate", 40)
                            else
                                -- Stage 1 done (quest gone / changed) → Jeremy next, no quest UI needed
                                notifyUser("Sea", "Bartilo done → kill Jeremy", 3)
                                _seaComm("StartQuest", "BartiloQuest", 2) -- talk / progress if remote exists
                                task.wait(0.5)
                                sea2Stage = "j"
                            end
                        elseif sea2Stage == "j" then
                            -- Direct kill Jeremy, then Don Swan
                            notifyUser("Sea", "Killing Jeremy...", 2)
                            _seaFly(Vector3.new(2338, 451, 700))
                            _seaKill("Jeremy", 100)
                            -- always advance after kill window (no Jeremy quest text to wait on)
                            notifyUser("Sea", "Jeremy done → Don Swan", 3)
                            sea2Stage = "don"
                        end
                    end

                    -- Don Swan whenever stage says so (and level high enough for sea3 path)
                    if sea2Stage == "don" or (level >= 1500 and sea2Stage == "wait") then
                        sea2Stage = "don"
                        notifyUser("Sea", "Killing Don Swan...", 3)
                        _seaFly(Vector3.new(2289, 18, 663))
                        _seaKill("Don Swan", 120)
                        _seaComm("TravelZou")
                        _seaComm("TravelToSea3")
                        task.wait(2)
                        if string.find(string.lower(tostring(workspace:GetAttribute("MAP") or "")), "3") then
                            sea2Stage = "done"
                            notifyUser("Sea", "Sea 3!", 4)
                        elseif level < 1500 then
                            sea2Stage = "wait"
                        end
                    end
                end
            end)
            if not ok then
                warn("[BF] seaProgress:", err)
            end
            task.wait(8)
        end
    end)
end

local function stopSeaProgress()
    seaProgressRunning = false
end


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
            -- Boss hunt (UP/?) fully owns movement + combat; farm waits
            if bossHuntOwnsFly and type(bossHuntOwnsFly) == "function" and bossHuntOwnsFly() then
                task.wait(0.2)
                continue
            end
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

            -- Level 700-725: make sure the normal Raider pattern is selected.
            -- This is deliberately scoped to the user's existing "Season 2, 1"
            -- entry and does not alter other level ranges.
            if island and island.Name == "Season 2, 1" then
                island.EnemyPatterns = {"Raider"}
                island.isBoss = false
            end
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
                        -- acceptQuest()/stackQuest() returning means the remote was
                        -- found and invoked.  Do not require PlayerGui.Main.Quest
                        -- to become visible before looking for the configured mob.
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
                -- Do not block target detection just because the Quest GUI has not
                -- updated yet.  The quest remote can succeed before the GUI becomes
                -- visible, and at level 700+ this used to leave the farmer parked at
                -- the waypoint instead of acquiring a Raider.
                --
                -- If the quest really is not active, the QUEST state will retry it
                -- after target detection has had a chance to find the configured mob.
                local guiQuestActive = hasActiveQuest()
                if not guiQuestActive and not questAccepted then
                    local patternInfo = getPatterns(island, currentQuestType)
                    local precheckTargets = getMatchingEnemies(island, patternInfo)
                    if #precheckTargets == 0 then
                        state = "QUEST"
                        lockedEnemy = nil
                        heightLocked = false
                        isBossTarget = false
                        continue
                    end
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
                            local hover = math.clamp(config.aboveHeight or 8, 4, 14)
                            setFlyTarget(targetPos + Vector3.new(0, hover, 0), false)
                            heightLocked = false
                            task.wait(0.03)
                        else
                            local speed = isBossTarget and config.bossAttackSpeed or config.attackSpeed
                            local hits = isBossTarget and config.bossHitsPerCycle or config.hitsPerCycle

                            if config.clusterEnabled and not isBossTarget then
                                local playerRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                                if playerRoot then
                                    -- Stay CLOSE above the real enemy (too high => server ignores hits)
                                    local hover = math.clamp(config.aboveHeight or 8, 4, 12)
                                    setFlyTarget(targetPos + Vector3.new(0, hover, 0), false)
                                    heightLocked = false

                                    local patternInfo = getPatterns(island, currentQuestType)
                                    local allTargets = getMatchingEnemies(island, patternInfo)
                                    local maxN = config.maxClusterSize or 15
                                    -- Pull range (large) vs attack range (small) were mixed before
                                    local radius = config.clusterRange or 150
                                    if radius < 80 then radius = 80 end

                                    local clusterTargets = collectNearbyTargets(
                                        allTargets,
                                        playerRoot,
                                        lockedEnemy,
                                        maxN,
                                        radius
                                    )

                                    if #clusterTargets > 0 then
                                        -- stand above the fixed stack (not a moving flyer underpoint)
                                        if clusterStackPos then
                                            local hover = math.clamp(config.aboveHeight or 8, 4, 12)
                                            setFlyTarget(clusterStackPos + Vector3.new(0, hover, 0), false)
                                        end
                                        attackTargets(clusterTargets, speed, hits)
                                    else
                                        attackEnemy(lockedEnemy, speed, hits)
                                    end
                                else
                                    attackEnemy(lockedEnemy, speed, hits)
                                end
                            else
                                -- single target: also keep height moderate for valid hits
                                local hover = math.clamp(config.aboveHeight or 8, 4, 14)
                                setFlyTarget(targetPos + Vector3.new(0, hover, 0), false)
                                attackEnemy(lockedEnemy, speed, hits)
                            end
                        end
                    else
                        lockedEnemy = nil
                        clusterStackPos = nil
                    end
                else
                    lockedEnemy = nil
                    clusterStackPos = nil
                end
                continue
            end

            if state == "PATROL" then
                -- Keep patrol independent from the Quest GUI.  If the Raider quest
                -- GUI is delayed, the farmer should still scan Workspace.Enemies
                -- and immediately switch back to COMBAT when a Raider appears.

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
    local espTab = window:CreateTab("ESP")
    local MoneyTab = window:CreateTab("Auto Money")
    local combatTab = window:CreateTab("Combat")
    local fruitTab = window:CreateTab("Fruits")
    local bossTab = window:CreateTab("Bosses")

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
        Name = "Auto Sea Progress (1→2 / 2→3)",
        CurrentValue = false,
        Flag = "Farm.AutoSeaProgress", Save = true,
        Callback = function(v)
            config.autoSeaProgress = v
            if v then startSeaProgress() else stopSeaProgress() end
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
        Name = "Cluster Range",
        Min = 50, Max = 300, CurrentValue = config.clusterRange or 150, Rounding = 10,
        Flag = "Farm.ClusterRange", Save = true,
        Callback = function(v) config.clusterRange = v end,
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

    local espBuilder = window:CreateESPBuilder()

    local esp = window:CreateESPWorldRenderer({
        Builder = espBuilder,

        Enabled = false,
        MaxDistance = 10000,
        TeamCheck = false,
        VisibleCheck = false,
        IgnoreLocalPlayer = true,
    })

    espTab:CreateToggle({
        Name = "Enable ESP",
        CurrentValue = false,
        Flag = "ESP.Enabled",
        Save = true,

        Callback = function(enabled)
            esp:SetEnabled(enabled)
        end,
    })

    espTab:CreateButton({
        Name = "Open ESP Builder",

        Callback = function()
            espBuilder:Open()
        end,
    })

    local RadarSection = MoneyTab:CreateSection({Name = "Radar Chests nearby"})

    local radarOk, radarErr = pcall(function()
        RadarSection:CreateWorldRadar({
            FolderName = "ChestModels",
            Range = 2500,
            DefaultActive = true,
            AutoFly = false,
            AutoFlyMode = "SkipVisited",
            ShowAutoFlyToggle = true,
            FlySpeed = 80,
            MinFlySpeed = 20,
            MaxFlySpeed = 300,
            FlySpeedStep = 10,
            ArriveDistance = 4,
            PreserveHeight = false,
        })
    end)
    if not radarOk then
        warn("[WorldRadar]", radarErr)
    end

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

    local statsSection = mainTab:CreateSection({Name = "Auto Stats"})
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

    local equipSection = mainTab:CreateSection({Name = "Auto Equip"})
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

    local bossSection = bossTab:CreateSection({Name = "Boss Respawn Timers"})
    bossSection:CreateParagraph({
        Title = "How it works",
        Content = "Full boss list for current MAP (Sea1/Sea2/Sea3). [UP]=spawned or no timer, [CD]=countdown (HTML stripped), [?]=no marker & not in Enemies.",
    })
    bossSection:CreateToggle({
        Name = "Show Boss Timer Board",
        CurrentValue = config.bossTimersEnabled,
        Flag = "Boss.TimersEnabled",
        Save = true,
        Callback = function(v)
            config.bossTimersEnabled = v
            if v then
                startBossTimers()
            else
                stopBossTimers()
            end
        end,
    })
    bossSection:CreateToggle({
        Name = "Notify on Boss Spawn",
        CurrentValue = config.bossSpawnNotify,
        Flag = "Boss.SpawnNotify",
        Save = true,
        Callback = function(v)
            config.bossSpawnNotify = v
        end,
    })
    bossSection:CreateButton({
        Name = "Refresh Once (print F9)",
        Callback = function()
            local list = scanBossMarkers()
            print("[BF] Sea:", getCurrentSea())
            for _, row in ipairs(list) do
                print("[BF]", row.Status, row.Name, row.Time)
            end
            notifyUser("Boss Scan", "Sea " .. getCurrentSea() .. " | " .. #list .. " markers (see F9)")
        end,
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
    if config.bossTimersEnabled then
        startBossTimers()
    end
    notifyUser("Loaded", "Vaxorin UI active. Sea: " .. getCurrentSea())
else
    notifyUser("Loaded", "Fallback UI active. Use the button to start/stop.")
    if config.bossTimersEnabled then
        startBossTimers()
    end
end

-- Keep script alive
while task.wait(1) do end

print("Test 1")
