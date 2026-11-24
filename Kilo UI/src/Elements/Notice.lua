--!strict
local Theme = require(script.Parent.Parent.Core.Theme)
local Maid = require(script.Parent.Parent.Utils.Maid)
local Helpers = require(script.Parent.Parent.Utils.Helpers)
local Tween = require(script.Parent.Parent.Utils.Tween)
local Notice = {}
Notice.__index = Notice
function Notice.new(section: any, data: any?): any
	data = data or {}
	local self = setmetatable({ _Section = section, _Data = data, _Maid = Maid.new() }, Notice)
	local theme = section.Tab.Window.Library.Theme
	local root = Helpers.CreateFrame({
		Name = data.Name or "Notice",
		Size = UDim2.new(1, 0, 0, data.Height or 56),
		BackgroundColor3 = data.BackgroundColor or theme.ElementBackground,
		BackgroundTransparency = 0.03,
		Parent = section.Inner,
	})
	Helpers.Corner(root, Theme.CornerRadiusSmall)
	local stroke = Helpers.Stroke(root, theme.Border, 1)
	stroke.Transparency = 0.18
	local accent = Helpers.CreateFrame({
		Name = "Accent",
		Size = UDim2.new(0, 3, 1, 0),
		BackgroundColor3 = data.Color or theme.Accent,
		Parent = root,
	})
	Helpers.Corner(accent, 1)
	local icon = Instance.new("ImageLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.fromOffset(20, 20)
	icon.Position = UDim2.fromOffset(14, 18)
	icon.BackgroundTransparency = 1
	icon.Image = data.Icon or ""
	icon.ImageColor3 = data.Color or theme.Accent
	icon.Parent = root
	local label = Helpers.CreateLabel({
		Name = "Label",
		Size = UDim2.new(1, -44, 0, 20),
		Position = UDim2.fromOffset(44, 8),
		Text = tostring(data.Text or data.Title or "Notice"),
		Font = Theme.FontBold,
		TextSize = 11,
		TextColor3 = theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = root,
	})
	local sub = Helpers.CreateLabel({
		Name = "Sub",
		Size = UDim2.new(1, -44, 0, 18),
		Position = UDim2.fromOffset(44, 30),
		Text = tostring(data.Sub or ""),
		Font = Theme.Font,
		TextSize = 9,
		TextColor3 = theme.TextMuted,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = root,
	})
	self.Instance = root
	self.Label = label
	self.Sub = sub
	self.Accent = accent
	self.Icon = icon
	self._Stroke = stroke
	if data.Callback then
		self._Maid:GiveTask(root.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				task.spawn(data.Callback, self)
			end
		end))
	end
	return self
end
function Notice:Set(text: string, sub: string?)
	self.Label.Text = tostring(text)
	if sub ~= nil then
		self.Sub.Text = tostring(sub)
	end
end
function Notice:SetColor(color: Color3)
	self.Accent.BackgroundColor3 = color
	self.Icon.ImageColor3 = color
end
function Notice:RefreshTheme()
	local theme = self._Section.Tab.Window.Library.Theme
	self.Instance.BackgroundColor3 = self._Data.BackgroundColor or theme.ElementBackground
	self._Stroke.Color = theme.Border
	self.Label.TextColor3 = theme.Text
	self.Sub.TextColor3 = theme.TextMuted
	if not self._Data.Color then
		self.Accent.BackgroundColor3 = theme.Accent
		self.Icon.ImageColor3 = theme.Accent
	end
end
function Notice:Destroy()
	self._Maid:DoCleaning()
	if self.Instance and self.Instance.Parent then
		self.Instance:Destroy()
	end
end
return Notice
