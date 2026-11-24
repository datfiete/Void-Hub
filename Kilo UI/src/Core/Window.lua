--!strict
-- Kilo UI Premium Window Engine
-- Animated boot sequence, responsive layout, animated floating island,
-- premium watermark, key-system hooks, and smooth theme transitions.
local Theme = require(script.Parent.Theme)
local Tab = require(script.Parent.Tab)
local Maid = require(script.Parent.Parent.Utils.Maid)
local Helpers = require(script.Parent.Parent.Utils.Helpers)
local Tween = require(script.Parent.Parent.Utils.Tween)
local ESPBuilder = require(script.Parent.ESPBuilder)
local ESPWorldRenderer = require(script.Parent.ESPWorldRenderer)
local LayoutVariants = require(script.Parent.LayoutVariants)

local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local Stats = game:GetService("Stats")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

local GUI_NAME = "Kilo UI"
local VERSION = "2.0"
local Kilo_Logo = "rbxassetid://135320038058277"
local LEGACY_LOGO = "rbxassetid://128228297210141"

local SHADOW_IMAGE = "rbxassetid://6014261993"
local SHADOW_SLICE_CENTER = Rect.new(49, 49, 450, 450)
local CLICK_SOUND_ID = "rbxassetid://876939830"

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
	Watermark: boolean?,
	KeySystem: { Enabled: boolean?, Key: string?, Url: string? }?,
}

export type DeveloperPanelHandle = {
	SetStats: (self: DeveloperPanelHandle, stats: { [string]: any }) -> (),
	SetContent: (self: DeveloperPanelHandle, content: string) -> (),
	Close: (self: DeveloperPanelHandle) -> (),
	Open: (self: DeveloperPanelHandle) -> (),
}

export type WindowHandle = {
	CreateTab: (self: WindowHandle, name: string) -> any,
	CreateDeveloperWindow: (self: WindowHandle, options: any?) -> DeveloperPanelHandle,
	OpenDeveloperWindow: (self: WindowHandle, options: any?) -> DeveloperPanelHandle,
	CreateESPBuilder: (self: WindowHandle, options: any?) -> any,
	CreateESPWorldRenderer: (self: WindowHandle, options: any?) -> any,
	CreateNotice: (self: WindowHandle, data: any) -> any,
	CreateStat: (self: WindowHandle, data: any) -> any,
	CreateDivider: (self: WindowHandle, data: any?) -> any,
	CreateIconButton: (self: WindowHandle, data: any?) -> any,
	CreateCard: (self: WindowHandle, data: any) -> any,
	CreateBadge: (self: WindowHandle, data: any) -> any,
	CreateProgress: (self: WindowHandle, data: any) -> any,
	CreateStatus: (self: WindowHandle, data: any) -> any,
	Notify: (self: WindowHandle, options: any) -> any,
	Destroy: (self: WindowHandle) -> (),
}

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

local function playSound(soundId: string, volume: number?)
	local ok, snd = pcall(function()
		local s = Instance.new("Sound")
		s.SoundId = soundId
		s.Volume = volume or 0.3
		s.Parent = SoundService
		s:Play()
		game:GetService("Debris"):AddItem(s, 5)
		return s
	end)
	return ok and snd or nil
end

local function cleanDisplayName(name: string): string
	local cleaned = name
	cleaned = cleaned:gsub("^%s%c+", "")
	for _, prefix in {
		"⚙️ ", "⚙ ", "🎨 ", "🧩 ", "⌨️ ", "🔧 ", "💡 ", "🌐 ", "👤 ", "⚔️ ",
		"🧠 ", "📦 ", "⭐ ", "✨ ", "💎 ", "🛠️ ", "🛠 ",
	} do
		if cleaned:sub(1, #prefix) == prefix then
			cleaned = cleaned:sub(#prefix + 1)
			break
		end
	end
	return cleaned ~= "" and cleaned or name
end

local function createMagnifier(parent: Instance, theme: any)
	local root = Helpers.CreateFrame({
		Name = "SearchIcon",
		Size = UDim2.fromOffset(22, 22),
		Position = UDim2.fromOffset(10, 11),
		BackgroundTransparency = 1,
		Parent = parent,
	})
	root.ZIndex = 3

	local ring = Helpers.CreateFrame({
		Name = "Ring",
		Size = UDim2.fromOffset(12, 12),
		Position = UDim2.fromOffset(2, 2),
		BackgroundTransparency = 1,
		Parent = root,
	})
	local stroke = Helpers.Stroke(ring, theme.TextMuted, 2)
	stroke.Transparency = 0.08
	Helpers.Corner(ring, 999)

	local handle = Helpers.CreateFrame({
		Name = "Handle",
		Size = UDim2.fromOffset(8, 2),
		Position = UDim2.fromOffset(12, 14),
		Rotation = 45,
		BackgroundColor3 = theme.TextMuted,
		BorderSizePixel = 0,
		Parent = root,
	})
	Helpers.Corner(handle, 2)

	return root, stroke, handle
end

function Window.new(library: any, options: WindowOptions?): WindowHandle
	local data = (typeof(options) == "table") and options or {}
	local self = setmetatable({
		Library = library,
		_Maid = Maid.new(),
		_Tabs = {} :: { any },
		_ActiveTab = nil :: any,
		_StartupTime = os.clock(),
		_Visible = false,
		_StartupComplete = false,
		_Minimized = false,
		_KeySystem = data.KeySystem or {},
		_WatermarkEnabled = data.Watermark ~= false,
		_Responsive = true,
		_Mobile = false,
	}, Window)

	local Players = game:GetService("Players")
	local localPlayer = Players.LocalPlayer and Players.LocalPlayer.Name or "Player"
	local userInputService = game:GetService("UserInputService")
	local runService = game:GetService("RunService")
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local sharedState = (getgenv and getgenv()) or _G

	-- Mobile detection
	local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
	self._Mobile = viewport.X < 1000 or viewport.Y < 600

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

	self._SoundEnabled = true
	local clickSound = Instance.new("Sound")
	clickSound.Name = "KiloUIClick"
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

	for _, container in { playerGui, topGuiParent } do
		if typeof(container) == "Instance" then
			for _, child in container:GetChildren() do
				if child:IsA("ScreenGui") and child.Name == "Kilo UI" then
					child:Destroy()
				end
			end
		end
	end
	local oldBlur = Lighting:FindFirstChild("KiloBlur")
	if oldBlur then
		oldBlur:Destroy()
	end

	self._BlurEnabled = false
	local blurEffect = Instance.new("BlurEffect")
	blurEffect.Name = "KiloBlur"
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

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "Kilo UI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.DisplayOrder = data.DisplayOrder or 2147483647
	screenGui.IgnoreGuiInset = data.IgnoreGuiInset ~= false
	pcall(function()
		screenGui.ScreenInsets = Enum.ScreenInsets.None
	end)
	screenGui.Parent = topGuiParent
	self._Maid:Give(screenGui)

	-- Core UI hiding
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
	local windowSubtitle = data.Subtitle or data.Description or nil
	local windowSize = data.Size or data.WindowSize or Theme.WindowSize

	if typeof(windowSize) == "UDim2" then
		windowSize = Vector2.new(windowSize.X.Offset, windowSize.Y.Offset)
	elseif typeof(windowSize) == "number" then
		windowSize = Vector2.new(windowSize, windowSize)
	elseif typeof(windowSize) ~= "Vector2" then
		windowSize = Vector2.new(820, 540)
	end

	-- Responsive: shrink on mobile
	if self._Mobile then
		windowSize = Vector2.new(
			math.clamp(windowSize.X, 560, viewport.X * 0.92),
			math.clamp(windowSize.Y, 400, viewport.Y * 0.92)
		)
	end

	local showSearch = data.ShowSearch ~= false
	local showWindowControls = data.ShowWindowControls ~= false
	local topBarHeight = Theme.TopBarHeight or 72
	local infoBarHeight = 0

	local minWindowSize = Vector2.new(640, 430)
	local maxWindowSize = Vector2.new(1180, 760)

	local camera = workspace.CurrentCamera
	local vp = camera and camera.ViewportSize or Vector2.new(1280, 720)
	local effectiveMinSize = Vector2.new(
		math.min(minWindowSize.X, vp.X * 0.76),
		math.min(minWindowSize.Y, vp.Y * 0.76)
	)
	local viewportMax = Vector2.new(vp.X * 0.82, vp.Y * 0.82)
	maxWindowSize = Vector2.new(
		math.max(effectiveMinSize.X, math.min(maxWindowSize.X, viewportMax.X)),
		math.max(effectiveMinSize.Y, math.min(maxWindowSize.Y, viewportMax.Y))
	)
	windowSize = Vector2.new(
		math.clamp(windowSize.X, effectiveMinSize.X, maxWindowSize.X),
		math.clamp(windowSize.Y, effectiveMinSize.Y, maxWindowSize.Y)
	)

	-- ============================================================
	-- PREMIUM ANIMATED BOOT SEQUENCE
	-- ============================================================
	local loadingGui = Instance.new("ScreenGui")
	loadingGui.Name = "KiloBoot"
	loadingGui.ResetOnSpawn = false
	loadingGui.IgnoreGuiInset = true
	loadingGui.DisplayOrder = 2147483647
	loadingGui.Parent = screenGui

	local bootBackdrop = Helpers.CreateFrame({ Name = "Backdrop", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(2, 3, 7), BackgroundTransparency = 0.02, Parent = loadingGui })

	-- Ambient glow pulses behind the boot card
	local bootGlow = Helpers.CreateFrame({ Name = "Glow", Size = UDim2.fromOffset(460, 460), Position = UDim2.fromScale(0.5, 0.48), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = library.Theme.Accent, BackgroundTransparency = 0.94, Parent = bootBackdrop })
	Helpers.Corner(bootGlow, 999)

	local bootCard = Helpers.CreateFrame({ Name = "Card", Size = UDim2.fromOffset(520, 320), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = library.Theme.Secondary, Parent = bootBackdrop })
	Helpers.Corner(bootCard, 24)
	local bootStroke = Helpers.Stroke(bootCard, library.Theme.BorderStrong or library.Theme.Border, 1)
	bootStroke.Transparency = 0.2

	local bootTopLine = Helpers.CreateFrame({ Name = "TopLine", Size = UDim2.new(1, -56, 0, 2), Position = UDim2.fromOffset(28, 20), BackgroundColor3 = library.Theme.Accent, Parent = bootCard })
	Helpers.Corner(bootTopLine, 2)

	local bootTitle = Helpers.CreateLabel({ Name = "Title", Size = UDim2.new(1, -56, 0, 36), Position = UDim2.fromOffset(28, 44), Text = windowName, Font = Theme.FontBold, TextSize = 30, TextColor3 = library.Theme.Text, Parent = bootCard })
	local bootSub = Helpers.CreateLabel({ Name = "Sub", Size = UDim2.new(1, -56, 0, 18), Position = UDim2.fromOffset(28, 80), Text = "PREMIUM COMMAND INTERFACE", Font = Theme.FontBold, TextSize = 10, TextColor3 = library.Theme.Accent, Parent = bootCard })
	local bootStatus = Helpers.CreateLabel({ Name = "Status", Size = UDim2.new(1, -56, 0, 22), Position = UDim2.fromOffset(28, 116), Text = "Initializing engine...", Font = Theme.Font, TextSize = 12, TextColor3 = library.Theme.TextMuted, Parent = bootCard })

	local bootTrack = Helpers.CreateFrame({ Name = "Track", Size = UDim2.new(1, -56, 0, 6), Position = UDim2.fromOffset(28, 162), BackgroundColor3 = library.Theme.Background, Parent = bootCard })
	Helpers.Corner(bootTrack, 3)
	local bootFill = Helpers.CreateFrame({ Name = "Fill", Size = UDim2.fromScale(0, 1), BackgroundColor3 = library.Theme.Accent, Parent = bootTrack })
	Helpers.Corner(bootFill, 3)

	local bootPercent = Helpers.CreateLabel({ Name = "Percent", Size = UDim2.fromOffset(70, 22), Position = UDim2.new(1, -98, 0, 182), Text = "0%", Font = Theme.FontBold, TextSize = 12, TextColor3 = library.Theme.Text, TextXAlignment = Enum.TextXAlignment.Right, Parent = bootCard })
	local bootStage = Helpers.CreateLabel({ Name = "Stage", Size = UDim2.new(1, -56, 0, 18), Position = UDim2.fromOffset(28, 210), Text = "CORE / 00", Font = Theme.FontBold, TextSize = 9, TextColor3 = library.Theme.TextMuted, Parent = bootCard })

	local bootPips = {}
	for i = 1, 5 do
		local pip = Helpers.CreateFrame({ Name = "Pip" .. i, Size = UDim2.fromOffset(54, 4), Position = UDim2.fromOffset(28 + (i - 1) * 62, 250), BackgroundColor3 = library.Theme.BorderStrong or library.Theme.Border, Parent = bootCard })
		Helpers.Corner(pip, 2)
		table.insert(bootPips, pip)
	end

	local bootFooter = Helpers.CreateLabel({ Name = "Footer", Size = UDim2.new(1, -56, 0, 18), Position = UDim2.fromOffset(28, 284), Text = "KILO UI  " .. VERSION .. "  ·  PREMIUM EDITION", Font = Theme.FontBold, TextSize = 8, TextColor3 = library.Theme.TextMuted, Parent = bootCard })

	-- Subtle glow pulse animation on boot card
	task.spawn(function()
		while bootCard and bootCard.Parent do
			Tween.Play(bootGlow, { BackgroundTransparency = 0.86 }, { Time = 2 })
			task.wait(2)
			Tween.Play(bootGlow, { BackgroundTransparency = 0.94 }, { Time = 2 })
			task.wait(2)
		end
	end)

	local bootPhases = {
		{0.16, "Mounting interface...", "CORE / 01"},
		{0.34, "Registering components...", "CORE / 02"},
		{0.55, "Building workspace...", "UI / 03"},
		{0.76, "Linking interactions...", "INPUT / 04"},
		{1.00, "System ready", "READY / 05"},
	}
	task.spawn(function()
		for index, phase in bootPhases do
			local value, status, stage = phase[1], phase[2], phase[3]
			bootStatus.Text = status
			bootStage.Text = stage
			bootPercent.Text = tostring(math.floor(value * 100)) .. "%"
			Tween.Play(bootFill, { Size = UDim2.fromScale(value, 1) }, { Time = 0.22 })
			for i, pip in bootPips do
				Tween.Play(pip, { BackgroundColor3 = if i <= index then library.Theme.Accent else (library.Theme.BorderStrong or library.Theme.Border) }, { Time = 0.14 })
			end
			task.wait(0.18)
		end
	end)
	self._BootGui = loadingGui
	self._BootCard = bootCard
	self._BootStatus = bootStatus
	self._BootFill = bootFill

	local bootstrapLoader = sharedState.KiloUI_BootstrapLoader
	sharedState.KiloUI_BootstrapLoader = nil
	if bootstrapLoader and bootstrapLoader.Parent then
		bootstrapLoader:Destroy()
	end

	-- ============================================================
	-- MAIN WINDOW FRAME
	-- ============================================================
	local main = Helpers.CreateFrame({
		Name = "Main",
		Size = UDim2.fromOffset(windowSize.X, windowSize.Y),
		Position = if data.Center ~= false then UDim2.fromScale(0.5, 0.5) else UDim2.fromOffset(40, 40),
		AnchorPoint = if data.Center ~= false then Vector2.new(0.5, 0.5) else Vector2.new(0, 0),
		BackgroundColor3 = library.Theme.Background,
		BackgroundTransparency = 0.02,
		Visible = false,
		Parent = screenGui,
	})
	Helpers.Corner(main, Theme.CornerRadius)
	local mainStroke = Helpers.Stroke(main, library.Theme.Border, 1)
	main.ClipsDescendants = true

	local shadow = Instance.new("ImageLabel")
	shadow.Name = "MainShadow"
	shadow.BackgroundTransparency = 1
	shadow.Image = SHADOW_IMAGE
	shadow.ImageColor3 = Color3.new(0, 0, 0)
	shadow.ImageTransparency = 0.5
	shadow.ScaleType = Enum.ScaleType.Slice
	shadow.SliceCenter = SHADOW_SLICE_CENTER
	shadow.ZIndex = 0
	shadow.Parent = screenGui

	local function syncShadow()
		shadow.AnchorPoint = main.AnchorPoint
		shadow.Position = main.Position
		shadow.Size = UDim2.new(main.Size.X.Scale, main.Size.X.Offset + 50, main.Size.Y.Scale, main.Size.Y.Offset + 50)
		shadow.Visible = main.Visible and not self._Minimized
	end
	syncShadow()
	self._Maid:GiveTask(main:GetPropertyChangedSignal("Position"):Connect(syncShadow))
	self._Maid:GiveTask(main:GetPropertyChangedSignal("Size"):Connect(syncShadow))
	self._Maid:GiveTask(main:GetPropertyChangedSignal("Visible"):Connect(syncShadow))
	self._Maid:Give(shadow)

	local ambientGlow = Instance.new("ImageLabel")
	ambientGlow.Name = "AmbientGlow"
	ambientGlow.BackgroundTransparency = 1
	ambientGlow.BorderSizePixel = 0
	ambientGlow.Image = SHADOW_IMAGE
	ambientGlow.ImageColor3 = library.Theme.Accent
	ambientGlow.ImageTransparency = 0.88
	ambientGlow.ScaleType = Enum.ScaleType.Slice
	ambientGlow.SliceCenter = SHADOW_SLICE_CENTER
	ambientGlow.ZIndex = 0
	ambientGlow.Parent = screenGui
	local function syncAmbientGlow()
		ambientGlow.AnchorPoint = main.AnchorPoint
		ambientGlow.Position = main.Position
		ambientGlow.Size = UDim2.new(main.Size.X.Scale, main.Size.X.Offset + 32, main.Size.Y.Scale, main.Size.Y.Offset + 32)
		ambientGlow.Visible = main.Visible and not self._Minimized
	end
	syncAmbientGlow()
	self._Maid:GiveTask(main:GetPropertyChangedSignal("Position"):Connect(syncAmbientGlow))
	self._Maid:GiveTask(main:GetPropertyChangedSignal("Size"):Connect(syncAmbientGlow))
	self._Maid:GiveTask(main:GetPropertyChangedSignal("Visible"):Connect(syncAmbientGlow))
	self._Maid:Give(ambientGlow)

	local glowStroke = Instance.new("UIStroke")
	glowStroke.Name = "AccentEdge"
	glowStroke.Color = library.Theme.Accent
	glowStroke.Thickness = 1
	glowStroke.Transparency = 0.72
	glowStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	glowStroke.Parent = main
	self._Maid:Give(glowStroke)
	self._AmbientGlow = ambientGlow

	local backgroundImage = Instance.new("ImageLabel")
	backgroundImage.AnchorPoint = Vector2.new(0, 0)
	backgroundImage.Position = UDim2.new(0, 0, 0, 0)
	backgroundImage.Name = "BackgroundImage"
	backgroundImage.Size = UDim2.fromScale(1, 1)
	backgroundImage.BackgroundTransparency = 1
	backgroundImage.Image = data.BackgroundImage or ""
	backgroundImage.ImageTransparency = 0.68
	backgroundImage.ScaleType = Enum.ScaleType.Crop
	backgroundImage.ZIndex = 0
	backgroundImage.Parent = main
	Helpers.Corner(backgroundImage, Theme.CornerRadius)
	self._BackgroundImage = backgroundImage

	local overlay = Instance.new("Frame")
	overlay.Name = "BackgroundOverlay"
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = Color3.new(0, 0, 0)
	overlay.BackgroundTransparency = 0.58
	overlay.BorderSizePixel = 0
	overlay.ZIndex = 1
	overlay.Parent = main
	Helpers.Corner(overlay, Theme.CornerRadius)

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
		NumberSequenceKeypoint.new(0, 0.14),
		NumberSequenceKeypoint.new(0.5, 0.92),
		NumberSequenceKeypoint.new(1, 0.14),
	})
	atmosphereGradient.Rotation = 0
	atmosphereGradient.Parent = atmosphere

	local topBar = Helpers.CreateFrame({
		Name = "TopBar",
		Size = UDim2.new(1, 0, 0, topBarHeight),
		Position = UDim2.fromOffset(0, 0),
		BackgroundColor3 = library.Theme.Secondary,
		BackgroundTransparency = 0.08,
		Active = true,
		Selectable = true,
		Parent = main,
	})
	topBar.ZIndex = 20
	Helpers.Corner(topBar, Theme.CornerRadius)

	local topBarGradient = Instance.new("UIGradient")
	topBarGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, library.Theme.Secondary),
		ColorSequenceKeypoint.new(0.55, library.Theme.Secondary),
		ColorSequenceKeypoint.new(1, library.Theme.Background),
	})
	topBarGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.02),
		NumberSequenceKeypoint.new(0.55, 0.06),
		NumberSequenceKeypoint.new(1, 0.16),
	})
	topBarGradient.Rotation = 0
	topBarGradient.Parent = topBar

	local topDivider = Instance.new("Frame")
	topDivider.Name = "Divider"
	topDivider.Size = UDim2.new(1, 0, 0, 1)
	topDivider.Position = UDim2.new(0, 0, 1, -1)
	topDivider.BackgroundColor3 = library.Theme.Border
	topDivider.BackgroundTransparency = 0.72
	topDivider.BorderSizePixel = 0
	topDivider.ZIndex = 30
	topDivider.Parent = topBar

	local topAccentRail = Instance.new("Frame")
	topAccentRail.Name = "AccentRail"
	topAccentRail.Size = UDim2.new(0, 220, 0, 2)
	topAccentRail.Position = UDim2.new(0, 22, 1, -3)
	topAccentRail.BackgroundColor3 = library.Theme.Accent
	topAccentRail.BackgroundTransparency = 0.14
	topAccentRail.BorderSizePixel = 0
	topAccentRail.ZIndex = 31
	topAccentRail.Parent = topBar
	local topAccentGradient = Instance.new("UIGradient")
	topAccentGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, library.Theme.Accent),
		ColorSequenceKeypoint.new(0.65, library.Theme.AccentAlt or library.Theme.Accent),
		ColorSequenceKeypoint.new(1, library.Theme.Background),
	})
	topAccentGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.75, 0.18),
		NumberSequenceKeypoint.new(1, 1),
	})
	topAccentGradient.Parent = topAccentRail

	local logoSize = Theme.LogoSize or 50
	local logoAsset = if data.Logo == nil or data.Logo == LEGACY_LOGO then Kilo_Logo else data.Logo

	local brand = Helpers.CreateFrame({
		Name = "Brand",
		Size = UDim2.new(0, 390, 1, 0),
		Position = UDim2.fromOffset(22, 0),
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
	Helpers.Corner(logoFrame, 14)
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
	logoFrame.Active = true
	logoImage.Active = true

	local discordInvite = data.DiscordLink or "https://discord.gg/kilo"
	self._Maid:GiveTask(logoFrame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			playClick()
			if setclipboard then
				pcall(setclipboard, discordInvite)
			end
			self:Notify({
				Title = "Kilo UI",
				Content = "Discord invite copied to clipboard!",
				Type = "Success",
				Duration = 3,
			})
		end
	end))

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
		TextSize = 24,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = library.Theme.Text,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = titleContainer,
	})
	title.ZIndex = 31

	local productMeta = Helpers.CreateLabel({
		Name = "ProductMeta",
		Size = UDim2.new(1, 0, 0, 13),
		Position = UDim2.fromOffset(1, 57),
		Text = "KILO UI  /  PREMIUM EDITION  /  2.0",
		Font = Theme.FontBold,
		TextSize = 9,
		TextColor3 = library.Theme.TextMuted,
		TextTransparency = 0.18,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = titleContainer,
	})
	productMeta.ZIndex = 31

	local controlWidth = showWindowControls and 112 or 0
	local headerControlGap = showWindowControls and 20 or 14
	local brandWidth = 394

	local badgeHolder = Helpers.CreateFrame({
		Name = "Badges",
		Size = UDim2.new(1, -(brandWidth + controlWidth + headerControlGap + 16), 0, 34),
		Position = UDim2.new(0, brandWidth, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundTransparency = 1,
		ClipsDescendants = false,
		Parent = topBar,
	})
	badgeHolder.ZIndex = 31

	local badgeLayout = Instance.new("UIListLayout")
	badgeLayout.FillDirection = Enum.FillDirection.Horizontal
	badgeLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	badgeLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	badgeLayout.Padding = UDim.new(0, 8)
	badgeLayout.Parent = badgeHolder

	local badgeData = data.Badges or {
		{ Text = "Kilo UI", Color = library.Theme.Accent },
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
		Helpers.Padding(pill, 9, 4)
		local badgeLabel = Helpers.CreateLabel({
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
		badgeLabel.ZIndex = 33
	end

	local minimizeButton, closeButton
	if showWindowControls then
		local controls = Helpers.CreateFrame({
			Name = "WindowControls",
			Size = UDim2.fromOffset(104, 44),
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
		minimizeButton.Size = UDim2.fromOffset(42, 42)
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
		closeButton.Size = UDim2.fromOffset(42, 42)
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

	-- ============================================================
	-- CONTENT AREA: TabList + Pages
	-- ============================================================
	local content = Helpers.CreateFrame({
		Name = "Content",
		Size = UDim2.new(1, 0, 1, -topBarHeight),
		Position = UDim2.fromOffset(0, topBarHeight),
		BackgroundTransparency = 1,
		Parent = main,
	})
	content.ZIndex = 10

	local tabList = Helpers.CreateFrame({
		Name = "TabList",
		Size = UDim2.new(0, self._Mobile and 140 or 200, 1, 0),
		BackgroundColor3 = library.Theme.Secondary,
		BackgroundTransparency = 0.05,
		Parent = content,
	})
	Helpers.Corner(tabList, Theme.CornerRadiusSmall)
	Helpers.Stroke(tabList, library.Theme.Border, 1)
	self.TabList = tabList

	local pages = Helpers.CreateFrame({
		Name = "Pages",
		Size = UDim2.new(1, -(self._Mobile and 140 or 200), 1, 0),
		Position = UDim2.fromOffset(self._Mobile and 140 or 200, 0),
		BackgroundTransparency = 1,
		Parent = content,
	})
	pages.ZIndex = 10
	self.Pages = pages

	-- ============================================================
	-- FLOATING ISLAND (minimized state)
	-- ============================================================
	local island = Instance.new("CanvasGroup")
	island.Name = "Island"
	island.Size = UDim2.fromOffset(168, 34)
	island.Position = UDim2.new(0.5, 0, 0, 10)
	island.AnchorPoint = Vector2.new(0.5, 0)
	island.BackgroundColor3 = Color3.fromRGB(20, 26, 40)
	island.BackgroundTransparency = 0
	island.BorderSizePixel = 0
	island.Visible = false
	island.ZIndex = 55
	island.Parent = screenGui
	Helpers.Corner(island, 16)
	local islandStroke = Helpers.Stroke(island, library.Theme.Border, 1)
	islandStroke.Transparency = 0.35
	self._IslandStroke = islandStroke

	local islandCompact = Helpers.CreateFrame({
		Name = "Compact",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(20, 26, 40),
		BackgroundTransparency = 0,
		Parent = island,
	})
	Helpers.Corner(islandCompact, 16)

	local islandIcon = Instance.new("ImageLabel")
	islandIcon.Name = "Icon"
	islandIcon.BackgroundTransparency = 1
	islandIcon.Size = UDim2.fromOffset(18, 18)
	islandIcon.Position = UDim2.new(0, 12, 0.5, 0)
	islandIcon.AnchorPoint = Vector2.new(0, 0.5)
	islandIcon.Image = logoAsset
	islandIcon.ScaleType = Enum.ScaleType.Fit
	islandIcon.ZIndex = 56
	islandIcon.Parent = islandCompact

	local islandTitle = Helpers.CreateLabel({
		Name = "Title",
		Size = UDim2.new(1, -70, 1, 0),
		Position = UDim2.fromOffset(36, 0),
		Text = "Kilo UI",
		Font = Theme.FontBold,
		TextSize = 12,
		TextColor3 = library.Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = islandCompact,
	})
	islandTitle.ZIndex = 56

	local bars = Helpers.CreateFrame({
		Name = "Bars",
		Size = UDim2.fromOffset(18, 16),
		Position = UDim2.new(1, -14, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundTransparency = 1,
		Parent = islandCompact,
	})
	bars.ZIndex = 56
	for i, h in ipairs({ 13, 15, 4, 4 }) do
		local bar = Instance.new("Frame")
		bar.Name = "Bar" .. i
		bar.Size = UDim2.fromOffset(3, h)
		bar.Position = UDim2.new(0, (i - 1) * 5, 0.5, 0)
		bar.AnchorPoint = Vector2.new(0, 0.5)
		bar.BackgroundColor3 = library.Theme.Accent
		bar.BorderSizePixel = 0
		bar.ZIndex = 57
		bar.Parent = bars
		Helpers.Corner(bar, 1)
	end

	local islandHit = Instance.new("TextButton")
	islandHit.Name = "Hit"
	islandHit.Size = UDim2.fromScale(1, 1)
	islandHit.BackgroundTransparency = 1
	islandHit.Text = ""
	islandHit.ZIndex = 58
	islandHit.Parent = island

	local floatingButton = islandHit
	floatingButton.Name = "FloatingToggle"
	self._FloatingButton = island
	self._FloatingIcon = islandIcon
	self._IslandTitle = islandTitle
	self._IslandBars = bars
	self._IslandCompact = islandCompact

	local islandActivityHost = Instance.new("Frame")
	islandActivityHost.Name = "ActivityHost"
	islandActivityHost.BackgroundTransparency = 1
	islandActivityHost.BorderSizePixel = 0
	islandActivityHost.ClipsDescendants = true
	islandActivityHost.Visible = false
	islandActivityHost.ZIndex = 59
	islandActivityHost.AnchorPoint = Vector2.new(0.5, 0)
	islandActivityHost.Size = UDim2.fromOffset(320, 0)
	islandActivityHost.Parent = screenGui
	self._IslandActivityHost = islandActivityHost

	local islandActivity = Instance.new("Frame")
	islandActivity.Name = "Activity"
	islandActivity.Size = UDim2.fromOffset(300, 148)
	islandActivity.Position = UDim2.new(0.5, 0, 0, 0)
	islandActivity.AnchorPoint = Vector2.new(0.5, 0)
	islandActivity.BackgroundColor3 = Color3.fromRGB(18, 24, 36)
	islandActivity.BackgroundTransparency = 0.02
	islandActivity.Visible = true
	islandActivity.ZIndex = 60
	islandActivity.Parent = islandActivityHost
	Helpers.Corner(islandActivity, 14)
	Helpers.Stroke(islandActivity, library.Theme.Border, 1)
	Helpers.Padding(islandActivity, 12)

	local actAvatar = Instance.new("ImageLabel")
	actAvatar.Name = "Avatar"
	actAvatar.Size = UDim2.fromOffset(32, 32)
	actAvatar.Position = UDim2.fromOffset(0, 0)
	actAvatar.BackgroundColor3 = library.Theme.ElementBackground
	actAvatar.BorderSizePixel = 0
	actAvatar.Image = ""
	actAvatar.ZIndex = 61
	actAvatar.Parent = islandActivity
	Helpers.Corner(actAvatar, 16)
	local lp = Players.LocalPlayer
	pcall(function()
		if lp then
			actAvatar.Image = Players:GetUserThumbnailAsync(
				lp.UserId,
				Enum.ThumbnailType.HeadShot,
				Enum.ThumbnailSize.Size48x48
			)
		end
	end)

	local actTitle = Helpers.CreateLabel({
		Name = "ActTitle",
		Size = UDim2.new(1, -100, 0, 16),
		Position = UDim2.fromOffset(40, 0),
		Text = (lp and (lp.DisplayName or lp.Name)) or tostring(localPlayer),
		Font = Theme.FontBold,
		TextSize = 13,
		TextColor3 = library.Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = islandActivity,
	})
	actTitle.ZIndex = 61

	local actGame = Helpers.CreateLabel({
		Name = "ActGame",
		Size = UDim2.new(1, -100, 0, 14),
		Position = UDim2.fromOffset(40, 16),
		Text = "Kilo UI",
		Font = Theme.Font,
		TextSize = 10,
		TextColor3 = library.Theme.TextMuted,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = islandActivity,
	})
	actGame.ZIndex = 61
	pcall(function()
		local info = MarketplaceService:GetProductInfo(game.PlaceId)
		if info and info.Name then actGame.Text = info.Name end
	end)

	local actSession = Helpers.CreateLabel({
		Name = "ActSession",
		Size = UDim2.fromOffset(64, 16),
		Position = UDim2.new(1, 0, 0, 0),
		AnchorPoint = Vector2.new(1, 0),
		Text = "0m 0s",
		Font = Theme.FontBold,
		TextSize = 11,
		TextColor3 = library.Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = islandActivity,
	})
	actSession.ZIndex = 61

	local actSessionLbl = Helpers.CreateLabel({
		Name = "ActSessionLbl",
		Size = UDim2.fromOffset(64, 12),
		Position = UDim2.new(1, 0, 0, 16),
		AnchorPoint = Vector2.new(1, 0),
		Text = "session",
		Font = Theme.Font,
		TextSize = 9,
		TextColor3 = library.Theme.TextMuted,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = islandActivity,
	})
	actSessionLbl.ZIndex = 61

	local actFpsVal = Helpers.CreateLabel({
		Name = "ActFps",
		Size = UDim2.fromOffset(90, 18),
		Position = UDim2.fromOffset(0, 42),
		Text = "— fps",
		Font = Theme.FontBold,
		TextSize = 14,
		TextColor3 = Color3.fromRGB(120, 255, 160),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = islandActivity,
	})
	actFpsVal.ZIndex = 61
	local actFpsLbl = Helpers.CreateLabel({
		Name = "ActFpsLbl",
		Size = UDim2.fromOffset(90, 12),
		Position = UDim2.fromOffset(0, 58),
		Text = "FRAME RATE",
		Font = Theme.Font,
		TextSize = 8,
		TextColor3 = library.Theme.TextMuted,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = islandActivity,
	})
	actFpsLbl.ZIndex = 61

	local actPingVal = Helpers.CreateLabel({
		Name = "ActPing",
		Size = UDim2.fromOffset(90, 18),
		Position = UDim2.fromOffset(110, 42),
		Text = "— ms",
		Font = Theme.FontBold,
		TextSize = 14,
		TextColor3 = Color3.fromRGB(120, 255, 160),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = islandActivity,
	})
	actPingVal.ZIndex = 61
	local actPingLbl = Helpers.CreateLabel({
		Name = "ActPingLbl",
		Size = UDim2.fromOffset(90, 12),
		Position = UDim2.fromOffset(110, 58),
		Text = "PING",
		Font = Theme.Font,
		TextSize = 8,
		TextColor3 = library.Theme.TextMuted,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = islandActivity,
	})
	actPingLbl.ZIndex = 61

	local chips = Helpers.CreateFrame({
		Name = "Chips",
		Size = UDim2.new(1, 0, 0, 20),
		Position = UDim2.fromOffset(0, 76),
		BackgroundTransparency = 1,
		Parent = islandActivity,
	})
	chips.ZIndex = 61
	local chipsLayout = Instance.new("UIListLayout")
	chipsLayout.FillDirection = Enum.FillDirection.Horizontal
	chipsLayout.Padding = UDim.new(0, 6)
	chipsLayout.Parent = chips

	local function makeChip(name: string, text: string): TextLabel
		local chip = Instance.new("TextLabel")
		chip.Name = name
		chip.AutomaticSize = Enum.AutomaticSize.X
		chip.Size = UDim2.fromOffset(0, 18)
		chip.BackgroundColor3 = library.Theme.ElementBackground or Color3.fromRGB(30, 30, 36)
		chip.BackgroundTransparency = 0.1
		chip.BorderSizePixel = 0
		chip.Font = Theme.Font
		chip.TextSize = 10
		chip.TextColor3 = library.Theme.Text
		chip.Text = text
		chip.ZIndex = 62
		chip.Parent = chips
		Helpers.Corner(chip, 6)
		local pad = Instance.new("UIPadding")
		pad.PaddingLeft = UDim.new(0, 8)
		pad.PaddingRight = UDim.new(0, 8)
		pad.Parent = chip
		return chip
	end
	local chipPlayers = makeChip("Players", "Players 0")
	local chipRunning = makeChip("Running", "Ready")
	local chipTab = makeChip("Tab", "Tab Home")

	local actDesc = Helpers.CreateLabel({
		Name = "ActDesc",
		Size = UDim2.new(1, 0, 0, 14),
		Position = UDim2.fromOffset(0, 100),
		Text = "Kilo UI",
		Font = Theme.Font,
		TextSize = 10,
		TextColor3 = library.Theme.TextMuted,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = islandActivity,
	})
	actDesc.ZIndex = 61

	local actHint = Helpers.CreateLabel({
		Name = "ActHint",
		Size = UDim2.new(1, 0, 0, 14),
		Position = UDim2.fromOffset(0, 118),
		Text = "Click or press RCtrl to open",
		Font = Theme.Font,
		TextSize = 10,
		TextColor3 = library.Theme.TextMuted,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = islandActivity,
	})
	actHint.ZIndex = 61

	self._IslandActivity = islandActivity
	self._IslandActStatus = chipRunning
	self._IslandActStats = actFpsVal
	self._IslandActFps = actFpsVal
	self._IslandActPing = actPingVal
	self._IslandActSession = actSession
	self._IslandActPlayers = chipPlayers
	self._IslandActTab = chipTab
	self._IslandActGame = actGame
	self._IslandActAvatar = actAvatar
	self._IslandSessionStart = os.clock()

	local classicBtn = Instance.new("ImageButton")
	classicBtn.Name = "ClassicOpen"
	classicBtn.Size = UDim2.fromOffset(50, 50)
	classicBtn.Position = UDim2.new(0, 43, 0.5, 0)
	classicBtn.AnchorPoint = Vector2.new(0, 0.5)
	classicBtn.BackgroundColor3 = library.Theme.Background
	classicBtn.BackgroundTransparency = 0
	classicBtn.Image = ""
	classicBtn.AutoButtonColor = false
	classicBtn.Visible = false
	classicBtn.ZIndex = 55
	classicBtn.Parent = screenGui
	Helpers.Corner(classicBtn, 12)
	local classicStroke = Helpers.Stroke(classicBtn, library.Theme.Border, 1.3)
	local classicIcon = Instance.new("ImageLabel")
	classicIcon.BackgroundTransparency = 1
	classicIcon.Size = UDim2.fromOffset(23, 23)
	classicIcon.Position = UDim2.fromScale(0.5, 0.5)
	classicIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	classicIcon.Image = logoAsset
	classicIcon.ScaleType = Enum.ScaleType.Fit
	classicIcon.ZIndex = 56
	classicIcon.Parent = classicBtn
	self._ClassicOpen = classicBtn
	self._ClassicStroke = classicStroke

	function self:_applyOpenStyle(style: string)
		style = style or "Island"
		self._OpenStyle = style
		local useIsland = style ~= "Button"
		if island then
			island:SetAttribute("Preferred", useIsland)
		end
		if classicBtn then
			classicBtn:SetAttribute("Preferred", not useIsland)
		end
		if not self._Visible and self._StartupComplete then
			if useIsland then
				island.Visible = true
				classicBtn.Visible = false
				self._FloatingButton = island
			else
				island.Visible = false
				classicBtn.Visible = true
				self._FloatingButton = classicBtn
			end
		end
	end

	local activityScale = Instance.new("UIScale")
	activityScale.Name = "Pop"
	activityScale.Scale = 0.9

	-- Boot completion: crossfade from boot screen to main window
	task.delay(1.2, function()
		if self._BootGui then
			Tween.Play(bootBackdrop, { BackgroundTransparency = 1 }, { Time = 0.3 })
			task.wait(0.32)
			if self._BootGui then
				self._BootGui:Destroy()
				self._BootGui = nil
			end
			main.Visible = true
			self._Visible = true
			self._StartupComplete = true
			self:_applyOpenStyle("Island")
			applyBlurTarget()
		end
	end)

	self._Maid:Give(function()
		if self._BlurEffect then
			self._BlurEffect:Destroy()
		end
	end)

	-- ============================================================
	-- PUBLIC API
	-- ============================================================
	function self:SetVisible(visible: boolean)
		self._Visible = visible
		main.Visible = visible
		if visible then
			if self._OpenStyle == "Button" or not self._FloatingButton then
				classicBtn.Visible = true
				island.Visible = false
				self._FloatingButton = classicBtn
			else
				island.Visible = true
				classicBtn.Visible = false
				self._FloatingButton = island
			end
		else
			island.Visible = false
			classicBtn.Visible = false
		end
		applyBlurTarget()
	end

	function self:Toggle()
		self:SetVisible(not self._Visible)
	end

	function self:SetOpen(open: boolean)
		self:SetVisible(open)
	end

	function self:_selectTab(tab: any)
		if self._ActiveTab then
			self._ActiveTab:SetActive(false)
		end
		self._ActiveTab = tab
		if tab then
			tab:SetActive(true)
			tab:Show()
			self._IslandActTab.Text = "Tab " .. (tab._Name or tab.Name or "Home")
		end
	end

	if data.ToggleKey then
		local conn
		conn = UserInputService.InputBegan:Connect(function(input, processed)
			if processed then return end
			if input.KeyCode == data.ToggleKey then
				self:Toggle()
			end
		end)
		self._Maid:GiveTask(conn)
	end

	if data.BackgroundImage then
		self:SetBackgroundImage(data.BackgroundImage)
	end

	function self:CreateTab(name: string)
		local tab = Tab.new(self, name)
		table.insert(self._Tabs, tab)
		if #self._Tabs == 1 then
			self:_selectTab(tab)
		end
		return tab
	end

	function self:SetProfileStatus(status: string)
		self._ProfileStatus = tostring(status or "")
	end

	function self:SetWatermarkEnabled(enabled: boolean)
		self._WatermarkEnabled = enabled == true
	end

	function self:CreateESPBuilder(opts: any?)
		local builder = ESPBuilder.new(opts)
		return builder
	end

	function self:CreateESPWorldRenderer(opts: any?)
		local renderer = ESPWorldRenderer.new(opts)
		return renderer
	end

	function self:CreateLayoutVariants(mode: string)
		local lv = LayoutVariants.new(self, mode)
		return lv
	end

	return self :: any
end

function Window:SetBackgroundImage(imageId: string)
	if self._BackgroundImage then
		self._BackgroundImage.Image = imageId or ""
	end
end

function Window:SetBackgroundOverlayTransparency(transparency: number)
	-- overlay handled in constructor; kept for API compat
end

function Window:SetCornerRadius(radius: number)
	-- kept for API compat
end

function Window:Notify(options: any)
	return self.Library:Notify(options)
end

function Window:Destroy()
	if self._Maid then
		self._Maid:DoCleaning()
	end
end

return Window
