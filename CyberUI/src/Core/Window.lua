--!strict

local Theme = require(script.Parent.Theme)
local Tab = require(script.Parent.Tab)
local Maid = require(script.Parent.Parent.Utils.Maid)
local Helpers = require(script.Parent.Parent.Utils.Helpers)
local Tween = require(script.Parent.Parent.Utils.Tween)

local GUI_NAME = "Vaxorin"
local VERSION = "1.0"
local Vaxorin_Logo = "rbxassetid://135320038058277"

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
		_StartupTime = os.clock(),
		_PlayerCount = 0,
	}, Window)

	local Players = game:GetService("Players")
	local localPlayer = Players.LocalPlayer.Name
	local UserInputService = game:GetService("UserInputService")
	local RunService = game:GetService("RunService")
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local sharedState = (getgenv and getgenv()) or _G

	-- Clean up old GUI
	for _, child in playerGui:GetChildren() do
		if child:IsA("ScreenGui") and child.Name == "Vaxorin" then
			child:Destroy()
		end
	end

	-- Create main ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "Vaxorin"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui
	self._Maid:Give(screenGui)

	local windowName = data.Name or data.Title or GUI_NAME
	local windowSubtitle = data.Subtitle or data.Description or "Welcome to the Vaxorin"
	local windowSize = data.Size or data.WindowSize or Theme.WindowSize

	if typeof(windowSize) == "UDim2" then
		windowSize = Vector2.new(windowSize.X.Offset, windowSize.Y.Offset)
	elseif typeof(windowSize) == "number" then
		windowSize = Vector2.new(windowSize, windowSize)
	elseif typeof(windowSize) ~= "Vector2" then
		windowSize = Vector2.new(900, 620)
	end

	local showSearch = data.ShowSearch ~= false
	local showWindowControls = data.ShowWindowControls ~= false
	local topBarHeight = Theme.TopBarHeight or 60
	local infoBarHeight = 32   -- height of the bottom info bar

	-- Resize limits
	local minWindowSize = Vector2.new(420, 320)
	local maxWindowSize = Vector2.new(1200, 900)

	-- ============================================
	-- LOADING SCREEN (unchanged)
	-- ============================================
	local loadingFrame = Helpers.CreateFrame({
		Name = "Loading",
		Size = UDim2.fromOffset(420, 180),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = library.Theme.Secondary,
		Parent = screenGui,
	})
	Helpers.Corner(loadingFrame, Theme.CornerRadius)
	Helpers.Stroke(loadingFrame, library.Theme.Border, 1)
	Helpers.Padding(loadingFrame, 20)

	local loadingAccent = Helpers.CreateFrame({
		Name = "Accent",
		Size = UDim2.new(0, 4, 1, -40),
		Position = UDim2.new(0, 20, 0, 20),
		BackgroundColor3 = library.Theme.Accent,
		Parent = loadingFrame,
	})
	Helpers.Corner(loadingAccent, 2)

	local loadingTitle = Helpers.CreateLabel({
		Name = "LoadingTitle",
		Size = UDim2.new(1, -44, 0, 34),
		Position = UDim2.fromOffset(20, 0),
		Text = windowName,
		Font = Theme.FontBold,
		TextColor3 = library.Theme.Text,
		TextSize = 22,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = loadingFrame,
	})

	local loadingSubtitle = Helpers.CreateLabel({
		Name = "LoadingSubtitle",
		Size = UDim2.new(1, -44, 0, 24),
		Position = UDim2.fromOffset(20, 38),
		Text = windowSubtitle,
		TextColor3 = library.Theme.TextMuted,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = loadingFrame,
	})

	local loadingVersion = Helpers.CreateLabel({
		Name = "LoadingVersion",
		Size = UDim2.new(1, -44, 0, 20),
		Position = UDim2.fromOffset(20, 62),
		Text = VERSION,
		TextColor3 = library.Theme.TextMuted,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = loadingFrame,
	})

	local loadingStatus = Helpers.CreateLabel({
		Name = "LoadingStatus",
		Size = UDim2.new(1, -44, 0, 20),
		Position = UDim2.fromOffset(20, 90),
		Text = "Loading components...",
		TextColor3 = library.Theme.TextMuted,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = loadingFrame,
	})

	local progressTrack = Helpers.CreateFrame({
		Name = "ProgressTrack",
		Size = UDim2.new(1, -44, 0, 6),
		Position = UDim2.fromOffset(20, 130),
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

	-- Remove old bootstrap loader
	local bootstrapLoader = sharedState.CyberUI_BootstrapLoader
	sharedState.CyberUI_BootstrapLoader = nil
	if bootstrapLoader and bootstrapLoader.Parent then
		bootstrapLoader:Destroy()
	end

	-- ============================================
	-- MAIN WINDOW
	-- ============================================
	local main = Helpers.CreateFrame({
		Name = "Main",
		Size = UDim2.fromOffset(windowSize.X, windowSize.Y),
		Position = if data.Center ~= false then UDim2.fromScale(0.5, 0.5) else UDim2.fromOffset(40, 40),
		AnchorPoint = if data.Center ~= false then Vector2.new(0.5, 0.5) else Vector2.new(0, 0),
		BackgroundColor3 = library.Theme.Background,
		BackgroundTransparency = 0.1,
		Visible = false,
		Parent = screenGui,
	})
	Helpers.Corner(main, Theme.CornerRadius)
	local mainStroke = Helpers.Stroke(main, library.Theme.Border, 1)
	main.ClipsDescendants = true

	-- Background Image
	local backgroundImage = Instance.new("ImageLabel")
	backgroundImage.AnchorPoint = Vector2.new(0, 0)
	backgroundImage.Position = UDim2.new(0, 0, 0, 0)
	backgroundImage.Name = "BackgroundImage"
	backgroundImage.Size = UDim2.fromScale(1, 1)
	backgroundImage.BackgroundTransparency = 1
	backgroundImage.Image = data.BackgroundImage or ""
	backgroundImage.ImageTransparency = 0.2
	backgroundImage.ScaleType = Enum.ScaleType.Crop
	backgroundImage.ZIndex = 0
	backgroundImage.Parent = main
	Helpers.Corner(backgroundImage, Theme.CornerRadius)
	self._BackgroundImage = backgroundImage

	-- Overlay
	local overlay = Instance.new("Frame")
	overlay.Name = "BackgroundOverlay"
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = Color3.new(0, 0, 0)
	overlay.BackgroundTransparency = 0.65
	overlay.BorderSizePixel = 0
	overlay.ZIndex = 1
	overlay.Parent = main
	Helpers.Corner(overlay, Theme.CornerRadius)

	-- ============================================
	-- TOP BAR (Title & Subtitle side by side)
	-- ============================================
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
	local logoSize = 36
	local logoAsset = data.Logo or "rbxassetid://135320038058277"

	local logoImage = Instance.new("ImageLabel")
	logoImage.Name = "Logo"
	logoImage.BackgroundTransparency = 1
	logoImage.Size = UDim2.fromOffset(logoSize, logoSize)
	logoImage.Position = UDim2.new(0, 14, 0.5, 0)
	logoImage.AnchorPoint = Vector2.new(0, 0.5)
	logoImage.Image = logoAsset
	logoImage.ScaleType = Enum.ScaleType.Fit
	logoImage.ZIndex = 30
	logoImage.Parent = topBar
	Helpers.Corner(logoImage, 8)

	-- Title and Subtitle container (horizontal layout)
	local titleContainer = Helpers.CreateFrame({
		Name = "TitleContainer",
		Size = UDim2.new(0, 300, 1, 0),
		Position = UDim2.new(0, 14 + logoSize + 10, 0, 0),
		BackgroundTransparency = 1,
		Parent = topBar,
	})

	local title = Helpers.CreateLabel({
		Name = "Title",
		Size = UDim2.new(0, 0, 1, 0),
		AutomaticSize = Enum.AutomaticSize.X,
		Position = UDim2.new(0, 0, 0, 0),
		Text = windowName,
		Font = Theme.FontBold,
		TextSize = 18,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = library.Theme.Text,
		Parent = titleContainer,
	})
	title.ZIndex = 21

	-- Subtitle placed to the right of title with some spacing
	local subtitle = Helpers.CreateLabel({
		Name = "Subtitle",
		Size = UDim2.new(0, 0, 1, 0),
		AutomaticSize = Enum.AutomaticSize.X,
		Position = UDim2.new(0, title.TextBounds.X + 10, 0, 0),
		Text = "• " .. windowSubtitle,
		TextColor3 = library.Theme.TextMuted,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = titleContainer,
	})
	subtitle.ZIndex = 21

	-- Adjust title container width after labels are rendered
	task.defer(function()
		local totalWidth = title.TextBounds.X + 10 + subtitle.TextBounds.X + 20
		titleContainer.Size = UDim2.new(0, math.max(totalWidth, 200), 1, 0)
		subtitle.Position = UDim2.new(0, title.TextBounds.X + 10, 0, 0)
	end)

	-- ========== BADGES (improved layout) ==========
	local badgeHolder = Helpers.CreateFrame({
		Name = "Badges",
		Size = UDim2.new(0, 0, 1, 0),
		AutomaticSize = Enum.AutomaticSize.X,
		Position = UDim2.new(1, -130, 0.5, 0),   -- moved left to avoid buttons
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundTransparency = 1,
		Parent = topBar,
	})
	badgeHolder.ZIndex = 21

	local badgeLayout = Instance.new("UIListLayout")
	badgeLayout.FillDirection = Enum.FillDirection.Horizontal
	badgeLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	badgeLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	badgeLayout.Padding = UDim.new(0, 8)
	badgeLayout.Parent = badgeHolder

	-- Create default badges if none provided
	local badgeData = data.Badges or {
		{ Text = "Executor", Color = library.Theme.Accent },
		{ Text = VERSION, Color = library.Theme.TextMuted },
	}

	for i, badge in badgeData do
		local color = badge.Color or library.Theme.Accent
		local pill = Helpers.CreateFrame({
			Name = "Badge" .. i,
			Size = UDim2.new(0, 0, 0, 28),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundColor3 = color,
			BackgroundTransparency = 0.85,
			Parent = badgeHolder,
		})
		pill.ZIndex = 22
		Helpers.Corner(pill, 14)
		Helpers.Stroke(pill, color, 1)
		Helpers.Padding(pill, 12, 4)

		local pillLabel = Helpers.CreateLabel({
			Name = "Label",
			Size = UDim2.new(0, 0, 1, 0),
			AutomaticSize = Enum.AutomaticSize.X,
			Text = badge.Text,
			Font = Theme.FontBold,
			TextSize = 11,
			TextColor3 = color,
			TextXAlignment = Enum.TextXAlignment.Center,
			Parent = pill,
		})
	end

	-- Window controls
	local minimizeButton, closeButton
	if showWindowControls then
		closeButton = Instance.new("TextButton")
		closeButton.Name = "Close"
		closeButton.Size = UDim2.fromOffset(32, 32)
		closeButton.Position = UDim2.new(1, -12, 0.5, 0)
		closeButton.AnchorPoint = Vector2.new(1, 0.5)
		closeButton.BackgroundColor3 = library.Theme.Background
		closeButton.BackgroundTransparency = 0.25
		closeButton.Text = "X"
		closeButton.Font = Theme.FontBold
		closeButton.TextSize = 16
		closeButton.TextColor3 = library.Theme.TextMuted
		closeButton.AutoButtonColor = false
		closeButton.ZIndex = 21
		closeButton.Parent = topBar
		Helpers.Corner(closeButton, 8)
		Helpers.Stroke(closeButton, library.Theme.Border, 1)

		closeButton.MouseEnter:Connect(function()
			Tween.Play(closeButton, { BackgroundTransparency = 0, TextColor3 = Color3.fromRGB(255, 50, 50) }, { Time = 0.15 })
		end)
		closeButton.MouseLeave:Connect(function()
			Tween.Play(closeButton, { BackgroundTransparency = 0.25, TextColor3 = library.Theme.TextMuted }, { Time = 0.15 })
		end)

		minimizeButton = Instance.new("TextButton")
		minimizeButton.Name = "Minimize"
		minimizeButton.Size = UDim2.fromOffset(28, 28)
		minimizeButton.Position = UDim2.new(1, -50, 0.5, 0)
		minimizeButton.AnchorPoint = Vector2.new(1, 0.5)
		minimizeButton.BackgroundTransparency = 1
		minimizeButton.Text = "—"
		minimizeButton.Font = Theme.FontBold
		minimizeButton.TextSize = 18
		minimizeButton.TextColor3 = library.Theme.TextMuted
		minimizeButton.AutoButtonColor = false
		minimizeButton.ZIndex = 21
		minimizeButton.Parent = topBar
	end

	-- ============================================
	-- FLOATING BUTTON (unchanged)
	-- ============================================
	local floatingButton = Instance.new("ImageButton")
	floatingButton.Name = "FloatingToggle"
	floatingButton.Size = UDim2.fromOffset(50, 50)
	floatingButton.Position = UDim2.new(0.5, 0, 0, 20)
	floatingButton.BackgroundColor3 = library.Theme.Secondary
	floatingButton.BackgroundTransparency = 0.1
	floatingButton.Image = logoAsset
	floatingButton.ScaleType = Enum.ScaleType.Fit
	floatingButton.ImageTransparency = 0
	floatingButton.Visible = false
	floatingButton.AutoButtonColor = false
	floatingButton.ZIndex = 50
	floatingButton.Active = true
	floatingButton.Selectable = true
	floatingButton.Parent = screenGui
	Helpers.Corner(floatingButton, 25)
	local floatingStroke = Helpers.Stroke(floatingButton, library.Theme.Accent, 1.5)

	floatingButton.MouseEnter:Connect(function()
		Tween.Play(floatingButton, { BackgroundTransparency = 0 }, { Time = 0.15 })
	end)
	floatingButton.MouseLeave:Connect(function()
		Tween.Play(floatingButton, { BackgroundTransparency = 0.1 }, { Time = 0.15 })
	end)
	floatingButton.MouseButton1Click:Connect(function()
		self:SetVisible(true)
	end)

	self._FloatDragging = false
	self._FloatDragStart = Vector2.new()
	self._FloatStart = UDim2.new()
	self._FloatDragInputType = nil :: Enum.UserInputType?

	self._Maid:GiveTask(floatingButton.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			self._FloatDragging = true
			self._FloatDragStart = input.Position
			self._FloatStart = floatingButton.Position
			self._FloatDragInputType = input.UserInputType
		end
	end))

	self._Maid:GiveTask(UserInputService.InputChanged:Connect(function(input)
		if not self._FloatDragging or self._FloatDragInputType == nil then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			local delta = input.Position - self._FloatDragStart
			floatingButton.Position = UDim2.new(
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

	self._Maid:Give(floatingButton)
	self._FloatingButton = floatingButton

	-- ============================================
	-- WINDOW DRAGGING (unchanged)
	-- ============================================
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
		if not dragging or dragInputType == nil then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			local delta = input.Position - dragStart
			main.Position = UDim2.new(
				windowStart.X.Scale, windowStart.X.Offset + delta.X,
				windowStart.Y.Scale, windowStart.Y.Offset + delta.Y
			)
		end
	end))

	self._Maid:GiveTask(UserInputService.InputEnded:Connect(function(input)
		if dragInputType ~= nil and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			dragging = false
			dragInputType = nil
		end
	end))

	-- ============================================
	-- RESIZE HANDLE (re‑added)
	-- ============================================
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

	-- Small lines in the corner
	for i = 1, 3 do
		local line = Instance.new("Frame")
		line.Name = "Line" .. i
		line.Size = UDim2.fromOffset(2, 2 + i * 3)
		line.Position = UDim2.new(1, -4 - (i * 5), 1, -4)
		line.AnchorPoint = Vector2.new(1, 1)
		line.BackgroundColor3 = library.Theme.TextMuted
		line.BorderSizePixel = 0
		line.Rotation = 45
		line.ZIndex = 26
		line.Parent = resizeHandle
	end

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
			local newX = math.clamp(sizeStart.X.Offset + delta.X, minWindowSize.X, maxWindowSize.X)
			local newY = math.clamp(sizeStart.Y.Offset + delta.Y, minWindowSize.Y, maxWindowSize.Y)
			main.Size = UDim2.fromOffset(newX, newY)
		end
	end))

	self._Maid:GiveTask(UserInputService.InputEnded:Connect(function(input)
		if resizeInputType ~= nil and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			resizing = false
			resizeInputType = nil
		end
	end))

	-- Hover effect on resize handle
	resizeHandle.MouseEnter:Connect(function()
		for _, line in resizeHandle:GetChildren() do
			Tween.Play(line, { BackgroundColor3 = library.Theme.Accent }, { Time = 0.12 })
		end
	end)
	resizeHandle.MouseLeave:Connect(function()
		for _, line in resizeHandle:GetChildren() do
			Tween.Play(line, { BackgroundColor3 = library.Theme.TextMuted }, { Time = 0.12 })
		end
	end)

	self._ResizeHandle = resizeHandle

	-- ============================================
	-- CONTENT AREA (now leaves space for infoBar)
	-- ============================================
	local contentArea = Helpers.CreateFrame({
		Name = "ContentArea",
		Size = UDim2.new(1, 0, 1, -(topBarHeight + infoBarHeight)),
		Position = UDim2.new(0, 0, 0, topBarHeight),
		BackgroundTransparency = 1,
		Parent = main,
	})

	-- Sidebar
	local sidebar = Helpers.CreateFrame({
		Name = "Sidebar",
		Size = UDim2.new(0, Theme.SidebarWidth, 1, 0),
		BackgroundColor3 = library.Theme.Secondary,
		BackgroundTransparency = 0.15,
		Parent = contentArea,
	})
	Helpers.Corner(sidebar, Theme.CornerRadius)
	sidebar.ClipsDescendants = true
	Helpers.Padding(sidebar, Theme.Padding)

	-- Search Box
	local searchBox
	local searchTop = 0
	if showSearch then
		local searchHolder = Helpers.CreateFrame({
			Name = "SearchHolder",
			Size = UDim2.new(1, 0, 0, 34),
			Position = UDim2.new(0, 0, 0, 0),
			BackgroundColor3 = library.Theme.Background,
			Parent = sidebar,
		})
		Helpers.Corner(searchHolder, Theme.CornerRadiusSmall)
		Helpers.Stroke(searchHolder, library.Theme.Border, 1)

		searchBox = Instance.new("TextBox")
		searchBox.Name = "SearchBox"
		searchBox.Size = UDim2.new(1, -24, 1, 0)
		searchBox.Position = UDim2.new(0, 12, 0, 0)
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

		searchTop = 44
	end

	-- Tab List
	local tabList = Helpers.CreateFrame({
		Name = "TabList",
		Size = UDim2.new(1, 0, 1, -(searchTop + 52)),
		Position = UDim2.new(0, 0, 0, searchTop),
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.None,
		Parent = sidebar,
	})
	Helpers.ListLayout(tabList, Theme.Gap)

	-- Footer (welcome text smaller, with truncation)
	local footer = Helpers.CreateFrame({
		Name = "Footer",
		Size = UDim2.new(1, 0, 0, 44),
		Position = UDim2.new(0, 0, 1, -44),
		BackgroundTransparency = 1,
		Parent = sidebar,
	})

	local footerDivider = Helpers.CreateFrame({
		Name = "Divider",
		Size = UDim2.new(1, -20, 0, 1),
		Position = UDim2.new(0, 10, 0, 0),
		BackgroundColor3 = library.Theme.Border,
		Parent = footer,
	})

	local avatarImage
	local footerUsername = data.Footer and data.Footer.Username or Players.LocalPlayer.DisplayName
	local footerAvatar = data.Footer and data.Footer.Avatar

	if footerAvatar and footerAvatar ~= "" then
		avatarImage = Instance.new("ImageLabel")
		avatarImage.Name = "Avatar"
		avatarImage.Size = UDim2.fromOffset(30, 30)
		avatarImage.Position = UDim2.new(0, 0, 0.5, 0)
		avatarImage.AnchorPoint = Vector2.new(0, 0.5)
		avatarImage.BackgroundColor3 = library.Theme.Background
		avatarImage.Image = footerAvatar
		avatarImage.Parent = footer
		Helpers.Corner(avatarImage, 15)
	end

	local footerLabel = Helpers.CreateLabel({
		Name = "WelcomeLabel",
		Size = UDim2.new(1, if avatarImage then -40 else 0, 1, 0),
		Position = UDim2.new(0, if avatarImage then 40 else 0, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		Text = "Welcome, " .. localPlayer,
		TextColor3 = library.Theme.Text,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Theme.FontBold,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = footer,
	})

	-- ============================================
	-- PAGES (unchanged)
	-- ============================================
	local pages = Instance.new("Frame")
	pages.Name = "Pages"
	pages.Position = UDim2.new(0, Theme.SidebarWidth + 8, 0, 0)
	pages.Size = UDim2.new(1, -(Theme.SidebarWidth + 8), 1, 0)
	pages.BackgroundTransparency = 1
	pages.BorderSizePixel = 0
	pages.ClipsDescendants = true
	pages.Parent = contentArea

	-- ============================================
	-- INFO BAR (bottom of main)
	-- ============================================
	local infoBar = Helpers.CreateFrame({
		Name = "InfoBar",
		Size = UDim2.new(1, 0, 0, infoBarHeight),
		Position = UDim2.new(0, 0, 1, -infoBarHeight),
		BackgroundColor3 = library.Theme.Secondary,
		BackgroundTransparency = 0.3,
		Parent = main,
	})
	Helpers.Corner(infoBar, Theme.CornerRadius, { BottomLeft = true, BottomRight = true })
	Helpers.Stroke(infoBar, library.Theme.Border, 0.5)

	local infoLayout = Instance.new("UIListLayout")
	infoLayout.Name = "InfoLayout"
	infoLayout.FillDirection = Enum.FillDirection.Horizontal
	infoLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	infoLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	infoLayout.Padding = UDim.new(0, 20)
	infoLayout.Parent = infoBar

	local infoRefs = {}

	local function createInfoItem(labelText: string, initialValue: string)
		local container = Instance.new("Frame")
		container.Name = "InfoItem"
		container.Size = UDim2.new(0, 0, 1, 0)
		container.AutomaticSize = Enum.AutomaticSize.X
		container.BackgroundTransparency = 1
		container.Parent = infoBar

		local label = Helpers.CreateLabel({
			Name = "Label",
			Size = UDim2.new(0, 0, 1, 0),
			AutomaticSize = Enum.AutomaticSize.X,
			Text = labelText,
			TextColor3 = library.Theme.TextMuted,
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = container,
		})

		local value = Helpers.CreateLabel({
			Name = "Value",
			Size = UDim2.new(0, 0, 1, 0),
			AutomaticSize = Enum.AutomaticSize.X,
			Position = UDim2.new(0, label.TextBounds.X + 2, 0, 0),
			Text = initialValue,
			TextColor3 = library.Theme.Text,
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Left,
			Font = Theme.FontBold,
			Parent = container,
		})

		container.Size = UDim2.new(0, label.TextBounds.X + value.TextBounds.X + 4, 1, 0)
		return { Container = container, Label = label, Value = value }
	end

	local executorName = "Unknown"
	if syn and syn.getexecutorname then
		executorName = syn.getexecutorname()
	elseif getexecutorname then
		executorName = getexecutorname()
	end

	local items = {
		{ Label = "Executor: ", Value = executorName },
		{ Label = "v", Value = VERSION },
		{ Label = "Uptime: ", Value = "00:00:00" },
		{ Label = "Players: ", Value = tostring(#Players:GetPlayers()) .. " / " .. tostring(Players.MaxPlayers) },
		{ Label = "Time: ", Value = os.date("%I:%M %p") },
	}

	for _, item in items do
		local ref = createInfoItem(item.Label, item.Value)
		table.insert(infoRefs, ref)
	end

	local function updateInfoBar()
		local uptime = os.clock() - self._StartupTime
		local hours = math.floor(uptime / 3600)
		local minutes = math.floor((uptime % 3600) / 60)
		local seconds = math.floor(uptime % 60)
		local uptimeStr = string.format("%02d:%02d:%02d", hours, minutes, seconds)

		local playerCount = #Players:GetPlayers()
		local maxPlayers = Players.MaxPlayers

		local values = {
			uptimeStr,
			tostring(playerCount) .. " / " .. tostring(maxPlayers),
			os.date("%I:%M %p"),
		}

		local index = 1
		for i, ref in ipairs(infoRefs) do
			if i > 2 then  -- skip Executor and Version
				if ref.Value then
					ref.Value.Text = values[index]
					index = index + 1
				end
			end
		end
	end

	local updateConnection = RunService.Heartbeat:Connect(function()
		updateInfoBar()
	end)
	self._Maid:GiveTask(updateConnection)

	self._Maid:GiveTask(Players.PlayerAdded:Connect(updateInfoBar))
	self._Maid:GiveTask(Players.PlayerRemoving:Connect(updateInfoBar))

	-- ============================================
	-- SEARCH FUNCTIONALITY
	-- ============================================
	if searchBox then
		local previouslyMatched = {} :: { [Instance]: boolean }

		self._Maid:GiveTask(searchBox:GetPropertyChangedSignal("Text"):Connect(function()
			local query = searchBox.Text:lower()

			for _, child in tabList:GetChildren() do
				if child:IsA("GuiObject") then
					local matches = query == "" or child.Name:lower():find(query, 1, true) ~= nil
					child.Visible = matches

					if matches and query ~= "" and not previouslyMatched[child] then
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
	end

	-- ============================================
	-- THEME REFRESH
	-- ============================================
	local function refreshWindowTheme()
		main.BackgroundColor3 = library.Theme.Background
		topBar.BackgroundColor3 = library.Theme.Secondary
		topBarMask.BackgroundColor3 = library.Theme.Secondary
		sidebar.BackgroundColor3 = library.Theme.Secondary
		title.TextColor3 = library.Theme.Text
		if subtitle then subtitle.TextColor3 = library.Theme.TextMuted end
		if minimizeButton then minimizeButton.TextColor3 = library.Theme.TextMuted end
		if closeButton then closeButton.TextColor3 = library.Theme.TextMuted end
		mainStroke.Color = library.Theme.Border

		-- Update info bar colors
		for _, ref in infoRefs do
			if ref.Label then ref.Label.TextColor3 = library.Theme.TextMuted end
			if ref.Value then ref.Value.TextColor3 = library.Theme.Text end
		end

		-- Update badge colors
		for _, child in badgeHolder:GetChildren() do
			if child:IsA("Frame") and child.Name:match("^Badge") then
				local label = child:FindFirstChild("Label")
				local color = child.BackgroundColor3
				if label then
					label.TextColor3 = color
				end
			end
		end

		-- Update resize handle lines
		if resizeHandle then
			for _, line in resizeHandle:GetChildren() do
				if line:IsA("Frame") and line.Name:match("^Line") then
					line.BackgroundColor3 = library.Theme.TextMuted
				end
			end
		end

		for _, tab in self._Tabs do
			if tab and tab.RefreshTheme then
				tab:RefreshTheme()
			end
		end
	end

	local themeConnection = library.Theme.Changed:Connect(function()
		refreshWindowTheme()
	end)
	self._Maid:GiveTask(themeConnection)

	-- ============================================
	-- MINIMIZE / CLOSE (unchanged)
	-- ============================================
	if minimizeButton then
		minimizeButton.MouseButton1Click:Connect(function()
			self._Minimized = not self._Minimized
			if self._Minimized then
				Tween.Play(main, { Size = UDim2.fromOffset(windowSize.X, topBarHeight) }, { Time = 0.18 })
			else
				Tween.Play(main, { Size = UDim2.fromOffset(windowSize.X, windowSize.Y) }, { Time = 0.18 })
			end
		end)
	end

	if closeButton then
		closeButton.MouseButton1Click:Connect(function()
			self:SetVisible(false)
		end)
	end

	-- ============================================
	-- KEYBIND
	-- ============================================
	self._ToggleKeybind = data.ToggleKey or Enum.KeyCode.RightControl
	self._Maid:GiveTask(UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if self._ToggleKeybind ~= nil and self._ToggleKeybind ~= Enum.KeyCode.Unknown and input.KeyCode == self._ToggleKeybind then
			self:Toggle()
		end
	end))

	-- ============================================
	-- SELF REFS
	-- ============================================
	self.Gui = screenGui
	self.Main = main
	self.TopBar = topBar
	self.Sidebar = sidebar
	self.TabList = tabList
	self.Pages = pages
	self.TitleLabel = title
	self.SearchBox = searchBox
	self._ThemeConnection = themeConnection
	self._LoadingFrame = loadingFrame
	self._Visible = true
	self._Minimized = false
	self._StartupComplete = false
	self._OptionsTab = nil
	self.RefreshTheme = refreshWindowTheme
	self._InfoBar = infoBar
	self._InfoRefs = infoRefs
	self._ResizeHandle = resizeHandle

	-- ============================================
	-- STARTUP COMPLETE
	-- ============================================
	self._Maid:Give(task.delay(0.8, function()
		if not self.Gui then return end

		if loadingFrame and loadingFrame.Parent then
			loadingStatus.Text = "Ready"

			Tween.Play(loadingFrame, { BackgroundTransparency = 1 }, { Time = 0.2 })
			Tween.Play(loadingAccent, { BackgroundTransparency = 1 }, { Time = 0.2 })
			Tween.Play(loadingTitle, { TextTransparency = 1 }, { Time = 0.2 })
			Tween.Play(loadingSubtitle, { TextTransparency = 1 }, { Time = 0.2 })
			Tween.Play(loadingVersion, { TextTransparency = 1 }, { Time = 0.2 })
			Tween.Play(loadingStatus, { TextTransparency = 1 }, { Time = 0.2 })
			Tween.Play(progressTrack, { BackgroundTransparency = 1 }, { Time = 0.2 })
			Tween.Play(progressFill, { BackgroundTransparency = 1 }, { Time = 0.2 })

			task.wait(0.2)
			if loadingFrame and loadingFrame.Parent then
				loadingFrame:Destroy()
			end
		end

		self._StartupComplete = true
		self:SetVisible(self._Visible)
	end))

	return self :: any
end

-- ============================================
-- METHODS (unchanged)
-- ============================================

function Window:SetBackgroundImage(value: string)
	local bg = self._BackgroundImage
	if not bg then return end

	local images = {
		["Solo Leveling"] = "rbxassetid://139001765478120",
		["Gojo"] = "rbxassetid://111578938106815",
		["Sukuna"] = "rbxassetid://106318186489675",
		["Cid Kagenou"] = "rbxassetid://113248988511733",
	}

	bg.Image = images[value] or ""
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
		if existingTab and existingTab.SetActive then
			existingTab:SetActive(existingTab == tab)
		end
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

	local optionsTab = Tab.new(self, "⚙️ Options")
	self._OptionsTab = optionsTab
	table.insert(self._Tabs, optionsTab)

	self.Library.Theme.Style = self.Library:_getSavedFlag("Vaxorin.Theme.Style", self.Library.Theme.Style, true)
	self.Library.Theme.Background = self.Library:_getSavedFlag("Vaxorin.Theme.Background", self.Library.Theme.Background, true)
	self.Library.Theme.Secondary = self.Library:_getSavedFlag("Vaxorin.Theme.Secondary", self.Library.Theme.Secondary, true)
	self.Library.Theme.Accent = self.Library:_getSavedFlag("Vaxorin.Theme.Accent", self.Library.Theme.Accent, true)
	self.Library.Theme.Text = self.Library:_getSavedFlag("Vaxorin.Theme.Text", self.Library.Theme.Text, true)
	self.Library.Theme.Border = self.Library:_getSavedFlag("Vaxorin.Theme.Border", self.Library.Theme.Border, true)

	local visualSection = optionsTab:CreateSection("🎨 Visual")
	visualSection:CreateParagraph({
		Title = "Customize your experience",
		Content = "Choose the look and feel of Vaxorin.",
	})

	visualSection:CreateDropdown({
		Name = "Theme Preset",
		Options = {"Dark", "Light", "Cyber", "Meng"},
		CurrentOption = self.Library.Theme.Style,
		Flag = "Vaxorin.Theme.Style",
		Callback = function(value)
			self.Library.Theme.Style = value
		end,
	})

	local themeColorPickers = {}
	local colorConfigs = {
		Accent = { Name = "Accent Color", Flag = "Vaxorin.Theme.Accent" },
		Background = { Name = "Background Color", Flag = "Vaxorin.Theme.Background" },
		Secondary = { Name = "Secondary Color", Flag = "Vaxorin.Theme.Secondary" },
		Text = { Name = "Text Color", Flag = "Vaxorin.Theme.Text" },
		Border = { Name = "Border Color", Flag = "Vaxorin.Theme.Border" },
	}

	for key, config in colorConfigs do
		themeColorPickers[key] = visualSection:CreateColorPicker({
			Name = config.Name,
			CurrentValue = self.Library.Theme[key],
			Flag = config.Flag,
			Callback = function(color)
				self.Library.Theme[key] = color
			end,
		})
	end

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
		PlaceholderText = "rbxassetid://123456789",
		Callback = function(value)
			if value == "" then return end
			if not value:match("^rbxassetid://") then
				value = "rbxassetid://" .. value
			end
			if self._BackgroundImage then
				self._BackgroundImage.Image = value
			end
		end,
	})

	visualSection:CreateDropdown({
		Name = "Background Presets",
		Options = {"Solo Leveling", "Gojo", "Sukuna", "Cid Kagenou", "None"},
		Callback = function(value: string)
			self:SetBackgroundImage(value)
		end,
	})

	visualSection:CreateSlider({
		Name = "Overlay Transparency",
		Min = 0,
		Max = 1,
		CurrentValue = 0.65,
		Rounding = 0.01,
		Callback = function(value: number)
			self:SetBackgroundOverlayTransparency(value)
		end,
		Flag = "Vaxorin.Background.OverlayTransparency",
	})

	local configSection = optionsTab:CreateSection("⚙️ Configuration")
	configSection:CreateParagraph({
		Title = "Save & Restore",
		Content = "Your settings are automatically saved.",
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
		Name = "💾 Save Configuration",
		Callback = function()
			self.Library:SaveConfiguration()
			self:Notify({
				Title = "Saved",
				Content = "Configuration saved successfully!",
				Type = "Success",
			})
		end,
	})

	configSection:CreateButton({
		Name = "📂 Load Configuration",
		Callback = function()
			self.Library:LoadConfiguration()
			self:Notify({
				Title = "Loaded",
				Content = "Configuration loaded successfully!",
				Type = "Success",
			})
		end,
	})

	local keybindSection = optionsTab:CreateSection("⌨️ Keybinds")
	keybindSection:CreateParagraph({
		Title = "Toggle UI",
		Content = "Press this key to show/hide the interface.",
	})

	local toggleKeybind = keybindSection:CreateKeybind({
		Name = "Toggle UI",
		Default = self._ToggleKeybind,
		Flag = "Vaxorin.ToggleKey",
		Callback = function(key)
			self._ToggleKeybind = key
		end,
	})

	self._Maid:GiveTask(toggleKeybind:OnChanged(function(key)
		self._ToggleKeybind = key
	end))

	local discordSection = optionsTab:CreateSection("💬 Discord")
	discordSection:CreateButton({
		Name = "📋 Copy Discord Invite",
		Callback = function()
			local invite = "https://discord.gg/D6AvbntAZf"
			if setclipboard then setclipboard(invite) end

			self:Notify({
				Title = "Discord",
				Content = "Invite copied to clipboard!",
				Type = "Success",
				Duration = 4,
			})
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
						Size = UDim2.fromOffset(50, 50),
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
	if self.Library and self.Library.Notifications and self.Library.Notifications.Notify then
		return self.Library.Notifications:Notify(options)
	end

	game:GetService("StarterGui"):SetCore("SendNotification", {
		Title = options.Title or "Vaxorin",
		Text = options.Content or options.Text or "",
		Duration = options.Duration or 5,
		Icon = Vaxorin_Logo,
	})
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

print("🌌 Vaxorin loaded successfully!")
return Window
