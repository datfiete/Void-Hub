--!strict

local Theme = require(script.Parent.Theme)
local Tab = require(script.Parent.Tab)
local Maid = require(script.Parent.Parent.Utils.Maid)
local Helpers = require(script.Parent.Parent.Utils.Helpers)
local Tween = require(script.Parent.Parent.Utils.Tween)
local GUI_Name = "Void Hub"

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
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local sharedState = (getgenv and getgenv()) or _G

	for _, child in playerGui:GetChildren() do
		if child:IsA("ScreenGui") and child.Name == "CyberUI" then
			child:Destroy()
		end
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "CyberUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui
	self._Maid:Give(screenGui)

	local windowName = data.Name or data.Title or "CyberUI"
	local windowSubtitle = data.Subtitle or data.Description
	local windowSize = data.Size or data.WindowSize or Theme.WindowSize

	if typeof(windowSize) == "UDim2" then
		windowSize = Vector2.new(windowSize.X.Offset, windowSize.Y.Offset)
	elseif typeof(windowSize) == "number" then
		windowSize = Vector2.new(windowSize, windowSize)
	elseif typeof(windowSize) ~= "Vector2" then
		windowSize = Vector2.new(800, 560)
	end

	local showSearch = data.ShowSearch ~= false
	local showWindowControls = data.ShowWindowControls ~= false
	local topBarHeight = Theme.TopBarHeight or 54

local loadingFrame = Helpers.CreateFrame({
		Name = "Loading",
		Size = UDim2.fromOffset(380, 168),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = library.Theme.Secondary,
		Parent = screenGui,
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
		Text = windowName,
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
		Text = windowSubtitle or "Preparing interface",
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

	local bootstrapLoader = sharedState.CyberUI_BootstrapLoader
	sharedState.CyberUI_BootstrapLoader = nil
	if bootstrapLoader and bootstrapLoader.Parent then
		bootstrapLoader:Destroy()
	end

	local main = Helpers.CreateFrame({
		Name = "Main",
		Size = UDim2.fromOffset(windowSize.X, windowSize.Y),
		Position = if data.Center ~= false then UDim2.fromScale(0.5, 0.5) else UDim2.fromOffset(40, 40),
		AnchorPoint = if data.Center ~= false then Vector2.new(0.5, 0.5) else Vector2.new(0, 0),
		BackgroundColor3 = library.Theme.Background,
		BackgroundTransparency = 0.2,
		Visible = false,
		Parent = screenGui,
	})
	Helpers.Corner(main, Theme.CornerRadius)
	main.ClipsDescendants = true
	local mainStroke = Helpers.Stroke(main, library.Theme.Border, 1)

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
	self._BackgroundImage = backgroundImage

	Helpers.Corner(backgroundImage, Theme.CornerRadius)

	local overlay = Instance.new("Frame")
	overlay.Name = "BackgroundOverlay"
	overlay.Size = UDim2.fromScale(1,1)
	overlay.BackgroundColor3 = Color3.new(0,0,0)
	overlay.BackgroundTransparency = 0.75
	overlay.BorderSizePixel = 0
	overlay.ZIndex = 1
	overlay.Parent = main
	main.Active = true
	main.Selectable = true
	main.ClipsDescendants = true
	Helpers.Corner(overlay, Theme.CornerRadius)

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

	local logoSize = 36
	local logoAsset = data.Logo

	local logoImage = nil

	if logoAsset and logoAsset ~= "" then
		logoImage = Instance.new("ImageLabel")
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
	end

	local titleStartX = if logoAsset then 12 + logoSize + 10 else 16

	local title = Helpers.CreateLabel({
		Name = "Title",
		Size = UDim2.new(0, 220, 0, 22),
		Position = UDim2.new(0, titleStartX, 0, 10),
		Text = windowName,
		Font = Theme.FontBold,
		TextSize = 17,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = library.Theme.Text,
		Parent = topBar,
	})
	title.ZIndex = 21

	local subtitle
	if windowSubtitle then
		subtitle = Helpers.CreateLabel({
			Name = "Subtitle",
			Size = UDim2.new(0, 220, 0, 16),
			Position = UDim2.new(0, titleStartX, 0, 30),
			Text = windowSubtitle,
			TextColor3 = library.Theme.TextMuted,
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = topBar,
		})
		subtitle.ZIndex = 21
	end

	local badgeHolder = Helpers.CreateFrame({
		Name = "Badges",
		Size = UDim2.new(0, 260, 0, 26),
		Position = UDim2.new(0, titleStartX + 180, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundTransparency = 1,
		Parent = topBar,
	})
	badgeHolder.ZIndex = 21
	Helpers.ListLayout(badgeHolder, 6)
	local badgeList: any = badgeHolder:FindFirstChildOfClass("UIListLayout")
	if badgeList then
		badgeList.FillDirection = Enum.FillDirection.Horizontal
		badgeList.VerticalAlignment = Enum.VerticalAlignment.Center
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
		closeButton.TextSize = 15
		closeButton.TextColor3 = library.Theme.TextMuted

		closeButton.AutoButtonColor = false
		closeButton.ZIndex = 21
		closeButton.Parent = topBar

		Helpers.Corner(closeButton, 8)
		Helpers.Stroke(closeButton, library.Theme.Border, 1)

		minimizeButton = Instance.new("TextButton")
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
	end

	closeButton.MouseEnter:Connect(function()
	Tween.Play(closeButton, {
		BackgroundTransparency = 0
	}, {
		Time = 0.15
	})
	end)

	closeButton.MouseLeave:Connect(function()
		Tween.Play(closeButton, {
			BackgroundTransparency = 0.25
		}, {
			Time = 0.15
		})
	end)

	local floatingButton = Instance.new("ImageButton")
	floatingButton.Name = "FloatingToggle"
	floatingButton.Size = UDim2.fromOffset(50, 50)
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
	floatingButton.Parent = screenGui
	Helpers.Corner(floatingButton, 25)
	local floatingStroke = Helpers.Stroke(floatingButton, library.Theme.Accent, 1.5)

	if not data.Logo or data.Logo == "" then
		local fallbackLabel = Helpers.CreateLabel({
			Name = "FallbackIcon",
			Size = UDim2.fromScale(1, 1),
			Text = string.sub(windowName, 1, 1),
			Font = Theme.FontBold,
			TextSize = 20,
			TextColor3 = library.Theme.Text,
			TextXAlignment = Enum.TextXAlignment.Center,
			Parent = floatingButton,
		})
		fallbackLabel.ZIndex = 51
	end

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
		if not self._FloatDragging or self._FloatDragInputType == nil then
			return
		end
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
	self._FloatingStroke = floatingStroke

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

	local minWindowSize = Vector2.new(420, 320)
	local maxWindowSize = Vector2.new(1200, 900)

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

	local searchBox
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

		searchTop = 40
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

	if data.Footer then
		local footer = Helpers.CreateFrame({
			Name = "Footer",
			Size = UDim2.new(1, 0, 0, 40),
			Position = UDim2.new(0, 0, 1, -40),
			BackgroundTransparency = 1,
			Parent = sidebar,
		})

		local avatarImage
		if data.Footer.Avatar and data.Footer.Avatar ~= "" then
			avatarImage = Instance.new("ImageLabel")
			avatarImage.Name = "Avatar"
			avatarImage.Size = UDim2.fromOffset(30, 30)
			avatarImage.Position = UDim2.new(0, 0, 0.5, 0)
			avatarImage.AnchorPoint = Vector2.new(0, 0.5)
			avatarImage.BackgroundColor3 = library.Theme.Background
			avatarImage.Image = data.Footer.Avatar
			avatarImage.Parent = footer
			Helpers.Corner(avatarImage, 15)
		end

		local footerLabel = Helpers.CreateLabel({
			Name = "WelcomeLabel",
			Size = UDim2.new(1, if avatarImage then -40 else 0, 1, 0),
			Position = UDim2.new(0, if avatarImage then 40 else 0, 0, 0),
			Text = "Welcome, " .. (data.Footer.Username or "Player"),
			TextColor3 = library.Theme.TextMuted,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = footer,
		})
	end

	local function refreshWindowTheme()
		main.BackgroundColor3 = library.Theme.Background
		topBar.BackgroundColor3 = library.Theme.Secondary
		topBarMask.BackgroundColor3 = library.Theme.Secondary
		sidebar.BackgroundColor3 = library.Theme.Secondary
		title.TextColor3 = library.Theme.Text
		if subtitle then
			subtitle.TextColor3 = library.Theme.TextMuted
		end
		if minimizeButton then
			minimizeButton.TextColor3 = library.Theme.TextMuted
		end
		if closeButton then
			closeButton.TextColor3 = library.Theme.TextMuted
		end
		mainStroke.Color = library.Theme.Border
		for _, tab in self._Tabs do
			tab:RefreshTheme()
		end
	end

	local themeConnection = library.Theme.Changed:Connect(function()
		refreshWindowTheme()
	end)
	self._Maid:GiveTask(themeConnection)

	local pages = Instance.new("Frame")
	pages.Name = "Pages"
	pages.Position = UDim2.new(0, Theme.SidebarWidth + 8, 0, 0)
	pages.Size = UDim2.new(1, -(Theme.SidebarWidth + 8), 1, 0)
	pages.BackgroundTransparency = 1
	pages.BorderSizePixel = 0
	pages.ClipsDescendants = true 
	pages.Parent = contentArea

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
	self._ToggleKeybind = data.ToggleKey or Enum.KeyCode.RightControl
	self._OptionsTab = nil
	self.RefreshTheme = refreshWindowTheme

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

	self._Maid:GiveTask(UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if self._ToggleKeybind ~= nil and self._ToggleKeybind ~= Enum.KeyCode.Unknown and input.KeyCode == self._ToggleKeybind then
			self:Toggle()
		end
	end))

	self._Maid:Give(task.delay(0.8, function()
		if not self.Gui then
			return
		end

		if loadingFrame and loadingFrame.Parent then
			loadingStatus.Text = "Ready"
			task.wait(0.25)
			Tween.Play(loadingFrame, { BackgroundTransparency = 1 }, { Time = 0.2 })
			Tween.Play(loadingAccent, { BackgroundTransparency = 1 }, { Time = 0.2 })
			Tween.Play(loadingTitle, { TextTransparency = 1 }, { Time = 0.2 })
			Tween.Play(loadingSubtitle, { TextTransparency = 1 }, { Time = 0.2 })
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

function Window:SetBackgroundImage(value: string)
	local bg = self._BackgroundImage
	if not bg then return end
	print("Changed BG to: " .. value)
	if value == "Solo Leveling" then
		bg.Image = "rbxassetid://139001765478120"
	elseif value == "Gojo" then
		bg.Image = "rbxassetid://111578938106815"

	elseif value == "Sukuna" then
		bg.Image = "rbxassetid://106318186489675"
	
	elseif value == "Cid Kagenou" then
		bg.Image = "rbxassetid://113248988511733"

	else
		bg.Image = ""
	end
end

function Window:SetBackgroundOverlayTransparency(value: number)
	local overlay = self.Main and self.Main:FindFirstChild("BackgroundOverlay")
	if overlay then
		overlay.BackgroundTransparency = value
	end
end

function Window:_selectTab(tab: any)
	if self._ActiveTab == tab then
		return
	end

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
		if key ~= "Style" then
			return
		end
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
        if value == "" then
            return
        end

        if not value:match("^rbxassetid://") then
            value = "rbxassetid://" .. value
        end

        if self._BackgroundImage then
            self._BackgroundImage.Image = value
        end
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
			setclipboard("https://discord.gg/D6AvbntAZf")
			print("Discord invite copied!")

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
	if not tab then
		return nil
	end
	return tab:CreateSection(nameOrData)
end

function Window:CreateDropdown(data: any)
	local tab = self:_getActiveTab()
	if not tab then
		return nil
	end
	return tab:CreateDropdown(data)
end

function Window:CreateToggle(data: any)
	local tab = self:_getActiveTab()
	if not tab then
		return nil
	end
	return tab:CreateToggle(data)
end

function Window:CreateButton(data: any)
	local tab = self:_getActiveTab()
	if not tab then
		return nil
	end
	return tab:CreateButton(data)
end

function Window:CreateSlider(data: any)
	local tab = self:_getActiveTab()
	if not tab then
		return nil
	end
	return tab:CreateSlider(data)
end

function Window:CreateInput(data: any)
	local tab = self:_getActiveTab()
	if not tab then
		return nil
	end
	return tab:CreateInput(data)
end

function Window:CreateKeybind(data: any)
	local tab = self:_getActiveTab()
	if not tab then
		return nil
	end
	return tab:CreateKeybind(data)
end

function Window:CreateColorPicker(data: any)
	local tab = self:_getActiveTab()
	if not tab then
		return nil
	end
	return tab:CreateColorPicker(data)
end

function Window:CreateParagraph(data: any)
	local tab = self:_getActiveTab()
	if not tab then
		return nil
	end
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
print("You use the CyberUI - UI!")
return Window
