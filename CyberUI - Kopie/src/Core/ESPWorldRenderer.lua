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
        text = string.gsub(text, token, replacement)
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
        cf * Vector3.new(-half.X, -half.Y, -half.Z),
        cf * Vector3.new(-half.X, -half.Y, half.Z),
        cf * Vector3.new(-half.X, half.Y, -half.Z),
        cf * Vector3.new(-half.X, half.Y, half.Z),
        cf * Vector3.new(half.X, -half.Y, -half.Z),
        cf * Vector3.new(half.X, -half.Y, half.Z),
        cf * Vector3.new(half.X, half.Y, -half.Z),
        cf * Vector3.new(half.X, half.Y, half.Z),
    }

    local minX = math.huge
    local minY = math.huge
    local maxX = -math.huge
    local maxY = -math.huge
    local nearestDepth = math.huge
    local anyVisible = false

    for _, point in ipairs(points) do
        local screen, visible = camera:WorldToViewportPoint(point)
        if screen.Z > 0 then
            anyVisible = anyVisible or visible
            minX = math.min(minX, screen.X)
            minY = math.min(minY, screen.Y)
            maxX = math.max(maxX, screen.X)
            maxY = math.max(maxY, screen.Y)
            nearestDepth = math.min(nearestDepth, screen.Z)
        end
    end

    if not anyVisible or nearestDepth == math.huge then
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
        _MaxDistance = math.max(tonumber(data.MaxDistance) or 1000, 0),
        _TeamCheck = data.TeamCheck == true,
        _VisibleCheck = data.VisibleCheck == true,
        _IgnoreLocalPlayer = data.IgnoreLocalPlayer ~= false,
    }, ESPWorldRenderer)

    local gui = Instance.new("ScreenGui")
    gui.Name = "VaxorinWorldESP"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.DisplayOrder = 900
    gui.Parent = parent
    self.Gui = gui

    self._Maid:Give(RunService.RenderStepped:Connect(function()
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

function ESPWorldRenderer:_renderElement(root, element, box, screenWidth, screenHeight, sample)
    if element.Visible == false then
        return
    end

    local design = self._Layout.Canvas or { Width = 420, Height = 430 }
    local designW = math.max(tonumber(design.Width) or 420, 1)
    local designH = math.max(tonumber(design.Height) or 430, 1)
    local boxElement = box.design

    local sx = box.w / math.max(boxElement.Width, 1)
    local sy = box.h / math.max(boxElement.Height, 1)
    local relativeX = (tonumber(element.X) or 0) - boxElement.X
    local relativeY = (tonumber(element.Y) or 0) - boxElement.Y

    local x = box.x + relativeX * sx
    local y = box.y + relativeY * sy
    local w = math.max((tonumber(element.Width) or 20) * sx, 1)
    local h = math.max((tonumber(element.Height) or 20) * sy, 1)

    if element.Type == "Tracer" then
        local tracer = Instance.new("Frame")
        tracer.Name = element.Id or "Tracer"
        tracer.AnchorPoint = Vector2.new(0.5, 0)
        tracer.Position = UDim2.fromOffset(box.x + box.w * 0.5, box.y + box.h)
        tracer.Size = UDim2.fromOffset(math.max(tonumber(element.Width) or 2, 1), math.max(screenHeight - (box.y + box.h), 0))
        tracer.BackgroundColor3 = colorFrom(element.Color, Color3.fromRGB(161, 76, 255))
        tracer.BackgroundTransparency = math.clamp(tonumber(element.Transparency) or 0, 0, 1)
        tracer.BorderSizePixel = 0
        tracer.ZIndex = 1
        tracer.Parent = root
        return
    end

    if element.Type == "Box" then
        local frame = Instance.new("Frame")
        frame.Name = element.Id or "Box"
        frame.Position = UDim2.fromOffset(box.x, box.y)
        frame.Size = UDim2.fromOffset(box.w, box.h)
        frame.BackgroundTransparency = 1
        frame.BorderSizePixel = 0
        frame.ZIndex = 2
        local stroke = Instance.new("UIStroke")
        stroke.Color = colorFrom(element.Color, Color3.fromRGB(161, 76, 255))
        stroke.Thickness = math.max(tonumber(element.Thickness) or 2, 1)
        stroke.Transparency = math.clamp(tonumber(element.Transparency) or 0, 0, 1)
        stroke.Parent = frame
        frame.Parent = root
        return
    end

    if element.Type == "HealthBar" then
        local bg = Instance.new("Frame")
        bg.Name = element.Id or "HealthBar"
        bg.Position = UDim2.fromOffset(x, y)
        bg.Size = UDim2.fromOffset(w, h)
        bg.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
        bg.BackgroundTransparency = 0.25
        bg.BorderSizePixel = 0
        bg.ZIndex = 3
        bg.Parent = root

        local fill = Instance.new("Frame")
        fill.Name = "Fill"
        fill.AnchorPoint = Vector2.new(0, 1)
        fill.Position = UDim2.fromScale(0, 1)
        fill.Size = UDim2.fromScale(1, math.clamp((tonumber(sample.Health) or 0) / math.max(tonumber(sample.MaxHealth) or 100, 1), 0, 1))
        fill.BackgroundColor3 = colorFrom(element.Color, Color3.fromRGB(76, 220, 137))
        fill.BackgroundTransparency = math.clamp(tonumber(element.Transparency) or 0, 0, 1)
        fill.BorderSizePixel = 0
        fill.ZIndex = 4
        fill.Parent = bg
        return
    end

    local label = Instance.new("TextLabel")
    label.Name = element.Id or element.Type or "ESPElement"
    label.Position = UDim2.fromOffset(x, y)
    label.Size = UDim2.fromOffset(w, h)
    label.BackgroundTransparency = 1
    label.Text = replaceTokens(tostring(element.Text or element.Name or element.Type or ""), sample)
    label.TextColor3 = colorFrom(element.Color, Color3.new(1, 1, 1))
    label.TextSize = math.clamp(tonumber(element.TextSize) or 12, 6, 40)
    label.Font = Enum.Font.GothamMedium
    label.TextXAlignment = Enum.TextXAlignment.Center
    if element.Anchor == "Left" then
        label.TextXAlignment = Enum.TextXAlignment.Left
    elseif element.Anchor == "Right" then
        label.TextXAlignment = Enum.TextXAlignment.Right
    end
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
        local rootGui = self:_makeVisuals(player)
        rootGui.Visible = false

        if not character or not rootPart or not humanoid or humanoid.Health <= 0 then shouldRender = false end
        local distance = 0
        if shouldRender then
            distance = (camera.CFrame.Position - rootPart.Position).Magnitude
            if distance > self._MaxDistance then shouldRender = false end
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
                elseif maxX < 0 or minX > viewport.X or maxY < 0 or minY > viewport.Y then
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
                    self:_destroyChildren(rootGui)
                    rootGui.Visible = true
                    local box = { x = minX, y = minY, w = boxWidth, h = boxHeight, design = boxDesign }
                    for _, element in ipairs(layoutElements) do
                        self:_renderElement(rootGui, element, box, viewport.X, viewport.Y, sample)
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
