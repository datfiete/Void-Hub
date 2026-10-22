
-- Vaxorin World ESP Renderer
-- Designed for experiences/projects that own the rendering context.
-- Consumes the layout produced by Core/ESPBuilder and binds it to real players.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Maid = require(script.Parent.Parent.Utils.Maid)

local ESPWorldRenderer = {}
ESPWorldRenderer.__index = ESPWorldRenderer

local DEFAULT_LAYOUT = {
    Version = 2,
    Canvas = { Width = 420, Height = 430 },
    Elements = {
        { Id = "box", Type = "Box", Name = "Box", X = 125, Y = 90, Width = 170, Height = 250, Color = { R = 161, G = 76, B = 255 }, Thickness = 2, Transparency = 0, Visible = true },
        { Id = "name", Type = "Name", Name = "Name", X = 145, Y = 62, Width = 130, Height = 24, Text = "{name}", Color = { R = 245, G = 245, B = 248 }, TextSize = 14, Anchor = "Center", Visible = true },
        { Id = "health", Type = "Health", Name = "Health", X = 145, Y = 34, Width = 130, Height = 22, Text = "{health}/{maxhealth}", Color = { R = 76, G = 220, B = 137 }, TextSize = 13, Anchor = "Center", Visible = true },
        { Id = "distance", Type = "Distance", Name = "Distance", X = 145, Y = 350, Width = 130, Height = 22, Text = "{distance}", Color = { R = 220, G = 225, B = 235 }, TextSize = 13, Anchor = "Center", Visible = true },
        { Id = "healthbar", Type = "HealthBar", Name = "Health Bar", X = 116, Y = 92, Width = 6, Height = 246, Color = { R = 76, G = 220, B = 137 }, Thickness = 0, Visible = true },
        { Id = "tracer", Type = "Tracer", Name = "Tracer", X = 210, Y = 385, Width = 2, Height = 42, Color = { R = 161, G = 76, B = 255 }, Thickness = 2, Visible = true },
        { Id = "weapon", Type = "Weapon", Name = "Weapon", X = 300, Y = 132, Width = 105, Height = 22, Text = "{weapon}", Color = { R = 245, G = 245, B = 248 }, TextSize = 11, Anchor = "Left", Visible = true },
        { Id = "status", Type = "Status", Name = "Status", X = 300, Y = 158, Width = 105, Height = 22, Text = "{team}", Color = { R = 247, G = 185, B = 78 }, TextSize = 11, Anchor = "Left", Visible = true },
        { Id = "team", Type = "Team", Name = "Team", X = 300, Y = 158, Width = 105, Height = 22, Text = "{team}", Color = { R = 247, G = 185, B = 78 }, TextSize = 11, Anchor = "Left", Visible = true },
        { Id = "class", Type = "Class", Name = "Class", X = 300, Y = 184, Width = 105, Height = 22, Text = "{class}", Color = { R = 190, G = 190, B = 210 }, TextSize = 11, Anchor = "Left", Visible = true },
        { Id = "state", Type = "State", Name = "State", X = 300, Y = 210, Width = 105, Height = 22, Text = "{state}", Color = { R = 190, G = 190, B = 210 }, TextSize = 11, Anchor = "Left", Visible = true },
        { Id = "health_percent", Type = "HealthPercent", Name = "Health %", X = 145, Y = 6, Width = 130, Height = 22, Text = "{health_percent}", Color = { R = 76, G = 220, B = 137 }, TextSize = 11, Anchor = "Center", Visible = true },
        { Id = "filled_box", Type = "FilledBox", Name = "Filled Box", X = 125, Y = 90, Width = 170, Height = 250, Color = { R = 161, G = 76, B = 255 }, Transparency = 0.82, Visible = true },
        { Id = "corner_box", Type = "CornerBox", Name = "Corner Box", X = 125, Y = 90, Width = 170, Height = 250, Color = { R = 161, G = 76, B = 255 }, Thickness = 2, Visible = true },
        { Id = "head_marker", Type = "HeadMarker", Name = "Head Marker", X = 198, Y = 96, Width = 24, Height = 24, Color = { R = 161, G = 76, B = 255 }, Thickness = 2, Visible = true },
        { Id = "skeleton", Type = "Skeleton", Name = "Skeleton", X = 160, Y = 105, Width = 100, Height = 215, Color = { R = 161, G = 76, B = 255 }, Thickness = 2, Visible = true },
    },
}

local function copy(value)
    if type(value) ~= "table" then
        return value
    end
    local out = {}
    for k, v in pairs(value) do
        out[k] = copy(v)
    end
    return out
end

local function colorFrom(value, fallback)
    if typeof(value) == "Color3" then
        return value
    end
    if type(value) == "table" then
        return Color3.fromRGB(
            math.clamp(tonumber(value.R) or math.floor(fallback.R * 255), 0, 255),
            math.clamp(tonumber(value.G) or math.floor(fallback.G * 255), 0, 255),
            math.clamp(tonumber(value.B) or math.floor(fallback.B * 255), 0, 255)
        )
    end
    return fallback
end

local function replaceTokens(text, sample)
    local health = tonumber(sample.Health) or 0
    local maxHealth = math.max(tonumber(sample.MaxHealth) or 100, 1)
    local replacements = {
        ["{name}"] = tostring(sample.Name or "Player"),
        ["{health}"] = tostring(math.floor(health + 0.5)),
        ["{maxhealth}"] = tostring(math.floor(maxHealth + 0.5)),
        ["{health_percent}"] = tostring(math.floor(math.clamp(health / maxHealth, 0, 1) * 100 + 0.5)) .. "%",
        ["{distance}"] = tostring(math.floor((tonumber(sample.Distance) or 0) + 0.5)) .. "m",
        ["{weapon}"] = tostring(sample.Weapon or "None"),
        ["{team}"] = tostring(sample.Team or "Neutral"),
        ["{class}"] = tostring(sample.Class or "Player"),
        ["{state}"] = tostring(sample.State or "Normal"),
    }
    for token, replacement in pairs(replacements) do
        text = string.gsub(text, token, function()
            return replacement
        end)
    end
    return text
end

local function getWeapon(character)
    local tool = character:FindFirstChildOfClass("Tool")
    if tool then
        return tool.Name
    end
    return "None"
end

local function getCharacterBounds(character)
    local ok, cf, size = pcall(function()
        return character:GetBoundingBox()
    end)
    if ok and cf and size then
        return cf, size
    end
    return nil
end

local function projectBounds(camera, cf, size)
    local half = size * 0.5
    local points = {
        cf * Vector3.new(-half.X, -half.Y, -half.Z), cf * Vector3.new(-half.X, -half.Y, half.Z),
        cf * Vector3.new(-half.X, half.Y, -half.Z), cf * Vector3.new(-half.X, half.Y, half.Z),
        cf * Vector3.new(half.X, -half.Y, -half.Z), cf * Vector3.new(half.X, -half.Y, half.Z),
        cf * Vector3.new(half.X, half.Y, -half.Z), cf * Vector3.new(half.X, half.Y, half.Z),
    }
    local minX = math.huge
    local minY = math.huge
    local maxX = -math.huge
    local maxY = -math.huge
    local nearestDepth = math.huge
    local anyFront = false
    for _, point in ipairs(points) do
        local screen = camera:WorldToViewportPoint(point)
        if screen.Z > 0 then
            anyFront = true
            minX = math.min(minX, screen.X)
            minY = math.min(minY, screen.Y)
            maxX = math.max(maxX, screen.X)
            maxY = math.max(maxY, screen.Y)
            nearestDepth = math.min(nearestDepth, screen.Z)
        end
    end
    if not anyFront or nearestDepth == math.huge then
        return nil
    end
    return minX, minY, maxX, maxY, nearestDepth
end

local function rayVisible(camera, origin, target, character)
    local direction = target - origin
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { camera, character }
    local result = workspace:Raycast(origin, direction, params)
    return result == nil
end

function ESPWorldRenderer.new(options)
    local data = {}
    if type(options) == "table" then data = options end
    local parent = data.Parent
    if not parent then
        local localPlayer = Players.LocalPlayer
        if not localPlayer then
            error("ESPWorldRenderer requires a LocalPlayer or an explicit Parent")
        end
        parent = localPlayer:WaitForChild("PlayerGui")
    end

    local self = setmetatable({
        _Maid = Maid.new(),
        _PlayerMaids = {},
        _Layout = copy(data.Layout or DEFAULT_LAYOUT),
        _Enabled = data.Enabled ~= false,
        _MaxDistance = math.max(tonumber(data.MaxDistance) or 5000, 0),
        _MaxDistanceSquared = math.max(tonumber(data.MaxDistance) or 5000, 0) ^ 2,
        _TeamCheck = data.TeamCheck == true,
        _VisibleCheck = data.VisibleCheck == true,
        _IgnoreLocalPlayer = data.IgnoreLocalPlayer ~= false,
        _UpdateRate = math.clamp(tonumber(data.UpdateRate) or 15, 10, 30),
        _Accumulator = 0,
        _LastLayout = nil,
    }, ESPWorldRenderer)

    local gui = Instance.new("ScreenGui")
    gui.Name = "VaxorinWorldESP"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.DisplayOrder = 900
    gui.Parent = parent
    self.Gui = gui

    self._Maid:Give(RunService.RenderStepped:Connect(function(dt)
        self._Accumulator += dt
        local interval = 1 / self._UpdateRate
        if self._Accumulator < interval then return end
        self._Accumulator = 0
        self:_render()
    end))

    if data.Builder and data.Builder.OnChanged then
        self._Maid:Give(data.Builder:OnChanged(function(layout)
            self:SetLayout(layout)
        end))
        if data.Builder.GetLayout then
            self:SetLayout(data.Builder:GetLayout())
        end
    end

    self._Maid:Give(Players.PlayerRemoving:Connect(function(player)
        self:_removePlayer(player)
    end))

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= Players.LocalPlayer then
            self:_ensurePlayer(player)
        end
    end

    self._Maid:Give(Players.PlayerAdded:Connect(function(player)
        self:_ensurePlayer(player)
    end))

    return self
end

function ESPWorldRenderer:_ensurePlayer(player)
    if self._PlayerMaids[player] then
        return
    end
    local maid = Maid.new()
    self._PlayerMaids[player] = maid
    maid:Give(player.CharacterAdded:Connect(function()
        self:_clearPlayerGui(player)
    end))
end

function ESPWorldRenderer:_clearPlayerGui(player)
    local maid = self._PlayerMaids[player]
    if maid then
        -- Keep the CharacterAdded connection; only destroy the current visual container.
        local current = self._Visuals and self._Visuals[player]
        if current then
            current:Destroy()
            self._Visuals[player] = nil
        end
    end
end

function ESPWorldRenderer:_removePlayer(player)
    local maid = self._PlayerMaids[player]
    if maid then
        maid:DoCleaning()
        self._PlayerMaids[player] = nil
    end
    local current = self._Visuals and self._Visuals[player]
    if current then
        current:Destroy()
        self._Visuals[player] = nil
    end
end

function ESPWorldRenderer:_makeVisuals(player)
    self._Visuals = self._Visuals or {}
    local existing = self._Visuals[player]
    if existing then
        return existing
    end

    local root = Instance.new("Frame")
    root.Name = "ESP_" .. player.UserId
    root.BackgroundTransparency = 1
    root.BorderSizePixel = 0
    root.Size = UDim2.fromOffset(1, 1)
    root.Parent = self.Gui
    self._Visuals[player] = root
    return root
end

function ESPWorldRenderer:_destroyChildren(root)
    for _, child in ipairs(root:GetChildren()) do
        child:Destroy()
    end
end

function ESPWorldRenderer:_renderElement(root, element, box, screenWidth, screenHeight, sample, character)
    if element.Visible == false then return end

    local design = self._Layout.Canvas or { Width = 420, Height = 430 }
    local designW = math.max(tonumber(design.Width) or 420, 1)
    local designH = math.max(tonumber(design.Height) or 430, 1)
    local boxElement = box.design
    local refW = math.max(tonumber(boxElement.Width) or 170, 1)
    local refH = math.max(tonumber(boxElement.Height) or 250, 1)
    local sx = box.w / refW
    local sy = box.h / refH
    local centerX = box.x + box.w * 0.5
    local centerY = box.y + box.h * 0.5
    local refCenterX = (tonumber(boxElement.X) or 125) + refW * 0.5
    local refCenterY = (tonumber(boxElement.Y) or 90) + refH * 0.5
    local x = centerX + ((tonumber(element.X) or 0) + (tonumber(element.Width) or 20) * 0.5 - refCenterX) * sx - (tonumber(element.Width) or 20) * sx * 0.5
    local y = centerY + ((tonumber(element.Y) or 0) + (tonumber(element.Height) or 20) * 0.5 - refCenterY) * sy - (tonumber(element.Height) or 20) * sy * 0.5
    local w = math.max((tonumber(element.Width) or 20) * sx, 1)
    local h = math.max((tonumber(element.Height) or 20) * sy, 1)
    local color = colorFrom(element.Color, Color3.fromRGB(161, 76, 255))

    local function line(parent, x1, y1, x2, y2, thickness, lineColor)
        local length = math.max((Vector2.new(x2, y2) - Vector2.new(x1, y1)).Magnitude, 1)
        local frame = Instance.new("Frame")
        frame.AnchorPoint = Vector2.new(0.5, 0.5)
        frame.Position = UDim2.fromOffset((x1 + x2) * 0.5, (y1 + y2) * 0.5)
        frame.Size = UDim2.fromOffset(length, math.max(thickness, 1))
        frame.Rotation = math.deg(math.atan2(y2 - y1, x2 - x1))
        frame.BackgroundColor3 = lineColor
        frame.BackgroundTransparency = math.clamp(tonumber(element.Transparency) or 0, 0, 1)
        frame.BorderSizePixel = 0
        frame.ZIndex = 6
        frame.Parent = parent
    end

    if element.Type == "Tracer" then
        local startX = centerX + ((tonumber(element.X) or 210) - refCenterX) * sx
        local startY = centerY + ((tonumber(element.Y) or 385) - refCenterY) * sy
        line(root, startX, startY, startX, screenHeight, math.max(tonumber(element.Width) or 2, 1), color)
        return
    end

    if element.Type == "Box" then
        local frame = Instance.new("Frame")
        frame.Position = UDim2.fromOffset(box.x, box.y)
        frame.Size = UDim2.fromOffset(box.w, box.h)
        frame.BackgroundTransparency = 1
        frame.BorderSizePixel = 0
        frame.ZIndex = 2
        local stroke = Instance.new("UIStroke")
        stroke.Color = color
        stroke.Thickness = math.max(tonumber(element.Thickness) or 2, 1)
        stroke.Transparency = math.clamp(tonumber(element.Transparency) or 0, 0, 1)
        stroke.Parent = frame
        frame.Parent = root
        return
    end

    if element.Type == "FilledBox" then
        local frame = Instance.new("Frame")
        frame.Position = UDim2.fromOffset(box.x, box.y)
        frame.Size = UDim2.fromOffset(box.w, box.h)
        frame.BackgroundColor3 = color
        frame.BackgroundTransparency = math.clamp(tonumber(element.Transparency) or 0.82, 0, 1)
        frame.BorderSizePixel = 0
        frame.ZIndex = 1
        frame.Parent = root
        return
    end

    if element.Type == "CornerBox" then
        local frame = Instance.new("Frame")
        frame.Position = UDim2.fromOffset(box.x, box.y)
        frame.Size = UDim2.fromOffset(box.w, box.h)
        frame.BackgroundTransparency = 1
        frame.BorderSizePixel = 0
        frame.ZIndex = 2
        local t = math.max(tonumber(element.Thickness) or 2, 1)
        local len = math.max(math.min(box.w, box.h) * 0.22, 8)
        local parts = {
            {0,0,len,t},{0,0,t,len},{box.w-len,0,len,t},{box.w-t,0,t,len},
            {0,box.h-t,len,t},{0,box.h-len,t,len},{box.w-len,box.h-t,len,t},{box.w-t,box.h-len,t,len},
        }
        for i, part in ipairs(parts) do
            local corner = Instance.new("Frame")
            corner.Name = "Corner" .. tostring(i)
            corner.Position = UDim2.fromOffset(part[1], part[2])
            corner.Size = UDim2.fromOffset(part[3], part[4])
            corner.BackgroundColor3 = color
            corner.BackgroundTransparency = math.clamp(tonumber(element.Transparency) or 0, 0, 1)
            corner.BorderSizePixel = 0
            corner.ZIndex = 3
            corner.Parent = frame
        end
        frame.Parent = root
        return
    end

    if element.Type == "HealthBar" then
        local bg = Instance.new("Frame")
        bg.Position = UDim2.fromOffset(x, y)
        bg.Size = UDim2.fromOffset(w, h)
        bg.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
        bg.BackgroundTransparency = 0.25
        bg.BorderSizePixel = 0
        bg.ZIndex = 3
        bg.Parent = root
        local ratio = math.clamp((tonumber(sample.Health) or 0) / math.max(tonumber(sample.MaxHealth) or 100, 1), 0, 1)
        local fill = Instance.new("Frame")
        fill.Name = "Fill"
        fill.AnchorPoint = Vector2.new(0, 1)
        fill.Position = UDim2.fromScale(0, 1)
        fill.Size = UDim2.fromScale(1, ratio)
        fill.BackgroundColor3 = color
        fill.BackgroundTransparency = math.clamp(tonumber(element.Transparency) or 0, 0, 1)
        fill.BorderSizePixel = 0
        fill.ZIndex = 4
        fill.Parent = bg
        return
    end

    if element.Type == "HeadMarker" then
        local head = character and (character:FindFirstChild("Head") or character:FindFirstChild("UpperTorso"))
        if head and head:IsA("BasePart") then
            local screen, visible = workspace.CurrentCamera:WorldToViewportPoint(head.Position)
            if screen.Z > 0 then
                local marker = Instance.new("Frame")
                marker.AnchorPoint = Vector2.new(0.5, 0.5)
                marker.Position = UDim2.fromOffset(screen.X, screen.Y)
                marker.Size = UDim2.fromOffset(math.max(w, 8), math.max(h, 8))
                marker.BackgroundTransparency = 1
                marker.BorderSizePixel = 0
                marker.ZIndex = 6
                local corner = Instance.new("UICorner")
                corner.CornerRadius = UDim.new(1, 0)
                corner.Parent = marker
                local stroke = Instance.new("UIStroke")
                stroke.Color = color
                stroke.Thickness = math.max(tonumber(element.Thickness) or 2, 1)
                stroke.Transparency = math.clamp(tonumber(element.Transparency) or 0, 0, 1)
                stroke.Parent = marker
                marker.Parent = root
            end
        end
        return
    end

    if element.Type == "Skeleton" then
        local function point(names)
            local part = nil
            for _, name in ipairs(names) do
                local candidate = character and character:FindFirstChild(name)
                if candidate and candidate:IsA("BasePart") then
                    part = candidate
                    break
                end
            end
            if part then
                local screen = workspace.CurrentCamera:WorldToViewportPoint(part.Position)
                if screen.Z > 0 then return screen.X, screen.Y end
            end
            return nil
        end
        local pairsToDraw = {
            {{"Head"}, {"UpperTorso", "Torso"}},
            {{"UpperTorso", "Torso"}, {"LowerTorso", "Torso"}},
            {{"UpperTorso", "Torso"}, {"LeftUpperArm", "Left Arm"}},
            {{"LeftUpperArm", "Left Arm"}, {"LeftLowerArm", "Left Arm"}},
            {{"LeftLowerArm", "Left Arm"}, {"LeftHand", "Left Arm"}},
            {{"UpperTorso", "Torso"}, {"RightUpperArm", "Right Arm"}},
            {{"RightUpperArm", "Right Arm"}, {"RightLowerArm", "Right Arm"}},
            {{"RightLowerArm", "Right Arm"}, {"RightHand", "Right Arm"}},
            {{"LowerTorso", "Torso"}, {"LeftUpperLeg", "Left Leg"}},
            {{"LeftUpperLeg", "Left Leg"}, {"LeftLowerLeg", "Left Leg"}},
            {{"LeftLowerLeg", "Left Leg"}, {"LeftFoot", "Left Leg"}},
            {{"LowerTorso", "Torso"}, {"RightUpperLeg", "Right Leg"}},
            {{"RightUpperLeg", "Right Leg"}, {"RightLowerLeg", "Right Leg"}},
            {{"RightLowerLeg", "Right Leg"}, {"RightFoot", "Right Leg"}},
        }
        for _, pair in ipairs(pairsToDraw) do
            local x1, y1 = point(pair[1])
            local x2, y2 = point(pair[2])
            if x1 and x2 then line(root, x1, y1, x2, y2, math.max(tonumber(element.Thickness) or 2, 1), color) end
        end
        return
    end

    local label = Instance.new("TextLabel")
    label.Position = UDim2.fromOffset(x, y)
    label.Size = UDim2.fromOffset(w, h)
    label.BackgroundTransparency = 1
    label.Text = replaceTokens(tostring(element.Text or element.Name or element.Type or ""), sample)
    label.TextColor3 = color
    label.TextSize = math.clamp(tonumber(element.TextSize) or 12, 6, 40)
    label.Font = Enum.Font.GothamMedium
    label.TextXAlignment = Enum.TextXAlignment.Center
    if element.Anchor == "Left" then label.TextXAlignment = Enum.TextXAlignment.Left elseif element.Anchor == "Right" then label.TextXAlignment = Enum.TextXAlignment.Right end
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.TextStrokeTransparency = 0.5
    label.TextTransparency = math.clamp(tonumber(element.Transparency) or 0, 0, 1)
    label.ZIndex = 5
    label.Parent = root
end

function ESPWorldRenderer:_render()
    if not self._Enabled then
        if self._Visuals then
            for _, root in pairs(self._Visuals) do
                root.Visible = false
            end
        end
        return
    end

    local camera = workspace.CurrentCamera
    local localPlayer = Players.LocalPlayer
    if not camera or not localPlayer then return end

    local viewport = camera.ViewportSize
    local layoutElements = self._Layout.Elements or {}
    local boxDesign = nil
    for _, element in ipairs(layoutElements) do
        if element.Type == "Box" and element.Visible ~= false then
            boxDesign = element
            break
        end
    end
    if not boxDesign then
        boxDesign = { X = 125, Y = 90, Width = 170, Height = 250 }
    end

    for _, player in ipairs(Players:GetPlayers()) do
        local shouldRender = true
        if player == localPlayer and self._IgnoreLocalPlayer then shouldRender = false end
        self:_ensurePlayer(player)

        local character = player.Character
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local rootGui = self._Visuals and self._Visuals[player]
        if rootGui then rootGui.Visible = false end

        if not character or not rootPart or not humanoid or humanoid.Health <= 0 then shouldRender = false end
        local distance = 0
        if shouldRender then
            local offset = camera.CFrame.Position - rootPart.Position
            local distanceSquared = offset.X * offset.X + offset.Y * offset.Y + offset.Z * offset.Z
            if distanceSquared > self._MaxDistanceSquared then
                shouldRender = false
            else
                distance = math.sqrt(distanceSquared)
            end
        end
        if shouldRender and self._TeamCheck and localPlayer.Team ~= nil and player.Team == localPlayer.Team then shouldRender = false end
        if shouldRender and self._VisibleCheck and not rayVisible(camera, camera.CFrame.Position, rootPart.Position, character) then shouldRender = false end

        if shouldRender then
            local cf, size = getCharacterBounds(character)
            if not cf or not size then
                shouldRender = false
            else
                local minX, minY, maxX, maxY = projectBounds(camera, cf, size)
                if not minX then
                    shouldRender = false
                else
                    local boxWidth = math.max(maxX - minX, 2)
                    local boxHeight = math.max(maxY - minY, 2)
                    local teamName = "Neutral"
                    if player.Team then teamName = player.Team.Name end
                    local health = humanoid.Health
                    local maxHealth = humanoid.MaxHealth
                    local percent = health / math.max(maxHealth, 1)
                    local state = "Normal"
                    if percent <= 0.25 then state = "Low Health" elseif percent < 1 then state = "Injured" end
                    local sample = {
                        Name = player.DisplayName ~= "" and player.DisplayName or player.Name,
                        Health = health, MaxHealth = maxHealth, Distance = distance,
                        Weapon = getWeapon(character), Team = teamName, Class = "Player", State = state,
                    }
                    rootGui = self:_makeVisuals(player)
                    self:_destroyChildren(rootGui)
                    rootGui.Visible = true
                    local box = { x = minX, y = minY, w = boxWidth, h = boxHeight, design = boxDesign }
                    for _, element in ipairs(layoutElements) do
                        self:_renderElement(rootGui, element, box, viewport.X, viewport.Y, sample, character)
                    end
                end
            end
        end
    end
end

function ESPWorldRenderer:SetLayout(layout)
    if type(layout) ~= "table" then
        return
    end
    self._Layout = copy(layout)
    self._LastLayout = nil
end

function ESPWorldRenderer:SetEnabled(enabled)
    self._Enabled = enabled == true
    if not self._Enabled and self._Visuals then
        for _, root in pairs(self._Visuals) do
            root.Visible = false
        end
    end
end

function ESPWorldRenderer:IsEnabled()
    return self._Enabled
end

function ESPWorldRenderer:SetMaxDistance(distance)
    self._MaxDistance = math.max(tonumber(distance) or self._MaxDistance, 0)
    self._MaxDistanceSquared = self._MaxDistance * self._MaxDistance
end

function ESPWorldRenderer:GetMaxDistance()
    return self._MaxDistance
end

function ESPWorldRenderer:Clear()
    if self._Visuals then
        for player, root in pairs(self._Visuals) do
            root:Destroy()
            self._Visuals[player] = nil
        end
    end
end

function ESPWorldRenderer:Destroy()
    self:Clear()
    for player, maid in pairs(self._PlayerMaids) do
        maid:DoCleaning()
        self._PlayerMaids[player] = nil
    end
    self._Maid:DoCleaning()
    if self.Gui then
        self.Gui:Destroy()
    end
end

return ESPWorldRenderer
