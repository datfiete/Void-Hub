--!strict

local Theme = require(script.Parent.Parent.Core.Theme)
local Maid = require(script.Parent.Parent.Utils.Maid)
local Helpers = require(script.Parent.Parent.Utils.Helpers)
local Tween = require(script.Parent.Parent.Utils.Tween)

local Button = {}
Button.__index = Button

export type ButtonOptions = {
	Name: string,
	Callback: (() -> ())?,
}

export type ButtonHandle = {
	Set: (self: ButtonHandle, text: string) -> (),
	Get: (self: ButtonHandle) -> string,
	Destroy: (self: ButtonHandle) -> (),
}

function Button.new(section: any, data: ButtonOptions): ButtonHandle
	local self = setmetatable({
		_Section = section,
		_Data = data,
		_Maid = Maid.new(),
	}, Button)

	local library = section.Tab.Window.Library

	local row = Helpers.CreateButton({
		Name = "Button",
		Size = UDim2.new(1, 0, 0, Theme.ElementHeight),
		Text = data.Name,
		TextXAlignment = Enum.TextXAlignment.Center,
		BackgroundColor3 = library.Theme.ElementBackground or library.Theme.Background,
		Parent = section.Inner,
	})
	Helpers.Corner(row, Theme.CornerRadiusSmall)
	local rowStroke = Helpers.Stroke(row, library.Theme.Border, 1)
	local rowGlow = Helpers.Stroke(row, library.Theme.Accent, 1)
	rowGlow.Transparency = 1
	rowStroke.Transparency = 0.18

	self.RowGlow = rowGlow

	self.Instance = row

	self._Maid:GiveTask(row.MouseEnter:Connect(function()
		Tween.Play(row, {
			BackgroundColor3 = library.Theme.ElementHover or library.Theme.Secondary,
		}, { Time = 0.12 })
		Tween.Play(rowGlow, { Transparency = 0.72 }, { Time = 0.12 })
	end))

	self._Maid:GiveTask(row.MouseLeave:Connect(function()
		Tween.Play(row, {
			BackgroundColor3 = library.Theme.ElementBackground or library.Theme.Background,
		}, { Time = 0.14 })
		Tween.Play(rowGlow, { Transparency = 1 }, { Time = 0.14 })
	end))

	self._Maid:GiveTask(row.MouseButton1Down:Connect(function()
		Tween.Play(row, { BackgroundColor3 = library.Theme.SurfaceHover or library.Theme.Secondary }, { Time = 0.07 })
	end))

	self._Maid:GiveTask(row.MouseButton1Up:Connect(function()
		Tween.Play(row, { BackgroundColor3 = library.Theme.ElementHover or library.Theme.Secondary }, { Time = 0.09 })
	end))

	self._Maid:GiveTask(row.MouseButton1Click:Connect(function()
		if data.Callback then
			task.spawn(data.Callback)
		end
	end))

	return self :: any
end

function Button:RefreshTheme()
	local theme = self._Section.Tab.Window.Library.Theme
	self.Instance.BackgroundColor3 = theme.ElementBackground or theme.Background
	self.Instance.TextColor3 = theme.Text
	local stroke = self.Instance:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Color = theme.Border
	end
	if self.RowGlow then
		self.RowGlow.Color = theme.Accent
	end
end

function Button:Set(text: string)
	self.Instance.Text = text
end

function Button:Get(): string
	return self.Instance.Text
end

function Button:Destroy()
	self._Maid:DoCleaning()
end

return Button
