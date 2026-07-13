--!strict

local Theme = require(script.Parent.Parent.Core.Theme)
local Maid = require(script.Parent.Parent.Utils.Maid)
local Helpers = require(script.Parent.Parent.Utils.Helpers)
local Tween = require(script.Parent.Parent.Utils.Tween)

local Toggle = {}
Toggle.__index = Toggle

export type ToggleOptions = {
	Name: string,
	CurrentValue: boolean?,
	Default: boolean?,
	Flag: string?,
	Save: boolean?,
	Callback: ((value: boolean) -> ())?,
}

export type ToggleHandle = {
	Set: (self: ToggleHandle, value: boolean) -> (),
	Get: (self: ToggleHandle) -> boolean,
	OnChanged: (self: ToggleHandle, callback: (value: boolean) -> ()) -> RBXScriptConnection,
	Destroy: (self: ToggleHandle) -> (),
}

function Toggle.new(section: any, data: ToggleOptions): ToggleHandle
	local self = setmetatable({
		_Section = section,
		_Data = data,
		_Maid = Maid.new(),
		_Value = data.CurrentValue == true or data.Default == true,
		_Changed = Instance.new("BindableEvent"),
	}, Toggle)

	local library = section.Tab.Window.Library
	self._Value = library:_getSavedFlag(data.Flag, self._Value, data.Save)

	local row = Helpers.CreateFrame({
		Name = "Toggle",
		Size = UDim2.new(1, 0, 0, Theme.ElementHeight),
		BackgroundColor3 = library.Theme.Background,
		Parent = section.Inner,
	})
	Helpers.Corner(row, Theme.CornerRadiusSmall)

	local label = Helpers.CreateLabel({
		Name = "Label",
		Size = UDim2.new(1, -56, 1, 0),
		Position = UDim2.new(0, 12, 0, 0),
		Text = data.Name,
		Parent = row,
	})

	local switch = Helpers.CreateFrame({
		Name = "Switch",
		Size = UDim2.fromOffset(40, 22),
		Position = UDim2.new(1, -12, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundColor3 = library.Theme.Border,
		Parent = row,
	})
	Helpers.Corner(switch, 999)

	local knob = Helpers.CreateFrame({
		Name = "Knob",
		Size = UDim2.fromOffset(16, 16),
		Position = UDim2.new(0, 3, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = library.Theme.Text,
		Parent = switch,
	})
	Helpers.Corner(knob, 999)

	local clickTarget = Helpers.CreateButton({
		Name = "ClickTarget",
		Size = UDim2.fromScale(1, 1),
		Text = "",
		BackgroundTransparency = 1,
		Parent = row,
	})

	self.Instance = row
	self.Label = label
	self.Switch = switch
	self.Knob = knob

	function self:_applyVisual(value: boolean, animate: boolean?)
		local onColor = library.Theme.Accent
		local offColor = library.Theme.Border
		local targetPosition = if value then UDim2.new(1, -19, 0.5, 0) else UDim2.new(0, 3, 0.5, 0)
		local targetColor = if value then onColor else offColor

		if animate then
			Tween.Play(knob, { Position = targetPosition })
			Tween.Play(switch, { BackgroundColor3 = targetColor })
		else
			knob.Position = targetPosition
			switch.BackgroundColor3 = targetColor
		end
	end

	function self:_commit(value: boolean, fireCallback: boolean?)
		self._Value = value
		self:_applyVisual(value, true)
		library:_setFlag(data.Flag, value, data.Save)
		self._Changed:Fire(value)

		if fireCallback ~= false and data.Callback then
			task.spawn(data.Callback, value)
		end
	end

	self._Maid:Give(self._Changed)
	self._Maid:GiveTask(clickTarget.MouseButton1Click:Connect(function()
		self:_commit(not self._Value)
	end))

	if data.Flag then
		library:_setFlag(data.Flag, self._Value, data.Save)
	end

	self:_applyVisual(self._Value, false)

	return self :: any
end

function Toggle:RefreshTheme()
	local theme = self._Section.Tab.Window.Library.Theme
	self.Instance.BackgroundColor3 = theme.Background
	self.Label.TextColor3 = theme.Text
	self.Switch.BackgroundColor3 = if self._Value then theme.Accent else theme.Border
	self.Knob.BackgroundColor3 = theme.Text
end

function Toggle:Set(value: boolean)
	self:_commit(value, false)
end

function Toggle:Get(): boolean
	return self._Value
end

function Toggle:OnChanged(callback: (value: boolean) -> ()): RBXScriptConnection
	return self._Changed.Event:Connect(callback)
end

function Toggle:Destroy()
	self._Maid:DoCleaning()
end

return Toggle
