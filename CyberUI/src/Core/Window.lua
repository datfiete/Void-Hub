--!strict

local Theme = require(script.Parent.Theme)
local Tab = require(script.Parent.Tab)
local Maid = require(script.Parent.Parent.Utils.Maid)
local Helpers = require(script.Parent.Parent.Utils.Helpers)
local Tween = require(script.Parent.Parent.Utils.Tween)
local GUI_Name = "Void Hub"

-- Constants
local PADDING = {
	Logo = 14,
	TitleLeft = 16,
	ControlSpacing = 12,
	Sidebar = 8,
	SearchTop = 40,
}

local SIZES = {
	MinWindow = Vector2.new(420, 320),
	MaxWindow = Vector2.new(1200, 900),
	FloatingButton = 50,
	Logo = 36,
}

local ASSETS = {
	Backgrounds = {
		["Solo Leveling"] = "rbxassetid://139001765478120",
		["Gojo"] = "rbxassetid://111578938106815",
		["Sukuna"] = "rbxassetid://106318186489675",
		["Cid Kagenou"] = "rbxassetid://113248988511733",
	}
}

local Window = {}
Window.__index = Window

export type WindowOptions = {
	Title: string?,
	Subtitle: string?,
	Size: Vector2?,
	Center: boolean?,
	BackgroundImage: string?,
	Logo: string?,
	Badges: { { Text: string, Color: Color3? } }?,
	Footer: { Avatar: string?, Username: string? }?,
	ShowSearch: boolean?,
	ShowWindowControls: boolean?,
	ToggleKey: Enum.KeyCode?,
}

export type WindowHandle = {
	CreateTab: (self: WindowHandle, name: string) -> any,
	Notify: (self: WindowHandle, options: any) -> any,
	Destroy: (self: WindowHandle) -> (),
}

function Window.new(library: any, options: WindowOptions?): WindowHandle
	local data = (typeof(options) == "table") and options or {}
	local self = setmetatable({
		Library = library,
		_Maid = Maid.new(),
		_Tabs = {} :: { any },
		_ActiveTab = nil :: any,
	}, Window)

	local Players = game:GetService("Players")
	local UserInputService = game:GetService("UserInputService")
	
	local player = Players.LocalPlayer
	if not player then return self :: any end
	
	local playerGui = player:WaitForChild("PlayerGui", 5)
	if not playerGui then return self :: any end

	local sharedState = _G

	-- Cleanup existing UI
	for _, child in playerGui:GetChildren() do
		if child:IsA("ScreenGui") and child.Name == "CyberUI" then
			child:Destroy()
		end
	end

	-- Get window dimensions
	local windowName = data.Name or data.Title or "CyberUI"
	local windowSubtitle = data.Subtitle or data.Description
	local windowSize = self:_getWindowSize(data.Size or data.WindowSize)

	local showSearch = data.ShowSearch ~= false
	local showWindowControls = data.ShowWindowControls ~= false
	local topBarHeight = Theme.TopBarHeight or 54

	-- Build screen gui
	local screenGui = self:_buildScreenGui(playerGui)
	self.Gui = screenGui

	-- Build loading frame (store references separately)
	local loadingFrame, loadingElements = self:_buildLoadingFrame(screenGui, library, windowName, windowSubtitle)
	self._Maid:Give(screenGui)
	self._Maid:Give(loadingFrame)

	-- Build main frame
	local main = self:_buildMainFrame(screenGui, library, windowSize, data, topBarHeight)
	self.Main = main
	self._BackgroundImage = main:FindFirstChild("BackgroundImage")

	-- Build top bar
	local topBar = self:_buildTopBar(main, library, windowName, windowSubtitle, data, topBarHeight, showWindowControls)
	self.TopBar = topBar

	-- Build sidebar
	local sidebar, searchBox, tabList = self:_buildSidebar(main, library, showSearch, topBarHeight)
	self.Sidebar = sidebar
	self.SearchBox = searchBox
	self.TabList = tabList

	-- Build pages
	local pages = self:_buildPages(main, sidebar, topBarHeight)
	self.Pages = pages

	-- Build floating button
	local floatingButton = self:_buildFloatingButton(screenGui, library, windowName, data)
	self._FloatingButton = floatingButton
	self._FloatingStroke = floatingButton:FindFirstChild("Stroke")

	-- Setup window controls
	self:_setupWindowControls(main, topBar, windowSize, topBarHeight)

	-- Setup drag functionality
	self:_setupDragging(main, topBar, UserInputService)

	-- Setup resize functionality
	self:_setupResizing(main, UserInputService, SIZES.MinWindow, SIZES.MaxWindow)

	-- Setup theme
	self:_setupTheme(library, main, topBar, sidebar)

	-- Setup search
	if searchBox then
		self:_setupSearch(searchBox, tabList, library)
	end

	-- Setup keybind
	self:_setupKeybind(UserInputService)

	-- Initialize state
	self._Visible = true
	self._Minimized = false
	self._StartupComplete = false
	self._ToggleKeybind = data.ToggleKey or Enum.KeyCode.RightControl
	self._OptionsTab = nil
	self.RefreshTheme = function() self:_refreshTheme(library, main, topBar, sidebar) end

	-- Startup sequence with proper loading elements
	self:_startupSequence(loadingFrame, loadingElements)

	return self :: any
end

-- Helper: Build ScreenGui
function Window:_buildScreenGui(parent)
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "CyberUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = parent
	return screenGui
end

-- Helper: Get Window Size
function Window:_getWindowSize(size)
	if typeof(size) == "UDim2" then
		return Vector2.new(size.X.Offset, size.Y.Offset)
	elseif typeof(size) == "number" then
		return Vector2.new(size, size)
	elseif typeof(size) == "Vector2" then
		return size
	end
	return Vector2.new(800, 560)
end

-- Helper: Build Loading Frame (returns frame and elements table)
function Window:_buildLoadingFrame(parent, library, title, subtitle)
	local loadingFrame = Helpers.CreateFrame({
		Name = "Loading",
		Size = UDim2.fromOffset(380, 168),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = library.Theme.Secondary,
		Parent = parent,
	})
	Helpers.Corner(loadingFrame, Theme.CornerRadius)
	Helpers.Stroke(loadingFrame, library.Theme.Border, 1)
	Helpers.Padding(loadingFrame, 18)

	local loadingAccent = Helpers.CreateFrame({
		Name = "Accent",
		Size = UDim2.new(0, 4, 1, -36),
		Position = UDim2.new(0, 18, 0, 18),
		BackgroundColor3 = library.Theme.Accent,
		Parent = loadingFrame,
	})
	Helpers.Corner(loadingAccent, 2)

	local loadingTitle = Helpers.CreateLabel({
		Name = "LoadingTitle",
		Size = UDim2.new(1, -34, 0, 30),
		Position = UDim2.fromOffset(18, 0),
		Text = title,
		Font = Theme.FontBold,
		TextColor3 = library.Theme.Text,
		TextSize = 20,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = loadingFrame,
	})

	local loadingSubtitle = Helpers.CreateLabel({
		Name = "LoadingSubtitle",
		Size = UDim2.new(1, -34, 0, 22),
		Position = UDim2.fromOffset(18, 34),
		Text = subtitle or "Preparing interface",
		TextColor3 = library.Theme.TextMuted,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = loadingFrame,
	})

	local loadingStatus = Helpers.CreateLabel({
		Name = "LoadingStatus",
		Size = UDim2.new(1, -34, 0, 20),
		Position = UDim2.fromOffset(18, 78),
		Text = "Loading components...",
		TextColor3 = library.Theme.TextMuted,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = loadingFrame,
	})

	local progressTrack = Helpers.CreateFrame({
		Name = "ProgressTrack",
		Size = UDim2.new(1, -34, 0, 6),
		Position = UDim2.fromOffset(18, 112),
		BackgroundColor3 = library.Theme.Background,
		Parent = loadingFrame,
	})
	Helpers.Corner(progressTrack, 3)

	local progressFill = Helpers.CreateFrame({
		Name = "ProgressFill",
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = library.Theme.Accent,
		Parent = progressTrack,
	})
	Helpers.Corner(progressFill, 3)
	Tween.Play(progressFill, { Size = UDim2.fromScale(1, 1) }, { Time = 0.85 })

	-- Return frame and all elements for later cleanup
	local elements = {
		Accent = loadingAccent,
		Title = loadingTitle,
		Subtitle = loadingSubtitle,
		Status = loadingStatus,
		ProgressTrack = progressTrack,
		ProgressFill = progressFill,
	}

	return loadingFrame, elements
end

-- Helper: Build Main Frame
function Window:_buildMainFrame(parent, library, windowSize, data, topBarHeight)
	local main = Helpers.CreateFrame({
		Name = "Main",
		Size = UDim2.fromOffset(windowSize.X, windowSize.Y),
		Position = if data.Center ~= false then UDim2.fromScale(0.5, 0.5) else UDim2.fromOffset(40, 40),
		AnchorPoint = if data.Center ~= false then Vector2.new(0.5, 0.5) else Vector2.new(0, 0),
		BackgroundColor3 = library.Theme.Background,
		BackgroundTransparency = 0.2,
		Visible = false,
		Parent = parent,
	})
	Helpers.Corner(main, Theme.CornerRadius)
	main.ClipsDescendants = true
	local mainStroke = Helpers.Stroke(main, library.Theme.Border, 1)
	main._Stroke = mainStroke

	-- Background image
	local backgroundImage = Instance.new("ImageLabel")
	backgroundImage.AnchorPoint = Vector2.new(0, 0)
	backgroundImage.Position = UDim2.new(0, 0, 0, 0)
	backgroundImage.Name = "BackgroundImage"
	backgroundImage.Size = UDim2.fromScale(1, 1)
	backgroundImage.BackgroundTransparency = 1
	backgroundImage.Image = data.BackgroundImage or ""
	backgroundImage.ImageTransparency = 0.3
	backgroundImage.ScaleType = Enum.ScaleType.Crop
	backgroundImage.ZIndex = 0
	backgroundImage.Parent = main
	Helpers.Corner(backgroundImage, Theme.CornerRadius)

	-- Overlay
	local overlay = Instance.new("Frame")
	overlay.Name = "BackgroundOverlay"
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = Color3.new(0, 0, 0)
	overlay.BackgroundTransparency = 0.75
	overlay.BorderSizePixel = 0
	overlay.ZIndex = 1
	overlay.Parent = main
	main.Active = true
	main.Selectable = true
	main.ClipsDescendants = true
	Helpers.Corner(overlay, Theme.CornerRadius)

	return main
end

-- Helper: Build Top Bar
function Window:_buildTopBar(main, library, title, subtitle, data, topBarHeight, showWindowControls)
	local topBar = Helpers.CreateFrame({
		Name = "TopBar",
		Size = UDim2.new(1, 0, 0, topBarHeight),
		Position = UDim2.new(0, 0, 0, 0),
		BackgroundColor3 = library.Theme.Secondary,
		BackgroundTransparency = 0.2,
		Active = true,
		Selectable = true,
		Parent = main,
	})
	topBar.ZIndex = 20
	Helpers.Corner(topBar, Theme.CornerRadius)

	local topBarMask = Helpers.CreateFrame({
		Name = "TopBarMask",
		Size = UDim2.new(1, 0, 0, Theme.CornerRadius),
		Position = UDim2.new(0, 0, 1, -Theme.CornerRadius),
		BackgroundColor3 = library.Theme.Secondary,
		Parent = topBar,
	})
	topBarMask.ZIndex = 19

	-- Logo
	local logoImage = nil
	if data.Logo and data.Logo ~= "" then
		logoImage = Instance.new("ImageLabel")
		logoImage.Name = "Logo"
		logoImage.BackgroundTransparency = 1
		logoImage.Size = UDim2.fromOffset(SIZES.Logo, SIZES.Logo)
		logoImage.Position = UDim2.new(0, PADDING.Logo, 0.5, 0)
		logoImage.AnchorPoint = Vector2.new(0, 0.5)
		logoImage.Image = data.Logo
		logoImage.ScaleType = Enum.ScaleType.Fit
		logoImage.ZIndex = 30
		logoImage.Parent = topBar
		Helpers.Corner(logoImage, 8)
	end

	local titleStartX = if logoImage then PADDING.Logo + SIZES.Logo + 10 else PADDING.TitleLeft

	local titleLabel = Helpers.CreateLabel({
		Name = "Title",
		Size = UDim2.new(0, 220, 0, 22),
		Position = UDim2.new(0, titleStartX, 0, 10),
		Text = title,
		Font = Theme.FontBold,
		TextSize = 17,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = library.Theme.Text,
		Parent = topBar,
	})
	titleLabel.ZIndex = 21

	local subtitleLabel = nil
	if subtitle then
		subtitleLabel = Helpers.CreateLabel({
			Name = "Subtitle",
			Size = UDim2.new(0, 220, 0, 16),
			Position = UDim2.new(0, titleStartX, 0, 30),
			Text = subtitle,
			TextColor3 = library.Theme.TextMuted,
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = topBar,
		})
		subtitleLabel.ZIndex = 21
	end

	-- Badges
	local badgeHolder = self:_buildBadges(topBar, library, data)

	-- Window controls
	local minimizeButton, closeButton = nil, nil
	if showWindowControls then
		minimizeButton, closeButton = self:_buildWindowControls(topBar, library)
	end

	topBar._Title = titleLabel
	topBar._Subtitle = subtitleLabel
	topBar._BadgeHolder = badgeHolder
	topBar._MinimizeButton = minimizeButton
	topBar._CloseButton = closeButton

	return topBar
end

-- Helper: Build Badges
function Window:_buildBadges(topBar, library, data)
	local badgeHolder = Helpers.CreateFrame({
		Name = "Badges",
		Size = UDim2.new(0, 260, 0, 26),
		Position = UDim2.new(0, 180, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundTransparency = 1,
		Parent = topBar,
	})
	badgeHolder.ZIndex = 21
	Helpers.ListLayout(badgeHolder, 6)
	local badgeList = badgeHolder:FindFirstChildOfClass("UIListLayout")
	if badgeList then
		badgeList.FillDirection = Enum.FillDirection.Horizontal
		badgeList.VerticalAlignment = Enum.VerticalAlignment.Center
		badgeList.SortOrder = Enum.SortOrder.LayoutOrder
	end

	if data.Badges then
		local altColors = { library.Theme.Accent, Theme.AccentAlt or library.Theme.Accent }
		for i, badge in data.Badges do
			local color = badge.Color or altColors[((i - 1) % #altColors) + 1]
			local pill = Helpers.CreateFrame({
				Name = "Badge" .. i,
				Size = UDim2.new(0, 0, 1, 0),
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundColor3 = color,
				Parent = badgeHolder,
				LayoutOrder = i,
			})
			pill.ZIndex = 22
			Helpers.Corner(pill, 13)
			Helpers.Padding(pill, 10, 4)
			local pillLabel = Helpers.CreateLabel({
				Name = "Label",
				Size = UDim2.new(0, 0, 1, 0),
				AutomaticSize = Enum.AutomaticSize.X,
				Position = UDim2.new(0, 0, 0, 0),
				Text = badge.Text,
				Font = Theme.FontBold,
				TextSize = 12,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextXAlignment = Enum.TextXAlignment.Center,
				Parent = pill,
			})
		end
	end

	return badgeHolder
end

-- Helper: Build Window Controls
function Window:_buildWindowControls(topBar, library)
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "Close"
	closeButton.Size = UDim2.fromOffset(32, 32)
	closeButton.Position = UDim2.new(1, -12, 0.5, 0)
	closeButton.AnchorPoint = Vector2.new(1, 0.5)
	closeButton.BackgroundColor3 = library.Theme.Background
	closeButton.BackgroundTransparency = 0.25
	closeButton.Text = "✕"
	closeButton.Font = Theme.FontBold
	closeButton.TextSize = 15
	closeButton.TextColor3 = library.Theme.TextMuted
	closeButton.AutoButtonColor = false
	closeButton.ZIndex = 21
	closeButton.Parent = topBar
	Helpers.Corner(closeButton, 8)
	Helpers.Stroke(closeButton, library.Theme.Border, 1)

	local minimizeButton = Instance.new("TextButton")
	minimizeButton.Name = "Minimize"
	minimizeButton.Size = UDim2.fromOffset(28, 28)
	minimizeButton.Position = UDim2.new(1, -50, 0.5, 0)
	minimizeButton.AnchorPoint = Vector2.new(1, 0.5)
	minimizeButton.BackgroundTransparency = 1
	minimizeButton.Text = "—"
	minimizeButton.Font = Theme.FontBold
	minimizeButton.TextSize = 16
	minimizeButton.TextColor3 = library.Theme.TextMuted
	minimizeButton.AutoButtonColor = false
	minimizeButton.ZIndex = 21
	minimizeButton.Parent = topBar

	-- Hover animations (cached)
	local hoverTween = Tween.new(closeButton, { BackgroundTransparency = 0 }, { Time = 0.15 })
	local leaveTween = Tween.new(closeButton, { BackgroundTransparency = 0.25 }, { Time = 0.15 })
	
	closeButton.MouseEnter:Connect(function() hoverTween:Play() end)
	closeButton.MouseLeave:Connect(function() leaveTween:Play() end)

	return minimizeButton, closeButton
end

-- Helper: Build Sidebar
function Window:_buildSidebar(main, library, showSearch, topBarHeight)
	local contentArea = Helpers.CreateFrame({
		Name = "ContentArea",
		Size = UDim2.new(1, 0, 1, -topBarHeight),
		Position = UDim2.new(0, 0, 0, topBarHeight),
		BackgroundTransparency = 1,
		Parent = main,
	})

	local sidebar = Helpers.CreateFrame({
		Name = "Sidebar",
		Size = UDim2.new(0, Theme.SidebarWidth, 1, 0),
		BackgroundColor3 = library.Theme.Secondary,
		BackgroundTransparency = 0.3,
		Parent = contentArea,
	})
	Helpers.Corner(sidebar, Theme.CornerRadius)
	sidebar.ClipsDescendants = true
	Helpers.Padding(sidebar, Theme.Padding)

	local searchBox = nil
	local searchTop = 0
	if showSearch then
		local searchHolder = Helpers.CreateFrame({
			Name = "SearchHolder",
			Size = UDim2.new(1, 0, 0, 32),
			Position = UDim2.new(0, 0, 0, 0),
			BackgroundColor3 = library.Theme.Background,
			Parent = sidebar,
		})
		Helpers.Corner(searchHolder, Theme.CornerRadiusSmall)
		Helpers.Stroke(searchHolder, library.Theme.Border, 1)

		searchBox = Instance.new("TextBox")
		searchBox.Name = "SearchBox"
		searchBox.Size = UDim2.new(1, -20, 1, 0)
		searchBox.Position = UDim2.new(0, 10, 0, 0)
		searchBox.BackgroundTransparency = 1
		searchBox.PlaceholderText = "Search..."
		searchBox.Text = ""
		searchBox.Font = Theme.Font
		searchBox.TextSize = 13
		searchBox.TextColor3 = library.Theme.Text
		searchBox.PlaceholderColor3 = library.Theme.TextMuted
		searchBox.TextXAlignment = Enum.TextXAlignment.Left
		searchBox.ClearTextOnFocus = false
		searchBox.Parent = searchHolder

		searchTop = PADDING.SearchTop
	end

	local tabList = Helpers.CreateFrame({
		Name = "TabList",
		Size = UDim2.new(1, 0, 1, -(searchTop + 52)),
		Position = UDim2.new(0, 0, 0, searchTop),
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.None,
		Parent = sidebar,
	})
	Helpers.ListLayout(tabList, Theme.Gap)
	local layout = tabList:FindFirstChildOfClass("UIListLayout")
	if layout then
		layout.SortOrder = Enum.SortOrder.LayoutOrder
	end

	return sidebar, searchBox, tabList
end

-- Helper: Build Pages
function Window:_buildPages(main, sidebar, topBarHeight)
	local contentArea = main:FindFirstChild("ContentArea")
	if not contentArea then return nil end

	local pages = Instance.new("Frame")
	pages.Name = "Pages"
	pages.Position = UDim2.new(0, Theme.SidebarWidth + PADDING.Sidebar, 0, 0)
	pages.Size = UDim2.new(1, -(Theme.SidebarWidth + PADDING.Sidebar), 1, 0)
	pages.BackgroundTransparency = 1
	pages.BorderSizePixel = 0
	pages.ClipsDescendants = true
	pages.Parent = contentArea

	return pages
end

-- Helper: Build Floating Button
function Window:_buildFloatingButton(parent, library, title, data)
	local floatingButton = Instance.new("ImageButton")
	floatingButton.Name = "FloatingToggle"
	floatingButton.Size = UDim2.fromOffset(SIZES.FloatingButton, SIZES.FloatingButton)
	floatingButton.Position = UDim2.new(0.5, 0, 0, 20)
	floatingButton.BackgroundColor3 = library.Theme.Secondary
	floatingButton.BackgroundTransparency = 0.1
	floatingButton.Image = data.Logo or ""
	floatingButton.ScaleType = Enum.ScaleType.Fit
	floatingButton.ImageTransparency = 0
	floatingButton.Visible = false
	floatingButton.AutoButtonColor = false
	floatingButton.ZIndex = 50
	floatingButton.Active = true
	floatingButton.Selectable = true
	floatingButton.Parent = parent
	Helpers.Corner(floatingButton, 25)
	local floatingStroke = Helpers.Stroke(floatingButton, library.Theme.Accent, 1.5)

	if not data.Logo or data.Logo == "" then
		local fallbackLabel = Helpers.CreateLabel({
			Name = "FallbackIcon",
			Size = UDim2.fromScale(1, 1),
			Text = string.sub(title, 1, 1),
			Font = Theme.FontBold,
			TextSize = 20,
			TextColor3 = library.Theme.Text,
			TextXAlignment = Enum.TextXAlignment.Center,
			Parent = floatingButton,
		})
		fallbackLabel.ZIndex = 51
	end

	-- Hover animations (cached)
	local hoverTween = Tween.new(floatingButton, { BackgroundTransparency = 0 }, { Time = 0.15 })
	local leaveTween = Tween.new(floatingButton, { BackgroundTransparency = 0.1 }, { Time = 0.15 })
	
	floatingButton.MouseEnter:Connect(function() hoverTween:Play() end)
	floatingButton.MouseLeave:Connect(function() leaveTween:Play() end)

	floatingButton.MouseButton1Click:Connect(function()
		self:SetVisible(true)
	end)

	-- Floating button dragging
	self:_setupFloatingDragging(floatingButton)

	return floatingButton
end

-- Helper: Setup Floating Dragging
function Window:_setupFloatingDragging(button)
	local UserInputService = game:GetService("UserInputService")
	
	self._FloatDragging = false
	self._FloatDragStart = Vector2.new()
	self._FloatStart = UDim2.new()
	self._FloatDragInputType = nil :: Enum.UserInputType?

	self._Maid:GiveTask(button.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			self._FloatDragging = true
			self._FloatDragStart = input.Position
			self._FloatStart = button.Position
			self._FloatDragInputType = input.UserInputType
		end
	end))

	self._Maid:GiveTask(UserInputService.InputChanged:Connect(function(input)
		if not self._FloatDragging or self._FloatDragInputType == nil then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			local delta = input.Position - self._FloatDragStart
			button.Position = UDim2.new(
				self._FloatStart.X.Scale, self._FloatStart.X.Offset + delta.X,
				self._FloatStart.Y.Scale, self._FloatStart.Y.Offset + delta.Y
			)
		end
	end))

	self._Maid:GiveTask(UserInputService.InputEnded:Connect(function(input)
		if self._FloatDragInputType ~= nil and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			self._FloatDragging = false
			self._FloatDragInputType = nil
		end
	end))
end

-- Helper: Setup Window Controls (minimize/close)
function Window:_setupWindowControls(main, topBar, windowSize, topBarHeight)
	local minimizeButton = topBar:FindFirstChild("Minimize")
	local closeButton = topBar:FindFirstChild("Close")

	if minimizeButton then
		minimizeButton.MouseButton1Click:Connect(function()
			self._Minimized = not self._Minimized
			if self._Minimized then
				Tween.Play(main, { Size = UDim2.fromOffset(windowSize.X, topBarHeight) }, { Time = 0.18 })
				local contentArea = main:FindFirstChild("ContentArea")
				if contentArea then contentArea.Visible = false end
			else
				Tween.Play(main, { Size = UDim2.fromOffset(windowSize.X, windowSize.Y) }, { Time = 0.18 })
				local contentArea = main:FindFirstChild("ContentArea")
				if contentArea then 
					task.delay(0.18, function()
						if contentArea then contentArea.Visible = true end
					end)
				end
			end
		end)
	end

	if closeButton then
		closeButton.MouseButton1Click:Connect(function()
			self:SetVisible(false)
		end)
	end
end

-- Helper: Setup Dragging
function Window:_setupDragging(main, topBar, UserInputService)
	local dragging = false
	local dragStart = Vector2.new()
	local windowStart = UDim2.new()
	local dragInputType = nil :: Enum.UserInputType?

	local function startDragging(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			windowStart = main.Position
			dragInputType = input.UserInputType
		end
	end

	self._Maid:GiveTask(topBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			startDragging(input)
		end
	end))

	self._Maid:GiveTask(UserInputService.InputChanged:Connect(function(input)
		if not dragging or dragInputType == nil then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			local delta = input.Position - dragStart
			main.Position = UDim2.new(
				windowStart.X.Scale,
				windowStart.X.Offset + delta.X,
				windowStart.Y.Scale,
				windowStart.Y.Offset + delta.Y
			)
		end
	end))

	self._Maid:GiveTask(UserInputService.InputEnded:Connect(function(input)
		if dragInputType ~= nil and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			dragging = false
			dragInputType = nil
		end
	end))
end

-- Helper: Setup Resizing
function Window:_setupResizing(main, UserInputService, minSize, maxSize)
	local resizeHandle = self:_buildResizeHandle(main)
	if not resizeHandle then return end

	local resizing = false
	local resizeStart = Vector2.new()
	local sizeStart = UDim2.new()
	local resizeInputType = nil :: Enum.UserInputType?

	self._Maid:GiveTask(resizeHandle.InputBegan:Connect(function(input)
		if self._Minimized then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			resizing = true
			resizeStart = input.Position
			sizeStart = main.Size
			resizeInputType = input.UserInputType
		end
	end))

	self._Maid:GiveTask(UserInputService.InputChanged:Connect(function(input)
		if not resizing or resizeInputType == nil then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			local delta = input.Position - resizeStart
			local newX = math.clamp(sizeStart.X.Offset + delta.X, minSize.X, maxSize.X)
			local newY = math.clamp(sizeStart.Y.Offset + delta.Y, minSize.Y, maxSize.Y)
			main.Size = UDim2.fromOffset(newX, newY)
		end
	end))

	self._Maid:GiveTask(UserInputService.InputEnded:Connect(function(input)
		if resizeInputType ~= nil and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			resizing = false
			resizeInputType = nil
		end
	end))
end

-- Helper: Build Resize Handle
function Window:_buildResizeHandle(main)
	local resizeHandle = Instance.new("Frame")
	resizeHandle.Name = "ResizeHandle"
	resizeHandle.Size = UDim2.fromOffset(18, 18)
	resizeHandle.Position = UDim2.new(1, -4, 1, -4)
	resizeHandle.AnchorPoint = Vector2.new(1, 1)
	resizeHandle.BackgroundTransparency = 1
	resizeHandle.Active = true
	resizeHandle.Selectable = true
	resizeHandle.ZIndex = 25
	resizeHandle.Parent = main

	local lines = {}
	for i = 1, 3 do
		local line = Instance.new("Frame")
		line.Name = "Line" .. i
		line.Size = UDim2.fromOffset(2, 2 + i * 3)
		line.Position = UDim2.new(1, -4 - (i * 5), 1, -4)
		line.AnchorPoint = Vector2.new(1, 1)
		line.BackgroundColor3 = Color3.new(0.5, 0.5, 0.5)
		line.BorderSizePixel = 0
		line.Rotation = 45
		line.ZIndex = 26
		line.Parent = resizeHandle
		table.insert(lines, line)
	end

	-- Cached hover tweens
	local accentColor = Color3.fromRGB(0, 150, 255)
	resizeHandle.MouseEnter:Connect(function()
		for _, line in lines do
			Tween.Play(line, { BackgroundColor3 = accentColor }, { Time = 0.12 })
		end
	end)
	resizeHandle.MouseLeave:Connect(function()
		for _, line in lines do
			Tween.Play(line, { BackgroundColor3 = Color3.new(0.5, 0.5, 0.5) }, { Time = 0.12 })
		end
	end)

	self._ResizeHandle = resizeHandle
	return resizeHandle
end

-- Helper: Setup Theme
function Window:_setupTheme(library, main, topBar, sidebar)
	local function refreshTheme()
		main.BackgroundColor3 = library.Theme.Background
		topBar.BackgroundColor3 = library.Theme.Secondary
		local topBarMask = topBar:FindFirstChild("TopBarMask")
		if topBarMask then topBarMask.BackgroundColor3 = library.Theme.Secondary end
		sidebar.BackgroundColor3 = library.Theme.Secondary

		local title = topBar:FindFirstChild("Title")
		if title then title.TextColor3 = library.Theme.Text end
		local subtitle = topBar:FindFirstChild("Subtitle")
		if subtitle then subtitle.TextColor3 = library.Theme.TextMuted end

		local minimizeButton = topBar:FindFirstChild("Minimize")
		if minimizeButton then minimizeButton.TextColor3 = library.Theme.TextMuted end
		local closeButton = topBar:FindFirstChild("Close")
		if closeButton then 
			closeButton.TextColor3 = library.Theme.TextMuted
			local stroke = closeButton:FindFirstChild("Stroke")
			if stroke then stroke.Color = library.Theme.Border end
		end

		local mainStroke = main:FindFirstChild("Stroke")
		if mainStroke then mainStroke.Color = library.Theme.Border end

		for _, tab in self._Tabs do
			if tab.RefreshTheme then tab:RefreshTheme() end
		end
	end

	local themeConnection = library.Theme.Changed:Connect(function()
		refreshTheme()
	end)
	self._Maid:GiveTask(themeConnection)
end

-- Helper: Setup Search
function Window:_setupSearch(searchBox, tabList, library)
	local previouslyMatched = setmetatable({}, { __mode = "v" })

	self._Maid:GiveTask(searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		local query = searchBox.Text:lower()
		previouslyMatched = setmetatable({}, { __mode = "v" })

		for _, child in tabList:GetChildren() do
			if child:IsA("GuiObject") then
				local matches = query == "" or child.Name:lower():find(query, 1, true) ~= nil
				child.Visible = matches

				if matches and query ~= "" then
					local isActiveTab = self._ActiveTab and self._ActiveTab.Button == child
					local restColor = if isActiveTab then library.Theme.Secondary else library.Theme.Background

					Tween.Play(child, { BackgroundColor3 = library.Theme.Accent }, { Time = 0.12 })
					task.delay(0.12, function()
						if child and child.Parent then
							Tween.Play(child, { BackgroundColor3 = restColor }, { Time = 0.35 })
						end
					end)
				end

				previouslyMatched[child] = matches
			end
		end
	end))

	task.defer(function()
		if searchBox and searchBox.Parent then
			searchBox:CaptureFocus()
		end
	end)
end

-- Helper: Setup Keybind
function Window:_setupKeybind(UserInputService)
	self._Maid:GiveTask(UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if self._ToggleKeybind ~= nil and self._ToggleKeybind ~= Enum.KeyCode.Unknown and input.KeyCode == self._ToggleKeybind then
			self:Toggle()
		end
	end))
end

-- Helper: Startup Sequence (fixed - uses elements table)
function Window:_startupSequence(loadingFrame, loadingElements)
	self._Maid:Give(task.delay(0.8, function()
		if not self.Gui then return end

		if loadingFrame and loadingFrame.Parent then
			-- Update status text
			if loadingElements.Status then
				loadingElements.Status.Text = "Ready"
			end
			
			task.wait(0.25)
			
			-- Fade out all loading elements using the stored references
			local elementsToFade = {
				loadingFrame,
				loadingElements.Accent,
				loadingElements.Title,
				loadingElements.Subtitle,
				loadingElements.Status,
				loadingElements.ProgressTrack,
				loadingElements.ProgressFill,
			}
			
			for _, elem in elementsToFade do
				if elem and elem.Parent then
					local prop = elem:IsA("Frame") and "BackgroundTransparency" or "TextTransparency"
					local value = elem:IsA("Frame") and 1 or 1
					Tween.Play(elem, { [prop] = value }, { Time = 0.2 })
				end
			end
			
			task.wait(0.2)
			if loadingFrame and loadingFrame.Parent then
				loadingFrame:Destroy()
			end
		end

		self._StartupComplete = true
		self:SetVisible(self._Visible)
	end))
end

function Window:SetBackgroundImage(value: string)
	local bg = self._BackgroundImage
	if not bg then return end
	
	if value == "None" or value == "" then
		bg.Image = ""
		return
	end
	
	local assetId = ASSETS.Backgrounds[value]
	if assetId then
		bg.Image = assetId
	else
		if not value:match("^rbxassetid://") and not value:match("^http") then
			bg.Image = "rbxassetid://" .. value
		else
			bg.Image = value
		end
	end
end

function Window:SetBackgroundOverlayTransparency(value: number)
	local overlay = self.Main and self.Main:FindFirstChild("BackgroundOverlay")
	if overlay then
		overlay.BackgroundTransparency = value
	end
end

function Window:_selectTab(tab: any)
	if self._ActiveTab == tab then return end

	local previousTab = self._ActiveTab

	for _, existingTab in self._Tabs do
		existingTab:SetActive(existingTab == tab)
	end

	self._ActiveTab = tab

	local direction = 1
	if previousTab then
		local prevIndex, newIndex
		for i, t in self._Tabs do
			if t == previousTab then prevIndex = i end
			if t == tab then newIndex = i end
		end
		if prevIndex and newIndex and newIndex < prevIndex then
			direction = -1
		end
	end

	local newPage = tab.Page
	local oldPage = previousTab and previousTab.Page

	if oldPage and oldPage ~= newPage then
		oldPage.Visible = false
		oldPage.Position = UDim2.fromOffset(0, 0)
	end

	local slideDistance = self.Pages.AbsoluteSize.X * 0.25
	newPage.Visible = true
	newPage.Position = UDim2.fromOffset(slideDistance * direction, 0)
	Tween.Play(newPage, { Position = UDim2.fromOffset(0, 0) }, { Time = 0.2 })
end

function Window:CreateTab(name: string)
	local tab = Tab.new(self, name)
	table.insert(self._Tabs, tab)

	if not self._OptionsTab then
		self:_createOptionsTab()
	end

	if not self._ActiveTab then
		self:_selectTab(tab)
	end

	return tab
end

function Window:_createOptionsTab()
	if self._OptionsTab then
		return self._OptionsTab
	end

	local optionsTab = Tab.new(self, "Options")
	self._OptionsTab = optionsTab
	table.insert(self._Tabs, optionsTab)

	self.Library.Theme.Style = self.Library:_getSavedFlag("CyberUI.Theme.Style", self.Library.Theme.Style, true)
	self.Library.Theme.Background = self.Library:_getSavedFlag("CyberUI.Theme.Background", self.Library.Theme.Background, true)
	self.Library.Theme.Secondary = self.Library:_getSavedFlag("CyberUI.Theme.Secondary", self.Library.Theme.Secondary, true)
	self.Library.Theme.Accent = self.Library:_getSavedFlag("CyberUI.Theme.Accent", self.Library.Theme.Accent, true)
	self.Library.Theme.Text = self.Library:_getSavedFlag("CyberUI.Theme.Text", self.Library.Theme.Text, true)
	self.Library.Theme.Border = self.Library:_getSavedFlag("CyberUI.Theme.Border", self.Library.Theme.Border, true)

	local visualSection = optionsTab:CreateSection("Visual")
	visualSection:CreateParagraph({
		Title = "Visual",
		Content = "Choose the look and feel of the UI.",
	})

	local themeColorPickers = {}

	visualSection:CreateDropdown({
		Name = "Theme",
		Options = {"Dark", "Light", "Cyber", "Meng"},
		CurrentOption = self.Library.Theme.Style,
		Flag = "CyberUI.Theme.Style",
		Callback = function(value)
			self.Library.Theme.Style = value
		end,
	})

	themeColorPickers.Accent = visualSection:CreateColorPicker({
		Name = "Accent Color",
		CurrentValue = self.Library.Theme.Accent,
		Flag = "CyberUI.Theme.Accent",
		Callback = function(color)
			self.Library.Theme.Accent = color
		end,
	})
	themeColorPickers.Background = visualSection:CreateColorPicker({
		Name = "Background Color",
		CurrentValue = self.Library.Theme.Background,
		Flag = "CyberUI.Theme.Background",
		Callback = function(color)
			self.Library.Theme.Background = color
		end,
	})
	themeColorPickers.Secondary = visualSection:CreateColorPicker({
		Name = "Secondary Color",
		CurrentValue = self.Library.Theme.Secondary,
		Flag = "CyberUI.Theme.Secondary",
		Callback = function(color)
			self.Library.Theme.Secondary = color
		end,
	})
	themeColorPickers.Text = visualSection:CreateColorPicker({
		Name = "Text Color",
		CurrentValue = self.Library.Theme.Text,
		Flag = "CyberUI.Theme.Text",
		Callback = function(color)
			self.Library.Theme.Text = color
		end,
	})
	themeColorPickers.Border = visualSection:CreateColorPicker({
		Name = "Border Color",
		CurrentValue = self.Library.Theme.Border,
		Flag = "CyberUI.Theme.Border",
		Callback = function(color)
			self.Library.Theme.Border = color
		end,
	})

	self._Maid:GiveTask(self.Library.Theme.Changed:Connect(function(key)
		if key ~= "Style" then return end
		for propName, picker in themeColorPickers do
			if picker and picker.Set then
				picker:Set(self.Library.Theme[propName])
			end
		end
	end))

	visualSection:CreateInput({
		Name = "Custom Background",
		PlaceholderText = "rbxassetid://123456789 or 123456789",
		Callback = function(value)
			if value == "" then return end
			local bg = self._BackgroundImage
			if not bg then return end
			if not value:match("^rbxassetid://") and not value:match("^http") then
				value = "rbxassetid://" .. value
			end
			bg.Image = value
		end,
	})

	visualSection:CreateDropdown({
		Name = "Background Image",
		Options = {"Solo Leveling", "Gojo", "Sukuna", "Cid Kagenou", "None"},
		Callback = function(value: string)
			self:SetBackgroundImage(value)
		end,
	})

	visualSection:CreateSlider({
		Name = "Overlay Transparency",
		Min = 0,
		Max = 1,
		CurrentValue = 0.75,
		Rounding = 0.01,
		Callback = function(value: number)
			self:SetBackgroundOverlayTransparency(value)
		end,
		Flag = "CyberUI.Background.OverlayTransparency",
	})

	local configSection = optionsTab:CreateSection("Configuration")
	configSection:CreateParagraph({
		Title = "Configuration",
		Content = "Save and restore flagged UI values.",
	})
	configSection:CreateToggle({
		Name = "Configuration Saving",
		CurrentValue = self.Library._ConfigEnabled,
		Save = false,
		Callback = function(value)
			self.Library._ConfigEnabled = value
		end,
	})
	configSection:CreateToggle({
		Name = "Auto Save",
		CurrentValue = self.Library._AutoSave,
		Save = false,
		Callback = function(value)
			self.Library._AutoSave = value
		end,
	})
	configSection:CreateButton({
		Name = "Save Configuration",
		Callback = function()
			self.Library:SaveConfiguration()
		end,
	})
	configSection:CreateButton({
		Name = "Load Configuration",
		Callback = function()
			self.Library:LoadConfiguration()
		end,
	})

	local keybindSection = optionsTab:CreateSection("Keybind")
	keybindSection:CreateParagraph({
		Title = "Keybind",
		Content = "Use this key to toggle the UI.",
	})
	local toggleKeybind = keybindSection:CreateKeybind({
		Name = "Toggle UI",
		Default = self._ToggleKeybind,
		Flag = "CyberUI.ToggleKey",
		Callback = function(key)
			self._ToggleKeybind = key
		end,
	})
	self._Maid:GiveTask(toggleKeybind:OnChanged(function(key)
		self._ToggleKeybind = key
	end))

	local DiscordSection = optionsTab:CreateSection("Discord")
	DiscordSection:CreateButton({
		Name = "Copy Discord Invite",
		Callback = function()
			if setclipboard then
				setclipboard("https://discord.gg/D6AvbntAZf")
			end
			if self.Library and self.Library.Notifications and self.Library.Notifications.Notify then
				self.Library.Notifications:Notify({
					Title = "Success",
					Content = "Discord invite has been copied to your clipboard!",
					Type = "Success",
					Duration = 4,
				})
			else
				game:GetService("StarterGui"):SetCore("SendNotification", {
					Title = "Discord",
					Text = "Invite copied to clipboard!",
					Duration = 5,
					Icon = "rbxassetid://6031097228"
				})
			end
		end,
	})
	return optionsTab
end

function Window:CreateFolder(name: string)
	return self:CreateTab(name)
end

function Window:_getActiveTab(): any
	if self._ActiveTab then
		return self._ActiveTab
	end
	return self._Tabs[1]
end

function Window:CreateSection(nameOrData: any)
	local tab = self:_getActiveTab()
	if not tab then return nil end
	return tab:CreateSection(nameOrData)
end

function Window:CreateDropdown(data: any)
	local tab = self:_getActiveTab()
	if not tab then return nil end
	return tab:CreateDropdown(data)
end

function Window:CreateToggle(data: any)
	local tab = self:_getActiveTab()
	if not tab then return nil end
	return tab:CreateToggle(data)
end

function Window:CreateButton(data: any)
	local tab = self:_getActiveTab()
	if not tab then return nil end
	return tab:CreateButton(data)
end

function Window:CreateSlider(data: any)
	local tab = self:_getActiveTab()
	if not tab then return nil end
	return tab:CreateSlider(data)
end

function Window:CreateInput(data: any)
	local tab = self:_getActiveTab()
	if not tab then return nil end
	return tab:CreateInput(data)
end

function Window:CreateKeybind(data: any)
	local tab = self:_getActiveTab()
	if not tab then return nil end
	return tab:CreateKeybind(data)
end

function Window:CreateColorPicker(data: any)
	local tab = self:_getActiveTab()
	if not tab then return nil end
	return tab:CreateColorPicker(data)
end

function Window:CreateParagraph(data: any)
	local tab = self:_getActiveTab()
	if not tab then return nil end
	return tab:CreateParagraph(data)
end

function Window:SetVisible(visible: boolean)
	self._FloatDragging = false
	self._FloatDragInputType = nil
	self._Visible = visible
	if self.Gui then
		self.Gui.Enabled = true
	end

	if visible then
		if self.Main then
			self.Main.Visible = self._StartupComplete
		end

		if self._FloatingButton and self._FloatingButton.Visible then
			local btn = self._FloatingButton
			Tween.Play(btn, {
				Size = UDim2.fromOffset(0, 0),
				ImageTransparency = 1,
				Rotation = 90,
			}, { Time = 0.15 })
			task.delay(0.15, function()
				if btn and btn.Parent then
					btn.Visible = false
					btn.Rotation = 0
				end
			end)
		end
	else
		if self.Main then
			self.Main.Visible = false
		end

		if self._FloatingButton and self._StartupComplete then
			local btn = self._FloatingButton
			btn.Visible = true
			btn.Size = UDim2.fromOffset(0, 0)
			btn.ImageTransparency = 1
			btn.Rotation = -90

			Tween.Play(btn, {
				Size = UDim2.fromOffset(58, 58),
				ImageTransparency = 0,
				Rotation = 10,
			}, { Time = 0.18 })

			task.delay(0.18, function()
				if btn and btn.Parent then
					Tween.Play(btn, {
						Size = UDim2.fromOffset(SIZES.FloatingButton, SIZES.FloatingButton),
						Rotation = 0,
					}, { Time = 0.12 })
				end
			end)
		end
	end
end

function Window:Toggle()
	self:SetVisible(not self._Visible)
end

function Window:Notify(options: any)
	return self.Library.Notifications:Notify(options)
end

function Window:Destroy()
	for _, tab in self._Tabs do
		if tab and tab.Destroy then
			tab:Destroy()
		end
	end
	table.clear(self._Tabs)
	self._ActiveTab = nil
	self._Maid:DoCleaning()
	if self.Gui then
		self.Gui:Destroy()
	end
end

return Window
