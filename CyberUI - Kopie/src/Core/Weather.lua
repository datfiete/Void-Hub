--!strict
-- Lightweight particle weather overlay for Vaxorin windows.
local RunService = game:GetService("RunService")
local Tween = require(script.Parent.Parent.Utils.Tween)

export type WeatherKind = "None" | "Rain" | "Snow" | "Sakura" | "Stars" | "Leaves"

local Weather = {}
Weather.__index = Weather

local PRESETS = {
	Rain = {
		count = 48,
		color = Color3.fromRGB(160, 190, 220),
		size = Vector2.new(1, 14),
		speed = { 180, 320 },
		drift = { -20, 20 },
		transparency = 0.35,
		corner = 0,
	},
	Snow = {
		count = 36,
		color = Color3.fromRGB(240, 245, 255),
		size = Vector2.new(4, 4),
		speed = { 30, 70 },
		drift = { -40, 40 },
		transparency = 0.25,
		corner = 8,
	},
	Sakura = {
		count = 28,
		color = Color3.fromRGB(255, 160, 190),
		size = Vector2.new(6, 6),
		speed = { 25, 55 },
		drift = { -50, 50 },
		transparency = 0.2,
		corner = 3,
	},
	Stars = {
		count = 40,
		color = Color3.fromRGB(255, 255, 255),
		size = Vector2.new(2, 2),
		speed = { 4, 12 },
		drift = { -8, 8 },
		transparency = 0.4,
		corner = 8,
	},
	Leaves = {
		count = 22,
		color = Color3.fromRGB(180, 120, 50),
		size = Vector2.new(7, 5),
		speed = { 35, 80 },
		drift = { -70, 70 },
		transparency = 0.15,
		corner = 2,
	},
}

function Weather.new(parent: Instance)
	local self = setmetatable({}, Weather)
	self._Parent = parent
	self._Kind = "None" :: WeatherKind
	self._Particles = {} :: { Frame }
	self._Conn = nil :: RBXScriptConnection?
	self._Layer = Instance.new("Frame")
	self._Layer.Name = "WeatherLayer"
	self._Layer.BackgroundTransparency = 1
	self._Layer.Size = UDim2.fromScale(1, 1)
	self._Layer.Position = UDim2.fromScale(0, 0)
	self._Layer.ZIndex = 5
	self._Layer.ClipsDescendants = true
	self._Layer.Visible = false
	self._Layer.Parent = parent
	return self
end

function Weather:_clear()
	if self._Conn then
		self._Conn:Disconnect()
		self._Conn = nil
	end
	for _, p in self._Particles do
		if p and p.Parent then
			p:Destroy()
		end
	end
	table.clear(self._Particles)
	self._Layer.Visible = false
end

function Weather:Set(kind: string)
	kind = kind or "None"
	if kind == self._Kind then
		return
	end
	self:_clear()
	self._Kind = kind
	local preset = PRESETS[kind]
	if not preset then
		return
	end
	self._Layer.Visible = true
	local rng = Random.new()
	for i = 1, preset.count do
		local f = Instance.new("Frame")
		f.Name = "P" .. i
		f.BorderSizePixel = 0
		f.BackgroundColor3 = preset.color
		f.BackgroundTransparency = preset.transparency + rng:NextNumber(0, 0.25)
		f.Size = UDim2.fromOffset(
			math.max(1, preset.size.X + rng:NextInteger(-1, 1)),
			math.max(1, preset.size.Y + rng:NextInteger(-2, 2))
		)
		f.Position = UDim2.fromScale(rng:NextNumber(0, 1), rng:NextNumber(-0.2, 1))
		f.Rotation = if kind == "Rain" then 12 else rng:NextNumber(-30, 30)
		f.ZIndex = 6
		f.Parent = self._Layer
		if preset.corner > 0 then
			local c = Instance.new("UICorner")
			c.CornerRadius = UDim.new(0, preset.corner)
			c.Parent = f
		end
		table.insert(self._Particles, f)
	end

	local speeds = {}
	local drifts = {}
	for i = 1, #self._Particles do
		speeds[i] = rng:NextNumber(preset.speed[1], preset.speed[2])
		drifts[i] = rng:NextNumber(preset.drift[1], preset.drift[2])
	end

	self._Conn = RunService.RenderStepped:Connect(function(dt)
		local layer = self._Layer
		if not layer or not layer.Parent then
			return
		end
		local abs = layer.AbsoluteSize
		if abs.X < 2 or abs.Y < 2 then
			return
		end
		for i, p in self._Particles do
			if not p.Parent then
				continue
			end
			local x = p.Position.X.Scale * abs.X + p.Position.X.Offset
			local y = p.Position.Y.Scale * abs.Y + p.Position.Y.Offset
			y += speeds[i] * dt
			x += drifts[i] * dt
			if kind == "Sakura" or kind == "Leaves" then
				p.Rotation += drifts[i] * dt * 0.4
			end
			if y > abs.Y + 20 then
				y = rng:NextNumber(-30, -4)
				x = rng:NextNumber(0, abs.X)
			end
			if x < -20 then
				x = abs.X + 10
			elseif x > abs.X + 20 then
				x = -10
			end
			p.Position = UDim2.fromOffset(x, y)
		end
	end)
end

function Weather:Destroy()
	self:_clear()
	if self._Layer then
		self._Layer:Destroy()
	end
end

return Weather
