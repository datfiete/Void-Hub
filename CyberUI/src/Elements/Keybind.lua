--!strict

local UserInputService = game:GetService("UserInputService")

local Theme = require(script.Parent.Parent.Core.Theme)
local Maid = require(script.Parent.Parent.Utils.Maid)
local Helpers = require(script.Parent.Parent.Utils.Helpers)
local Tween = require(script.Parent.Parent.Utils.Tween)

local Keybind = {}
Keybind.__index = Keybind

export type KeybindOptions = {
	Name: string,
	Default: Enum.KeyCode?,
	CurrentKeybind: Enum.KeyCode?,
	Flag: string?,
	Save: boolean?,
	Callback: ((key: Enum.KeyCode) -> ())?,
}

export type KeybindHandle = {
	Set: (self: KeybindHandle, key: Enum.KeyCode) -> (),
	Get: (self: KeybindHandle) -> Enum.KeyCode,
	OnChanged: (self: KeybindHandle, callback: (key: Enum.KeyCode) -> ()) -> RBXScriptConnection,
	Destroy: (self: KeybindHandle) -> (),
}

local function isBindableInput(input: InputObject): boolean
	return input.UserInputType == Enum.UserInputType.Keyboard
		or input.KeyCode == Enum.KeyCode.ButtonX
		or input.KeyCode == Enum.KeyCode.ButtonY
		or input.KeyCode == Enum.KeyCode.ButtonA
		or input.KeyCode == Enum.KeyCode.ButtonB
end

function Keybind.new(section: any, data: KeybindOptions): KeybindHandle
	local initial = data.CurrentKeybind or data.Default or Enum.KeyCode.Unknown

	local library = section.Tab.Window.Library
	initial = library:_getSavedFlag(data.Flag, initial, data.Save)

	local self = setmetatable({
		_Section = section,
		_Data = data,
		_Maid = Maid.new(),
		_Value = initial,
		_Listening = false,
		_ListenMaid = nil :: any,
		_Changed = Instance.new("BindableEvent"),
	}, Keybind)

	local row = Helpers.CreateFrame({
		Name = "Keybind",
		Size = UDim2.new(1, 0, 0, Theme.ElementHeight),
		BackgroundColor3 = library.Theme.Background,
		Parent = section.Inner,
	})
	Helpers.Corner(row, Theme.CornerRadiusSmall)

	Helpers.CreateLabel({
		Name = "Label",
		Size = UDim2.new(1, -110, 1, 0),
		Position = UDim2.new(0, 12, 0, 0),
		Text = data.Name,
		Parent = row,
	})

	local bindButton = Helpers.CreateButton({
		Name = "BindButton",
		Size = UDim2.fromOffset(84, 28),
		Position = UDim2.new(1, -12, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		Text = Helpers.KeyCodeToString(initial),
		TextXAlignment = Enum.TextXAlignment.Center,
		BackgroundColor3 = library.Theme.Secondary,
		Parent = row,
	})
	Helpers.Corner(bindButton, Theme.CornerRadiusSmall)
	Helpers.Stroke(bindButton, library.Theme.Border, 1)

	self.Instance = row
	self.BindButton = bindButton

	function self:_applyVisual(listening: boolean?)
		if listening then
			bindButton.Text = "..."
			Tween.Play(bindButton, { BackgroundColor3 = library.Theme.Accent, TextColor3 = library.Theme.Background })
		else
			bindButton.Text = Helpers.KeyCodeToString(self._Value)
			Tween.Play(bindButton, { BackgroundColor3 = library.Theme.Secondary, TextColor3 = library.Theme.Text })
		end
	end

	function self:_stopListening()
		if self._ListenMaid then
			self._ListenMaid:DoCleaning()
			self._ListenMaid = nil
		end
		self._Listening = false
		self:_applyVisual(false)
	end

	function self:_startListening()
		if self._Listening then
			return
		end

		self._Listening = true
		self:_applyVisual(true)

		local listenMaid = Maid.new()
		self._ListenMaid = listenMaid

		listenMaid:GiveTask(UserInputService.InputBegan:Connect(function(input, processed)
			if processed then
				return
			end

			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.MouseButton2
				or input.UserInputType == Enum.UserInputType.MouseButton3
			then
				self:_stopListening()
				return
			end

			if isBindableInput(input) and input.KeyCode ~= Enum.KeyCode.Unknown then
				self:_commit(input.KeyCode)
				self:_stopListening()
			end
		end))

		task.delay(5, function()
			if self._Listening then
				self:_stopListening()
			end
		end)
	end

	function self:_commit(key: Enum.KeyCode, fireCallback: boolean?)
		self._Value = key
		self:_applyVisual(false)
		library:_setFlag(data.Flag, key, data.Save)
		self._Changed:Fire(key)

		if fireCallback ~= false and data.Callback then
			task.spawn(data.Callback, key)
		end
	end

	self._Maid:Give(self._Changed)
	self._Maid:GiveTask(bindButton.MouseButton1Click:Connect(function()
		if self._Listening then
			self:_stopListening()
		else
			self:_startListening()
		end
	end))

	if data.Flag then
		library:_setFlag(data.Flag, self._Value, data.Save)
	end

	self:_applyVisual(false)

	return self :: any
end

function Keybind:RefreshTheme()
	local theme = self._Section.Tab.Window.Library.Theme
	self.Instance.BackgroundColor3 = theme.Background
	self.BindButton.BackgroundColor3 = if self._Listening then theme.Accent else theme.Secondary
	self.BindButton.TextColor3 = if self._Listening then theme.Background else theme.Text
	local stroke = self.BindButton:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Color = theme.Border
	end
end

function Keybind:Set(key: Enum.KeyCode)
	self:_commit(key, false)
end

function Keybind:Get(): Enum.KeyCode
	return self._Value
end

function Keybind:OnChanged(callback: (key: Enum.KeyCode) -> ()): RBXScriptConnection
	return self._Changed.Event:Connect(callback)
end

function Keybind:Destroy()
	self:_stopListening()
	self._Maid:DoCleaning()
end

return Keybind
