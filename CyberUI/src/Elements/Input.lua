--!strict

local Theme = require(script.Parent.Parent.Core.Theme)
local Maid = require(script.Parent.Parent.Utils.Maid)
local Helpers = require(script.Parent.Parent.Utils.Helpers)

local Input = {}
Input.__index = Input

export type InputOptions = {
	Name: string,
	Placeholder: string?,
	Default: string?,
	CurrentValue: string?,
	Flag: string?,
	Save: boolean?,
	Callback: ((value: string) -> ())?,
}

export type InputHandle = {
	Set: (self: InputHandle, value: string) -> (),
	Get: (self: InputHandle) -> string,
	OnChanged: (self: InputHandle, callback: (value: string) -> ()) -> RBXScriptConnection,
	Destroy: (self: InputHandle) -> (),
}

function Input.new(section: any, data: InputOptions): InputHandle
	local initial = data.CurrentValue or data.Default or ""
	local library = section.Tab.Window.Library
	initial = library:_getSavedFlag(data.Flag, initial, data.Save)

	local self = setmetatable({
		_Section = section,
		_Data = data,
		_Maid = Maid.new(),
		_Value = initial,
		_Changed = Instance.new("BindableEvent"),
	}, Input)

	local row = Helpers.CreateFrame({
		Name = "Input",
		Size = UDim2.new(1, 0, 0, Theme.ElementHeight + 36),
		BackgroundColor3 = library.Theme.Background,
		Parent = section.Inner,
	})
	Helpers.Corner(row, Theme.CornerRadiusSmall)

	Helpers.CreateLabel({
		Name = "Label",
		Size = UDim2.new(1, -24, 0, 18),
		Position = UDim2.new(0, 12, 0, 8),
		Text = data.Name,
		Parent = row,
	})

	local textBox = Helpers.CreateTextBox({
		Name = "TextBox",
		Size = UDim2.new(1, -24, 0, 30),
		Position = UDim2.new(0, 12, 1, -10),
		AnchorPoint = Vector2.new(0, 1),
		Text = initial,
		PlaceholderText = data.Placeholder or "Enter text...",
		Parent = row,
	})
	Helpers.Corner(textBox, Theme.CornerRadiusSmall)
	Helpers.Stroke(textBox, library.Theme.Border, 1)
	Helpers.Padding(textBox, 8)

	self.Instance = row
	self.TextBox = textBox

	function self:_commit(value: string, fireCallback: boolean?)
		self._Value = value
		textBox.Text = value
		library:_setFlag(data.Flag, value, data.Save)
		self._Changed:Fire(value)

		if fireCallback ~= false and data.Callback then
			task.spawn(data.Callback, value)
		end
	end

	self._Maid:Give(self._Changed)
	self._Maid:GiveTask(textBox.FocusLost:Connect(function(enterPressed: boolean)
		self:_commit(textBox.Text, enterPressed)
	end))

	if data.Flag then
		library:_setFlag(data.Flag, self._Value, data.Save)
	end

	return self :: any
end

function Input:RefreshTheme()
	local theme = self._Section.Tab.Window.Library.Theme
	self.Instance.BackgroundColor3 = theme.Background
	self.TextBox.BackgroundColor3 = theme.Background
	self.TextBox.TextColor3 = theme.Text
	self.TextBox.PlaceholderColor3 = theme.TextMuted
	local stroke = self.TextBox:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Color = theme.Border
	end
end

function Input:Set(value: string)
	self:_commit(value, false)
end

function Input:Get(): string
	return self._Value
end

function Input:OnChanged(callback: (value: string) -> ()): RBXScriptConnection
	return self._Changed.Event:Connect(callback)
end

function Input:Destroy()
	self._Maid:DoCleaning()
end

return Input
