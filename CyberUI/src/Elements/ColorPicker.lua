--!strict

local UserInputService = game:GetService("UserInputService")

local Theme = require(script.Parent.Parent.Core.Theme)
local Maid = require(script.Parent.Parent.Utils.Maid)
local Helpers = require(script.Parent.Parent.Utils.Helpers)
local Tween = require(script.Parent.Parent.Utils.Tween)

local ColorPicker = {}
ColorPicker.__index = ColorPicker

export type ColorPickerOptions = {
	Name: string,
	Default: Color3?,
	CurrentValue: Color3?,
	Flag: string?,
	Save: boolean?,
	Callback: ((color: Color3) -> ())?,
}

export type ColorPickerHandle = {
	Set: (self: ColorPickerHandle, color: Color3) -> (),
	Get: (self: ColorPickerHandle) -> Color3,
	OnChanged: (self: ColorPickerHandle, callback: (color: Color3) -> ()) -> RBXScriptConnection,
	Destroy: (self: ColorPickerHandle) -> (),
}

function ColorPicker.new(section: any, data: ColorPickerOptions): ColorPickerHandle
	local library = section.Tab.Window.Library
	local initial = data.CurrentValue or data.Default or Theme.Accent
	initial = library:_getSavedFlag(data.Flag, initial, data.Save)
	local hue, saturation, value = initial:ToHSV()

	local self = setmetatable({
		_Section = section,
		_Data = data,
		_Maid = Maid.new(),
		_Value = initial,
		_Hue = hue,
		_Saturation = saturation,
		_ValueChannel = value,
		_Open = false,
		_Dragging = nil :: string?,
		_Changed = Instance.new("BindableEvent"),
	}, ColorPicker)

	local container = Helpers.CreateFrame({
		Name = "ColorPicker",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = section.Inner,
	})
	Helpers.ListLayout(container, 6)

	local header = Helpers.CreateFrame({
		Name = "Header",
		Size = UDim2.new(1, 0, 0, Theme.ElementHeight),
		BackgroundColor3 = library.Theme.Background,
		Active = true,
		Parent = container,
	})
	Helpers.Corner(header, Theme.CornerRadiusSmall)

	Helpers.CreateLabel({
		Name = "Label",
		Size = UDim2.new(1, -72, 1, 0),
		Position = UDim2.new(0, 12, 0, 0),
		Text = data.Name,
		Parent = header,
	})

	local preview = Helpers.CreateButton({
		Name = "Preview",
		Size = UDim2.fromOffset(28, 28),
		Position = UDim2.new(1, -12, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		Text = "",
		BackgroundColor3 = initial,
		Parent = header,
	})
	Helpers.Corner(preview, Theme.CornerRadiusSmall)
	Helpers.Stroke(preview, library.Theme.Border, 1)

	local panel = Helpers.CreateFrame({
		Name = "Panel",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = library.Theme.Background,
		Visible = false,
		Parent = container,
	})
	Helpers.Corner(panel, Theme.CornerRadiusSmall)
	Helpers.Stroke(panel, library.Theme.Border, 1)
	Helpers.Padding(panel, 10)
	Helpers.ListLayout(panel, 8)

	local svBox = Helpers.CreateFrame({
		Name = "SVBox",
		Size = UDim2.new(1, 0, 0, 90),
		BackgroundColor3 = Color3.fromHSV(self._Hue, 1, 1),
		Parent = panel,
	})
	Helpers.Corner(svBox, Theme.CornerRadiusSmall)

	local whiteOverlay = Helpers.CreateFrame({
		Name = "WhiteOverlay",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0,
		Parent = svBox,
	})
	local whiteGradient = Instance.new("UIGradient")
	whiteGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	whiteGradient.Parent = whiteOverlay

	local blackOverlay = Helpers.CreateFrame({
		Name = "BlackOverlay",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0,
		Parent = svBox,
	})
	local blackGradient = Instance.new("UIGradient")
	blackGradient.Rotation = 90
	blackGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(1, 0),
	})
	blackGradient.Parent = blackOverlay

	local svCursor = Helpers.CreateFrame({
		Name = "Cursor",
		Size = UDim2.fromOffset(10, 10),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = svBox,
	})
	Helpers.Corner(svCursor, 999)
	Helpers.Stroke(svCursor, Color3.new(0, 0, 0), 1)

	local hueTrack = Helpers.CreateFrame({
		Name = "HueTrack",
		Size = UDim2.new(1, 0, 0, 12),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = panel,
	})
	Helpers.Corner(hueTrack, 999)

	local hueGradient = Instance.new("UIGradient")
	hueGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)),
		ColorSequenceKeypoint.new(0.17, Color3.fromHSV(0.17, 1, 1)),
		ColorSequenceKeypoint.new(0.33, Color3.fromHSV(0.33, 1, 1)),
		ColorSequenceKeypoint.new(0.5, Color3.fromHSV(0.5, 1, 1)),
		ColorSequenceKeypoint.new(0.67, Color3.fromHSV(0.67, 1, 1)),
		ColorSequenceKeypoint.new(0.83, Color3.fromHSV(0.83, 1, 1)),
		ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1)),
	})
	hueGradient.Parent = hueTrack

	local hueCursor = Helpers.CreateFrame({
		Name = "HueCursor",
		Size = UDim2.new(0, 4, 1, 4),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = hueTrack,
	})
	Helpers.Corner(hueCursor, 999)
	Helpers.Stroke(hueCursor, Color3.new(0, 0, 0), 1)

	local hexLabel = Helpers.CreateLabel({
		Name = "Hex",
		Size = UDim2.new(1, 0, 0, 16),
		Text = Helpers.ColorToHex(initial),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextColor3 = library.Theme.TextMuted,
		TextSize = 12,
		Parent = panel,
	})

	self.Instance = container
	self.Header = header
	self.Preview = preview
	self.HexLabel = hexLabel
	self.Panel = panel
	self.SVBox = svBox
	self.SVCursor = svCursor
	self.HueTrack = hueTrack
	self.HueCursor = hueCursor

	function self:_composeColor(): Color3
		return Color3.fromHSV(self._Hue, self._Saturation, self._ValueChannel)
	end

	function self:_applyVisual(fireCallback: boolean?)
		local color = self:_composeColor()
		self._Value = color
		svBox.BackgroundColor3 = Color3.fromHSV(self._Hue, 1, 1)
		svCursor.Position = UDim2.new(self._Saturation, 0, 1 - self._ValueChannel, 0)
		hueCursor.Position = UDim2.new(self._Hue, 0, 0.5, 0)
		preview.BackgroundColor3 = color
		hexLabel.Text = Helpers.ColorToHex(color)
		library:_setFlag(data.Flag, color, data.Save)
		self._Changed:Fire(color)

		if fireCallback ~= false and data.Callback then
			task.spawn(data.Callback, color)
		end
	end

	function self:SetOpen(open: boolean)
		self._Open = open
		panel.Visible = open
	end

	function self:_updateFromSV(input: InputObject)
		local position = svBox.AbsolutePosition
		local size = svBox.AbsoluteSize
		if size.X <= 0 or size.Y <= 0 then
			return
		end

		self._Saturation = Helpers.Clamp((input.Position.X - position.X) / size.X, 0, 1)
		self._ValueChannel = 1 - Helpers.Clamp((input.Position.Y - position.Y) / size.Y, 0, 1)
		self:_applyVisual()
	end

	function self:_updateFromHue(input: InputObject)
		local position = hueTrack.AbsolutePosition
		local size = hueTrack.AbsoluteSize
		if size.X <= 0 then
			return
		end

		self._Hue = Helpers.Clamp((input.Position.X - position.X) / size.X, 0, 1)
		self:_applyVisual()
	end

	local function bindDrag(target: Frame, mode: string)
		self._Maid:GiveTask(target.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				self._Dragging = mode
				if mode == "sv" then
					self:_updateFromSV(input)
				else
					self:_updateFromHue(input)
				end
			end
		end))
	end

	bindDrag(svBox, "sv")
	bindDrag(hueTrack, "hue")

	self._Maid:GiveTask(UserInputService.InputChanged:Connect(function(input)
		if self._Dragging == nil then
			return
		end

		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			if self._Dragging == "sv" then
				self:_updateFromSV(input)
			elseif self._Dragging == "hue" then
				self:_updateFromHue(input)
			end
		end
	end))

	self._Maid:GiveTask(UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			self._Dragging = nil
		end
	end))

	self._Maid:Give(self._Changed)
	self._Maid:GiveTask(preview.MouseButton1Click:Connect(function()
		self:SetOpen(not self._Open)
	end))
	self._Maid:GiveTask(header.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			self:SetOpen(not self._Open)
		end
	end))

	if data.Flag then
		library:_setFlag(data.Flag, self._Value, data.Save)
	end

	self:_applyVisual(false)

	return self :: any
end

function ColorPicker:RefreshTheme()
	local theme = self._Section.Tab.Window.Library.Theme
	self.Header.BackgroundColor3 = theme.Background
	self.Preview.BackgroundColor3 = self._Value
	self.HexLabel.TextColor3 = theme.TextMuted
	self.Panel.BackgroundColor3 = theme.Background
	local stroke = self.Preview:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Color = theme.Border
	end
	local panelStroke = self.Panel:FindFirstChildOfClass("UIStroke")
	if panelStroke then
		panelStroke.Color = theme.Border
	end
end

function ColorPicker:Set(color: Color3)
	self._Hue, self._Saturation, self._ValueChannel = color:ToHSV()
	self:_applyVisual(false)
end

function ColorPicker:Get(): Color3
	return self._Value
end

function ColorPicker:OnChanged(callback: (color: Color3) -> ()): RBXScriptConnection
	return self._Changed.Event:Connect(callback)
end

function ColorPicker:Destroy()
	self._Dragging = nil
	self:SetOpen(false)
	self._Maid:DoCleaning()
end

return ColorPicker
