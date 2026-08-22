--!strict

local Theme = require(script.Parent.Theme)
local Tab = require(script.Parent.Tab)
local Maid = require(script.Parent.Parent.Utils.Maid)
local Helpers = require(script.Parent.Parent.Utils.Helpers)
local Tween = require(script.Parent.Parent.Utils.Tween)

local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local Stats = game:GetService("Stats")

local GUI_NAME = "Vaxorin"
local VERSION = "3.0"
local Vaxorin_Logo = "rbxassetid://135320038058277"
local LEGACY_LOGO = "rbxassetid://128228297210141"

-- Soft 9-slice drop shadow, used behind the main window for real depth instead
-- of a flat card floating on nothing.
local SHADOW_IMAGE = "rbxassetid://6014261993"
local SHADOW_SLICE_CENTER = Rect.new(49, 49, 450, 450)

-- Short, unobtrusive UI click. Toggleable via Options -> Sound Effects.
local CLICK_SOUND_ID = "rbxassetid://876939830"

-- How often (seconds) the bottom info bar / watermark refreshes.
-- Was previously recalculated every single Heartbeat frame (~60x/sec) for no reason.
local INFO_BAR_REFRESH_INTERVAL = 1
local WATERMARK_REFRESH_INTERVAL = 0.5

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
	TopMost: boolean?,
	HideCoreUI: boolean?,
}

export type WindowHandle = {
	CreateTab: (self: WindowHandle, name: string) -> any,
	Notify: (self: WindowHandle, options: any) -> any,
	Destroy: (self: WindowHandle) -> (),
}

-- Safely resolve the executor name without ever throwing.
local function getExecutorName(): string
	local ok, result = pcall(function()
		if syn and syn.getexecutorname then
			return syn.getexecutorname()
		elseif getexecutorname then
			return getexecutorname()
		elseif identifyexecutor then
			local name = identifyexecutor()
			return name
		end
		return "Unknown"
	end)
	if ok and typeof(result) == "string" and result ~= "" then
		return result
	end
	return "Unknown"
end

function Window.new(library: any, options: WindowOptions?): WindowHandle
	local data = (typeof(options) == "table") and options or {}
	local self = setmetatable({
		Library = library,
		_Maid = Maid.new(),
		_Tabs = {} :: { any },
		_ActiveTab = nil :: any,
		_StartupTime = os.clock(),
	}, Window)

	local Players = game:GetService("Players")
	local localPlayer = Players.LocalPlayer.Name
	local UserInputService = game:GetService("UserInputService")
	local RunService = game:GetService("RunService")
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local sharedState = (getgenv and getgenv()) or _G

	-- Prefer the executor's hidden/CoreGui container when available. This gets
	-- CyberUI out of the normal PlayerGui layer and above most game UI.
	-- It still cannot guarantee drawing over Roblox's own pause/CoreGui menus.
	local function getTopGuiParent(): Instance
		local ok, hidden = pcall(function()
			if gethui then
				return gethui()
			end
			if get_hidden_gui then
				return get_hidden_gui()
			end
			return nil
		end)
		if ok and typeof(hidden) == "Instance" then
			return hidden
		end
		return playerGui
	end

	local topGuiParent = getTopGuiParent()
	self._TopGuiParent = topGuiParent

	-- ============================================
	-- CLICK SOUND
	-- ============================================
	self._SoundEnabled = true
	local clickSound = Instance.new("Sound")
	clickSound.Name = "VaxorinClick"
	clickSound.SoundId = CLICK_SOUND_ID
	clickSound.Volume = 0.35
	clickSound.Parent = SoundService
	self._Maid:Give(clickSound)

	local function playClick()
		if self._SoundEnabled then
			clickSound:Play()
		end
	end
	self._PlayClick = playClick

	-- Clean up old GUI in both PlayerGui and any hidden GUI container.
	for _, container in { playerGui, topGuiParent } do
		if typeof(container) == "Instance" then
			for _, child in container:GetChildren() do
				if child:IsA("ScreenGui") and child.Name == "Vaxorin" then
					child:Destroy()
				end
			end
		end
	end
	local oldBlur = Lighting:FindFirstChild("VaxorinBlur")
	if oldBlur then
		oldBlur:Destroy()
	end

	-- ============================================
	-- BACKGROUND BLUR ("acrylic" look behind the window)
	-- Off by default until the window is actually visible/enabled by the user,
	-- and always cleaned up on Destroy() so it never lingers in Lighting.
	-- ============================================
	self._BlurEnabled = false
	local blurEffect = Instance.new("BlurEffect")
	blurEffect.Name = "VaxorinBlur"
	blurEffect.Size = 0
	blurEffect.Enabled = true
	blurEffect.Parent = Lighting
	self._Maid:Give(blurEffect)
	self._BlurEffect = blurEffect

	local function applyBlurTarget()
		local targetSize = (self._BlurEnabled and self._Visible and not self._Minimized) and 14 or 0
		Tween.Play(blurEffect, { Size = targetSize }, { Time = 0.25 })
	end
	self._ApplyBlurTarget = applyBlurTarget

	-- Create main ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "Vaxorin"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	-- Maximum practical layering for game-created UI. When the executor exposes
	-- gethui/get_hidden_gui, use that container so CyberUI sits above normal
	-- PlayerGui ScreenGuis. 2147483647 is the maximum signed DisplayOrder.
	screenGui.DisplayOrder = data.DisplayOrder or 2147483647
	screenGui.IgnoreGuiInset = data.IgnoreGuiInset ~= false
	pcall(function()
		screenGui.ScreenInsets = Enum.ScreenInsets.None
	end)
	screenGui.Parent = topGuiParent
	self._Maid:Give(screenGui)

	-- Optional "top-most" mode: hide Roblox's normal in-game CoreGui so
	-- CyberUI remains above chat, player list, backpack, health, emotes, etc.
	-- The Roblox pause/menu layer itself cannot be covered by game UI.
	self._CoreUIState = nil
	if data.TopMost ~= false and data.HideCoreUI ~= false then
		local StarterGui = game:GetService("StarterGui")
		local GuiService = game:GetService("GuiService")
		local coreTypes = {
			Enum.CoreGuiType.PlayerList,
			Enum.CoreGuiType.Health,
			Enum.CoreGuiType.Backpack,
			Enum.CoreGuiType.Chat,
			Enum.CoreGuiType.EmotesMenu,
			Enum.CoreGuiType.SelfView,
			Enum.CoreGuiType.Captures,
			Enum.CoreGuiType.AvatarSwitcher,
		}
		self._CoreUIState = { Topbar = nil, Types = {} }
		for _, coreType in coreTypes do
			local ok, enabled = pcall(function()
				return StarterGui:GetCoreGuiEnabled(coreType)
			end)
			if ok then
				table.insert(self._CoreUIState.Types, { Type = coreType, Enabled = enabled })
				pcall(function() StarterGui:SetCoreGuiEnabled(coreType, false) end)
			end
		end
		pcall(function()
			self._CoreUIState.Topbar = true
			StarterGui:SetCore("TopbarEnabled", false)
		end)
		self._Maid:Give(function()
			for _, entry in self._CoreUIState and self._CoreUIState.Types or {} do
				pcall(function() StarterGui:SetCoreGuiEnabled(entry.Type, entry.Enabled) end)
			end
			if self._CoreUIState and self._CoreUIState.Topbar then
				pcall(function() StarterGui:SetCore("TopbarEnabled", true) end)
			end
		end)
		pcall(function()
			GuiService.GuiNavigationEnabled = true
		end)
	end

	local windowName = data.Name or data.Title or GUI_NAME
	local windowSubtitle = data.Subtitle or data.Description or nil -- nil = don't render a subtitle at all
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
	local topBarHeight = Theme.TopBarHeight or 82
	local infoBarHeight = 0 -- Vaxorin keeps the content area clean; optional info bar remains available internally

	-- Resize limits
	local minWindowSize = Vector2.new(640, 440)
	local maxWindowSize = Vector2.new(1180, 720)

	-- Keep the default window comfortably inside the current viewport. This is
	-- especially important on small emulator resolutions where a fixed desktop
	-- size can otherwise consume the entire screen.
	local camera = workspace.CurrentCamera
	local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
	local effectiveMinSize = Vector2.new(
		math.min(minWindowSize.X, viewport.X * 0.76),
		math.min(minWindowSize.Y, viewport.Y * 0.76)
	)
	local viewportMax = Vector2.new(
		viewport.X * 0.84,
		viewport.Y * 0.84
	)
	maxWindowSize = Vector2.new(
		math.max(effectiveMinSize.X, math.min(maxWindowSize.X, viewportMax.X)),
		math.max(effectiveMinSize.Y, math.min(maxWindowSize.Y, viewportMax.Y))
	)
	windowSize = Vector2.new(
		math.clamp(windowSize.X, effectiveMinSize.X, maxWindowSize.X),
		math.clamp(windowSize.Y, effectiveMinSize.Y, maxWindowSize.Y)
	)

	-- ============================================
	-- LOADING SCREEN
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
		Text = windowSubtitle or "Welcome to " .. windowName,
		TextColor3 = library.Theme.TextMuted,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = loadingFrame,
	})

	local loadingVersion = Helpers.CreateLabel({
		Name = "LoadingVersion",
		Size = UDim2.new(1, -44, 0, 20),
		Position = UDim2.fromOffset(20, 62),
		Text = VERSION,
		TextColor3 = library.Theme.TextMuted,
		TextSize = 12,
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
		BackgroundTransparency = 0.03,
		Visible = false,
		Parent = screenGui,
	})
	Helpers.Corner(main, Theme.CornerRadius)
	local mainCorner = main:FindFirstChildOfClass("UICorner")
	local mainStroke = Helpers.Stroke(main, library.Theme.Border, 1)
	main.ClipsDescendants = true

	-- ============================================
	-- DROP SHADOW
	-- Parented as a sibling (not a child) of `main`, since `main` clips
	-- descendants and would cut the shadow off. Position/size stay in sync
	-- with `main` through cheap event-driven bindings, not a per-frame loop.
	-- ============================================
	local shadow = Instance.new("ImageLabel")
	shadow.Name = "MainShadow"
	shadow.BackgroundTransparency = 1
	shadow.Image = SHADOW_IMAGE
	shadow.ImageColor3 = Color3.new(0, 0, 0)
	shadow.ImageTransparency = 0.45
	shadow.ScaleType = Enum.ScaleType.Slice
	shadow.SliceCenter = SHADOW_SLICE_CENTER
	shadow.ZIndex = 0
	shadow.Parent = screenGui

	local function syncShadow()
		shadow.AnchorPoint = main.AnchorPoint
		shadow.Position = main.Position
		shadow.Size = UDim2.new(main.Size.X.Scale, main.Size.X.Offset + 46, main.Size.Y.Scale, main.Size.Y.Offset + 46)
		shadow.Visible = main.Visible
	end
	syncShadow()
	self._Maid:GiveTask(main:GetPropertyChangedSignal("Position"):Connect(syncShadow))
	self._Maid:GiveTask(main:GetPropertyChangedSignal("Size"):Connect(syncShadow))
	self._Maid:GiveTask(main:GetPropertyChangedSignal("Visible"):Connect(syncShadow))
	self._Maid:Give(shadow)

	-- Subtle Vaxorin ambient glow. It is intentionally restrained: a soft
	-- accent halo around the shell rather than a neon outline.
	local ambientGlow = Instance.new("Frame")
	ambientGlow.Name = "AmbientGlow"
	ambientGlow.BackgroundTransparency = 1
	ambientGlow.BorderSizePixel = 0
	ambientGlow.ZIndex = 0
	ambientGlow.Parent = screenGui
	Helpers.Corner(ambientGlow, Theme.CornerRadius + 5)
	local ambientStroke = Helpers.Stroke(ambientGlow, library.Theme.Accent, 4)
	ambientStroke.Transparency = 0.88
	local function syncAmbientGlow()
		ambientGlow.AnchorPoint = main.AnchorPoint
		ambientGlow.Position = main.Position
		ambientGlow.Size = UDim2.new(main.Size.X.Scale, main.Size.X.Offset + 10, main.Size.Y.Scale, main.Size.Y.Offset + 10)
		ambientGlow.Visible = main.Visible
	end
	syncAmbientGlow()
	self._Maid:GiveTask(main:GetPropertyChangedSignal("Position"):Connect(syncAmbientGlow))
	self._Maid:GiveTask(main:GetPropertyChangedSignal("Size"):Connect(syncAmbientGlow))
	self._Maid:GiveTask(main:GetPropertyChangedSignal("Visible"):Connect(syncAmbientGlow))
	self._Maid:Give(ambientGlow)

	-- A restrained accent edge: visible at close range, never a neon outline.
	local glowStroke = Instance.new("UIStroke")
	glowStroke.Name = "AccentGlow"
	glowStroke.Color = library.Theme.Accent
	glowStroke.Thickness = 1
	glowStroke.Transparency = 0.58
	glowStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	glowStroke.Parent = main
	self._Maid:Give(glowStroke)

	-- Background Image
	local backgroundImage = Instance.new("ImageLabel")
	backgroundImage.AnchorPoint = Vector2.new(0, 0)
	backgroundImage.Position = UDim2.new(0, 0, 0, 0)
	backgroundImage.Name = "BackgroundImage"
	backgroundImage.Size = UDim2.fromScale(1, 1)
	backgroundImage.BackgroundTransparency = 1
	backgroundImage.Image = data.BackgroundImage or ""
	backgroundImage.ImageTransparency = 0.66
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
	overlay.BackgroundTransparency = 0.56
	overlay.BorderSizePixel = 0
	overlay.ZIndex = 1
	overlay.Parent = main
	Helpers.Corner(overlay, Theme.CornerRadius)

	-- ============================================
	-- QUIET BACKDROP
	-- No floating circles, scanlines, or decorative geometry. The background
	-- image and a restrained vignette do the visual work.
	-- ============================================
	local atmosphere = Instance.new("Frame")
	atmosphere.Name = "Vignette"
	atmosphere.Size = UDim2.fromScale(1, 1)
	atmosphere.BackgroundTransparency = 0.94
	atmosphere.BackgroundColor3 = library.Theme.Background
	atmosphere.BorderSizePixel = 0
	atmosphere.ZIndex = 2
	atmosphere.Parent = main
	Helpers.Corner(atmosphere, Theme.CornerRadius)

	local atmosphereGradient = Instance.new("UIGradient")
	atmosphereGradient.Name = "VignetteGradient"
	atmosphereGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, library.Theme.Background),
		ColorSequenceKeypoint.new(0.48, Color3.new(1, 1, 1)),
		ColorSequenceKeypoint.new(1, library.Theme.Background),
	})
	atmosphereGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.12),
		NumberSequenceKeypoint.new(0.5, 0.92),
		NumberSequenceKeypoint.new(1, 0.12),
	})
	atmosphereGradient.Rotation = 0
	atmosphereGradient.Parent = atmosphere

	-- ============================================
	-- TOP BAR
	-- A clean product header with a fixed control zone. The left content can
	-- grow, but it can never occupy the close/minimize area.
	-- ============================================
	local topBar = Helpers.CreateFrame({
		Name = "TopBar",
		Size = UDim2.new(1, 0, 0, topBarHeight),
		Position = UDim2.fromOffset(0, 0),
		BackgroundColor3 = library.Theme.Secondary,
		BackgroundTransparency = 0.015,
		Active = true,
		Selectable = true,
		Parent = main,
	})
	topBar.ZIndex = 20
	local topBarCorner = Helpers.Corner(topBar, Theme.CornerRadius)

	local topBarGradient = Instance.new("UIGradient")
	topBarGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, library.Theme.Secondary),
		ColorSequenceKeypoint.new(1, library.Theme.Background),
	})
	topBarGradient.Rotation = 0
	topBarGradient.Parent = topBar

	local topDivider = Instance.new("Frame")
	topDivider.Name = "Divider"
	topDivider.Size = UDim2.new(1, 0, 0, 1)
	topDivider.Position = UDim2.new(0, 0, 1, -1)
	topDivider.BackgroundColor3 = library.Theme.Border
	topDivider.BackgroundTransparency = 0.15
	topDivider.BorderSizePixel = 0
	topDivider.ZIndex = 30
	topDivider.Parent = topBar

	local logoSize = Theme.LogoSize or 50
	local logoAsset = if data.Logo == nil or data.Logo == LEGACY_LOGO then Vaxorin_Logo else data.Logo

	local brand = Helpers.CreateFrame({
		Name = "Brand",
		Size = UDim2.new(0, 370, 1, 0),
		Position = UDim2.fromOffset(18, 0),
		BackgroundTransparency = 1,
		Parent = topBar,
	})

	local logoFrame = Helpers.CreateFrame({
		Name = "LogoFrame",
		Size = UDim2.fromOffset(logoSize + 4, logoSize + 4),
		Position = UDim2.new(0, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = library.Theme.Background,
		Parent = brand,
	})
	Helpers.Corner(logoFrame, 13)
	local logoStroke = Helpers.Stroke(logoFrame, library.Theme.BorderStrong or library.Theme.Border, 1)
	local logoAccentStroke = Helpers.Stroke(logoFrame, library.Theme.Accent, 1)
	logoAccentStroke.Transparency = 0.62

	local logoImage = Instance.new("ImageLabel")
	logoImage.Name = "Logo"
	logoImage.BackgroundTransparency = 1
	logoImage.Size = UDim2.fromScale(1, 1)
	logoImage.Position = UDim2.fromScale(0.5, 0.5)
	logoImage.AnchorPoint = Vector2.new(0.5, 0.5)
	logoImage.Image = logoAsset
	logoImage.ScaleType = Enum.ScaleType.Fit
	logoImage.ZIndex = 31
	logoImage.Parent = logoFrame
	Helpers.Corner(logoImage, 12)

	local titleContainer = Helpers.CreateFrame({
		Name = "TitleContainer",
		Size = UDim2.new(1, -(logoSize + 18), 1, 0),
		Position = UDim2.new(0, logoSize + 18, 0, 0),
		BackgroundTransparency = 1,
		Parent = brand,
	})
	local titleLayout = Instance.new("UIListLayout")
	titleLayout.FillDirection = Enum.FillDirection.Vertical
	titleLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	titleLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	titleLayout.Padding = UDim.new(0, 1)
	titleLayout.Parent = titleContainer

	local subtitle: TextLabel? = nil
	if windowSubtitle and windowSubtitle ~= "" then
		subtitle = Helpers.CreateLabel({
			Name = "Subtitle",
			Size = UDim2.new(1, 0, 0, 20),
			Text = windowSubtitle,
			Font = Theme.Font,
			TextColor3 = library.Theme.Accent,
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = titleContainer,
		})
		subtitle.ZIndex = 31
	end

	local title = Helpers.CreateLabel({
		Name = "Title",
		Size = UDim2.new(1, 0, 0, 34),
		Text = windowName,
		Font = Theme.FontBold,
		TextSize = 27,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = library.Theme.Text,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = titleContainer,
	})
	title.ZIndex = 31

	local controlWidth = showWindowControls and 112 or 20
	local headerLeftReserved = 390
	local headerRightReserved = controlWidth + 30
	local badgeHolder = Helpers.CreateFrame({
		Name = "Badges",
		Size = UDim2.new(1, -(headerLeftReserved + headerRightReserved), 1, 0),
		Position = UDim2.fromOffset(headerLeftReserved, 0),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Parent = topBar,
	})
	badgeHolder.ZIndex = 31

	local badgeLayout = Instance.new("UIListLayout")
	badgeLayout.FillDirection = Enum.FillDirection.Horizontal
	badgeLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	badgeLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	badgeLayout.Padding = UDim.new(0, 10)
	badgeLayout.Parent = badgeHolder

	local badgeData = data.Badges or {
		{ Text = "Vaxorin", Color = library.Theme.Accent },
		{ Text = VERSION, Color = library.Theme.AccentAlt },
	}

	for i, badge in badgeData do
		local color = badge.Color or library.Theme.Accent
		local pill = Helpers.CreateFrame({
			Name = "Badge" .. i,
			Size = UDim2.new(0, 0, 0, 28),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundColor3 = color,
			BackgroundTransparency = 0.9,
			Parent = badgeHolder,
		})
		pill.ZIndex = 32
		Helpers.Corner(pill, 7)
		local badgeStroke = Helpers.Stroke(pill, color, 1)
		badgeStroke.Transparency = 0.08
		local badgeGlow = Helpers.Stroke(pill, color, 2)
		badgeGlow.Transparency = 0.88
		Helpers.Padding(pill, 10, 4)
		local badgeLabel = Helpers.CreateLabel({
			Name = "Label",
			Size = UDim2.new(0, 0, 1, 0),
			AutomaticSize = Enum.AutomaticSize.X,
			Text = badge.Text,
			Font = Theme.FontBold,
			TextSize = 12,
			TextColor3 = color,
			TextXAlignment = Enum.TextXAlignment.Center,
			Parent = pill,
		})
		badgeLabel.ZIndex = 33
	end

	local minimizeButton, closeButton
	if showWindowControls then
		local controls = Helpers.CreateFrame({
			Name = "WindowControls",
			Size = UDim2.fromOffset(104, 46),
			Position = UDim2.new(1, -14, 0.5, 0),
			AnchorPoint = Vector2.new(1, 0.5),
			BackgroundTransparency = 1,
			Parent = topBar,
		})
		controls.ZIndex = 34
		local controlLayout = Instance.new("UIListLayout")
		controlLayout.FillDirection = Enum.FillDirection.Horizontal
		controlLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
		controlLayout.VerticalAlignment = Enum.VerticalAlignment.Center
		controlLayout.Padding = UDim.new(0, 8)
		controlLayout.Parent = controls

		minimizeButton = Instance.new("TextButton")
		minimizeButton.Name = "Minimize"
		minimizeButton.Size = UDim2.fromOffset(44, 44)
		minimizeButton.BackgroundColor3 = library.Theme.Background
		minimizeButton.BackgroundTransparency = 0.05
		minimizeButton.Text = "—"
		minimizeButton.Font = Theme.FontBold
		minimizeButton.TextSize = 18
		minimizeButton.TextColor3 = library.Theme.TextMuted
		minimizeButton.AutoButtonColor = false
		minimizeButton.ZIndex = 35
		minimizeButton.Parent = controls
		Helpers.Corner(minimizeButton, 10)
		Helpers.Stroke(minimizeButton, library.Theme.Border, 1)

		closeButton = Instance.new("TextButton")
		closeButton.Name = "Close"
		closeButton.Size = UDim2.fromOffset(44, 44)
		closeButton.BackgroundColor3 = library.Theme.Background
		closeButton.BackgroundTransparency = 0.05
		closeButton.Text = "×"
		closeButton.Font = Theme.Font
		closeButton.TextSize = 24
		closeButton.TextColor3 = library.Theme.TextMuted
		closeButton.AutoButtonColor = false
		closeButton.ZIndex = 35
		closeButton.Parent = controls
		Helpers.Corner(closeButton, 10)
		Helpers.Stroke(closeButton, library.Theme.Border, 1)

		self._Maid:GiveTask(closeButton.MouseEnter:Connect(function()
			Tween.Play(closeButton, { BackgroundColor3 = Color3.fromRGB(130, 45, 68), TextColor3 = Color3.new(1, 1, 1) }, { Time = 0.12 })
		end))
		self._Maid:GiveTask(closeButton.MouseLeave:Connect(function()
			Tween.Play(closeButton, { BackgroundColor3 = library.Theme.Background, TextColor3 = library.Theme.TextMuted }, { Time = 0.12 })
		end))
		self._Maid:GiveTask(minimizeButton.MouseEnter:Connect(function()
			Tween.Play(minimizeButton, { BackgroundColor3 = library.Theme.SurfaceHover, TextColor3 = library.Theme.Text }, { Time = 0.12 })
		end))
		self._Maid:GiveTask(minimizeButton.MouseLeave:Connect(function()
			Tween.Play(minimizeButton, { BackgroundColor3 = library.Theme.Background, TextColor3 = library.Theme.TextMuted }, { Time = 0.12 })
		end))
	end

	-- ============================================
	-- FLOATING BUTTON
	-- ============================================
	local floatingButton = Instance.new("ImageButton")
	floatingButton.Name = "FloatingToggle"
	floatingButton.Size = UDim2.fromOffset(48, 48)
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
	Helpers.Corner(floatingButton, 10)
	Helpers.Stroke(floatingButton, library.Theme.Accent, 1.5)

	self._Maid:GiveTask(floatingButton.MouseEnter:Connect(function()
		Tween.Play(floatingButton, { BackgroundTransparency = 0 }, { Time = 0.15 })
	end))
	self._Maid:GiveTask(floatingButton.MouseLeave:Connect(function()
		Tween.Play(floatingButton, { BackgroundTransparency = 0.1 }, { Time = 0.15 })
	end))

	-- Drag-vs-click distinction: only treat it as a "toggle" click if the pointer
	-- barely moved. Previously any drag would also fire SetVisible(true) on release.
	local FLOAT_CLICK_THRESHOLD = 4
	local floatMovedDistance = 0

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
			floatMovedDistance = 0
		end
	end))

	self._Maid:GiveTask(UserInputService.InputChanged:Connect(function(input)
		if not self._FloatDragging or self._FloatDragInputType == nil then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			local delta = input.Position - self._FloatDragStart
			floatMovedDistance = delta.Magnitude
			floatingButton.Position = UDim2.new(
				self._FloatStart.X.Scale,
				self._FloatStart.X.Offset + delta.X,
				self._FloatStart.Y.Scale,
				self._FloatStart.Y.Offset + delta.Y
			)
		end
	end))

	self._Maid:GiveTask(UserInputService.InputEnded:Connect(function(input)
		if self._FloatDragInputType ~= nil and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			self._FloatDragging = false
			self._FloatDragInputType = nil
			if floatMovedDistance <= FLOAT_CLICK_THRESHOLD then
				playClick()
				self:SetVisible(true)
			end
		end
	end))

	self._Maid:Give(floatingButton)
	self._FloatingButton = floatingButton

	-- ============================================
	-- WATERMARK (compact draggable FPS / Ping / Uptime pill)
	-- Off by default, toggled from Options -> General.
	-- ============================================
	self._WatermarkEnabled = false

	local watermark = Helpers.CreateFrame({
		Name = "Watermark",
		Size = UDim2.new(0, 0, 0, 30),
		AutomaticSize = Enum.AutomaticSize.X,
		Position = UDim2.new(0.5, 0, 0, topBarHeight + 16),
	AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = library.Theme.Secondary,
		BackgroundTransparency = 0.1,
		Visible = false,
		Parent = screenGui,
	})
	watermark.ZIndex = 40
	Helpers.Corner(watermark, 9)
	local watermarkStroke = Helpers.Stroke(watermark, library.Theme.Border, 1)
	Helpers.Padding(watermark, 12, 0)

	local watermarkLayout = Instance.new("UIListLayout")
	watermarkLayout.FillDirection = Enum.FillDirection.Horizontal
	watermarkLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	watermarkLayout.Padding = UDim.new(0, 12)
	watermarkLayout.Parent = watermark

	local function watermarkStat(labelText: string)
		local lbl = Helpers.CreateLabel({
			Name = labelText:gsub("[^%w]", "") .. "Stat",
			Size = UDim2.new(0, 0, 1, 0),
			AutomaticSize = Enum.AutomaticSize.X,
			Text = labelText,
			Font = Theme.FontBold,
			TextSize = 12,
			TextColor3 = library.Theme.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = watermark,
		})
		return lbl
	end

	local watermarkDot = Instance.new("Frame")
	watermarkDot.Name = "AccentDot"
	watermarkDot.Size = UDim2.fromOffset(6, 6)
	watermarkDot.BackgroundColor3 = library.Theme.Accent
	watermarkDot.BorderSizePixel = 0
	watermarkDot.Parent = watermark
	Helpers.Corner(watermarkDot, 999)

	local watermarkTitle = watermarkStat(windowName)
	watermarkTitle.TextColor3 = library.Theme.Accent
	local watermarkFps = watermarkStat("60 FPS")
	local watermarkPing = watermarkStat("0 ms")
	local watermarkUptime = watermarkStat("00:00:00")

	-- Simple drag support, matching the floating button's behavior.
	local wmDragging = false
	local wmDragStart = Vector2.new()
	local wmStart = UDim2.new()
	local wmDragInputType = nil :: Enum.UserInputType?

	self._Maid:GiveTask(watermark.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			wmDragging = true
			wmDragStart = input.Position
			wmStart = watermark.Position
			wmDragInputType = input.UserInputType
		end
	end))
	self._Maid:GiveTask(UserInputService.InputChanged:Connect(function(input)
		if not wmDragging or wmDragInputType == nil then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			local delta = input.Position - wmDragStart
			watermark.Position = UDim2.new(
				wmStart.X.Scale, wmStart.X.Offset + delta.X,
				wmStart.Y.Scale, wmStart.Y.Offset + delta.Y
			)
		end
	end))
	self._Maid:GiveTask(UserInputService.InputEnded:Connect(function(input)
		if wmDragInputType ~= nil and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			wmDragging = false
			wmDragInputType = nil
		end
	end))

	local wmFrameCount = 0
	local wmFrameAccumulator = 0
	local wmRefreshAccumulator = 0

	self._Maid:GiveTask(RunService.Heartbeat:Connect(function(dt)
		if not self._WatermarkEnabled then
			return
		end
		wmFrameCount += 1
		wmFrameAccumulator += dt
		wmRefreshAccumulator += dt

		if wmRefreshAccumulator >= WATERMARK_REFRESH_INTERVAL then
			local fps = wmFrameAccumulator > 0 and math.round(wmFrameCount / wmFrameAccumulator) or 0
			wmFrameCount = 0
			wmFrameAccumulator = 0
			wmRefreshAccumulator = 0

			watermarkFps.Text = tostring(fps) .. " FPS"

			local ok, pingMs = pcall(function()
				local network = Stats.Network
				local ping = network:FindFirstChild("ServerStatsItem") and network.ServerStatsItem:FindFirstChild("Data Ping")
				return ping and math.round(ping:GetValue()) or 0
			end)
			watermarkPing.Text = (ok and pingMs or 0) .. " ms"

			local uptime = os.clock() - self._StartupTime
			local hours = math.floor(uptime / 3600)
			local minutes = math.floor((uptime % 3600) / 60)
			local seconds = math.floor(uptime % 60)
			watermarkUptime.Text = string.format("%02d:%02d:%02d", hours, minutes, seconds)
		end
	end))

	self._Maid:Give(watermark)
	self._Watermark = watermark

	function self:SetWatermarkEnabled(enabled: boolean)
		self._WatermarkEnabled = enabled
		watermark.Visible = enabled
	end

	-- ============================================
	-- WINDOW DRAGGING
	-- ============================================
	local dragging = false
	local dragStart = Vector2.new()
	local windowStart = UDim2.new()
	local dragInputType = nil :: Enum.UserInputType?

	self._Maid:GiveTask(topBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			windowStart = main.Position
			dragInputType = input.UserInputType
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

	-- ============================================
	-- RESIZE HANDLE
	-- ============================================
	local resizeHandle = Instance.new("Frame")
	resizeHandle.Name = "ResizeHandle"
	resizeHandle.Size = UDim2.fromOffset(16, 16)
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
		if self._Minimized then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			resizing = true
			resizeStart = input.Position
			sizeStart = main.Size
			resizeInputType = input.UserInputType
		end
	end))

	self._Maid:GiveTask(UserInputService.InputChanged:Connect(function(input)
		if not resizing or resizeInputType == nil then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			local delta = input.Position - resizeStart
			local newX = math.clamp(sizeStart.X.Offset + delta.X, minWindowSize.X, maxWindowSize.X)
			local newY = math.clamp(sizeStart.Y.Offset + delta.Y, minWindowSize.Y, maxWindowSize.Y)
			main.Size = UDim2.fromOffset(newX, newY)
			-- Keep windowSize in sync so un-minimizing restores the resized dimensions
			-- instead of snapping back to the original startup size.
			windowSize = Vector2.new(newX, newY)
		end
	end))

	self._Maid:GiveTask(UserInputService.InputEnded:Connect(function(input)
		if resizeInputType ~= nil and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			resizing = false
			resizeInputType = nil
		end
	end))

	self._Maid:GiveTask(resizeHandle.MouseEnter:Connect(function()
		for _, line in resizeHandle:GetChildren() do
			Tween.Play(line, { BackgroundColor3 = library.Theme.Accent }, { Time = 0.12 })
		end
	end))
	self._Maid:GiveTask(resizeHandle.MouseLeave:Connect(function()
		for _, line in resizeHandle:GetChildren() do
			Tween.Play(line, { BackgroundColor3 = library.Theme.TextMuted }, { Time = 0.12 })
		end
	end))

	self._ResizeHandle = resizeHandle

	-- ============================================
	-- CONTENT AREA
	-- ============================================
	local contentArea = Helpers.CreateFrame({
		Name = "ContentArea",
		Size = UDim2.new(1, 0, 1, -topBarHeight),
		Position = UDim2.new(0, 0, 0, topBarHeight),
		BackgroundTransparency = 1,
		Parent = main,
	})

	-- Sidebar
	local sidebar = Helpers.CreateFrame({
		Name = "Sidebar",
		Size = UDim2.new(0, Theme.SidebarWidth, 1, 0),
		Position = UDim2.fromOffset(0, 0),
		BackgroundColor3 = library.Theme.Secondary,
		BackgroundTransparency = 0.01,
		Parent = contentArea,
	})
	local sidebarCorner = Helpers.Corner(sidebar, Theme.CornerRadius)
	sidebar.ClipsDescendants = true
	Helpers.Padding(sidebar, 16)

	local sidebarDivider = Instance.new("Frame")
	sidebarDivider.Name = "Divider"
	sidebarDivider.Size = UDim2.new(0, 1, 1, -32)
	sidebarDivider.Position = UDim2.new(1, 0, 0, 16)
	sidebarDivider.BackgroundColor3 = library.Theme.Border
	sidebarDivider.BackgroundTransparency = 0.15
	sidebarDivider.BorderSizePixel = 0
	sidebarDivider.ZIndex = 4
	sidebarDivider.Parent = sidebar

	local navLabel = Helpers.CreateLabel({
		Name = "NavigationLabel",
		Size = UDim2.new(1, 0, 0, 16),
		Position = UDim2.new(0, 0, 0, if showSearch then 50 else 8),
		Text = "NAVIGATION",
		Font = Theme.FontBold,
		TextSize = 10,
		TextColor3 = library.Theme.TextMuted,
		TextTransparency = 0.12,
		Parent = sidebar,
	})

	local searchBox
	local searchTop = 0
	if showSearch then
		local searchHolder = Helpers.CreateFrame({
			Name = "SearchHolder",
			Size = UDim2.new(1, 0, 0, 44),
			Position = UDim2.fromOffset(0, 0),
			BackgroundColor3 = library.Theme.Background,
			BackgroundTransparency = 0.02,
			Parent = sidebar,
		})
		Helpers.Corner(searchHolder, Theme.CornerRadiusSmall)
		Helpers.Stroke(searchHolder, library.Theme.Border, 1)

		local searchIcon = Helpers.CreateLabel({
			Name = "Icon",
			Size = UDim2.fromOffset(22, 44),
			Position = UDim2.fromOffset(10, 0),
			Text = "⌕",
			Font = Theme.FontBold,
			TextSize = 20,
			TextColor3 = library.Theme.TextMuted,
			TextXAlignment = Enum.TextXAlignment.Center,
			Parent = searchHolder,
		})

		searchBox = Instance.new("TextBox")
		searchBox.Name = "SearchBox"
		searchBox.Size = UDim2.new(1, -46, 1, 0)
		searchBox.Position = UDim2.fromOffset(40, 0)
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
		searchTop = 68
	else
		searchTop = 28
	end

	local footerHeight = 82
	local tabList = Helpers.CreateFrame({
		Name = "TabList",
		Size = UDim2.new(1, 0, 1, -(searchTop + footerHeight + 12)),
		Position = UDim2.new(0, 0, 0, searchTop),
		BackgroundTransparency = 1,
		Parent = sidebar,
	})
	local tabLayout = Helpers.ListLayout(tabList, 5)
	tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left

	local footer = Helpers.CreateFrame({
		Name = "Footer",
		Size = UDim2.new(1, 0, 0, footerHeight),
		Position = UDim2.new(0, 0, 1, -footerHeight),
		BackgroundColor3 = library.Theme.Background,
		BackgroundTransparency = 0.03,
		Parent = sidebar,
	})
	Helpers.Corner(footer, Theme.CornerRadiusSmall)
	Helpers.Stroke(footer, library.Theme.Border, 1)

	local avatarImage = Instance.new("ImageLabel")
	avatarImage.Name = "Avatar"
	avatarImage.Size = UDim2.fromOffset(44, 44)
	avatarImage.Position = UDim2.fromOffset(10, 17)
	avatarImage.BackgroundTransparency = 1
	avatarImage.Image = data.Footer and data.Footer.Avatar or ""
	avatarImage.ScaleType = Enum.ScaleType.Crop
	avatarImage.Parent = footer
	Helpers.Corner(avatarImage, 22)
	Helpers.Stroke(avatarImage, library.Theme.BorderStrong or library.Theme.Border, 1)

	local footerName = Helpers.CreateLabel({
		Name = "WelcomeLabel",
		Size = UDim2.new(1, -70, 0, 20),
		Position = UDim2.fromOffset(68, 14),
		Text = "Welcome, " .. (data.Footer and data.Footer.Username or localPlayer),
		Font = Theme.FontBold,
		TextSize = 13,
		TextColor3 = library.Theme.Text,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = footer,
	})

	local footerStatus = Helpers.CreateLabel({
		Name = "Status",
		Size = UDim2.new(1, -70, 0, 18),
		Position = UDim2.fromOffset(68, 38),
		Text = "Premium User",
		Font = Theme.FontBold,
		TextSize = 12,
		TextColor3 = library.Theme.Accent,
		Parent = footer,
	})

	-- ============================================
	-- PAGES
	-- ============================================
	local pages = Instance.new("Frame")
	pages.Name = "Pages"
	pages.Position = UDim2.new(0, Theme.SidebarWidth, 0, 0)
	pages.Size = UDim2.new(1, -Theme.SidebarWidth, 1, 0)
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
		BackgroundTransparency = 1,
		Visible = false,
		Parent = main,
	})
	Helpers.Corner(infoBar, Theme.CornerRadius, { BottomLeft = true, BottomRight = true })
	local infoBarCorner = infoBar:FindFirstChildOfClass("UICorner")
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

		local itemLayout = Instance.new("UIListLayout")
		itemLayout.FillDirection = Enum.FillDirection.Horizontal
		itemLayout.VerticalAlignment = Enum.VerticalAlignment.Center
		itemLayout.Parent = container

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
			Text = initialValue,
			TextColor3 = library.Theme.Text,
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Left,
			Font = Theme.FontBold,
			Parent = container,
		})

		return { Container = container, Label = label, Value = value }
	end

	local executorName = getExecutorName()

	local uptimeRef = createInfoItem("Executor: ", executorName)
	table.insert(infoRefs, uptimeRef)
	table.insert(infoRefs, createInfoItem("v", VERSION))
	local uptimeItem = createInfoItem("Uptime: ", "00:00:00")
	table.insert(infoRefs, uptimeItem)
	local playersItem = createInfoItem("Players: ", tostring(#Players:GetPlayers()) .. " / " .. tostring(Players.MaxPlayers))
	table.insert(infoRefs, playersItem)
	local timeItem = createInfoItem("Time: ", os.date("%I:%M %p"))
	table.insert(infoRefs, timeItem)

	-- Only the dynamic items get updated on a timer; Executor/Version never change.
	local function updateInfoBar()
		local uptime = os.clock() - self._StartupTime
		local hours = math.floor(uptime / 3600)
		local minutes = math.floor((uptime % 3600) / 60)
		local seconds = math.floor(uptime % 60)
		uptimeItem.Value.Text = string.format("%02d:%02d:%02d", hours, minutes, seconds)

		playersItem.Value.Text = tostring(#Players:GetPlayers()) .. " / " .. tostring(Players.MaxPlayers)
		timeItem.Value.Text = os.date("%I:%M %p")
	end

	-- Throttled updates instead of once-per-frame: massively cheaper, and a clock
	-- doesn't need sub-second precision anyway.
	local infoBarAccumulator = 0
	self._Maid:GiveTask(RunService.Heartbeat:Connect(function(dt)
		infoBarAccumulator += dt
		if infoBarAccumulator >= INFO_BAR_REFRESH_INTERVAL then
			infoBarAccumulator = 0
			updateInfoBar()
		end
	end))

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
		topBarGradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, library.Theme.Secondary),
			ColorSequenceKeypoint.new(1, library.Theme.Background),
		})
		topDivider.BackgroundColor3 = library.Theme.Border
		logoFrame.BackgroundColor3 = library.Theme.Background
		logoStroke.Color = library.Theme.BorderStrong or library.Theme.Border
		logoAccentStroke.Color = library.Theme.Accent
		sidebar.BackgroundColor3 = library.Theme.Secondary
		sidebarDivider.BackgroundColor3 = library.Theme.Border
		navLabel.TextColor3 = library.Theme.TextMuted
		if searchBox then
			searchBox.TextColor3 = library.Theme.Text
			searchBox.PlaceholderColor3 = library.Theme.TextMuted
		end
		footer.BackgroundColor3 = library.Theme.Background
		footerStatus.TextColor3 = library.Theme.Accent
		atmosphere.BackgroundColor3 = library.Theme.Background
		atmosphereGradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, library.Theme.Background),
			ColorSequenceKeypoint.new(0.48, Color3.new(1, 1, 1)),
			ColorSequenceKeypoint.new(1, library.Theme.Background),
		})
		title.TextColor3 = library.Theme.Text
		if subtitle then
			subtitle.TextColor3 = library.Theme.Accent
		end
		if minimizeButton then
			minimizeButton.TextColor3 = library.Theme.TextMuted
		end
		if closeButton then
			closeButton.TextColor3 = library.Theme.TextMuted
		end
		mainStroke.Color = library.Theme.Border
		glowStroke.Color = library.Theme.Accent
		ambientStroke.Color = library.Theme.Accent
		watermarkStroke.Color = library.Theme.Border
		watermark.BackgroundColor3 = library.Theme.Secondary
		watermarkTitle.TextColor3 = library.Theme.Accent
		watermarkFps.TextColor3 = library.Theme.Text
		watermarkPing.TextColor3 = library.Theme.Text
		watermarkUptime.TextColor3 = library.Theme.Text

		for _, ref in infoRefs do
			if ref.Label then
				ref.Label.TextColor3 = library.Theme.TextMuted
			end
			if ref.Value then
				ref.Value.TextColor3 = library.Theme.Text
			end
		end

		for _, child in badgeHolder:GetChildren() do
			if child:IsA("Frame") and child.Name:match("^Badge") then
				local label = child:FindFirstChild("Label")
				local color = child.BackgroundColor3
				if label then
					label.TextColor3 = color
				end
			end
		end

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

	self._Maid:GiveTask(library.Theme.Changed:Connect(refreshWindowTheme))

	-- ============================================
	-- MINIMIZE / CLOSE
	-- ============================================
	if minimizeButton then
		self._Maid:GiveTask(minimizeButton.MouseButton1Click:Connect(function()
			playClick()
			self._Minimized = not self._Minimized
			if self._Minimized then
				Tween.Play(main, { Size = UDim2.fromOffset(windowSize.X, topBarHeight) }, { Time = 0.18 })
			else
				Tween.Play(main, { Size = UDim2.fromOffset(windowSize.X, windowSize.Y) }, { Time = 0.18 })
			end
			if self._ApplyBlurTarget then
				self._ApplyBlurTarget()
			end
		end))
	end

	if closeButton then
		self._Maid:GiveTask(closeButton.MouseButton1Click:Connect(function()
			playClick()
			self:SetVisible(false)
		end))
	end

	-- ============================================
	-- KEYBIND
	-- ============================================
	self._ToggleKeybind = data.ToggleKey or Enum.KeyCode.RightControl
	self._Maid:GiveTask(UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
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
	self._LoadingFrame = loadingFrame
	self._Visible = true
	self._Minimized = false
	self._StartupComplete = false
	self._OptionsTab = nil
	self.RefreshTheme = refreshWindowTheme
	self._InfoBar = infoBar
	self._InfoRefs = infoRefs
	self._ResizeHandle = resizeHandle
	self._WindowSize = function()
		return windowSize
	end
	self._CornerInstances = { mainCorner, topBarCorner, sidebarCorner, infoBarCorner }

	function self:SetCornerRadius(radius: number)
		radius = math.clamp(radius, 0, 24)
		for _, corner in self._CornerInstances do
			if corner then
				corner.CornerRadius = UDim.new(0, radius)
			end
		end
	end

	-- ============================================
	-- STARTUP COMPLETE
	-- ============================================
	self._Maid:GiveTask(task.delay(0.8, function()
		if not self.Gui then
			return
		end

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
-- METHODS
-- ============================================

function Window:SetBackgroundImage(value: string)
	local bg = self._BackgroundImage
	if not bg then
		return
	end

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
		overlay.BackgroundTransparency = math.clamp(value, 0, 1)
	end
end

function Window:_selectTab(tab: any)
	if self._ActiveTab == tab then
		return
	end

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
			if t == previousTab then
				prevIndex = i
			end
			if t == tab then
				newIndex = i
			end
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
		Options = { "Vaxorin", "Dark", "Light", "Cyber" },
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
		PlaceholderText = "rbxassetid://123456789",
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
		Name = "Background Presets",
		Options = { "Solo Leveling", "Gojo", "Sukuna", "Cid Kagenou", "None" },
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

	visualSection:CreateSlider({
		Name = "Corner Roundness",
		Min = 0,
		Max = 20,
		CurrentValue = Theme.CornerRadius,
		Rounding = 0,
		Callback = function(value: number)
			self:SetCornerRadius(value)
		end,
		Flag = "Vaxorin.Visual.CornerRadius",
	})

	visualSection:CreateToggle({
		Name = "Background Blur",
		CurrentValue = false,
		Flag = "Vaxorin.Visual.Blur",
		Callback = function(value: boolean)
			self._BlurEnabled = value
			if self._ApplyBlurTarget then
				self._ApplyBlurTarget()
			end
		end,
	})

	local generalSection = optionsTab:CreateSection("🧩 General")
	generalSection:CreateParagraph({
		Title = "Quality of life",
		Content = "Small extras that don't change how the UI looks, just how it feels.",
	})

	generalSection:CreateToggle({
		Name = "Sound Effects",
		CurrentValue = true,
		Flag = "Vaxorin.General.Sound",
		Callback = function(value: boolean)
			self._SoundEnabled = value
		end,
	})

	generalSection:CreateToggle({
		Name = "Show Watermark",
		CurrentValue = false,
		Flag = "Vaxorin.General.Watermark",
		Callback = function(value: boolean)
			self:SetWatermarkEnabled(value)
		end,
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
			local ok, err = pcall(function()
				self.Library:SaveConfiguration()
			end)
			self:Notify({
				Title = ok and "Saved" or "Save Failed",
				Content = ok and "Configuration saved successfully!" or tostring(err),
				Type = ok and "Success" or "Error",
			})
		end,
	})

	configSection:CreateButton({
		Name = "📂 Load Configuration",
		Callback = function()
			local ok, err = pcall(function()
				self.Library:LoadConfiguration()
			end)
			self:Notify({
				Title = ok and "Loaded" or "Load Failed",
				Content = ok and "Configuration loaded successfully!" or tostring(err),
				Type = ok and "Success" or "Error",
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
			local invite = "https://discord.gg/9jZTsy7Wtb"
			if setclipboard then
				setclipboard(invite)
			end

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

	if self._ApplyBlurTarget then
		self._ApplyBlurTarget()
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
