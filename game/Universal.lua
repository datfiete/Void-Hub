local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local RootPart = Character:WaitForChild("HumanoidRootPart")
local Executor = getexecutorname()
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local Mouse = Player:GetMouse()

local Avatar = Players:GetUserThumbnailAsync(
    Player.UserId,
    Enum.ThumbnailType.HeadShot,
    Enum.ThumbnailSize.Size150x150
)

local CyberUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/datfiete/Void-Hub/refs/heads/main/CyberUI/load.lua"))()

CyberUI.Theme.Style = "Meng"

local window = CyberUI:CreateWindow({
    Title = "Universal Vaxiron script",
    Subtitle = "by Vaxiron Officials",
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

local ESPtab = window:CreateTab("ESP")
local ESPsection = ESPtab:CreateSection("ESP")
local AIMtab = window:CreateTab("AIM")
local AIMsection = AIMtab:CreateSection("AIM")
local MISCtab = window:CreateTab("MISC")
local MISCsection = MISCtab:CreateSection("MISC")

-- ====== Globale Variablen ======
local BoxESP = false
local SkeletonESP = false
local HealthESP = false
local TracerESP = false
local NameESP = false
local DistanceESP = false

local SoftAim = false
local FOVCircle = false
local RMBDown = false
local CurrentTarget = nil
local FOV = 35
local STRENGTH = 0.15
local FOVCircleRadius = 150
local AimMethod = "Mouse"  -- "Mouse" oder "Camera"
local AlwaysAim = false
local TriggerBot = false
local TriggerKey = Enum.KeyCode.F  -- standardmäßig F

-- MISC Features
local WalkSpeedEnabled = false
local WalkSpeedValue = 16
local JumpPowerEnabled = false
local JumpPowerValue = 50
local InfiniteJump = false
local FlyEnabled = false
local FlySpeed = 50
local NoClipEnabled = false
local AntiAFK = false

-- ====== GUI-Elemente ======
ESPsection:CreateToggle({
    Name = "Box ESP",
    CurrentValue = false,
    Flag = "ESP.BoxESP",
    Callback = function(value) BoxESP = value end,
})

ESPsection:CreateToggle({
    Name = "Skeleton ESP",
    CurrentValue = false,
    Flag = "ESP.SkeletonESP",
    Callback = function(value) SkeletonESP = value end,
})

ESPsection:CreateToggle({
    Name = "Health ESP",
    CurrentValue = false,
    Flag = "ESP.HealthESP",
    Callback = function(value) HealthESP = value end,
})

ESPsection:CreateToggle({
    Name = "Tracer ESP",
    CurrentValue = false,
    Flag = "ESP.TracerESP",
    Callback = function(value) TracerESP = value end,
})

ESPsection:CreateToggle({
    Name = "Name ESP",
    CurrentValue = false,
    Flag = "ESP.NameESP",
    Callback = function(value) NameESP = value end,
})

ESPsection:CreateToggle({
    Name = "Distance ESP",
    CurrentValue = false,
    Flag = "ESP.DistanceESP",
    Callback = function(value) DistanceESP = value end,
})

AIMsection:CreateSlider({
    Name = "Soft Aim Strength",
    Min = 0.01,
    Max = 0.5,
    CurrentValue = 0.15,
    Rounding = 0.01,
    Flag = "Aim.Strength",
    Callback = function(value) STRENGTH = value end,
})

AIMsection:CreateSlider({
    Name = "Aim FOV (degrees)",
    Min = 5,
    Max = 120,
    CurrentValue = 35,
    Rounding = 1,
    Flag = "Aim.FOV",
    Callback = function(value) FOV = value end,
})

AIMsection:CreateToggle({
    Name = "Soft Aim",
    CurrentValue = false,
    Flag = "Aim.SoftAim",
    Callback = function(value)
        SoftAim = value
        if not value then CurrentTarget = nil end
    end,
})

AIMsection:CreateToggle({
    Name = "Always Aim (no RMB)",
    CurrentValue = false,
    Flag = "Aim.AlwaysAim",
    Callback = function(value) AlwaysAim = value end,
})

AIMsection:CreateDropdown({
    Name = "Aim Method",
    CurrentValue = "Mouse",
    Options = { "Mouse", "Camera" },
    Flag = "Aim.Method",
    Callback = function(value) AimMethod = value end,
})

AIMsection:CreateToggle({
    Name = "FOV Circle",
    CurrentValue = false,
    Flag = "Aim.FOVCircle",
    Callback = function(value) FOVCircle = value end,
})

AIMsection:CreateSlider({
    Name = "FOV Circle Radius",
    Min = 50,
    Max = 400,
    CurrentValue = 150,
    Rounding = 1,
    Flag = "Aim.FOVCircleRadius",
    Callback = function(value) FOVCircleRadius = value end,
})

AIMsection:CreateToggle({
    Name = "Trigger Bot",
    CurrentValue = false,
    Flag = "Aim.TriggerBot",
    Callback = function(value) TriggerBot = value end,
})

AIMsection:CreateKeybind({
    Name = "Trigger Key",
    CurrentKey = Enum.KeyCode.F,
    Flag = "Aim.TriggerKey",
    Callback = function(key) TriggerKey = key end,
})

-- MISC Features
MISCsection:CreateToggle({
    Name = "WalkSpeed",
    CurrentValue = false,
    Flag = "MISC.WalkSpeed",
    Callback = function(value) WalkSpeedEnabled = value end,
})

MISCsection:CreateSlider({
    Name = "WalkSpeed Value",
    Min = 16,
    Max = 100,
    CurrentValue = 16,
    Rounding = 1,
    Flag = "MISC.WalkSpeedValue",
    Callback = function(value) WalkSpeedValue = value end,
})

MISCsection:CreateToggle({
    Name = "JumpPower",
    CurrentValue = false,
    Flag = "MISC.JumpPower",
    Callback = function(value) JumpPowerEnabled = value end,
})

MISCsection:CreateSlider({
    Name = "JumpPower Value",
    Min = 50,
    Max = 200,
    CurrentValue = 50,
    Rounding = 1,
    Flag = "MISC.JumpPowerValue",
    Callback = function(value) JumpPowerValue = value end,
})

MISCsection:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Flag = "MISC.InfiniteJump",
    Callback = function(value) InfiniteJump = value end,
})

MISCsection:CreateToggle({
    Name = "Fly",
    CurrentValue = false,
    Flag = "MISC.Fly",
    Callback = function(value) FlyEnabled = value end,
})

MISCsection:CreateSlider({
    Name = "Fly Speed",
    Min = 10,
    Max = 200,
    CurrentValue = 50,
    Rounding = 1,
    Flag = "MISC.FlySpeed",
    Callback = function(value) FlySpeed = value end,
})

MISCsection:CreateToggle({
    Name = "NoClip",
    CurrentValue = false,
    Flag = "MISC.NoClip",
    Callback = function(value) NoClipEnabled = value end,
})

MISCsection:CreateToggle({
    Name = "Anti-AFK",
    CurrentValue = false,
    Flag = "MISC.AntiAFK",
    Callback = function(value) AntiAFK = value end,
})

-- ====== Box ESP ======
task.spawn(function()
    while task.wait(0.5) do
        if BoxESP then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= Player then
                    local char = plr.Character
                    if char and char:FindFirstChild("HumanoidRootPart") and not char:FindFirstChild("EspBox") then
                        local esp = Instance.new("BoxHandleAdornment", char)
                        esp.Adornee = char
                        esp.ZIndex = 0
                        esp.Size = Vector3.new(5, 6, 2)
                        esp.Transparency = 0.5
                        esp.Color3 = Color3.fromRGB(0, 255, 0)
                        esp.AlwaysOnTop = true
                        esp.Name = "EspBox"
                    end
                end
            end
        else
            for _, obj in ipairs(workspace:GetDescendants()) do
                local esp = obj:FindFirstChild("EspBox")
                if esp then esp:Destroy() end
            end
        end
    end
end)

-- ====== Skeleton ESP ======
local SkeletonSettings = { Color = Color3.new(0, 1, 0), Thickness = 2, Transparency = 1 }
local skeletons = {}

local function createLine()
    local line = Drawing.new("Line")
    return line
end

local function removeSkeleton(skeleton)
    for _, line in pairs(skeleton) do
        line:Remove()
    end
end

local function trackPlayer(plr)
    local skeleton = {}
    local function updateSkeleton()
        if not plr.Character or not plr.Character:FindFirstChild("HumanoidRootPart") then
            for _, line in pairs(skeleton) do line.Visible = false end
            return
        end
        local character = plr.Character
        local humanoid = character:FindFirstChild("Humanoid")
        local joints = {}
        if humanoid and humanoid.RigType == Enum.HumanoidRigType.R15 then
            joints = {
                Head = character:FindFirstChild("Head"),
                UpperTorso = character:FindFirstChild("UpperTorso"),
                LowerTorso = character:FindFirstChild("LowerTorso"),
                LeftUpperArm = character:FindFirstChild("LeftUpperArm"),
                LeftLowerArm = character:FindFirstChild("LeftLowerArm"),
                LeftHand = character:FindFirstChild("LeftHand"),
                RightUpperArm = character:FindFirstChild("RightUpperArm"),
                RightLowerArm = character:FindFirstChild("RightLowerArm"),
                RightHand = character:FindFirstChild("RightHand"),
                LeftUpperLeg = character:FindFirstChild("LeftUpperLeg"),
                LeftLowerLeg = character:FindFirstChild("LeftLowerLeg"),
                RightUpperLeg = character:FindFirstChild("RightUpperLeg"),
                RightLowerLeg = character:FindFirstChild("RightLowerLeg"),
            }
        elseif humanoid and humanoid.RigType == Enum.HumanoidRigType.R6 then
            joints = {
                Head = character:FindFirstChild("Head"),
                Torso = character:FindFirstChild("Torso"),
                LeftLeg = character:FindFirstChild("Left Leg"),
                RightLeg = character:FindFirstChild("Right Leg"),
                LeftArm = character:FindFirstChild("Left Arm"),
                RightArm = character:FindFirstChild("Right Arm"),
            }
        end
        local connections = {}
        if humanoid and humanoid.RigType == Enum.HumanoidRigType.R15 then
            connections = {
                {"Head","UpperTorso"}, {"UpperTorso","LowerTorso"},
                {"LowerTorso","LeftUpperLeg"}, {"LeftUpperLeg","LeftLowerLeg"},
                {"LowerTorso","RightUpperLeg"}, {"RightUpperLeg","RightLowerLeg"},
                {"UpperTorso","LeftUpperArm"}, {"LeftUpperArm","LeftLowerArm"},
                {"LeftLowerArm","LeftHand"}, {"UpperTorso","RightUpperArm"},
                {"RightUpperArm","RightLowerArm"}, {"RightLowerArm","RightHand"},
            }
        elseif humanoid and humanoid.RigType == Enum.HumanoidRigType.R6 then
            connections = {
                {"Head","Torso"}, {"Torso","LeftArm"}, {"Torso","RightArm"},
                {"Torso","LeftLeg"}, {"Torso","RightLeg"},
            }
        end
        for index, conn in ipairs(connections) do
            local a = joints[conn[1]]
            local b = joints[conn[2]]
            if a and b then
                local posA, onA = Camera:WorldToViewportPoint(a.Position)
                local posB, onB = Camera:WorldToViewportPoint(b.Position)
                local line = skeleton[index] or createLine()
                skeleton[index] = line
                line.Color = SkeletonSettings.Color
                line.Thickness = SkeletonSettings.Thickness
                line.Transparency = SkeletonSettings.Transparency
                if onA and onB then
                    if conn[2] == "LeftArm" or conn[2] == "RightArm" then
                        posB = Camera:WorldToViewportPoint(b.Position + Vector3.new(0, 0.5, 0))
                    end
                    line.From = Vector2.new(posA.X, posA.Y)
                    line.To = Vector2.new(posB.X, posB.Y)
                    line.Visible = true
                else
                    line.Visible = false
                end
            elseif skeleton[index] then
                skeleton[index].Visible = false
            end
        end
    end
    skeletons[plr] = skeleton
    RunService.RenderStepped:Connect(function()
        if plr and plr.Parent then updateSkeleton()
        else removeSkeleton(skeleton) end
    end)
end

local function untrackPlayer(plr)
    if skeletons[plr] then
        removeSkeleton(skeletons[plr])
        skeletons[plr] = nil
    end
end

Players.PlayerAdded:Connect(function(plr)
    if SkeletonESP and plr ~= Player then trackPlayer(plr) end
end)
Players.PlayerRemoving:Connect(untrackPlayer)

task.spawn(function()
    while task.wait(0.1) do
        if SkeletonESP then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= Player and not skeletons[plr] then trackPlayer(plr) end
            end
        else
            for plr in pairs(skeletons) do untrackPlayer(plr) end
        end
    end
end)

-- ====== Health ESP ======
local healthBars = {}
local function createHealthBar(plr)
    if healthBars[plr] then return end
    local bg = Drawing.new("Line")
    bg.Visible = false
    bg.Thickness = 5
    bg.Color = Color3.fromRGB(0,0,0)
    local bar = Drawing.new("Line")
    bar.Visible = false
    bar.Thickness = 3
    healthBars[plr] = { Background = bg, Bar = bar }
end
local function removeHealthBar(plr)
    if healthBars[plr] then
        healthBars[plr].Background:Remove()
        healthBars[plr].Bar:Remove()
        healthBars[plr] = nil
    end
end

RunService.RenderStepped:Connect(function()
    for plr, bars in pairs(healthBars) do
        if HealthESP and plr.Character then
            local humanoid = plr.Character:FindFirstChild("Humanoid")
            local root = plr.Character:FindFirstChild("HumanoidRootPart")
            if humanoid and root then
                local screen, vis = Camera:WorldToViewportPoint(root.Position)
                if vis then
                    local percent = humanoid.Health / humanoid.MaxHealth
                    local x = screen.X - 30
                    local top = screen.Y - 25
                    local bottom = screen.Y + 25
                    bars.Background.From = Vector2.new(x, top)
                    bars.Background.To = Vector2.new(x, bottom)
                    bars.Bar.From = Vector2.new(x, bottom)
                    bars.Bar.To = Vector2.new(x, bottom - (50 * percent))
                    bars.Bar.Color = Color3.fromHSV(percent * 0.33, 1, 1)
                    bars.Background.Visible = true
                    bars.Bar.Visible = true
                else
                    bars.Background.Visible = false
                    bars.Bar.Visible = false
                end
            end
        else
            bars.Background.Visible = false
            bars.Bar.Visible = false
        end
    end
end)

task.spawn(function()
    while task.wait(0.1) do
        if HealthESP then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= Player and not healthBars[plr] then createHealthBar(plr) end
            end
        else
            for plr in pairs(healthBars) do removeHealthBar(plr) end
        end
    end
end)
Players.PlayerRemoving:Connect(removeHealthBar)

-- ====== Tracer, Name, Distance ESP ======
local tracerLines = {}
local nameLabels = {}
local distLabels = {}

local function createTracer(plr)
    if tracerLines[plr] then return end
    local line = Drawing.new("Line")
    line.Visible = false
    line.Thickness = 1
    line.Color = Color3.fromRGB(255,255,255)
    tracerLines[plr] = line
end

local function createNameLabel(plr)
    if nameLabels[plr] then return end
    local label = Drawing.new("Text")
    label.Visible = false
    label.Size = 14
    label.Center = true
    label.Color = Color3.fromRGB(255,255,255)
    label.Outline = true
    label.OutlineColor = Color3.fromRGB(0,0,0)
    nameLabels[plr] = label
end

local function createDistLabel(plr)
    if distLabels[plr] then return end
    local label = Drawing.new("Text")
    label.Visible = false
    label.Size = 12
    label.Center = true
    label.Color = Color3.fromRGB(200,200,200)
    label.Outline = true
    label.OutlineColor = Color3.fromRGB(0,0,0)
    distLabels[plr] = label
end

local function removeDrawings(plr)
    if tracerLines[plr] then tracerLines[plr]:Remove(); tracerLines[plr] = nil end
    if nameLabels[plr] then nameLabels[plr]:Remove(); nameLabels[plr] = nil end
    if distLabels[plr] then distLabels[plr]:Remove(); distLabels[plr] = nil end
end

RunService.RenderStepped:Connect(function()
    local rootPos = RootPart and RootPart.Position or Vector3.new(0,0,0)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == Player then continue end
        local char = plr.Character
        if not char then
            if tracerLines[plr] then tracerLines[plr].Visible = false end
            if nameLabels[plr] then nameLabels[plr].Visible = false end
            if distLabels[plr] then distLabels[plr].Visible = false end
            continue
        end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then
            if tracerLines[plr] then tracerLines[plr].Visible = false end
            if nameLabels[plr] then nameLabels[plr].Visible = false end
            if distLabels[plr] then distLabels[plr].Visible = false end
            continue
        end
        local pos = hrp.Position
        local screen, visible = Camera:WorldToViewportPoint(pos)
        local screenVec = Vector2.new(screen.X, screen.Y)

        -- Tracer
        if TracerESP then
            if not tracerLines[plr] then createTracer(plr) end
            local line = tracerLines[plr]
            line.Visible = visible
            if visible then
                local bottom = Camera:WorldToViewportPoint(Vector3.new(pos.X, 0, pos.Z))
                line.From = Vector2.new(screen.X, screen.Y)
                line.To = Vector2.new(bottom.X, bottom.Y)
                line.Color = Color3.fromRGB(255,255,255)
            end
        else
            if tracerLines[plr] then tracerLines[plr].Visible = false end
        end

        -- Name
        if NameESP then
            if not nameLabels[plr] then createNameLabel(plr) end
            local label = nameLabels[plr]
            label.Visible = visible
            if visible then
                label.Position = Vector2.new(screen.X, screen.Y - 30)
                label.Text = plr.Name
                label.Color = Color3.fromRGB(255,255,255)
            end
        else
            if nameLabels[plr] then nameLabels[plr].Visible = false end
        end

        -- Distance
        if DistanceESP then
            if not distLabels[plr] then createDistLabel(plr) end
            local label = distLabels[plr]
            label.Visible = visible
            if visible then
                label.Position = Vector2.new(screen.X, screen.Y + 20)
                local dist = (rootPos - pos).Magnitude
                label.Text = string.format("%.1f m", dist)
                label.Color = Color3.fromRGB(200,200,200)
            end
        else
            if distLabels[plr] then distLabels[plr].Visible = false end
        end
    end
end)

Players.PlayerRemoving:Connect(removeDrawings)

-- ====== Soft Aim (Verbesserte Version) ======
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then RMBDown = true end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        RMBDown = false
        CurrentTarget = nil
    end
end)

local function GetTarget()
    local closest = nil
    local closestAngle = FOV
    local char = Player.Character
    if not char then return nil end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == Player then continue end
        local eChar = plr.Character
        if not eChar then continue end
        local head = eChar:FindFirstChild("Head")
        local hrp = eChar:FindFirstChild("HumanoidRootPart")
        if head and hrp then
            local dist = (root.Position - hrp.Position).Magnitude
            if dist <= 300 then
                local direction = (head.Position - Camera.CFrame.Position).Unit
                local dot = math.clamp(Camera.CFrame.LookVector:Dot(direction), -1, 1)
                local angle = math.deg(math.acos(dot))
                if angle < closestAngle then
                    closestAngle = angle
                    closest = head
                end
            end
        end
    end
    return closest
end

-- Funktion zur Mausbewegung
local function MoveMouseTo(targetPos)
    local viewport = Camera.ViewportSize
    local center = viewport / 2
    local deltaX = targetPos.X - center.X
    local deltaY = targetPos.Y - center.Y
    -- Sanfte Bewegung
    local smoothX = deltaX * STRENGTH
    local smoothY = deltaY * STRENGTH
    Mouse.X = Mouse.X + smoothX
    Mouse.Y = Mouse.Y + smoothY
end

-- Hauptschleife für Aim
RunService.RenderStepped:Connect(function()
    local shouldAim = false
    if AlwaysAim then
        shouldAim = true
    elseif SoftAim and RMBDown then
        shouldAim = true
    end

    if shouldAim then
        if not CurrentTarget then CurrentTarget = GetTarget() end
        if CurrentTarget then
            if AimMethod == "Mouse" then
                -- Ziel in Bildschirmkoordinaten
                local screenPos, onScreen = Camera:WorldToViewportPoint(CurrentTarget.Position)
                if onScreen then
                    MoveMouseTo(Vector2.new(screenPos.X, screenPos.Y))
                end
            else
                -- Kamera-CFrame-Methode
                local camPos = Camera.CFrame.Position
                local aimDir = (CurrentTarget.Position - camPos).Unit
                local smoothDir = Camera.CFrame.LookVector:Lerp(aimDir, STRENGTH)
                Camera.CFrame = CFrame.lookAt(camPos, camPos + smoothDir)
            end
        end
    else
        CurrentTarget = nil
    end
end)

-- ====== FOV Circle ======
local fovCircle = Drawing.new("Circle")
fovCircle.Visible = false
fovCircle.Thickness = 1
fovCircle.Color = Color3.fromRGB(255,255,255)
fovCircle.Filled = false
fovCircle.NumSides = 64

RunService.RenderStepped:Connect(function()
    if FOVCircle then
        local center = Camera.ViewportSize / 2
        fovCircle.Position = center
        fovCircle.Radius = FOVCircleRadius
        fovCircle.Visible = true
    else
        fovCircle.Visible = false
    end
end)

-- ====== Trigger Bot ======
UserInputService.InputBegan:Connect(function(input)
    if TriggerBot and input.KeyCode == TriggerKey then
        -- Prüfe ob Ziel im Fadenkreuz ist (Mitte des Bildschirms)
        local center = Camera.ViewportSize / 2
        local ray = Camera:ViewportPointToRay(center.X, center.Y)
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Blacklist
        params.FilterDescendantsInstances = {Player.Character}
        local hit = workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
        if hit then
            local part = hit.Instance
            local char = part:FindFirstAncestorOfClass("Model")
            if char then
                local plr = Players:GetPlayerFromCharacter(char)
                if plr and plr ~= Player then
                    -- Schießen simulieren (Mausklick)
                    Mouse1click()
                end
            end
        end
    end
end)

-- ====== MISC Features ======
-- WalkSpeed & JumpPower
local function updateMovement()
    local char = Player.Character
    if not char then return end
    local humanoid = char:FindFirstChild("Humanoid")
    if not humanoid then return end
    if WalkSpeedEnabled then
        humanoid.WalkSpeed = WalkSpeedValue
    else
        humanoid.WalkSpeed = 16
    end
    if JumpPowerEnabled then
        humanoid.JumpPower = JumpPowerValue
    else
        humanoid.JumpPower = 50
    end
end

-- Überwache Charakterwechsel
Player.CharacterAdded:Connect(function(newChar)
    Character = newChar
    RootPart = newChar:WaitForChild("HumanoidRootPart")
    task.wait(0.5)
    updateMovement()
end)

-- Regelmäßiges Update
task.spawn(function()
    while task.wait(0.5) do
        updateMovement()
    end
end)

-- Infinite Jump
local debounce = false
UserInputService.InputBegan:Connect(function(input)
    if InfiniteJump and input.KeyCode == Enum.KeyCode.Space then
        if debounce then return end
        debounce = true
        local char = Player.Character
        if char then
            local humanoid = char:FindFirstChild("Humanoid")
            if humanoid then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
        task.wait(0.1)
        debounce = false
    end
end)

-- Fly
local flyEnabled = false
local flyBodyVelocity = nil
local flyBodyGyro = nil

local function startFly()
    local char = Player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local humanoid = char:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.PlatformStand = true
    end
    flyBodyVelocity = Instance.new("BodyVelocity")
    flyBodyVelocity.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    flyBodyVelocity.Parent = hrp
    flyBodyGyro = Instance.new("BodyGyro")
    flyBodyGyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
    flyBodyGyro.Parent = hrp
    flyEnabled = true
end

local function stopFly()
    if flyBodyVelocity then flyBodyVelocity:Destroy(); flyBodyVelocity = nil end
    if flyBodyGyro then flyBodyGyro:Destroy(); flyBodyGyro = nil end
    local char = Player.Character
    if char then
        local humanoid = char:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.PlatformStand = false
        end
    end
    flyEnabled = false
end

UserInputService.InputBegan:Connect(function(input)
    if FlyEnabled and input.KeyCode == Enum.KeyCode.F then
        if not flyEnabled then
            startFly()
        else
            stopFly()
        end
    end
end)

-- Fly Bewegung (WASD und Maus)
RunService.RenderStepped:Connect(function()
    if FlyEnabled and flyEnabled and flyBodyVelocity and flyBodyGyro then
        local char = Player.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local cameraCF = Camera.CFrame
        local forward = cameraCF.LookVector
        local right = cameraCF.RightVector
        local up = cameraCF.UpVector
        local move = Vector3.new(0,0,0)
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + forward end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - forward end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - right end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + right end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + up end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move = move - up end
        if move.Magnitude > 0 then
            move = move.Unit * FlySpeed
        end
        flyBodyVelocity.Velocity = move
        flyBodyGyro.CFrame = cameraCF
    end
end)

-- NoClip
local function setNoClip(enabled)
    local char = Player.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = not enabled
        end
    end
end

task.spawn(function()
    while task.wait(0.5) do
        if NoClipEnabled then
            setNoClip(true)
        else
            setNoClip(false)
        end
    end
end)

-- Anti-AFK
local vu = game:GetService("VirtualUser")
task.spawn(function()
    while task.wait(60) do
        if AntiAFK then
            vu:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            task.wait(0.1)
            vu:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        end
    end
end)

-- ====== Aufräumen ======
Players.PlayerRemoving:Connect(function(plr)
    removeDrawings(plr)
end)

-- ====== Ende ======
