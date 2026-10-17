--!strict

local Theme = require(script.Parent.Parent.Core.Theme)
local Helpers = require(script.Parent.Parent.Utils.Helpers)

local Chart = {}
Chart.__index = Chart

export type ChartOptions = {
	Name: string?,
	Label: string?,
	Value: string?,
	Color: Color3?,
	Bars: number?,
	Height: number?,
	Max: number?,
}

function Chart.new(section: any, data: ChartOptions?): any
	data = data or {}
	local theme = section.Tab.Window.Library.Theme
	local barCount = math.clamp(tonumber(data.Bars) or 20, 6, 40)
	local color = data.Color or theme.Accent
	local maxRef = tonumber(data.Max) or 60

	local root = Helpers.CreateFrame({
		Name = data.Name or "Chart",
		Size = UDim2.new(1, 0, 0, data.Height or 78),
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
		Instance = root,
		Label = label,
		ValueLabel = valueLbl,
	}, Chart)

	return self
end

function Chart:Set(value: any, pushHistory: boolean?)
	local n = tonumber(value)
	self.ValueLabel.Text = if n then (self._Data.Suffix and (tostring(n) .. self._Data.Suffix) or tostring(n)) else tostring(value)
	if n and pushHistory ~= false then
		table.remove(self._History, 1)
		table.insert(self._History, n)
		self:_paint()
	end
end

function Chart:Push(value: number)
	value = tonumber(value) or 0
	table.remove(self._History, 1)
	table.insert(self._History, value)
	self.ValueLabel.Text = if self._Data.Suffix then (tostring(value) .. self._Data.Suffix) else tostring(value)
	self:_paint()
end

function Chart:_paint()
	local maxV = self._MaxRef
	for _, v in self._History do
		if v > maxV then maxV = v end
	end
	if maxV < 1 then maxV = 1 end
	for i, bar in self._Bars do
		local v = self._History[i] or 0
		local h = math.clamp(math.floor((v / maxV) * 28 + 0.5), 3, 30)
		bar.Size = UDim2.new(1 / self._BarCount, -2, 0, h)
		bar.BackgroundColor3 = self._Color
		bar.BackgroundTransparency = 0.12 + (1 - v / maxV) * 0.5
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
	end
end

function Chart:Destroy()
	if self.Instance and self.Instance.Parent then
		self.Instance:Destroy()
	end
end

return Chart
