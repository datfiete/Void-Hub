--!strict

local Theme = require(script.Parent.Parent.Core.Theme)

local Helpers = {}

export type FrameProps = {
	Name: string?,
	Size: UDim2?,
	Position: UDim2?,
	AnchorPoint: Vector2?,
	BackgroundColor3: Color3?,
	BackgroundTransparency: number?,
	BorderSizePixel: number?,
	AutomaticSize: Enum.AutomaticSize?,
	Visible: boolean?,
	LayoutOrder: number?,
	ZIndex: number?,
	Parent: Instance?,
}

export type TextProps = {
	Name: string?,
	Size: UDim2?,
	Position: UDim2?,
	AnchorPoint: Vector2?,
	BackgroundTransparency: number?,
	BackgroundColor3: Color3?,
	Text: string?,
	PlaceholderText: string?,
	TextColor3: Color3?,
	PlaceholderColor3: Color3?,
	TextSize: number?,
	Font: Enum.Font?,
	TextXAlignment: Enum.TextXAlignment?,
	TextYAlignment: Enum.TextYAlignment?,
	TextWrapped: boolean?,
	RichText: boolean?,
	ClearTextOnFocus: boolean?,
	AutomaticSize: Enum.AutomaticSize?,
	LayoutOrder: number?,
	ZIndex: number?,
	Parent: Instance?,
}

function Helpers.Corner(parent: Instance, radius: number): UICorner
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
	return corner
end

function Helpers.Stroke(parent: Instance, color: Color3, thickness: number?): UIStroke
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness or 1
	stroke.Parent = parent
	return stroke
end

function Helpers.Padding(parent: Instance, padding: number | Rect): UIPadding
	local uiPadding = Instance.new("UIPadding")

	if typeof(padding) == "number" then
		local offset = UDim.new(0, padding)
		uiPadding.PaddingTop = offset
		uiPadding.PaddingBottom = offset
		uiPadding.PaddingLeft = offset
		uiPadding.PaddingRight = offset
	else
		uiPadding.PaddingTop = UDim.new(0, padding.Min.Y)
		uiPadding.PaddingBottom = UDim.new(0, padding.Max.Y)
		uiPadding.PaddingLeft = UDim.new(0, padding.Min.X)
		uiPadding.PaddingRight = UDim.new(0, padding.Max.X)
	end

	uiPadding.Parent = parent
	return uiPadding
end

function Helpers.ListLayout(
	parent: Instance,
	padding: number?,
	horizontal: boolean?,
	fillDirection: Enum.FillDirection?
): UIListLayout
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, padding or 8)
	layout.FillDirection = fillDirection or (if horizontal then Enum.FillDirection.Horizontal else Enum.FillDirection.Vertical)
	layout.Parent = parent
	return layout
end

function Helpers.Apply<T>(instance: T & Instance, props: { [string]: any }): T
	for key, value in props do
		if key ~= "Parent" and value ~= nil then
			(instance :: any)[key] = value
		end
	end

	if props.Parent then
		instance.Parent = props.Parent
	end

	return instance
end

function Helpers.CreateFrame(props: FrameProps): Frame
	local frame = Instance.new("Frame")
	frame.Name = props.Name or "Frame"
	frame.Size = props.Size or UDim2.fromScale(1, 0)
	frame.BackgroundColor3 = props.BackgroundColor3 or Theme.Secondary
	frame.BorderSizePixel = props.BorderSizePixel or 0
	return Helpers.Apply(frame, props)
end

function Helpers.CreateLabel(props: TextProps): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = props.Name or "Label"
	label.Size = props.Size or UDim2.fromScale(1, 0)
	label.BackgroundTransparency = props.BackgroundTransparency or 1
	label.Text = props.Text or ""
	label.TextColor3 = props.TextColor3 or Theme.Text
	label.TextSize = props.TextSize or 14
	label.Font = props.Font or Theme.Font
	label.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
	label.TextYAlignment = props.TextYAlignment or Enum.TextYAlignment.Center
	return Helpers.Apply(label, props)
end

function Helpers.CreateButton(props: TextProps): TextButton
	local button = Instance.new("TextButton")
	button.Name = props.Name or "Button"
	button.Size = props.Size or UDim2.fromScale(1, 0)
	button.BackgroundColor3 = Theme.Secondary
	button.BorderSizePixel = 0
	button.AutoButtonColor = false
	button.Text = props.Text or ""
	button.TextColor3 = props.TextColor3 or Theme.Text
	button.TextSize = props.TextSize or 14
	button.Font = props.Font or Theme.Font
	button.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
	return Helpers.Apply(button, props)
end

function Helpers.CreateTextBox(props: TextProps): TextBox
	local textBox = Instance.new("TextBox")
	textBox.Name = props.Name or "TextBox"
	textBox.Size = props.Size or UDim2.fromScale(1, 0)
	textBox.BackgroundColor3 = props.BackgroundColor3 or Theme.Background
	textBox.BorderSizePixel = 0
	textBox.ClearTextOnFocus = if props.ClearTextOnFocus ~= nil then props.ClearTextOnFocus else false
	textBox.Text = props.Text or ""
	textBox.PlaceholderText = props.PlaceholderText or ""
	textBox.TextColor3 = props.TextColor3 or Theme.Text
	textBox.PlaceholderColor3 = props.PlaceholderColor3 or Theme.TextMuted
	textBox.TextSize = props.TextSize or 14
	textBox.Font = props.Font or Theme.Font
	textBox.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
	return Helpers.Apply(textBox, props)
end

function Helpers.Clamp(value: number, min: number, max: number): number
	return math.clamp(value, min, max)
end

function Helpers.Round(value: number, rounding: number?): number
	if rounding == nil or rounding <= 0 then
		return value
	end

	return math.floor(value / rounding + 0.5) * rounding
end

function Helpers.KeyCodeToString(keyCode: Enum.KeyCode): string
	if keyCode == Enum.KeyCode.Unknown then
		return "None"
	end

	local name = keyCode.Name

	if string.sub(name, 1, 5) == "Left" then
		return string.sub(name, 6)
	end

	if string.sub(name, 1, 6) == "Right" then
		return string.sub(name, 7)
	end

	return name
end

function Helpers.ColorToHex(color: Color3): string
	return string.format(
		"#%02X%02X%02X",
		math.floor(color.R * 255 + 0.5),
		math.floor(color.G * 255 + 0.5),
		math.floor(color.B * 255 + 0.5)
	)
end

function Helpers.SetFlag(flags: { [string]: any }, flag: string?, value: any)
	if flag then
		flags[flag] = value
	end
end

function Helpers.GetFlag(flags: { [string]: any }, flag: string?, default: any): any
	if flag and flags[flag] ~= nil then
		return flags[flag]
	end
	return default
end

return Helpers
