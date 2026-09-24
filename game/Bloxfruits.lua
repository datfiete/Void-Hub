-- BF_FULL_BUILD size_marker
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
print("[BF] load ok - full autofarm script")

-- Register budget: Luau max ~200 locals per function. Store API on one table.
local BF = {}


-- Load Vaxorin (or fallback UI)
local useVaxorin = false
local window = nil
local notifierLabel = nil  -- fallback notification label

-- Notification helper:
--   BF.notifyUser(title, content)
--   BF.notifyUser(title, content, duration)           -- seconds (default 3)
--   BF.notifyUser(title, content, 0) or "sticky"     -- stays until closed / replaced
-- Flood protection: same title+content won't re-fire within 2.5s
local _notifyLast = {} -- key -> os.clock()
BF.notifyUser = function(title, content, duration)
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
        pcall(function()
            if Vaxorin.Theme then
                Vaxorin.Theme.Style = "Vaxorin"
            end
        end)
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

    -- Simple toggle button (Start/Stop farm) - we'll just use the same functions later
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
        if BF.farmRunning then
            BF.stopFarm()
            toggleBtn.Text = "Start Farm"
            toggleBtn.BackgroundColor3 = Color3.new(0.2, 0.8, 0.2)
            notifierLabel.Text = "Farm stopped"
        else
            BF.startFarm()
            toggleBtn.Text = "Stop Farm"
            toggleBtn.BackgroundColor3 = Color3.new(0.8, 0.2, 0.2)
            notifierLabel.Text = "Farming..."
        end
    end)

    BF.notifyUser("UI Loaded", "Fallback UI active (Vaxorin unavailable).")
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
    hitsPerCycle = 40,
    bossHitsPerCycle = 35,
    clusterEnabled = true,
    clusterHeight = 12,
    maxClusterSize = 30,
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
    fruitFilterCollect = true,   -- only auto-collect valuable fruits
    fruitFilterNotify = false,   -- if true, only notify valuable; false = notify all
    enemyEspEnabled = false,
    enemyEspMaxDist = 2000,
    enemyEspShowName = true,
    enemyEspShowHealth = true,
    enemyEspBossColor = true,
    bossTimersEnabled = true,    -- show boss respawn board
    bossSpawnNotify = true,
    autoSeaProgress = false, -- off by default until stable
    autoSecrets = false, -- Update 30 island secrets (windmill etc.)
    autoRandomFruit = false, -- Zioles / Gacha random fruit (2h CD, Lv50+)
}

-- =============================================
-- COMBAT (copied from working FastAttack hubs: QuantumOnyx / redz-style)
-- Real damage path: getsenv(PlayerScripts LocalScript)._G.SendHitsToServer(part, bladeHits)
-- Plus: RegisterAttack, LeftClickRemote, RegisterHit fallback
-- =============================================
local _hitBodyParts = {
    "RightHand", "LeftHand", "RightLowerArm", "LeftLowerArm",
    "RightUpperArm", "LeftUpperArm", "Head", "UpperTorso", "LowerTorso", "HumanoidRootPart",
}

BF._SendHitsToServer = nil
BF._CombatController = nil
BF._m1Combo = 0
BF._comboDebounce = 0

BF.resolveSendHits = function()
    if BF._SendHitsToServer then return BF._SendHitsToServer end
    pcall(function()
        if not getsenv then return end
        local ps = LocalPlayer:FindFirstChild("PlayerScripts")
        if not ps then return end
        for _, ls in ipairs(ps:GetChildren()) do
            if ls:IsA("LocalScript") then
                local ok, env = pcall(getsenv, ls)
                if ok and type(env) == "table" then
                    local g = env._G or env
                    if type(g) == "table" and type(g.SendHitsToServer) == "function" then
                        BF._SendHitsToServer = g.SendHitsToServer
                        return
                    end
                    if type(env.SendHitsToServer) == "function" then
                        BF._SendHitsToServer = env.SendHitsToServer
                        return
                    end
                end
            end
        end
    end)
    return BF._SendHitsToServer
end

BF.resolveCombatController = function()
    if BF._CombatController then return BF._CombatController end
    pcall(function()
        local c = ReplicatedStorage:FindFirstChild("Controllers")
        local mod = c and c:FindFirstChild("CombatController")
        if mod then
            BF._CombatController = require(mod)
        end
    end)
    return BF._CombatController
end

BF.getNetRemote = function(name)
    local modules = ReplicatedStorage:FindFirstChild("Modules")
    local net = modules and modules:FindFirstChild("Net")
    if not net then return nil end
    local direct = net:FindFirstChild("RE/" .. name) or net:FindFirstChild(name)
    if direct then return direct end
    pcall(function()
        local netMod = require(net)
        if netMod and netMod.RemoteEvent then
            direct = netMod:RemoteEvent(name, true)
        end
    end)
    return direct
end

BF.getCombatRemotes = function()
    return BF.getNetRemote("RegisterAttack"), BF.getNetRemote("RegisterHit")
end

BF.getEnemyHitPart = function(enemy)
    if not enemy then return nil end
    local pick = _hitBodyParts[math.random(1, #_hitBodyParts)]
    local p = enemy:FindFirstChild(pick)
    if p and p:IsA("BasePart") then return p end
    for _, n in ipairs(_hitBodyParts) do
        p = enemy:FindFirstChild(n)
        if p and p:IsA("BasePart") then return p end
    end
    return enemy:FindFirstChildWhichIsA("BasePart")
end

BF.buildBladeHits = function(targets)
    local hits = {}
    local primary = nil
    for _, enemy in ipairs(targets) do
        if enemy and enemy.Parent then
            local hum = enemy:FindFirstChildOfClass("Humanoid")
            local root = enemy:FindFirstChild("HumanoidRootPart")
            if hum and root and hum.Health > 0 then
                local part = BF.getEnemyHitPart(enemy)
                if part then
                    table.insert(hits, { enemy, part })
                    if not primary then
                        primary = part
                    end
                end
            end
        end
    end
    return primary, hits
end

BF.getCombo = function()
    local since = tick() - BF._comboDebounce
    local combo = (since <= 0.5) and BF._m1Combo or 0
    combo = (combo >= 4) and 1 or (combo + 1)
    BF._comboDebounce = tick()
    BF._m1Combo = combo
    return combo
end

BF.fireLeftClickRemote = function(primaryPart)
    local char = LocalPlayer.Character
    if not char then return false end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then return false end
    local remote = tool:FindFirstChild("LeftClickRemote")
    if not remote then return false end
    local combo = BF.getCombo()
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local ok = pcall(function()
        if primaryPart and hrp then
            local dir = (primaryPart.Position - hrp.Position)
            if dir.Magnitude > 0.01 then
                remote:FireServer(dir.Unit, combo)
            else
                remote:FireServer(Vector3.new(0.01, -500, 0.01), combo, true)
            end
        else
            remote:FireServer(Vector3.new(0.01, -500, 0.01), combo, true)
        end
    end)
    return ok
end

BF.fireVirtualClick = function()
    -- used only for secret rope cuts, not combat spam
    pcall(function()
        local vu = game:GetService("VirtualUser")
        vu:CaptureController()
        vu:Button1Down(Vector2.new(0, 0))
        task.wait(0.05)
        vu:Button1Up(Vector2.new(0, 0))
    end)
end

-- Cobalt Assets path (updates often)
BF._combatSessionHash = "160293a1"
BF._combatNumericId = 16110659
BF._combatKey = "XO%Xomcy~oxBc~"

BF.fireAssetsHit = function(bodyPart)
    if not bodyPart then return false end
    local assets = ReplicatedStorage:FindFirstChild("Assets")
    if not assets then return false end
    local fired = false
    for _, rem in ipairs(assets:GetChildren()) do
        if rem:IsA("RemoteEvent") then
            local ok = pcall(function()
                rem:FireServer(BF._combatKey, BF._combatNumericId, bodyPart, {}, nil, BF._combatSessionHash)
            end)
            if ok then fired = true end
        end
    end
    return fired
end

-- QuantumOnyx-style: all living targets within 70 studs of player -> one bladeHits packet
BF.expandTargetsInHitRange = function(targets, maxDist)
    maxDist = maxDist or 70
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return targets end
    local byModel = {}
    for _, t in ipairs(targets or {}) do
        if t then byModel[t] = true end
    end
    -- also pull any same-folder enemies near player (cluster may miss some)
    local folder = Workspace:FindFirstChild("Enemies")
    if folder then
        for _, enemy in ipairs(folder:GetChildren()) do
            if enemy:IsA("Model") and not byModel[enemy] then
                local root = enemy:FindFirstChild("HumanoidRootPart")
                local hum = enemy:FindFirstChildOfClass("Humanoid")
                if root and hum and hum.Health > 0 then
                    if (root.Position - hrp.Position).Magnitude <= maxDist then
                        -- only if name matches any already targeted type
                        local match = false
                        for t in pairs(byModel) do
                            if t.Name == enemy.Name then match = true break end
                        end
                        if match or #targets == 0 then
                            byModel[enemy] = true
                        end
                    end
                end
            end
        end
    end
    local list = {}
    for m in pairs(byModel) do
        table.insert(list, m)
    end
    return list
end

BF.fireCombatHit = function(targets)
    if not targets or #targets == 0 then return false end
    targets = BF.expandTargetsInHitRange(targets, 70)
    local primary, hits = BF.buildBladeHits(targets)
    if not primary or #hits == 0 then return false end

    -- QuantumOnyx: RegisterAttack + SendHitsToServer(closest, full list)
    local RegisterAttack, RegisterHit = BF.getCombatRemotes()
    if RegisterAttack then
        pcall(function() RegisterAttack:FireServer(0.05) end)
    end

    local send = BF.resolveSendHits()
    if send then
        pcall(function() send(primary, hits) end)
    end
    if RegisterHit then
        pcall(function() RegisterHit:FireServer(primary, hits) end)
    end

    BF.fireLeftClickRemote(primary)

    pcall(function()
        local cc = BF.resolveCombatController()
        local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
        if cc and tool and type(cc.Attack) == "function" then
            cc:Attack(tool)
        end
    end)

    for _, pair in ipairs(hits) do
        BF.fireAssetsHit(pair[2])
    end

    return true
end

-- Cluster / Bring (hub-style, less immortal desync):
-- 1) sethiddenproperty SimulationRadius so client can own NPC physics
-- 2) Bring same-name mobs to a FIXED stack point (first target), not under BF.flying player
-- 3) Player stands above that point and multi-hits
-- Constant CFrame under a moving flyer = server position desync = red markers, 0 damage
BF.clusterStackPos = nil
BF.lastBringAt = 0

BF.ensureSimRadius = function()
    pcall(function()
        sethiddenproperty(LocalPlayer, "SimulationRadius", 10000)
    end)
    pcall(function()
        sethiddenproperty(LocalPlayer, "MaxSimulationRadius", 10000)
    end)
end

BF.collectNearbyTargets = function(allTargets, playerRoot, lockedEnemy, maxCount, radius)
    BF.ensureSimRadius()
    local list = {}
    local seen = {}
    local now = os.clock()
    local shouldBring = (now - BF.lastBringAt) >= 0.06
    if shouldBring then
        BF.lastBringAt = now
    end

    -- Fixed stack: locked enemy position (or first valid target), refresh slowly
    if lockedEnemy and lockedEnemy.Parent then
        local lr = lockedEnemy:FindFirstChild("HumanoidRootPart")
        if lr then
            if not BF.clusterStackPos or (BF.clusterStackPos - lr.Position).Magnitude > 40 then
                BF.clusterStackPos = lr.Position
            end
        end
    end
    if not BF.clusterStackPos then
        BF.clusterStackPos = playerRoot.Position - Vector3.new(0, 6, 0)
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
        local dist = (root.Position - BF.clusterStackPos).Magnitude
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
                    root.CFrame = CFrame.new(BF.clusterStackPos + Vector3.new(sx, 0, sz))
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
                d = (root.Position - BF.clusterStackPos).Magnitude,
            })
        end
    end
    table.sort(scored, function(a, b)
        return a.d < b.d
    end)
    for _, item in ipairs(scored) do
        if maxCount and maxCount > 0 and #list >= maxCount then
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
    -- Sea1 (from EnemySpawns dump MAP=Sea1 PlaceId=2753915549)
    {Name = "Pirate Starter",     Min = 0,   Max = 10,  Pos = Vector3.new(1137, 13, 1594), Quest = {"StartQuest","BanditQuest1",1}, EnemyPatterns = {"Bandit"}, isBoss = false},
    {Name = "Marine Starter",     Min = 0,   Max = 10,  Pos = Vector3.new(-2723, 32, 2090), Quest = {"StartQuest","MarineQuest1",1}, EnemyPatterns = {"Trainee"}, isBoss = false},
    {Name = "Jungle (Normal)",    Min = 10,  Max = 15,  Pos = Vector3.new(-1520, 30, 150), Quest = {"StartQuest","JungleQuest",1}, EnemyPatterns = {"Monkey"}, isBoss = false},
    {Name = "Jungle (Stage 2)",   Min = 15,  Max = 20,  Pos = Vector3.new(-1313, 18, -548), Quest = {"StartQuest","JungleQuest",2}, EnemyPatterns = {"Gorilla"}, isBoss = false},
    {Name = "Pirate Village",     Min = 30,  Max = 40,  Pos = Vector3.new(-1141, 22, 3976), Quest = {"StartQuest","BuggyQuest1",1}, EnemyPatterns = {"Pirate"}, isBoss = false},
    {Name = "Pirate Village Stage 2", Min = 40, Max = 55, Pos = Vector3.new(-1204, 28, 4370), Quest = {"StartQuest","BuggyQuest1",2}, EnemyPatterns = {"Brute"}, isBoss = false},
    {Name = "Desert 1",           Min = 60, Max = 75, Pos = Vector3.new(924, 8, 4514), Quest = {"StartQuest","DesertQuest",1}, EnemyPatterns = {"Desert Bandit"}, isBoss = false},
    {Name = "Desert 2",           Min = 75, Max = 90, Pos = Vector3.new(1573, 14, 4159), Quest = {"StartQuest","DesertQuest",2}, EnemyPatterns = {"Desert Officer"}, isBoss = false},
    {Name = "Snow 1",             Min = 90, Max = 100, Pos = Vector3.new(1416, 78, -1435), Quest = {"StartQuest","SnowQuest",1}, EnemyPatterns = {"Snow Bandit"}, isBoss = false},
    {Name = "Snow 2",             Min = 100, Max = 120, Pos = Vector3.new(1198, 98, -1603), Quest = {"StartQuest","SnowQuest",2}, EnemyPatterns = {"Snowman"}, isBoss = false},
    {Name = "Marine Fortress",    Min = 120, Max = 150, Pos = Vector3.new(-4809, 13, 4302), Quest = {"StartQuest","MarineQuest2",1}, EnemyPatterns = {"Chief Petty Officer"}, isBoss = false},
    {Name = "Sky 1",              Min = 150, Max = 175, Pos = Vector3.new(-5092, 281, -1019), Quest = {"StartQuest","SkyQuest",1}, EnemyPatterns = {"Sky Bandit"}, isBoss = false},
    {Name = "Sky 2",              Min = 175, Max = 190, Pos = Vector3.new(-5293, 505, -351), Quest = {"StartQuest","SkyQuest",2}, EnemyPatterns = {"Dark Master"}, isBoss = false},
    {Name = "Prison 1",           Min = 190, Max = 210, Pos = Vector3.new(5272, 7, 468), Quest = {"StartQuest","PrisonerQuest",1}, EnemyPatterns = {"Prisoner"}, isBoss = false},
    {Name = "Prison 2",           Min = 210, Max = 230, Pos = Vector3.new(5224, 9, 998), Quest = {"StartQuest","PrisonerQuest",2}, EnemyPatterns = {"Dangerous Prisoner"}, isBoss = false},
    {Name = "Colosseum 1",        Min = 250, Max = 275, Pos = Vector3.new(-1745, 10, -2705), Quest = {"StartQuest","ColosseumQuest",1}, EnemyPatterns = {"Toga Warrior"}, isBoss = false},
    {Name = "Colosseum 2",        Min = 275, Max = 300, Pos = Vector3.new(-1175, 12, -3214), Quest = {"StartQuest","ColosseumQuest",2}, EnemyPatterns = {"Gladiator"}, isBoss = false},
    {Name = "Magma 1",            Min = 300, Max = 325, Pos = Vector3.new(-5468, 17, 8450), Quest = {"StartQuest","MagmaQuest",1}, EnemyPatterns = {"Military Soldier"}, isBoss = false},
    {Name = "Magma 2",            Min = 325, Max = 350, Pos = Vector3.new(-5842, 77, 8773), Quest = {"StartQuest","MagmaQuest",2}, EnemyPatterns = {"Military Spy"}, isBoss = false},
    {Name = "Fishman 1",          Min = 375, Max = 400, Pos = Vector3.new(60793, 24, 1362), Quest = {"StartQuest","FishmanQuest",1}, EnemyPatterns = {"Fishman Warrior"}, isBoss = false},
    {Name = "Fishman 2",          Min = 400, Max = 425, Pos = Vector3.new(61928, 25, 1331), Quest = {"StartQuest","FishmanQuest",2}, EnemyPatterns = {"Fishman Commando"}, isBoss = false},
    {Name = "Sky Upper 1",        Min = 450, Max = 475, Pos = Vector3.new(-4241, 1089, -404), Quest = {"StartQuest","SkyExp1Quest",1}, EnemyPatterns = {"God's Guard"}, isBoss = false},
    {Name = "Sky Upper 2",        Min = 475, Max = 500, Pos = Vector3.new(-5959, 5469, 1831), Quest = {"StartQuest","SkyExp1Quest",2}, EnemyPatterns = {"Shanda"}, isBoss = false},
    {Name = "Sky Upper 3",        Min = 525, Max = 550, Pos = Vector3.new(-6798, 5552, 1214), Quest = {"StartQuest","SkyExp2Quest",1}, EnemyPatterns = {"Royal Squad"}, isBoss = false},
    {Name = "Sky Upper 4",        Min = 550, Max = 575, Pos = Vector3.new(-7064, 5541, 939), Quest = {"StartQuest","SkyExp2Quest",2}, EnemyPatterns = {"Royal Soldier"}, isBoss = false},
    {Name = "Fountain 1",         Min = 625, Max = 650, Pos = Vector3.new(5572, 78, 4010), Quest = {"StartQuest","FountainQuest",1}, EnemyPatterns = {"Galley Pirate"}, isBoss = false},
    {Name = "Fountain 2",         Min = 650, Max = 675, Pos = Vector3.new(5634, 78, 4789), Quest = {"StartQuest","FountainQuest",2}, EnemyPatterns = {"Galley Captain"}, isBoss = false},

    -- Sea1 Bosses (positions from dump) - Mob Boss is NOT a real boss quest target
    {Name = "The Gorilla King", Min = 20, Max = 30, Pos = Vector3.new(-1194, 11, -550),
        Quest = {"StartQuest","JungleQuest",2}, EnemyPatterns = {"Gorilla"},
        BossQuest = {"StartQuest","JungleQuest",3}, BossPatterns = {"The Gorilla King", "Gorilla King"},
        isBoss = true},
    {Name = "Chef", Min = 55, Max = 60, Pos = Vector3.new(-1121, 55, 4121),
        Quest = {"StartQuest","BuggyQuest1",2}, EnemyPatterns = {"Brute"},
        BossQuest = {"StartQuest","BuggyQuest1",3}, BossPatterns = {"Chef"},
        isBoss = true},
    {Name = "Yeti", Min = 105, Max = 120, Pos = Vector3.new(1182, 104, -1617),
        Quest = {"StartQuest","SnowQuest",2}, EnemyPatterns = {"Snowman"},
        BossQuest = {"StartQuest","SnowQuest",3}, BossPatterns = {"Yeti"},
        isBoss = true},
    {Name = "Vice Admiral", Min = 130, Max = 150, Pos = Vector3.new(-5011, 15, 4384),
        Quest = {"StartQuest","MarineQuest2",1}, EnemyPatterns = {"Chief Petty Officer"},
        BossQuest = {"StartQuest","MarineQuest2",2}, BossPatterns = {"Vice Admiral"},
        isBoss = true},
    {Name = "Warden", Min = 220, Max = 240, Pos = Vector3.new(5623, 1, 734),
        Quest = {"StartQuest","PrisonerQuest",2}, EnemyPatterns = {"Dangerous Prisoner"},
        BossQuest = nil, BossPatterns = {"Warden"},
        isBoss = true},
    {Name = "Magma General", Min = 350, Max = 375, Pos = Vector3.new(-5626, 55, 8623),
        Quest = {"StartQuest","MagmaQuest",2}, EnemyPatterns = {"Military Spy"},
        BossQuest = {"StartQuest","MagmaQuest",3}, BossPatterns = {"Magma General"},
        isBoss = true},
    {Name = "Fishman Lord", Min = 425, Max = 450, Pos = Vector3.new(61353, 67, 1029),
        Quest = {"StartQuest","FishmanQuest",2}, EnemyPatterns = {"Fishman Commando"},
        BossQuest = {"StartQuest","FishmanQuest",3}, BossPatterns = {"Fishman Lord"},
        isBoss = true},
    {Name = "Sky Warlord", Min = 500, Max = 525, Pos = Vector3.new(-6272, 5473, 1888),
        Quest = {"StartQuest","SkyExp1Quest",2}, EnemyPatterns = {"Shanda"},
        BossQuest = {"StartQuest","SkyExp1Quest",3}, BossPatterns = {"Sky Warlord"},
        isBoss = true},
    {Name = "Lightning God", Min = 575, Max = 625, Pos = Vector3.new(-7125, 5596, 112),
        Quest = {"StartQuest","SkyExp2Quest",2}, EnemyPatterns = {"Royal Soldier"},
        BossQuest = {"StartQuest","SkyExp2Quest",3}, BossPatterns = {"Lightning God"},
        isBoss = true},
    {Name = "Cyborg", Min = 675, Max = 700, Pos = Vector3.new(6252, 9, 4941),
        Quest = {"StartQuest","FountainQuest",2}, EnemyPatterns = {"Galley Captain"},
        BossQuest = {"StartQuest","FountainQuest",3}, BossPatterns = {"Cyborg"},
        isBoss = true},
    {Name = "Ice Admiral", Min = 700, Max = 725, Pos = Vector3.new(1212, 20, -1430),
        Quest = nil, EnemyPatterns = {},
        BossQuest = nil, BossPatterns = {"Ice Admiral"},
        isBoss = true},

    -- Sea2 normals
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

    -- Sea1 bosses (deduped positions from dump)
    {Name = "Chief Warden",       Min = 230, Max = 250, Pos = Vector3.new(5117, 2, 483),
        Quest = {"StartQuest","PrisonerQuest",2}, EnemyPatterns = {"Dangerous Prisoner"},
        BossQuest = {"StartQuest","ImpelQuest",2}, BossPatterns = {"Chief Warden"},
        isBoss = true},
    {Name = "Swan",               Min = 240, Max = 250, Pos = Vector3.new(5117, 2, 483),
        Quest = {"StartQuest","PrisonerQuest",2}, EnemyPatterns = {"Dangerous Prisoner"},
        BossQuest = {"StartQuest","ImpelQuest",3}, BossPatterns = {"Swan"},
        isBoss = true},

    -- Sea2 bosses
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
BF.noclipConnection = nil

BF.enableNoclip = function()
    if BF.noclipConnection then return end
    BF.noclipConnection = RunService.Heartbeat:Connect(function()
        local character = LocalPlayer.Character
        if not character then return end
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end)
end

BF.disableNoclip = function()
    if BF.noclipConnection then
        BF.noclipConnection:Disconnect()
        BF.noclipConnection = nil
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

BF.flyTarget = nil
BF.flyConnection = nil
BF.flying = false
BF.hoverY = nil
BF._bossFlyUnlock = false

-- Keep the player on a stable horizontal flight plane.  The old implementation
-- always added upward velocity, which made the character arc and slowly sink.
BF.enableFly = function()
    if BF.flying then return end
    local character = LocalPlayer.Character
    if not character then return end
    local humanoid = character:FindFirstChild("Humanoid")
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not hrp then return end

    BF.flying = true
    BF.hoverY = hrp.Position.Y
    humanoid.PlatformStand = true
    BF.enableNoclip()

    BF.flyConnection = RunService.Heartbeat:Connect(function()
        if not BF.flying then return end

        local currentCharacter = LocalPlayer.Character
        local currentHrp = currentCharacter and currentCharacter:FindFirstChild("HumanoidRootPart")
        local currentHumanoid = currentCharacter and currentCharacter:FindFirstChild("Humanoid")
        if not currentHrp or not currentHumanoid or currentHumanoid.Health <= 0 then return end

        if not BF.hoverY then BF.hoverY = currentHrp.Position.Y end

        local target = BF.flyTarget
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
            BF.hoverY = BF.hoverY or currentHrp.Position.Y
            local verticalError = BF.hoverY - currentHrp.Position.Y
            currentHrp.AssemblyLinearVelocity = Vector3.new(0, math.clamp(verticalError * 6, -20, 20), 0)
            currentHrp.AssemblyAngularVelocity = Vector3.zero
        end
    end)
end

BF.disableFly = function()
    if not BF.flying then return end
    BF.flying = false
    if BF.flyConnection then
        BF.flyConnection:Disconnect()
        BF.flyConnection = nil
    end
    BF.flyTarget = nil
    BF.hoverY = nil

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
    BF.disableNoclip()
end

BF.setFlyTarget = function(position, preserveHeight)
    -- While a selected boss is UP/? and hunt is active, Auto Farm must not steal the target.
    -- Boss hunt sets BF._bossFlyUnlock for its own calls.
    if BF.bossHuntOwnsFly and type(BF.bossHuntOwnsFly) == "function" and BF.bossHuntOwnsFly() then
        if not BF._bossFlyUnlock then
            return
        end
    end
    if not BF.flying then BF.enableFly() end
    if not position then
        BF.flyTarget = nil
        return
    end

    if preserveHeight and BF.hoverY then
        position = Vector3.new(position.X, BF.hoverY, position.Z)
    else
        BF.hoverY = position.Y
    end
    BF.flyTarget = position
end

BF.setHoverHeight = function(y)
    if BF.bossHuntOwnsFly and type(BF.bossHuntOwnsFly) == "function" and BF.bossHuntOwnsFly() then
        if not BF._bossFlyUnlock then
            return
        end
    end
    BF.hoverY = y
    if BF.flyTarget then
        BF.flyTarget = Vector3.new(BF.flyTarget.X, y, BF.flyTarget.Z)
    end
end

-- Blox Fruits has an underwater entrance/whirlpool.  Servers can name the
-- object differently, so check both parts and models for common whirlpool names.
BF.findWhirlpool = function()
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

BF.isUnderwaterIsland = function(island)
    if not island then return false end
    return island.Name:lower():find("underwater", 1, true) ~= nil
        or island.Name:lower():find("submerged", 1, true) ~= nil
end

-- =============================================
-- QUEST STACK & HELPERS
-- =============================================
BF.acceptQuest = function(questArgs)
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

BF.stackQuest = function(questArgs, count)
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

BF.acceptQuestWrapper = function(questArgs)
    if questArgs and questArgs[2] and type(BF.activeQuestMatches) == "function" then
        local ok, matched = pcall(function()
            return BF.activeQuestMatches(tostring(questArgs[2]))
        end)
        if ok and matched then
            return true
        end
    end
    if config.questStack and questArgs then
        return BF.stackQuest(questArgs, config.stackCount)
    else
        return BF.acceptQuest(questArgs)
    end
end

BF.abandonQuest = function()
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
BF.autoEquipWeapon = function()
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
BF.fruitNotifierRunning = false
BF.fruitNotified = {} -- instance or name key -> true (already announced)

-- Valuable fruits for filter (auto-collect / optional notify)
local FRUIT_WHITELIST = {
    "dragon", "kitsune", "yeti", "leopard", "tiger", "gas", "dough", "control",
    "mammoth", "spirit", "venom", "soul", "blizzard", "phoenix", "buddha",
    "shadow", "gravity", "spider", "rumble", "portal", "quake", "pain", "love",
    "sound", "creation", "light", "magma", "rubber", "barrier", "ghost",
    "dark", "ice", "flame", "sand", "quake", "string", "paw", "trex", "t-rex",
    "east dragon", "west dragon", "dough-dough", "dragon-dragon",
}

BF.isValuableFruit = function(name)
    local n = string.lower(tostring(name or ""))
    for _, w in ipairs(FRUIT_WHITELIST) do
        if string.find(n, w, 1, true) then return true end
    end
    return false
end

BF.getFruitHandle = function(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then return obj end
    local h = obj:FindFirstChild("Handle")
    if h and h:IsA("BasePart") then return h end
    return obj:FindFirstChildWhichIsA("BasePart", true)
end

BF.isWorldFruit = function(obj)
    if not obj then return false end
    -- Tool on ground
    if obj:IsA("Tool") then
        local parent = obj.Parent
        if parent and parent:IsA("Model") and parent:FindFirstChildOfClass("Humanoid") then
            return false -- held by player
        end
        if parent and parent:IsA("Backpack") then return false end
        return BF.getFruitHandle(obj) ~= nil
    end
    -- Fruit model / spawn marker
    local n = string.lower(obj.Name)
    if string.find(n, "fruit", 1, true) then
        return BF.getFruitHandle(obj) ~= nil or obj:IsA("Model") or obj:IsA("BasePart")
    end
    return false
end

BF.fruitScan = function()
    if not config.fruitNotifier and not config.fruitAutoCollect then return end

    local candidates = {}

    -- 1) Workspace root tools/fruits
    for _, v in ipairs(Workspace:GetChildren()) do
        if BF.isWorldFruit(v) then
            table.insert(candidates, v)
        end
    end

    -- 2) workspace._WorldOrigin.FruitSpawns
    pcall(function()
        local wo = Workspace:FindFirstChild("_WorldOrigin")
        local fs = wo and wo:FindFirstChild("FruitSpawns")
        if not fs then return end
        for _, v in ipairs(fs:GetChildren()) do
            if BF.isWorldFruit(v) or v:IsA("BasePart") or v:IsA("Model") then
                table.insert(candidates, v)
            end
        end
        -- nested
        for _, v in ipairs(fs:GetDescendants()) do
            if v:IsA("Tool") and BF.isWorldFruit(v) then
                table.insert(candidates, v)
            end
        end
    end)

    for _, v in ipairs(candidates) do
        local handle = BF.getFruitHandle(v)
        local pos = handle and handle.Position
        if (not pos) and v:IsA("Model") then
            local okp, piv = pcall(function() return v:GetPivot().Position end)
            if okp then pos = piv end
        end
        if pos then
            local displayName = v.Name
            local key = tostring(v) .. "|" .. displayName
            local valuable = BF.isValuableFruit(displayName)

            if not BF.fruitNotified[key] then
                BF.fruitNotified[key] = true
                local shouldNotify = config.fruitNotifier
                if shouldNotify and config.fruitFilterNotify and not valuable then
                    shouldNotify = false
                end
                if shouldNotify then
                    local tag = valuable and " [VAL]" or ""
                    BF.notifyUser("Fruit Detected", displayName .. tag, 4)
                end
            end

            local canCollect = config.fruitAutoCollect
            if canCollect then
                local owns = false
                pcall(function()
                    if type(BF.bossHuntOwnsFly) == "function" then owns = BF.bossHuntOwnsFly() end
                end)
                if owns then canCollect = false end
            end
            if canCollect and config.fruitFilterCollect and not valuable then
                canCollect = false
            end
            if canCollect then
                pcall(function() BF.setFlyTarget(pos + Vector3.new(0, 5, 0), false) end)
                task.wait(0.4)
                local character = LocalPlayer.Character
                local hrp = character and character:FindFirstChild("HumanoidRootPart")
                if hrp and (hrp.Position - pos).Magnitude < 20 then
                    pcall(function()
                        if firetouchinterest and handle then
                            firetouchinterest(hrp, handle, 0)
                            firetouchinterest(hrp, handle, 1)
                        end
                    end)
                    pcall(function()
                        VirtualInputManager:SendKeyEvent(true, "E", false, game)
                        task.wait(0.1)
                        VirtualInputManager:SendKeyEvent(false, "E", false, game)
                    end)
                    BF.notifyUser("Fruit", "Collected " .. displayName, 2)
                end
                break
            end
        end
    end

    if os.clock() % 30 < 2 then
        for k in pairs(BF.fruitNotified) do
            BF.fruitNotified[k] = nil
        end
    end
end

BF.startFruitNotifier = function()
    if BF.fruitNotifierRunning then return end
    BF.fruitNotifierRunning = true
    task.spawn(function()
        while BF.fruitNotifierRunning do
            pcall(BF.fruitScan)
            task.wait(2) -- never Heartbeat+wait spam
        end
    end)
end

BF.stopFruitNotifier = function()
    BF.fruitNotifierRunning = false
end

-- =============================================
-- HELPERS
-- =============================================
BF.getPlayerLevel = function()
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

BF.getAvailableStatPoints = function()
    local data = LocalPlayer:FindFirstChild("Data")
    if data then
        local points = data:FindFirstChild("Points")
        if points then return points.Value end
    end
    return 0
end

BF.getIslandForLevel = function(level)
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

-- TrackedQuestFrame = has quest; gone = no quest / completed
-- Text: TrackedQuestFrame.Frame.header.textLabel ContentText e.g. "Defeat 8 Brutes"
BF.getTrackedQuestLabel = function()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return nil end
    local tqf = pg:FindFirstChild("TrackedQuestFrame")
    if not tqf then return nil end
    local frame = tqf:FindFirstChild("Frame")
    local header = frame and frame:FindFirstChild("header")
    local label = header and (header:FindFirstChild("textLabel") or header:FindFirstChild("TextLabel"))
    if label and (label:IsA("TextLabel") or label:IsA("TextButton")) then
        return label
    end
    -- fallback: any TextLabel under TrackedQuestFrame
    for _, d in ipairs(tqf:GetDescendants()) do
        if d:IsA("TextLabel") and d.Text and #d.Text > 2 then
            return d
        end
    end
    return nil
end

BF.hasActiveQuest = function()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return false end
    return pg:FindFirstChild("TrackedQuestFrame") ~= nil
end

BF.getActiveQuestInfo = function()
    if not BF.hasActiveQuest() then
        return false, "", ""
    end
    local label = BF.getTrackedQuestLabel()
    local text = ""
    if label then
        text = tostring(label.ContentText or label.Text or "")
    end
    return true, text, text
end

BF.activeQuestMatches = function(...)
    local active, title, body = BF.getActiveQuestInfo()
    if not active then return false end
    local hay = string.lower(title .. " " .. body)
    for i = 1, select("#", ...) do
        local n = string.lower(tostring(select(i, ...)))
        if n ~= "" and string.find(hay, n, 1, true) then return true end
    end
    return false
end

-- Derive farm patterns from tracked quest text when possible

-- While a quest is still active, farm THAT quest's mobs even if level unlocked the next island.
BF.resolveFarmPatterns = function(island, questType)
    local patternInfo = BF.getPatterns(island, questType or "normal")
    if BF.hasActiveQuest() then
        local _, qtext = BF.getActiveQuestInfo()
        local fromQuest = BF.getPatternsFromQuestText(qtext, patternInfo and patternInfo.patterns)
        if fromQuest and #fromQuest > 0 then
            return { patterns = fromQuest, includeBossAttr = false }
        end
    end
    return patternInfo
end

BF.resolveFarmIsland = function(level)
    local island = BF.getIslandForLevel(level)
    if not BF.hasActiveQuest() then
        return island
    end
    local _, qtext = BF.getActiveQuestInfo()
    local fromQuest = BF.getPatternsFromQuestText(qtext, nil)
    if not fromQuest or not fromQuest[1] then
        return island
    end
    local p = string.lower(fromQuest[1])
    for _, isl in ipairs(islands) do
        for _, ep in ipairs(isl.EnemyPatterns or {}) do
            local epl = string.lower(ep)
            if string.find(epl, p, 1, true) or string.find(p, epl, 1, true) then
                return isl
            end
        end
        for _, ep in ipairs(isl.BossPatterns or {}) do
            local epl = string.lower(ep)
            if string.find(epl, p, 1, true) or string.find(p, epl, 1, true) then
                return isl
            end
        end
    end
    return island
end

BF.getPatternsFromQuestText = function(text, fallbackPatterns)
    text = string.lower(tostring(text or ""))
    if text == "" then return fallbackPatterns end
    -- "Defeat 8 Brutes" / "Defeat Bandits" etc.
    local known = {
        "bandit", "trainee", "monkey", "gorilla", "pirate", "brute",
        "desert bandit", "desert officer", "snow bandit", "snowman",
        "chief petty officer", "sky bandit", "dark master", "prisoner",
        "dangerous prisoner", "toga warrior", "gladiator",
        "military soldier", "military spy", "fishman warrior", "fishman commando",
        "god's guard", "shanda", "royal squad", "royal soldier",
        "galley pirate", "galley captain", "raider", "mercenary",
        "swan pirate", "factory staff", "marine lieutenant", "marine captain",
        "zombie", "vampire", "snow trooper", "winter warrior",
        "lab subordinate", "horned warrior", "magma ninja", "lava pirate",
        "ship deckhand", "ship engineer", "ship steward", "ship officer",
        "arctic warrior", "snow lurker", "sea soldier", "water fighter",
    }
    local found = {}
    for _, name in ipairs(known) do
        if string.find(text, name, 1, true) then
            -- prefer longer matches: store as-is
            table.insert(found, name)
        end
    end
    if #found == 0 then return fallbackPatterns end
    -- use longest match first
    table.sort(found, function(a, b) return #a > #b end)
    return { found[1] }
end

-- =============================================
-- BOSS DETECTION
-- =============================================
BF.findBossInWorkspace = function(island)
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

BF.bossExists = function(island)
    return BF.findBossInWorkspace(island) ~= nil
end

BF.getDesiredQuestType = function(island)
    if not island.isBoss then return "normal" end
    if BF.bossExists(island) then return "boss" else return "normal" end
end

BF.getQuestArgs = function(island, questType)
    if questType == "boss" then return island.BossQuest else return island.Quest end
end

BF.getPatterns = function(island, questType)
    if questType == "boss" then
        return { patterns = island.BossPatterns, includeBossAttr = true }
    else
        return { patterns = island.EnemyPatterns, includeBossAttr = false }
    end
end

-- =============================================
-- ENEMY TARGETING
-- =============================================
BF.enemyMatchesPatterns = function(enemy, patternInfo)
    if not enemy or not enemy:IsA("Model") then return false end
    local humanoid = enemy:FindFirstChildOfClass("Humanoid")
    local root = enemy:FindFirstChild("HumanoidRootPart")
    local head = enemy:FindFirstChild("Head")
    if not humanoid or humanoid.Health <= 0 or not root or not head then return false end

    local lower = string.lower(enemy.Name)
    local wantBoss = patternInfo.includeBossAttr == true

    -- Boss-only mode
    if wantBoss then
        if enemy:GetAttribute("isBoss") == true or string.find(lower, "%[boss%]") then
            return true
        end
        for _, pattern in ipairs(patternInfo.patterns or {}) do
            local p = string.lower(pattern)
            if string.sub(lower, 1, #p) == p then
                return true
            end
        end
        return false
    end

    -- Normal farm: NEVER take bosses (Gorilla King while farming Gorilla)
    if enemy:GetAttribute("isBoss") == true then return false end
    if string.find(lower, "%[boss%]") then return false end

    for _, pattern in ipairs(patternInfo.patterns or {}) do
        local p = string.lower(pattern)
        -- must start with pattern as a name token (not mid-string)
        if string.sub(lower, 1, #p) == p then
            local nextc = string.sub(lower, #p + 1, #p + 1)
            if nextc == "" or nextc == " " or nextc == "[" then
                local rest = string.sub(lower, #p + 1)
                -- reject "Gorilla King", "Fishman Lord", etc. unless pattern includes that word
                if string.find(rest, "^%s+king") or string.find(rest, "^%s+lord")
                    or string.find(rest, "^%s+admiral") or string.find(rest, "^%s+boss") then
                    -- allow if pattern itself was e.g. "Gorilla King"
                    if not string.find(p, "king") and not string.find(p, "lord")
                        and not string.find(p, "admiral") and not string.find(p, "boss") then
                        -- skip this pattern match
                    else
                        return true
                    end
                else
                    return true
                end
            end
        end
    end
    return false
end

BF.getMatchingEnemies = function(island, patternInfo)
    local container = Workspace:FindFirstChild("Enemies")
    if not container then return {} end
    local enemies = {}
    for _, enemy in ipairs(container:GetChildren()) do
        if BF.enemyMatchesPatterns(enemy, patternInfo) then
            table.insert(enemies, enemy)
        end
    end
    return enemies
end

-- =============================================
-- FAST REMOTE ATTACK (no mouse)
-- =============================================
BF.selectAttackWeapon = function()
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

BF.attackTargets = function(targets, speed, hits)
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

    BF.selectAttackWeapon()

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
        BF.fireCombatHit(alive)
        task.wait(delay)
    end
end

BF.attackEnemy = function(target, speed, hits)
    BF.attackTargets({target}, speed, hits)
end

BF.heal = function()
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
BF.addStatPoints = function(statName, points)
    if points <= 0 then return end
    local remote = ReplicatedStorage:FindFirstChild("Remotes")
    if remote then
        local commF = remote:FindFirstChild("CommF_")
        if commF then
            pcall(function() commF:InvokeServer("AddPoint", statName, points) end)
        end
    end
end

BF.distributeStats = function(statsList, pointsPerStat, silent)
    if not statsList or #statsList == 0 then
        if not silent then BF.notifyUser("Stats Error", "No stats selected.") end
        return
    end
    local available = BF.getAvailableStatPoints()
    if available <= 0 then
        if not silent then BF.notifyUser("No Stat Points", "You have 0 stat points available.") end
        return
    end
    local totalNeeded = #statsList * pointsPerStat
    local pointsToAdd = pointsPerStat
    if totalNeeded > available then
        pointsToAdd = math.floor(available / #statsList)
        if pointsToAdd == 0 then
            if not silent then BF.notifyUser("Not Enough Points", "You have " .. available .. " points, need at least " .. #statsList .. " to add 1 to each stat.") end
            return
        end
    end
    local added = 0
    for _, stat in ipairs(statsList) do
        if available >= added + pointsToAdd then
            BF.addStatPoints(stat, pointsToAdd)
            added = added + pointsToAdd
        else
            break
        end
    end
    local remaining = available - added
    if not silent and added > 0 then
        BF.notifyUser("Stats Added", "Added " .. pointsToAdd .. " to " .. table.concat(statsList, ", ") .. ". Remaining: " .. remaining)
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
        "__NO_MOB_BOSS__",
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
        "Magma General",
        "Sky Warlord",
        "Lightning God",
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
    ["Lightning God"] = { "Lightning God", "Lightning God" },
    ["Lightning God"] = { "Lightning God", "Lightning God" },
    ["rip_indra"] = { "rip_indra", "Rip Indra", "Indra" },
    ["Core"] = { "Core", "CORE" },
    ["Hydra Leader"] = { "Hydra Leader", "Island Empress" },
    ["Island Empress"] = { "Island Empress", "Hydra Leader" },
    ["The Gorilla King"] = { "The Gorilla King", "Gorilla King" },
    ["Sky Warlord"] = { "Sky Warlord", "Sky Warlord" },
}

BF.stripEnemyLabel = function(name)
    -- "Diamond [Lv. 750] [Boss]" -> "Diamond"
    name = tostring(name or "")
    name = string.gsub(name, "%s*%[Lv%.%s*%d+%]%s*", " ")
    name = string.gsub(name, "%s*%[Boss%]%s*", " ")
    name = string.gsub(name, "%s+", " ")
    return (string.match(name, "^%s*(.-)%s*$")) or name
end

BF.collectBossesFromEnemySpawns = function()
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
            local short = BF.stripEnemyLabel(label)
            if short ~= "" and not seen[string.lower(short)] then
                seen[string.lower(short)] = true
                table.insert(list, short)
            end
        end
    end
    table.sort(list)
    return list
end

BF.averageSpawnPosition = function(enemyShortName)
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
            local short = string.lower(BF.stripEnemyLabel(label))
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

BF.bossTimerGui = nil
BF.bossTimerLabel = nil
BF.bossTimerRunning = false
BF.bossTimerTask = nil
BF.lastBossStatus = {} -- name -> "SPAWNED" | "RESPAWNING" | "UNKNOWN"
-- Timer UI can blink out of workspace for a frame; require stable absence before SPAWNED
BF.pendingSpawnConfirm = {} -- name -> os.clock() when timer first disappeared while we thought CD
local SPAWN_CONFIRM_DELAY = 1.0
BF.selectedBosses = {}
BF.unknownProbeDone = {}
BF.bossListFrame = nil
BF.bossAutoHuntEnabled = true
BF.activeBossHuntTask = nil
BF.activeBossHuntName = nil

BF.normalizeSea = function(mapAttr)
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

BF.getCurrentSea = function()
    return BF.normalizeSea(workspace:GetAttribute("MAP"))
end

BF.cleanTimerText = function(raw)
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

BF.findBossTimerLabel = function(marker)
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

BF.nameMatches = function(bossName, candidate)
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

BF.scanMarkerMap = function()
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
            local timerLabel = BF.findBossTimerLabel(child)
            local status, timeText
            if timerLabel and timerLabel.Parent then
                local cleaned = BF.cleanTimerText(timerLabel.Text)
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

BF.enemyAliveMatching = function(bossName)
    local enemies = workspace:FindFirstChild("Enemies")
    if not enemies then
        return false
    end
    for _, model in ipairs(enemies:GetChildren()) do
        if BF.nameMatches(bossName, model.Name) then
            local hum = model:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                return true
            end
        end
    end
    return false
end

BF.lookupMarker = function(markerMap, bossName)
    for key, data in pairs(markerMap) do
        if type(data) == "table" and data.Status and BF.nameMatches(bossName, data.MarkerName or key) then
            return data
        end
    end
    return nil
end

BF.scanBossesForSea = function()
    local sea = BF.getCurrentSea()
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

    -- 1) live from EnemySpawns ([Boss] parts) - authoritative for this server/sea
    for _, name in ipairs(BF.collectBossesFromEnemySpawns()) do
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

    local markerMap = BF.scanMarkerMap()
    local results = {}
    local now = os.clock()
    for _, bossName in ipairs(catalog) do
        local status, timeText
        if BF.enemyAliveMatching(bossName) then
            status = "SPAWNED"
            timeText = "-"
            BF.pendingSpawnConfirm[bossName] = nil
        else
            local m = BF.lookupMarker(markerMap, bossName)
            if m then
                if m.Status == "RESPAWNING" then
                    -- timer visible again -> cancel any pending spawn confirm
                    status = "RESPAWNING"
                    timeText = m.Time
                    BF.pendingSpawnConfirm[bossName] = nil
                else
                    -- marker exists but no timer text (often "SPAWNED", but can be a 1-frame glitch)
                    local prev = BF.lastBossStatus[bossName]
                    if prev == "RESPAWNING" or BF.pendingSpawnConfirm[bossName] then
                        local t0 = BF.pendingSpawnConfirm[bossName]
                        if not t0 then
                            BF.pendingSpawnConfirm[bossName] = now
                            status = "RESPAWNING"
                            timeText = "..."
                        elseif (now - t0) < SPAWN_CONFIRM_DELAY then
                            status = "RESPAWNING"
                            timeText = "..."
                        else
                            status = "SPAWNED"
                            timeText = "-"
                            BF.pendingSpawnConfirm[bossName] = nil
                        end
                    else
                        status = "SPAWNED"
                        timeText = "-"
                        BF.pendingSpawnConfirm[bossName] = nil
                    end
                end
            else
                -- no marker at all
                local prev = BF.lastBossStatus[bossName]
                if prev == "RESPAWNING" or BF.pendingSpawnConfirm[bossName] then
                    local t0 = BF.pendingSpawnConfirm[bossName]
                    if not t0 then
                        BF.pendingSpawnConfirm[bossName] = now
                        status = "RESPAWNING"
                        timeText = "..."
                    elseif (now - t0) < SPAWN_CONFIRM_DELAY then
                        status = "RESPAWNING"
                        timeText = "..."
                    else
                        -- confirmed gone: SPAWNED (sticky), not ?
                        status = "SPAWNED"
                        timeText = "-"
                        BF.pendingSpawnConfirm[bossName] = nil
                    end
                elseif prev == "SPAWNED" then
                    status = "SPAWNED"
                    timeText = "-"
                else
                    status = "UNKNOWN"
                    timeText = "-"
                    BF.pendingSpawnConfirm[bossName] = nil
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
BF.scanBossMarkers = function()
    local pack = BF.scanBossesForSea()
    return pack.List, pack.Sea
end

BF.formatBossBoard = function(list, sea)
    sea = sea or BF.getCurrentSea()
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

BF.makeDraggable = function(handle, target)
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
BF.bossHuntOwnsFly = function()
    if not BF.bossAutoHuntEnabled then
        return false
    end
    if BF.activeBossHuntName and BF.selectedBosses[BF.activeBossHuntName] then
        return true
    end
    return false
end

BF.flyToBossPosition = function(bossName)
    BF._bossFlyUnlock = true
    local pos = BF.averageSpawnPosition(bossName)
    if not pos then
        local origin = workspace:FindFirstChild("_WorldOrigin")
        if origin then
            for _, child in ipairs(origin:GetChildren()) do
                if string.find(child.Name, "Respawn Marker", 1, true) then
                    local bn = string.gsub(child.Name, "%s*Respawn Marker%s*$", "")
                    if BF.nameMatches(bossName, bn) then
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
        BF._bossFlyUnlock = false
        BF.notifyUser("Boss Hunt", bossName .. ": no position", 2)
        return false
    end
    BF.setFlyTarget(pos + Vector3.new(0, 12, 0), false)
    BF._bossFlyUnlock = false
    return true
end

-- Try accept boss quest from islands table BossQuest / patterns
BF.tryAcceptBossQuest = function(bossName)
    for _, island in ipairs(islands) do
        local patterns = island.BossPatterns or (island.isBoss and island.EnemyPatterns) or {}
        local hit = false
        for _, p in ipairs(patterns) do
            if BF.nameMatches(bossName, p) then
                hit = true
                break
            end
        end
        if not hit and BF.nameMatches(bossName, island.Name) then
            hit = true
        end
        if hit then
            local args = island.BossQuest or island.Quest
            if args then
                pcall(function()
                    BF.acceptQuestWrapper(args)
                end)
                return true
            end
        end
    end
    return false
end

BF.findBossModelByName = function(bossName)
    local enemies = workspace:FindFirstChild("Enemies")
    if not enemies then
        return nil
    end
    local best, bestDist = nil, math.huge
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local origin = hrp and hrp.Position or Vector3.zero
    for _, model in ipairs(enemies:GetChildren()) do
        if BF.nameMatches(bossName, model.Name) then
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

BF.stopActiveBossHunt = function(reason)
    if BF.activeBossHuntTask then
        pcall(function()
            task.cancel(BF.activeBossHuntTask)
        end)
    end
    BF.activeBossHuntTask = nil
    if BF.activeBossHuntName and BF.selectedBosses[BF.activeBossHuntName] == "hunting" then
        BF.selectedBosses[BF.activeBossHuntName] = true
    end
    BF.activeBossHuntName = nil
end

BF.startBossHuntCombat = function(bossName)
    if BF.activeBossHuntName == bossName and BF.activeBossHuntTask then
        return
    end
    BF.stopActiveBossHunt(nil)
    BF.activeBossHuntName = bossName
    BF.selectedBosses[bossName] = "hunting"
    BF.flyToBossPosition(bossName)
    BF.tryAcceptBossQuest(bossName)
    BF.notifyUser("Boss Hunt", "Engaging " .. bossName, 2)

    BF.activeBossHuntTask = task.spawn(function()
        local deadline = os.clock() + 180
        local speed = (config and config.bossAttackSpeed) or 0.002
        local hits = (config and config.bossHitsPerCycle) or 35
        local above = math.clamp((config and config.aboveHeight) or 8, 4, 14)
        local questTriedAt = 0

        while BF.bossTimerRunning and BF.selectedBosses[bossName] and os.clock() < deadline do
            if not BF.flying then
                pcall(BF.enableFly)
            end
            -- re-try quest every ~8s while hunting
            if os.clock() - questTriedAt > 8 then
                questTriedAt = os.clock()
                BF.tryAcceptBossQuest(bossName)
            end

            local boss = BF.findBossModelByName(bossName)
            if boss then
                local root = boss:FindFirstChild("HumanoidRootPart")
                local hum = boss:FindFirstChildOfClass("Humanoid")
                if root and hum and hum.Health > 0 then
                    local character = LocalPlayer.Character
                    local hrp = character and character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local dist = (hrp.Position - root.Position).Magnitude
                        BF._bossFlyUnlock = true
                        BF.setFlyTarget(root.Position + Vector3.new(0, above, 0), false)
                        BF._bossFlyUnlock = false
                        if dist <= ((config and config.attackRange) or 30) + 10 then
                            pcall(function()
                                BF.attackEnemy(boss, speed, hits)
                            end)
                        end
                    end
                else
                    break
                end
            else
                BF.flyToBossPosition(bossName)
                task.wait(0.35)
            end
            task.wait(0.05)
        end

        if BF.selectedBosses[bossName] == "hunting" then
            BF.selectedBosses[bossName] = true
        end
        if BF.activeBossHuntName == bossName then
            BF.activeBossHuntTask = nil
            BF.activeBossHuntName = nil
        end
        BF.notifyUser("Boss Hunt", bossName .. " hunt ended", 2)
    end)
end

-- Stable list: create buttons once, only update text/colors (fixes click delay)
BF.bossRowButtons = {} -- name -> TextButton

BF.rebuildBossListRows = function(list)
    if not BF.bossListFrame then
        return
    end

    local seen = {}
    local y = 0
    for _, row in ipairs(list or {}) do
        seen[row.Name] = true
        local sel = BF.selectedBosses[row.Name] ~= nil
        local hunting = BF.selectedBosses[row.Name] == "hunting"
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

        local btn = BF.bossRowButtons[row.Name]
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
            btn.Parent = BF.bossListFrame
            local c = Instance.new("UICorner")
            c.CornerRadius = UDim.new(0, 5)
            c.Parent = btn
            local name = row.Name
            btn.MouseButton1Click:Connect(function()
                if BF.selectedBosses[name] then
                    BF.selectedBosses[name] = nil
                    BF.unknownProbeDone[name] = nil
                    if BF.activeBossHuntName == name then
                        BF.stopActiveBossHunt("deselected")
                    end
                else
                    BF.selectedBosses[name] = true
                    BF.unknownProbeDone[name] = nil
                end
                -- instant visual feedback
                local isOn = BF.selectedBosses[name] ~= nil
                btn.BackgroundColor3 = isOn and Color3.fromRGB(40, 90, 55) or Color3.fromRGB(24, 26, 34)
                local t = btn.Text
                if isOn then
                    btn.Text = (t:gsub("%[ %]", "[x]", 1):gsub("^ %[ %]", " [x]"))
                    if not btn.Text:find("%[x%]", 1) then
                        btn.Text = " [x] " .. name
                    end
                end
            end)
            BF.bossRowButtons[row.Name] = btn
        end

        btn.Position = UDim2.new(0, 2, 0, y)
        btn.Text = " " .. mark .. " " .. tag .. "  " .. row.Name
        btn.BackgroundColor3 = (sel or hunting) and Color3.fromRGB(40, 90, 55) or Color3.fromRGB(24, 26, 34)
        y = y + 28
    end

    -- remove rows no longer in list
    for name, btn in pairs(BF.bossRowButtons) do
        if not seen[name] then
            pcall(function() btn:Destroy() end)
            BF.bossRowButtons[name] = nil
        end
    end
    BF.bossListFrame.CanvasSize = UDim2.new(0, 0, 0, y + 10)
end

BF.processBossHuntActions = function(list)
    if not BF.bossAutoHuntEnabled then
        return
    end
    for _, row in ipairs(list or {}) do
        local sel = BF.selectedBosses[row.Name]
        if sel then
            if row.Status == "SPAWNED" then
                -- UP: take control from farm, fight
                if sel ~= "hunting" or BF.activeBossHuntName ~= row.Name then
                    BF.startBossHuntCombat(row.Name)
                end
            elseif row.Status == "UNKNOWN" then
                -- ?: probe once (fly + try attack if found)
                if not BF.unknownProbeDone[row.Name] then
                    BF.unknownProbeDone[row.Name] = true
                    BF.startBossHuntCombat(row.Name)
                end
            elseif row.Status == "RESPAWNING" then
                -- DOWN / on CD: release fly to Auto Farm
                if BF.activeBossHuntName == row.Name then
                    BF.stopActiveBossHunt("on cooldown")
                end
                if sel == "hunting" then
                    BF.selectedBosses[row.Name] = true
                end
                -- allow a new probe next time it goes ?
                BF.unknownProbeDone[row.Name] = nil
            end
        elseif BF.activeBossHuntName == row.Name then
            BF.stopActiveBossHunt("deselected")
        end
    end
end

BF.ensureBossTimerGui = function()
    local pg = LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 5)
    if not pg then return end
    if BF.bossTimerGui and BF.bossTimerGui.Parent then return end
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
    BF.makeDraggable(title, frame)

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

    BF.bossTimerGui = sg
    BF.bossListFrame = scroll
    BF.bossTimerLabel = nil
end

BF.destroyBossTimerGui = function()
    if BF.bossTimerGui then
        pcall(function()
            BF.bossTimerGui:Destroy()
        end)
    end
    BF.bossTimerGui = nil
    BF.bossTimerLabel = nil
    BF.bossListFrame = nil
    BF.bossRowButtons = {}
end

BF.stopBossTimers = function()
    BF.bossTimerRunning = false
    BF.bossTimerTask = nil
    BF.stopActiveBossHunt("timers off")
    BF.destroyBossTimerGui()
end

BF.startBossTimers = function()
    if BF.bossTimerRunning then
        return
    end
    BF.bossTimerRunning = true
    BF.ensureBossTimerGui()
    BF.bossTimerTask = task.spawn(function()
        while BF.bossTimerRunning do
            local list, sea = {}, BF.getCurrentSea()
            local ok, pack = pcall(BF.scanBossesForSea)
            if ok and type(pack) == "table" then
                list = pack.List or {}
                sea = pack.Sea or BF.getCurrentSea()
            end
            pcall(BF.rebuildBossListRows, list)
            pcall(BF.processBossHuntActions, list)
            if config.bossSpawnNotify then
                for _, row in ipairs(list or {}) do
                    local prev = BF.lastBossStatus[row.Name]
                    if row.Status == "SPAWNED" and prev == "RESPAWNING" then
                        BF.notifyUser("Boss Spawned", row.Name .. " is UP!")
                    end
                    BF.lastBossStatus[row.Name] = row.Status
                end
            else
                for _, row in ipairs(list or {}) do
                    BF.lastBossStatus[row.Name] = row.Status
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
BF.seaProgressRunning = false
BF.sea1Stage, BF.sea2Stage = "idle", "idle"

BF._seaFly = function(pos)
    if not pos then return end
    pcall(function()
        if not BF.flying then BF.enableFly() end
        BF.setFlyTarget(pos + Vector3.new(0, 8, 0), false)
    end)
    task.wait(3)
end

BF._seaComm = function(...)
    local args = { ... }
    local r = ReplicatedStorage:FindFirstChild("Remotes")
    local f = r and r:FindFirstChild("CommF_")
    if f then
        pcall(function()
            f:InvokeServer(unpack(args))
        end)
    end
end

-- returns true if we saw the target alive and then it died / despawned
BF._seaFindAlive = function(nameSub)
    local en = workspace:FindFirstChild("Enemies")
    if not en then return nil end
    for _, m in ipairs(en:GetChildren()) do
        if string.find(string.lower(m.Name), string.lower(nameSub), 1, true) then
            local h = m:FindFirstChildOfClass("Humanoid")
            if h and h.Health > 0 then
                return m
            end
        end
    end
    return nil
end

BF._seaKill = function(nameSub, seconds)
    local t0 = os.clock()
    local sawAlive = false
    local confirmedDead = false
    while os.clock() - t0 < (seconds or 60) and BF.seaProgressRunning do
        local tgt = BF._seaFindAlive(nameSub)
        if tgt then
            sawAlive = true
            local root = tgt:FindFirstChild("HumanoidRootPart")
            if root then
                pcall(function()
                    if not BF.flying then BF.enableFly() end
                    BF.setFlyTarget(root.Position + Vector3.new(0, 10, 0), false)
                    BF.attackEnemy(tgt, config.bossAttackSpeed or 0.002, config.bossHitsPerCycle or 35)
                end)
            end
        elseif sawAlive then
            -- was alive, now gone -> killed
            confirmedDead = true
            break
        end
        task.wait(0.12)
    end
    -- final check
    if sawAlive and not BF._seaFindAlive(nameSub) then
        confirmedDead = true
    end
    return confirmedDead
end

BF.startSeaProgress = function()
    if BF.seaProgressRunning then return end
    BF.seaProgressRunning = true
    task.spawn(function()
        while BF.seaProgressRunning do
            local ok, err = pcall(function()
                if not config.autoSeaProgress then return end
                local level = BF.getPlayerLevel()
                local map = tostring(workspace:GetAttribute("MAP") or "")
                local sea = string.lower(map)

                -- ========== RECONCILE STAGE FROM WORLD ==========
                -- Never trust only BF.sea2Stage; fix mismatches every tick.
                local jeremyAlive = BF._seaFindAlive("Jeremy") ~= nil
                local donAlive = BF._seaFindAlive("Don Swan") ~= nil
                local indraAlive = (BF._seaFindAlive("indra") or BF._seaFindAlive("rip_indra") or BF._seaFindAlive("rip indra")) ~= nil
                local onSwanQuest = BF.activeQuestMatches("swan", "50") and BF.activeQuestMatches("pirate", "swan", "bartilo")
                -- softer swan quest detect
                if BF.activeQuestMatches("swan") and BF.activeQuestMatches("50") then
                    onSwanQuest = true
                elseif BF.activeQuestMatches("swan pirate") then
                    onSwanQuest = true
                end

                -- If we think we're past Jeremy but he's still alive -> force stage j
                if jeremyAlive and (BF.sea2Stage == "prisoners" or BF.sea2Stage == "don" or BF.sea2Stage == "king") then
                    BF.sea2Stage = "j"
                    BF.notifyUser("Sea", "Jeremy still alive -> back to stage j", 3)
                end
                -- If on swan quest text, force swan stage
                if onSwanQuest and BF.sea2Stage ~= "swan" and BF.sea2Stage ~= "idle" then
                    if BF.sea2Stage == "j" or BF.sea2Stage == "prisoners" then
                        -- allow if user already advanced; only force if clearly still stage1
                        if BF.activeQuestMatches("50") then
                            BF.sea2Stage = "swan"
                        end
                    end
                end

                local stageLabel = tostring(BF.sea2Stage)
                if jeremyAlive then stageLabel = stageLabel .. " | Jeremy ALIVE" end
                if donAlive then stageLabel = stageLabel .. " | Don ALIVE" end
                BF.notifyUser("Sea Stage", stageLabel .. " | " .. map .. " lv" .. tostring(level), 2)

                -- ========== SEA1 -> SEA2 ==========
                if level >= 700 and (sea == "" or sea == "sea1" or string.find(sea, "1"))
                    and not string.find(sea, "2") and not string.find(sea, "3")
                    and BF.sea1Stage ~= "done" then
                    if BF.sea1Stage == "idle" then
                        BF.notifyUser("Sea", "Sea1: Detective", 3)
                        BF._seaFly(Vector3.new(4850, 20, 750))
                        BF._seaComm("TalkDetective")
                        BF.sea1Stage = "ice"
                    elseif BF.sea1Stage == "ice" then
                        BF._seaFly(Vector3.new(-1166, 13, -2447))
                        BF._seaKill("Ice Admiral", 90)
                        BF.sea1Stage = "cap"
                    elseif BF.sea1Stage == "cap" then
                        BF._seaFly(Vector3.new(-285, 9, 5360))
                        BF._seaComm("TravelDressrosa")
                        BF._seaComm("TravelToSea2")
                        task.wait(2)
                        map = tostring(workspace:GetAttribute("MAP") or "")
                        if string.find(string.lower(map), "2") then
                            BF.sea1Stage = "done"
                            BF.notifyUser("Sea", "Sea 2!", 4)
                        end
                    end
                    return
                end

                -- ========== SEA2 -> SEA3 ==========
                if not (string.find(sea, "2") or sea == "") then
                    if string.find(sea, "3") then
                        BF.sea2Stage = "done"
                    end
                    return
                end
                if BF.sea2Stage == "done" then return end

                -- Stage machine (one action per tick, always fly to correct place first)
                if BF.sea2Stage == "idle" then
                    if BF.hasActiveQuest() and not BF.activeQuestMatches("swan", "bartilo", "50", "pirate") then
                        return
                    end
                    if not BF.activeQuestMatches("swan", "50") then
                        BF._seaComm("StartQuest", "BartiloQuest", 1)
                        task.wait(0.5)
                    end
                    BF.sea2Stage = "swan"
                    BF.notifyUser("Sea", "-> stage swan", 3)

                elseif BF.sea2Stage == "swan" then
                    BF._seaFly(Vector3.new(1019, 73, 1221))
                    if BF.activeQuestMatches("swan", "50", "pirate") or BF.activeQuestMatches("swan") then
                        BF._seaKill("Swan Pirate", 35)
                    else
                        -- quest cleared -> Jeremy
                        BF._seaComm("StartQuest", "BartiloQuest", 2)
                        task.wait(0.4)
                        BF.sea2Stage = "j"
                        BF.notifyUser("Sea", "-> stage j (Jeremy)", 3)
                    end

                elseif BF.sea2Stage == "j" then
                    -- MUST stay here until Jeremy confirmed dead
                    BF._seaFly(Vector3.new(2338, 451, 700))
                    if jeremyAlive then
                        local dead = BF._seaKill("Jeremy", 90)
                        if dead then
                            BF.sea2Stage = "prisoners"
                            BF.notifyUser("Sea", "Jeremy dead -> stage prisoners", 3)
                        else
                            BF.notifyUser("Sea", "Jeremy still fighting...", 2)
                        end
                    else
                        -- not on map: wait / hop, do NOT skip to don
                        BF.notifyUser("Sea", "Jeremy not in Enemies - waiting (stage j)", 2)
                        task.wait(3)
                        -- if still missing after a few ticks, optional skip only if level high and user wants
                        -- stay on j
                    end

                elseif BF.sea2Stage == "prisoners" then
                    -- Colosseum / free gladiators / King cell - STAY HERE, don't skip
                    local colPos = Vector3.new(-1836, 7, -2742)
                    BF.notifyUser("Sea", "Stage prisoners: BF.flying to Colosseum", 2)
                    BF._seaFly(colPos)
                    -- verify we moved roughly near colosseum
                    pcall(function()
                        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if hrp and (hrp.Position - colPos).Magnitude > 200 then
                            BF._seaFly(colPos)
                            task.wait(2)
                        end
                    end)
                    pcall(function()
                        if fireclickdetector then
                            for _, d in ipairs(workspace:GetDescendants()) do
                                if d:IsA("ClickDetector") then
                                    local p = d.Parent
                                    if p and p:IsA("BasePart") and (p.Position - colPos).Magnitude < 150 then
                                        fireclickdetector(d)
                                        task.wait(0.05)
                                    end
                                end
                            end
                        end
                    end)
                    BF._seaComm("StartQuest", "BartiloQuest", 3)
                    task.wait(4)
                    -- only leave prisoners when Jeremy is gone AND we've spent time at colosseum
                    if not jeremyAlive then
                        BF.sea2Stage = "don"
                        BF.notifyUser("Sea", "-> stage don (Don Swan)", 3)
                    end

                elseif BF.sea2Stage == "don" then
                    if jeremyAlive then
                        BF.sea2Stage = "j"
                        return
                    end
                    local donPos = Vector3.new(2289, 18, 663)
                    BF.notifyUser("Sea", "Stage don: Don Swan", 2)
                    BF._seaFly(donPos)
                    BF._seaComm("TalkTrevor")
                    BF._seaComm("Trevor")
                    if donAlive then
                        local dead = BF._seaKill("Don Swan", 120)
                        if dead then
                            BF.sea2Stage = "king"
                            BF.notifyUser("Sea", "Don Swan dead -> stage king", 3)
                        end
                    else
                        BF.notifyUser("Sea", "Don Swan not spawned (fruit door?)", 2)
                        if level >= 1500 then
                            -- allow try king if already killed before on this account
                            BF.sea2Stage = "king"
                        end
                    end

                elseif BF.sea2Stage == "king" then
                    local colPos = Vector3.new(-1836, 7, -2742)
                    BF.notifyUser("Sea", "Stage king: King Red Head", 2)
                    BF._seaFly(colPos)
                    BF._seaComm("KingRedHead")
                    BF._seaComm("TalkKingRedHead")
                    BF._seaComm("IndraRaid")
                    pcall(function()
                        if fireproximityprompt then
                            for _, d in ipairs(workspace:GetDescendants()) do
                                if d:IsA("ProximityPrompt") then
                                    local p = d.Parent
                                    local pos = nil
                                    if p and p:IsA("BasePart") then pos = p.Position
                                    elseif p and p:IsA("Model") then pos = p:GetPivot().Position end
                                    if pos and (pos - colPos).Magnitude < 80 then
                                        fireproximityprompt(d)
                                    end
                                end
                            end
                        end
                    end)
                    task.wait(3)
                    BF.sea2Stage = "indra"
                    BF.notifyUser("Sea", "-> stage indra", 3)

                elseif BF.sea2Stage == "indra" then
                    BF.notifyUser("Sea", "Stage indra: rip_indra", 2)
                    local indra = BF._seaFindAlive("indra") or BF._seaFindAlive("rip_indra") or BF._seaFindAlive("rip")
                    if indra then
                        local hum = indra:FindFirstChildOfClass("Humanoid")
                        local root = indra:FindFirstChild("HumanoidRootPart")
                        if root then
                            pcall(function()
                                if not BF.flying then BF.enableFly() end
                                BF.setFlyTarget(root.Position + Vector3.new(0, 12, 0), false)
                                BF.attackEnemy(indra, config.bossAttackSpeed or 0.002, config.bossHitsPerCycle or 40)
                            end)
                        end
                        if hum and hum.MaxHealth > 0 and (hum.Health / hum.MaxHealth) <= 0.55 then
                            BF.sea2Stage = "captain"
                            BF.notifyUser("Sea", "Indra ~50% -> captain", 3)
                        end
                    else
                        local deadish = BF._seaKill("indra", 40)
                        if deadish or not (BF._seaFindAlive("indra") or BF._seaFindAlive("rip")) then
                            BF.sea2Stage = "captain"
                            BF.notifyUser("Sea", "-> stage captain", 3)
                        end
                    end

                elseif BF.sea2Stage == "captain" then
                    BF.notifyUser("Sea", "Stage captain: Mr Captain", 2)
                    BF._seaFly(Vector3.new(-3350, 73, -1010))
                    BF._seaComm("TravelZou")
                    BF._seaComm("TravelToSea3")
                    BF._seaComm("MrCaptain")
                    task.wait(2)
                    map = tostring(workspace:GetAttribute("MAP") or "")
                    if string.find(string.lower(map), "3") then
                        BF.sea2Stage = "done"
                        BF.notifyUser("Sea", "Sea 3 unlocked!", 4)
                    end
                end
            end)
            if not ok then
                warn("[BF] seaProgress:", err)
            end
            task.wait(6)
        end
    end)
end

BF.stopSeaProgress = function()
    BF.seaProgressRunning = false
end



-- =============================================
-- AUTO RAID (Microchip / Awakening Raids)
-- Wiki: 5 islands, kill all enemies to progress, boss on island 5
-- Start: Mysterious Scientist chip -> lab tubes (Sea2 Hot&Cold / Sea3 Castle)
-- Remote: CommF_ "RaidsNpc","Select", <RaidName>
-- In-raid detect: PlayerGui.Main.TopHUDList.RaidTimer (or similar)
-- =============================================
BF.raidRunning = false
BF.raidTask = nil
BF.lastRaidChipAt = 0

local RAID_TYPES = {
    "Flame", "Ice", "Quake", "Light", "Dark", "Magma", "Sand",
    "Buddha", "Spider", "Rumble", "Phoenix", "Dough",
}

-- Lab / lobby approximate positions
local RAID_LAB_SEA2 = Vector3.new(-6520, 308, -4812) -- chip insert pad (user)
local RAID_LAB_SEA3 = Vector3.new(-5550, 314, -2980) -- Castle on the Sea (approx)

-- ========== RAID CORE (hub-style Locations + death/end handling) ==========
BF.getRaidLocations = function()
    local wo = workspace:FindFirstChild("_WorldOrigin")
    return wo and wo:FindFirstChild("Locations")
end

BF.raidTimerVisible = function()
    local ok, vis = pcall(function()
        local main = LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("Main")
        if not main then return false end
        local timer = main:FindFirstChild("Timer")
        if timer and timer:IsA("GuiObject") then
            return timer.Visible == true
        end
        return false
    end)
    return ok and vis == true
end

BF.isPlayerDead = function()
    local char = LocalPlayer.Character
    if not char then return true end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return true end
    return false
end

BF.isInRaid = function()
    -- Timer HUD OR any Island part under Locations
    if BF.raidTimerVisible() then return true end
    local locs = BF.getRaidLocations()
    if not locs then return false end
    for _, ch in ipairs(locs:GetChildren()) do
        local n = string.lower(ch.Name)
        if string.find(n, "island") then
            return true
        end
    end
    return false
end

BF.getPartCFrame = function(obj)
    if not obj then return nil end
    local cf = nil
    pcall(function()
        if obj:IsA("BasePart") then
            cf = obj.CFrame
        elseif obj:IsA("Model") then
            cf = obj:GetPivot()
        else
            local p = obj:FindFirstChildWhichIsA("BasePart", true)
            if p then cf = p.CFrame end
        end
    end)
    return cf
end

-- Prefer highest Island N; also accept "Island1" / loose names
BF.getActiveRaidIsland = function()
    local locs = BF.getRaidLocations()
    if not locs then return nil, 0, nil end

    for i = 5, 1, -1 do
        local island = locs:FindFirstChild("Island " .. i) or locs:FindFirstChild("Island" .. i)
        if island then
            local cf = BF.getPartCFrame(island)
            if cf then return island, i, cf end
        end
    end

    -- fallback: any child with Island in name, pick furthest from player or first
    local best, bestI, bestCf, bestScore = nil, 0, nil, -1
    for _, ch in ipairs(locs:GetChildren()) do
        local n = string.lower(ch.Name)
        if string.find(n, "island") then
            local cf = BF.getPartCFrame(ch)
            if cf then
                local num = tonumber(string.match(ch.Name, "%d+")) or 1
                if num >= bestScore then
                    best, bestI, bestCf, bestScore = ch, num, cf, num
                end
            end
        end
    end
    return best, bestI, bestCf
end

BF.getRaidEnemiesNear = function(pos, radius)
    local list = {}
    local en = workspace:FindFirstChild("Enemies")
    if not en then return list end
    radius = radius or 250
    for _, m in ipairs(en:GetChildren()) do
        local h = m:FindFirstChildOfClass("Humanoid")
        local r = m:FindFirstChild("HumanoidRootPart")
        if h and r and h.Health > 0 then
            if not pos or (r.Position - pos).Magnitude <= radius then
                table.insert(list, m)
            end
        end
    end
    return list
end

BF.getAllRaidEnemies = function()
    return BF.getRaidEnemiesNear(nil, 1e9)
end

BF.raidOrbitAngle = 0
BF.raidHoverY = 22
BF.raidDodgeAmp = 35 -- side-to-side dodge distance (not stuck mid-island)
BF.currentRaidIslandIndex = 0
BF.raidEndedAt = 0
local RAID_REENTRY_COOLDOWN = 8

-- Stay over the island, but STRAFE left/right (real dodge), not tiny circle in the center
BF.raidFlyToPos = function(pos)
    if not pos then return end
    pcall(function()
        BF._bossFlyUnlock = true
        if not BF.flying then BF.enableFly() end

        -- smooth left-right + slight forward/back (figure-8-ish)
        BF.raidOrbitAngle = BF.raidOrbitAngle + 0.07
        local ox = math.sin(BF.raidOrbitAngle) * BF.raidDodgeAmp
        local oz = math.sin(BF.raidOrbitAngle * 0.5) * (BF.raidDodgeAmp * 0.45)
        local target = Vector3.new(pos.X + ox, pos.Y + BF.raidHoverY, pos.Z + oz)
        BF.setFlyTarget(target, false)

        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local flat = Vector3.new(hrp.Position.X - target.X, 0, hrp.Position.Z - target.Z)
            if flat.Magnitude < 6 then
                local v = hrp.AssemblyLinearVelocity
                hrp.AssemblyLinearVelocity = Vector3.new(v.X * 0.35, v.Y * 0.5, v.Z * 0.35)
            elseif flat.Magnitude > 160 then
                hrp.AssemblyLinearVelocity = Vector3.zero
                BF.setFlyTarget(target, false)
            end
        end
        BF._bossFlyUnlock = false
    end)
end

BF.raidKillLoop = function()
    if BF.isPlayerDead() then
        return false
    end

    BF.ensureSimRadius()

    local island, idx, cf = BF.getActiveRaidIsland()
    local focusPos = cf and cf.Position or nil

    -- Fallback: no Locations parts -> use living enemies as focus (still progress raid)
    if not focusPos then
        local all = BF.getAllRaidEnemies()
        if #all > 0 then
            local sum = Vector3.zero
            for _, m in ipairs(all) do
                sum = sum + m.HumanoidRootPart.Position
            end
            focusPos = sum / #all
            if BF.currentRaidIslandIndex ~= -1 then
                BF.currentRaidIslandIndex = -1
                BF.notifyUser("Raid", "No Island parts - following enemies", 2)
            end
        end
    end

    if not focusPos then
        -- truly nothing: stay put briefly (island between spawns)
        return false
    end

    if idx > 0 and idx ~= BF.currentRaidIslandIndex then
        BF.currentRaidIslandIndex = idx
        BF.notifyUser("Raid", "Island " .. idx, 2)
    end

    BF.raidFlyToPos(focusPos)

    local aura = BF.getRaidEnemiesNear(focusPos, 250)
    if #aura == 0 then
        aura = BF.getAllRaidEnemies()
    end
    if #aura == 0 then
        return false
    end

    pcall(function()
        for i, m in ipairs(aura) do
            if i > 14 then break end
            local r = m:FindFirstChild("HumanoidRootPart")
            if r and focusPos then
                local d = (r.Position - focusPos).Magnitude
                if d > 20 and d < 200 then
                    local ang = (i - 1) * 0.55
                    r.CFrame = CFrame.new(focusPos + Vector3.new(math.cos(ang) * 6, 2, math.sin(ang) * 6))
                end
            end
        end
    end)

    pcall(function()
        BF.attackTargets(aura, config.raidAttackSpeed or 0.001, config.raidHitsPerCycle or 40)
    end)
    return true
end

BF.startAutoRaid = function()
    if BF.raidRunning then return end
    BF.raidRunning = true
    BF.raidEndedAt = 0
    BF.currentRaidIslandIndex = 0
    BF.notifyUser("Raid", "Auto Raid ON (" .. tostring(config.raidType) .. ")", 3)
    BF.raidTask = task.spawn(function()
        while BF.raidRunning do
            local ok, err = pcall(function()
                if not config.autoRaid then return end

                -- DEAD: wait for respawn, do not fly to old raid
                if BF.isPlayerDead() then
                    BF.notifyUser("Raid", "Dead - waiting respawn", 2)
                    task.wait(1)
                    return
                end

                if BF.isInRaid() then
                    BF.raidEndedAt = 0
                    local fighting = BF.raidKillLoop()
                    if not fighting then
                        task.wait(0.8)
                    end
                    return
                end

                -- Raid ended (timer gone, no islands)
                BF.currentRaidIslandIndex = 0
                if BF.raidEndedAt == 0 then
                    BF.raidEndedAt = os.clock()
                    BF.notifyUser("Raid", "Raid ended - cooldown then new chip", 3)
                end
                -- short cooldown so we don't path back into a finishing raid
                if os.clock() - BF.raidEndedAt < RAID_REENTRY_COOLDOWN then
                    task.wait(0.5)
                    return
                end

                if BF.getPlayerLevel() < 1100 then
                    BF.notifyUser("Raid", "Need level 1100+", 3)
                    task.wait(10)
                    return
                end

                selectRaidType(config.raidType)
                if not hasMicrochip() then
                    buyRaidChip()
                    if not hasMicrochip() then
                        BF.notifyUser("Raid", "No Microchip - lobby / CD", 3)
                        goToRaidLobby()
                        task.wait(4)
                        return
                    end
                end

                BF.notifyUser("Raid", "Lobby -> start", 2)
                goToRaidLobby()
                tryStartRaid()
                task.wait(2.5)
            end)
            if not ok then
                warn("[BF] autoRaid:", err)
            end
            task.wait(0.35)
        end
    end)
end

BF.stopAutoRaid = function()
    BF.raidRunning = false
    config.autoRaid = false
    BF.notifyUser("Raid", "Auto Raid OFF", 2)
end


BF.farmRunning = false
BF.farmTask = nil
BF.lastIslandName = ""
BF.respawnConnection = nil
BF.equipCheckConnection = nil

BF.setupRespawnRecovery = function()
    if BF.respawnConnection then BF.respawnConnection:Disconnect() end
    BF.respawnConnection = LocalPlayer.CharacterAdded:Connect(function(character)
        if not BF.farmRunning then return end
        local humanoid = character:WaitForChild("Humanoid", 10)
        local hrp = character:WaitForChild("HumanoidRootPart", 10)
        if humanoid and hrp and BF.farmRunning then
            task.wait(0.5)
            if BF.flying then BF.disableFly() end
            BF.enableFly()
        end
    end)
end

BF.startFarm = function()
    if BF.farmRunning then return end
    BF.farmRunning = true
    BF.setupRespawnRecovery()
    BF.enableFly()
    if config.fruitNotifier then BF.startFruitNotifier() end

    if config.autoEquip then
        BF.equipCheckConnection = RunService.Heartbeat:Connect(function()
            if BF.farmRunning then BF.autoEquipWeapon() end
        end)
    end

    BF.farmTask = task.spawn(function()
        local state = "ISLAND"
        local questAccepted = false
        local currentLevel = BF.getPlayerLevel()
        local lockedEnemy = nil
        local heightLocked = false
        local lockedY = 0
        local currentQuestType = "normal"
        local lastLevelForStats = currentLevel
        local isBossTarget = false
        local underwaterEntryDone = false
        local underwaterEntryStarted = false

        while BF.farmRunning do
            -- Boss hunt (UP/?) fully owns movement + combat; farm waits
            if BF.bossHuntOwnsFly and type(BF.bossHuntOwnsFly) == "function" and BF.bossHuntOwnsFly() then
                task.wait(0.2)
                continue
            end
            local character = LocalPlayer.Character
            if not character then task.wait(0.5) continue end
            local humanoid = character:FindFirstChild("Humanoid")
            if not humanoid or humanoid.Health <= 0 then task.wait(0.5) continue end
            if not BF.flying then BF.enableFly() end
            if config.autoHeal then BF.heal() end
            local characters = workspace:FindFirstChild("Characters")
            local localCharacter = characters and characters:FindFirstChild(LocalPlayer.Name)
            local busoHumanoid = localCharacter and localCharacter:FindFirstChild("Humanoid")
            if busoHumanoid and not busoHumanoid:FindFirstChild("LeftHand_BusoLayer1") then
                local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                local commF = remotes and remotes:FindFirstChild("CommF_")
                if commF then pcall(function() commF:InvokeServer("Buso") end) end
            end

            local level = BF.getPlayerLevel()
            local island = BF.resolveFarmIsland(level)
            local hrp = character:FindFirstChild("HumanoidRootPart")

            -- Level 700-725: make sure the normal Raider pattern is selected.
            -- This is deliberately scoped to the user's existing "Season 2, 1"
            -- entry and does not alter other level ranges.
            if island and island.Name == "Season 2, 1" then
                island.EnemyPatterns = {"Raider"}
                island.isBoss = false
            end
            if not hrp then task.wait(0.5) continue end

            -- Stats: always dump available points (not only on level-up)
            if config.statEnabled then
                local pts = BF.getAvailableStatPoints()
                if pts and pts > 0 then
                    pcall(function()
                        BF.distributeStats(config.statsToAdd, config.pointsPerStat, true)
                    end)
                end
            end


            -- QUEST: TrackedQuestFrame exists = has quest (never StartQuest)
            --        missing = no quest -> accept once (cooldown)
            do
                if not _lastQuestAcceptAt then _lastQuestAcceptAt = 0 end
                if BF.hasActiveQuest() then
                    questAccepted = true
                else
                    -- frame gone = finished or none -> may take new quest
                    if (os.clock() - _lastQuestAcceptAt) >= 3 then
                        questAccepted = false
                        if state == "COMBAT" or state == "PATROL" then
                            state = "QUEST"
                        end
                    end
                end
            end

            if level ~= currentLevel then
                currentLevel = level
                lastLevelForStats = level
                -- Keep fighting current quest mobs until TrackedQuestFrame is gone
                if not BF.hasActiveQuest() then
                    lockedEnemy = nil
                    heightLocked = false
                    isBossTarget = false
                    underwaterEntryDone = false
                    underwaterEntryStarted = false
                    questAccepted = false
                    currentQuestType = "normal"
                    state = "ISLAND"
                    if island.Name ~= BF.lastIslandName then
                        BF.lastIslandName = island.Name
                        BF.notifyUser("New Island", "Now farming: " .. island.Name)
                    end
                else
                    -- level-up mid-quest: stay on quest island/mobs, keep attacking
                    BF.notifyUser("Level Up", "Finishing current quest first", 3)
                end
            end

            if state == "ISLAND" then
                local underwater = BF.isUnderwaterIsland(island)

                -- Underwater route: deliberately visit the whirlpool first rather
                -- than BF.flying directly across the ocean to the island coordinates.
                if underwater and not underwaterEntryDone then
                    local whirlpool = BF.findWhirlpool()
                    if whirlpool then
                        underwaterEntryStarted = true
                        if whirlpool.Distance > 65 then
                            BF.setFlyTarget(whirlpool.Position + Vector3.new(0, 6, 0), false)
                            task.wait(0.08)
                            continue
                        end

                        -- Stay over the whirlpool briefly so its entrance/teleport
                        -- trigger has time to fire. Do not fly away immediately.
                        BF.setFlyTarget(whirlpool.Position + Vector3.new(0, 4, 0), false)
                        task.wait(0.6)
                        underwaterEntryDone = true
                        BF.setHoverHeight(hrp.Position.Y)
                        continue
                    else
                        -- If the server has no named whirlpool object, fall back to
                        -- the known island position instead of getting stuck forever.
                        underwaterEntryDone = true
                    end
                end

                local targetPos = island.Pos + Vector3.new(0, 25, 0)
                if (hrp.Position - targetPos).Magnitude > 50 then
                    BF.setFlyTarget(targetPos, false)
                    task.wait(0.08)
                    continue
                else
                    BF.setHoverHeight(hrp.Position.Y)
                    state = "QUEST"
                    continue
                end
            end

            if state == "QUEST" then
                -- TrackedQuestFrame present = already have quest
                if BF.hasActiveQuest() then
                    questAccepted = true
                    state = "COMBAT"
                    continue
                end
                if not _lastQuestAcceptAt then _lastQuestAcceptAt = 0 end
                if (os.clock() - _lastQuestAcceptAt) < 3 then
                    state = "COMBAT"
                    continue
                end

                local bossEnemy = nil
                if island.isBoss then bossEnemy = BF.findBossInWorkspace(island) end
                local desiredType = bossEnemy and "boss" or "normal"
                local questArgs = BF.getQuestArgs(island, desiredType)

                if questArgs then
                    _lastQuestAcceptAt = os.clock()
                    local success = BF.acceptQuestWrapper(questArgs)
                    if success then
                        currentQuestType = desiredType
                        questAccepted = true
                        state = "COMBAT"
                        task.wait(0.8)
                    else
                        task.wait(1.5)
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
                -- Never interrupt an accepted quest. Farm always.
                -- New quest only via the 10s-hidden tracker above -> state QUEST.

                local bossEnemy = nil
                if island.isBoss then bossEnemy = BF.findBossInWorkspace(island) end
                -- no AbandonQuest mid-run

                if bossEnemy and bossEnemy.Parent and bossEnemy:FindFirstChildOfClass("Humanoid")
                    and bossEnemy:FindFirstChildOfClass("Humanoid").Health > 0 then
                    lockedEnemy = bossEnemy
                    isBossTarget = true
                else
                    isBossTarget = false
                    local patternInfo = BF.resolveFarmPatterns(island, currentQuestType)
                    local allTargets = BF.getMatchingEnemies(island, patternInfo)
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
                            BF.setFlyTarget(targetPos + Vector3.new(0, hover, 0), false)
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
                                    BF.setFlyTarget(targetPos + Vector3.new(0, hover, 0), false)
                                    heightLocked = false

                                    local patternInfo = BF.resolveFarmPatterns(island, currentQuestType)
                                    local allTargets = BF.getMatchingEnemies(island, patternInfo)
                                    local maxN = config.maxClusterSize or 15
                                    -- Pull range (large) vs attack range (small) were mixed before
                                    local radius = config.clusterRange or 150
                                    if radius < 80 then radius = 80 end

                                    local clusterTargets = BF.collectNearbyTargets(
                                        allTargets,
                                        playerRoot,
                                        lockedEnemy,
                                        maxN,
                                        radius
                                    )

                                    if #clusterTargets > 0 then
                                        -- stand above the fixed stack (not a moving flyer underpoint)
                                        if BF.clusterStackPos then
                                            local hover = math.clamp(config.aboveHeight or 8, 4, 12)
                                            BF.setFlyTarget(BF.clusterStackPos + Vector3.new(0, hover, 0), false)
                                        end
                                        BF.attackTargets(clusterTargets, speed, hits)
                                    else
                                        BF.attackEnemy(lockedEnemy, speed, hits)
                                    end
                                else
                                    BF.attackEnemy(lockedEnemy, speed, hits)
                                end
                            else
                                -- single target: also keep height moderate for valid hits
                                local hover = math.clamp(config.aboveHeight or 8, 4, 14)
                                BF.setFlyTarget(targetPos + Vector3.new(0, hover, 0), false)
                                BF.attackEnemy(lockedEnemy, speed, hits)
                            end
                        end
                    else
                        lockedEnemy = nil
                        BF.clusterStackPos = nil
                    end
                else
                    lockedEnemy = nil
                    BF.clusterStackPos = nil
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
                    BF.setFlyTarget(Vector3.new(hrp.Position.X, lockedY, hrp.Position.Z), false)
                else
                    if not BF.hoverY then BF.hoverY = hrp.Position.Y end
                    BF.setFlyTarget(Vector3.new(hrp.Position.X, BF.hoverY, hrp.Position.Z), false)
                end

                local bossEnemy = nil
                if island.isBoss then bossEnemy = BF.findBossInWorkspace(island) end
                if bossEnemy then
                    lockedEnemy = bossEnemy
                    isBossTarget = true
                    state = "COMBAT"
                else
                    local patternInfo = BF.resolveFarmPatterns(island, currentQuestType)
                    local enemies = BF.getMatchingEnemies(island, patternInfo)
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

        if BF.equipCheckConnection then
            BF.equipCheckConnection:Disconnect()
            BF.equipCheckConnection = nil
        end
        if BF.fruitNotifierRunning then BF.stopFruitNotifier() end
        BF.disableFly()
    end)
end

BF.stopFarm = function()
    BF.farmRunning = false
    if BF.farmTask then task.cancel(BF.farmTask) BF.farmTask = nil end
    if BF.respawnConnection then BF.respawnConnection:Disconnect() end
    if BF.equipCheckConnection then BF.equipCheckConnection:Disconnect() BF.equipCheckConnection = nil end
    if BF.fruitNotifierRunning then BF.stopFruitNotifier() end
    BF.fruitTarget = nil
    BF.disableFly()
    BF.notifyUser("Stopped", "Farm stopped.")
end



-- =============================================
-- AUTO RANDOM FRUIT (Zioles Gacha)
-- Classic: CommF_ "Cousin","BuyItem"
-- New: Modules.Net RF/GachaNetworkRF ZiolesGacha
-- Cooldown ~2 hours, Level 50+
-- =============================================
BF.randomFruitRunning = false
BF.randomFruitTask = nil
BF._lastRandomFruitAt = 0

BF.getGachaRemote = function()
    local modules = ReplicatedStorage:FindFirstChild("Modules")
    local net = modules and modules:FindFirstChild("Net")
    if not net then return nil end
    return net:FindFirstChild("RF/GachaNetworkRF") or net:FindFirstChild("GachaNetworkRF")
end

BF.buyRandomFruitOnce = function()
    local lvl = BF.getPlayerLevel()
    if lvl < 50 then
        BF.notifyUser("Gacha", "Need level 50+", 3)
        return false, "level"
    end
    if (os.clock() - (BF._lastRandomFruitAt or 0)) < 2 then
        return false, "throttle"
    end

    local gacha = BF.getGachaRemote()
    if not gacha then
        BF.notifyUser("Gacha", "GachaNetworkRF not found", 4)
        return false, "no remote"
    end

    -- Check status first (cooldown / money / level)
    local okC, check = pcall(function()
        return gacha:InvokeServer({
            BoxName = "ZiolesGacha",
            Context = "Check",
            SpokeNPC = "Blox Fruit Gacha",
        })
    end)
    if okC and type(check) == "table" then
        local cd = check.Cooldown
        if cd and cd.RequirementMet == false then
            local left = ""
            if type(cd.TimeEnds) == "number" then
                local sec = math.max(0, math.floor(cd.TimeEnds - os.time()))
                local m = math.floor(sec / 60)
                local s = sec % 60
                left = string.format(" (%d:%02d)", m, s)
            end
            local msg = tostring(cd.ErrorMessage or check.ErrorMessage or "On cooldown")
            BF.notifyUser("Gacha", msg .. left, 5)
            print("[BF] Gacha CD:", msg, left)
            return false, "cooldown"
        end
        if check.RequirementsMet == false and check.ErrorMessage then
            -- still try Purchase if only soft fail; but show reason
            print("[BF] Gacha RequirementsMet=false:", check.ErrorMessage)
        end
        if check.Price then
            print("[BF] Gacha price", check.Price.Value, "money", check.Price.Current, "ok", check.Price.RequirementMet)
        end
    end

    -- Working path (from live log): Context = "Purchase" -> true
    local ok, ret = pcall(function()
        return gacha:InvokeServer({
            BoxName = "ZiolesGacha",
            Context = "Purchase",
            SpokeNPC = "Blox Fruit Gacha",
        })
    end)
    BF._lastRandomFruitAt = os.clock()
    print("[BF] Gacha Purchase:", ok, ret)

    if ok and ret == true then
        BF.notifyUser("Gacha", "Roll success! Check inventory", 5)
        return true, ret
    elseif ok and ret == false then
        BF.notifyUser("Gacha", "Purchase denied (CD / money / region)", 5)
        return false, ret
    elseif ok then
        BF.notifyUser("Gacha", "Purchase sent: " .. tostring(ret), 4)
        return true, ret
    else
        BF.notifyUser("Gacha", "Purchase error: " .. tostring(ret), 5)
        return false, ret
    end
end

BF.startAutoRandomFruit = function()
    if BF.randomFruitRunning then return end
    BF.randomFruitRunning = true
    BF.notifyUser("Gacha", "Auto Random Fruit ON", 3)
    BF.randomFruitTask = task.spawn(function()
        while BF.randomFruitRunning do
            if config.autoRandomFruit then
                pcall(BF.buyRandomFruitOnce)
            end
            -- check every 5 min (server CD is 2h)
            task.wait(300)
        end
    end)
end

BF.stopAutoRandomFruit = function()
    BF.randomFruitRunning = false
    if BF.randomFruitTask then pcall(function() task.cancel(BF.randomFruitTask) end) BF.randomFruitTask = nil end
    BF.notifyUser("Gacha", "Auto Random Fruit OFF", 2)
end

-- =============================================
-- SEA1 ISLAND SECRETS (Update 30) - partial auto
-- Pirate Village: Free the Windmill = cut 5 ropes with sword
-- More secrets: toggle flies you to island; full puzzles still partial
-- =============================================
BF.secretsRunning = false
BF.secretsTask = nil

BF.findRopeLikeParts = function(nearPos, radius)
    local found = {}
    radius = radius or 120
    for _, d in ipairs(workspace:GetDescendants()) do
        if d:IsA("BasePart") then
            local n = string.lower(d.Name)
            if string.find(n, "rope") or string.find(n, "rigging") or string.find(n, "cord")
                or string.find(n, "line") or string.find(n, "cable") then
                if nearPos and (d.Position - nearPos).Magnitude <= radius then
                    table.insert(found, d)
                end
            end
        end
    end
    return found
end

BF.tryCutWindmillRopes = function()
    -- Pirate Village windmill center ~ dock/village
    local windmillPos = Vector3.new(-1140, 55, 3975)
    pcall(function()
        if not BF.flying then BF.enableFly() end
        BF.setFlyTarget(windmillPos, false)
    end)
    task.wait(2)
    local ropes = BF.findRopeLikeParts(windmillPos, 150)
    if #ropes == 0 then
        -- broader search on island
        ropes = BF.findRopeLikeParts(windmillPos, 250)
    end
    BF.notifyUser("Secrets", "Windmill ropes found: " .. tostring(#ropes), 3)
    for _, rope in ipairs(ropes) do
        pcall(function()
            if not BF.flying then BF.enableFly() end
            BF.setFlyTarget(rope.Position + Vector3.new(0, 3, 0), false)
            task.wait(0.35)
            -- equip sword and M1 / hit
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                local bp = LocalPlayer:FindFirstChild("Backpack")
                if hum and bp then
                    for _, t in ipairs(bp:GetChildren()) do
                        if t:IsA("Tool") and (t.ToolTip == "Sword" or string.find(string.lower(t.Name), "sword")) then
                            hum:EquipTool(t)
                            break
                        end
                    end
                end
            end
            BF.fireVirtualClick()
            -- also tool activate
            pcall(function()
                local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
                if tool then tool:Activate() end
            end)
            -- click detectors on rope
            if fireclickdetector then
                local cd = rope:FindFirstChildOfClass("ClickDetector") or rope.Parent and rope.Parent:FindFirstChildOfClass("ClickDetector")
                if cd then fireclickdetector(cd) end
            end
            task.wait(0.25)
        end)
    end
end

BF.startAutoSecrets = function()
    if BF.secretsRunning then return end
    BF.secretsRunning = true
    BF.notifyUser("Secrets", "Auto Secrets ON (Windmill first)", 3)
    BF.secretsTask = task.spawn(function()
        while BF.secretsRunning do
            local ok, err = pcall(function()
                if not config.autoSecrets then return end
                BF.tryCutWindmillRopes()
                task.wait(8)
            end)
            if not ok then warn("[BF] secrets:", err) end
            task.wait(1)
        end
    end)
end

BF.stopAutoSecrets = function()
    BF.secretsRunning = false
    if BF.secretsTask then pcall(function() task.cancel(BF.secretsTask) end) BF.secretsTask = nil end
    BF.notifyUser("Secrets", "Auto Secrets OFF", 2)
end



-- =============================================
-- ENEMY ESP (through walls) - Highlight + name/HP
-- =============================================
BF.enemyEspRunning = false
BF.enemyEspTask = nil
BF.enemyEspObjects = {} -- [model] = {hl=, bb=, nameLbl=, hpLbl=}

BF.clearEnemyEsp = function()
    for model, data in pairs(BF.enemyEspObjects) do
        pcall(function()
            if data.hl then data.hl:Destroy() end
            if data.bb then data.bb:Destroy() end
        end)
        BF.enemyEspObjects[model] = nil
    end
end

BF.isBossModel = function(model)
    if not model then return false end
    if model:GetAttribute("isBoss") == true then return true end
    local n = string.lower(model.Name)
    if string.find(n, "boss", 1, true) then return true end
    return false
end

BF.ensureEnemyEsp = function(model)
    if BF.enemyEspObjects[model] then return BF.enemyEspObjects[model] end
    local data = {}
    pcall(function()
        local hl = Instance.new("Highlight")
        hl.Name = "BF_EnemyESP"
        hl.Enabled = true
        pcall(function()
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        end)
        hl.FillTransparency = 0.5
        hl.OutlineTransparency = 0
        if BF.isBossModel(model) then
            hl.FillColor = Color3.fromRGB(255, 60, 60)
            hl.OutlineColor = Color3.fromRGB(255, 200, 50)
        else
            hl.FillColor = Color3.fromRGB(80, 180, 255)
            hl.OutlineColor = Color3.fromRGB(255, 255, 255)
        end
        hl.Adornee = model
        -- Parent to PlayerGui folder so it survives enemy streaming better
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        local folder = pg and pg:FindFirstChild("BF_ESP_FOLDER")
        if not folder and pg then
            folder = Instance.new("Folder")
            folder.Name = "BF_ESP_FOLDER"
            folder.Parent = pg
        end
        hl.Parent = folder or model
        data.hl = hl
    end)
    pcall(function()
        local root = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Head")
        if not root then return end
        local bb = Instance.new("BillboardGui")
        bb.Name = "BF_EnemyESP_BB"
        bb.AlwaysOnTop = true
        bb.Size = UDim2.new(0, 160, 0, 40)
        bb.StudsOffset = Vector3.new(0, 3.2, 0)
        bb.MaxDistance = config.enemyEspMaxDist or 2000
        bb.Adornee = root
        bb.Parent = root

        local nameLbl = Instance.new("TextLabel")
        nameLbl.BackgroundTransparency = 1
        nameLbl.Size = UDim2.new(1, 0, 0.5, 0)
        nameLbl.Font = Enum.Font.GothamBold
        nameLbl.TextSize = 14
        nameLbl.TextColor3 = Color3.new(1, 1, 1)
        nameLbl.TextStrokeTransparency = 0.4
        nameLbl.Text = model.Name
        nameLbl.Parent = bb

        local hpLbl = Instance.new("TextLabel")
        hpLbl.BackgroundTransparency = 1
        hpLbl.Position = UDim2.new(0, 0, 0.5, 0)
        hpLbl.Size = UDim2.new(1, 0, 0.5, 0)
        hpLbl.Font = Enum.Font.Gotham
        hpLbl.TextSize = 12
        hpLbl.TextColor3 = Color3.fromRGB(120, 255, 120)
        hpLbl.TextStrokeTransparency = 0.4
        hpLbl.Text = ""
        hpLbl.Parent = bb

        data.bb = bb
        data.nameLbl = nameLbl
        data.hpLbl = hpLbl
    end)
    BF.enemyEspObjects[model] = data
    return data
end

BF.updateEnemyEsp = function()
    if not config.enemyEspEnabled then
        BF.clearEnemyEsp()
        return
    end
    local folder = Workspace:FindFirstChild("Enemies")
    if not folder then return end
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local maxD = config.enemyEspMaxDist or 2000
    local seen = {}

    for _, model in ipairs(folder:GetChildren()) do
        if model:IsA("Model") then
            local hum = model:FindFirstChildOfClass("Humanoid")
            local root = model:FindFirstChild("HumanoidRootPart")
            if hum and root and hum.Health > 0 then
                local dist = hrp and (root.Position - hrp.Position).Magnitude or 0
                if not hrp or dist <= maxD then
                    seen[model] = true
                    local data = BF.ensureEnemyEsp(model)
                    if data then
                        if data.nameLbl then
                            data.nameLbl.Visible = config.enemyEspShowName ~= false
                            data.nameLbl.Text = model.Name
                        end
                        if data.hpLbl then
                            data.hpLbl.Visible = config.enemyEspShowHealth ~= false
                            local maxH = math.max(hum.MaxHealth, 1)
                            data.hpLbl.Text = string.format("%d / %d", math.floor(hum.Health), math.floor(maxH))
                        end
                        if data.hl and BF.isBossModel(model) and config.enemyEspBossColor ~= false then
                            data.hl.FillColor = Color3.fromRGB(255, 60, 60)
                            data.hl.OutlineColor = Color3.fromRGB(255, 200, 50)
                        end
                    end
                end
            end
        end
    end

    for model, data in pairs(BF.enemyEspObjects) do
        if not seen[model] or not model.Parent then
            pcall(function()
                if data.hl then data.hl:Destroy() end
                if data.bb then data.bb:Destroy() end
            end)
            BF.enemyEspObjects[model] = nil
        end
    end
end

BF.startEnemyEsp = function()
    if BF.enemyEspRunning then return end
    BF.enemyEspRunning = true
    config.enemyEspEnabled = true
    BF.enemyEspTask = task.spawn(function()
        while BF.enemyEspRunning do
            pcall(BF.updateEnemyEsp)
            task.wait(0.35)
        end
        BF.clearEnemyEsp()
    end)
    BF.notifyUser("ESP", "Enemy ESP ON (through walls)", 2)
end

BF.stopEnemyEsp = function()
    BF.enemyEspRunning = false
    config.enemyEspEnabled = false
    if BF.enemyEspTask then pcall(function() task.cancel(BF.enemyEspTask) end) BF.enemyEspTask = nil end
    BF.clearEnemyEsp()
    BF.notifyUser("ESP", "Enemy ESP OFF", 2)
end

-- =============================================
-- VAXORIN UI CREATION (if successful)
-- =============================================

-- =============================================
-- FPS BOOSTER + ISLAND FLY
-- =============================================
BF.fpsBoostOn = false

BF.applyFpsBoost = function(on)
    BF.fpsBoostOn = on and true or false
    pcall(function()
        local lighting = game:GetService("Lighting")
        if BF.fpsBoostOn then
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
            pcall(function()
                UserSettings():GetService("UserGameSettings").SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1
            end)
            lighting.GlobalShadows = false
            lighting.FogEnd = 9e9
            lighting.Brightness = 1
            pcall(function()
                workspace.Terrain.WaterWaveSize = 0
                workspace.Terrain.WaterWaveSpeed = 0
                workspace.Terrain.WaterReflectance = 0
                workspace.Terrain.WaterTransparency = 1
            end)
            pcall(function()
                for _, v in ipairs(workspace:GetDescendants()) do
                    if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") then
                        v.Enabled = false
                    elseif v:IsA("Explosion") then
                        v:Destroy()
                    end
                end
            end)
            BF.notifyUser("FPS", "Boost ON", 2)
        else
            settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
            lighting.GlobalShadows = true
            BF.notifyUser("FPS", "Boost OFF", 2)
        end
    end)
end

BF.getIslandTeleportList = function()
    local list = {}
    local seen = {}
    for _, isl in ipairs(islands) do
        if isl.Pos and not seen[isl.Name] then
            seen[isl.Name] = true
            table.insert(list, { Name = isl.Name, Pos = isl.Pos })
        end
    end
    pcall(function()
        local locs = workspace:FindFirstChild("_WorldOrigin") and workspace._WorldOrigin:FindFirstChild("Locations")
        if not locs then return end
        for _, loc in ipairs(locs:GetChildren()) do
            if loc:IsA("BasePart") and not seen[loc.Name] then
                seen[loc.Name] = true
                table.insert(list, { Name = loc.Name, Pos = loc.Position })
            elseif loc:IsA("Model") and not seen[loc.Name] then
                local p = loc:FindFirstChildWhichIsA("BasePart")
                if p then
                    seen[loc.Name] = true
                    table.insert(list, { Name = loc.Name, Pos = p.Position })
                end
            end
        end
    end)
    table.sort(list, function(a, b) return a.Name < b.Name end)
    return list
end

BF.flyToIslandByName = function(name)
    if not name or name == "" then return end
    local list = BF.getIslandTeleportList()
    local target = nil
    for _, e in ipairs(list) do
        if e.Name == name then target = e break end
    end
    if not target then
        for _, e in ipairs(list) do
            if string.find(string.lower(e.Name), string.lower(name), 1, true) then
                target = e
                break
            end
        end
    end
    if not target then
        BF.notifyUser("Island", "Not found: " .. tostring(name), 3)
        return
    end
    pcall(function()
        if not BF.flying then BF.enableFly() end
        BF.setFlyTarget(target.Pos + Vector3.new(0, 25, 0), false)
    end)
    BF.notifyUser("Island", "Flying to " .. target.Name, 3)
end


if useVaxorin and window then
    local mainTab = window:CreateTab("Farm")

    local miscTab = window:CreateTab("Misc")
    local fpsSection = miscTab:CreateSection({Name = "Performance"})
    fpsSection:CreateToggle({
        Name = "FPS Booster",
        CurrentValue = false,
        Flag = "Misc.FPS",
        Save = true,
        Callback = function(v) BF.applyFpsBoost(v) end,
    })

    local islandSection = miscTab:CreateSection({Name = "Fly to Island"})
    local islandNames = {}
    pcall(function()
        for _, e in ipairs(BF.getIslandTeleportList()) do
            table.insert(islandNames, e.Name)
        end
    end)
    if #islandNames == 0 then islandNames = {"Jungle (Normal)", "Pirate Village", "Desert 1"} end
    islandSection:CreateDropdown({
        Name = "Island",
        Options = islandNames,
        CurrentOption = islandNames[1],
        Flag = "Misc.IslandSelect",
        Save = false,
        Callback = function(v)
            -- dropdown may pass string or table
            local name = v
            if type(v) == "table" then name = v[1] or v.Name or tostring(v) end
            BF._selectedIslandFly = tostring(name)
        end,
    })
    islandSection:CreateButton({
        Name = "Fly to Selected Island",
        Callback = function()
            BF.flyToIslandByName(BF._selectedIslandFly or islandNames[1])
        end,
    })

    local espTab = window:CreateTab("ESP")
    local MoneyTab = window:CreateTab("Auto Money")
    local combatTab = window:CreateTab("Combat")
    local fruitTab = window:CreateTab("Fruits")

    local raidTab = window:CreateTab("Raid")
    local raidSection = raidTab:CreateSection({Name = "Auto Raid (Microchip)"})
    raidSection:CreateToggle({
        Name = "Auto Raid",
        CurrentValue = false,
        Flag = "Raid.Enabled", Save = true,
        Callback = function(v)
            config.autoRaid = v
            if v then BF.startAutoRaid() else BF.stopAutoRaid() end
        end,
    })
    raidSection:CreateDropdown({
        Name = "Raid Type",
        Options = {"Flame", "Ice", "Quake", "Light", "Dark", "Magma", "Sand", "Buddha", "Spider", "Rumble", "Phoenix", "Dough"},
        CurrentOption = config.raidType or "Flame",
        Flag = "Raid.Type", Save = true,
        Callback = function(v)
            if type(v) == "table" then v = v[1] end
            config.raidType = tostring(v or "Flame")
            selectRaidType(config.raidType)
        end,
    })
    raidSection:CreateToggle({
        Name = "Auto Buy Chip",
        CurrentValue = true,
        Flag = "Raid.AutoBuy", Save = true,
        Callback = function(v) config.raidAutoBuyChip = v end,
    })
    raidSection:CreateParagraph({
        Title = "How it works",
        Content = "Lv 1100+ | Sea2/3. Selects raid, buys Special Microchip when possible, flies to lab, starts raid, kills all enemies on each of the 5 islands. Flame = easiest. Phoenix/Dough need advanced chip.",
    })

    local bossTab = window:CreateTab("Bosses")

    local mainSection = mainTab:CreateSection({Name = "Farm Controls"})
    mainSection:CreateToggle({
        Name = "Auto Farm",
        CurrentValue = false,
        Flag = "Farm.Enabled", Save = true,
        Callback = function(v)
            if v then BF.startFarm() else BF.stopFarm() end
        end,
    })
    mainSection:CreateToggle({
        Name = "Auto Secrets (Sea1)",
        CurrentValue = false,
        Flag = "Farm.AutoSecrets", Save = true,
        Callback = function(v)
            config.autoSecrets = v
            if v then BF.startAutoSecrets() else BF.stopAutoSecrets() end
        end,
    })

    mainSection:CreateToggle({
        Name = "Auto Sea Progress (1->2 / 2->3)",
        CurrentValue = false,
        Flag = "Farm.AutoSeaProgress", Save = true,
        Callback = function(v)
            config.autoSeaProgress = v
            if v then BF.startSeaProgress() else BF.stopSeaProgress() end
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
            BF.stopFarm()
            BF.notifyUser("Stopped", "Landed.")
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

    local enemyEspSection = espTab:CreateSection({Name = "Enemy ESP (Walls)"})
    enemyEspSection:CreateToggle({
        Name = "Enemy ESP",
        CurrentValue = false,
        Flag = "ESP.Enemy",
        Save = true,
        Callback = function(v)
            if v then BF.startEnemyEsp() else BF.stopEnemyEsp() end
        end,
    })
    enemyEspSection:CreateToggle({
        Name = "Show Name",
        CurrentValue = true,
        Flag = "ESP.EnemyName",
        Save = true,
        Callback = function(v) config.enemyEspShowName = v end,
    })
    enemyEspSection:CreateToggle({
        Name = "Show Health",
        CurrentValue = true,
        Flag = "ESP.EnemyHP",
        Save = true,
        Callback = function(v) config.enemyEspShowHealth = v end,
    })
    enemyEspSection:CreateSlider({
        Name = "Max Distance",
        Min = 200, Max = 5000, CurrentValue = 2000, Rounding = 50,
        Flag = "ESP.EnemyDist",
        Save = true,
        Callback = function(v) config.enemyEspMaxDist = v end,
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
            BF.distributeStats(config.statsToAdd, config.pointsPerStat, false)
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
                BF.startBossTimers()
            else
                BF.stopBossTimers()
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
            local list = BF.scanBossMarkers()
            print("[BF] Sea:", BF.getCurrentSea())
            for _, row in ipairs(list) do
                print("[BF]", row.Status, row.Name, row.Time)
            end
            BF.notifyUser("Boss Scan", "Sea " .. BF.getCurrentSea() .. " | " .. #list .. " markers (see F9)")
        end,
    })

    local fruitSection = fruitTab:CreateSection({Name = "Fruit Notifier"})
    fruitSection:CreateToggle({
        Name = "Auto Random Fruit (Gacha)",
        CurrentValue = false,
        Flag = "Fruit.AutoRandom", Save = true,
        Callback = function(v)
            config.autoRandomFruit = v
            if v then BF.startAutoRandomFruit() else BF.stopAutoRandomFruit() end
        end,
    })
    fruitSection:CreateButton({
        Name = "Buy Random Fruit Once",
        Callback = function()
            BF.buyRandomFruitOnce()
        end,
    })
    fruitSection:CreateToggle({
        Name = "Fruit Notifier",
        CurrentValue = config.fruitNotifier,
        Flag = "Fruit.Notifier", Save = true,
        Callback = function(v)
            config.fruitNotifier = v
            if v then
                BF.startFruitNotifier()
            else
                BF.stopFruitNotifier()
            end
        end,
    })
    fruitSection:CreateToggle({
        Name = "Notify Only Valuable",
        CurrentValue = config.fruitFilterNotify,
        Flag = "Fruit.FilterNotify", Save = true,
        Callback = function(v) config.fruitFilterNotify = v end,
    })
    fruitSection:CreateToggle({
        Name = "Auto Collect",
        CurrentValue = config.fruitAutoCollect,
        Flag = "Fruit.AutoCollect", Save = true,
        Callback = function(v)
            config.fruitAutoCollect = v
            if v then BF.startFruitNotifier() end
        end,
    })
    fruitSection:CreateToggle({
        Name = "Collect Only Valuable",
        CurrentValue = config.fruitFilterCollect,
        Flag = "Fruit.FilterCollect", Save = true,
        Callback = function(v) config.fruitFilterCollect = v end,
    })

    window:SetWatermarkEnabled(true)
    if config.bossTimersEnabled then
        pcall(BF.startBossTimers)
    end
    local seaName = "?"
    pcall(function() seaName = tostring(BF.getCurrentSea()) end)
    BF.notifyUser("Loaded", "Vaxorin UI active. Sea: " .. seaName)
else
    BF.notifyUser("Loaded", "Fallback UI active. Use the button to start/stop.")
    if config.bossTimersEnabled then
        pcall(BF.startBossTimers)
    end
end

print("[BF] fully loaded, lines ready")
-- Keep script alive
while task.wait(1) do end

print("Test 1")
