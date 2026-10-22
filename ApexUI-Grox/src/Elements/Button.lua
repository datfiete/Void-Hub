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
	local rowStroke = Helpers.Stroke(row, library.Theme.Border, 1.2)
	local rowGlow = Helpers.Stroke(row, library.Theme.Accent, 2.5)
	rowGlow.Transparency = 0.92
	rowStroke.Transparency = 0.22
	local btnGrad = Instance.new("UIGradient")
	btnGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 200, 255)),
	})
	btnGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.92),
		NumberSequenceKeypoint.new(1, 0.97),
	})
	btnGrad.Rotation = 90
	btnGrad.Parent = row

	local pop = Instance.new("UIScale")
	pop.Scale = 0.94
	pop.Parent = row
	task.defer(function()
		Tween.Play(pop, { Scale = 1 }, { Time = 0.2, EasingStyle = Enum.EasingStyle.Back })
	end)

	self.RowGlow = rowGlow
	self.Instance = row

	self._Maid:GiveTask(row.MouseEnter:Connect(function()
		Tween.Play(row, { BackgroundColor3 = library.Theme.ElementHover or library.Theme.Secondary }, { Time = 0.15 })
		Tween.Play(rowGlow, { Transparency = 0.55 }, { Time = 0.18 })
		Tween.Play(rowStroke, { Color = library.Theme.Accent, Transparency = 0.4 }, { Time = 0.18 })
	end))

	self._Maid:GiveTask(row.MouseLeave:Connect(function()
		Tween.Play(row, { BackgroundColor3 = library.Theme.ElementBackground or library.Theme.Background }, { Time = 0.18 })
		Tween.Play(rowGlow, { Transparency = 0.92 }, { Time = 0.2 })
		Tween.Play(rowStroke, { Color = library.Theme.Border, Transparency = 0.22 }, { Time = 0.2 })
	end))

	self._Maid:GiveTask(row.MouseButton1Click:Connect(function()
		local s = row:FindFirstChildOfClass("UIScale")
		if s then
			Tween.Play(s, { Scale = 0.95 }, { Time = 0.05 })
			task.delay(0.05, function()
				if s and s.Parent then
					Tween.Play(s, { Scale = 1 }, { Time = 0.14, EasingStyle = Enum.EasingStyle.Back })
				end
			end)
		end
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
	for _, child in self.Instance:GetChildren() do
		if child:IsA("UIStroke") then
			-- border stroke is tighter transparency; accent glow is ~0.95
			if child.Transparency > 0.5 then
				child.Color = theme.Accent
			else
				child.Color = theme.Border
			end
		end
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
