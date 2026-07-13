--!strict

local UserInputService = game:GetService("UserInputService")

local Theme = require(script.Parent.Parent.Core.Theme)
local Maid = require(script.Parent.Parent.Utils.Maid)
local Helpers = require(script.Parent.Parent.Utils.Helpers)
local Tween = require(script.Parent.Parent.Utils.Tween)

local Slider = {}
Slider.__index = Slider

export type SliderOptions = {
	Name: string,
	Min: number?,
	Max: number?,
	Default: number?,
	CurrentValue: number?,
	Rounding: number?,
	Flag: string?,
	Save: boolean?,
	Callback: ((value: number) -> ())?,
}

export type SliderHandle = {
	Set: (self: SliderHandle, value: number) -> (),
	Get: (self: SliderHandle) -> number,
	OnChanged: (self: SliderHandle, callback: (value: number) -> ()) -> RBXScriptConnection,
	Destroy: (self: SliderHandle) -> (),
}

function Slider.new(section: any, data: SliderOptions): SliderHandle
	local min = data.Min or 0
	local max = data.Max or 100
	local rounding = data.Rounding or 1
	local initial = data.CurrentValue or data.Default or min
	local library = section.Tab.Window.Library
	initial = library:_getSavedFlag(data.Flag, initial, data.Save)

	local self = setmetatable({
		_Section = section,
		_Data = data,
		_Maid = Maid.new(),
		_Min = min,
		_Max = max,
		_Rounding = rounding,
		_Value = Helpers.Clamp(Helpers.Round(initial, rounding), min, max),
		_Dragging = false,
		_Changed = Instance.new("BindableEvent"),
	}, Slider)

	local row = Helpers.CreateFrame({
		Name = "Slider",
		Size = UDim2.new(1, 0, 0, Theme.ElementHeight + 18),
		BackgroundColor3 = library.Theme.Background,
		Parent = section.Inner,
	})
	Helpers.Corner(row, Theme.CornerRadiusSmall)

	local label = Helpers.CreateLabel({
		Name = "Label",
		Size = UDim2.new(1, -56, 0, 18),
		Position = UDim2.new(0, 12, 0, 8),
		Text = data.Name,
		Parent = row,
	})

	local valueLabel = Helpers.CreateLabel({
		Name = "Value",
		Size = UDim2.new(0, 44, 0, 18),
		Position = UDim2.new(1, -12, 0, 8),
		AnchorPoint = Vector2.new(1, 0),
		Text = tostring(self._Value),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextColor3 = library.Theme.Accent,
		Parent = row,
	})

	local track = Helpers.CreateFrame({
		Name = "Track",
		Size = UDim2.new(1, -24, 0, 6),
		Position = UDim2.new(0, 12, 1, -16),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = library.Theme.Border,
		Parent = row,
	})
	Helpers.Corner(track, 999)

	local fill = Helpers.CreateFrame({
		Name = "Fill",
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = library.Theme.Accent,
		Parent = track,
	})
	Helpers.Corner(fill, 999)

	local knob = Helpers.CreateFrame({
		Name = "Knob",
		Size = UDim2.fromOffset(14, 14),
		Position = UDim2.new(0, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = library.Theme.Text,
		Parent = track,
	})
	Helpers.Corner(knob, 999)

	local clickTarget = Helpers.CreateButton({
		Name = "ClickTarget",
		Size = UDim2.new(1, 24, 0, 24),
		Position = UDim2.new(0, -12, 1, -16),
		AnchorPoint = Vector2.new(0, 0.5),
		Text = "",
		BackgroundTransparency = 1,
		Parent = row,
	})

	self.Instance = row
	self.Label = label
	self.ValueLabel = valueLabel
	self.Track = track
	self.Fill = fill
	self.Knob = knob

	function self:_ratio(): number
		if self._Max == self._Min then
			return 0
		end
		return (self._Value - self._Min) / (self._Max - self._Min)
	end

	function self:_applyVisual(animate: boolean?)
		local ratio = self:_ratio()
		local targetFill = UDim2.new(ratio, 0, 1, 0)
		local targetKnob = UDim2.new(ratio, 0, 0.5, 0)
		self.ValueLabel.Text = tostring(self._Value)

		if animate then
			Tween.Play(self.Fill, { Size = targetFill })
			Tween.Play(self.Knob, { Position = targetKnob })
		else
			self.Fill.Size = targetFill
			self.Knob.Position = targetKnob
		end
	end

	function self:_commit(value: number, fireCallback: boolean?)
		value = Helpers.Clamp(Helpers.Round(value, self._Rounding), self._Min, self._Max)
		self._Value = value
		self:_applyVisual(true)
		library:_setFlag(data.Flag, value, data.Save)
		self._Changed:Fire(value)

		if fireCallback ~= false and data.Callback then
			task.spawn(data.Callback, value)
		end
	end

	function self:_updateFromInput(input: InputObject)
		local trackPosition = track.AbsolutePosition.X
		local trackSize = track.AbsoluteSize.X
		if trackSize <= 0 then
			return
		end

		local alpha = Helpers.Clamp((input.Position.X - trackPosition) / trackSize, 0, 1)
		local value = self._Min + (self._Max - self._Min) * alpha
		self:_commit(value)
	end

	self._Maid:Give(self._Changed)
	self._Maid:GiveTask(clickTarget.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			self._Dragging = true
			self:_updateFromInput(input)
		end
	end))

	self._Maid:GiveTask(UserInputService.InputChanged:Connect(function(input)
		if self._Dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			self:_updateFromInput(input)
		end
	end))

	self._Maid:GiveTask(UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			self._Dragging = false
		end
	end))

	if data.Flag then
		library:_setFlag(data.Flag, self._Value, data.Save)
	end

	self:_applyVisual(false)

	return self :: any
end

function Slider:RefreshTheme()
	local theme = self._Section.Tab.Window.Library.Theme
	self.Instance.BackgroundColor3 = theme.Background
	self.Label.TextColor3 = theme.Text
	self.ValueLabel.TextColor3 = theme.Accent
	self.Track.BackgroundColor3 = theme.Border
	self.Fill.BackgroundColor3 = theme.Accent
	self.Knob.BackgroundColor3 = theme.Text
	self:_applyVisual(false)
end

function Slider:Set(value: number)
	self:_commit(value, false)
end

function Slider:Get(): number
	return self._Value
end

function Slider:OnChanged(callback: (value: number) -> ()): RBXScriptConnection
	return self._Changed.Event:Connect(callback)
end

function Slider:Destroy()
	self._Dragging = false
	self._Maid:DoCleaning()
end

return Slider
