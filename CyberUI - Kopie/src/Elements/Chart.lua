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

export type ChartOptions = {
	Name: string?,
	Label: string?,
	Value: string?,
	Color: Color3?,
	Bars: number?,
	Height: number?,
	Max: number?,
	Suffix: string?,
}

function Chart.new(section: any, data: ChartOptions?): any
	data = data or {}
	local theme = section.Tab.Window.Library.Theme
	local barCount = math.clamp(math.floor(finiteOr(data.Bars, 20)), 6, 40)
	local color = data.Color or theme.Accent
	local maxRef = finiteOr(data.Max, 60)
	if maxRef <= 0 then maxRef = 60 end
	local height = math.clamp(math.floor(finiteOr(data.Height, 78)), 60, 160)

	local root = Helpers.CreateFrame({
		Name = data.Name or "Chart",
		Size = UDim2.new(1, 0, 0, height),
		BackgroundTransparency = 1,
		Parent = section.Inner,
	})

	local label = Helpers.CreateLabel({
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
		Size = UDim2.new(1, 0, 0, 30),
		Position = UDim2.fromOffset(0, 42),
		BackgroundTransparency = 1,
		Parent = root,
	})
	local lay = Instance.new("UIListLayout")
	lay.FillDirection = Enum.FillDirection.Horizontal
	lay.VerticalAlignment = Enum.VerticalAlignment.Bottom
	lay.HorizontalAlignment = Enum.HorizontalAlignment.Left
	lay.HorizontalFlex = Enum.UIFlexAlignment.None
	lay.Padding = UDim.new(0, 2)
	lay.Parent = barsHold

	local bars = {}
	for i = 1, barCount do
		local bar = Instance.new("Frame")
		bar.Name = "B" .. i
		-- Scale width so the row fills the element (minus padding gaps)
		bar.Size = UDim2.new(1 / barCount, -2, 0, 4)
		bar.BorderSizePixel = 0
		bar.BackgroundColor3 = color
		bar.BackgroundTransparency = 0.45
		bar.Parent = barsHold
		Helpers.Corner(bar, 2)
		bars[i] = bar
	end

	local self = setmetatable({
		_Section = section,
		_Data = data,
		_Bars = bars,
		_History = table.create(barCount, 0),
		_MaxRef = maxRef,
		_Color = color,
		_BarCount = barCount,
		_Seeded = false,
		Instance = root,
		Label = label,
		ValueLabel = valueLbl,
	}, Chart)

	return self
end

local function isFiniteNumber(value: number): boolean
	return value == value and value ~= math.huge and value ~= -math.huge
end

function Chart:_formatValue(value: any): string
	local n = tonumber(value)
	if n and isFiniteNumber(n) then
		local text = if n % 1 == 0 then tostring(math.floor(n)) else string.format("%.2f", n):gsub("0+$", ""):gsub("%.$", "")
		return text .. (self._Data.Suffix or "")
	end
	return tostring(value)
end

function Chart:Set(value: any, pushHistory: boolean?)
	local n = tonumber(value)
	if n and not isFiniteNumber(n) then n = nil end
	self.ValueLabel.Text = self:_formatValue(if n ~= nil then n else value)
	if n ~= nil and pushHistory ~= false then
		table.remove(self._History, 1)
		table.insert(self._History, n)
		self:_paint()
	end
end

function Chart:Push(value: number)
	local n = tonumber(value) or 0
	-- First real sample fills the whole strip so bars don't "grow" from the middle/right.
	if not self._Seeded then
		for i = 1, self._BarCount do
			self._History[i] = n
		end
		self._Seeded = true
	else
		table.remove(self._History, 1)
		table.insert(self._History, n)
	end
	local label = tostring(n)
	if self._Data.Suffix then
		label = label .. self._Data.Suffix
	end
	self.ValueLabel.Text = label
	self:_paint()
end

function Chart:_paint()
	local maxV = self._MaxRef
	for _, value in self._History do
		if isFiniteNumber(value) then
			maxV = math.max(maxV, math.abs(value))
		end
	end
	maxV = math.max(maxV, 1)

	for i, bar in self._Bars do
		local value = self._History[i] or 0
		local magnitude = if isFiniteNumber(value) then math.abs(value) else 0
		local ratio = math.clamp(magnitude / maxV, 0, 1)
		local h = if magnitude == 0 then 0 else math.clamp(math.floor(ratio * 28 + 0.5), 3, 30)
		bar.Size = UDim2.new(1 / self._BarCount, -2, 0, h)
		bar.BackgroundColor3 = self._Color
		bar.BackgroundTransparency = 0.12 + (1 - ratio) * 0.5
	end
end

function Chart:SetColor(color: Color3)
	self._Color = color
	self.ValueLabel.TextColor3 = color
	self:_paint()
end

function Chart:RefreshTheme()
	local theme = self._Section.Tab.Window.Library.Theme
	self.Label.TextColor3 = theme.TextMuted
	if not self._Data.Color then
		self._Color = theme.Accent
		self.ValueLabel.TextColor3 = theme.Accent
		self:_paint()
	else
		self.ValueLabel.TextColor3 = self._Data.Color
		self:_paint()
	end
end

function Chart:Destroy()
	if self.Instance and self.Instance.Parent then
		self.Instance:Destroy()
	end
end

return Chart
