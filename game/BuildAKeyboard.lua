local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Player = Players.LocalPlayer
local UserID = Player.UserId
local Executor = getexecutorname()

-- Character/RootPart dynamisch halten, damit Respawns nicht crashen
local Character = Player.Character or Player.CharacterAdded:Wait()
local RootPart = Character:WaitForChild("HumanoidRootPart")

Player.CharacterAdded:Connect(function(newChar)
    Character = newChar
    RootPart = newChar:WaitForChild("HumanoidRootPart")
end)

local Avatar = Players:GetUserThumbnailAsync(
    Player.UserId,
    Enum.ThumbnailType.HeadShot,
    Enum.ThumbnailSize.Size150x150
)

local CyberUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/datfiete/Void-Hub/main/CyberUI/load.lua"))()
CyberUI.Theme.Style = "Meng"

local window = CyberUI:CreateWindow({
    Title = "Build A Keyboard",
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

local Farmtab = window:CreateTab("Farm")
local Farmsection = Farmtab:CreateSection("Auto Farm")
local Upgradesection = Farmtab:CreateSection("Upgrades")

local YourID = nil

local function FindYourSlot()
    for _, v in pairs(workspace.Slots:GetChildren()) do
        if v:GetAttribute("OwnerUserId") == UserID then
            YourID = v.Name
            return v
        end
    end
    return nil
end

FindYourSlot()

local function isInTable(value, tbl)
    for _, v in ipairs(tbl) do
        if v == value then
            return true
        end
    end
    return false
end

local function DropdownRarities()
    local options = {}
    for _, folder in ipairs(ReplicatedStorage.Assets.Keycaps:GetChildren()) do
        table.insert(options, folder.Name)
    end
    return options
end

-- Mapping Keycap-Name -> Rarity einmal aufbauen, für schnellen Nachschlag
local KeycapToRarity = {}

local function BuildKeycapMap()
    KeycapToRarity = {}
    for _, rarityFolder in ipairs(ReplicatedStorage.Assets.Keycaps:GetChildren()) do
        for _, keycap in ipairs(rarityFolder:GetChildren()) do
            KeycapToRarity[keycap.Name] = rarityFolder.Name
        end
    end
end

BuildKeycapMap()

local function ParseMoneyString(str)
    if type(str) == "number" then
        return str
    end
    if type(str) ~= "string" then
        return 0
    end

    -- $, Kommas und Leerzeichen entfernen
    local cleaned = str:gsub("[%$,%s]", "")

    -- Zahl + optionales Suffix (K/M/B/T) irgendwo im String finden (nicht mehr strikt verankert)
    local number, suffix = cleaned:match("(%-?%d+%.?%d*)(%a?)")
    if not number then
        return 0
    end

    number = tonumber(number) or 0
    suffix = suffix and suffix:upper() or ""

    local multipliers = {
        K = 1e3,
        M = 1e6,
        B = 1e9,
        T = 1e12,
    }

    return number * (multipliers[suffix] or 1)
end

local function FindProximityPrompt(container)
    if not container then return nil end

    -- Falls der Container selbst schon der MeshPart mit dem Prompt ist
    local direct = container:FindFirstChildOfClass("ProximityPrompt")
    if direct then
        return direct
    end

    -- Ansonsten überall drunter suchen (egal ob Model, MeshPart-Child, etc.)
    for _, descendant in ipairs(container:GetDescendants()) do
        if descendant:IsA("ProximityPrompt") then
            return descendant
        end
    end

    return nil
end
local AutoKeyDelay = 0.1
local AutoKey = false
local ToBuy = {"Common"}
local AutoRollKeyCap = false

-- === Collect Keycap ===

Farmsection:CreateSlider({
    Name = "KeyCap Collect Delay",
    Min = 0.01,
    Max = 1,
    CurrentValue = 0.1,
    Rounding = 0.01,
    Flag = "SpeedValue",
    Save = true,
    Callback = function(value)
        AutoKeyDelay = value
    end,
})

Farmsection:CreateToggle({
    Name = "Collect Keycap",
    CurrentValue = false,
    Flag = "AutoCollectKeycap",
    Save = false,
    Callback = function(value)
        AutoKey = value
    end,
})

task.spawn(function()
    while task.wait(0.1) do
        if AutoKey then
            if not YourID or not workspace.Slots:FindFirstChild(YourID) then
                FindYourSlot()
            end

            local slot = YourID and workspace.Slots:FindFirstChild(YourID)
            local keycapFolder = slot
                and slot:FindFirstChild("BasePlayer")
                and slot.BasePlayer:FindFirstChild("Utils")
                and slot.BasePlayer.Utils:FindFirstChild("Keyboard")
                and slot.BasePlayer.Utils.Keyboard:FindFirstChild("Keyboard")
                and slot.BasePlayer.Utils.Keyboard.Keyboard:FindFirstChild("Utils")
                and slot.BasePlayer.Utils.Keyboard.Keyboard.Utils:FindFirstChild("Keycap")

            if keycapFolder then
                for _, v in pairs(keycapFolder:GetChildren()) do
                    if AutoKey and v:GetAttribute("Discovered") == true then
                        RootPart.CFrame = CFrame.new(v.Position + Vector3.new(0, 3, 0))
                        task.wait(AutoKeyDelay)
                    end
                end
            end
        end
    end
end)

-- === Rarity Auswahl ===

Farmsection:CreateDropdown({
    Name = "Rarity to Auto Buy",
    Options = DropdownRarities(),
    CurrentOption = "Common",
    MultipleOptions = true,
    Flag = "GameMode",
    Save = true,
    Callback = function(value)
        if typeof(value) == "table" then
            ToBuy = value
        else
            ToBuy = {value}
        end
    end,
})

-- === Auto Roll Keycap ===

Farmsection:CreateToggle({
    Name = "Auto Roll Keycap",
    CurrentValue = false,
    Flag = "AutoRollKeycap",
    Save = false,
    Callback = function(value)
        AutoRollKeyCap = value
    end,
})

task.spawn(function()
    while task.wait(0.5) do
        if AutoRollKeyCap then
            if not YourID or not workspace.Slots:FindFirstChild(YourID) then
                FindYourSlot()
            end

            local slot = YourID and workspace.Slots:FindFirstChild(YourID)

            local rollBase = slot
                and slot:FindFirstChild("BasePlayer")
                and slot.BasePlayer:FindFirstChild("Utils")
                and slot.BasePlayer.Utils:FindFirstChild("Roll")
                and slot.BasePlayer.Utils.Roll:FindFirstChild("RollKeycapsMain")
                and slot.BasePlayer.Utils.Roll.RollKeycapsMain:FindFirstChild("RollkeyBase")
            
            
            local prompt = FindProximityPrompt(rollBase)

            if prompt then
                Character:MoveTo(rollBase.WorldPivot.Position + Vector3.new(0, 3, 0))
                fireproximityprompt(prompt)
                task.wait(0.5) -- Wartezeit für die Roll-Animation
            end
        end
    end
end)

-- Erkennt automatisch, wenn ein gerolltes Keycap in workspace erscheint
workspace.ChildAdded:Connect(function(newInstance)
    if not AutoRollKeyCap then return end

    local rarity = KeycapToRarity[newInstance.Name]
    if rarity and isInTable(rarity, ToBuy) then
        print("Bekommen:", newInstance.Name, "| Rarity:", rarity)

        -- Versuch: falls das Keycap selbst einen ProximityPrompt zum Kaufen/Einsammeln hat
        task.wait(0.2) -- kurz warten, falls der Prompt erst nachträglich hinzugefügt wird
        local buyPrompt = FindProximityPrompt(newInstance)
        if buyPrompt then
            print("Kaufe:", newInstance.Name)
            fireproximityprompt(buyPrompt)
        else
            print("Kein ProximityPrompt zum Kaufen an", newInstance.Name, "gefunden - Kauf-Mechanik unbekannt")
        end
    end
end)

-- === Auto Buy Upgrade ===

-- Findet den Part unter KeyboardPanel.Model, der tatsächlich Children hat
-- (alle anderen heißen "Part" und sind leer)
-- Generische Version: findet den Buy-Container unter einem beliebigen "Panel"-Objekt
-- (z.B. KeyboardPanel, KeycapsPanel, etc.), egal ob die Sachen im Model oder direkt
-- unter den Part-Kindern liegen
local function FindContainerUnderPanel(panel)
    if not panel then
        print("[Container Debug] Panel ist nil")
        return nil
    end

    for _, child in ipairs(panel:GetChildren()) do
        if child:IsA("BasePart") then
            local surfaceGui = child:FindFirstChildOfClass("SurfaceGui")
            if surfaceGui then
                local container = surfaceGui:FindFirstChild("Container")
                if container then
                    return container
                end
            end
        elseif child:IsA("Model") then
            -- Falls die Sachen doch mal im Model stecken, hier auch durchsuchen
            for _, sub in ipairs(child:GetChildren()) do
                if sub:IsA("BasePart") then
                    local surfaceGui = sub:FindFirstChildOfClass("SurfaceGui")
                    if surfaceGui then
                        local container = surfaceGui:FindFirstChild("Container")
                        if container then
                            return container
                        end
                    end
                end
            end
        end
    end

    print("[Container Debug] Kein Container unter", panel:GetFullName(), "gefunden")
    return nil
end

local function FindUpgradeContainer(slot)
    local keyboardPanel = slot
        and slot:FindFirstChild("BasePlayer")
        and slot.BasePlayer:FindFirstChild("Utils")
        and slot.BasePlayer.Utils:FindFirstChild("Upgrades")
        and slot.BasePlayer.Utils.Upgrades:FindFirstChild("Keyboard")
        and slot.BasePlayer.Utils.Upgrades.Keyboard:FindFirstChild("KeyboardPanel")

    if not keyboardPanel then
        print("[Container Debug] 'KeyboardPanel' nicht gefunden - Pfad davor prüfen")
        return nil
    end

    return FindContainerUnderPanel(keyboardPanel)
end

local function FindKeycapUpgradeContainer(slot)
    local keycapsPanel = slot
        and slot:FindFirstChild("BasePlayer")
        and slot.BasePlayer:FindFirstChild("Utils")
        and slot.BasePlayer.Utils:FindFirstChild("Upgrades")
        and slot.BasePlayer.Utils.Upgrades:FindFirstChild("Keycaps")
        and slot.BasePlayer.Utils.Upgrades.Keycaps:FindFirstChild("KeycapsPanel")

    if not keycapsPanel then
        print("[Container Debug] 'KeycapsPanel' nicht gefunden - Pfad davor prüfen")
        return nil
    end

    return FindContainerUnderPanel(keycapsPanel)
end

local UpgradeOptions = { "LuckMultiplier", "MoneyMultiplier", "SpawnRate", "WalkSpeed" }
local SelectedUpgrade = "LuckMultiplier"
local AutoBuyUpgrade = false

Upgradesection:CreateDropdown({
    Name = "Upgrade to Buy",
    Options = UpgradeOptions,
    CurrentOption = "LuckMultiplier",
    MultipleOptions = false,
    Flag = "UpgradeSelection",
    Save = true,
    Callback = function(value)
        SelectedUpgrade = value
    end,
})

Upgradesection:CreateToggle({
    Name = "Auto Buy Upgrade",
    CurrentValue = false,
    Flag = "AutoBuyUpgrade",
    Save = false,
    Callback = function(value)
        AutoBuyUpgrade = value
    end,
})

task.spawn(function()
    while task.wait(0.5) do
        if AutoBuyUpgrade then
            if not YourID or not workspace.Slots:FindFirstChild(YourID) then
                FindYourSlot()
            end

            local slot = YourID and workspace.Slots:FindFirstChild(YourID)
            if not slot then
                print("[Upgrade Debug] Kein Slot gefunden, YourID:", YourID)
                continue
            end

            local container = FindUpgradeContainer(slot)
            if not container then
                print("[Upgrade Debug] Kein Container gefunden")
                continue
            end

            local upgradeFrame = container:FindFirstChild(SelectedUpgrade)
            if not upgradeFrame then
                print("[Upgrade Debug] Kein Frame namens", SelectedUpgrade, "- vorhanden sind:")
                for _, child in ipairs(container:GetChildren()) do
                    print(" -", child.Name)
                end
                continue
            end

            local buyButton = upgradeFrame:FindFirstChild("Buy")
            if not buyButton then
                print("[Upgrade Debug] Kein 'Buy' Child in", upgradeFrame.Name, "- vorhanden sind:")
                for _, child in ipairs(upgradeFrame:GetChildren()) do
                    print(" -", child.Name, child.ClassName)
                end
                continue
            end

            local priceLabel = buyButton:FindFirstChild("Value")
            local rawPriceText = priceLabel and priceLabel.Text or "NICHT GEFUNDEN"
            local price = priceLabel and ParseMoneyString(priceLabel.Text) or 0

            local moneyStat = Player:FindFirstChild("leaderstats") and Player.leaderstats:FindFirstChild("Money")
            local rawMoneyValue = moneyStat and moneyStat.Value or "NICHT GEFUNDEN"
            local currentMoney = moneyStat and ParseMoneyString(moneyStat.Value) or 0

            print("[Upgrade Debug] Roher Preis-Text:", rawPriceText, "-> geparst:", price)
            print("[Upgrade Debug] Roher Money-Wert:", rawMoneyValue, "-> geparst:", currentMoney)

            if currentMoney < price then
                print("[Upgrade Debug] Nicht genug Geld, überspringe Kauf")
                continue
            end

            print("[Upgrade Debug] Buy Button gefunden:", buyButton:GetFullName())
            print("[Upgrade Debug] ClassName:", buyButton.ClassName)

            local signalsToCheck = {"MouseButton1Click", "MouseButton1Down", "MouseButton1Up", "Activated", "InputBegan"}
            local fired = false

            for _, signalName in ipairs(signalsToCheck) do
                local signal = buyButton[signalName]
                if signal then
                    local connections = getconnections(signal)
                    print("[Upgrade Debug]", signalName, "- Connections:", #connections)
                    if #connections > 0 then
                        for _, c in ipairs(connections) do
                            c:Fire()
                        end
                        fired = true
                    end
                end
            end

            if not fired then
                print("[Upgrade Debug] Keine Connections auf irgendeinem Signal gefunden - checke ClickDetector im Parent")
                local clickDetector = buyButton:FindFirstChildOfClass("ClickDetector")
                    or upgradeFrame:FindFirstChildOfClass("ClickDetector")
                if clickDetector then
                    print("[Upgrade Debug] ClickDetector gefunden:", clickDetector:GetFullName())
                    local cdConnections = getconnections(clickDetector.MouseClick)
                    print("[Upgrade Debug] ClickDetector MouseClick Connections:", #cdConnections)
                    for _, c in ipairs(cdConnections) do
                        c:Fire(Player)
                    end
                end
            end
        end
    end
end)

-- === Auto Buy Keycap Upgrade (KeycapsPanel, z.B. "+1Keycap") ===

local function GetKeycapUpgradeOptions()
    local slot = YourID and workspace.Slots:FindFirstChild(YourID)
    local container = slot and FindKeycapUpgradeContainer(slot)
    local options = {}

    if container then
        for _, child in ipairs(container:GetChildren()) do
            table.insert(options, child.Name)
        end
    end

    if #options == 0 then
        options = {"+1Keycap"} -- Fallback falls Slot beim UI-Aufbau noch nicht existiert
    end

    return options
end

local SelectedKeycapUpgrade = "+1Keycap"
local AutoBuyKeycapUpgrade = false

Upgradesection:CreateDropdown({
    Name = "Keycap Upgrade to Buy",
    Options = GetKeycapUpgradeOptions(),
    CurrentOption = "+1Keycap",
    MultipleOptions = false,
    Flag = "KeycapUpgradeSelection",
    Save = true,
    Callback = function(value)
        SelectedKeycapUpgrade = value
    end,
})

Upgradesection:CreateToggle({
    Name = "Auto Buy Keycap Upgrade",
    CurrentValue = false,
    Flag = "AutoBuyKeycapUpgrade",
    Save = false,
    Callback = function(value)
        AutoBuyKeycapUpgrade = value
    end,
})

task.spawn(function()
    while task.wait(0.5) do
        if AutoBuyKeycapUpgrade then
            if not YourID or not workspace.Slots:FindFirstChild(YourID) then
                FindYourSlot()
            end

            local slot = YourID and workspace.Slots:FindFirstChild(YourID)
            if not slot then
                continue
            end

            local container = FindKeycapUpgradeContainer(slot)
            if not container then
                continue
            end

            local upgradeFrame = container:FindFirstChild(SelectedKeycapUpgrade)
            if not upgradeFrame then
                continue
            end

            local buyButton = upgradeFrame:FindFirstChild("Buy")
            if not buyButton then
                continue
            end

            local priceLabel = buyButton:FindFirstChild("Value")
            local price = priceLabel and ParseMoneyString(priceLabel.Text) or 0

            local moneyStat = Player:FindFirstChild("leaderstats") and Player.leaderstats:FindFirstChild("Money")
            local currentMoney = moneyStat and ParseMoneyString(moneyStat.Value) or 0

            if currentMoney < price then
                continue
            end

            local signalsToCheck = {"MouseButton1Click", "MouseButton1Down", "MouseButton1Up", "Activated", "InputBegan"}
            local fired = false

            for _, signalName in ipairs(signalsToCheck) do
                local signal = buyButton[signalName]
                if signal then
                    local connections = getconnections(signal)
                    if #connections > 0 then
                        for _, c in ipairs(connections) do
                            c:Fire()
                        end
                        fired = true
                    end
                end
            end

            if not fired then
                local clickDetector = buyButton:FindFirstChildOfClass("ClickDetector")
                    or upgradeFrame:FindFirstChildOfClass("ClickDetector")
                if clickDetector then
                    local cdConnections = getconnections(clickDetector.MouseClick)
                    for _, c in ipairs(cdConnections) do
                        c:Fire(Player)
                    end
                end
            end
        end
    end
end)
