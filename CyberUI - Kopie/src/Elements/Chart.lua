--!strict

local Theme = require(script.Parent.Parent.Core.Theme)
local Helpers = require(script.Parent.Parent.Utils.Helpers)

local Chart = {}
Chart.__index = Chart

local function finiteOr(value: any, fallback: number): number
	local n = tonumber(value)
	if not n or n ~= n or n == math.huge or n == -math.huge then
		return fallback
	end
	return n
end

local function isFiniteNumber(value: number): boolean
	return value == value and value ~= math.huge and value ~= -math.huge
end

export type ChartOptions = {
	Name: string?,
	Label: string?,
	Value: string?,
	Color: Color3?,
	Bars: number?,
	Height: number?,
	Max: number?,
	Suffix: string?,
	AutoScale: boolean?,
}

function Chart.new(section: any, data: ChartOptions?): any
	data = data or {}
	local theme = section.Tab.Window.Library.Theme
	local barCount = math.clamp(math.floor(finiteOr(data.Bars, 20)), 6, 40)
	local color = data.Color or theme.Accent
	local maxRef = finiteOr(data.Max, 60)
	if maxRef <= 0 then
		maxRef = 60
	end
	local height = math.clamp(math.floor(finiteOr(data.Height, 78)), 60, 160)
	local barAreaH = 30
	local gap = 2

	local root = Helpers.CreateFrame({
		Name = data.Name or "Chart",
		Size = UDim2.new(1, 0, 0, height),
		BackgroundTransparency = 1,
		Parent = section.Inner,
	})

	Helpers.CreateLabel({
		Name = "Label",
		Size = UDim2.new(1, 0, 0, 12),
		Text = tostring(data.Label or data.Name or "Chart"),
		Font = Theme.Font,
		TextSize = 10,
		TextColor3 = theme.TextMuted,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = root,
	})

	local valueLbl = Helpers.CreateLabel({
		Name = "Value",
		Size = UDim2.new(1, 0, 0, 24),
		Position = UDim2.fromOffset(0, 14),
		Text = tostring(data.Value or "—"),
		Font = Theme.FontBold,
		TextSize = 22,
		TextColor3 = color,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = root,
	})

	local barsHold = Helpers.CreateFrame({
		Name = "Bars",
		Size = UDim2.new(1, 0, 0, barAreaH),
		Position = UDim2.fromOffset(0, 42),
		BackgroundTransparency = 1,
		Parent = root,
	})

	-- history[1] = oldest (LEFT), history[barCount] = newest (RIGHT)
	local history = table.create(barCount, 0)
	local bars = table.create(barCount)

	for i = 1, barCount do
		local bar = Instance.new("Frame")
		bar.Name = "B" .. i
		bar.BorderSizePixel = 0
		bar.BackgroundColor3 = color
		bar.BackgroundTransparency = 0.55
		bar.AnchorPoint = Vector2.new(0, 1)
		bar.Parent = barsHold
		Helpers.Corner(bar, 2)
		bars[i] = bar
	end

	local self = setmetatable({
		_Section = section,
		_Data = data,
		_History = history,
		_Bars = bars,
		_BarCount = barCount,
		_MaxRef = maxRef,
		_Color = color,
		_AutoScale = data.AutoScale == true,
		_Gap = gap,
		_BarAreaH = barAreaH,
		_Seeded = false,
		Instance = root,
		Label = root:FindFirstChild("Label"),
		ValueLabel = valueLbl,
		BarsHold = barsHold,
	}, Chart)

	local function relayout()
		self:_layoutBars()
		self:_paint()
	end

	barsHold:GetPropertyChangedSignal("AbsoluteSize"):Connect(relayout)
	task.defer(relayout)

	return self
end

function Chart:_layoutBars()
	local width = self.BarsHold.AbsoluteSize.X
	local n = self._BarCount
	local gap = self._Gap
	if width < 1 then
		-- fallback to scale until AbsoluteSize is known
		for i, bar in self._Bars do
			bar.Position = UDim2.new((i - 1) / n, 0, 1, 0)
			bar.Size = UDim2.new(1 / n, -gap, 0, 3)
		end
		return
	end

	local totalGap = gap * (n - 1)
	local barW = math.max(1, math.floor((width - totalGap) / n))
	-- distribute leftover pixels so the last bar touches the right edge
	local used = barW * n + totalGap
	local leftover = math.max(0, math.floor(width - used))

	local x = 0
	for i, bar in self._Bars do
		local extra = if i > (n - leftover) then 1 else 0
		local w = barW + extra
		bar.Position = UDim2.fromOffset(x, 0)
		bar.AnchorPoint = Vector2.new(0, 1)
		bar.Position = UDim2.fromOffset(x, self._BarAreaH)
		bar.Size = UDim2.fromOffset(w, math.max(bar.Size.Y.Offset, 3))
		x += w + gap
	end
end

function Chart:_formatValue(value: any): string
	local n = tonumber(value)
	if n and isFiniteNumber(n) then
		local text = if n % 1 == 0 then tostring(math.floor(n)) else string.format("%.2f", n):gsub("0+$", ""):gsub("%.$", "")
		return text .. (self._Data.Suffix or "")
	end
	return tostring(value)
end

function Chart:_paint()
	local maxV = self._MaxRef
	if self._AutoScale then
		for _, value in self._History do
			if isFiniteNumber(value) then
				maxV = math.max(maxV, math.abs(value))
			end
		end
	end
	maxV = math.max(maxV, 1)
	local areaH = self._BarAreaH

	for i, bar in self._Bars do
		local value = self._History[i] or 0
		local magnitude = if isFiniteNumber(value) then math.abs(value) else 0
		local ratio = math.clamp(magnitude / maxV, 0, 1)
		local h = if magnitude <= 0 then 2 else math.clamp(math.floor(ratio * areaH + 0.5), 3, areaH)

		local size = bar.Size
		bar.Size = UDim2.fromOffset(size.X.Offset, h)
		-- if still in scale fallback mode
		if size.X.Scale > 0 then
			bar.Size = UDim2.new(size.X.Scale, size.X.Offset, 0, h)
		end
		bar.BackgroundColor3 = self._Color
		bar.BackgroundTransparency = 0.08 + (1 - ratio) * 0.5
	end
end

function Chart:Set(value: any, pushHistory: boolean?)
	local n = tonumber(value)
	if n and not isFiniteNumber(n) then
		n = nil
	end
	self.ValueLabel.Text = self:_formatValue(if n ~= nil then n else value)
	if n ~= nil and pushHistory ~= false then
		self:Push(n)
	end
end

function Chart:Push(value: number)
	local n = tonumber(value)
	if not n or not isFiniteNumber(n) then
		n = 0
	end

	if not self._Seeded then
		-- fill entire strip so newest is already on the RIGHT edge
		for i = 1, self._BarCount do
			self._History[i] = n
		end
		self._Seeded = true
	else
		-- scroll LEFT ← oldest drops, newest enters RIGHT
		table.remove(self._History, 1)
		self._History[self._BarCount] = n
	end

	self.ValueLabel.Text = self:_formatValue(n)
	self:_paint()
end

function Chart:SetColor(color: Color3)
	self._Color = color
	self.ValueLabel.TextColor3 = color
	self:_paint()
end

function Chart:RefreshTheme()
	local theme = self._Section.Tab.Window.Library.Theme
	if self.Label then
		self.Label.TextColor3 = theme.TextMuted
	end
	if not self._Data.Color then
		self._Color = theme.Accent
		self.ValueLabel.TextColor3 = theme.Accent
	else
		self.ValueLabel.TextColor3 = self._Data.Color
	end
	self:_paint()
end

function Chart:Destroy()
	if self.Instance and self.Instance.Parent then
		self.Instance:Destroy()
	end
end

return Chart
