--[[
    Universal Vaxiron Script - Improved ESP + Fixed Aimbot
    Features:
    - Box ESP (2D corners)
    - Skeleton ESP (R6 + R15)
    - Body ESP (filled body highlight / chams style)
    - Health Bar ESP
    - Tracer ESP
    - Name + Distance ESP
    - Soft Aim (Mouse / Camera) with better targeting
    - FOV Circle
    - Trigger Bot
    - WalkSpeed / JumpPower / Infinite Jump / Fly / NoClip / Anti-AFK
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local RootPart = Character:WaitForChild("HumanoidRootPart")
local Camera = workspace.CurrentCamera
local Mouse = Player:GetMouse()

local Executor = (getexecutorname and getexecutorname()) or "Unknown"

local Avatar = Players:GetUserThumbnailAsync(
    Player.UserId,
    Enum.ThumbnailType.HeadShot,
    Enum.ThumbnailSize.Size150x150
)

-- Load UI
local CyberUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/datfiete/Void-Hub/refs/heads/main/CyberUI%20-%20Kopie/load.lua"))()
CyberUI.Theme.Style = "Meng"

local window = CyberUI:CreateWindow({
    Title = "Universal Vaxiron Script",
    Subtitle = "Improved ESP + Fixed Aimbot",
    BackgroundImage = "rbxassetid://106318186489675",
    Logo = "rbxassetid://128228297210141",
    Badges = {
        { Text = "Void Hub | v1.1" },
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

-- ====== GLOBALS ======
local BoxESP = false
local SkeletonESP = false
local BodyESP = false
local HealthESP = false
local TracerESP = false
local NameESP = false
local DistanceESP = false

local SoftAim = false
local FOVCircle = false
local RMBDown = false
local CurrentTarget = nil
local FOV = 35
local STRENGTH = 0.18
local FOVCircleRadius = 150
local AimMethod = "Mouse"          -- "Mouse" or "Camera"
local AlwaysAim = false
local TriggerBot = false
local TriggerKey = Enum.KeyCode.F
local AimPart = "Head"             -- "Head", "HumanoidRootPart", "UpperTorso"

-- MISC
local WalkSpeedEnabled = false
local WalkSpeedValue = 16
local JumpPowerEnabled = false
local JumpPowerValue = 50
local InfiniteJump = false
local FlyEnabled = false
local FlySpeed = 50
local NoClipEnabled = false
local AntiAFK = false

-- ESP Settings
local ESPSettings = {
    MaxDistance = 900,
    TeamCheck = false,
    BoxColor = Color3.fromRGB(0, 255, 120),
    SkeletonColor = Color3.fromRGB(0, 255, 120),
    BodyColor = Color3.fromRGB(0, 200, 255),
    BodyTransparency = 0.55,
    TracerColor = Color3.fromRGB(255, 255, 255),
    NameColor = Color3.fromRGB(255, 255, 255),
    HealthBarWidth = 4,
}

-- Drawing storage
local drawings = {
    Boxes = {},
    Skeletons = {},
    Bodies = {},      -- Body ESP (Highlight or Drawing)
    HealthBars = {},
    Tracers = {},
    Labels = {},
}

-- ====== HELPERS ======
local function isAlive(plr)
    local char = plr.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    return hum and root and hum.Health > 0
end

local function shouldShow(plr)
    if plr == Player then return false end
    if not isAlive(plr) then return false end
    if ESPSettings.TeamCheck and plr.Team and Player.Team and plr.Team == Player.Team then
        return false
    end
    return true
end

local function getDistance(plr)
    local root = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
    if not root or not RootPart then return math.huge end
    return (root.Position - RootPart.Position).Magnitude
end

local function removeAllDrawings(plr)
    if drawings.Boxes[plr] then
        for _, line in pairs(drawings.Boxes[plr]) do
            pcall(function() line:Remove() end)
        end
        drawings.Boxes[plr] = nil
    end
    if drawings.Skeletons[plr] then
        for _, line in pairs(drawings.Skeletons[plr]) do
            pcall(function() line:Remove() end)
        end
        drawings.Skeletons[plr] = nil
    end
    if drawings.Bodies[plr] then
        pcall(function() drawings.Bodies[plr]:Destroy() end)
        drawings.Bodies[plr] = nil
    end
    if drawings.HealthBars[plr] then
        pcall(function() drawings.HealthBars[plr].Background:Remove() end)
        pcall(function() drawings.HealthBars[plr].Bar:Remove() end)
        drawings.HealthBars[plr] = nil
    end
    if drawings.Tracers[plr] then
        pcall(function() drawings.Tracers[plr]:Remove() end)
        drawings.Tracers[plr] = nil
    end
    if drawings.Labels[plr] then
        pcall(function() drawings.Labels[plr]:Remove() end)
        drawings.Labels[plr] = nil
    end
end

-- ====== DRAWING CREATORS ======
local function createBox()
    local box = {
        TL = Drawing.new("Line"), TR = Drawing.new("Line"),
        BL = Drawing.new("Line"), BR = Drawing.new("Line"),
        L1 = Drawing.new("Line"), L2 = Drawing.new("Line"),
        R1 = Drawing.new("Line"), R2 = Drawing.new("Line"),
    }
    for _, line in pairs(box) do
        line.Visible = false
        line.Thickness = 1.6
        line.Color = ESPSettings.BoxColor
    end
    return box
end

local function createSkeleton()
    local lines = {}
    for i = 1, 14 do
        local line = Drawing.new("Line")
        line.Visible = false
        line.Thickness = 1.5
        line.Color = ESPSettings.SkeletonColor
        lines[i] = line
    end
    return lines
end

local function createHealthBar()
    local bg = Drawing.new("Line")
    local bar = Drawing.new("Line")
    bg.Thickness = ESPSettings.HealthBarWidth + 2
    bg.Color = Color3.new(0, 0, 0)
    bg.Visible = false
    bar.Thickness = ESPSettings.HealthBarWidth
    bar.Visible = false
    return { Background = bg, Bar = bar }
end

local function createTracer()
    local line = Drawing.new("Line")
    line.Visible = false
    line.Thickness = 1.2
    line.Color = ESPSettings.TracerColor
    return line
end

local function createLabel()
    local text = Drawing.new("Text")
    text.Visible = false
    text.Size = 13
    text.Center = true
    text.Outline = true
    text.OutlineColor = Color3.new(0, 0, 0)
    text.Color = ESPSettings.NameColor
    text.Font = 2
    return text
end

-- Body ESP using Highlight (best looking & performant)
local function createBodyESP(plr)
    if drawings.Bodies[plr] then return end
    local char = plr.Character
    if not char then return end

    local highlight = Instance.new("Highlight")
    highlight.Name = "BodyESP"
    highlight.Adornee = char
    highlight.FillColor = ESPSettings.BodyColor
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = ESPSettings.BodyTransparency
    highlight.OutlineTransparency = 0.3
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = char
    drawings.Bodies[plr] = highlight
end

-- ====== MAIN ESP UPDATE ======
local function updateESP()
    local cam = workspace.CurrentCamera
    if not cam then return end

    for _, plr in ipairs(Players:GetPlayers()) do
        if not shouldShow(plr) then
            if drawings.Boxes[plr] then for _, l in pairs(drawings.Boxes[plr]) do l.Visible = false end end
            if drawings.Skeletons[plr] then for _, l in pairs(drawings.Skeletons[plr]) do l.Visible = false end end
            if drawings.Bodies[plr] then drawings.Bodies[plr].Enabled = false end
            if drawings.HealthBars[plr] then
                drawings.HealthBars[plr].Background.Visible = false
                drawings.HealthBars[plr].Bar.Visible = false
            end
            if drawings.Tracers[plr] then drawings.Tracers[plr].Visible = false end
            if drawings.Labels[plr] then drawings.Labels[plr].Visible = false end
            continue
        end

        local char = plr.Character
        local hum = char:FindFirstChildOfClass("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        local head = char:FindFirstChild("Head")
        if not (hum and root and head) then continue end

        local dist = getDistance(plr)
        if dist > ESPSettings.MaxDistance then
            removeAllDrawings(plr)
            continue
        end

        local rootPos, rootVis = cam:WorldToViewportPoint(root.Position)
        local headPos = cam:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
        local legPos = cam:WorldToViewportPoint(root.Position - Vector3.new(0, 3.2, 0))
        local onScreen = rootVis and rootPos.Z > 0

        -- ===== BODY ESP =====
        if BodyESP then
            if not drawings.Bodies[plr] or not drawings.Bodies[plr].Parent then
                createBodyESP(plr)
            end
            if drawings.Bodies[plr] then
                drawings.Bodies[plr].Enabled = true
                drawings.Bodies[plr].FillColor = ESPSettings.BodyColor
                drawings.Bodies[plr].FillTransparency = ESPSettings.BodyTransparency
            end
        elseif drawings.Bodies[plr] then
            drawings.Bodies[plr].Enabled = false
        end

        -- ===== BOX ESP =====
        if BoxESP and onScreen then
            if not drawings.Boxes[plr] then drawings.Boxes[plr] = createBox() end
            local box = drawings.Boxes[plr]
            local height = math.abs(headPos.Y - legPos.Y)
            local width = height / 1.85
            local x, y = rootPos.X, headPos.Y

            local tl = Vector2.new(x - width/2, y)
            local tr = Vector2.new(x + width/2, y)
            local bl = Vector2.new(x - width/2, y + height)
            local br = Vector2.new(x + width/2, y + height)
            local corner = width * 0.28

            box.TL.From = tl; box.TL.To = Vector2.new(tl.X + corner, tl.Y)
            box.TR.From = tr; box.TR.To = Vector2.new(tr.X - corner, tr.Y)
            box.BL.From = bl; box.BL.To = Vector2.new(bl.X + corner, bl.Y)
            box.BR.From = br; box.BR.To = Vector2.new(br.X - corner, br.Y)

            box.L1.From = tl; box.L1.To = Vector2.new(tl.X, tl.Y + corner)
            box.L2.From = bl; box.L2.To = Vector2.new(bl.X, bl.Y - corner)
            box.R1.From = tr; box.R1.To = Vector2.new(tr.X, tr.Y + corner)
            box.R2.From = br; box.R2.To = Vector2.new(br.X, br.Y - corner)

            for _, line in pairs(box) do
                line.Visible = true
                line.Color = ESPSettings.BoxColor
            end
        elseif drawings.Boxes[plr] then
            for _, line in pairs(drawings.Boxes[plr]) do line.Visible = false end
        end

        -- ===== SKELETON ESP =====
        if SkeletonESP and onScreen then
            if not drawings.Skeletons[plr] then drawings.Skeletons[plr] = createSkeleton() end
            local lines = drawings.Skeletons[plr]

            local function getPart(name)
                return char:FindFirstChild(name)
            end

            local isR15 = hum.RigType == Enum.HumanoidRigType.R15
            local joints = {}
            if isR15 then
                joints = {
                    Head = getPart("Head"), UpperTorso = getPart("UpperTorso"), LowerTorso = getPart("LowerTorso"),
                    LeftUpperArm = getPart("LeftUpperArm"), LeftLowerArm = getPart("LeftLowerArm"), LeftHand = getPart("LeftHand"),
                    RightUpperArm = getPart("RightUpperArm"), RightLowerArm = getPart("RightLowerArm"), RightHand = getPart("RightHand"),
                    LeftUpperLeg = getPart("LeftUpperLeg"), LeftLowerLeg = getPart("LeftLowerLeg"),
                    RightUpperLeg = getPart("RightUpperLeg"), RightLowerLeg = getPart("RightLowerLeg"),
                }
            else
                joints = {
                    Head = getPart("Head"), Torso = getPart("Torso"),
                    LeftArm = getPart("Left Arm"), RightArm = getPart("Right Arm"),
                    LeftLeg = getPart("Left Leg"), RightLeg = getPart("Right Leg"),
                }
            end

            local connections = isR15 and {
                {"Head","UpperTorso"}, {"UpperTorso","LowerTorso"},
                {"UpperTorso","LeftUpperArm"}, {"LeftUpperArm","LeftLowerArm"}, {"LeftLowerArm","LeftHand"},
                {"UpperTorso","RightUpperArm"}, {"RightUpperArm","RightLowerArm"}, {"RightLowerArm","RightHand"},
                {"LowerTorso","LeftUpperLeg"}, {"LeftUpperLeg","LeftLowerLeg"},
                {"LowerTorso","RightUpperLeg"}, {"RightUpperLeg","RightLowerLeg"},
            } or {
                {"Head","Torso"}, {"Torso","LeftArm"}, {"Torso","RightArm"},
                {"Torso","LeftLeg"}, {"Torso","RightLeg"},
            }

            for i, conn in ipairs(connections) do
                local a = joints[conn[1]]
                local b = joints[conn[2]]
                if a and b then
                    local posA, onA = cam:WorldToViewportPoint(a.Position)
                    local posB, onB = cam:WorldToViewportPoint(b.Position)
                    if onA and onB and posA.Z > 0 and posB.Z > 0 then
                        lines[i].From = Vector2.new(posA.X, posA.Y)
                        lines[i].To = Vector2.new(posB.X, posB.Y)
                        lines[i].Visible = true
                        lines[i].Color = ESPSettings.SkeletonColor
                    else
                        lines[i].Visible = false
                    end
                else
                    lines[i].Visible = false
                end
            end
        elseif drawings.Skeletons[plr] then
            for _, line in pairs(drawings.Skeletons[plr]) do line.Visible = false end
        end

        -- ===== HEALTH BAR =====
        if HealthESP and onScreen then
            if not drawings.HealthBars[plr] then drawings.HealthBars[plr] = createHealthBar() end
            local bars = drawings.HealthBars[plr]
            local percent = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
            local height = math.abs(headPos.Y - legPos.Y)
            local x = rootPos.X - (height / 1.85) / 2 - 9
            local top, bottom = headPos.Y, legPos.Y

            bars.Background.From = Vector2.new(x, top)
            bars.Background.To = Vector2.new(x, bottom)
            bars.Background.Visible = true

            bars.Bar.From = Vector2.new(x, bottom)
            bars.Bar.To = Vector2.new(x, bottom - (height * percent))
            bars.Bar.Color = Color3.fromHSV(percent * 0.33, 1, 1)
            bars.Bar.Visible = true
        elseif drawings.HealthBars[plr] then
            drawings.HealthBars[plr].Background.Visible = false
            drawings.HealthBars[plr].Bar.Visible = false
        end

        -- ===== TRACER =====
        if TracerESP and onScreen then
            if not drawings.Tracers[plr] then drawings.Tracers[plr] = createTracer() end
            local line = drawings.Tracers[plr]
            local screenBottom = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y)
            line.From = screenBottom
            line.To = Vector2.new(rootPos.X, rootPos.Y)
            line.Visible = true
            line.Color = ESPSettings.TracerColor
        elseif drawings.Tracers[plr] then
            drawings.Tracers[plr].Visible = false
        end

        -- ===== NAME + DISTANCE =====
        if (NameESP or DistanceESP) and onScreen then
            if not drawings.Labels[plr] then drawings.Labels[plr] = createLabel() end
            local label = drawings.Labels[plr]
            local text = ""
            if NameESP then text = plr.Name end
            if DistanceESP then
                text = text .. (text ~= "" and "\n" or "") .. string.format("[%.0fm]", dist)
            end
            label.Text = text
            label.Position = Vector2.new(rootPos.X, headPos.Y - 18)
            label.Visible = true
        elseif drawings.Labels[plr] then
            drawings.Labels[plr].Visible = false
        end
    end
end

RunService.RenderStepped:Connect(updateESP)
Players.PlayerRemoving:Connect(removeAllDrawings)

-- Keep RootPart updated
Player.CharacterAdded:Connect(function(char)
    Character = char
    RootPart = char:WaitForChild("HumanoidRootPart", 5)
end)

-- ====== GUI - ESP ======
ESPsection:CreateToggle({
    Name = "Box ESP",
    CurrentValue = false,
    Flag = "ESP.BoxESP",
    Callback = function(v) BoxESP = v end,
})

ESPsection:CreateToggle({
    Name = "Skeleton ESP",
    CurrentValue = false,
    Flag = "ESP.SkeletonESP",
    Callback = function(v) SkeletonESP = v end,
})

ESPsection:CreateToggle({
    Name = "Body ESP (Highlight)",
    CurrentValue = false,
    Flag = "ESP.BodyESP",
    Callback = function(v)
        BodyESP = v
        if not v then
            for plr, hl in pairs(drawings.Bodies) do
                if hl then hl.Enabled = false end
            end
        end
    end,
})

ESPsection:CreateToggle({
    Name = "Health ESP",
    CurrentValue = false,
    Flag = "ESP.HealthESP",
    Callback = function(v) HealthESP = v end,
})

ESPsection:CreateToggle({
    Name = "Tracer ESP",
    CurrentValue = false,
    Flag = "ESP.TracerESP",
    Callback = function(v) TracerESP = v end,
})

ESPsection:CreateToggle({
    Name = "Name ESP",
    CurrentValue = false,
    Flag = "ESP.NameESP",
    Callback = function(v) NameESP = v end,
})

ESPsection:CreateToggle({
    Name = "Distance ESP",
    CurrentValue = false,
    Flag = "ESP.DistanceESP",
    Callback = function(v) DistanceESP = v end,
})

ESPsection:CreateToggle({
    Name = "Team Check",
    CurrentValue = false,
    Flag = "ESP.TeamCheck",
    Callback = function(v) ESPSettings.TeamCheck = v end,
})

ESPsection:CreateSlider({
    Name = "Max Distance",
    Min = 100,
    Max = 2000,
    CurrentValue = 900,
    Rounding = 50,
    Flag = "ESP.MaxDistance",
    Callback = function(v) ESPSettings.MaxDistance = v end,
})

-- ====== AIMBOT (FIXED & IMPROVED) ======
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        RMBDown = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        RMBDown = false
        CurrentTarget = nil
    end
end)

local function GetClosestTarget()
    local closest = nil
    local closestAngle = FOV
    local myChar = Player.Character
    if not myChar then return nil end
    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end

    local camPos = Camera.CFrame.Position
    local lookVec = Camera.CFrame.LookVector

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == Player then continue end
        if ESPSettings.TeamCheck and plr.Team and Player.Team and plr.Team == Player.Team then continue end

        local eChar = plr.Character
        if not eChar then continue end
        local hum = eChar:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then continue end

        local targetPart = eChar:FindFirstChild(AimPart) or eChar:FindFirstChild("Head") or eChar:FindFirstChild("HumanoidRootPart")
        if not targetPart then continue end

        local dist = (myRoot.Position - targetPart.Position).Magnitude
        if dist > 450 then continue end

        local direction = (targetPart.Position - camPos).Unit
        local dot = math.clamp(lookVec:Dot(direction), -1, 1)
        local angle = math.deg(math.acos(dot))

        if angle < closestAngle then
            closestAngle = angle
            closest = targetPart
        end
    end
    return closest
end

-- Smooth mouse move (works on most executors)
local function SmoothMoveMouse(targetScreenPos)
    local viewport = Camera.ViewportSize
    local center = viewport / 2
    local deltaX = (targetScreenPos.X - center.X) * STRENGTH
    local deltaY = (targetScreenPos.Y - center.Y) * STRENGTH

    if mousemoverel then
        mousemoverel(deltaX, deltaY)
    else
        -- Fallback
        local current = UserInputService:GetMouseLocation()
        mousemoveabs(current.X + deltaX, current.Y + deltaY)
    end
end

RunService.RenderStepped:Connect(function()
    local shouldAim = SoftAim and (AlwaysAim or RMBDown)

    if shouldAim then
        if not CurrentTarget or not CurrentTarget.Parent then
            CurrentTarget = GetClosestTarget()
        end

        if CurrentTarget then
            if AimMethod == "Mouse" then
                local screenPos, onScreen = Camera:WorldToViewportPoint(CurrentTarget.Position)
                if onScreen and screenPos.Z > 0 then
                    SmoothMoveMouse(Vector2.new(screenPos.X, screenPos.Y))
                end
            else
                -- Camera method
                local camPos = Camera.CFrame.Position
                local aimDir = (CurrentTarget.Position - camPos).Unit
                local newLook = Camera.CFrame.LookVector:Lerp(aimDir, STRENGTH)
                Camera.CFrame = CFrame.lookAt(camPos, camPos + newLook)
            end
        end
    else
        CurrentTarget = nil
    end
end)

-- FOV Circle
local fovCircle = Drawing.new("Circle")
fovCircle.Visible = false
fovCircle.Thickness = 1.5
fovCircle.Color = Color3.fromRGB(255, 255, 255)
fovCircle.Filled = false
fovCircle.NumSides = 64
fovCircle.Transparency = 0.3

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

-- Trigger Bot
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if not TriggerBot then return end
    if input.KeyCode ~= TriggerKey then return end

    local center = Camera.ViewportSize / 2
    local ray = Camera:ViewportPointToRay(center.X, center.Y)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {Player.Character}

    local result = workspace:Raycast(ray.Origin, ray.Direction * 1200, params)
    if result then
        local model = result.Instance:FindFirstAncestorOfClass("Model")
        if model then
            local targetPlayer = Players:GetPlayerFromCharacter(model)
            if targetPlayer and targetPlayer ~= Player then
                if mouse1click then
                    mouse1click()
                elseif Mouse1click then
                    Mouse1click()
                end
            end
        end
    end
end)

-- AIM GUI
AIMsection:CreateToggle({
    Name = "Soft Aim",
    CurrentValue = false,
    Flag = "Aim.SoftAim",
    Callback = function(v)
        SoftAim = v
        if not v then CurrentTarget = nil end
    end,
})

AIMsection:CreateToggle({
    Name = "Always Aim (no RMB needed)",
    CurrentValue = false,
    Flag = "Aim.AlwaysAim",
    Callback = function(v) AlwaysAim = v end,
})

AIMsection:CreateDropdown({
    Name = "Aim Method",
    CurrentValue = "Mouse",
    Options = {"Mouse", "Camera"},
    Flag = "Aim.Method",
    Callback = function(v) AimMethod = v end,
})

AIMsection:CreateDropdown({
    Name = "Aim Part",
    CurrentValue = "Head",
    Options = {"Head", "HumanoidRootPart", "UpperTorso"},
    Flag = "Aim.Part",
    Callback = function(v) AimPart = v end,
})

AIMsection:CreateSlider({
    Name = "Aim Strength",
    Min = 0.05,
    Max = 0.6,
    CurrentValue = 0.18,
    Rounding = 0.01,
    Flag = "Aim.Strength",
    Callback = function(v) STRENGTH = v end,
})

AIMsection:CreateSlider({
    Name = "Aim FOV (degrees)",
    Min = 5,
    Max = 120,
    CurrentValue = 35,
    Rounding = 1,
    Flag = "Aim.FOV",
    Callback = function(v) FOV = v end,
})

AIMsection:CreateToggle({
    Name = "FOV Circle",
    CurrentValue = false,
    Flag = "Aim.FOVCircle",
    Callback = function(v) FOVCircle = v end,
})

AIMsection:CreateSlider({
    Name = "FOV Circle Radius",
    Min = 40,
    Max = 450,
    CurrentValue = 150,
    Rounding = 5,
    Flag = "Aim.FOVCircleRadius",
    Callback = function(v) FOVCircleRadius = v end,
})

AIMsection:CreateToggle({
    Name = "Trigger Bot",
    CurrentValue = false,
    Flag = "Aim.TriggerBot",
    Callback = function(v) TriggerBot = v end,
})

AIMsection:CreateKeybind({
    Name = "Trigger Key",
    CurrentKey = Enum.KeyCode.F,
    Flag = "Aim.TriggerKey",
    Callback = function(key) TriggerKey = key end,
})

-- ====== MISC ======
local function updateMovement()
    local char = Player.Character
    if not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    if WalkSpeedEnabled then
        humanoid.WalkSpeed = WalkSpeedValue
    else
        humanoid.WalkSpeed = 16
    end

    if JumpPowerEnabled then
        humanoid.JumpPower = JumpPowerValue
        humanoid.JumpHeight = JumpPowerValue / 3.5   -- modern games use JumpHeight
    else
        humanoid.JumpPower = 50
    end
end

Player.CharacterAdded:Connect(function(newChar)
    Character = newChar
    RootPart = newChar:WaitForChild("HumanoidRootPart", 5)
    task.wait(0.4)
    updateMovement()
end)

task.spawn(function()
    while task.wait(0.4) do
        updateMovement()
    end
end)

-- Infinite Jump
local jumpDebounce = false
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if InfiniteJump and input.KeyCode == Enum.KeyCode.Space and not jumpDebounce then
        jumpDebounce = true
        local char = Player.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
        task.wait(0.12)
        jumpDebounce = false
    end
end)

-- ==================== FLY (FIXED - no more weird floating) ====================
local flyActive = false
local flyBV, flyBG

-- Aggressively remove ANY leftover BodyMovers that cause floating/spinning
local function cleanFlyRemnants(char)
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    for _, obj in ipairs(hrp:GetChildren()) do
        if obj:IsA("BodyVelocity") or obj:IsA("BodyGyro") or obj:IsA("BodyPosition")
            or obj:IsA("LinearVelocity") or obj:IsA("AngularVelocity")
            or obj.Name == "VaxironFlyBV" or obj.Name == "VaxironFlyBG" then
            pcall(function() obj:Destroy() end)
        end
    end

    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.PlatformStand = false
        -- Force humanoid back to normal physics
        pcall(function()
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end)
    end
end

local function stopFly()
    flyActive = false

    if flyBV then
        pcall(function() flyBV:Destroy() end)
        flyBV = nil
    end
    if flyBG then
        pcall(function() flyBG:Destroy() end)
        flyBG = nil
    end

    -- Extra safety: clean everything on current character
    cleanFlyRemnants(Player.Character)
end

local function startFly()
    -- Always clean first so we never stack movers
    stopFly()

    local char = Player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    hum.PlatformStand = true

    flyBV = Instance.new("BodyVelocity")
    flyBV.Name = "VaxironFlyBV"
    flyBV.MaxForce = Vector3.new(40000, 40000, 40000)
    flyBV.Velocity = Vector3.zero
    flyBV.Parent = hrp

    flyBG = Instance.new("BodyGyro")
    flyBG.Name = "VaxironFlyBG"
    flyBG.MaxTorque = Vector3.new(40000, 40000, 40000)
    flyBG.P = 3000
    flyBG.D = 500
    flyBG.Parent = hrp

    flyActive = true
end

-- Toggle with F only when Fly feature is enabled
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if not FlyEnabled then return end
    if input.KeyCode == Enum.KeyCode.F then
        if flyActive then
            stopFly()
        else
            startFly()
        end
    end
end)

-- Fly movement loop
RunService.RenderStepped:Connect(function()
    if not flyActive then return end
    if not FlyEnabled then
        stopFly()
        return
    end

    local char = Player.Character
    if not char then
        stopFly()
        return
    end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp or not flyBV or not flyBG then
        stopFly()
        return
    end

    -- Safety: if the movers somehow got destroyed, abort
    if not flyBV.Parent or not flyBG.Parent then
        stopFly()
        return
    end

    local cf = Camera.CFrame
    local move = Vector3.zero

    if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + cf.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - cf.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - cf.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + cf.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.yAxis end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move = move - Vector3.yAxis end

    if move.Magnitude > 0 then
        move = move.Unit * FlySpeed
    end

    flyBV.Velocity = move
    flyBG.CFrame = CFrame.new(hrp.Position, hrp.Position + cf.LookVector)
end)

-- Critical: clean up every time character respawns / dies
Player.CharacterAdded:Connect(function(char)
    stopFly()                       -- make sure flags are reset
    task.wait(0.3)
    cleanFlyRemnants(char)          -- destroy any leftover movers
end)

-- Also clean when character is removed (death)
if Player.Character then
    Player.Character.AncestryChanged:Connect(function(_, parent)
        if not parent then
            stopFly()
        end
    end)
end

-- NoClip
task.spawn(function()
    while task.wait(0.25) do
        local char = Player.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = not NoClipEnabled
                end
            end
        end
    end
end)

-- Anti-AFK
task.spawn(function()
    while task.wait(55) do
        if AntiAFK then
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        end
    end
end)

-- MISC GUI
MISCsection:CreateToggle({
    Name = "WalkSpeed",
    CurrentValue = false,
    Flag = "MISC.WalkSpeed",
    Callback = function(v) WalkSpeedEnabled = v end,
})

MISCsection:CreateSlider({
    Name = "WalkSpeed Value",
    Min = 16,
    Max = 120,
    CurrentValue = 16,
    Rounding = 1,
    Flag = "MISC.WalkSpeedValue",
    Callback = function(v) WalkSpeedValue = v end,
})

MISCsection:CreateToggle({
    Name = "JumpPower",
    CurrentValue = false,
    Flag = "MISC.JumpPower",
    Callback = function(v) JumpPowerEnabled = v end,
})

MISCsection:CreateSlider({
    Name = "JumpPower Value",
    Min = 50,
    Max = 250,
    CurrentValue = 50,
    Rounding = 1,
    Flag = "MISC.JumpPowerValue",
    Callback = function(v) JumpPowerValue = v end,
})

MISCsection:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Flag = "MISC.InfiniteJump",
    Callback = function(v) InfiniteJump = v end,
})

MISCsection:CreateToggle({
    Name = "Fly (Toggle with F)",
    CurrentValue = false,
    Flag = "MISC.Fly",
    Callback = function(v)
        FlyEnabled = v
        if not v then
            stopFly()   -- always force stop + clean when disabled
        end
    end,
})

MISCsection:CreateSlider({
    Name = "Fly Speed",
    Min = 10,
    Max = 250,
    CurrentValue = 50,
    Rounding = 5,
    Flag = "MISC.FlySpeed",
    Callback = function(v) FlySpeed = v end,
})

MISCsection:CreateToggle({
    Name = "NoClip",
    CurrentValue = false,
    Flag = "MISC.NoClip",
    Callback = function(v) NoClipEnabled = v end,
})

MISCsection:CreateToggle({
    Name = "Anti-AFK",
    CurrentValue = false,
    Flag = "MISC.AntiAFK",
    Callback = function(v) AntiAFK = v end,
})

print("[Vaxiron] Script loaded successfully - ESP + Aimbot improved")