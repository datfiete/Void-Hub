local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Executor = "unknown"
pcall(function()
    if type(getexecutorname) == "function" then
        Executor = tostring(getexecutorname())
    elseif type(identifyexecutor) == "function" then
        Executor = tostring(identifyexecutor())
    end
end)

local Vaxorin = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/datfiete/Void-Hub/refs/heads/main/CyberUI%20-%20Kopie/load.lua"
))()

pcall(function()
    if Vaxorin.Theme then
        Vaxorin.Theme.Style = "Vaxorin"
    end
end)

local avatar = ""
pcall(function()
    avatar = Players:GetUserThumbnailAsync(
        LocalPlayer.UserId,
        Enum.ThumbnailType.HeadShot,
        Enum.ThumbnailSize.Size150x150
    )
end)

local window = Vaxorin:CreateWindow({
    Title = "My Script",
    Subtitle = "by Fietewoozle",
    Logo = "rbxassetid://135320038058277",

    Badges = {
        { Text = "Vaxorin | v1.0" },
        { Text = "Executor : " .. Executor },
    },

    Footer = {
        Avatar = avatar,
        Username = LocalPlayer.Name,
        Status = "Ready",
    },

    DiscordLink = "https://discord.gg/example",
    ShowSearch = true,
    ShowWindowControls = true,
    ToggleKey = Enum.KeyCode.RightControl,
    TopMost = true,

    -- Layout = "Vaxorin", -- optional: Classic, Minecraft, Orbit, Aether, Nova, Vortex, Prism, Eclipse, Zenith

    ConfigurationSaving = {
        Enabled = true,
        AutoSave = true,
        FolderName = "Vaxorin",
        FileName = "Bloxfruits(2)",
    },
})

window:SetProfileStatus("Ready")
window:SetWatermarkEnabled(true)

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
    {Name = "Prison 1",           Min = 190, Max = 210, Pos = Vector3.new(5270, 9, 470), Quest = {"StartQuest","PrisonerQuest",1}, EnemyPatterns = {"Prisoner"}, isBoss = false},
    {Name = "Prison 2",           Min = 210, Max = 230, Pos = Vector3.new(5330, 20, 750), Quest = {"StartQuest","PrisonerQuest",2}, EnemyPatterns = {"Ruthless Prisoner","Dangerous Prisoner"}, isBoss = false},
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
    {Name = "Warden", Min = 220, Max = 240, Pos = Vector3.new(5592, 2, 729),
        Quest = {"StartQuest","PrisonerQuest",2}, EnemyPatterns = {"Dangerous Prisoner","Ruthless Prisoner"},
        BossQuest = nil, BossPatterns = {"Warden"},
        isBoss = true},
    {Name = "Chief Warden", Min = 230, Max = 250, Pos = Vector3.new(5117, 2, 483),
        Quest = {"StartQuest","PrisonerQuest",2}, EnemyPatterns = {"Dangerous Prisoner"},
        BossQuest = {"StartQuest","ImpelQuest",2}, BossPatterns = {"Chief Warden"},
        isBoss = true},
    {Name = "Swan", Min = 240, Max = 250, Pos = Vector3.new(5117, 2, 483),
        Quest = {"StartQuest","PrisonerQuest",2}, EnemyPatterns = {"Dangerous Prisoner"},
        BossQuest = {"StartQuest","ImpelQuest",3}, BossPatterns = {"Swan"},
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
}

local noclipConnection = nil
local noclipParts = {}
local noclipRefreshAt = 0
local noclipChar = nil

BF.enableNoclip = function()
    if noclipConnection then return end
    -- Stepped runs before physics; Heartbeat is too late for collisions
    noclipConnection = RunService.Stepped:Connect(function()
        local character = LocalPlayer.Character
        if not character then return end
        local now = os.clock()
        if character ~= noclipChar or now - (noclipRefreshAt or 0) > 0.4 then
            noclipChar = character
            noclipRefreshAt = now
            local list = {}
            for _, p in ipairs(character:GetDescendants()) do
                if p:IsA("BasePart") then
                    table.insert(list, p)
                end
            end
            noclipParts = list
        end
        for _, p in ipairs(noclipParts) do
            if p and p.Parent then
                p.CanCollide = false
            end
        end
    end)
end

local disableNoclip = function()
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end
    noclipParts = {}
    noclipChar = nil
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

local flyTarget = nil
local flyConnection = nil
local flying = false
local hoverY = nil
local _bossFlyUnlock = false

local enableFly = function()
    if flying then return end
    local character = LocalPlayer.Character
    if not character then return end
    local humanoid = character:FindFirstChild("Humanoid")
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not hrp then return end

    flying = true
    hoverY = hrp.Position.Y
    humanoid.PlatformStand = true
    local enableNoclip()

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
                        hoverY = hoverY or currentHrp.Position.Y
            local verticalError = hoverY - currentHrp.Position.Y
            currentHrp.AssemblyLinearVelocity = Vector3.new(0, math.clamp(verticalError * 6, -20, 20), 0)
            currentHrp.AssemblyAngularVelocity = Vector3.zero
        end
    end)
end

local disableFly = function()
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

local setFlyTarget = function(position, preserveHeight)
    if fruitOwnsFly and type(BF.fruitOwnsFly) == "function" and BF.fruitOwnsFly() then
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

local function AutoFarm()
    
end