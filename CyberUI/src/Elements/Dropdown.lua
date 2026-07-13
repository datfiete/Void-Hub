--!strict

local Theme = require(script.Parent.Parent.Core.Theme)
local Maid = require(script.Parent.Parent.Utils.Maid)
local Helpers = require(script.Parent.Parent.Utils.Helpers)
local Tween = require(script.Parent.Parent.Utils.Tween)

local Dropdown = {}
Dropdown.__index = Dropdown

export type DropdownOptions = {
	Name: string,
	Options: { string },
	Default: string?,
	CurrentOption: string?,
	Flag: string?,
	Save: boolean?,
	Callback: ((value: string) -> ())?,
}

export type DropdownHandle = {
	Set: (self: DropdownHandle, value: string) -> (),
	Get: (self: DropdownHandle) -> string,
	OnChanged: (self: DropdownHandle, callback: (value: string) -> ()) -> RBXScriptConnection,
	Destroy: (self: DropdownHandle) -> (),
}

function Dropdown.new(section: any, data: DropdownOptions): DropdownHandle
	local options = data.Options or {}
	local multiple = data.MultipleOptions == true
	local initial = data.CurrentOption or data.Default or options[1] or ""
	local library = section.Tab.Window.Library
	initial = library:_getSavedFlag(data.Flag, initial, data.Save)

	local initialValue
	if multiple then
		initialValue = {}
		if type(initial) == "table" then
			for _, option in ipairs(initial) do
				if table.find(options, option) ~= nil then
					table.insert(initialValue, option)
				end
			end
		elseif initial ~= nil and initial ~= "" then
			table.insert(initialValue, initial)
		end
	else
		if type(initial) == "table" then
			initialValue = initial[1] or options[1] or ""
		else
			initialValue = initial or options[1] or ""
		end
	end

	local self = setmetatable({
		_Section = section,
		_Data = data,
		_Maid = Maid.new(),
		_Options = options,
		_Value = initialValue,
		_Open = false,
		_Multiple = multiple,
		_Changed = Instance.new("BindableEvent"),
		_OptionMaids = {} :: { any },
	}, Dropdown)

	local container = Helpers.CreateFrame({
		Name = "Dropdown",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = section.Inner,
	})
	Helpers.ListLayout(container, 4)

	local header = Helpers.CreateButton({
		Name = "Header",
		Size = UDim2.new(1, 0, 0, Theme.ElementHeight),
		Text = "",
		BackgroundColor3 = library.Theme.Background,
		Parent = container,
	})
	header.AutoButtonColor = false
	header.Active = true
	header.Selectable = true
	Helpers.Corner(header, Theme.CornerRadiusSmall)
	Helpers.Stroke(header, library.Theme.Border, 1)

	Helpers.CreateLabel({
		Name = "Label",
		Size = UDim2.new(0.5, 0, 1, 0),
		Position = UDim2.new(0, 12, 0, 0),
		Text = data.Name,
		Parent = header,
	})

	local selectedLabel = Helpers.CreateLabel({
		Name = "Selected",
		Size = UDim2.new(0.5, -28, 1, 0),
		Position = UDim2.new(0.5, 0, 0, 0),
		Text = if multiple and type(initialValue) == "table" and #initialValue > 0 then table.concat(initialValue, ", ") else tostring(initialValue or "None"),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextColor3 = library.Theme.Accent,
		Parent = header,
	})

	local arrow = Helpers.CreateLabel({
		Name = "Arrow",
		Size = UDim2.fromOffset(16, 16),
		Position = UDim2.new(1, -12, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		Text = "▼",
		TextSize = 12,
		TextColor3 = library.Theme.TextMuted,
		Parent = header,
	})

	local list = Helpers.CreateFrame({
		Name = "List",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = library.Theme.Background,
		Visible = false,
		Parent = container,
	})
	Helpers.Corner(list, Theme.CornerRadiusSmall)
	Helpers.Stroke(list, library.Theme.Border, 1)
	Helpers.Padding(list, 6)
	Helpers.ListLayout(list, 4)

	self.Instance = container
	self.Header = header
	self.SelectedLabel = selectedLabel
	self.List = list
	self.Arrow = arrow

	function self:_clearOptions()
		for _, optionMaid in self._OptionMaids do
			optionMaid:DoCleaning()
		end
		table.clear(self._OptionMaids)
	end

	function self:_updateSelectedLabel()
		if self._Multiple then
			if type(self._Value) == "table" and #self._Value > 0 then
				selectedLabel.Text = table.concat(self._Value, ", ")
			else
				selectedLabel.Text = "None"
			end
		else
			selectedLabel.Text = tostring(self._Value)
		end
	end

	function self:_buildOptions()
		self:_clearOptions()

		for _, option in self._Options do
			local optionMaid = Maid.new()
			table.insert(self._OptionMaids, optionMaid)

			local isSelected = if self._Multiple then type(self._Value) == "table" and table.find(self._Value, option) ~= nil else option == self._Value
			local button = Helpers.CreateButton({
				Name = option,
				Size = UDim2.new(1, 0, 0, 32),
				Text = `  {option}`,
				BackgroundColor3 = if isSelected then library.Theme.Secondary else library.Theme.Background,
				Parent = list,
			})
			Helpers.Corner(button, Theme.CornerRadiusSmall)
			optionMaid:Give(button)

			optionMaid:GiveTask(button.MouseEnter:Connect(function()
				if not isSelected then
					Tween.Play(button, { BackgroundColor3 = library.Theme.Secondary })
				end
			end))

			optionMaid:GiveTask(button.MouseLeave:Connect(function()
				if not isSelected then
					Tween.Play(button, { BackgroundColor3 = library.Theme.Background })
				end
			end))

			optionMaid:GiveTask(button.MouseButton1Click:Connect(function()
				if self._Multiple then
					local selectedValues = if type(self._Value) == "table" then self._Value else {}
					local index = table.find(selectedValues, option)
					if index then
						table.remove(selectedValues, index)
					else
						table.insert(selectedValues, option)
					end
					self._Value = selectedValues
					self:_updateSelectedLabel()
					self:_buildOptions()
					library:_setFlag(data.Flag, selectedValues, data.Save)
					self._Changed:Fire(selectedValues)
					if data.Callback then
						task.spawn(data.Callback, selectedValues)
					end
				else
					self:_commit(option)
					self:SetOpen(false)
				end
			end))
		end
	end

	function self:SetOpen(open: boolean)
		self._Open = open
		list.Visible = open
		arrow.Text = if open then "▲" else "▼"
	end

	function self:_commit(value: string, fireCallback: boolean?)
		if table.find(self._Options, value) == nil then
			return
		end

		self._Value = value
		self:_updateSelectedLabel()
		library:_setFlag(data.Flag, value, data.Save)
		self._Changed:Fire(value)
		self:_buildOptions()

		if fireCallback ~= false and data.Callback then
			task.spawn(data.Callback, value)
		end
	end

	self._Maid:Give(self._Changed)
	self._Maid:GiveTask(header.MouseButton1Click:Connect(function()
		self:SetOpen(not self._Open)
	end))

	if data.Flag then
		library:_setFlag(data.Flag, self._Value, data.Save)
	end

	self:_updateSelectedLabel()
	self:_buildOptions()

	return self :: any
end

function Dropdown:RefreshTheme()
	local theme = self._Section.Tab.Window.Library.Theme
	self.Header.BackgroundColor3 = theme.Background
	self.Header.TextColor3 = theme.Text
	self.List.BackgroundColor3 = theme.Background
	self.SelectedLabel.TextColor3 = theme.Accent
	self.Arrow.TextColor3 = theme.TextMuted
	self:_buildOptions()
end

function Dropdown:Set(value: string | { string })
	if self._Multiple then
		if type(value) == "table" then
			self._Value = value
		else
			self._Value = { value }
		end
		self:_updateSelectedLabel()
		self:_buildOptions()
		return
	end

	self:_commit(value, false)
end

function Dropdown:Get(): string | { string }
	return self._Value
end

function Dropdown:OnChanged(callback: (value: string) -> ()): RBXScriptConnection
	return self._Changed.Event:Connect(callback)
end

function Dropdown:Destroy()
	self:SetOpen(false)
	self:_clearOptions()
	self._Maid:DoCleaning()
end

return Dropdown
