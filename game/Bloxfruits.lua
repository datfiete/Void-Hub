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
            Title = "Blox Fruits",
            Subtitle = "by Fietewoozle",
            Logo = Vaxorin_Logo,
            Badges = {{Text = "Vaxorin | v1.0"}, {Text = "Executor : " .. Executor}},
            Footer = {Username = LocalPlayer.Name, Status = "Ready"},
            DiscordLink = "https://discord.gg/example",
            ShowSearch = true,
            ShowWindowControls = true,
            ToggleKey = Enum.KeyCode.RightControl,
            TopMost = true,
            HideCoreUI = true,
            ConfigurationSaving = {
                Enabled = true,
                FolderName = "Vaxorin",
                FileName = "Blox Fruits",
            },
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
    attackSpeed = 0.04,
    bossAttackSpeed = 0.001,
    hitsPerCycle = 6,
    bossHitsPerCycle = 35,
    clusterEnabled = true,
    clusterHeight = 12,
    maxClusterSize = 12,
    clusterRange = 300, -- how far to pull mobs into cluster
    statEnabled = false,
    statsToAdd = {"Melee", "Defense"},
    pointsPerStat = 1,
    bossPriority = true,
    autoEquip = true,
    preferredWeapon = "Melee",
    selectedFightingStyle = "Dark Step",
    questStack = false,
    stackCount = 3,
    fruitNotifier = true,        -- fruit notifier toggle
    fruitAutoCollect = true,
    fruitFilterCollect = false,  -- false = collect any dropped fruit
    fruitFilterNotify = false,
    fruitEspEnabled = true,
    fruitStoreAfterCollect = true,
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
    autoBones = false,       -- Haunted Castle bone farm
    autoBonesBuy = false,    -- CommF_ Bones Buy (Random Surprise)
    autoBuyAbilities = false,-- CommF_ Auto Buy Haki/Geppo/Soru/Ken
    autoCakePrince = false,  -- Cake Land 500 kills + drip_mama + kill Cake Prince
    acceptQuest = true,     -- auto accept island quest while farming
    devIslandLock = false,
    devIslandIndex = nil,
}

-- =============================================
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
        pcall(function()
        local vu = game:GetService("VirtualUser")
        vu:CaptureController()
        vu:Button1Down(Vector2.new(0, 0))
        task.wait(0.05)
        vu:Button1Up(Vector2.new(0, 0))
    end)
end

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

BF.expandTargetsInHitRange = function(targets, maxDist)
    maxDist = maxDist or 70
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return targets end
    local byModel = {}
    for _, t in ipairs(targets or {}) do
        if t then byModel[t] = true end
    end
        local folder = Workspace:FindFirstChild("Enemies")
    if folder then
        for _, enemy in ipairs(folder:GetChildren()) do
            if enemy:IsA("Model") and not byModel[enemy] then
                local root = enemy:FindFirstChild("HumanoidRootPart")
                local hum = enemy:FindFirstChildOfClass("Humanoid")
                if root and hum and hum.Health > 0 then
                    if (root.Position - hrp.Position).Magnitude <= maxDist then
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

BF._combatRemotesCache = nil
BF._combatRemotesAt = 0
BF._hitTick = 0

BF.fireCombatHit = function(targets)
    if not targets or #targets == 0 then return false end
        BF._hitTick = (BF._hitTick or 0) + 1
    -- Only hit the explicitly selected targets. Expanding by matching name can
    -- include unrelated enemies that are not part of the active quest.
    local primary, hits = BF.buildBladeHits(targets)
    if not primary or #hits == 0 then return false end

    local now = os.clock()
    if not BF._combatRemotesCache or (now - (BF._combatRemotesAt or 0)) > 5 then
        local a, h = BF.getCombatRemotes()
        BF._combatRemotesCache = { attack = a, hit = h }
        BF._combatRemotesAt = now
    end
    local RegisterAttack = BF._combatRemotesCache.attack
    local RegisterHit = BF._combatRemotesCache.hit

        local send = BF.resolveSendHits()
    if send then
        pcall(function() send(primary, hits) end)
    elseif RegisterHit then
        pcall(function() RegisterHit:FireServer(primary, hits) end)
    end
    if RegisterAttack then
        pcall(function() RegisterAttack:FireServer(0.05) end)
    end
        if BF._hitTick % 4 == 0 then
        BF.fireLeftClickRemote(primary)
    end

    return true
end

BF.clusterStackPos = nil
BF.lastBringAt = 0

BF._simRadiusAt = 0
BF.ensureSimRadius = function()
    if os.clock() - (BF._simRadiusAt or 0) < 5 then return end
    BF._simRadiusAt = os.clock()
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
    -- Sea1 normals (EnemySpawns dump 2026-09-27)
    {Name = "Pirate Starter",     Min = 0,   Max = 10,  Pos = Vector3.new(1137, 13, 1594), Quest = {"StartQuest","BanditQuest1",1}, EnemyPatterns = {"Bandit"}, isBoss = false},
    {Name = "Marine Starter",     Min = 0,   Max = 10,  Pos = Vector3.new(-2723, 32, 2090), Quest = {"StartQuest","MarineQuest1",1}, EnemyPatterns = {"Trainee"}, isBoss = false},
    {Name = "Jungle (Normal)",    Min = 10,  Max = 15,  Pos = Vector3.new(-1593, 28, 137), Quest = {"StartQuest","JungleQuest",1}, EnemyPatterns = {"Monkey"}, isBoss = false},
    {Name = "Jungle (Stage 2)",   Min = 15,  Max = 25,  Pos = Vector3.new(-1313, 18, -548), Quest = {"StartQuest","JungleQuest",2}, EnemyPatterns = {"Gorilla"}, isBoss = false},
    {Name = "Pirate Village",     Min = 30,  Max = 40,  Pos = Vector3.new(-1141, 22, 3976), Quest = {"StartQuest","BuggyQuest1",1}, EnemyPatterns = {"Pirate"}, isBoss = false},
    {Name = "Pirate Village Stage 2", Min = 40, Max = 55, Pos = Vector3.new(-1204, 28, 4370), Quest = {"StartQuest","BuggyQuest1",2}, EnemyPatterns = {"Brute"}, isBoss = false},
    {Name = "Desert 1",           Min = 60,  Max = 70,  Pos = Vector3.new(924, 8, 4514), Quest = {"StartQuest","DesertQuest",1}, EnemyPatterns = {"Desert Bandit"}, isBoss = false},
    {Name = "Desert 2",           Min = 70,  Max = 90,  Pos = Vector3.new(1573, 14, 4159), Quest = {"StartQuest","DesertQuest",2}, EnemyPatterns = {"Desert Officer"}, isBoss = false},
    {Name = "Snow 1",             Min = 90,  Max = 100, Pos = Vector3.new(1416, 78, -1435), Quest = {"StartQuest","SnowQuest",1}, EnemyPatterns = {"Snow Bandit"}, isBoss = false},
    {Name = "Snow 2",             Min = 100, Max = 110, Pos = Vector3.new(1198, 98, -1603), Quest = {"StartQuest","SnowQuest",2}, EnemyPatterns = {"Snowman"}, isBoss = false},
    {Name = "Marine Fortress",    Min = 120, Max = 150, Pos = Vector3.new(-4809, 13, 4302), Quest = {"StartQuest","MarineQuest2",1}, EnemyPatterns = {"Chief Petty Officer"}, isBoss = false},
    {Name = "Sky 1",              Min = 150, Max = 175, Pos = Vector3.new(-5092, 281, -1019), Quest = {"StartQuest","SkyQuest",1}, EnemyPatterns = {"Sky Bandit"}, isBoss = false},
    {Name = "Sky 2",              Min = 175, Max = 190, Pos = Vector3.new(-5293, 505, -351), Quest = {"StartQuest","SkyQuest",2}, EnemyPatterns = {"Dark Master"}, isBoss = false},
    {Name = "Prison 1",           Min = 190, Max = 209, Pos = Vector3.new(5270, 9, 470), Quest = {"StartQuest","PrisonerQuest",1}, EnemyPatterns = {"Prisoner"}, isBoss = false},
    {Name = "Prison 2",           Min = 210, Max = 224, Pos = Vector3.new(5330, 20, 750), Quest = {"StartQuest","PrisonerQuest",2}, EnemyPatterns = {"Dangerous Prisoner"}, isBoss = false},
    {Name = "Prison 3 (Ruthless Prisoners)", Min = 220, Max = 229, Pos = Vector3.new(5330, 20, 750), Quest = {"StartQuest","ImpelQuest",1}, EnemyPatterns = {"Ruthless Prisoner"}, isBoss = false},
    {Name = "Colosseum 1",        Min = 250, Max = 300, Pos = Vector3.new(-1745, 10, -2705), Quest = {"StartQuest","ColosseumQuest",1}, EnemyPatterns = {"Toga Warrior"}, isBoss = false},
    --{Name = "Colosseum 2",        Min = 275, Max = 300, Pos = Vector3.new(-1175, 12, -3214), Quest = {"StartQuest","ColosseumQuest",2}, EnemyPatterns = {"Gladiator"}, isBoss = false},
    {Name = "Magma 1",            Min = 300, Max = 325, Pos = Vector3.new(-5468, 17, 8450), Quest = {"StartQuest","MagmaQuest",1}, EnemyPatterns = {"Military Soldier"}, isBoss = false},
    {Name = "Magma 2",            Min = 325, Max = 350, Pos = Vector3.new(-5842, 77, 8773), Quest = {"StartQuest","MagmaQuest",2}, EnemyPatterns = {"Military Spy"}, isBoss = false},
    {Name = "Fishman 1",          Min = 375, Max = 400, Pos = Vector3.new(60793, 24, 1362), Quest = {"StartQuest","FishmanQuest",1}, EnemyPatterns = {"Fishman Warrior"}, isBoss = false},
    {Name = "Fishman 2",          Min = 400, Max = 425, Pos = Vector3.new(61928, 25, 1331), Quest = {"StartQuest","FishmanQuest",2}, EnemyPatterns = {"Fishman Commando"}, isBoss = false},
    {Name = "Sky Upper 1",        Min = 450, Max = 475, Pos = Vector3.new(-4241, 1089, -404), Quest = {"StartQuest","SkyExp1Quest",1}, EnemyPatterns = {"God's Guard"}, isBoss = false},
    {Name = "Sky Upper 2",        Min = 475, Max = 500, Pos = Vector3.new(-5959, 5469, 1831), Quest = {"StartQuest","SkyExp1Quest",2}, EnemyPatterns = {"Shanda"}, isBoss = false},
    {Name = "Sky Upper 3",        Min = 525, Max = 550, Pos = Vector3.new(-6798, 5552, 1214), Quest = {"StartQuest","SkyExp2Quest",1}, EnemyPatterns = {"Royal Squad"}, isBoss = false},
    {Name = "Sky Upper 4",        Min = 550, Max = 575, Pos = Vector3.new(-7064, 5541, 939), Quest = {"StartQuest","SkyExp2Quest",2}, EnemyPatterns = {"Royal Soldier"}, isBoss = false},
    {Name = "Fountain 1",         Min = 625, Max = 650, Pos = Vector3.new(5572, 78, 4010), Quest = {"StartQuest","FountainQuest",1}, EnemyPatterns = {"Galley Pirate"}, isBoss = false},
    {Name = "Fountain 2",         Min = 650, Max = 700, Pos = Vector3.new(5634, 78, 4789), Quest = {"StartQuest","FountainQuest",2}, EnemyPatterns = {"Galley Captain"}, isBoss = false},

    -- Sea1 bosses (names from live EnemySpawns dump)
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
    {Name = "Warden", Min = 230, Max = 249, Pos = Vector3.new(5592, 2, 729),
        Quest = {"StartQuest","ImpelQuest",1}, EnemyPatterns = {"Ruthless Prisoner"},
        BossQuest = {"StartQuest","ImpelQuest",2}, BossPatterns = {"Warden"},
        isBoss = true},
    -- Dump name is Magma General (not Admiral)
    {Name = "Magma General", Min = 350, Max = 375, Pos = Vector3.new(-5626, 55, 8623),
        Quest = {"StartQuest","MagmaQuest",2}, EnemyPatterns = {"Military Spy"},
        BossQuest = {"StartQuest","MagmaQuest",3}, BossPatterns = {"Magma General", "Magma Admiral"},
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
        BossQuest = {"StartQuest","SkyExp2Quest",3}, BossPatterns = {"Lightning God", "Thunder God"},
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
    {Name = "Horned Warrior",     Min = 1125, Max = 1174, Pos = Vector3.new(-6342, 29, -5818), Quest = {"StartQuest","IceSideQuest",2}, EnemyPatterns = {"Horned Warrior"}, isBoss = false},
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

    -- ========== SEA 3 (EnemySpawns dump MAP=Sea3 PlaceId=7449423635) ==========
    -- Port Town
    {Name = "Port Town 1",        Min = 1500, Max = 1524, Pos = Vector3.new(-384, 56, 5669),
        Quest = {"StartQuest","PiratePortQuest",1}, EnemyPatterns = {"Pirate Millionaire"}, isBoss = false},
    {Name = "Port Town 2",        Min = 1525, Max = 1574, Pos = Vector3.new(-444, 83, 6051),
        Quest = {"StartQuest","PiratePortQuest",2}, EnemyPatterns = {"Pistol Billionaire"}, isBoss = false},
    -- Hydra Island
    {Name = "Hydra Warriors",     Min = 1575, Max = 1599, Pos = Vector3.new(6822, 54, -915),
        Quest = {"StartQuest","DragonCrewQuest",1}, EnemyPatterns = {"Dragon Crew Warrior"}, isBoss = false},
    {Name = "Hydra Archers",      Min = 1600, Max = 1624, Pos = Vector3.new(6756, 490, 329),
        Quest = {"StartQuest","DragonCrewQuest",2}, EnemyPatterns = {"Dragon Crew Archer"}, isBoss = false},
    {Name = "Hydra Enforcers",    Min = 1625, Max = 1649, Pos = Vector3.new(4526, 1005, 367),
        Quest = {"StartQuest","VenomCrewQuest",1}, EnemyPatterns = {"Hydra Enforcer"}, isBoss = false},
    {Name = "Venom Assailants",   Min = 1650, Max = 1699, Pos = Vector3.new(4590, 1165, 760),
        Quest = {"StartQuest","VenomCrewQuest",2}, EnemyPatterns = {"Venomous Assailant"}, isBoss = false},
    -- Great Tree
    {Name = "Great Tree 1",       Min = 1700, Max = 1724, Pos = Vector3.new(2724, 77, -7806),
        Quest = {"StartQuest","MarineTreeIsland",1}, EnemyPatterns = {"Marine Commodore"}, isBoss = false},
    {Name = "Great Tree 2",       Min = 1725, Max = 1774, Pos = Vector3.new(3775, 128, -7103),
        Quest = {"StartQuest","MarineTreeIsland",2}, EnemyPatterns = {"Marine Rear Admiral"}, isBoss = false},
    -- Floating Turtle
    {Name = "Turtle Raiders",     Min = 1775, Max = 1799, Pos = Vector3.new(-10452, 333, -8367),
        Quest = {"StartQuest","DeepForestIsland3",1}, EnemyPatterns = {"Fishman Raider"}, isBoss = false},
    {Name = "Turtle Captains",    Min = 1800, Max = 1824, Pos = Vector3.new(-11015, 332, -8937),
        Quest = {"StartQuest","DeepForestIsland3",2}, EnemyPatterns = {"Fishman Captain"}, isBoss = false},
    {Name = "Forest Pirates",     Min = 1825, Max = 1849, Pos = Vector3.new(-13416, 332, -7813),
        Quest = {"StartQuest","DeepForestIsland",1}, EnemyPatterns = {"Forest Pirate"}, isBoss = false},
    {Name = "Myth Pirates",       Min = 1850, Max = 1899, Pos = Vector3.new(-13471, 494, -6876),
        Quest = {"StartQuest","DeepForestIsland",2}, EnemyPatterns = {"Mythological Pirate"}, isBoss = false},
    {Name = "Jungle Pirates",     Min = 1900, Max = 1924, Pos = Vector3.new(-11987, 332, -10544),
        Quest = {"StartQuest","DeepForestIsland2",1}, EnemyPatterns = {"Jungle Pirate"}, isBoss = false},
    {Name = "Musketeer Pirates",  Min = 1925, Max = 1974, Pos = Vector3.new(-13339, 416, -9802),
        Quest = {"StartQuest","DeepForestIsland2",2}, EnemyPatterns = {"Musketeer Pirate"}, isBoss = false},
    -- Haunted Castle (live names: Reborn Skeleton / Living Zombie / Demonic Soul / Posessed Mummy)
    {Name = "Haunted 1",          Min = 1975, Max = 1999, Pos = Vector3.new(-8786, 142, 6261),
        Quest = {"StartQuest","HauntedQuest1",1}, EnemyPatterns = {"Reborn Skeleton","Ghost"}, isBoss = false},
    {Name = "Haunted 2",          Min = 2000, Max = 2024, Pos = Vector3.new(-10145, 147, 5955),
        Quest = {"StartQuest","HauntedQuest1",2}, EnemyPatterns = {"Living Zombie"}, isBoss = false},
    {Name = "Haunted 3",          Min = 2025, Max = 2049, Pos = Vector3.new(-9427, 171, 6048),
        Quest = {"StartQuest","HauntedQuest2",1}, EnemyPatterns = {"Demonic Soul"}, isBoss = false},
    {Name = "Haunted 4",          Min = 2050, Max = 2074, Pos = Vector3.new(-9449, 5, 6343),
        Quest = {"StartQuest","HauntedQuest2",2}, EnemyPatterns = {"Posessed Mummy","Possessed Mummy"}, isBoss = false},
    -- Sea of Treats
    {Name = "Peanut 1",           Min = 2075, Max = 2099, Pos = Vector3.new(-2122, 25, -10112),
        Quest = {"StartQuest","NutsIslandQuest",1}, EnemyPatterns = {"Peanut Scout"}, isBoss = false},
    {Name = "Peanut 2",           Min = 2100, Max = 2124, Pos = Vector3.new(-2136, 62, -10547),
        Quest = {"StartQuest","NutsIslandQuest",2}, EnemyPatterns = {"Peanut President"}, isBoss = false},
    {Name = "Ice Cream 1",        Min = 2125, Max = 2149, Pos = Vector3.new(-837, 65, -10939),
        Quest = {"StartQuest","IceCreamIslandQuest",1}, EnemyPatterns = {"Ice Cream Chef"}, isBoss = false},
    {Name = "Ice Cream 2",        Min = 2150, Max = 2199, Pos = Vector3.new(-647, 87, -11279),
        Quest = {"StartQuest","IceCreamIslandQuest",2}, EnemyPatterns = {"Ice Cream Commander"}, isBoss = false},
    {Name = "Cake 1",             Min = 2200, Max = 2224, Pos = Vector3.new(-2359, 37, -12115),
        Quest = {"StartQuest","CakeQuest1",1}, EnemyPatterns = {"Cookie Crafter"}, isBoss = false},
    {Name = "Cake 2",             Min = 2225, Max = 2249, Pos = Vector3.new(-1570, 35, -12302),
        Quest = {"StartQuest","CakeQuest1",2}, EnemyPatterns = {"Cake Guard"}, isBoss = false},
    {Name = "Cake 3",             Min = 2250, Max = 2274, Pos = Vector3.new(-1818, 35, -12958),
        Quest = {"StartQuest","CakeQuest2",1}, EnemyPatterns = {"Baking Staff"}, isBoss = false},
    {Name = "Cake 4",             Min = 2275, Max = 2299, Pos = Vector3.new(-2254, 51, -12888),
        Quest = {"StartQuest","CakeQuest2",2}, EnemyPatterns = {"Head Baker"}, isBoss = false},
    {Name = "Choco 1",            Min = 2300, Max = 2324, Pos = Vector3.new(-9, 26, -12262),
        Quest = {"StartQuest","ChocQuest1",1}, EnemyPatterns = {"Cocoa Warrior"}, isBoss = false},
    {Name = "Choco 2",            Min = 2325, Max = 2349, Pos = Vector3.new(707, 26, -12609),
        Quest = {"StartQuest","ChocQuest1",2}, EnemyPatterns = {"Chocolate Bar Battler"}, isBoss = false},
    {Name = "Choco 3",            Min = 2350, Max = 2374, Pos = Vector3.new(4, 26, -12630),
        Quest = {"StartQuest","ChocQuest2",1}, EnemyPatterns = {"Sweet Thief"}, isBoss = false},
    {Name = "Choco 4",            Min = 2375, Max = 2399, Pos = Vector3.new(83, 26, -12954),
        Quest = {"StartQuest","ChocQuest2",2}, EnemyPatterns = {"Candy Rebel"}, isBoss = false},
    {Name = "Candy 1",            Min = 2400, Max = 2424, Pos = Vector3.new(-1344, 34, -14582),
        Quest = {"StartQuest","CandyQuest1",1}, EnemyPatterns = {"Candy Pirate"}, isBoss = false},
    {Name = "Candy 2",            Min = 2425, Max = 2449, Pos = Vector3.new(-841, 19, -14535),
        Quest = {"StartQuest","CandyQuest1",2}, EnemyPatterns = {"Snow Demon"}, isBoss = false},
    -- Tiki Outpost
    {Name = "Tiki 1",             Min = 2450, Max = 2474, Pos = Vector3.new(-16272, 26, -203),
        Quest = {"StartQuest","TikiQuest1",1}, EnemyPatterns = {"Isle Outlaw"}, isBoss = false},
    {Name = "Tiki 2",             Min = 2475, Max = 2499, Pos = Vector3.new(-16836, 26, -179),
        Quest = {"StartQuest","TikiQuest1",2}, EnemyPatterns = {"Island Boy"}, isBoss = false},
    {Name = "Tiki 3",             Min = 2500, Max = 2524, Pos = Vector3.new(-16233, 25, 1033),
        Quest = {"StartQuest","TikiQuest2",1}, EnemyPatterns = {"Sun-kissed Warrior"}, isBoss = false},
    {Name = "Tiki 4",             Min = 2525, Max = 2549, Pos = Vector3.new(-16797, 27, 1049),
        Quest = {"StartQuest","TikiQuest2",2}, EnemyPatterns = {"Isle Champion"}, isBoss = false},
    {Name = "Tiki 5",             Min = 2550, Max = 2574, Pos = Vector3.new(-16544, 96, 1516),
        Quest = {"StartQuest","TikiQuest3",1}, EnemyPatterns = {"Serpent Hunter"}, isBoss = false},
    {Name = "Tiki 6",             Min = 2575, Max = 2599, Pos = Vector3.new(-16874, 121, 1635),
        Quest = {"StartQuest","TikiQuest3",2}, EnemyPatterns = {"Skull Slayer"}, isBoss = false},
    -- Submerged Island
    {Name = "Submerged 1",        Min = 2600, Max = 2624, Pos = Vector3.new(10978, -2157, 9163),
        Quest = {"StartQuest","SubmergedQuest1",1}, EnemyPatterns = {"Reef Bandit"}, isBoss = false},
    {Name = "Submerged 2",        Min = 2625, Max = 2649, Pos = Vector3.new(10750, -2087, 9363),
        Quest = {"StartQuest","SubmergedQuest1",2}, EnemyPatterns = {"Coral Pirate"}, isBoss = false},
    {Name = "Submerged 3",        Min = 2650, Max = 2674, Pos = Vector3.new(10628, -2078, 10072),
        Quest = {"StartQuest","SubmergedQuest2",1}, EnemyPatterns = {"Sea Chanter","Ocean Prophet"}, isBoss = false},
    {Name = "Submerged 4 (Ocean Prophet)", Min = 2675, Max = 2699, Pos = Vector3.new(9827, -1995, 9745),
        Quest = {"StartQuest","SubmergedQuest2",2}, EnemyPatterns = {"Ocean Prophet"}, isBoss = false},
    {Name = "Submerged 5 (High Disciple)", Min = 2700, Max = 2724, Pos = Vector3.new(9827, -1995, 9745),
        Quest = {"StartQuest","SubmergedQuest3",1}, EnemyPatterns = {"High Disciple"}, isBoss = false},
    {Name = "Submerged 6 (Grand Devotee)", Min = 2725, Max = 2800, Pos = Vector3.new(9610, -1993, 9926),
        Quest = {"StartQuest","SubmergedQuest3",2}, EnemyPatterns = {"Grand Devotee"}, isBoss = false},

    -- Sea3 bosses (from dump + markers)
    {Name = "Beautiful Pirate",   Min = 1950, Max = 1975, Pos = Vector3.new(5367, 26, -65),
        Quest = {"StartQuest","DeepForestIsland2",2}, EnemyPatterns = {"Musketeer Pirate"},
        BossQuest = nil, BossPatterns = {"Beautiful Pirate"},
        isBoss = true},
    {Name = "Longma",             Min = 2000, Max = 2025, Pos = Vector3.new(-10156, 338, -9446),
        Quest = {"StartQuest","HauntedQuest1",2}, EnemyPatterns = {"Living Zombie"},
        BossQuest = nil, BossPatterns = {"Longma"},
        isBoss = true},
    {Name = "Stone",              Min = 1550, Max = 1600, Pos = Vector3.new(-1110, 58, 6812),
        Quest = {"StartQuest","PiratePortQuest",2}, EnemyPatterns = {"Pistol Billionaire"},
        BossQuest = nil, BossPatterns = {"Stone"},
        isBoss = true},
    {Name = "Captain Elephant",   Min = 1875, Max = 1925, Pos = Vector3.new(-13366, 326, -8485),
        Quest = {"StartQuest","DeepForestIsland",2}, EnemyPatterns = {"Mythological Pirate"},
        BossQuest = nil, BossPatterns = {"Captain Elephant","Elephant"},
        isBoss = true},

}

table.sort(islands, function(a,b) return a.Min < b.Min end)

-- =============================================
-- NOCLIP & Teleport & FLY
-- =============================================
BF.noclipConnection = nil
BF._noclipParts = {}
BF._noclipRefreshAt = 0
BF._noclipChar = nil

BF.enableNoclip = function()
    if BF.noclipConnection then return end
    -- Stepped runs before physics; Heartbeat is too late for collisions
    BF.noclipConnection = RunService.Stepped:Connect(function()
        local character = LocalPlayer.Character
        if not character then return end
        local now = os.clock()
        if character ~= BF._noclipChar or now - (BF._noclipRefreshAt or 0) > 0.4 then
            BF._noclipChar = character
            BF._noclipRefreshAt = now
            local list = {}
            for _, p in ipairs(character:GetDescendants()) do
                if p:IsA("BasePart") then
                    table.insert(list, p)
                end
            end
            BF._noclipParts = list
        end
        for _, p in ipairs(BF._noclipParts) do
            if p and p.Parent then
                p.CanCollide = false
            end
        end
    end)
end

BF.disableNoclip = function()
    if BF.noclipConnection then
        BF.noclipConnection:Disconnect()
        BF.noclipConnection = nil
    end
    BF._noclipParts = {}
    BF._noclipChar = nil
    local character = LocalPlayer.Character
    if character then
        for _, p in ipairs(character:GetDescendants()) do
            if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
                -- leave default; HRP often stays non-collide in fly
                pcall(function() p.CanCollide = true end)
            end
        end
    end
end

BF.flyTarget = nil
BF.flyConnection = nil
BF.flying = false
BF.hoverY = nil
BF._bossFlyUnlock = false

-- Direkter Teleport (ohne Physik-Flug) – für Unterwasser / lange Distanzen
BF.teleportCharacterTo = function(pos)
    if not pos then return false end
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    local wasFlying = BF.flying
    if wasFlying then BF.disableFly() end
    -- Position setzen (sauberer als MoveTo bei HRP mit Velocity)
    pcall(function()
        hrp.CFrame = CFrame.new(pos + Vector3.new(0, 6, 0))
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end)
    task.wait(0.4)
    if wasFlying then pcall(BF.enableFly) end
    return true
end

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

-- Only land if no other fly-using mode is still active
BF.anyFlyModeActive = function()
    return BF.farmRunning
        or BF.bonesRunning
        or BF.cakePrinceRunning
        or BF.seaProgressRunning
        or BF.secretsRunning
        or BF.raidRunning
        or (BF.activeBossHuntTask ~= nil)
end

BF.safeDisableFly = function()
    if BF.anyFlyModeActive() then return end
    pcall(BF.disableFly)
end

BF.setFlyTarget = function(position, preserveHeight)
    if BF.fruitOwnsFly and type(BF.fruitOwnsFly) == "function" and BF.fruitOwnsFly() then
        if not BF._fruitFlyUnlock then
            return
        end
    end
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

BF._whirlpoolCache = nil
BF._whirlpoolCacheAt = 0
BF.findWhirlpool = function()
    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local now = os.clock()
    if BF._whirlpoolCache and (now - (BF._whirlpoolCacheAt or 0)) < 8 then
        local c = BF._whirlpoolCache
        if c and c.Position then
            return {
                Object = c.Object,
                Position = c.Position,
                Distance = (c.Position - hrp.Position).Magnitude,
            }
        end
        return nil
    end

    local best, bestDistance = nil, math.huge
    local keywords = {"whirlpool", "vortex", "maelstrom", "swirl"}

    local function consider(obj)
        if not obj then return end
        local name = string.lower(obj.Name)
        local matches = false
        for _, keyword in ipairs(keywords) do
            if string.find(name, keyword, 1, true) then matches = true break end
        end
        if not matches then return end
        local position = nil
        if obj:IsA("BasePart") then
            position = obj.Position
        elseif obj:IsA("Model") then
            if obj.PrimaryPart then
                position = obj.PrimaryPart.Position
            else
                local part = obj:FindFirstChildWhichIsA("BasePart")
                if part then position = part.Position end
            end
        end
        if not position then return end
        local distance = (position - hrp.Position).Magnitude
        if distance < bestDistance then
            bestDistance = distance
            best = { Object = obj, Position = position, Distance = distance }
        end
    end

    pcall(function()
        local wo = Workspace:FindFirstChild("_WorldOrigin")
        if wo then
            for _, obj in ipairs(wo:GetChildren()) do consider(obj) end
            local locs = wo:FindFirstChild("Locations")
            if locs then
                for _, obj in ipairs(locs:GetChildren()) do consider(obj) end
            end
        end
    end)
    for _, obj in ipairs(Workspace:GetChildren()) do
        consider(obj)
    end

    BF._whirlpoolCache = best
    BF._whirlpoolCacheAt = now
    return best
end

BF.isUnderwaterIsland = function(island)
    if not island then return false end
    local name = island.Name:lower()
    return name:find("underwater", 1, true) ~= nil
        or name:find("submerged", 1, true) ~= nil
        or name:find("fishman", 1, true) ~= nil
end

-- The First Sea Underwater City is entered through the fixed whirlpool portal
-- between Frozen Village and Prison. It is not a named dynamic whirlpool object.
BF.UNDERWATER_CITY_WHIRLPOOL = Vector3.new(61163.8515625, 11.680007934570312, 1819.7840576171875)
BF.enterUnderwaterCity = function(timeout)
    timeout = timeout or 90
    local remoteFolder = ReplicatedStorage:FindFirstChild("Remotes")
    local commF = remoteFolder and remoteFolder:FindFirstChild("CommF_")
    if not commF then return false end
    local portal = BF.UNDERWATER_CITY_WHIRLPOOL
    local approach = portal + Vector3.new(0, 3, 0)
    local expectedCity = Vector3.new(61165.19140625, 0.18704631924629211, 1897.379150390625)
    local deadline = os.clock() + timeout
    repeat
        if not BF.farmRunning then return false end
        local character = LocalPlayer.Character
        local hrp = character and character:FindFirstChild("HumanoidRootPart")
        if not hrp then
            task.wait(0.2)
            continue
        end

        -- The portal and city spawn are only ~78 studs apart, so require
        -- actual arrival at the city spawn; a broad check falsely passed
        -- while still standing at the whirlpool.
        if (hrp.Position - expectedCity).Magnitude < 30 then
            if BF.flying then BF.disableFly() end
            return true
        end

        local distance = (hrp.Position - approach).Magnitude
        if distance > 18 then
            if not BF.flying then BF.enableFly() end
            BF.setFlyTarget(approach, false)
            task.wait(0.12)
        else
            if BF.flying then BF.disableFly() end
            pcall(function()
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
            end)
            pcall(function()
                commF:InvokeServer("requestEntrance", Vector3.new(61163.8515625, 11.680007934570312, 1819.7840576171875))
            end)
            task.wait(0.4)
        end
    until os.clock() >= deadline
    return false
end

-- =============================================
-- QUEST STACK & HELPERS
-- =============================================
BF.acceptQuest = function(questArgs)
    if not questArgs then return false end
    local remote = ReplicatedStorage:FindFirstChild("Remotes")
    if not remote then return false end
    local commF = remote:FindFirstChild("CommF_")
    if not commF then return false end
        local ok = pcall(function()
        commF:InvokeServer(unpack(questArgs))
    end)
    BF.invalidateQuestCache()
    return ok
end

BF.stackQuest = function(questArgs, count)
    if not questArgs or count < 1 then return false end
    local remote = ReplicatedStorage:FindFirstChild("Remotes")
    if not remote then return false end
    local commF = remote:FindFirstChild("CommF_")
    if not commF then return false end
    for i = 1, count do
        pcall(function() commF:InvokeServer(unpack(questArgs)) end)
        task.wait(0.25)
    end
    return true
end

BF.acceptQuestWrapper = function(questArgs, opts)
    opts = opts or {}
    if questArgs and questArgs[2] and type(BF.activeQuestMatches) == "function" then
        local ok, matched = pcall(function()
            return BF.activeQuestMatches(tostring(questArgs[2]))
        end)
        if ok and matched then
            return true
        end
    end
            if opts.allowStack and config.questStack and questArgs then
        return BF.stackQuest(questArgs, math.min(config.stackCount or 2, 3))
    end
    return BF.acceptQuest(questArgs)
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

    -- If preferred is Melee and user has a selected fighting style, keep that style equipped
    if preferred == "Melee" and config.selectedFightingStyle and type(BF.findFightingStyleTool) == "function" then
        local tool, isEquipped = BF.findFightingStyleTool(config.selectedFightingStyle)
        if tool then
            if not isEquipped then
                humanoid:EquipTool(tool)
            end
            return
        end
    end

    if preferred == "Any" and currentType then return end
    if preferred ~= "Any" and currentType == preferred then return end

    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not backpack then return end
    for _, tool in ipairs(backpack:GetChildren()) do
        if tool:IsA("Tool") then
            local wType = tool:GetAttribute("WeaponType") or (tool:FindFirstChild("WeaponType") and tool.WeaponType.Value)
            if not wType and tool:FindFirstChild("ToolTip") and tool.ToolTip == "Melee" then
                wType = "Melee"
            end
            if wType then
                if preferred == "Any" or wType == preferred then
                    humanoid:EquipTool(tool)
                    return
                end
            elseif preferred == "Melee" and BF.styleAliases then
                for _, aliasList in pairs(BF.styleAliases) do
                    for _, alias in ipairs(aliasList) do
                        if string.lower(tool.Name) == string.lower(alias) then
                            humanoid:EquipTool(tool)
                            return
                        end
                    end
                end
            end
        end
    end
end

-- Buso (Observation/Armament) + preferred weapon — for Bones / Cake / farm
BF._lastBusoAt = 0
BF._busoAttemptCharacter = nil
BF.ensureBuso = function()
    local character = LocalPlayer.Character
    if not character then return end
    -- Buso layers are usually parented to body parts, not directly to Humanoid.
    -- Searching descendants prevents repeatedly toggling Buso off after enabling it.
    if character:FindFirstChild("LeftHand_BusoLayer1", true)
        or character:FindFirstChild("RightHand_BusoLayer1", true)
        or character:FindFirstChild("LeftArm_BusoLayer1", true)
        or character:FindFirstChild("RightArm_BusoLayer1", true) then
        BF._busoAttemptCharacter = character
        return
    end
    -- CommF_ "Buso" is a toggle. Only issue it once per character because
    -- client-side aura visuals may replicate after a delay or under another rig.
    if BF._busoAttemptCharacter == character then return end
    BF._busoAttemptCharacter = character
    BF._lastBusoAt = os.clock()
    local characters = Workspace:FindFirstChild("Characters")
    local localCharacter = characters and characters:FindFirstChild(LocalPlayer.Name)
    if localCharacter and (localCharacter:FindFirstChild("LeftHand_BusoLayer1", true)
        or localCharacter:FindFirstChild("RightHand_BusoLayer1", true)
        or localCharacter:FindFirstChild("LeftArm_BusoLayer1", true)
        or localCharacter:FindFirstChild("RightArm_BusoLayer1", true)) then
        return
    end
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local commF = remotes and remotes:FindFirstChild("CommF_")
    if commF then
        pcall(function()
            commF:InvokeServer("Buso")
        end)
    end
end

BF.ensureCombatReady = function()
    pcall(BF.autoEquipWeapon)
    pcall(BF.ensureBuso)
end

-- =============================================
-- FRUIT NOTIFIER (SIMPLE)
-- =============================================
BF.fruitNotifierRunning = false
BF.fruitNotified = {}
BF._fruitCollectActive = false
BF._fruitTargetPos = nil
BF._fruitFlyUnlock = false
BF._fruitEspFolder = nil
BF._fruitEspMap = {} -- key -> {bb, label, obj}

BF.fruitOwnsFly = function()
    if not BF._fruitCollectActive or not BF._fruitTargetPos then
        return false
    end
    -- auto-clear stuck fruit lock after 20s
    if BF._fruitLockAt and (os.clock() - BF._fruitLockAt) > 20 then
        BF._fruitCollectActive = false
        BF._fruitTargetPos = nil
        return false
    end
    return true
end

BF.getFruitStoreKey = function(displayName)
    local n = tostring(displayName or "")
    n = n:gsub("%s*[Ff]ruit%s*", ""):gsub("^%s+", ""):gsub("%s+$", "")
    if n == "" then return nil end
    if string.find(n, "-", 1, true) then return n end
    -- "Spin" -> "Spin-Spin"
    local word = n:match("^(%S+)") or n
    return word .. "-" .. word
end

BF.storeFruitInInventory = function()
    if not config.fruitStoreAfterCollect then return end
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local comm = remotes and remotes:FindFirstChild("CommF_")
    if not comm then return end
    local char = LocalPlayer.Character
    local bp = LocalPlayer:FindFirstChild("Backpack")
    local tools = {}
    if char then
        for _, t in ipairs(char:GetChildren()) do
            if t:IsA("Tool") and BF.isRealFruitName and BF.isRealFruitName(t.Name) then
                table.insert(tools, t)
            end
        end
    end
    if bp then
        for _, t in ipairs(bp:GetChildren()) do
            if t:IsA("Tool") and BF.isRealFruitName and BF.isRealFruitName(t.Name) then
                table.insert(tools, t)
            end
        end
    end
    for _, tool in ipairs(tools) do
        local key = BF.getFruitStoreKey(tool.Name)
        if key then
            pcall(function()
                comm:InvokeServer("StoreFruit", key, tool)
            end)
            task.wait(0.2)
        end
    end
end

BF.ensureFruitEspFolder = function()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return nil end
    local f = pg:FindFirstChild("BF_FruitESP")
    if not f then
        f = Instance.new("Folder")
        f.Name = "BF_FruitESP"
        f.Parent = pg
    end
    BF._fruitEspFolder = f
    return f
end

BF.clearFruitEsp = function()
    if BF._fruitEspFolder then
        pcall(function() BF._fruitEspFolder:ClearAllChildren() end)
    end
    BF._fruitEspMap = {}
end

BF.updateFruitEspEntry = function(key, obj, pos, displayName)
    if not config.fruitEspEnabled then return end
    local folder = BF.ensureFruitEspFolder()
    if not folder then return end
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local dist = hrp and math.floor((hrp.Position - pos).Magnitude) or 0

    local entry = BF._fruitEspMap[key]
    if not entry or not entry.bb or not entry.bb.Parent then
        local part = BF.getFruitHandle(obj)
        if not part and obj:IsA("Model") then
            part = obj:FindFirstChildWhichIsA("BasePart")
        end
        if not part then
            part = Instance.new("Part")
            part.Name = "BF_FruitEspAnchor"
            part.Anchored = true
            part.CanCollide = false
            part.Transparency = 1
            part.Size = Vector3.new(1, 1, 1)
            part.Position = pos
            part.Parent = folder
        end
        local bb = Instance.new("BillboardGui")
        bb.Name = "FruitESP"
        bb.AlwaysOnTop = true
        bb.Size = UDim2.new(0, 160, 0, 40)
        bb.StudsOffset = Vector3.new(0, 3, 0)
        bb.Adornee = part
        bb.Parent = folder
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 0.35
        label.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
        label.TextColor3 = Color3.fromRGB(120, 255, 140)
        label.Font = Enum.Font.GothamBold
        label.TextSize = 14
        label.TextStrokeTransparency = 0.5
        label.Parent = bb
        entry = { bb = bb, label = label, part = part }
        BF._fruitEspMap[key] = entry
    end
    if entry.label then
        entry.label.Text = string.format("%s\n%d studs", displayName, dist)
    end
    if entry.part and entry.part.Name == "BF_FruitEspAnchor" then
        entry.part.Position = pos
    end
end

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

BF.isJunkFruitName = function(name)
    local n = string.lower(tostring(name or "")):gsub("%s+", "")
    if n == "fruit" then return true end
    if string.match(n, "^fruit%d+$") then return true end
    if string.match(n, "^fruit[%-_]%d+$") then return true end
    if n == "fruitspawn" or n == "fruitspawns" then return true end
    if n == "handle" or n == "part" or n == "mesh" or n == "model" then return true end
    return false
end

BF.isRealFruitName = function(name)
    local n = string.lower(tostring(name or ""))
    if BF.isJunkFruitName(n) then return false end
    if string.find(n, "%-", 1, true) then return true end
    if string.find(n, "fruit", 1, true) then
        local base = n:gsub("%s*fruit%s*", ""):gsub("%s+", "")
        if #base >= 2 and not BF.isJunkFruitName(base) then return true end
    end
    if BF.isValuableFruit(n) then return true end
    return false
end

BF.isHeldBySomeone = function(obj)
    local parent = obj and obj.Parent
    if not parent then return true end
    if parent == LocalPlayer.Character then return true end
    if parent == LocalPlayer:FindFirstChild("Backpack") then return true end
    if parent:IsA("Model") and parent:FindFirstChildOfClass("Humanoid") then return true end
    if parent:IsA("Backpack") then return true end
    return false
end

-- ONLY workspace-root Tools = real dropped fruits.
-- FruitSpawns markers flicker / respawn and cause fly ping-pong — never collect those.
BF.isCollectibleFruit = function(obj)
    if not obj or not obj.Parent then return false end
    if not obj:IsA("Tool") then return false end
    if BF.isJunkFruitName(obj.Name) then return false end
    if BF.isHeldBySomeone(obj) then return false end
    -- must be direct child of Workspace (true ground drop)
    if obj.Parent ~= Workspace then return false end
    return BF.getFruitHandle(obj) ~= nil
end

BF.isWorldFruit = function(obj)
    return BF.isCollectibleFruit(obj)
end

BF._lockedFruit = nil
BF._lockedFruitPos = nil
BF._lockedFruitAt = 0
BF._stableHits = {} -- [obj] = { pos, count, lastSeen }

BF.fruitTargetStillValid = function(obj)
    if not obj or not obj.Parent then return false end
    if obj.Parent ~= Workspace then return false end
    if not obj:IsA("Tool") then return false end
    if BF.isHeldBySomeone(obj) then return false end
    return BF.getFruitHandle(obj) ~= nil
end

BF.findFruitCandidates = function()
    local candidates = {}
    for _, v in ipairs(Workspace:GetChildren()) do
        if v:IsA("Tool") and BF.isCollectibleFruit(v) then
            table.insert(candidates, v)
        end
    end
    return candidates
end

BF.fruitScan = function()
    if not config.fruitNotifier and not config.fruitAutoCollect and not config.fruitEspEnabled then return end

    local candidates = BF.findFruitCandidates()
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local now = os.clock()

    -- stability tracker: same tool must stay near same pos for 2+ scans
    local alive = {}
    for _, v in ipairs(candidates) do
        alive[v] = true
        local handle = BF.getFruitHandle(v)
        local pos = handle and handle.Position
        if pos then
            local st = BF._stableHits[v]
            if st and (pos - st.pos).Magnitude < 8 then
                st.count = st.count + 1
                st.pos = pos
                st.lastSeen = now
            else
                BF._stableHits[v] = { pos = pos, count = 1, lastSeen = now }
            end
        end
    end
    for obj, st in pairs(BF._stableHits) do
        if not alive[obj] or (now - (st.lastSeen or 0)) > 6 then
            BF._stableHits[obj] = nil
        end
    end

    -- ESP
    local seenEsp = {}
    for _, v in ipairs(candidates) do
        local handle = BF.getFruitHandle(v)
        local pos = handle and handle.Position
        if pos then
            local key = tostring(v)
            seenEsp[key] = true
            pcall(function() BF.updateFruitEspEntry(key, v, pos, v.Name) end)
            local st = BF._stableHits[v]
            local stable = st and st.count >= 2
            if stable and not BF.fruitNotified[key] then
                BF.fruitNotified[key] = true
                if config.fruitNotifier then
                    local valuable = BF.isValuableFruit(v.Name)
                    if not (config.fruitFilterNotify and not valuable) then
                        BF.notifyUser("Fruit Detected", v.Name .. (valuable and " [VAL]" or ""), 4)
                    end
                end
            end
        end
    end
    for key, entry in pairs(BF._fruitEspMap) do
        if not seenEsp[key] then
            pcall(function()
                if entry.bb then entry.bb:Destroy() end
                if entry.part and entry.part.Name == "BF_FruitEspAnchor" then entry.part:Destroy() end
            end)
            BF._fruitEspMap[key] = nil
        end
    end

    if not config.fruitAutoCollect then
        BF._fruitCollectActive = false
        BF._fruitTargetPos = nil
        BF._lockedFruit = nil
        return
    end

    local bossOwns = false
    pcall(function()
        if type(BF.bossHuntOwnsFly) == "function" then bossOwns = BF.bossHuntOwnsFly() end
    end)
    if bossOwns then
        BF._fruitCollectActive = false
        BF._fruitTargetPos = nil
        return
    end

    -- HARD LOCK: once chosen, keep it up to 25s — never hop to another fruit
    local target = BF._lockedFruit
    if target then
        local age = now - (BF._lockedFruitAt or 0)
        if BF.fruitTargetStillValid(target) and age < 25 then
            local handle = BF.getFruitHandle(target)
            local pos = handle and handle.Position
            if pos then
                BF._fruitCollectActive = true
                BF._fruitTargetPos = pos
                BF._fruitFlyUnlock = true
                pcall(function()
                    if not BF.flying then BF.enableFly() end
                    BF.setFlyTarget(pos + Vector3.new(0, 6, 0), false)
                end)
                BF._fruitFlyUnlock = false

                if hrp and (hrp.Position - pos).Magnitude < 25 then
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
                    task.wait(0.45)
                    pcall(BF.storeFruitInInventory)
                    BF.notifyUser("Fruit", "Collected " .. tostring(target.Name), 2)
                    BF._lockedFruit = nil
                    BF._fruitCollectActive = false
                    BF._fruitTargetPos = nil
                end
                return -- do not evaluate other fruits while locked
            end
        end
        -- lock expired or invalid
        BF._lockedFruit = nil
        BF._fruitCollectActive = false
        BF._fruitTargetPos = nil
    end

    -- pick only STABLE candidates (seen 2+ scans at same place)
    local best, bestDist = nil, math.huge
    for _, v in ipairs(candidates) do
        local st = BF._stableHits[v]
        if st and st.count >= 2 then
            if config.fruitFilterCollect and not BF.isValuableFruit(v.Name) then
                -- skip
            else
                local d = hrp and (hrp.Position - st.pos).Magnitude or 0
                if d < bestDist then
                    bestDist = d
                    best = v
                end
            end
        end
    end

    if not best then
        BF._fruitCollectActive = false
        BF._fruitTargetPos = nil
        return
    end

    BF._lockedFruit = best
    BF._lockedFruitAt = now
    BF._lockedFruitPos = BF._stableHits[best] and BF._stableHits[best].pos
    BF._fruitCollectActive = true
    BF._fruitTargetPos = BF._lockedFruitPos
    BF.notifyUser("Fruit", "Going to " .. tostring(best.Name), 2)
end

BF.startFruitNotifier = function()
    if BF.fruitNotifierRunning then return end
    BF.fruitNotifierRunning = true
    task.spawn(function()
        while BF.fruitNotifierRunning do
            pcall(BF.fruitScan)
            if BF._fruitCollectActive then
                task.wait(0.35)
            else
                task.wait(1.0)
            end
        end
    end)
end

BF.stopFruitNotifier = function()
    BF.fruitNotifierRunning = false
    BF._fruitCollectActive = false
    BF._fruitTargetPos = nil
    BF._lockedFruit = nil
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

BF.getPlayerCurrency = function(currencyName)
    local aliases = {
        Beli = {"Beli", "Money"},
        Fragments = {"Fragments", "Fragment"},
    }
    local names = aliases[currencyName] or {currencyName}
    for _, containerName in ipairs({"leaderstats", "Data"}) do
        local container = LocalPlayer:FindFirstChild(containerName)
        if container then
            for _, valueName in ipairs(names) do
                local value = container:FindFirstChild(valueName)
                if value and (value:IsA("IntValue") or value:IsA("NumberValue")) then
                    return tonumber(value.Value), value
                end
            end
        end
    end
    local attribute = LocalPlayer:GetAttribute(currencyName)
    return tonumber(attribute), nil
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
    local fallbackIsland = nil
    -- Submerged Island is progression-locked below Lv 2600.
    -- From 2600+ we allow it like any other island.
    local SUBMERGED_MIN = 2600
    for _, island in ipairs(islands) do
        local isSubmerged = island.Name and island.Name:lower():find("submerged", 1, true) ~= nil
        local allowed = (not isSubmerged) or (level >= SUBMERGED_MIN)
        if allowed and island.Pos and island.Pos.Magnitude > 0.1 then
            if level >= island.Min and level <= island.Max then
                table.insert(candidates, island)
            end
            if island.Max < level and (not fallbackIsland or island.Max > fallbackIsland.Max) then
                fallbackIsland = island
            end
        end
    end
    if #candidates == 0 then
        return fallbackIsland or islands[1]
    end
    -- ... Rest bleibt identisch wie in deinem Original ...
    local bossCandidates, normalCandidates = {}, {}
    for _, island in ipairs(candidates) do
        if island.isBoss then table.insert(bossCandidates, island)
        else table.insert(normalCandidates, island) end
    end
    if config.bossPriority and #bossCandidates > 0 then
        for _, island in ipairs(bossCandidates) do
            local alive = false
            pcall(function() alive = BF.findBossInWorkspace(island) ~= nil end)
            if alive then return island end
        end
        if #normalCandidates > 0 then
            table.sort(normalCandidates, function(a, b)
                if a.Max ~= b.Max then return a.Max > b.Max end
                return a.Min > b.Min
            end)
            return normalCandidates[1]
        end
        return bossCandidates[1]
    end
    local selectedList = #normalCandidates > 0 and normalCandidates or bossCandidates
    table.sort(selectedList, function(a, b)
        if a.Max ~= b.Max then return a.Max > b.Max end
        return a.Min > b.Min
    end)
    return selectedList[1]
end

-- TrackedQuestFrame = has quest; gone = no quest / completed
-- Text: TrackedQuestFrame.Frame.header.textLabel ContentText e.g. "Defeat 8 Brutes"
BF._questCacheAt = 0
BF._questCacheHas = false
BF._questCacheLabel = nil

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
        return nil
end

BF.hasActiveQuest = function()
    local now = os.clock()
    if now - (BF._questCacheAt or 0) < 0.4 then
        return BF._questCacheHas
    end
    BF._questCacheAt = now
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    BF._questCacheHas = pg ~= nil and pg:FindFirstChild("TrackedQuestFrame") ~= nil
    return BF._questCacheHas
end

BF.invalidateQuestCache = function()
    BF._questCacheAt = 0
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
    local hay = string.lower(tostring(title or "") .. " " .. tostring(body or ""))
    for i = 1, select("#", ...) do
        local n = string.lower(tostring(select(i, ...)))
        if n ~= "" and string.find(hay, n, 1, true) then return true end
    end
    return false
end

-- Does the current TrackedQuest text match this island's mobs / quest id?
BF.questMatchesIsland = function(island, questType)
    if not island then return false end
    if not BF.hasActiveQuest() then return false end
    local _, qtext = BF.getActiveQuestInfo()
    qtext = string.lower(tostring(qtext or ""))
    if qtext == "" then return false end

    local patterns = {}
    if questType == "boss" then
        for _, p in ipairs(island.BossPatterns or {}) do table.insert(patterns, p) end
    else
        for _, p in ipairs(island.EnemyPatterns or {}) do table.insert(patterns, p) end
    end
    for _, p in ipairs(patterns) do
        local pl = string.lower(tostring(p))
        if pl ~= "" and string.find(qtext, pl, 1, true) then
            return true
        end
    end
    -- quest id e.g. BanditQuest1 / HauntedQuest1
    local qa = BF.getQuestArgs and BF.getQuestArgs(island, questType or "normal")
    if qa and qa[2] then
        local id = string.lower(tostring(qa[2]))
        if id ~= "" and string.find(qtext, id, 1, true) then
            return true
        end
    end
    return false
end

BF._lastQuestFixAt = 0
-- Abandon wrong quest and take the right one for this island
BF.ensureCorrectQuest = function(island, questType)
    if config.acceptQuest == false then return false end
    if not island then return false end
    questType = questType or "normal"
    local questArgs = BF.getQuestArgs and BF.getQuestArgs(island, questType)
    if not questArgs then return false end

    if BF.hasActiveQuest() then
        if BF.questMatchesIsland(island, questType) then
            return true
        end
        -- Wrong quest (e.g. old island after level-up) -> drop it
        BF._lastQuestFixAt = os.clock()
        pcall(BF.abandonQuest)
        BF.invalidateQuestCache()
        local abandonDeadline = os.clock() + 2
        repeat
            task.wait(0.1)
            BF.invalidateQuestCache()
        until not BF.hasActiveQuest() or os.clock() >= abandonDeadline
        if BF.hasActiveQuest() then return false end
    end

    if os.clock() - (BF._lastQuestFixAt or 0) < 1.5 then
        return false
    end
    BF._lastQuestFixAt = os.clock()
    local ok = BF.acceptQuest(questArgs)
    BF.invalidateQuestCache()
    local acceptDeadline = os.clock() + 2
    repeat
        task.wait(0.1)
        BF.invalidateQuestCache()
        if BF.questMatchesIsland(island, questType) then return true end
    until os.clock() >= acceptDeadline
    return false
end


BF.resolveFarmPatterns = function(island, questType)
    local patternInfo = BF.getPatterns(island, questType or "normal")
    -- An active quest is the authority for normal farming. Without a verified
    -- matching quest, return no targets instead of farming island/random mobs.
    if not island or not BF.hasActiveQuest()
        or not BF.questMatchesIsland(island, questType or "normal") then
        return { patterns = {}, includeBossAttr = false }
    end
    -- Prefer patterns from the active island that appear in the quest text.
    -- Never fall back to short tokens like "pirate" (breaks "Candy Pirate").
    if BF.hasActiveQuest() then
        local _, qtext = BF.getActiveQuestInfo()
        qtext = string.lower(tostring(qtext or ""))
        if qtext ~= "" then
            local matched = {}
            for _, ep in ipairs(island.EnemyPatterns or {}) do
                local epl = string.lower(tostring(ep))
                if epl ~= "" and string.find(qtext, epl, 1, true) then
                    table.insert(matched, ep)
                end
            end
            if #matched > 0 then
                return { patterns = matched, includeBossAttr = false }
            end
            for _, ep in ipairs(island.BossPatterns or {}) do
                local epl = string.lower(tostring(ep))
                if epl ~= "" and string.find(qtext, epl, 1, true) then
                    table.insert(matched, ep)
                end
            end
            if #matched > 0 then
                return { patterns = matched, includeBossAttr = true }
            end
        end
    end
    -- The quest is valid but its GUI text did not identify a target pattern.
    return { patterns = {}, includeBossAttr = false }
end


BF.resolveFarmIsland = function(level)
    -- Developer island lock
    if config.devIslandLock and config.devIslandIndex and islands[config.devIslandIndex] then
        return islands[config.devIslandIndex]
    end
    if config.bossPriority then
        local bossEnemy, bossIsland = BF.findAnyPriorityBoss(level)
        if bossEnemy and bossIsland then
            return bossIsland
        end
    end
    return BF.getIslandForLevel(level)
end

BF.getIslandIndex = function(island)
    if not island then return nil end
    for i, isl in ipairs(islands) do
        if isl == island or isl.Name == island.Name then
            return i
        end
    end
    return nil
end

BF.devShiftIsland = function(delta)
    local level = BF.getPlayerLevel()
    local cur = BF.resolveFarmIsland(level) or BF.getIslandForLevel(level)
    local idx = BF.getIslandIndex(cur) or 1
    idx = math.clamp(idx + (delta or 1), 1, #islands)
    config.devIslandIndex = idx
    config.devIslandLock = true
    local isl = islands[idx]
    BF.notifyUser("Dev", "Island: " .. tostring(isl and isl.Name or idx), 3)
    return isl
end

BF.devAcceptQuest = function()
    local island = BF.resolveFarmIsland(BF.getPlayerLevel())
    if not island then
        BF.notifyUser("Dev", "No island", 2)
        return
    end
    local qt = "normal"
    if island.isBoss and island.BossQuest then qt = "boss" end
    pcall(function() BF.ensureCorrectQuest(island, qt) end)
    BF.notifyUser("Dev", "Quest for " .. tostring(island.Name), 2)
end

BF.devSkipQuest = function()
    pcall(BF.abandonQuest)
    BF.invalidateQuestCache()
    BF.notifyUser("Dev", "Quest abandoned", 2)
end

BF.devPrintBones = function()
    local rem = ReplicatedStorage:FindFirstChild("Remotes")
    local comm = rem and rem:FindFirstChild("CommF_")
    if not comm then print("[BF] no CommF_") return end
    local results = {}
    for _, args in ipairs({{"Bones","Check"},{"Bones"},{"getInventory"}}) do
        local ok, res = pcall(function() return comm:InvokeServer(unpack(args)) end)
        print("[BF] Invoke", table.concat(args, ","), "ok=", ok, "type=", type(res), "val=", res)
        if type(res) == "table" then
            for k,v in pairs(res) do
                print("  ", k, type(v), v)
                if type(v) == "table" then
                    for k2,v2 in pairs(v) do print("    ", k2, v2) end
                end
            end
        end
    end
    print("[BF] getBoneCount=", BF.getBoneCount())
end


BF.getPatternsFromQuestText = function(text, fallbackPatterns)
    -- Kept for compatibility; resolveFarmPatterns no longer relies on the short-token list.
    text = string.lower(tostring(text or ""))
    if text == "" then return fallbackPatterns end
    if type(fallbackPatterns) == "table" then
        local matched = {}
        for _, ep in ipairs(fallbackPatterns) do
            local epl = string.lower(tostring(ep))
            if epl ~= "" and string.find(text, epl, 1, true) then
                table.insert(matched, ep)
            end
        end
        if #matched > 0 then return matched end
    end
    return fallbackPatterns
end


-- =============================================
-- BOSS DETECTION
-- =============================================
BF.findBossInWorkspace = function(island)
    if not island then return nil end
    local patterns = island.BossPatterns or (island.Name and { island.Name }) or {}
    if #patterns == 0 then return nil end
    local container = Workspace:FindFirstChild("Enemies")
    if not container then return nil end
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local best, bestDist = nil, math.huge
    for _, enemy in ipairs(container:GetChildren()) do
        if enemy:IsA("Model") then
            local humanoid = enemy:FindFirstChildOfClass("Humanoid")
            local root = enemy:FindFirstChild("HumanoidRootPart")
            if humanoid and root and humanoid.Health > 0 then
                local lower = string.lower(enemy.Name)
                for _, pattern in ipairs(patterns) do
                    local p = string.lower(tostring(pattern or ""))
                    if p ~= "" and string.find(lower, p, 1, true) then
                        local d = hrp and (root.Position - hrp.Position).Magnitude or 0
                        if d < bestDist then
                            bestDist = d
                            best = enemy
                        end
                        break
                    end
                end
            end
        end
    end
    return best
end

BF.bossExists = function(island)
    return BF.findBossInWorkspace(island) ~= nil
end

-- Live boss in level range (quest NOT required)
BF.findAnyPriorityBoss = function(level)
    return BF.findLiveBossSimple(level)
end

-- Simple live-boss scan (same idea as popular hubs: scan Enemies for [Boss] name)
BF.findLiveBossSimple = function(level)
    level = tonumber(level) or BF.getPlayerLevel()
    local enemies = Workspace:FindFirstChild("Enemies")
    if not enemies then return nil, nil end
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local best, bestIsl, bestDist = nil, nil, math.huge

    for _, model in ipairs(enemies:GetChildren()) do
        if not model:IsA("Model") then continue end
        local hum = model:FindFirstChildOfClass("Humanoid")
        local root = model:FindFirstChild("HumanoidRootPart")
        if not hum or not root or hum.Health <= 0 then continue end

        local lower = string.lower(model.Name)

        -- Only bosses listed in islands, and only if player level is high enough
        for _, isl in ipairs(islands) do
            if not isl.isBoss then continue end
            local minLv = isl.Min or 0
            local maxLv = isl.Max or 9999
            -- Strict: must meet Min. Small +5 on Max so a level-up mid-fight still finishes.
            if level < minLv or level > maxLv + 5 then
                continue
            end
            local patterns = isl.BossPatterns or { isl.Name }
            for _, p in ipairs(patterns) do
                local pl = string.lower(tostring(p or ""))
                if pl ~= "" and string.find(lower, pl, 1, true) then
                    local d = hrp and (root.Position - hrp.Position).Magnitude or 0
                    if d < bestDist then
                        bestDist = d
                        best = model
                        bestIsl = isl
                    end
                    break
                end
            end
        end
    end
    return best, bestIsl
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
    if not humanoid or humanoid.Health <= 0 or not root then return false end

    local lower = string.lower(enemy.Name)
    local patterns = (patternInfo and patternInfo.patterns) or {}
    local wantBoss = patternInfo and patternInfo.includeBossAttr == true

    local isBossName = enemy:GetAttribute("isBoss") == true
        or string.find(lower, "[boss]", 1, true) ~= nil

    if not wantBoss and isBossName then
        return false
    end

    if #patterns == 0 then
        return wantBoss and isBossName
    end

    for _, pattern in ipairs(patterns) do
        local p = string.lower(tostring(pattern or ""))
        if p ~= "" and string.find(lower, p, 1, true) then
            return true
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

BF._lastWeaponSelectAt = 0
BF.attackTargets = function(targets, speed, hits)
    if not targets or #targets == 0 then return end

    local validTargets = {}
    for _, target in ipairs(targets) do
        if target and target.Parent then
            local hum = target:FindFirstChildOfClass("Humanoid")
            local head = target:FindFirstChild("Head")
                or target:FindFirstChild("UpperTorso")
                or target:FindFirstChild("HumanoidRootPart")
            if hum and hum.Health > 0 and head then
                table.insert(validTargets, target)
            end
        end
    end
    if #validTargets == 0 then return end

        if os.clock() - (BF._lastWeaponSelectAt or 0) > 2 then
        BF._lastWeaponSelectAt = os.clock()
        pcall(BF.selectAttackWeapon)
    end

        local delay = tonumber(speed) or 0.04
    if delay < 0.025 then delay = 0.025 end
    if delay > 0.12 then delay = 0.12 end
    local n = math.max(1, math.floor(tonumber(hits) or 1))
    if n > 50 then n = 50 end

    for _ = 1, n do
        local alive = {}
        for _, target in ipairs(validTargets) do
            local hum = target:FindFirstChildOfClass("Humanoid")
            if target.Parent and hum and hum.Health > 0 then
                table.insert(alive, target)
            end
        end
        if #alive == 0 then break end
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
    BF.safeDisableFly()
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
    BF.safeDisableFly()
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

local function hasMicrochip()
    local bp = LocalPlayer:FindFirstChild("Backpack")
    local ch = LocalPlayer.Character
    for _, name in ipairs({"Special Microchip", "Microchip"}) do
        if (bp and bp:FindFirstChild(name)) or (ch and ch:FindFirstChild(name)) then
            return true
        end
    end
    return false
end

local function selectRaidType(raidName)
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local commF = remotes and remotes:FindFirstChild("CommF_")
    if not commF then return end
    pcall(function()
        commF:InvokeServer("RaidsNpc", "Select", tostring(raidName or "Flame"))
    end)
end

local function buyRaidChip()
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local commF = remotes and remotes:FindFirstChild("CommF_")
    if not commF then return false end
    selectRaidType(config.raidType or "Flame")
    local ok = pcall(function()
        commF:InvokeServer("RaidsNpc", "Buy")
    end)
    return ok
end

local function goToRaidLobby()
    local sea = 1
    pcall(function() sea = tonumber(BF.getCurrentSea()) or 1 end)
    local targetPos = (sea == 3) and RAID_LAB_SEA3 or RAID_LAB_SEA2
    if targetPos then
        pcall(function()
            if not BF.flying then BF.enableFly() end
            BF.setFlyTarget(targetPos + Vector3.new(0, 10, 0), false)
        end)
    end
end

local function tryStartRaid()
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local commF = remotes and remotes:FindFirstChild("CommF_")
    if commF then
        pcall(function()
            commF:InvokeServer("RaidsNpc", "Start")
        end)
    end
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
    BF.safeDisableFly()
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
    BF.startFruitNotifier() -- always scan so Auto Collect / ESP can work

    if config.autoEquip then
        task.spawn(function()
            while BF.farmRunning do
                if config.autoEquip then pcall(BF.autoEquipWeapon) end
                task.wait(1.5)
            end
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
        local underwaterPortalPending = false

        while BF.farmRunning do
            -- Boss hunt (UP/?) fully owns movement + combat; farm waits
            if BF.fruitOwnsFly and type(BF.fruitOwnsFly) == "function" and BF.fruitOwnsFly() then
                task.wait(0.15)
                continue
            end
            if BF.bossHuntOwnsFly and type(BF.bossHuntOwnsFly) == "function" and BF.bossHuntOwnsFly() then
                task.wait(0.2)
                continue
            end
            if BF.bonesOwnsFly and type(BF.bonesOwnsFly) == "function" and BF.bonesOwnsFly() then
                task.wait(0.2)
                continue
            end
            if BF.cakePrinceOwnsFly and type(BF.cakePrinceOwnsFly) == "function" and BF.cakePrinceOwnsFly() then
                task.wait(0.2)
                continue
            end
            local character = LocalPlayer.Character
            if not character then task.wait(0.5) continue end
            local humanoid = character:FindFirstChild("Humanoid")
            if not humanoid or humanoid.Health <= 0 then task.wait(0.5) continue end
            if not BF.flying then BF.enableFly() end
            if config.autoHeal then BF.heal() end
            pcall(BF.ensureBuso)

            local level = BF.getPlayerLevel()
            local island = BF.resolveFarmIsland(level)
            -- Always re-check live boss (works without quest)
            local _prioBoss, _prioIsland = nil, nil
            if config.bossPriority then
                _prioBoss, _prioIsland = BF.findLiveBossSimple(level)
                if _prioBoss and _prioIsland then
                    island = _prioIsland
                end
            end
            local hrp = character:FindFirstChild("HumanoidRootPart")

                        -- This is deliberately scoped to the user's existing "Season 2, 1"
            -- entry and does not alter other level ranges.
            if island and island.Name == "Season 2, 1" then
                island.EnemyPatterns = {"Raider"}
                island.isBoss = false
            end
            if not hrp then task.wait(0.5) continue end

            -- At Lv. 425 the Fishman Lord can be selected before the regular
            -- island state runs. Force the Underwater City portal transition
            -- first, then let boss-priority logic resume inside the city.
            local mustEnterUnderwater = level >= 375 and level <= 450 and not underwaterEntryDone
            if mustEnterUnderwater then
                local underwaterIsland = nil
                for _, candidate in ipairs(islands) do
                    if not candidate.isBoss and BF.isUnderwaterIsland(candidate)
                        and level >= candidate.Min and level <= candidate.Max then
                        underwaterIsland = candidate
                        break
                    end
                end
                if underwaterIsland and BF.isUnderwaterIsland(underwaterIsland) then
                    island = underwaterIsland
                    state = "ISLAND"
                end
            end

            -- ===== BOSS SHORT-CIRCUIT (no quest needed) =====
            -- Same approach as boss-timer hunt: fly above boss + attackEnemy
            if config.bossPriority and not mustEnterUnderwater then
                local liveBoss, liveIsl = _prioBoss, _prioIsland
                if not liveBoss then
                    liveBoss, liveIsl = BF.findLiveBossSimple(level)
                end
                if liveBoss and liveBoss.Parent then
                    local bHum = liveBoss:FindFirstChildOfClass("Humanoid")
                    local bRoot = liveBoss:FindFirstChild("HumanoidRootPart")
                    if bHum and bRoot and bHum.Health > 0 then
                        if liveIsl then island = liveIsl end
                        lockedEnemy = liveBoss
                        isBossTarget = true
                        currentQuestType = "boss"
                        state = "COMBAT"

                        -- Accept the exact boss quest, replacing a normal quest
                        -- from the same quest giver if one is currently active.
                        if liveIsl and liveIsl.BossQuest and (os.clock() - (_lastQuestAcceptAt or 0)) > 6 then
                            _lastQuestAcceptAt = os.clock()
                            pcall(function()
                                BF.ensureCorrectQuest(liveIsl, "boss")
                            end)
                        end

                        if not BF.flying then pcall(BF.enableFly) end
                        local above = math.clamp(config.aboveHeight or 8, 4, 14)
                        local dist = (hrp.Position - bRoot.Position).Magnitude
                        BF.setFlyTarget(bRoot.Position + Vector3.new(0, above, 0), false)

                        if dist <= (config.attackRange or 30) + 15 then
                            local speed = config.bossAttackSpeed or 0.002
                            local hits = config.bossHitsPerCycle or 35
                            pcall(function()
                                BF.attackEnemy(liveBoss, speed, hits)
                            end)
                        end
                        task.wait(0.05)
                        continue
                    end
                end
            end


                        if not _lastStatAt then _lastStatAt = 0 end
            if config.statEnabled and (os.clock() - _lastStatAt) > 2.5 then
                _lastStatAt = os.clock()
                local pts = BF.getAvailableStatPoints()
                if pts and pts > 0 then
                    pcall(function()
                        BF.distributeStats(config.statsToAdd, config.pointsPerStat, true)
                    end)
                end
            end


            -- QUEST gate: don't interrupt boss fights just because no quest is active
            do
                if not _lastQuestAcceptAt then _lastQuestAcceptAt = 0 end
                if BF.hasActiveQuest() then
                    questAccepted = true
                else
                    local fightingBoss = isBossTarget or (lockedEnemy and lockedEnemy.Parent
                        and (lockedEnemy:GetAttribute("isBoss") == true
                            or string.find(string.lower(lockedEnemy.Name), "[boss]", 1, true)))
                    if not fightingBoss and (os.clock() - _lastQuestAcceptAt) >= 8 then
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
                                if not BF.hasActiveQuest() then
                    lockedEnemy = nil
                    BF._submergedTeleported = false
                    heightLocked = false
                    isBossTarget = false
                    underwaterEntryDone = false
                    underwaterEntryStarted = false
                    underwaterPortalPending = false
                    questAccepted = false
                    currentQuestType = "normal"
                    state = "ISLAND"
                    if island.Name ~= BF.lastIslandName then
                        BF.lastIslandName = island.Name
                        BF.notifyUser("New Island", "Now farming: " .. island.Name)
                    end
                else
                                        BF.notifyUser("Level Up", "Finishing current quest first", 3)
                end
            end

            if state == "ISLAND" then
                if not BF.flying then pcall(BF.enableFly) end
                local underwater = BF.isUnderwaterIsland(island)

                -- Submerged 2600+: direkt hin teleportieren, kein Whirlpool-Umweg nötig
                if underwater and level >= 2600 then
                    if not BF._submergedTeleported then
                        BF.notifyUser("Island", "Teleport -> Submerged", 3)
                        BF.teleportCharacterTo(island.Pos)
                        BF._submergedTeleported = true
                        BF.setHoverHeight(hrp.Position.Y)
                        task.wait(0.3)
                        state = "QUEST"
                        continue
                    end
                elseif underwater and not underwaterEntryDone then
                    underwaterEntryStarted = true
                    BF.notifyUser("Underwater City", "Entering through whirlpool...", 3)
                    local entered = BF.enterUnderwaterCity(90)
                    if entered then
                        underwaterEntryDone = true
                        underwaterPortalPending = false
                        local newCharacter = LocalPlayer.Character
                        local newHrp = newCharacter and newCharacter:FindFirstChild("HumanoidRootPart")
                        if newHrp then
                            BF.setHoverHeight(newHrp.Position.Y)
                        end
                        state = "QUEST"
                        continue
                    else
                        -- Never mark the portal as passed on a timeout. Retry
                        -- in place rather than flying away toward the quest giver.
                        underwaterEntryStarted = false
                        BF.disableFly()
                        pcall(function()
                            hrp.AssemblyLinearVelocity = Vector3.zero
                            hrp.AssemblyAngularVelocity = Vector3.zero
                        end)
                        task.wait(1.5)
                        continue
                    end
                end

                local targetPos = island.Pos + Vector3.new(0, 25, 0)
                if (hrp.Position - targetPos).Magnitude > 50 then
                    BF.setFlyTarget(targetPos, false)
                    task.wait(0.2)
                    continue
                else
                    BF.setHoverHeight(hrp.Position.Y)
                    state = "QUEST"
                    continue
                end
            end

            if state == "QUEST" then
                if config.acceptQuest == false then
                    -- With auto quest disabled, wait for the user to accept one.
                    task.wait(0.2)
                    continue
                end

                local desiredType = "normal"
                if _prioBoss and _prioIsland then
                    island = _prioIsland
                    desiredType = "boss"
                elseif island and island.isBoss and BF.bossExists(island) then
                    desiredType = "boss"
                end
                currentQuestType = desiredType

                if BF.hasActiveQuest() and BF.questMatchesIsland(island, desiredType) then
                    questAccepted = true
                    state = "COMBAT"
                    continue
                elseif BF.hasActiveQuest() then
                    pcall(BF.abandonQuest)
                    BF.invalidateQuestCache()
                    local abandonDeadline = os.clock() + 2
                    repeat
                        task.wait(0.1)
                        BF.invalidateQuestCache()
                    until not BF.hasActiveQuest() or os.clock() >= abandonDeadline
                    if BF.hasActiveQuest() then
                        task.wait(0.2)
                        continue
                    end
                end
                if not _lastQuestAcceptAt then _lastQuestAcceptAt = 0 end
                if (os.clock() - _lastQuestAcceptAt) < 1.5 then
                    task.wait(0.2)
                    continue
                end

                                -- center was freezing the client (0 FPS). Hover, zero velocity, wait.
                pcall(function()
                    if hrp then
                        BF.flyTarget = Vector3.new(hrp.Position.X, hrp.Position.Y + 10, hrp.Position.Z)
                        hrp.AssemblyLinearVelocity = Vector3.zero
                        hrp.AssemblyAngularVelocity = Vector3.zero
                    end
                end)
                -- Do NOT disable Enemy ESP preference while accepting quest
                local questArgs = BF.getQuestArgs(island, desiredType)
                -- Boss with no BossQuest: go fight immediately
                if desiredType == "boss" and not questArgs then
                    questAccepted = true
                    currentQuestType = "boss"
                    state = "COMBAT"
                    pcall(BF.restartEnemyEspIfNeeded)
                    continue
                end

                _lastQuestAcceptAt = os.clock()
                if questArgs then
                    local questOk = false
                    pcall(function()
                        questOk = BF.ensureCorrectQuest(island, desiredType)
                    end)
                    currentQuestType = desiredType
                    questAccepted = questOk == true
                    BF.invalidateQuestCache()
                    if not questAccepted then
                        state = "QUEST"
                        task.wait(0.25)
                        continue
                    end
                else
                    state = "QUEST"
                    task.wait(0.5)
                    continue
                end
                pcall(BF.restartEnemyEspIfNeeded)
                -- After taking quest, go to island first if we are far away
                if island and island.Pos and hrp and (hrp.Position - island.Pos).Magnitude > 120 then
                    state = "ISLAND"
                else
                    state = "COMBAT"
                end
                continue
            end

            if state == "COMBAT" then
                if not BF.flying then pcall(BF.enableFly) end
                -- Wrong quest stuck? Fix while farming (e.g. after level-up)
                if not isBossTarget then
                    if not island or not BF.hasActiveQuest()
                        or not BF.questMatchesIsland(island, currentQuestType or "normal") then
                        lockedEnemy = nil
                        BF.clusterStackPos = nil
                        state = "QUEST"
                        task.wait(0.1)
                        continue
                    end
                end
                                -- updated yet.  The quest remote can succeed before the GUI becomes
                -- visible, and at level 700+ this used to leave the farmer parked at
                -- the waypoint instead of acquiring a Raider.
                --
                -- If the quest really is not active, the QUEST state will retry it
                -- after target detection has had a chance to find the configured mob.
                                
                -- Prefer live priority boss (no quest needed)
                local bossEnemy = _prioBoss
                if not bossEnemy and config.bossPriority then
                    bossEnemy = select(1, BF.findAnyPriorityBoss(level))
                end
                if not bossEnemy and island and island.isBoss then
                    bossEnemy = BF.findBossInWorkspace(island)
                end
                if _prioIsland then island = _prioIsland end

                if bossEnemy and bossEnemy.Parent and bossEnemy:FindFirstChildOfClass("Humanoid")
                    and bossEnemy:FindFirstChildOfClass("Humanoid").Health > 0 then
                    lockedEnemy = bossEnemy
                    isBossTarget = true
                    currentQuestType = "boss"
                    -- Ensure the boss objective is active; this also abandons
                    -- a normal quest from the same quest family when needed.
                    if island and island.BossQuest and (os.clock() - (_lastQuestAcceptAt or 0)) > 5 then
                        local _, qtext = BF.getActiveQuestInfo()
                        local qlow = string.lower(tostring(qtext or ""))
                        local hasBossQ = false
                        for _, bp in ipairs(island.BossPatterns or {}) do
                            if string.find(qlow, string.lower(bp), 1, true) then
                                hasBossQ = true
                                break
                            end
                        end
                        if not hasBossQ then
                            _lastQuestAcceptAt = os.clock()
                            pcall(function()
                                BF.ensureCorrectQuest(island, "boss")
                            end)
                        end
                    end
                else
                    isBossTarget = false
                    isBossTarget = false
                    local patternInfo = BF.resolveFarmPatterns(island, "normal")
                    if not patternInfo or not patternInfo.patterns or #patternInfo.patterns == 0 then
                        patternInfo = { patterns = (island and island.EnemyPatterns) or {}, includeBossAttr = false }
                    end
                    local allTargets = BF.getMatchingEnemies(island, patternInfo)
                    if #allTargets == 0 then
                        lockedEnemy = nil
                        -- Enemies not streamed yet: fly to island, don't stand still
                        if not BF.flying then pcall(BF.enableFly) end
                        if island and island.Pos and island.Pos.Magnitude > 0.1 then
                            local hover = math.clamp(config.aboveHeight or 8, 4, 14)
                            BF.setFlyTarget(island.Pos + Vector3.new(0, hover, 0), false)
                        end
                        state = "PATROL"
                        task.wait(0.2)
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
                                                                        local hover = math.clamp(config.aboveHeight or 8, 4, 12)
                                    BF.setFlyTarget(targetPos + Vector3.new(0, hover, 0), false)
                                    heightLocked = false

                                    local patternInfo = BF.resolveFarmPatterns(island, currentQuestType)
                                    local allTargets = BF.getMatchingEnemies(island, patternInfo)
                                    local maxN = config.maxClusterSize or 15
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
                                local hover = math.clamp(config.aboveHeight or 8, 4, 14)
                                BF.setFlyTarget(targetPos + Vector3.new(0, hover, 0), false)
                                BF.attackEnemy(lockedEnemy, speed, hits)
                            end
                                                        task.wait(0.03)
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
                if not BF.flying then pcall(BF.enableFly) end
                -- No matching enemies: path to island spawn area (don't stand still)
                if island and island.Pos and island.Pos.Magnitude > 0.1 then
                    local distIsland = (hrp.Position - island.Pos).Magnitude
                    if distIsland > 80 then
                        local hover = math.clamp(config.aboveHeight or 8, 4, 14)
                        BF.setFlyTarget(island.Pos + Vector3.new(0, hover, 0), false)
                    elseif heightLocked then
                        BF.setFlyTarget(Vector3.new(hrp.Position.X, lockedY, hrp.Position.Z), false)
                    else
                        if not BF.hoverY then BF.hoverY = hrp.Position.Y end
                        BF.setFlyTarget(Vector3.new(hrp.Position.X, BF.hoverY, hrp.Position.Z), false)
                    end
                elseif heightLocked then
                    BF.setFlyTarget(Vector3.new(hrp.Position.X, lockedY, hrp.Position.Z), false)
                else
                    if not BF.hoverY then BF.hoverY = hrp.Position.Y end
                    BF.setFlyTarget(Vector3.new(hrp.Position.X, BF.hoverY, hrp.Position.Z), false)
                end

                local bossEnemy = _prioBoss
                if not bossEnemy and config.bossPriority then
                    bossEnemy = select(1, BF.findAnyPriorityBoss(level))
                end
                if not bossEnemy and island and island.isBoss then
                    bossEnemy = BF.findBossInWorkspace(island)
                end
                if bossEnemy then
                    lockedEnemy = bossEnemy
                    isBossTarget = true
                    if _prioIsland then island = _prioIsland end
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
-- =============================================
-- SEA1 ISLAND SECRETS (Update 30) — auto where possible
-- Sources: Pro Game Guides / community routes
-- Puzzle/combat secrets we can automate:
--   Pirate Village: Windmill (5 ropes), Tavern Pirates
--   Desert: Stone circle / pillars (hit 8)
--   Jungle: hit trees (hat monkey), fly to zipline area
--   Marine Fortress: find rope-like + flag parts
-- Awakened bosses / timed harvests still need player/manual.
-- =============================================
BF.secretsRunning = false
BF.secretsTask = nil
BF._secretDone = {} -- key -> true after one attempt cycle

BF.equipSword = function()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if not hum then return false end
    local tool = char and char:FindFirstChildOfClass("Tool")
    if tool and (tool.ToolTip == "Sword" or string.find(string.lower(tool.Name), "sword", 1, true)) then
        return true
    end
    if bp then
        for _, t in ipairs(bp:GetChildren()) do
            if t:IsA("Tool") then
                local tip = tostring(t.ToolTip or "")
                local n = string.lower(t.Name)
                if tip == "Sword" or string.find(n, "sword", 1, true) or string.find(n, "blade", 1, true)
                    or string.find(n, "cutlass", 1, true) or string.find(n, "katana", 1, true) then
                    hum:EquipTool(t)
                    return true
                end
            end
        end
        -- any melee tool fallback
        for _, t in ipairs(bp:GetChildren()) do
            if t:IsA("Tool") and (t.ToolTip == "Melee" or t.ToolTip == "") then
                hum:EquipTool(t)
                return true
            end
        end
    end
    return false
end

BF.hitPart = function(part)
    if not part then return end
    pcall(function()
        if not BF.flying then BF.enableFly() end
        BF.setFlyTarget(part.Position + Vector3.new(0, 4, 0), false)
    end)
    task.wait(0.4)
    BF.equipSword()
    for _ = 1, 4 do
        pcall(BF.fireVirtualClick)
        pcall(function()
            local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
            if tool then tool:Activate() end
        end)
        if fireclickdetector then
            local cd = part:FindFirstChildOfClass("ClickDetector")
            if not cd and part.Parent then
                cd = part.Parent:FindFirstChildOfClass("ClickDetector")
            end
            if cd then pcall(fireclickdetector, cd) end
        end
        task.wait(0.15)
    end
end

BF.findPartsByKeywords = function(nearPos, radius, keywords)
    local found = {}
    radius = radius or 150
    keywords = keywords or {}
    local function matchName(n)
        n = string.lower(n)
        for _, k in ipairs(keywords) do
            if string.find(n, k, 1, true) then return true end
        end
        return false
    end
    -- prefer Locations / island folders over full map scan when possible
    local roots = { Workspace }
    pcall(function()
        local wo = Workspace:FindFirstChild("_WorldOrigin")
        if wo then table.insert(roots, 1, wo) end
    end)
    for _, root in ipairs(roots) do
        for _, d in ipairs(root:GetDescendants()) do
            if d:IsA("BasePart") and matchName(d.Name) then
                if not nearPos or (d.Position - nearPos).Magnitude <= radius then
                    table.insert(found, d)
                end
            end
        end
        if #found > 0 and root ~= Workspace then break end
    end
    -- if still empty, limited Workspace children only (not full descendants — FPS)
    if #found == 0 and nearPos then
        for _, child in ipairs(Workspace:GetChildren()) do
            if child:IsA("BasePart") and matchName(child.Name) then
                if (child.Position - nearPos).Magnitude <= radius then
                    table.insert(found, child)
                end
            elseif child:IsA("Model") then
                for _, d in ipairs(child:GetDescendants()) do
                    if d:IsA("BasePart") and matchName(d.Name) then
                        if (d.Position - nearPos).Magnitude <= radius then
                            table.insert(found, d)
                        end
                    end
                end
            end
        end
    end
    return found
end

BF.flyTo = function(pos, waitSec)
    pcall(function()
        if not BF.flying then BF.enableFly() end
        BF.setFlyTarget(pos + Vector3.new(0, 10, 0), false)
    end)
    task.wait(waitSec or 2)
end

-- --- Individual secrets ---

BF.secretWindmill = function()
    local key = "windmill"
    if BF._secretDone[key] then return end
    local pos = Vector3.new(-1140, 55, 3975) -- Pirate Village
    BF.notifyUser("Secrets", "Windmill: cutting ropes", 3)
    BF.flyTo(pos, 2.5)
    local ropes = BF.findPartsByKeywords(pos, 180, {"rope", "rigging", "cord", "cable"})
    if #ropes == 0 then
        ropes = BF.findPartsByKeywords(pos, 280, {"rope", "rigging"})
    end
    BF.notifyUser("Secrets", "Ropes: " .. #ropes, 2)
    for _, rope in ipairs(ropes) do
        if not BF.secretsRunning then return end
        BF.hitPart(rope)
    end
    -- claim area: docks NPC
    BF.flyTo(Vector3.new(-1140, 20, 3850), 1.5)
    BF._secretDone[key] = true
end

BF.secretTavern = function()
    local key = "tavern"
    if BF._secretDone[key] then return end
    local pos = Vector3.new(-1200, 35, 4300) -- near Chef / tavern
    BF.notifyUser("Secrets", "Tavern: looking for pirates", 3)
    BF.flyTo(pos, 2)
    local enemies = Workspace:FindFirstChild("Enemies")
    if enemies then
        for _, m in ipairs(enemies:GetChildren()) do
            if not BF.secretsRunning then return end
            local n = string.lower(m.Name)
            if string.find(n, "tavern", 1, true) or string.find(n, "brawler", 1, true) then
                local root = m:FindFirstChild("HumanoidRootPart")
                local hum = m:FindFirstChildOfClass("Humanoid")
                if root and hum and hum.Health > 0 then
                    BF.flyTo(root.Position, 1)
                    for _ = 1, 20 do
                        if not m.Parent or hum.Health <= 0 then break end
                        pcall(function() BF.attackEnemy(m, 0.04, 4) end)
                        task.wait(0.3)
                    end
                end
            end
        end
    end
    BF._secretDone[key] = true
end

BF.secretDesertPillars = function()
    local key = "desert_pillars"
    if BF._secretDone[key] then return end
    local pos = Vector3.new(1100, 20, 4400) -- desert / pyramid area
    BF.notifyUser("Secrets", "Desert: cleaning pillars", 3)
    BF.flyTo(pos, 2.5)
    local pillars = BF.findPartsByKeywords(pos, 220, {
        "pillar", "stone", "monolith", "obelisk", "circle", "rune", "slab"
    })
    BF.notifyUser("Secrets", "Pillars/stones: " .. #pillars, 2)
    for _, p in ipairs(pillars) do
        if not BF.secretsRunning then return end
        BF.hitPart(p)
    end
    BF._secretDone[key] = true
end

BF.secretJungleTrees = function()
    local key = "jungle_trees"
    if BF._secretDone[key] then return end
    local pos = Vector3.new(-1520, 30, 150)
    BF.notifyUser("Secrets", "Jungle: hitting trees (hat)", 3)
    BF.flyTo(pos, 2)
    local trees = BF.findPartsByKeywords(pos, 250, {"tree", "trunk", "leaf", "wood"})
    -- limit hits
    local n = 0
    for _, t in ipairs(trees) do
        if not BF.secretsRunning then return end
        if n >= 25 then break end
        BF.hitPart(t)
        n = n + 1
        -- monkey thief spawn
        local enemies = Workspace:FindFirstChild("Enemies")
        if enemies then
            for _, m in ipairs(enemies:GetChildren()) do
                local ln = string.lower(m.Name)
                if string.find(ln, "monkey", 1, true) and (string.find(ln, "thief", 1, true) or string.find(ln, "hat", 1, true)) then
                    local root = m:FindFirstChild("HumanoidRootPart")
                    local hum = m:FindFirstChildOfClass("Humanoid")
                    if root and hum and hum.Health > 0 then
                        BF.flyTo(root.Position, 1)
                        for _ = 1, 15 do
                            if not m.Parent or hum.Health <= 0 then break end
                            pcall(function() BF.attackEnemy(m, 0.04, 4) end)
                            task.wait(0.25)
                        end
                    end
                end
            end
        end
    end
    BF._secretDone[key] = true
end

BF.secretMarineFlag = function()
    local key = "marine_flag"
    if BF._secretDone[key] then return end
    local pos = Vector3.new(-4800, 30, 4300)
    BF.notifyUser("Secrets", "Marine Fortress: rope/flag", 3)
    BF.flyTo(pos, 2)
    local parts = BF.findPartsByKeywords(pos, 300, {"rope", "flag", "parlus", "pole"})
    for _, p in ipairs(parts) do
        if not BF.secretsRunning then return end
        BF.hitPart(p)
        if fireproximityprompt then
            local pp = p:FindFirstChildOfClass("ProximityPrompt")
            if pp then pcall(fireproximityprompt, pp) end
        end
    end
    BF._secretDone[key] = true
end

BF.runSecretsCycle = function()
    if BF.getCurrentSea and BF.getCurrentSea() ~= "Sea1" and BF.getCurrentSea() ~= 1 then
        local sea = tostring(BF.getCurrentSea and BF.getCurrentSea() or "?")
        if sea ~= "Sea1" and not string.find(sea, "1") then
            BF.notifyUser("Secrets", "Sea1 only (current: " .. sea .. ")", 4)
            task.wait(5)
            return
        end
    end
    BF.secretWindmill()
    if not BF.secretsRunning then return end
    BF.secretTavern()
    if not BF.secretsRunning then return end
    BF.secretDesertPillars()
    if not BF.secretsRunning then return end
    BF.secretJungleTrees()
    if not BF.secretsRunning then return end
    BF.secretMarineFlag()
end

BF.startAutoSecrets = function()
    if BF.secretsRunning then return end
    BF.secretsRunning = true
    BF._secretDone = {}
    BF.notifyUser("Secrets", "Auto Secrets ON (Sea1 puzzles)", 4)
    BF.secretsTask = task.spawn(function()
        while BF.secretsRunning do
            local ok, err = pcall(function()
                if not config.autoSecrets then return end
                BF.runSecretsCycle()
            end)
            if not ok then warn("[BF] secrets:", err) end
            -- full cycle then wait before retrying incomplete ones
            task.wait(15)
            -- allow retry of failed finds after a while
            if os.clock() % 120 < 20 then
                BF._secretDone = {}
            end
        end
    end)
end

BF.stopAutoSecrets = function()
    BF.secretsRunning = false
    if BF.secretsTask then pcall(function() task.cancel(BF.secretsTask) end) BF.secretsTask = nil end
    BF.safeDisableFly()
    BF.notifyUser("Secrets", "Auto Secrets OFF", 2)
end

-- =============================================
-- ENEMY ESP (Highlight + Billboard through walls)
-- =============================================
BF.enemyEspRunning = false
BF.enemyEspTask = nil
BF._enemyEspMap = {} -- model -> {highlight, billboard, label}

BF.clearEnemyEsp = function()
    for model, entry in pairs(BF._enemyEspMap) do
        pcall(function()
            if entry.highlight then entry.highlight:Destroy() end
            if entry.billboard then entry.billboard:Destroy() end
        end)
    end
    BF._enemyEspMap = {}
end

BF.updateEnemyEsp = function()
    if not config.enemyEspEnabled then
        BF.clearEnemyEsp()
        return
    end
    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local maxDist = config.enemyEspMaxDist or 2000
    local folder = Workspace:FindFirstChild("Enemies")
    if not folder then
        BF.clearEnemyEsp()
        return
    end

    local seen = {}
    for _, m in ipairs(folder:GetChildren()) do
        if m:IsA("Model") then
            local hum = m:FindFirstChildOfClass("Humanoid")
            local root = m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart
            if hum and root and hum.Health > 0 then
                local dist = (hrp.Position - root.Position).Magnitude
                if dist <= maxDist then
                    seen[m] = true
                    local entry = BF._enemyEspMap[m]
                    if not entry then
                        local hl = Instance.new("Highlight")
                        hl.Name = "BF_EnemyESP"
                        hl.Adornee = m
                        hl.FillTransparency = 0.55
                        hl.OutlineTransparency = 0
                        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        hl.Parent = m

                        local bb = Instance.new("BillboardGui")
                        bb.Name = "BF_EnemyESP_BB"
                        bb.AlwaysOnTop = true
                        bb.Size = UDim2.new(0, 140, 0, 36)
                        bb.StudsOffset = Vector3.new(0, 3.2, 0)
                        bb.Adornee = root
                        bb.Parent = m

                        local label = Instance.new("TextLabel")
                        label.Size = UDim2.new(1, 0, 1, 0)
                        label.BackgroundTransparency = 0.4
                        label.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
                        label.TextColor3 = Color3.fromRGB(255, 255, 255)
                        label.Font = Enum.Font.GothamBold
                        label.TextSize = 12
                        label.TextStrokeTransparency = 0.4
                        label.Parent = bb

                        entry = { highlight = hl, billboard = bb, label = label }
                        BF._enemyEspMap[m] = entry
                    end

                    local isBoss = string.find(string.lower(m.Name), "boss", 1, true)
                        or m:GetAttribute("IsBoss")
                        or (hum.MaxHealth and hum.MaxHealth >= 50000)
                    if config.enemyEspBossColor and isBoss then
                        entry.highlight.FillColor = Color3.fromRGB(255, 60, 60)
                        entry.highlight.OutlineColor = Color3.fromRGB(255, 200, 80)
                    else
                        entry.highlight.FillColor = Color3.fromRGB(80, 180, 255)
                        entry.highlight.OutlineColor = Color3.fromRGB(200, 230, 255)
                    end

                    local parts = {}
                    if config.enemyEspShowName ~= false then
                        table.insert(parts, m.Name)
                    end
                    if config.enemyEspShowHealth ~= false then
                        table.insert(parts, string.format("%d/%d", math.floor(hum.Health), math.floor(hum.MaxHealth)))
                    end
                    table.insert(parts, string.format("%dm", math.floor(dist)))
                    if entry.label then
                        entry.label.Text = table.concat(parts, "\n")
                    end
                    if entry.billboard and entry.billboard.Adornee ~= root then
                        entry.billboard.Adornee = root
                    end
                end
            end
        end
    end

    -- cleanup dead / out of range
    for model, entry in pairs(BF._enemyEspMap) do
        if not seen[model] then
            pcall(function()
                if entry.highlight then entry.highlight:Destroy() end
                if entry.billboard then entry.billboard:Destroy() end
            end)
            BF._enemyEspMap[model] = nil
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

BF.stopEnemyEsp = function(silent)
    BF.enemyEspRunning = false
    -- only clear user preference when user toggles OFF (silent ~= true)
    if not silent then
        config.enemyEspEnabled = false
    end
    if BF.enemyEspTask then pcall(function() task.cancel(BF.enemyEspTask) end) BF.enemyEspTask = nil end
    pcall(BF.clearEnemyEsp)
    if not silent then
        BF.notifyUser("ESP", "Enemy ESP OFF", 2)
    end
end

BF.restartEnemyEspIfNeeded = function()
    if config.enemyEspEnabled and not BF.enemyEspRunning then
        pcall(BF.startEnemyEsp)
    end
end

-- =============================================
-- VAXORIN UI CREATION (if successful)
-- =============================================


-- =============================================
-- AUTO BONES (Haunted Castle — Sea 3)
-- Bones drop from: Reborn Skeleton, Living Zombie,
-- Demonic Soul, Posessed Mummy (Haunted Castle)
-- =============================================
BF.bonesRunning = false
BF.bonesTask = nil
BF.BONE_POS = Vector3.new(-9504, 172, 6057)
BF.BONE_PATTERNS = {
    "Reborn Skeleton", "Living Zombie", "Demonic Soul",
    "Posessed Mummy", "Possessed Mummy", "Ghost",
}

BF.bonesOwnsFly = function()
    return BF.bonesRunning == true
end

BF.findBoneTargets = function()
    local list = {}
    local seen = {}
    local function consider(m)
        if not m or not m:IsA("Model") or seen[m] then return end
        local hum = m:FindFirstChildOfClass("Humanoid")
        local root = m:FindFirstChild("HumanoidRootPart")
        if not hum or not root or hum.Health <= 0 then return end
        local lower = string.lower(m.Name)
        for _, p in ipairs(BF.BONE_PATTERNS) do
            if string.find(lower, string.lower(p), 1, true) then
                seen[m] = true
                table.insert(list, m)
                return
            end
        end
    end
    local folder = Workspace:FindFirstChild("Enemies")
    if folder then
        for _, m in ipairs(folder:GetChildren()) do
            consider(m)
        end
    end
    -- some builds keep inactive mobs in ReplicatedStorage
    for _, m in ipairs(ReplicatedStorage:GetChildren()) do
        consider(m)
    end
    return list
end

BF.buyBonesRandom = function()
    -- Death King / Random Surprise: CommF_ "Bones","Buy",1,1
    local rem = ReplicatedStorage:FindFirstChild("Remotes")
    local comm = rem and rem:FindFirstChild("CommF_")
    if not comm then return false, "no CommF_" end
    local ok, res = pcall(function()
        return comm:InvokeServer("Bones", "Buy", 1, 1)
    end)
    return ok, res
end

BF.bonesBuyRunning = false
BF.bonesBuyTask = nil
BF.startBonesBuy = function()
    if BF.bonesBuyRunning then return end
    BF.bonesBuyRunning = true
    config.autoBonesBuy = true
    BF.notifyUser("Bones", "Auto Buy Random Surprise ON (50 Bones)", 3)
    BF.bonesBuyTask = task.spawn(function()
        while BF.bonesBuyRunning do
            local ok, err = pcall(function()
                if not config.autoBonesBuy then return end
                local count = 0
                pcall(function() count = BF.getBoneCount() end)
                -- Random Surprise costs 50 bones
                if count >= 50 then
                    local bought, res = BF.buyBonesRandom()
                    if bought then
                        -- silent / light notify
                        pcall(function()
                            BF.notifyUser("Bones", "Bought surprise (left ~" .. tostring(math.max(0, count - 50)) .. ")", 2)
                        end)
                    end
                    task.wait(2.5) -- avoid spam / 2h limit handling by game
                else
                    task.wait(3)
                end
            end)
            if not ok then warn("[BF BonesBuy]", err) end
            task.wait(1.5)
        end
    end)
end

BF.stopBonesBuy = function()
    BF.bonesBuyRunning = false
    config.autoBonesBuy = false
    if BF.bonesBuyTask then pcall(function() task.cancel(BF.bonesBuyTask) end) BF.bonesBuyTask = nil end
    BF.notifyUser("Bones", "Auto Buy OFF", 2)
end

BF.startBonesFarm = function()
    if BF.bonesRunning then return end
    BF.bonesRunning = true
    config.autoBones = true
    BF.notifyUser("Bones", "Auto Bones ON (Haunted Castle)", 3)
    BF.bonesTask = task.spawn(function()
        while BF.bonesRunning do
            local ok, err = pcall(function()
                if not config.autoBones then return end
                local character = LocalPlayer.Character
                local hrp = character and character:FindFirstChild("HumanoidRootPart")
                local hum = character and character:FindFirstChild("Humanoid")
                if not hrp or not hum or hum.Health <= 0 then
                    task.wait(0.5)
                    return
                end
                if not BF.flying then pcall(BF.enableFly) end
                pcall(BF.ensureCombatReady)

                -- Keep correct Haunted quest (abandon wrong ones)
                if config.acceptQuest ~= false then
                    if BF.hasActiveQuest() then
                        if not BF.activeQuestMatches("reborn", "skeleton", "zombie", "demonic", "mummy", "possessed", "posessed", "haunted") then
                            pcall(BF.abandonQuest)
                            BF.invalidateQuestCache()
                            task.wait(0.4)
                            pcall(function()
                                BF.acceptQuest({"StartQuest", "HauntedQuest1", 1})
                            end)
                        end
                    else
                        pcall(function()
                            BF.acceptQuest({"StartQuest", "HauntedQuest1", 1})
                        end)
                    end
                end

                local targets = BF.findBoneTargets()
                if #targets == 0 then
                    BF.setFlyTarget(BF.BONE_POS + Vector3.new(0, 12, 0), false)
                    task.wait(0.25)
                    return
                end

                -- closest target
                local best, bestD = nil, math.huge
                for _, t in ipairs(targets) do
                    local r = t:FindFirstChild("HumanoidRootPart")
                    if r then
                        local d = (hrp.Position - r.Position).Magnitude
                        if d < bestD then bestD = d best = t end
                    end
                end
                if not best then return end

                local root = best:FindFirstChild("HumanoidRootPart")
                local above = math.clamp(config.aboveHeight or 8, 4, 14)
                BF.setFlyTarget(root.Position + Vector3.new(0, above, 0), false)

                local speed = config.attackSpeed or 0.04
                local hits = config.hitsPerCycle or 6
                if config.clusterEnabled then
                    local maxN = config.maxClusterSize or 12
                    local radius = math.max(config.clusterRange or 150, 80)
                    local cluster = BF.collectNearbyTargets(targets, hrp, best, maxN, radius)
                    if #cluster > 0 then
                        if BF.clusterStackPos then
                            BF.setFlyTarget(BF.clusterStackPos + Vector3.new(0, above, 0), false)
                        end
                        BF.attackTargets(cluster, speed, hits)
                    else
                        BF.attackEnemy(best, speed, hits)
                    end
                else
                    BF.attackEnemy(best, speed, hits)
                end
            end)
            if not ok then warn("[BF Bones]", err) end
            task.wait(0.05)
        end
    end)
end

BF.stopBonesFarm = function()
    BF.bonesRunning = false
    config.autoBones = false
    if BF.bonesTask then pcall(function() task.cancel(BF.bonesTask) end) BF.bonesTask = nil end
    BF.safeDisableFly()
    BF.notifyUser("Bones", "Auto Bones OFF", 2)
end

-- =============================================
-- AUTO CAKE PRINCE (Sea of Treats / Cake Land)
-- 1) Kill Cake Land mobs (server share of 500)
-- 2) Talk to drip_mama -> portal / dimension
-- 3) Kill Cake Prince when he spawns
-- =============================================
BF.cakePrinceRunning = false
BF.cakePrinceTask = nil
BF.CAKE_LAND_POS = Vector3.new(-1818, 40, -12958) -- Baking Staff avg / cake area
BF.DRIP_MAMA_POS = Vector3.new(-2150, 50, -12400) -- approx center cake land
BF.CAKE_MOB_PATTERNS = {
    "Cookie Crafter", "Cake Guard", "Baking Staff", "Head Baker",
}
BF.CAKE_BOSS_PATTERNS = {
    "Cake Prince", "Dough King",
}

BF.cakePrinceOwnsFly = function()
    return BF.cakePrinceRunning == true
end

BF.findCakeMobs = function()
    local folder = Workspace:FindFirstChild("Enemies")
    if not folder then return {} end
    local list = {}
    for _, m in ipairs(folder:GetChildren()) do
        if m:IsA("Model") then
            local hum = m:FindFirstChildOfClass("Humanoid")
            local root = m:FindFirstChild("HumanoidRootPart")
            if hum and root and hum.Health > 0 then
                local lower = string.lower(m.Name)
                for _, p in ipairs(BF.CAKE_MOB_PATTERNS) do
                    if string.find(lower, string.lower(p), 1, true) then
                        table.insert(list, m)
                        break
                    end
                end
            end
        end
    end
    return list
end

-- LIVE boss only (Workspace). ReplicatedStorage clones are preloaded and sit at Cake Loaf,
-- so treating them as the fight target yanks the player back down to the portal.
BF.findCakeBoss = function(includeQueued)
    local nameHits = {
        "Cake Prince",
        "Cake Prince [Lv. 2300] [Raid Boss]",
        "Dough King",
        "Dough King [Lv. 2300] [Raid Boss]",
    }
    local function isCakeName(name)
        local lower = string.lower(tostring(name or ""))
        return string.find(lower, "cake prince", 1, true) or string.find(lower, "dough king", 1, true)
    end
    local function collect(container, list, seen)
        if not container then return end
        for _, m in ipairs(container:GetChildren()) do
            if m:IsA("Model") and not seen[m] and isCakeName(m.Name) then
                local hum = m:FindFirstChildOfClass("Humanoid")
                local root = m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart
                if hum and root and hum.Health > 0 then
                    seen[m] = true
                    table.insert(list, m)
                end
            end
        end
        for _, n in ipairs(nameHits) do
            local m = container:FindFirstChild(n)
            if m and m:IsA("Model") and not seen[m] then
                local hum = m:FindFirstChildOfClass("Humanoid")
                local root = m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart
                if hum and root and hum.Health > 0 then
                    seen[m] = true
                    table.insert(list, m)
                end
            end
        end
    end
    local function pickClosest(list)
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if #list == 0 then return nil end
        if not hrp then return list[1] end
        local best, bestD, fallback, fallbackD = nil, math.huge, nil, math.huge
        for _, m in ipairs(list) do
            local root = m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart
            if root then
                local d = (hrp.Position - root.Position).Magnitude
                if d < fallbackD then
                    fallback, fallbackD = m, d
                end
                -- Ignore loaf-level dummies while we are already in the sky arena.
                if not (hrp.Position.Y > 180 and root.Position.Y < hrp.Position.Y - 70) then
                    if d < bestD then
                        best, bestD = m, d
                    end
                end
            end
        end
        return best or fallback
    end

    local seen, live = {}, {}
    collect(Workspace:FindFirstChild("Enemies"), live, seen)
    collect(Workspace:FindFirstChild("Characters"), live, seen)
    collect(Workspace, live, seen)
    local chosen = pickClosest(live)
    if chosen then return chosen end
    if includeQueued then
        local queued, qSeen = {}, {}
        collect(ReplicatedStorage, queued, qSeen)
        return queued[1]
    end
    return nil
end

BF.isCakeBossQueued = function()
    return BF.findCakeBoss(true) ~= nil and BF.findCakeBoss(false) == nil
end

BF.getCakeMirrorPortalPart = function()
    local map = Workspace:FindFirstChild("Map")
    local loaf = map and map:FindFirstChild("CakeLoaf")
    local mirror = loaf and loaf:FindFirstChild("BigMirror")
    if mirror then
        local other = mirror:FindFirstChild("Other") or mirror:FindFirstChild("Portal") or mirror:FindFirstChildWhichIsA("BasePart")
        if other then return other end
    end
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name == "BigMirror" then
            local p = obj:FindFirstChild("Other") or obj:FindFirstChild("Portal") or obj:FindFirstChildWhichIsA("BasePart")
            if p then return p end
        end
    end
    return nil
end

BF.isCakePortalOpen = function()
    local part = BF.getCakeMirrorPortalPart()
    if part and part:IsA("BasePart") then
        return part.Transparency <= 0.05
    end
    return false
end

BF.getCakePortalCFrame = function()
    local part = BF.getCakeMirrorPortalPart()
    if part and part:IsA("BasePart") then
        return part.CFrame
    end
    return CFrame.new(-2151.82, 149.32, -12404.91)
end

BF.getCakeArenaTeleporter = function()
    local function fromInst(inst)
        if not inst then return nil end
        if inst:IsA("BasePart") then return inst end
        return inst:FindFirstChildWhichIsA("BasePart", true)
    end
    local map = Workspace:FindFirstChild("Map")
    local loaf = map and map:FindFirstChild("CakeLoaf")
    local containers = { loaf }
    for _, container in ipairs(containers) do
        if container then
            for _, inst in ipairs(container:GetDescendants()) do
                local n = string.lower(inst.Name)
                if n == "teleporter" or n == "teleport" or n == "cakeprinceteleporter" then
                    local part = fromInst(inst)
                    if part then return part end
                end
            end
        end
    end
    return nil
end

BF.holdCakeFly = function(pos)
    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not pos and hrp then
        pos = hrp.Position + Vector3.new(0, 6, 0)
    end
    if pos then
        BF.setFlyTarget(pos, false)
    end
end

BF.isPlayerInCakeArena = function()
    if BF._cakeNeedPortal then return false end
    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    local portal = BF.getCakeMirrorPortalPart()
    local portalPos = (portal and portal:IsA("BasePart") and portal.Position) or Vector3.new(-2151.82, 149.32, -12404.91)
    local horiz = Vector3.new(hrp.Position.X - portalPos.X, 0, hrp.Position.Z - portalPos.Z).Magnitude

    -- Sky arena only: well above the loaf portal. Spawn/death is always at loaf height.
    if hrp.Position.Y > portalPos.Y + 30 and horiz < 450 then
        return true
    end

    local live = BF.findCakeBoss(false)
    if live then
        local root = live:FindFirstChild("HumanoidRootPart") or live.PrimaryPart
        if root and (hrp.Position - root.Position).Magnitude < 90 then
            return true
        end
    end
    return false
end

BF.resetCakeArenaState = function()
    BF._cakeInsideArena = false
    BF._cakePortalEnteredAt = 0
    BF._cakeLastY = nil
    BF._isCakeDodging = false
    BF._cakeNeedPortal = true
end

BF.enterCakeMirrorPortal = function(force)
    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    -- Already up in the isolated arena: never pull back down to the loaf portal.
    if not force and not BF._cakeNeedPortal and BF.isPlayerInCakeArena() then
        BF.holdCakeFly(hrp.Position + Vector3.new(0, 8, 0))
        return true
    end

    local portalPart = BF.getCakeMirrorPortalPart()
    local portalCFrame = portalPart and portalPart.CFrame or BF.getCakePortalCFrame()
    local portalPos = portalCFrame.Position

    local dist = (hrp.Position - portalPos).Magnitude
    -- After death we snap straight to the portal instead of slowly flying up from spawn.
    if force or BF._cakeNeedPortal or dist > 25 then
        pcall(function()
            hrp.CFrame = CFrame.new(portalPos + Vector3.new(0, 3, 0))
            hrp.AssemblyLinearVelocity = Vector3.zero
        end)
        dist = 0
    end
    BF.setFlyTarget(portalPos + Vector3.new(0, 3, 0), false)

    if dist < 25 then
        pcall(function()
            if portalPart and portalPart:IsA("BasePart") and firetouchinterest then
                firetouchinterest(hrp, portalPart, 0)
                task.wait(0.05)
                firetouchinterest(hrp, portalPart, 1)
            else
                hrp.CFrame = portalCFrame
            end
        end)
        -- Release the portal fly target so an in-game teleporter can send us up.
        task.wait(0.15)
        hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            BF.holdCakeFly(hrp.Position + Vector3.new(0, 8, 0))
        end
        BF._cakePortalEnteredAt = os.clock()
    end
    return true
end

BF.useCakeArenaTeleporter = function()
    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    if BF.isPlayerInCakeArena() then
        -- If we are already high, do not walk back to a pad near the portal.
        local portal = BF.getCakeMirrorPortalPart()
        local portalY = (portal and portal:IsA("BasePart") and portal.Position.Y) or 149
        if hrp.Position.Y > portalY + 30 then
            return false
        end
    end
    local pad = BF.getCakeArenaTeleporter()
    if not pad then return false end
    BF.setFlyTarget(pad.Position + Vector3.new(0, 3, 0), false)
    if (hrp.Position - pad.Position).Magnitude < 20 then
        pcall(function()
            if firetouchinterest then
                firetouchinterest(hrp, pad, 0)
                task.wait(0.05)
                firetouchinterest(hrp, pad, 1)
            else
                hrp.CFrame = pad.CFrame + Vector3.new(0, 3, 0)
            end
        end)
        task.wait(0.2)
        hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            BF.holdCakeFly(hrp.Position + Vector3.new(0, 8, 0))
        end
        return true
    end
    return true
end

BF.cakePrinceSpawnerStatus = function()
    local rem = ReplicatedStorage:FindFirstChild("Remotes")
    local comm = rem and rem:FindFirstChild("CommF_")
    if not comm then return nil end
    local ok, res = pcall(function()
        return comm:InvokeServer("CakePrinceSpawner")
    end)
    if ok then return res end
    return nil
end

BF.tryOpenCakePortal = function()
    local rem = ReplicatedStorage:FindFirstChild("Remotes")
    local comm = rem and rem:FindFirstChild("CommF_")
    if not comm then return false end
    local ok, status = pcall(function()
        return comm:InvokeServer("CakePrinceSpawner")
    end)
    if ok and type(status) == "string" then
        local low = string.lower(status)
        if string.find(low, "open the portal", 1, true) or string.find(low, "portal now", 1, true) then
            pcall(function()
                comm:InvokeServer("CakePrinceSpawner")
            end)
            return true
        end
    end
    pcall(function()
        comm:InvokeServer("CakePrinceSpawner", true)
    end)
    pcall(function()
        comm:InvokeServer("CakePrinceSpawner")
    end)
    return BF.isCakePortalOpen()
end

BF.findDripMama = function()
    local names = {"drip_mama", "Drip Mama", "drip mama", "DripMama"}
    for _, n in ipairs(names) do
        local npc = Workspace:FindFirstChild(n, true)
        if npc then return npc end
    end
    for _, inst in ipairs(Workspace:GetDescendants()) do
        local nm = string.lower(inst.Name)
        if string.find(nm, "drip", 1, true) and string.find(nm, "mama", 1, true) then
            return inst
        end
    end
    return nil
end

BF.tryTalkDripMama = function()
    local npc = BF.findDripMama()
    if not npc then return false end
    local part = npc:IsA("BasePart") and npc
        or npc:FindFirstChild("HumanoidRootPart")
        or npc:FindFirstChildWhichIsA("BasePart")
    if part then
        pcall(function()
            BF.setFlyTarget(part.Position + Vector3.new(0, 4, 0), false)
        end)
    end
    local fired = false
    local root = npc
    if not npc:IsA("Model") and npc.Parent then root = npc.Parent end
    for _, d in ipairs(root:GetDescendants()) do
        if d:IsA("ProximityPrompt") then
            pcall(function()
                if fireproximityprompt then
                    fireproximityprompt(d)
                else
                    d:InputHoldBegin()
                    task.wait(d.HoldDuration or 0.1)
                    d:InputHoldEnd()
                end
            end)
            fired = true
        end
    end
    for _, d in ipairs(root:GetDescendants()) do
        if d:IsA("ClickDetector") then
            pcall(function()
                if fireclickdetector then fireclickdetector(d) end
            end)
            fired = true
        end
    end
    pcall(function()
        local rem = ReplicatedStorage:FindFirstChild("Remotes")
        local comm = rem and rem:FindFirstChild("CommF_")
        if comm then
            comm:InvokeServer("CakePrince")
            comm:InvokeServer("TalkNpc", "drip_mama")
        end
    end)
    return fired
end

-- V-ATTACK DODGE & COMBAT EVASION ENGINE
BF._lastCakeDodgeAt = 0
BF._isCakeDodging = false
BF._cakeNeedPortal = false
BF._cakeDodgeCooldown = 0.85
BF._cakeDodgeMin = 0.45
BF._cakeDodgeDuration = 1.15
BF._cakeAttackAboveHeight = 4
BF._cakeDodgeHeight = 95
BF._cakeVKeywords = {
    "barrage", "fusillade", "restless", "roller", "fusilade",
    "ult", "aoe", "vattack", "v-attack", "move4",
}
BF._cakeLastHp = nil
BF._cakeLastHpAt = 0

local function cakeAnimLooksDangerous(text)
    text = string.lower(tostring(text or ""))
    if text == "" then return false end
    if string.find(text, "idle") or string.find(text, "walk") or string.find(text, "run") or string.find(text, "jump") then
        return false
    end
    for _, kw in ipairs(BF._cakeVKeywords) do
        if string.find(text, kw, 1, true) then
            return true
        end
    end
    return false
end

BF.isCakeBossAttacking = function(boss)
    if not boss then return false, false end
    local hum = boss:FindFirstChildOfClass("Humanoid")
    if not hum then return false, false end

    local isV = false
    local isAnyAttack = false

    pcall(function()
        local tracks = hum:GetPlayingAnimationTracks()
        for _, t in ipairs(tracks) do
            if t.IsPlaying and (t.Speed or 1) > 0.05 then
                local anim = t.Animation
                local blobs = {
                    t.Name,
                    anim and anim.Name,
                }
                for _, blob in ipairs(blobs) do
                    local s = string.lower(tostring(blob or ""))
                    if s ~= "" and not string.find(s, "idle") and not string.find(s, "walk") and not string.find(s, "run") then
                        isAnyAttack = true
                    end
                    if cakeAnimLooksDangerous(blob) then
                        isV = true
                        isAnyAttack = true
                        break
                    end
                end
                if isV then break end
            end
        end
    end)

    -- Large aura / hitbox around the boss = Fusillade V, not random loaf props.
    if not isV then
        pcall(function()
            local bRoot = boss:FindFirstChild("HumanoidRootPart") or boss.PrimaryPart
            if not bRoot then return end
            local bPos = bRoot.Position
            for _, child in ipairs(Workspace:GetChildren()) do
                if child ~= boss and child:IsA("BasePart") and child.Size.Magnitude > 55 then
                    if (child.Position - bPos).Magnitude < 45 then
                        isV = true
                        isAnyAttack = true
                        break
                    end
                end
            end
        end)
    end

    return isV, isAnyAttack
end

BF.cakeHealthSpike = function()
    local character = LocalPlayer.Character
    local hum = character and character:FindFirstChild("Humanoid")
    if not hum then return false end
    local now = os.clock()
    local hp = hum.Health
    local last = BF._cakeLastHp
    BF._cakeLastHp = hp
    local dt = now - (BF._cakeLastHpAt or 0)
    BF._cakeLastHpAt = now
    if last and dt > 0 and dt < 0.5 and hum.MaxHealth > 0 then
        local drop = (last - hp) / hum.MaxHealth
        if drop >= 0.12 then
            return true
        end
    end
    return false
end

BF.enableCakeKen = function()
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, "E", false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, "E", false, game)
    end)
    pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        local commF = remotes and remotes:FindFirstChild("CommF_")
        local commE = remotes and remotes:FindFirstChild("CommE")
        if commF then commF:InvokeServer("Ken", true) end
        if commE then commE:FireServer("Ken", true) end
    end)
end

BF.snapCakeTo = function(pos)
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp or not pos then return end
    pcall(function()
        hrp.CFrame = CFrame.new(pos)
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end)
    BF.setFlyTarget(pos, false)
end

BF.dodgeCakeBoss = function(boss, root)
    if not boss or not root or not root.Parent then return false end
    if BF._isCakeDodging then
        BF.snapCakeTo(root.Position + Vector3.new(0, BF._cakeDodgeHeight, 0))
        return true
    end

    local now = os.clock()
    if (now - BF._lastCakeDodgeAt) < BF._cakeDodgeCooldown then
        return false
    end

    BF._isCakeDodging = true
    BF._lastCakeDodgeAt = now
    pcall(BF.enableCakeKen)

    local dodgeStart = os.clock()
    while os.clock() - dodgeStart < BF._cakeDodgeDuration and BF.cakePrinceRunning and not BF._cakeNeedPortal do
        if not root or not root.Parent then break end
        BF.snapCakeTo(root.Position + Vector3.new(0, BF._cakeDodgeHeight, 0))
        local elapsed = os.clock() - dodgeStart
        local stillV = select(1, BF.isCakeBossAttacking(boss))
        if elapsed >= BF._cakeDodgeMin and not stillV then
            break
        end
        task.wait(0.04)
    end

    -- Instant drop back into melee — do not fly down slowly from dodge height.
    if root and root.Parent then
        BF.snapCakeTo(root.Position + Vector3.new(0, BF._cakeAttackAboveHeight, 2))
    end
    BF._isCakeDodging = false
    BF._lastCakeDodgeAt = os.clock()
    return true
end

BF.attackCakeBoss = function(boss, root)
    if BF._isCakeDodging or BF._cakeNeedPortal then return end
    if not boss or not root then return end
    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local attackPos = root.Position + Vector3.new(0, BF._cakeAttackAboveHeight, 2)
    -- If we are still high from a dodge, snap down immediately.
    if math.abs(hrp.Position.Y - attackPos.Y) > 12 or (hrp.Position - attackPos).Magnitude > 18 then
        BF.snapCakeTo(attackPos)
    else
        BF.setFlyTarget(attackPos, false)
    end

    pcall(BF.ensureCombatReady)
    BF.attackEnemy(boss, 0.03, 4)
    pcall(function()
        BF.fireVirtualClick()
    end)
end
BF._cakeInsideArena = false
BF._cakePortalEnteredAt = 0
BF._cakeLastY = nil
BF._cakeDiedConn = nil
BF._cakeAddedConn = nil

BF.hookCakePrinceRespawn = function()
    if BF._cakeDiedConn then pcall(function() BF._cakeDiedConn:Disconnect() end) BF._cakeDiedConn = nil end
    if BF._cakeAddedConn then pcall(function() BF._cakeAddedConn:Disconnect() end) BF._cakeAddedConn = nil end

    local function onDied()
        BF.resetCakeArenaState()
        BF.notifyUser("Cake Prince", "Died — going through portal again", 2)
    end

    local function attachDied(char)
        if BF._cakeDiedConn then
            pcall(function() BF._cakeDiedConn:Disconnect() end)
            BF._cakeDiedConn = nil
        end
        local hum = char and (char:FindFirstChild("Humanoid") or char:WaitForChild("Humanoid", 8))
        if hum then
            BF._cakeDiedConn = hum.Died:Connect(onDied)
        end
    end

    if LocalPlayer.Character then
        attachDied(LocalPlayer.Character)
    end
    BF._cakeAddedConn = LocalPlayer.CharacterAdded:Connect(function(char)
        if not BF.cakePrinceRunning then return end
        BF.resetCakeArenaState()
        task.wait(0.7)
        if not BF.cakePrinceRunning then return end
        attachDied(char)
        pcall(BF.enableFly)
        pcall(function()
            BF.enterCakeMirrorPortal(true)
        end)
    end)
end

BF.startCakePrince = function()
    if BF.cakePrinceRunning then return end
    BF.cakePrinceRunning = true
    config.autoCakePrince = true
    BF._cakeInsideArena = false
    BF._cakePortalEnteredAt = 0
    BF._cakeLastY = nil
    BF._isCakeDodging = false
    BF._cakeNeedPortal = false
    BF._cakeLastHp = nil
    pcall(BF.hookCakePrinceRespawn)
    BF.notifyUser("Cake Prince", "Auto Cake Prince ON", 3)
    local lastTalk = 0
    BF.cakePrinceTask = task.spawn(function()
        while BF.cakePrinceRunning do
            local ok, err = pcall(function()
                if not config.autoCakePrince then return end
                local character = LocalPlayer.Character
                local hrp = character and character:FindFirstChild("HumanoidRootPart")
                local hum = character and character:FindFirstChild("Humanoid")
                if not hrp or not hum or hum.Health <= 0 then
                    BF.resetCakeArenaState()
                    task.wait(0.5)
                    return
                end
                if not BF.flying then pcall(BF.enableFly) end
                pcall(BF.ensureCombatReady)

                -- Detect the in-game pad teleporting us into the sky arena.
                local lastY = BF._cakeLastY
                BF._cakeLastY = hrp.Position.Y
                if lastY and (hrp.Position.Y - lastY) > 25 then
                    BF._cakeInsideArena = true
                    BF._cakeNeedPortal = false
                    BF._cakePortalEnteredAt = os.clock()
                    BF.holdCakeFly(hrp.Position + Vector3.new(0, 8, 0))
                end

                local inArena = BF.isPlayerInCakeArena()
                if inArena then
                    BF._cakeInsideArena = true
                    BF._cakeNeedPortal = false
                end

                -- After death: snap through the portal, never fly slowly up to the boss.
                if BF._cakeNeedPortal then
                    BF.enterCakeMirrorPortal(true)
                    pcall(BF.useCakeArenaTeleporter)
                    task.wait(0.2)
                    return
                end

                -- 1) Fight the LIVE boss only (never the ReplicatedStorage dummy).
                local boss = BF.findCakeBoss(false)
                if boss then
                    local root = boss:FindFirstChild("HumanoidRootPart") or boss.PrimaryPart
                    if root then
                        local dist = (hrp.Position - root.Position).Magnitude

                        if dist > 220 then
                            if inArena then
                                BF.snapCakeTo(root.Position + Vector3.new(0, 10, 0))
                                return
                            end
                            BF.notifyUser("Cake Prince", "Boss spawned — entering portal", 2)
                            BF.enterCakeMirrorPortal(true)
                            pcall(BF.useCakeArenaTeleporter)
                            task.wait(0.25)
                            return
                        end

                        BF._cakeInsideArena = true
                        BF._cakeNeedPortal = false

                        if hum.Health < hum.MaxHealth * 0.35 then
                            BF.snapCakeTo(root.Position + Vector3.new(0, BF._cakeDodgeHeight, 0))
                            if config.autoHeal then pcall(BF.heal) end
                            task.wait(0.25)
                            return
                        end

                        local isV = select(1, BF.isCakeBossAttacking(boss))
                        local spike = BF.cakeHealthSpike()
                        if isV or spike or BF._isCakeDodging then
                            local did = BF.dodgeCakeBoss(boss, root)
                            if not did then
                                BF.snapCakeTo(root.Position + Vector3.new(0, BF._cakeDodgeHeight, 0))
                            end
                            return
                        end

                        BF.attackCakeBoss(boss, root)
                    end
                    return
                end

                -- 2) Inside the dimension with no live boss yet: wait / use pad. Never portal-loop.
                if inArena or (os.clock() - (BF._cakePortalEnteredAt or 0)) < 12 then
                    local usedPad = false
                    pcall(function()
                        usedPad = BF.useCakeArenaTeleporter()
                    end)
                    if not usedPad then
                        local hrp2 = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if hrp2 then
                            BF.holdCakeFly(hrp2.Position + Vector3.new(0, 8, 0))
                        end
                    end
                    task.wait(0.2)
                    return
                end

                -- 3) Portal open on Cake Loaf -> step in, then release fly so the pad can send us up.
                if BF.isCakePortalOpen() or BF.isCakeBossQueued() then
                    BF.notifyUser("Cake Prince", "Portal is OPEN! Stepping inside...", 2)
                    BF.enterCakeMirrorPortal()
                    pcall(BF.useCakeArenaTeleporter)
                    task.wait(0.4)
                    return
                end

                -- 4) Open portal / talk to Drip Mama
                if os.clock() - lastTalk > 4 then
                    lastTalk = os.clock()
                    local opened = BF.tryOpenCakePortal()
                    if opened then
                        BF.enterCakeMirrorPortal()
                        return
                    end
                    pcall(BF.tryTalkDripMama)
                end

                -- 5) Farm Cake Land mobs toward 500 server kills
                BF._cakeInsideArena = false
                local mobs = BF.findCakeMobs()
                if #mobs == 0 then
                    BF.setFlyTarget(BF.CAKE_LAND_POS + Vector3.new(0, 12, 0), false)
                    task.wait(0.25)
                    return
                end

                local best, bestD = nil, math.huge
                for _, t in ipairs(mobs) do
                    local r = t:FindFirstChild("HumanoidRootPart")
                    if r then
                        local d = (hrp.Position - r.Position).Magnitude
                        if d < bestD then bestD = d best = t end
                    end
                end
                if not best then return end

                local root = best:FindFirstChild("HumanoidRootPart")
                local above = math.clamp(config.aboveHeight or 8, 4, 14)
                BF.setFlyTarget(root.Position + Vector3.new(0, above, 0), false)

                local speed = config.attackSpeed or 0.04
                local hits = config.hitsPerCycle or 6
                if config.clusterEnabled then
                    local maxN = config.maxClusterSize or 12
                    local radius = math.max(config.clusterRange or 150, 80)
                    local cluster = BF.collectNearbyTargets(mobs, hrp, best, maxN, radius)
                    if #cluster > 0 then
                        if BF.clusterStackPos then
                            BF.setFlyTarget(BF.clusterStackPos + Vector3.new(0, above, 0), false)
                        end
                        BF.attackTargets(cluster, speed, hits)
                    else
                        BF.attackEnemy(best, speed, hits)
                    end
                else
                    BF.attackEnemy(best, speed, hits)
                end
            end)
            if not ok then warn("[BF CakePrince]", err) end
            task.wait(0.04)
        end
    end)
end

BF.stopCakePrince = function()
    BF.cakePrinceRunning = false
    config.autoCakePrince = false
    BF._isCakeDodging = false
    BF._cakeInsideArena = false
    BF._cakeNeedPortal = false
    if BF._cakeDiedConn then pcall(function() BF._cakeDiedConn:Disconnect() end) BF._cakeDiedConn = nil end
    if BF._cakeAddedConn then pcall(function() BF._cakeAddedConn:Disconnect() end) BF._cakeAddedConn = nil end
    if BF.cakePrinceTask then pcall(function() task.cancel(BF.cakePrinceTask) end) BF.cakePrinceTask = nil end
    BF.safeDisableFly()
    BF.notifyUser("Cake Prince", "Auto Cake Prince OFF", 2)
end



-- =============================================
-- STATUS HELPERS (UI labels)
-- =============================================
BF.getBoneCount = function()
    local rem = ReplicatedStorage:FindFirstChild("Remotes")
    local comm = rem and rem:FindFirstChild("CommF_")

    local function fromItem(item, depth)
        depth = depth or 0
        if depth > 4 then return nil end
        if type(item) == "number" then return item end
        if type(item) ~= "table" then return nil end
        local name = string.lower(tostring(item.Name or item.name or item.Item or item.item or ""))
        local c = item.Count or item.count or item.Amount or item.amount
            or item.Value or item.value or item.Quantity or item.quantity
            or item.Total or item.total or item.Bones or item.bones
        if (name == "bones" or name == "bone" or name == "") and c ~= nil then
            local n = tonumber(c)
            if n then return n end
        end
        -- deep scan values (Bones Check sometimes returns nested table)
        for k, v in pairs(item) do
            local kl = string.lower(tostring(k))
            if kl == "bones" or kl == "bone" or kl == "count" then
                if type(v) == "number" then return v end
            end
            if type(v) == "table" then
                local n = fromItem(v, depth + 1)
                if n then return n end
            end
        end
        return nil
    end

    if comm then
        -- Hub: CommF_ "Bones","Check"
        for _, args in ipairs({
            {"Bones", "Check"},
            {"Bones"},
            {"CheckBones"},
        }) do
            local ok, n = pcall(function()
                return comm:InvokeServer(unpack(args))
            end)
            if ok then
                if type(n) == "number" then return n end
                if type(n) == "string" then
                    local num = tonumber((string.match(n, "(%d+)") or n))
                    if num then return num end
                end
                if type(n) == "table" then
                    local c = fromItem(n) or n.Count or n.Bones or n.bones
                    if type(c) == "number" then return c end
                end
            end
        end

        -- Full inventory scan (array or map)
        local ok2, inv = pcall(function()
            return comm:InvokeServer("getInventory")
        end)
        if ok2 and type(inv) == "table" then
            for key, item in pairs(inv) do
                if type(key) == "string" and string.lower(key) == "bones" then
                    if type(item) == "number" then return item end
                    local c = fromItem(item)
                    if c then return c end
                end
                local c = fromItem(item)
                if c then return c end
            end
        end
    end

    -- LocalPlayer.Data / attributes
    local data = LocalPlayer:FindFirstChild("Data")
    if data then
        for _, n in ipairs({"Bones", "Bone", "bones", "TotalBones"}) do
            local v = data:FindFirstChild(n)
            if v then
                if type(v.Value) == "number" then return v.Value end
                if typeof(v) == "NumberValue" or typeof(v) == "IntValue" then return v.Value end
            end
        end
        local attr = data:GetAttribute("Bones")
        if type(attr) == "number" then return attr end
    end
    local attr2 = LocalPlayer:GetAttribute("Bones")
    if type(attr2) == "number" then return attr2 end

    return 0
end

BF.getCakeEnemiesLeft = function()
    local status = nil
    if type(BF.cakePrinceSpawnerStatus) == "function" then
        status = BF.cakePrinceSpawnerStatus()
    end
    if type(status) == "string" then
        local n = string.match(status, "(%d+)")
        if n then return tonumber(n) end
        local low = string.lower(status)
        if string.find(low, "portal", 1, true) or string.find(low, "spawn", 1, true) then
            return 0
        end
    elseif type(status) == "number" then
        return status
    end
    return nil
end

BF._statusLabels = BF._statusLabels or {}
BF._statusRunning = false

BF.updateStatusLabels = function()
    local labs = BF._statusLabels
    if not labs then return end

    local function setStat(handle, value)
        if not handle then return end
        -- CyberUI Stat:Set(value, delta?)
        pcall(function() handle:Set(tostring(value)) end)
    end
    local function setPara(handle, text)
        if not handle then return end
        -- CyberUI Paragraph:Set(content: string)  -- NOT a table
        pcall(function() handle:Set(tostring(text)) end)
    end

    -- Level
    setStat(labs.level, BF.getPlayerLevel())

    -- Quest text
    local qtext = "None"
    pcall(function()
        if BF.hasActiveQuest() then
            local _, t = BF.getActiveQuestInfo()
            qtext = (t and t ~= "" and t) or "(active)"
        end
    end)
    setPara(labs.quest, qtext)

    -- Enemy / island
    local enemyName = "-"
    pcall(function()
        local level = BF.getPlayerLevel()
        local island = (BF.resolveFarmIsland and BF.resolveFarmIsland(level)) or BF.getIslandForLevel(level)
        if island then
            local pats = island.EnemyPatterns or {}
            enemyName = (#pats > 0 and table.concat(pats, ", ")) or island.Name or "-"
            if island.Name and #pats > 0 then
                enemyName = island.Name .. " → " .. table.concat(pats, ", ")
            end
        end
    end)
    setPara(labs.enemy, enemyName)

    -- Cake enemies left
    local left = BF.getCakeEnemiesLeft()
    if left == nil then
        setStat(labs.cakeLeft, "?")
    elseif left <= 0 then
        setStat(labs.cakeLeft, "0 (ready)")
    else
        setStat(labs.cakeLeft, left)
    end

    -- Bones
    local bones = 0
    pcall(function() bones = BF.getBoneCount() end)
    setStat(labs.bones, bones)

    -- Dev island
    if labs.devIsland then
        local isl = nil
        pcall(function() isl = BF.resolveFarmIsland(BF.getPlayerLevel()) end)
        local s = isl and (tostring(isl.Name) .. (config.devIslandLock and " [LOCKED]" or "")) or "-"
        setPara(labs.devIsland, s)
    end
end

BF.startStatusUpdater = function()
    if BF._statusRunning then return end
    BF._statusRunning = true
    task.spawn(function()
        while BF._statusRunning do
            pcall(BF.updateStatusLabels)
            task.wait(1.0)
        end
    end)
end

-- =============================================
-- FPS BOOSTER + ISLAND FLY
-- =============================================
BF.fpsBoostOn = false

BF._fpsConn = nil
BF._fpsWhite = false

BF.applyFpsBoost = function(on)
    BF.fpsBoostOn = on and true or false
    local lighting = game:GetService("Lighting")
    local terrain = workspace:FindFirstChildOfClass("Terrain")

    if BF._fpsConn then
        pcall(function() BF._fpsConn:Disconnect() end)
        BF._fpsConn = nil
    end

    if not BF.fpsBoostOn then
        pcall(function()
            settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
            lighting.GlobalShadows = true
            RunService:Set3dRenderingEnabled(true)
        end)
        BF.notifyUser("FPS", "Boost OFF", 2)
        return
    end

    -- Graphics (hub-style)
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level01
        settings().Rendering.EagerBulkExecution = false
    end)
    pcall(function()
        local ugs = UserSettings():GetService("UserGameSettings")
        ugs.SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1
    end)
    pcall(function()
        if setfpscap then setfpscap(999) end
    end)

    -- Lighting
    pcall(function()
        lighting.GlobalShadows = false
        lighting.FogEnd = 9e9
        lighting.FogStart = 0
        lighting.Brightness = 1
        lighting.ClockTime = 12
        lighting.EnvironmentDiffuseScale = 0
        lighting.EnvironmentSpecularScale = 0
        pcall(function()
            lighting.Technology = Enum.Technology.Compatibility
        end)
        for _, v in ipairs(lighting:GetChildren()) do
            if v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or v:IsA("ColorCorrectionEffect")
                or v:IsA("BloomEffect") or v:IsA("DepthOfFieldEffect") or v:IsA("Atmosphere")
                or v:IsA("Sky") or v:IsA("Clouds") then
                pcall(function() v.Enabled = false end)
            end
        end
    end)

    -- Terrain / water
    pcall(function()
        if terrain then
            terrain.WaterWaveSize = 0
            terrain.WaterWaveSpeed = 0
            terrain.WaterReflectance = 0
            terrain.WaterTransparency = 1
            terrain.Decoration = false
        end
    end)

    local function strip(obj)
        if not obj then return end
        if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke")
            or obj:IsA("Fire") or obj:IsA("Sparkles") or obj:IsA("Beam") then
            pcall(function() obj.Enabled = false end)
        elseif obj:IsA("Explosion") then
            pcall(function() obj:Destroy() end)
        elseif obj:IsA("Decal") or obj:IsA("Texture") then
            pcall(function() obj.Transparency = 1 end)
        elseif obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then
            pcall(function() obj.Enabled = false end)
        elseif obj:IsA("BasePart") and not obj:IsA("Terrain") then
            pcall(function()
                obj.CastShadow = false
                obj.Material = Enum.Material.SmoothPlastic
                obj.Reflectance = 0
            end)
        end
    end

    -- One-shot pass (can hitch briefly once)
    task.spawn(function()
        pcall(function()
            for _, v in ipairs(workspace:GetDescendants()) do
                strip(v)
            end
        end)
        BF.notifyUser("FPS", "Boost applied (materials + effects)", 3)
    end)

    BF._fpsConn = workspace.DescendantAdded:Connect(function(v)
        if BF.fpsBoostOn then strip(v) end
    end)
end

BF.applyWhiteScreen = function(on)
    BF._fpsWhite = on and true or false
    pcall(function()
        RunService:Set3dRenderingEnabled(not BF._fpsWhite)
    end)
    BF.notifyUser("FPS", BF._fpsWhite and "White screen ON" or "White screen OFF", 2)
end

-- =============================================
-- ANTI AFK (Silent, Non-Intrusive, 100% Reliable)
-- =============================================
BF.antiAfkEnabled = false
BF._antiAfkConns = {}
BF._antiAfkLoops = {}

BF.startAntiAfk = function()
    if BF.antiAfkEnabled then return end
    BF.antiAfkEnabled = true

    -- Method 1: Disable internal Roblox Idled connections (if executor supports getconnections)
    pcall(function()
        if getconnections then
            for _, conn in pairs(getconnections(LocalPlayer.Idled)) do
                if conn.Disable then
                    conn:Disable()
                elseif conn.Disconnect then
                    conn:Disconnect()
                end
            end
        end
    end)

    -- Method 2: Listen to LocalPlayer.Idled and counter with VirtualUser (silent click)
    pcall(function()
        local conn = LocalPlayer.Idled:Connect(function()
            if not BF.antiAfkEnabled then return end
            pcall(function()
                local vu = game:GetService("VirtualUser")
                vu:CaptureController()
                vu:ClickButton2(Vector2.new(0, 0))
            end)
        end)
        table.insert(BF._antiAfkConns, conn)
    end)

    -- Method 3: Silent heartbeat every 90 seconds (never moves character, jumps, or presses keys)
    local loop = task.spawn(function()
        while BF.antiAfkEnabled do
            task.wait(90)
            if not BF.antiAfkEnabled then break end
            pcall(function()
                local vu = game:GetService("VirtualUser")
                vu:CaptureController()
                vu:ClickButton2(Vector2.new(0, 0))
            end)
        end
    end)
    table.insert(BF._antiAfkLoops, loop)

    BF.notifyUser("Anti-AFK", "Anti-AFK active (silent mode)", 2)
end

BF.stopAntiAfk = function()
    BF.antiAfkEnabled = false
    -- Re-enable idled connections if disabled
    pcall(function()
        if getconnections then
            for _, conn in pairs(getconnections(LocalPlayer.Idled)) do
                if conn.Enable then
                    conn:Enable()
                end
            end
        end
    end)
    for _, c in ipairs(BF._antiAfkConns) do
        pcall(function() c:Disconnect() end)
    end
    BF._antiAfkConns = {}
    for _, t in ipairs(BF._antiAfkLoops) do
        pcall(function() task.cancel(t) end)
    end
    BF._antiAfkLoops = {}
    BF.notifyUser("Anti-AFK", "Anti-AFK OFF", 2)
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



BF.CODE_LIST = {
    "SUB2GAMERROBOT_EXP1", "SUB2GAMERROBOT_RESET1", "Starcodeheo", "starcodeheo",
    "Sub2Fer999", "Sub2UncleKizaru", "Sub2Daigrock", "Sub2CaptainMaui",
    "Sub2OfficialNoobie", "Enyu_is_Pro", "THEGREATACE", "TheGreatAce",
    "JCWK", "kittgaming", "KITT_RESET", "Magicbus", "Bluxxy", "BIGNEWS", "Bignews",
    "Axiore", "LIGHTNINGABUSE", "Lightningabuse", "EASTEREXP", "fudd10_v2", "Fudd10",
    "StrawHatMaine", "TantaiGaming", "Sub2NoobMaster123", "CHANDLER",
    "1LOSTADMIN", "ADMINFIGHT", "DRAGONABUSE", "CODE_SERVICIO", "DEVSCOOKING",
}

BF.redeemAllCodes = function()
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local comm = remotes and remotes:FindFirstChild("CommF_")
    if not comm then
        BF.notifyUser("Codes", "CommF_ not found", 3)
        return
    end
    BF.notifyUser("Codes", "Redeeming " .. #BF.CODE_LIST .. " codes...", 3)
    task.spawn(function()
        local okCount = 0
        for _, code in ipairs(BF.CODE_LIST) do
            local ok, ret = pcall(function()
                return comm:InvokeServer("Codes", code)
            end)
            print("[BF] Code", code, ok, ret)
            if ok then okCount += 1 end
            task.wait(0.35)
        end
        BF.notifyUser("Codes", "Done (" .. okCount .. " calls)", 4)
    end)
end

-- =============================================
-- FIGHTING STYLE SHOP & ABILITIES (CommF_)
-- =============================================
BF.styleRemoteNames = {
    ["Dark Step"]       = "BuyBlackLeg",
    ["Electro"]         = "BuyElectro",
    ["Water Kung Fu"]   = "BuyFishmanKarate",
    ["Dragon Breath"]   = "DragonClaw",
    ["Superhuman"]      = "BuySuperhuman",
    ["Death Step"]      = "BuyDeathStep",
    ["Sharkman Karate"] = "BuySharkmanKarate",
    ["Electric Claw"]   = "BuyElectricClaw",
    ["Dragon Talon"]    = "BuyDragonTalon",
    ["Godhuman"]        = "BuyGodhuman",
    ["Sanguine Art"]    = "BuySanguineArt",
}

BF.styleAliases = {
    ["Dark Step"]       = {"Dark Step", "DarkStep", "Black Leg", "BlackLeg"},
    ["Electro"]         = {"Electro", "Electric"},
    ["Water Kung Fu"]   = {"Water Kung Fu", "WaterKungFu", "Fishman Karate", "FishmanKarate"},
    ["Dragon Breath"]   = {"Dragon Breath", "DragonBreath", "Dragon Claw", "DragonClaw"},
    ["Superhuman"]      = {"Superhuman"},
    ["Death Step"]      = {"Death Step", "DeathStep"},
    ["Sharkman Karate"] = {"Sharkman Karate", "SharkmanKarate"},
    ["Electric Claw"]   = {"Electric Claw", "ElectricClaw"},
    ["Dragon Talon"]    = {"Dragon Talon", "DragonTalon"},
    ["Godhuman"]        = {"Godhuman"},
    ["Sanguine Art"]    = {"Sanguine Art", "SanguineArt"},
    ["Combat"]          = {"Combat"},
}

BF.styleMinimumBeli = {
    ["Dark Step"] = 150000,
    ["Electro"] = 550000,
    ["Water Kung Fu"] = 750000,
    ["Superhuman"] = 3000000,
    ["Death Step"] = 2500000,
    ["Sharkman Karate"] = 2500000,
    ["Electric Claw"] = 3000000,
    ["Dragon Talon"] = 3000000,
    ["Godhuman"] = 5000000,
    ["Sanguine Art"] = 5000000,
}

BF.findFightingStyleTool = function(styleName)
    local char = LocalPlayer.Character
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    local aliases = BF.styleAliases[styleName] or {styleName}

    -- 1. Check Character (already equipped)
    if char then
        for _, child in ipairs(char:GetChildren()) do
            if child:IsA("Tool") then
                for _, alias in ipairs(aliases) do
                    if string.lower(child.Name) == string.lower(alias) or string.find(string.lower(child.Name), string.lower(alias), 1, true) then
                        return child, true
                    end
                end
            end
        end
    end

    -- 2. Check Backpack
    if backpack then
        for _, child in ipairs(backpack:GetChildren()) do
            if child:IsA("Tool") then
                for _, alias in ipairs(aliases) do
                    if string.lower(child.Name) == string.lower(alias) or string.find(string.lower(child.Name), string.lower(alias), 1, true) then
                        return child, false
                    end
                end
            end
        end
    end

    return nil, false
end

BF.isFightingStyleOwned = function(styleName)
    if BF.findFightingStyleTool(styleName) then return true end
    -- The current style may be saved in player data while its Tool is not
    -- parented to Character/Backpack during respawn or a switch.
    local aliases = BF.styleAliases[styleName] or {styleName}
    local containers = {
        LocalPlayer:FindFirstChild("Data"),
        LocalPlayer:FindFirstChild("PlayerData"),
        ReplicatedStorage:FindFirstChild("PlayerData"),
    }
    for _, container in ipairs(containers) do
        if container then
            for _, item in ipairs(container:GetDescendants()) do
                if item:IsA("BoolValue") and item.Value then
                    local lowerName = string.lower(item.Name)
                    for _, alias in ipairs(aliases) do
                        local aliasLower = string.lower(alias)
                        if lowerName == aliasLower or lowerName == aliasLower .. "owned" then
                            return true
                        end
                    end
                end
            end
        end
    end
    return false
end

BF.equipStyleTool = function(tool)
    if not tool then return false end
    local equipEvent = tool:FindFirstChild("EquipEvent")
    if equipEvent and equipEvent:IsA("RemoteEvent") then
        return pcall(function() equipEvent:FireServer(false) end)
    end
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end
    return pcall(function() humanoid:EquipTool(tool) end)
end

BF.equipFightingStyle = function(styleName)
    local char = LocalPlayer.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return false end

    -- 1. Check if tool is already in Character or Backpack
    local tool, isEquipped = BF.findFightingStyleTool(styleName)
    if tool then
        if not isEquipped then
            BF.equipStyleTool(tool)
        end
        config.selectedFightingStyle = styleName
        return true
    end

    -- 2. Not in inventory: invoke the style purchase/equip action.
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local commF = remotes and remotes:FindFirstChild("CommF_")
    if not commF then return false end

    local remoteName = BF.styleRemoteNames[styleName]
    if not remoteName then return false end

    -- The style purchase remote also switches to/equips the style when owned.
    pcall(function() commF:InvokeServer(remoteName, true) end)
    task.wait(0.75)

    -- Check if tool arrived in inventory
    tool, isEquipped = BF.findFightingStyleTool(styleName)
    if tool then
        if not isEquipped then
            BF.equipStyleTool(tool)
        end
        config.selectedFightingStyle = styleName
        return true
    end

    return false
end

BF.buyFightingStyle = function(styleName, autoEquip)
    local remoteName = BF.styleRemoteNames[styleName]
    if not remoteName then
        BF.notifyUser("Style", "Unknown style: " .. tostring(styleName), 3)
        return false
    end
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local commF = remotes and remotes:FindFirstChild("CommF_")
    if not commF then
        BF.notifyUser("Style", "CommF_ not found", 3)
        return false
    end

    local existingTool, existingEquipped = BF.findFightingStyleTool(styleName)
    if existingTool then
        if autoEquip ~= false and not existingEquipped then
            BF.equipStyleTool(existingTool)
        end
        BF.notifyUser("Style", styleName .. " is already owned; equipped it.", 4)
        return true
    end

    local beliBefore, beliValue = BF.getPlayerCurrency("Beli")
    local minBeli = BF.styleMinimumBeli[styleName]
    if minBeli and beliBefore and beliBefore < minBeli then
        BF.notifyUser("Style", styleName .. " needs " .. tostring(minBeli) .. " Beli; current: " .. tostring(beliBefore), 5)
        return false
    end

    -- Fighting style purchase commands are invoked with the command name only.
    -- A second argument changes the server action and can return 0 without buying.
    local commands
    if styleName == "Dragon Breath" then
        commands = {
            {"BlackbeardReward", "DragonClaw", "1"},
            {"BlackbeardReward", "DragonClaw", "2"},
            {"BuyDragonBreath"},
        }
    else
        commands = {{remoteName, true}}
    end

    local callSucceeded = false
    local responses = {}
    for _, args in ipairs(commands) do
        local ok, result = pcall(function()
            return commF:InvokeServer(unpack(args))
        end)
        callSucceeded = callSucceeded or ok
        table.insert(responses, tostring(result))
        task.wait(0.25)
        local owned = BF.isFightingStyleOwned(styleName)
        if owned then break end
    end

    -- Give the server a moment to replicate the newly granted tool.
    local tool, isEquipped
    local deadline = os.clock() + 2
    repeat
        tool, isEquipped = BF.findFightingStyleTool(styleName)
        if tool or BF.isFightingStyleOwned(styleName) then break end
        task.wait(0.1)
    until os.clock() >= deadline

    if tool then
        if autoEquip ~= false and not isEquipped then
            BF.equipStyleTool(tool)
        end
        config.selectedFightingStyle = styleName
        BF.notifyUser("Style", styleName .. " purchased", 3)
        return true
    end

    if BF.isFightingStyleOwned(styleName) then
        BF.notifyUser("Style", styleName .. " is already owned; equip it from your fighting style/NPC interaction.", 5)
        return false
    end

    if styleName == "Dark Step" and beliBefore then
        local liveBeli = BF.getPlayerCurrency("Beli")
        local beliAfter = liveBeli or (beliValue and tonumber(beliValue.Value)) or beliBefore
        if beliAfter < beliBefore then
            -- Ownership may replicate after the currency deduction.
            local verifyDeadline = os.clock() + 2
            repeat
                tool, isEquipped = BF.findFightingStyleTool(styleName)
                if tool then break end
                task.wait(0.1)
            until os.clock() >= verifyDeadline
            if tool then
                if autoEquip ~= false and not isEquipped then
                    BF.equipStyleTool(tool)
                end
                BF.notifyUser("Style", "Dark Step purchased", 3)
                return true
            end
        end
        table.insert(responses, "Beli " .. tostring(beliBefore) .. " -> " .. tostring(beliAfter))
    end
    -- Remote responses vary between game versions. Do not treat an arbitrary
    -- non-nil response as proof of purchase; report requirements if no tool arrived.
    local responseText = table.concat(responses, " | ")
    if not callSucceeded then responseText = "remote call failed" end
    local beliAfter = BF.getPlayerCurrency("Beli")
    local beliDelta = (beliBefore and beliAfter) and (beliBefore - beliAfter) or nil
    local detail = beliDelta and (" Beli change: " .. tostring(beliDelta) .. ".") or ""
    BF.notifyUser("Style", styleName .. " was not confirmed (server: " .. responseText .. ")." .. detail .. " Stand next to its teacher and use the in-game interaction to see the exact requirement.", 7)
    local char = LocalPlayer.Character
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    local tools = {}
    for _, container in ipairs({char, backpack}) do
        if container then
            for _, child in ipairs(container:GetChildren()) do
                if child:IsA("Tool") then
                    local mastery = child:FindFirstChild("Level")
                    table.insert(tools, child.Name .. (mastery and (" [" .. tostring(mastery.Value) .. "]") or ""))
                end
            end
        end
    end
    print("[BF Style]", styleName, "not confirmed; responses:", responseText,
        "Beli before/after:", beliBefore, beliAfter,
        "current tools:", table.concat(tools, ", "))
    return false
end

BF.buyAllFightingStyles = function()
    BF.notifyUser("Style", "Buying all styles (requirements needed)...", 3)
    task.spawn(function()
        for name in pairs(BF.styleRemoteNames) do
            pcall(function() BF.buyFightingStyle(name, false) end)
            task.wait(0.4)
        end
        BF.notifyUser("Style", "All style buy attempts sent", 4)
    end)
end

-- Ability Teacher purchases
BF.buyBusoHaki = function()
    return BF.buyShopItem("BuyHaki", "Buso")
end

BF.buyGeppo = function()
    return BF.buyShopItem("BuyHaki", "Geppo")
end

BF.buySoru = function()
    return BF.buyShopItem("BuyHaki", "Soru")
end

BF.buyObservationHaki = function()
    return BF.buyShopItem("KenTalk", "Buy")
end

BF.buyAllAbilities = function()
    BF.notifyUser("Abilities", "Buying Geppo, Buso, Soru, Ken...", 3)
    task.spawn(function()
        BF.buyGeppo()
        task.wait(0.3)
        BF.buyBusoHaki()
        task.wait(0.3)
        BF.buySoru()
        task.wait(0.3)
        BF.buyObservationHaki()
        BF.notifyUser("Abilities", "Ability purchases completed", 3)
    end)
end

-- Auto Buy Abilities background task
BF.autoBuyAbilitiesRunning = false
BF.startAutoBuyAbilities = function()
    if BF.autoBuyAbilitiesRunning then return end
    BF.autoBuyAbilitiesRunning = true
    task.spawn(function()
        while BF.autoBuyAbilitiesRunning do
            if config.autoBuyAbilities then
                pcall(function()
                    local lvl = BF.getPlayerLevel()
                    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
                    local beli = leaderstats and leaderstats:FindFirstChild("Beli") and leaderstats.Beli.Value or 0

                    if lvl >= 20 and beli >= 10000 then BF.buyGeppo() end
                    if lvl >= 20 and beli >= 25000 then BF.buyBusoHaki() end
                    if lvl >= 100 and beli >= 100000 then BF.buySoru() end
                    if lvl >= 300 and beli >= 750000 then BF.buyObservationHaki() end
                end)
            end
            task.wait(20)
        end
    end)
end

-- Generic CommF_ purchase supporting arbitrary arguments
BF.buyShopItem = function(...)
    local args = {...}
    if #args == 0 then return false end
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local commF = remotes and remotes:FindFirstChild("CommF_")
    if not commF then
        BF.notifyUser("Shop", "CommF_ not found", 3)
        return false
    end
    local ok, ret = pcall(function()
        return commF:InvokeServer(unpack(args))
    end)
    local itemName = tostring(args[2] or args[1])
    if ok and ret ~= false then
        BF.notifyUser("Shop", "Bought " .. itemName .. " (" .. tostring(ret) .. ")", 3)
        print("[BF Shop]", unpack(args), "->", ret)
        return true, ret
    else
        BF.notifyUser("Shop", "Shop call " .. itemName .. ": " .. tostring(ret), 4)
        return false, ret
    end
end

-- Server utilities (Rejoin & Server Hop)
BF.rejoinServer = function()
    local TeleportService = game:GetService("TeleportService")
    BF.notifyUser("Server", "Rejoining server...", 3)
    pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end)
end

BF.serverHop = function()
    local TeleportService = game:GetService("TeleportService")
    local HttpService = game:GetService("HttpService")
    BF.notifyUser("Server", "Finding new server...", 3)
    task.spawn(function()
        pcall(function()
            local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
            local res = game:HttpGet(url)
            local data = HttpService:JSONDecode(res)
            if data and data.data then
                for _, server in ipairs(data.data) do
                    if type(server) == "table" and server.playing and server.maxPlayers and server.playing < server.maxPlayers and server.id ~= game.JobId then
                        TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer)
                        return
                    end
                end
            end
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
        end)
    end)
end

if useVaxorin and window then
    local mainTab = window:CreateTab("Farm")

    local miscTab = window:CreateTab("Misc")
    local fpsSection = miscTab:CreateSection({Name = "Performance"})
    fpsSection:CreateToggle({
        Name = "Anti-AFK",
        CurrentValue = true, -- direkt an lassen
        Flag = "Misc.AntiAfk",
        Save = true,
        Callback = function(v)
            if v then 
                BF.startAntiAfk() 
            else 
                BF.stopAntiAfk() 
            end
        end,
    })
    fpsSection:CreateToggle({
        Name = "FPS Booster",
        CurrentValue = false,
        Flag = "Misc.FPS",
        Save = true,
        Callback = function(v) BF.applyFpsBoost(v) end,
    })
    fpsSection:CreateToggle({
        Name = "White Screen (max FPS)",
        CurrentValue = false,
        Flag = "Misc.WhiteScreen",
        Save = false,
        Callback = function(v) BF.applyWhiteScreen(v) end,
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

    local codesSection = miscTab:CreateSection({Name = "Codes"})
    codesSection:CreateButton({
        Name = "Redeem All Codes",
        Callback = function()
            BF.redeemAllCodes()
        end,
    })

    local espTab = window:CreateTab("ESP")
    local fruitTab = window:CreateTab("Fruits")
    local ShopTab = window:CreateTab("Shop")
    local MoneyTab = window:CreateTab("Auto Money")
    local combatTab = window:CreateTab("Combat")

    local raidTab = window:CreateTab("Raid")
    local raidSection = raidTab:CreateSection({Name = "Auto Raid (Microchip)"})
    raidSection:CreateToggle({
        Name = "Auto Raid",
        CurrentValue = false,
        Flag = "Raid.Enabled", Save = true,
        Callback = function(v)
            config.autoRaid = v
            pcall(function()
                if v then
                    if type(BF.startAutoRaid) == "function" then BF.startAutoRaid() end
                else
                    if type(BF.stopAutoRaid) == "function" then BF.stopAutoRaid() end
                end
            end)
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
            if type(selectRaidType) == "function" then
                pcall(selectRaidType, config.raidType)
            end
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
    local currentSea = "Unknown"
    pcall(function() currentSea = BF.getCurrentSea() end)
    mainSection:CreateToggle({
        Name = "Auto Farm",
        CurrentValue = false,
        Flag = "Farm.Enabled", Save = true,
        Callback = function(v)
            if v then
                if type(BF.startFarm) == "function" then BF.startFarm() end
            else
                if type(BF.stopFarm) == "function" then BF.stopFarm() end
            end
        end,
    })
    -- Live status under Auto Farm (CyberUI: Stat:Set(value), Paragraph:Set(string))
    BF._statusLabels = BF._statusLabels or {}
    pcall(function()
        BF._statusLabels.level = mainSection:CreateStat({ Label = "Level", Value = "..." })
    end)
    pcall(function()
        BF._statusLabels.quest = mainSection:CreateParagraph({ Title = "Quest", Content = "..." })
    end)
    pcall(function()
        BF._statusLabels.enemy = mainSection:CreateParagraph({ Title = "Enemy", Content = "..." })
    end)
    mainSection:CreateToggle({
        Name = "Accept Quest",
        CurrentValue = config.acceptQuest ~= false,
        Flag = "Farm.AcceptQuest", Save = true,
        Callback = function(v) config.acceptQuest = v end,
    })
    -- Sea-specific toggles
    if currentSea == "Sea1" then
        mainSection:CreateToggle({
            Name = "Auto Secrets (Sea1)",
            CurrentValue = false,
            Flag = "Farm.AutoSecrets", Save = true,
            Callback = function(v)
                config.autoSecrets = v
                pcall(function()
                    if v then
                        if type(BF.startAutoSecrets) == "function" then BF.startAutoSecrets() end
                    else
                        if type(BF.stopAutoSecrets) == "function" then BF.stopAutoSecrets() end
                    end
                end)
            end,
        })
        mainSection:CreateToggle({
            Name = "Auto Sea Progress (1->2)",
            CurrentValue = false,
            Flag = "Farm.AutoSeaProgress", Save = true,
            Callback = function(v)
                config.autoSeaProgress = v
                pcall(function()
                    if v then
                        if type(BF.startSeaProgress) == "function" then BF.startSeaProgress() end
                    else
                        if type(BF.stopSeaProgress) == "function" then BF.stopSeaProgress() end
                    end
                end)
            end,
        })
    elseif currentSea == "Sea2" then
        mainSection:CreateToggle({
            Name = "Auto Sea Progress (2->3)",
            CurrentValue = false,
            Flag = "Farm.AutoSeaProgress", Save = true,
            Callback = function(v)
                config.autoSeaProgress = v
                pcall(function()
                    if v then
                        if type(BF.startSeaProgress) == "function" then BF.startSeaProgress() end
                    else
                        if type(BF.stopSeaProgress) == "function" then BF.stopSeaProgress() end
                    end
                end)
            end,
        })
    end
    mainSection:CreateToggle({
        Name = "Boss Priority",
        CurrentValue = config.bossPriority,
        Flag = "Farm.BossPriority", Save = true,
        Callback = function(v) config.bossPriority = v end,
    })
    if currentSea == "Sea3" then
        mainSection:CreateToggle({
            Name = "Auto Bones (Haunted)",
            CurrentValue = false,
            Flag = "Farm.AutoBones", Save = true,
            Callback = function(v)
                config.autoBones = v
                pcall(function()
                    if v then
                        if type(BF.startBonesFarm) == "function" then BF.startBonesFarm() end
                    else
                        if type(BF.stopBonesFarm) == "function" then BF.stopBonesFarm() end
                    end
                end)
            end,
        })
        pcall(function()
            BF._statusLabels = BF._statusLabels or {}
            BF._statusLabels.bones = mainSection:CreateStat({ Label = "Bones", Value = "..." })
        end)
        mainSection:CreateToggle({
            Name = "Auto Buy Bones (Random)",
            CurrentValue = false,
            Flag = "Farm.AutoBonesBuy", Save = true,
            Callback = function(v)
                config.autoBonesBuy = v
                pcall(function()
                    if v then
                        if type(BF.startBonesBuy) == "function" then BF.startBonesBuy() end
                    else
                        if type(BF.stopBonesBuy) == "function" then BF.stopBonesBuy() end
                    end
                end)
            end,
        })
        mainSection:CreateToggle({
            Name = "Auto Cake Prince",
            CurrentValue = false,
            Flag = "Farm.AutoCakePrince", Save = true,
            Callback = function(v)
                config.autoCakePrince = v
                pcall(function()
                    if v then
                        if type(BF.startCakePrince) == "function" then BF.startCakePrince() end
                    else
                        if type(BF.stopCakePrince) == "function" then BF.stopCakePrince() end
                    end
                end)
            end,
        })
        pcall(function()
            BF._statusLabels = BF._statusLabels or {}
            BF._statusLabels.cakeLeft = mainSection:CreateStat({ Label = "Enemies Left", Value = "..." })
        end)
    end
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
            pcall(function()
                if v then
                    if type(BF.startEnemyEsp) == "function" then BF.startEnemyEsp() end
                else
                    if type(BF.stopEnemyEsp) == "function" then BF.stopEnemyEsp(true) end
                end
            end)
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
    -- ========== SHOP TAB ==========
    -- 1) ABILITIES & HAKI (ABILITY TEACHER)
    local abilitySection = ShopTab:CreateSection({Name = "Abilities & Haki (Teacher)"})
    abilitySection:CreateButton({
        Name = "Buy Aura / Buso Haki ($25,000)",
        Callback = function()
            BF.buyBusoHaki()
        end,
    })
    abilitySection:CreateButton({
        Name = "Buy Sky Jump / Geppo ($10,000)",
        Callback = function()
            BF.buyGeppo()
        end,
    })
    abilitySection:CreateButton({
        Name = "Buy Flash Step / Soru ($100,000)",
        Callback = function()
            BF.buySoru()
        end,
    })
    abilitySection:CreateButton({
        Name = "Buy Instinct / Ken Haki ($750,000 | Lv 300+)",
        Callback = function()
            BF.buyObservationHaki()
        end,
    })
    abilitySection:CreateButton({
        Name = "Buy ALL Basic Abilities (Geppo, Buso, Soru)",
        Callback = function()
            BF.buyAllAbilities()
        end,
    })
    abilitySection:CreateToggle({
        Name = "Auto Buy Abilities (when money/level ready)",
        CurrentValue = config.autoBuyAbilities or false,
        Flag = "Shop.AutoBuyAbilities",
        Save = true,
        Callback = function(v)
            config.autoBuyAbilities = v
            if v then
                BF.startAutoBuyAbilities()
                BF.notifyUser("Shop", "Auto Buy Abilities ON", 2)
            else
                BF.autoBuyAbilitiesRunning = false
                BF.notifyUser("Shop", "Auto Buy Abilities OFF", 2)
            end
        end,
    })

    -- 2) FIGHTING STYLES (BUY & QUICK SWITCH)
    local styleSection = ShopTab:CreateSection({Name = "Fighting Styles"})
    styleSection:CreateParagraph({
        Title = "Fighting Styles Info & Requirements",
        Content = "Sea 1: Dark Step ($150k), Electro ($500k), Water Kung Fu ($750k)\nSea 2: Dragon Breath (1.5k Frags), Superhuman ($3M), Death Step ($2.5M+5k F), Sharkman Karate ($2.5M+5k F)\nSea 3: Electric Claw ($3M+5k F), Dragon Talon ($3M+5k F), Godhuman ($5M+5k F), Sanguine Art ($5M+5k F)",
    })

    local STYLES_LIST = {
        {Name = "Dark Step ($150,000 | Sea 1)",            Key = "Dark Step"},
        {Name = "Electro ($500,000 | Sea 1)",              Key = "Electro"},
        {Name = "Water Kung Fu ($750,000 | Sea 1)",        Key = "Water Kung Fu"},
        {Name = "Dragon Breath (1,500 Frags | Sea 2)",     Key = "Dragon Breath"},
        {Name = "Superhuman ($3,000,000 | Sea 2)",         Key = "Superhuman"},
        {Name = "Death Step ($2.5M + 5k Frags | Sea 2)",   Key = "Death Step"},
        {Name = "Sharkman Karate ($2.5M + 5k F | Sea 2)",  Key = "Sharkman Karate"},
        {Name = "Electric Claw ($3,000,000 + 5k F | Sea 3)", Key = "Electric Claw"},
        {Name = "Dragon Talon ($3,000,000 + 5k F | Sea 3)", Key = "Dragon Talon"},
        {Name = "Godhuman ($5,000,000 + 5k Frags | Sea 3)", Key = "Godhuman"},
        {Name = "Sanguine Art ($5M + 5k Frags | Sea 3)",   Key = "Sanguine Art"},
    }

    for _, style in ipairs(STYLES_LIST) do
        styleSection:CreateButton({
            Name = "Buy " .. style.Name,
            Callback = function()
                BF.buyFightingStyle(style.Key)
            end,
        })
    end

    styleSection:CreateButton({
        Name = "Buy ALL Styles (Throttled)",
        Callback = function()
            BF.buyAllFightingStyles()
        end,
    })

    local selectedSwitchStyle = "Dark Step"
    styleSection:CreateDropdown({
        Name = "Quick Switch Fighting Style",
        Options = {
            "Dark Step", "Electro", "Water Kung Fu", "Dragon Breath",
            "Superhuman", "Death Step", "Sharkman Karate",
            "Electric Claw", "Dragon Talon", "Godhuman", "Sanguine Art"
        },
        CurrentOption = "Dark Step",
        Flag = "Shop.SwitchStyle",
        Save = false,
        Callback = function(v)
            if type(v) == "table" then v = v[1] end
            selectedSwitchStyle = tostring(v or "Dark Step")
        end,
    })

    styleSection:CreateButton({
        Name = "Equip Selected Fighting Style",
        Callback = function()
            local success = BF.equipFightingStyle(selectedSwitchStyle)
            if success then
                BF.notifyUser("Style", selectedSwitchStyle .. " equipped!", 2)
            else
                BF.notifyUser("Style", "Could not equip " .. selectedSwitchStyle .. " (check if unlocked)", 3)
            end
        end,
    })

    -- 3) SWORDS DEALER
    local swordSection = ShopTab:CreateSection({Name = "Swords Dealer"})
    local SWORD_PURCHASES = {
        {Name = "Katana ($1,000 | Sea 1)",              Args = {"BuyItem", "Katana"}},
        {Name = "Cutlass ($1,000 | Sea 1)",             Args = {"BuyItem", "Cutlass"}},
        {Name = "Dual Katana ($12,000 | Sea 1)",        Args = {"BuyItem", "Dual Katana"}},
        {Name = "Iron Mace ($25,000 | Sea 1)",          Args = {"BuyItem", "Iron Mace"}},
        {Name = "Triple Katana ($60,000 | Sea 1)",      Args = {"BuyItem", "Triple Katana"}},
        {Name = "Pipe ($100,000 | Sea 1)",              Args = {"BuyItem", "Pipe"}},
        {Name = "Dual-Headed Blade ($400,000 | Sea 1)", Args = {"BuyItem", "Dual-Headed Blade"}},
        {Name = "Soul Cane ($750,000 | Sea 1)",         Args = {"BuyItem", "Soul Cane"}},
        {Name = "Bisento ($1,000,000 | Sea 1)",         Args = {"BuyItem", "Bisento"}},
        {Name = "True Triple Katana ($2,000,000 | Sea 2)", Args = {"BuyTrueTripleKatana"}},
    }
    for _, item in ipairs(SWORD_PURCHASES) do
        swordSection:CreateButton({
            Name = "Buy " .. item.Name,
            Callback = function()
                BF.buyShopItem(unpack(item.Args))
            end,
        })
    end

    -- 4) GUNS DEALER
    local gunSection = ShopTab:CreateSection({Name = "Guns Dealer"})
    local GUN_PURCHASES = {
        {Name = "Slingshot ($5,000 | Sea 1)",           Args = {"BuyItem", "Slingshot"}},
        {Name = "Flintlock ($10,500 | Sea 1)",          Args = {"BuyItem", "Flintlock"}},
        {Name = "Refined Slingshot ($30,000 | Sea 1)",  Args = {"BuyItem", "Refined Slingshot"}},
        {Name = "Refined Flintlock ($65,000 | Sea 1)",  Args = {"BuyItem", "Refined Flintlock"}},
        {Name = "Musket ($8,000 | Sea 1)",              Args = {"BuyItem", "Musket"}},
        {Name = "Dual Flintlock ($175,000 | Sea 1)",    Args = {"BuyItem", "Dual Flintlock"}},
        {Name = "Cannon ($100,000 | Sea 1)",            Args = {"BuyItem", "Cannon"}},
        {Name = "Kabucha (1,500 Frags | Sea 2)",        Args = {"BlackbeardReward", "Slingshot", "2"}},
    }
    for _, item in ipairs(GUN_PURCHASES) do
        gunSection:CreateButton({
            Name = "Buy " .. item.Name,
            Callback = function()
                BF.buyShopItem(unpack(item.Args))
            end,
        })
    end

    -- 5) ACCESSORIES DEALER
    local accessorySection = ShopTab:CreateSection({Name = "Accessories Dealer"})
    local ACCESSORY_PURCHASES = {
        {Name = "Black Cape ($50,000 | Sea 1 Lv 50+)",  Args = {"BuyItem", "Black Cape"}},
        {Name = "Swordsman Hat ($150,000 | Sea 1)",     Args = {"BuyItem", "Swordsman Hat"}},
        {Name = "Tomoe Ring ($500,000 | Sea 1 Lv 450+)",Args = {"BuyItem", "Tomoe Ring"}},
    }
    for _, item in ipairs(ACCESSORY_PURCHASES) do
        accessorySection:CreateButton({
            Name = "Buy " .. item.Name,
            Callback = function()
                BF.buyShopItem(unpack(item.Args))
            end,
        })
    end

    -- 6) BOATS DEALER
    local boatSection = ShopTab:CreateSection({Name = "Boats Dealer"})
    local BOAT_PURCHASES = {
        {Name = "Dinghy (Free)",          Args = {"BuyBoat", "Dinghy"}},
        {Name = "Sloop ($300)",           Args = {"BuyBoat", "Sloop"}},
        {Name = "Caravel ($1,000)",       Args = {"BuyBoat", "Caravel"}},
        {Name = "Galleon ($3,000)",       Args = {"BuyBoat", "Galleon"}},
        {Name = "Brigade ($10,000 | Sea 2)", Args = {"BuyBoat", "Brigade"}},
        {Name = "Flying Boat (Enel)",     Args = {"BuyBoat", "FlyingBoat"}},
    }
    for _, item in ipairs(BOAT_PURCHASES) do
        boatSection:CreateButton({
            Name = "Buy " .. item.Name,
            Callback = function()
                BF.buyShopItem(unpack(item.Args))
            end,
        })
    end

    -- 7) STATS, RACES & DEATH KING
    local resetSection = ShopTab:CreateSection({Name = "Stats, Races & Death King"})
    resetSection:CreateButton({
        Name = "Stat Reset (Plokster | 2,500 Frags)",
        Callback = function()
            BF.buyShopItem("BlackbeardReward", "Refund", "1")
            task.wait(0.2)
            BF.buyShopItem("BlackbeardReward", "Refund", "2")
        end,
    })
    resetSection:CreateButton({
        Name = "Race Reroll (Tort | 3,000 Frags)",
        Callback = function()
            BF.buyShopItem("BlackbeardReward", "Reroll", "1")
            task.wait(0.2)
            BF.buyShopItem("BlackbeardReward", "Reroll", "2")
        end,
    })
    resetSection:CreateButton({
        Name = "Random Surprise (50 Bones | Death King)",
        Callback = function()
            BF.buyShopItem("Bones", "Buy", 1, 1)
        end,
    })
    resetSection:CreateButton({
        Name = "Stat Reset (150 Bones | Death King)",
        Callback = function()
            BF.buyShopItem("Bones", "Buy", 2, 1)
        end,
    })
    resetSection:CreateButton({
        Name = "Race Reroll (300 Bones | Death King)",
        Callback = function()
            BF.buyShopItem("Bones", "Buy", 3, 1)
        end,
    })
    resetSection:CreateToggle({
        Name = "Auto Gamble Bones (when 50+ Bones)",
        CurrentValue = config.autoBonesBuy or false,
        Flag = "Shop.AutoBonesBuy",
        Save = true,
        Callback = function(v)
            config.autoBonesBuy = v
            if v then
                if type(BF.startBonesBuy) == "function" then BF.startBonesBuy() end
            else
                if type(BF.stopBonesBuy) == "function" then BF.stopBonesBuy() end
            end
        end,
    })

    -- 8) DEVIL FRUIT GACHA & INVENTORY
    local gachaSection = ShopTab:CreateSection({Name = "Fruit Gacha & Storage"})
    gachaSection:CreateButton({
        Name = "Roll Zioles Gacha Once",
        Callback = function()
            BF.buyRandomFruitOnce()
        end,
    })
    gachaSection:CreateToggle({
        Name = "Auto Roll Gacha (when 2h CD ready)",
        CurrentValue = config.autoRandomFruit or false,
        Flag = "Shop.AutoRandomFruit",
        Save = true,
        Callback = function(v)
            config.autoRandomFruit = v
            if v then
                BF.startAutoRandomFruit()
            else
                BF.stopAutoRandomFruit()
            end
        end,
    })
    gachaSection:CreateButton({
        Name = "Store Held Fruits in Inventory",
        Callback = function()
            pcall(function()
                if type(BF.storeFruitInInventory) == "function" then
                    local oldVal = config.fruitStoreAfterCollect
                    config.fruitStoreAfterCollect = true
                    BF.storeFruitInInventory()
                    config.fruitStoreAfterCollect = oldVal
                    BF.notifyUser("Fruit", "Stored fruits in inventory", 3)
                end
            end)
        end,
    })

    -- 9) RAID MICROCHIPS
    local raidChipSection = ShopTab:CreateSection({Name = "Raid Microchips"})
    raidChipSection:CreateButton({
        Name = "Buy Normal Microchip ($100,000 / 1 Fruit)",
        Callback = function()
            BF.buyShopItem("RaidsNpc", "Select", config.raidType or "Flame")
            task.wait(0.2)
            BF.buyShopItem("RaidsNpc", "Buy")
        end,
    })
    raidChipSection:CreateButton({
        Name = "Buy Special Microchip (Dough/Phoenix)",
        Callback = function()
            BF.buyShopItem("RaidsNpc", "SpecialMicrochip")
        end,
    })

    -- 10) SERVER UTILITIES
    local serverSection = ShopTab:CreateSection({Name = "Server Utilities"})
    serverSection:CreateButton({
        Name = "Rejoin Current Server",
        Callback = function()
            BF.rejoinServer()
        end,
    })
    serverSection:CreateButton({
        Name = "Server Hop (Find New Server)",
        Callback = function()
            BF.serverHop()
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
        Min = 0.025, Max = 0.15, CurrentValue = config.attackSpeed, Rounding = 0.001,
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
        Min = 1, Max = 15, CurrentValue = config.hitsPerCycle, Rounding = 1,
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

    -- ========== DEVELOPER ==========
    local devTab = window:CreateTab("Developer")
    local devSection = devTab:CreateSection({Name = "Quest / Island"})
    pcall(function()
        BF._statusLabels = BF._statusLabels or {}
        BF._statusLabels.devIsland = devSection:CreateParagraph({ Title = "Island", Content = "..." })
    end)
    devSection:CreateButton({
        Name = "Accept Correct Quest",
        Callback = function()
            pcall(BF.devAcceptQuest)
        end,
    })
    devSection:CreateButton({
        Name = "Resume Normal Quest Farming",
        Callback = function()
            -- Return to level-based farming; this does not grant game progression.
            config.devIslandLock = false
            config.devIslandIndex = nil
            config.acceptQuest = true
            config.bossPriority = false
            pcall(BF.abandonQuest)
            pcall(BF.invalidateQuestCache)
            local level = BF.getPlayerLevel()
            local isl = BF.getIslandForLevel(level)
            if isl then
                pcall(function() BF.ensureCorrectQuest(isl, "normal") end)
                BF.notifyUser("Dev", "Normal quest farming resumed: " .. tostring(isl.Name), 3)
            else
                BF.notifyUser("Dev", "Normal farming enabled; no level island found", 3)
            end
        end,
    })
    devSection:CreateButton({
        Name = "Skip / Abandon Quest",
        Callback = function()
            pcall(BF.devSkipQuest)
        end,
    })
    devSection:CreateButton({
        Name = "Previous Island",
        Callback = function()
            pcall(function() BF.devShiftIsland(-1) end)
        end,
    })
    devSection:CreateButton({
        Name = "Next Island",
        Callback = function()
            pcall(function() BF.devShiftIsland(1) end)
        end,
    })
    devSection:CreateToggle({
        Name = "Lock Island (ignore level)",
        CurrentValue = false,
        Flag = "Dev.IslandLock", Save = false,
        Callback = function(v)
            config.devIslandLock = v
            if v and not config.devIslandIndex then
                pcall(function() BF.devShiftIsland(0) end)
            end
            if not v then
                config.devIslandIndex = nil
                BF.notifyUser("Dev", "Island lock OFF", 2)
            end
        end,
    })
    devSection:CreateButton({
        Name = "Fly to Current Island",
        Callback = function()
            local isl = BF.resolveFarmIsland(BF.getPlayerLevel())
            if isl and isl.Pos then
                pcall(BF.enableFly)
                BF.setFlyTarget(isl.Pos + Vector3.new(0, 12, 0), false)
                BF.notifyUser("Dev", "Flying to " .. tostring(isl.Name), 2)
            end
        end,
    })
    devSection:CreateButton({
        Name = "Teleport to Submerged (Lv 2600+)",
        Callback = function()
            if BF.getPlayerLevel() < 2600 then
                BF.notifyUser("Dev", "Need Lv 2600+", 3)
                return
            end
            local sub = nil
            for _, isl in ipairs(islands) do
                if isl.Name:lower():find("submerged 1", 1, true) then sub = isl break end
            end
            if sub then
                BF.teleportCharacterTo(sub.Pos)
                BF.notifyUser("Dev", "Teleported to Submerged 1", 3)
            end
        end,
    })
    local devCombat = devTab:CreateSection({Name = "Combat / ESP"})
    devCombat:CreateButton({
        Name = "Restart Enemy ESP",
        Callback = function()
            config.enemyEspEnabled = true
            pcall(function() BF.stopEnemyEsp(true) end)
            pcall(BF.startEnemyEsp)
        end,
    })
    devCombat:CreateButton({
        Name = "Equip + Buso Now",
        Callback = function()
            pcall(BF.ensureCombatReady)
        end,
    })
    devCombat:CreateButton({
        Name = "Disable Fly / Land",
        Callback = function()
            pcall(BF.disableFly)
        end,
    })
    local devDebug = devTab:CreateSection({Name = "Debug"})
    devDebug:CreateButton({
        Name = "Print Bones Debug (F9)",
        Callback = function()
            pcall(BF.devPrintBones)
            BF.notifyUser("Dev", "Bones dump in F9 console", 2)
        end,
    })
    devDebug:CreateButton({
        Name = "Print Level / Sea / Quest",
        Callback = function()
            local _, qt = BF.getActiveQuestInfo()
            print("[BF] Level", BF.getPlayerLevel(), "Sea", BF.getCurrentSea(), "Quest", qt)
            local isl = BF.resolveFarmIsland(BF.getPlayerLevel())
            print("[BF] Island", isl and isl.Name, isl and isl.Pos)
            BF.notifyUser("Dev", "Printed to F9", 2)
        end,
    })
    devDebug:CreateButton({
        Name = "Force Ensure Correct Quest",
        Callback = function()
            local isl = BF.resolveFarmIsland(BF.getPlayerLevel())
            if isl then
                pcall(BF.abandonQuest)
                task.wait(0.3)
                pcall(function() BF.ensureCorrectQuest(isl, "normal") end)
            end
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
    pcall(BF.startStatusUpdater)
    pcall(BF.startAntiAfk)
    if config.bossTimersEnabled then
        pcall(BF.startBossTimers)
    end
    if config.autoBuyAbilities then
        pcall(BF.startAutoBuyAbilities)
    end
    local seaName = "?"
    pcall(function() seaName = tostring(BF.getCurrentSea()) end)
    BF.notifyUser("Loaded", "Vaxorin UI active. Sea: " .. seaName)
else
    BF.notifyUser("Loaded", "Fallback UI active. Use the button to start/stop.")
    pcall(BF.startAntiAfk) 
    if config.bossTimersEnabled then
        pcall(BF.startBossTimers)
    end
    if config.autoBuyAbilities then
        pcall(BF.startAutoBuyAbilities)
    end
end

print("[BF] fully loaded, lines ready")
-- Keep script alive
while task.wait(1) do end

print("Test 1")
