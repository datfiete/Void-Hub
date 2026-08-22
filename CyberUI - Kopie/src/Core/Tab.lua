--!strict

local Theme = require(script.Parent.Theme)
local Section = require(script.Parent.Section)
local Maid = require(script.Parent.Parent.Utils.Maid)
local Helpers = require(script.Parent.Parent.Utils.Helpers)

local Tab = {}
Tab.__index = Tab

export type TabHandle = {
	CreateSection: (self: TabHandle, name: string?) -> any,
	SetActive: (self: TabHandle, active: boolean) -> (),
	Show: (self: TabHandle) -> (),
	Destroy: (self: TabHandle) -> (),
}

function Tab.new(window: any, name: string): TabHandle
	local self = setmetatable({
		Window = window,
		_Name = name,
		_Maid = Maid.new(),
		_Sections = {} :: { any },
		_DefaultSection = nil :: any,
	}, Tab)

	local button = Helpers.CreateButton({
		Name = name,
		Size = UDim2.new(1, 0, 0, 42),
		Text = "",
		BackgroundColor3 = window.Library.Theme.Background,
		BackgroundTransparency = 0.18,
		Parent = window.TabList,
	})
	Helpers.Corner(button, Theme.CornerRadiusSmall)
	Helpers.Stroke(button, window.Library.Theme.Border, 0.8)

	local indicator = Instance.new("Frame")
	indicator.Name = "ActiveIndicator"
	indicator.Size = UDim2.new(0, 3, 1, -12)
	indicator.Position = UDim2.new(0, 0, 0.5, 0)
	indicator.AnchorPoint = Vector2.new(0, 0.5)
	indicator.BackgroundColor3 = window.Library.Theme.Accent
	indicator.BackgroundTransparency = 1
	indicator.BorderSizePixel = 0
	indicator.Parent = button
	Helpers.Corner(indicator, 2)

	local icon = Instance.new("TextLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.fromOffset(26, 26)
	icon.Position = UDim2.new(0, 8, 0.5, 0)
	icon.AnchorPoint = Vector2.new(0, 0.5)
	icon.BackgroundColor3 = window.Library.Theme.Secondary
	icon.BackgroundTransparency = 0.15
	icon.Text = string.upper(string.sub(name, 1, 1))
	icon.Font = Theme.FontBold
	icon.TextSize = 11
	icon.TextColor3 = window.Library.Theme.TextMuted
	icon.Parent = button
	Helpers.Corner(icon, 8)

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.new(1, -48, 1, 0)
	label.Position = UDim2.new(0, 42, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = name
	label.Font = Theme.FontBold
	label.TextSize = 12
	label.TextColor3 = window.Library.Theme.TextMuted
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.Parent = button

	local hoverGlow = Instance.new("Frame")
	hoverGlow.Name = "HoverGlow"
	hoverGlow.Size = UDim2.new(0, 2, 1, -14)
	hoverGlow.Position = UDim2.new(1, -2, 0.5, 0)
	hoverGlow.AnchorPoint = Vector2.new(1, 0.5)
	hoverGlow.BackgroundColor3 = window.Library.Theme.AccentAlt
	hoverGlow.BackgroundTransparency = 1
	hoverGlow.BorderSizePixel = 0
	hoverGlow.Parent = button
	Helpers.Corner(hoverGlow, 2)

	button.MouseEnter:Connect(function()
		if window._ActiveTab ~= self then
			button.BackgroundColor3 = window.Library.Theme.SurfaceHover or window.Library.Theme.Secondary
			label.TextColor3 = window.Library.Theme.Text
			icon.BackgroundColor3 = window.Library.Theme.SurfaceHover or window.Library.Theme.Secondary
			icon.TextColor3 = window.Library.Theme.AccentAlt or window.Library.Theme.Accent
		end
	end)
	button.MouseLeave:Connect(function()
		if window._ActiveTab ~= self then
			button.BackgroundColor3 = window.Library.Theme.Background
			label.TextColor3 = window.Library.Theme.TextMuted
			icon.BackgroundColor3 = window.Library.Theme.Secondary
			icon.TextColor3 = window.Library.Theme.TextMuted
		end
	end)

	local page = Instance.new("ScrollingFrame")
	page.Name = name
	page.Visible = false
	page.Size = UDim2.fromScale(1, 1)
	page.Position = UDim2.fromOffset(0, 0)
	page.BackgroundTransparency = 1
	page.BorderSizePixel = 0
	page.ScrollBarThickness = 4
	page.ScrollBarImageColor3 = window.Library.Theme.Accent
	page.CanvasSize = UDim2.new()
	page.AutomaticCanvasSize = Enum.AutomaticSize.Y
	page.ClipsDescendants = true
	page.Parent = window.Pages

	local pagePadding = Helpers.Padding(page, Theme.Padding)
	local pageLayout = Helpers.ListLayout(page, Theme.Gap)

	self._Maid:GiveTask(pageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		page.CanvasSize = UDim2.new(0, 0, 0, pageLayout.AbsoluteContentSize.Y + pagePadding.PaddingTop.Offset + pagePadding.PaddingBottom.Offset)
	end))

	self.Button = button
	self.Page = page
	self._Maid:Give(button)
	self._Maid:Give(page)

	self._Maid:GiveTask(button.MouseButton1Click:Connect(function()
		window:_selectTab(self)
	end))

	self._ThemeConnection = window.Library.Theme.Changed:Connect(function()
		self:SetActive(self == window._ActiveTab)
		page.ScrollBarImageColor3 = window.Library.Theme.Accent
	end)

	self._Maid:GiveTask(self._ThemeConnection)

	return self :: any
end

function Tab:SetActive(active: boolean)
	local theme = self.Window.Library.Theme
	self.Button.BackgroundColor3 = if active then (theme.Surface or theme.Secondary) else theme.Background
	self.Button.BackgroundTransparency = if active then 0.02 else 0.18
	self.Button.BorderSizePixel = 0
	local indicator = self.Button:FindFirstChild("ActiveIndicator")
	local hoverGlow = self.Button:FindFirstChild("HoverGlow")
	local icon = self.Button:FindFirstChild("Icon")
	local label = self.Button:FindFirstChild("Label")
	if indicator and indicator:IsA("Frame") then
		indicator.BackgroundColor3 = theme.Accent
		indicator.BackgroundTransparency = if active then 0 else 1
	end
	if hoverGlow and hoverGlow:IsA("Frame") then
		hoverGlow.BackgroundColor3 = theme.AccentAlt or theme.Accent
		hoverGlow.BackgroundTransparency = if active then 0.45 else 1
	end
	if icon and icon:IsA("TextLabel") then
		icon.BackgroundColor3 = if active then theme.Accent else theme.Secondary
		icon.BackgroundTransparency = if active then 0.82 else 0.15
		icon.TextColor3 = if active then theme.Accent else theme.TextMuted
	end
	if label and label:IsA("TextLabel") then
		label.TextColor3 = if active then theme.Text else theme.TextMuted
	end
end

function Tab:RefreshTheme()
	self:SetActive(self == self.Window._ActiveTab)
	self.Page.ScrollBarImageColor3 = self.Window.Library.Theme.Accent
	for _, section in self._Sections do
		if section.RefreshTheme then
			section:RefreshTheme()
		end
	end
end

function Tab:Show()
	self.Page.Visible = true
	for _, sibling in self.Window.Pages:GetChildren() do
		if sibling:IsA("ScrollingFrame") and sibling ~= self.Page then
			sibling.Visible = false
		end
	end
end

function Tab:CreateSection(nameOrData: any)
	local name = nil
	if type(nameOrData) == "string" then
		name = nameOrData
	elseif type(nameOrData) == "table" then
		name = nameOrData.Name or nameOrData.Title or nil
	end

	local section = Section.new(self, name)
	table.insert(self._Sections, section)
	return section
end

function Tab:_getDefaultSection(): any
	if not self._DefaultSection then
		self._DefaultSection = self:CreateSection("Default")
	end
	return self._DefaultSection
end

function Tab:CreateDropdown(data: any)
	return self:_getDefaultSection():CreateDropdown(data)
end

function Tab:CreateToggle(data: any)
	return self:_getDefaultSection():CreateToggle(data)
end

function Tab:CreateButton(data: any)
	return self:_getDefaultSection():CreateButton(data)
end

function Tab:CreateSlider(data: any)
	return self:_getDefaultSection():CreateSlider(data)
end

function Tab:CreateInput(data: any)
	return self:_getDefaultSection():CreateInput(data)
end

function Tab:CreateKeybind(data: any)
	return self:_getDefaultSection():CreateKeybind(data)
end

function Tab:CreateColorPicker(data: any)
	return self:_getDefaultSection():CreateColorPicker(data)
end

function Tab:CreateParagraph(data: any)
	return self:_getDefaultSection():CreateParagraph(data)
end

function Tab:Destroy()
	for _, section in self._Sections do
		section:Destroy()
	end
	table.clear(self._Sections)
	self._Maid:DoCleaning()
end

return Tab
