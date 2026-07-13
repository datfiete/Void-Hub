--[[
	================================================================================
	ModernUI  —  A modern, high-quality Roblox UI Library
	Rayfield-API-compatible | Discord x Fluent inspired design
	================================================================================

	Version: 1.0.0
	Author:  Fiete Woozle

	ARCHITECTURE (all inside one file for loadstring-friendliness, but organized
	into clearly separated "modules" exactly like you would split them into real
	ModuleScripts if you use Rojo):

		1. SERVICES        -> Roblox service references
		2. CONFIGURATION    -> central, editable settings (colors, sounds, links...)
		3. ASSETS           -> icons & sound ids
		4. THEMES           -> Dark / Light / Custom theme definitions
		5. UTILITIES        -> generic helpers (tween, corner, stroke, drag, ripple)
		6. SERVICES (lib)   -> NotificationService, ConfigService (save/load), SoundService
		7. CORE             -> Window / Tab / Section objects, main state machine
		8. COMPONENTS       -> Button, Toggle, Slider, Dropdown, Input, Keybind,
		                        Paragraph, Label, ColorPicker, Dialog
		9. PUBLIC API       -> the table returned to the user script

	To extend the library:
		- New component?  Add a function under COMPONENTS following the existing
		  pattern (see comments "HOW TO ADD A NEW COMPONENT").
		- New theme?       Add a key to Themes table in section THEMES.
		- New icon?        Add to Icons table in section ASSETS.
	================================================================================
]]

local ModernUI = {}
ModernUI.__index = ModernUI

-- ============================================================================
-- 1. SERVICES
-- ============================================================================
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local HttpService       = game:GetService("HttpService")
local CoreGui           = game:GetService("CoreGui")
local GuiService        = game:GetService("GuiService")
local TextService       = game:GetService("TextService")

local LocalPlayer = Players.LocalPlayer

-- ============================================================================
-- 2. CONFIGURATION  (edit this block to reconfigure the whole library)
-- ============================================================================
local Config = {
	LibraryName   = "ModernUI",
	Version       = "1.0.0",

	-- >>> EASILY CHANGE YOUR DISCORD LINK HERE <<<
	DiscordInvite = "https://discord.gg/pmJABXQtw",

	DefaultTheme  = "Dark",
	DefaultScale  = 1,

	-- Feature toggles (also changeable at runtime from the Visuals tab)
	AnimationsEnabled = true,
	SoundsEnabled     = true,
	BlurEnabled       = false,

	-- Timings
	TweenSpeed = 0.22,
	TweenStyle = Enum.EasingStyle.Quint,
	TweenDir   = Enum.EasingDirection.Out,

	-- Config saving (folder used by writefile/readfile, if the executor supports it)
	ConfigFolder = "ModernUI/Configs",

	-- Notification defaults
	NotificationDuration = 5,
	NotificationPosition = "BottomRight", -- BottomRight | TopRight
}

-- ============================================================================
-- 3. ASSETS  (icons & sounds — centrally editable)
-- ============================================================================
local Assets = {}

-- Sounds (replace ids with your own if these ever go dead / are region-blocked)
Assets.Sounds = {
	Click        = "rbxassetid://6895079853",
	Hover        = "rbxassetid://6895079091",
	Toggle       = "rbxassetid://6895079837",
	Open         = "rbxassetid://6895079802",
	Close        = "rbxassetid://6895079968",
	Notification = "rbxassetid://6895079931",
	Error        = "rbxassetid://6895079781",
}

-- Drop-shadow image (well known soft shadow asset used widely in Roblox UI work)
Assets.Shadow = "rbxassetid://5028857084"

-- Icon set. Icons can be:
--   * a string key from this table (rendered with a text-glyph, works everywhere,
--     no dependency on external asset ids that may break)
--   * a number  -> treated as a literal rbxassetid image
-- This keeps the library 100% self-contained while still letting users supply
-- their own custom icon asset ids (e.g. from the Lucide icon pack) if desired.
Assets.Icons = {
	home        = "⌂",
	settings    = "⚙",
	palette     = "◐",
	search      = "⌕",
	star        = "★",
	heart       = "♥",
	bell        = "🔔",
	user        = "☺",
	folder      = "🗀",
	shield      = "🛡",
	code        = "</>",
	play        = "►",
	pause       = "❚❚",
	stop        = "■",
	trash       = "🗑",
	info        = "ⓘ",
	success     = "✔",
	warning     = "⚠",
	error       = "✖",
	discord     = "🎮",
	close       = "✕",
	minimize    = "—",
	maximize    = "▢",
	chevronDown = "▾",
	chevronUp   = "▴",
	dot         = "●",
	link        = "🔗",
	lock        = "🔒",
	unlock      = "🔓",
	edit        = "✎",
	keybind     = "⌨",
	slider      = "═",
	color       = "🎨",
	image       = "🖼",
}

local function ResolveIcon(icon)
	if typeof(icon) == "number" then
		return "Image", "rbxassetid://" .. tostring(icon)
	elseif typeof(icon) == "string" then
		if Assets.Icons[icon] then
			return "Text", Assets.Icons[icon]
		elseif icon:match("^rbxassetid://") then
			return "Image", icon
		else
			-- fall back: show first character as a mini glyph
			return "Text", icon
		end
	end
	return "Text", ""
end

-- ============================================================================
-- 4. THEMES
-- ============================================================================
local Themes = {
	Dark = {
		Background   = Color3.fromRGB(20, 20, 23),
		Secondary    = Color3.fromRGB(28, 28, 32),
		Elevated     = Color3.fromRGB(36, 36, 41),
		ElevatedHi   = Color3.fromRGB(46, 46, 52),
		Stroke       = Color3.fromRGB(54, 54, 60),
		Text         = Color3.fromRGB(238, 238, 240),
		SubText      = Color3.fromRGB(160, 160, 168),
		Accent       = Color3.fromRGB(114, 137, 218),
		Glow         = Color3.fromRGB(140, 160, 255),
		Success      = Color3.fromRGB(87, 201, 124),
		Warning      = Color3.fromRGB(250, 166, 26),
		Error        = Color3.fromRGB(237, 66, 69),
	},
	Light = {
		Background   = Color3.fromRGB(244, 244, 247),
		Secondary    = Color3.fromRGB(255, 255, 255),
		Elevated     = Color3.fromRGB(250, 250, 252),
		ElevatedHi   = Color3.fromRGB(240, 240, 245),
		Stroke       = Color3.fromRGB(222, 222, 228),
		Text         = Color3.fromRGB(24, 24, 28),
		SubText      = Color3.fromRGB(105, 105, 112),
		Accent       = Color3.fromRGB(88, 101, 242),
		Glow         = Color3.fromRGB(120, 135, 255),
		Success      = Color3.fromRGB(45, 160, 90),
		Warning      = Color3.fromRGB(210, 130, 20),
		Error        = Color3.fromRGB(205, 50, 55),
	},
}
-- "Custom" theme starts as a copy of Dark; user can overwrite fields at runtime
Themes.Custom = {}
for k, v in pairs(Themes.Dark) do Themes.Custom[k] = v end

-- ============================================================================
-- 5. UTILITIES
-- ============================================================================
local Utility = {}

function Utility.Create(className, props, children)
	local inst = Instance.new(className)
	for prop, value in pairs(props or {}) do
		inst[prop] = value
	end
	for _, child in ipairs(children or {}) do
		child.Parent = inst
	end
	return inst
end

function Utility.Corner(radius)
	return Utility.Create("UICorner", { CornerRadius = UDim.new(0, radius or 8) })
end

function Utility.Stroke(color, thickness, transparency)
	return Utility.Create("UIStroke", {
		Color = color or Color3.new(1, 1, 1),
		Thickness = thickness or 1,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

function Utility.Gradient(colorSequence, rotation)
	return Utility.Create("UIGradient", {
		Color = colorSequence,
		Rotation = rotation or 0,
	})
end

function Utility.Padding(all, top, bottom, left, right)
	return Utility.Create("UIPadding", {
		PaddingTop = UDim.new(0, top or all or 0),
		PaddingBottom = UDim.new(0, bottom or all or 0),
		PaddingLeft = UDim.new(0, left or all or 0),
		PaddingRight = UDim.new(0, right or all or 0),
	})
end

function Utility.ListLayout(direction, padding, alignX, alignY)
	return Utility.Create("UIListLayout", {
		FillDirection = direction or Enum.FillDirection.Vertical,
		Padding = UDim.new(0, padding or 6),
		HorizontalAlignment = alignX or Enum.HorizontalAlignment.Left,
		VerticalAlignment = alignY or Enum.VerticalAlignment.Top,
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
end

-- Track every tween/connection the library creates so Destroy() can clean up
-- perfectly (no memory leaks).
local ActiveConnections = {}
local ActiveTweens = {}

function Utility.Tween(instance, props, duration, style, direction)
	if not Config.AnimationsEnabled then
		for prop, value in pairs(props) do
			instance[prop] = value
		end
		return
	end
	local info = TweenInfo.new(
		duration or Config.TweenSpeed,
		style or Config.TweenStyle,
		direction or Config.TweenDir
	)
	local tween = TweenService:Create(instance, info, props)
	ActiveTweens[tween] = true
	tween.Completed:Connect(function()
		ActiveTweens[tween] = nil
	end)
	tween:Play()
	return tween
end

function Utility.Connect(signal, fn)
	local conn = signal:Connect(fn)
	table.insert(ActiveConnections, conn)
	return conn
end

function Utility.CleanupAll()
	for _, conn in ipairs(ActiveConnections) do
		pcall(function() conn:Disconnect() end)
	end
	ActiveConnections = {}
	for tween in pairs(ActiveTweens) do
		pcall(function() tween:Cancel() end)
	end
	ActiveTweens = {}
end

-- Drag support for the main window
function Utility.MakeDraggable(frame, dragHandle)
	dragHandle = dragHandle or frame
	local dragging = false
	local dragStart, startPos

	Utility.Connect(dragHandle.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	Utility.Connect(UserInputService.InputChanged, function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			frame.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)
end

-- Ripple / press feedback effect
function Utility.Ripple(button, colorOverride)
	Utility.Connect(button.InputBegan, function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		local ripple = Utility.Create("Frame", {
			BackgroundColor3 = colorOverride or Color3.new(1, 1, 1),
			BackgroundTransparency = 0.75,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(0, 0, 0, 0),
			ZIndex = button.ZIndex + 1,
		}, { Utility.Corner(999) })
		ripple.Parent = button
		local size = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 1.6
		Utility.Tween(ripple, { Size = UDim2.new(0, size, 0, size), BackgroundTransparency = 1 }, 0.5)
		task.delay(0.5, function()
			if ripple then ripple:Destroy() end
		end)
	end)
end

-- Shadow helper
function Utility.AddShadow(parent, transparency, size)
	local shadow = Utility.Create("ImageLabel", {
		Name = "Shadow",
		Image = Assets.Shadow,
		ImageColor3 = Color3.new(0, 0, 0),
		ImageTransparency = transparency or 0.55,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(23, 23, 277, 277),
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 4),
		Size = UDim2.new(1, size or 40, 1, size or 40),
		ZIndex = parent.ZIndex - 1,
	})
	shadow.Parent = parent
	return shadow
end

-- ============================================================================
-- 6. LIB SERVICES: Sound, Notification, Config saving
-- ============================================================================

-- --- Sound Service ---
local SoundService_ = {}
do
	local soundGroup = Utility.Create("Folder", { Name = "ModernUI_Sounds" })
	function SoundService_.Play(name)
		if not Config.SoundsEnabled then return end
		local id = Assets.Sounds[name]
		if not id then return end
		local sound = Utility.Create("Sound", {
			SoundId = id,
			Volume = 0.5,
			Parent = soundGroup,
		})
		sound:Play()
		game:GetService("Debris"):AddItem(sound, 3)
	end
	SoundService_.Group = soundGroup
end

-- --- Notification Service (created lazily once a ScreenGui exists) ---
local NotificationService = {}
NotificationService.Holder = nil
NotificationService._order = 0
NotificationService._active = 0

function NotificationService.Init(screenGui, theme)
	local holder = Utility.Create("Frame", {
		Name = "NotificationHolder",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -20, 1, -20),
		Size = UDim2.new(0, 320, 1, -40),
		ZIndex = 100,
	}, {
		Utility.Create("UIListLayout", {
			VerticalAlignment = Enum.VerticalAlignment.Bottom,
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			Padding = UDim.new(0, 10),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
	holder.Parent = screenGui
	NotificationService.Holder = holder
end

function NotificationService.Notify(opts, theme)
	if not NotificationService.Holder then return end
	opts = opts or {}
	local title    = opts.Title or "Notification"
	local content  = opts.Content or ""
	local duration = opts.Duration or Config.NotificationDuration
	local kind     = opts.Image or "info" -- info | success | warning | error

	local accentColor = theme.Accent
	if kind == "success" then accentColor = theme.Success
	elseif kind == "warning" then accentColor = theme.Warning
	elseif kind == "error" then accentColor = theme.Error end

	local iconType, iconValue = ResolveIcon(kind)

	-- Reset the ordering counter whenever there are no notifications left on
	-- screen so LayoutOrder can never grow without bound during a long session.
	if NotificationService._active <= 0 then
		NotificationService._order = 0
	end
	NotificationService._order = NotificationService._order + 1
	NotificationService._active = NotificationService._active + 1

	local card = Utility.Create("Frame", {
		BackgroundColor3 = theme.Elevated,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		ClipsDescendants = false,
		LayoutOrder = NotificationService._order,
	}, {
		Utility.Corner(12),
		Utility.Stroke(theme.Stroke, 1),
	})
	Utility.AddShadow(card, 0.6, 24)

	local accentBar = Utility.Create("Frame", {
		BackgroundColor3 = accentColor,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 4, 1, 0),
	}, { Utility.Corner(2) })
	accentBar.Parent = card

	local iconLabel = Utility.Create("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 16, 0, 12),
		Size = UDim2.new(0, 24, 0, 24),
		Font = Enum.Font.GothamBold,
		Text = iconValue,
		TextColor3 = accentColor,
		TextSize = 18,
	})
	iconLabel.Parent = card

	local titleLabel = Utility.Create("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 48, 0, 10),
		Size = UDim2.new(1, -64, 0, 20),
		Font = Enum.Font.GothamBold,
		Text = title,
		TextColor3 = theme.Text,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	titleLabel.Parent = card

	local contentLabel = Utility.Create("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 48, 0, 30),
		Size = UDim2.new(1, -64, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Font = Enum.Font.Gotham,
		Text = content,
		TextColor3 = theme.SubText,
		TextSize = 13,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
	})
	contentLabel.Parent = card

	Utility.Padding(0, 12, 12, 0, 0).Parent = card

	card.Parent = NotificationService.Holder
	card.Position = UDim2.new(1.2, 0, 0, 0)
	SoundService_.Play("Notification")

	Utility.Tween(card, { Position = UDim2.new(0, 0, 0, 0) }, 0.35, Enum.EasingStyle.Back)

	local removed = false
	local function markRemoved()
		if removed then return end
		removed = true
		NotificationService._active = math.max(0, NotificationService._active - 1)
	end

	task.delay(duration, function()
		if not card or not card.Parent then
			markRemoved()
			return
		end
		Utility.Tween(card, { Position = UDim2.new(1.2, 0, 0, 0) }, 0.3)
		task.delay(0.32, function()
			markRemoved()
			if card then card:Destroy() end
		end)
	end)
end

-- --- Config (save/load) Service ---
local ConfigService = {}
function ConfigService.Save(name, data)
	local ok = pcall(function()
		if not isfolder(Config.ConfigFolder) then
			makefolder(Config.ConfigFolder)
		end
		writefile(Config.ConfigFolder .. "/" .. name .. ".json", HttpService:JSONEncode(data))
	end)
	return ok
end
function ConfigService.Load(name)
	local result = nil
	pcall(function()
		if isfile(Config.ConfigFolder .. "/" .. name .. ".json") then
			result = HttpService:JSONDecode(readfile(Config.ConfigFolder .. "/" .. name .. ".json"))
		end
	end)
	return result
end

-- ============================================================================
-- 7. CORE  (Window / Tab / Section)
-- ============================================================================

ModernUI.Flags = {}     -- Flag -> value store (Rayfield compatible)
ModernUI.FlagObjects = {} -- Flag -> component object (for :Set())

local function GetGuiParent()
	-- gethui() is provided by most executors to place UI outside CoreGui detection issues
	local ok, hui = pcall(function() return gethui() end)
	if ok and hui then return hui end
	return CoreGui
end

--[[
	CreateWindow(options)
	options = {
		Name = "Window Title",
		LoadingTitle = "...",
		LoadingSubtitle = "...",
		Theme = "Dark" | "Light" | "Custom",
		ConfigurationSaving = { Enabled = true, FolderName = "...", FileName = "..." },
		Discord = { Enabled = true, Invite = "xxxx" },
		KeySystem = false,
		KeySettings = { Key = "...", Title="...", Subtitle="..." },
	}
]]
function ModernUI:CreateWindow(options)
	options = options or {}

	local self = setmetatable({}, ModernUI)
	self.Tabs = {}

	-- IMPORTANT: clone the theme table instead of pointing straight at the
	-- shared Themes[...] table. Components (e.g. the ColorPicker) write
	-- directly into `theme` at runtime (theme.Accent = color); without a
	-- per-window clone those writes would corrupt the shared theme
	-- definition for every other/future window.
	local baseTheme = Themes[options.Theme or Config.DefaultTheme] or Themes.Dark
	self.Theme = {}
	for k, v in pairs(baseTheme) do self.Theme[k] = v end
	self.ThemeName = options.Theme or Config.DefaultTheme
	self.Minimized = false
	self.Destroyed = false

	if options.Discord and options.Discord.Invite then
		Config.DiscordInvite = options.Discord.Invite
	end

	-- ============ ROOT SCREENGUI ============
	local screenGui = Utility.Create("ScreenGui", {
		Name = "ModernUI_" .. HttpService:GenerateGUID(false),
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 999,
	})
	local ok = pcall(function() screenGui.Parent = GetGuiParent() end)
	if not ok then screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
	self.ScreenGui = screenGui

	-- optional blur
	local blur = Utility.Create("BlurEffect", { Size = 0, Enabled = false })
	blur.Parent = game:GetService("Lighting")
	self.Blur = blur

	-- ============ MAIN WINDOW FRAME ============
	local main = Utility.Create("Frame", {
		Name = "Main",
		BackgroundColor3 = self.Theme.Background,
		BorderSizePixel = 0,
		Position = UDim2.new(0.5, -280, 0.5, -180),
		Size = UDim2.new(0, 560, 0, 360),
		ClipsDescendants = true,
	}, {
		Utility.Corner(14),
		Utility.Stroke(self.Theme.Stroke, 1),
	})
	main.Parent = screenGui
	Utility.AddShadow(main, 0.5, 60)
	self.Main = main

	-- background image (optional, user-set via Visuals tab)
	local bgImage = Utility.Create("ImageLabel", {
		Name = "BackgroundImage",
		BackgroundTransparency = 1,
		Image = "",
		ImageTransparency = 0.85,
		ScaleType = Enum.ScaleType.Crop,
		Size = UDim2.new(1, 0, 1, 0),
		Visible = false,
		ZIndex = 0,
	})
	bgImage.Parent = main
	self.BackgroundImage = bgImage

	-- ============ TITLE BAR ============
	local titleBar = Utility.Create("Frame", {
		Name = "TitleBar",
		BackgroundColor3 = self.Theme.Secondary,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 44),
	}, { Utility.Corner(14) })
	titleBar.Parent = main
	-- mask the bottom corners of the titlebar so it looks flush
	local mask = Utility.Create("Frame", {
		BackgroundColor3 = self.Theme.Secondary,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 1, -14),
		Size = UDim2.new(1, 0, 0, 14),
	})
	mask.Parent = titleBar

	local titleText = Utility.Create("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 16, 0, 0),
		Size = UDim2.new(1, -160, 1, 0),
		Font = Enum.Font.GothamBold,
		Text = options.Name or Config.LibraryName,
		TextColor3 = self.Theme.Text,
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	titleText.Parent = titleBar
	self.TitleText = titleText

	-- window control buttons (close / minimize)
	local function makeControlButton(icon, order, hoverColor)
		local btn = Utility.Create("TextButton", {
			BackgroundColor3 = self.Theme.Elevated,
			BorderSizePixel = 0,
			Size = UDim2.new(0, 28, 0, 28),
			Text = "",
			AutoButtonColor = false,
			LayoutOrder = order,
		}, { Utility.Corner(8) })
		local label = Utility.Create("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
			Font = Enum.Font.GothamBold,
			Text = icon,
			TextColor3 = self.Theme.SubText,
			TextSize = 13,
		})
		label.Parent = btn
		Utility.Connect(btn.MouseEnter, function()
			Utility.Tween(btn, { BackgroundColor3 = hoverColor }, 0.15)
			Utility.Tween(label, { TextColor3 = self.Theme.Text }, 0.15)
			SoundService_.Play("Hover")
		end)
		Utility.Connect(btn.MouseLeave, function()
			Utility.Tween(btn, { BackgroundColor3 = self.Theme.Elevated }, 0.15)
			Utility.Tween(label, { TextColor3 = self.Theme.SubText }, 0.15)
		end)
		return btn
	end

	local controlHolder = Utility.Create("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.new(0, 70, 0, 28),
	}, {
		Utility.Create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 6),
			VerticalAlignment = Enum.VerticalAlignment.Center,
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
		}),
	})
	controlHolder.Parent = titleBar

	local minimizeBtn = makeControlButton(Assets.Icons.minimize, 1, self.Theme.ElevatedHi)
	minimizeBtn.Parent = controlHolder
	local closeBtn = makeControlButton(Assets.Icons.close, 2, self.Theme.Error)
	closeBtn.Parent = controlHolder

	-- ============ TAB SIDEBAR ============
	local sidebar = Utility.Create("Frame", {
		Name = "Sidebar",
		BackgroundColor3 = self.Theme.Secondary,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, 44),
		Size = UDim2.new(0, 140, 1, -44),
	})
	sidebar.Parent = main

	local tabListHolder = Utility.Create("ScrollingFrame", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 8),
		Size = UDim2.new(1, 0, 1, -60),
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = self.Theme.Accent,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
	}, {
		Utility.ListLayout(Enum.FillDirection.Vertical, 4),
		Utility.Padding(8),
	})
	tabListHolder.Parent = sidebar
	self.TabListHolder = tabListHolder

	-- Discord button fixed at bottom of sidebar
	local discordBtn = Utility.Create("TextButton", {
		Name = "DiscordButton",
		BackgroundColor3 = self.Theme.Elevated,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 8, 1, -44),
		Size = UDim2.new(1, -16, 0, 36),
		Text = "",
		AutoButtonColor = false,
	}, { Utility.Corner(10) })
	discordBtn.Parent = sidebar
	Utility.Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 6),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
	}).Parent = discordBtn
	Utility.Create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 18, 0, 18),
		Font = Enum.Font.GothamBold,
		Text = Assets.Icons.discord,
		TextColor3 = self.Theme.Accent,
		TextSize = 15,
	}).Parent = discordBtn
	Utility.Create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 70, 0, 18),
		Font = Enum.Font.GothamMedium,
		Text = "Discord",
		TextColor3 = self.Theme.SubText,
		TextSize = 13,
	}).Parent = discordBtn

	Utility.Ripple(discordBtn, self.Theme.Accent)
	Utility.Connect(discordBtn.MouseButton1Click, function()
		SoundService_.Play("Click")
		local success = pcall(function()
			setclipboard(Config.DiscordInvite)
		end)
		NotificationService.Notify({
			Title = "Discord",
			Content = success and "Discord-Link wurde kopiert." or ("Link: " .. Config.DiscordInvite),
			Image = success and "success" or "info",
			Duration = 4,
		}, self.Theme)
	end)

	-- ============ CONTENT AREA ============
	local contentArea = Utility.Create("Frame", {
		Name = "ContentArea",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 140, 0, 44),
		Size = UDim2.new(1, -140, 1, -44),
	})
	contentArea.Parent = main
	self.ContentArea = contentArea

	-- ============ NOTIFICATIONS ============
	NotificationService.Init(screenGui, self.Theme)

	-- ============ DRAG ============
	Utility.MakeDraggable(main, titleBar)

	-- ============ MINIMIZE / CLOSE LOGIC ============
	local originalSize = main.Size
	Utility.Connect(minimizeBtn.MouseButton1Click, function()
		SoundService_.Play("Click")
		self.Minimized = not self.Minimized
		if self.Minimized then
			Utility.Tween(main, { Size = UDim2.new(0, 560, 0, 44) }, 0.3)
			sidebar.Visible = false
			contentArea.Visible = false
		else
			sidebar.Visible = true
			contentArea.Visible = true
			Utility.Tween(main, { Size = originalSize }, 0.3)
		end
	end)

	Utility.Connect(closeBtn.MouseButton1Click, function()
		SoundService_.Play("Close")
		self:Destroy()
	end)

	-- ============ OPEN ANIMATION ============
	main.Size = UDim2.new(0, 0, 0, 0)
	main.BackgroundTransparency = 1
	SoundService_.Play("Open")
	Utility.Tween(main, { Size = originalSize, BackgroundTransparency = 0 }, 0.4, Enum.EasingStyle.Back)

	-- store globally
	ModernUI.Windows = ModernUI.Windows or {}
	table.insert(ModernUI.Windows, self)

	-- ============ TAB / SECTION / COMPONENT FACTORIES ============
	self:_InitTabAPI()

	-- ============ BUILT-IN VISUALS / APPEARANCE TAB ============
	self:_BuildVisualsTab()

	-- ============ CONFIG SAVING ============
	self.ConfigSaving = options.ConfigurationSaving or { Enabled = false }
	if self.ConfigSaving.Enabled then
		local loaded = ConfigService.Load(self.ConfigSaving.FileName or "config")
		if loaded then
			for flag, value in pairs(loaded) do
				ModernUI.Flags[flag] = value
			end
		end
	end

	return self
end

-- ============================================================================
-- TAB API
-- ============================================================================
function ModernUI:_InitTabAPI()
	local window = self

	function window:CreateTab(name, icon)
		local theme = window.Theme

		-- sidebar tab button
		local tabBtn = Utility.Create("TextButton", {
			BackgroundColor3 = theme.Elevated,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 34),
			Text = "",
			AutoButtonColor = false,
		}, { Utility.Corner(8) })
		tabBtn.Parent = window.TabListHolder

		local iconType, iconValue = ResolveIcon(icon or "dot")
		local iconLabel = Utility.Create(iconType == "Image" and "ImageLabel" or "TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 10, 0, 0),
			Size = UDim2.new(0, 20, 1, 0),
			TextColor3 = theme.SubText,
			TextSize = 14,
			Font = Enum.Font.GothamBold,
		})
		if iconType == "Image" then iconLabel.Image = iconValue else iconLabel.Text = iconValue end
		iconLabel.Parent = tabBtn

		local nameLabel = Utility.Create("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 36, 0, 0),
			Size = UDim2.new(1, -42, 1, 0),
			Font = Enum.Font.GothamMedium,
			Text = name,
			TextColor3 = theme.SubText,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
		})
		nameLabel.Parent = tabBtn

		-- page (scroll frame)
		local page = Utility.Create("ScrollingFrame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = theme.Accent,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			Visible = false,
		}, {
			Utility.ListLayout(Enum.FillDirection.Vertical, 10),
			Utility.Padding(16),
		})
		page.Parent = window.ContentArea

		local tabObject = { Name = name, Button = tabBtn, Page = page, Sections = {}, SectionCount = 0 }

		local function selectTab()
			for _, t in ipairs(window.Tabs) do
				t.Page.Visible = false
				Utility.Tween(t.Button, { BackgroundTransparency = 1 }, 0.15)
				Utility.Tween(t.NameLabel, { TextColor3 = theme.SubText }, 0.15)
				Utility.Tween(t.IconLabel, { TextColor3 = theme.SubText }, 0.15)
			end
			page.Visible = true
			Utility.Tween(tabBtn, { BackgroundTransparency = 0 }, 0.15)
			Utility.Tween(nameLabel, { TextColor3 = theme.Text }, 0.15)
			Utility.Tween(iconLabel, { TextColor3 = theme.Accent }, 0.15)
		end

		tabObject.NameLabel = nameLabel
		tabObject.IconLabel = iconLabel
		tabObject.Select = selectTab

		Utility.Connect(tabBtn.MouseButton1Click, function()
			SoundService_.Play("Click")
			selectTab()
		end)
		Utility.Ripple(tabBtn, theme.Accent)

		table.insert(window.Tabs, tabObject)
		if #window.Tabs == 1 then selectTab() end

		-- ---------------- Section factory ----------------
		function tabObject:CreateSection(sectionName)
			-- Use an explicit, monotonically increasing counter for LayoutOrder
			-- instead of #page:GetChildren(), which also counts non-visual
			-- instances (UIListLayout, UIPadding) and produced inconsistent
			-- ordering once a page had more than a couple of elements.
			tabObject.SectionCount = tabObject.SectionCount + 1
			local sectionLabel = Utility.Create("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 24),
				Font = Enum.Font.GothamBold,
				Text = sectionName,
				TextColor3 = theme.SubText,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
				LayoutOrder = tabObject.SectionCount * 1000,
			})
			sectionLabel.Parent = page
			return { Name = sectionName, Label = sectionLabel }
		end

		-- attach all component builders (Button, Toggle, Slider, ...) to this tab
		window:_AttachComponents(tabObject, page, theme)

		return tabObject
	end
end

-- ============================================================================
-- 8. COMPONENTS
-- ============================================================================
-- HOW TO ADD A NEW COMPONENT:
--   1. Write a function CreateXxx(tabObject, page, theme, options) below.
--   2. Register it inside ModernUI:_AttachComponents so tabs expose
--      tab:CreateXxx({...}).
--   3. Keep the same option-table + Flag + Callback pattern used everywhere
--      else for full Rayfield-API compatibility.
-- ============================================================================

local function baseElementFrame(page, height)
	local holder = Utility.Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, height or 40),
	})
	holder.Parent = page
	return holder
end

function ModernUI:_AttachComponents(tab, page, theme)

	-- ---------------- BUTTON ----------------
	function tab:CreateButton(opts)
		opts = opts or {}
		local holder = baseElementFrame(page, 40)
		local btn = Utility.Create("TextButton", {
			BackgroundColor3 = theme.Elevated,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 1, 0),
			Text = "",
			AutoButtonColor = false,
		}, { Utility.Corner(10), Utility.Stroke(theme.Stroke, 1) })
		btn.Parent = holder

		Utility.Create("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 14, 0, 0),
			Size = UDim2.new(1, -28, 1, 0),
			Font = Enum.Font.GothamMedium,
			Text = opts.Name or "Button",
			TextColor3 = theme.Text,
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
		}).Parent = btn

		Utility.Ripple(btn, theme.Accent)
		Utility.Connect(btn.MouseEnter, function()
			Utility.Tween(btn, { BackgroundColor3 = theme.ElevatedHi }, 0.15)
		end)
		Utility.Connect(btn.MouseLeave, function()
			Utility.Tween(btn, { BackgroundColor3 = theme.Elevated }, 0.15)
		end)
		Utility.Connect(btn.MouseButton1Click, function()
			SoundService_.Play("Click")
			if opts.Callback then
				task.spawn(opts.Callback)
			end
		end)

		return { Instance = holder }
	end

	-- ---------------- TOGGLE ----------------
	function tab:CreateToggle(opts)
		opts = opts or {}
		local state = opts.CurrentValue or false
		local holder = baseElementFrame(page, 40)

		local label = Utility.Create("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 4, 0, 0),
			Size = UDim2.new(1, -70, 1, 0),
			Font = Enum.Font.GothamMedium,
			Text = opts.Name or "Toggle",
			TextColor3 = theme.Text,
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
		})
		label.Parent = holder

		local switchBg = Utility.Create("Frame", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -4, 0.5, 0),
			Size = UDim2.new(0, 44, 0, 24),
			BackgroundColor3 = state and theme.Accent or theme.Elevated,
			BorderSizePixel = 0,
		}, { Utility.Corner(12) })
		switchBg.Parent = holder

		local knob = Utility.Create("Frame", {
			Position = state and UDim2.new(1, -22, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			Size = UDim2.new(0, 20, 0, 20),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
		}, { Utility.Corner(10) })
		knob.Parent = switchBg

		local clickable = Utility.Create("TextButton", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
			Text = "",
		})
		clickable.Parent = switchBg

		local toggleObj = { Value = state }

		local function updateVisual(animated)
			local dur = animated and 0.18 or 0
			Utility.Tween(switchBg, { BackgroundColor3 = toggleObj.Value and theme.Accent or theme.Elevated }, dur)
			Utility.Tween(knob, { Position = toggleObj.Value and UDim2.new(1, -22, 0.5, 0) or UDim2.new(0, 2, 0.5, 0) }, dur)
		end

		function toggleObj:Set(value)
			toggleObj.Value = value
			updateVisual(true)
			if opts.Flag then ModernUI.Flags[opts.Flag] = value end
			if opts.Callback then task.spawn(opts.Callback, value) end
		end

		Utility.Connect(clickable.MouseButton1Click, function()
			SoundService_.Play("Toggle")
			toggleObj:Set(not toggleObj.Value)
		end)

		if opts.Flag then
			ModernUI.Flags[opts.Flag] = state
			ModernUI.FlagObjects[opts.Flag] = toggleObj
		end

		return toggleObj
	end

	-- ---------------- SLIDER ----------------
	function tab:CreateSlider(opts)
		opts = opts or {}
		local range = opts.Range or { 0, 100 }
		local increment = opts.Increment or 1
		local suffix = opts.Suffix or ""
		local value = opts.CurrentValue or range[1]

		local holder = baseElementFrame(page, 48)

		Utility.Create("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -60, 0, 20),
			Font = Enum.Font.GothamMedium,
			Text = opts.Name or "Slider",
			TextColor3 = theme.Text,
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
		}).Parent = holder

		local valueLabel = Utility.Create("TextLabel", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, 0, 0, 0),
			Size = UDim2.new(0, 60, 0, 20),
			Font = Enum.Font.GothamBold,
			Text = tostring(value) .. suffix,
			TextColor3 = theme.Accent,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Right,
		})
		valueLabel.Parent = holder

		local track = Utility.Create("Frame", {
			Position = UDim2.new(0, 0, 0, 28),
			Size = UDim2.new(1, 0, 0, 8),
			BackgroundColor3 = theme.Elevated,
			BorderSizePixel = 0,
		}, { Utility.Corner(4) })
		track.Parent = holder

		local fill = Utility.Create("Frame", {
			Size = UDim2.new(0, 0, 1, 0),
			BackgroundColor3 = theme.Accent,
			BorderSizePixel = 0,
		}, { Utility.Corner(4) })
		fill.Parent = track

		local grabber = Utility.Create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.new(0, 14, 0, 14),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			Position = UDim2.new(0, 0, 0.5, 0),
		}, { Utility.Corner(7) })
		grabber.Parent = fill

		local dragBtn = Utility.Create("TextButton", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
			Text = "",
		})
		dragBtn.Parent = track

		local sliderObj = { Value = value }

		local function setFromAlpha(alpha)
			alpha = math.clamp(alpha, 0, 1)
			local raw = range[1] + (range[2] - range[1]) * alpha
			raw = math.floor(raw / increment + 0.5) * increment
			raw = math.clamp(raw, range[1], range[2])
			sliderObj.Value = raw
			fill.Size = UDim2.new((raw - range[1]) / (range[2] - range[1]), 0, 1, 0)
			valueLabel.Text = tostring(raw) .. suffix
			if opts.Flag then ModernUI.Flags[opts.Flag] = raw end
			if opts.Callback then task.spawn(opts.Callback, raw) end
		end

		function sliderObj:Set(v)
			local alpha = (v - range[1]) / (range[2] - range[1])
			setFromAlpha(alpha)
		end

		-- init visual
		sliderObj:Set(value)

		local dragging = false
		Utility.Connect(dragBtn.InputBegan, function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
			end
		end)
		Utility.Connect(UserInputService.InputEnded, function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end)
		Utility.Connect(UserInputService.InputChanged, function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				local relative = (input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X
				setFromAlpha(relative)
			end
		end)

		if opts.Flag then
			ModernUI.Flags[opts.Flag] = value
			ModernUI.FlagObjects[opts.Flag] = sliderObj
		end

		return sliderObj
	end

	-- ---------------- DROPDOWN ----------------
	function tab:CreateDropdown(opts)
		opts = opts or {}
		local options = opts.Options or {}
		local multi = opts.MultipleOptions or false
		local current = opts.CurrentOption

		local holder = baseElementFrame(page, 40)
		holder.ClipsDescendants = false

		local head = Utility.Create("TextButton", {
			BackgroundColor3 = theme.Elevated,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 40),
			Text = "",
			AutoButtonColor = false,
			ZIndex = 5,
		}, { Utility.Corner(10), Utility.Stroke(theme.Stroke, 1) })
		head.Parent = holder

		Utility.Create("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 14, 0, 0),
			Size = UDim2.new(1, -80, 1, 0),
			Font = Enum.Font.GothamMedium,
			Text = opts.Name or "Dropdown",
			TextColor3 = theme.Text,
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 5,
		}).Parent = head

		local selectedLabel = Utility.Create("TextLabel", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -34, 0.5, 0),
			Size = UDim2.new(0, 120, 0, 20),
			Font = Enum.Font.Gotham,
			Text = typeof(current) == "table" and table.concat(current, ", ") or tostring(current or "..."),
			TextColor3 = theme.SubText,
			TextSize = 12,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Right,
			ZIndex = 5,
		})
		selectedLabel.Parent = head

		local chevron = Utility.Create("TextLabel", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -12, 0.5, 0),
			Size = UDim2.new(0, 16, 0, 16),
			Font = Enum.Font.GothamBold,
			Text = Assets.Icons.chevronDown,
			TextColor3 = theme.SubText,
			TextSize = 12,
			ZIndex = 5,
		})
		chevron.Parent = head

		local listFrame = Utility.Create("Frame", {
			BackgroundColor3 = theme.ElevatedHi,
			BorderSizePixel = 0,
			Position = UDim2.new(0, 0, 0, 44),
			Size = UDim2.new(1, 0, 0, 0),
			ClipsDescendants = true,
			ZIndex = 10,
			Visible = false,
		}, {
			Utility.Corner(10),
			Utility.Stroke(theme.Stroke, 1),
			Utility.ListLayout(Enum.FillDirection.Vertical, 2),
			Utility.Padding(4),
		})
		listFrame.Parent = holder

		local dropdownObj = { Value = current, Open = false, Selected = multi and (current or {}) or current }

		local function isSelected(opt)
			if multi then
				for _, v in ipairs(dropdownObj.Selected or {}) do
					if v == opt then return true end
				end
				return false
			else
				return dropdownObj.Selected == opt
			end
		end

		local optionButtons = {}

		local function refreshLabel()
			if multi then
				selectedLabel.Text = #dropdownObj.Selected > 0 and table.concat(dropdownObj.Selected, ", ") or "..."
			else
				selectedLabel.Text = tostring(dropdownObj.Selected or "...")
			end
		end

		local function selectOption(opt)
			if multi then
				local selected = dropdownObj.Selected
				local found = false
				for i, v in ipairs(selected) do
					if v == opt then table.remove(selected, i); found = true; break end
				end
				if not found then table.insert(selected, opt) end
			else
				dropdownObj.Selected = opt
			end
			refreshLabel()
			for _, b in pairs(optionButtons) do
				local sel = isSelected(b.OptValue)
				Utility.Tween(b.Btn, { BackgroundColor3 = sel and theme.Accent or theme.ElevatedHi }, 0.12)
			end
			if opts.Flag then ModernUI.Flags[opts.Flag] = dropdownObj.Selected end
			if opts.Callback then task.spawn(opts.Callback, dropdownObj.Selected) end
		end

		for i, opt in ipairs(options) do
			local optBtn = Utility.Create("TextButton", {
				BackgroundColor3 = isSelected(opt) and theme.Accent or theme.ElevatedHi,
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, 30),
				Text = "",
				AutoButtonColor = false,
				ZIndex = 11,
			}, { Utility.Corner(6) })
			optBtn.Parent = listFrame
			Utility.Create("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 10, 0, 0),
				Size = UDim2.new(1, -10, 1, 0),
				Font = Enum.Font.Gotham,
				Text = tostring(opt),
				TextColor3 = theme.Text,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 11,
			}).Parent = optBtn

			optionButtons[i] = { Btn = optBtn, OptValue = opt }
			Utility.Connect(optBtn.MouseButton1Click, function()
				SoundService_.Play("Click")
				selectOption(opt)
			end)
		end

		local function toggleOpen()
			dropdownObj.Open = not dropdownObj.Open
			local targetHeight = dropdownObj.Open and math.min(#options * 32 + 8, 160) or 0
			listFrame.Visible = true
			Utility.Tween(listFrame, { Size = UDim2.new(1, 0, 0, targetHeight) }, 0.2)
			Utility.Tween(chevron, { Rotation = dropdownObj.Open and 180 or 0 }, 0.2)
			if not dropdownObj.Open then
				task.delay(0.2, function()
					if listFrame then listFrame.Visible = false end
				end)
			end
		end

		Utility.Connect(head.MouseButton1Click, function()
			SoundService_.Play("Click")
			toggleOpen()
		end)

		if opts.Flag then
			ModernUI.Flags[opts.Flag] = current
			ModernUI.FlagObjects[opts.Flag] = dropdownObj
		end

		return dropdownObj
	end

	-- ---------------- INPUT BOX ----------------
	function tab:CreateInput(opts)
		opts = opts or {}
		local holder = baseElementFrame(page, 40)

		local box = Utility.Create("Frame", {
			BackgroundColor3 = theme.Elevated,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 1, 0),
		}, { Utility.Corner(10), Utility.Stroke(theme.Stroke, 1) })
		box.Parent = holder

		Utility.Create("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 14, 0, 0),
			Size = UDim2.new(0.45, 0, 1, 0),
			Font = Enum.Font.GothamMedium,
			Text = opts.Name or "Input",
			TextColor3 = theme.Text,
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
		}).Parent = box

		local textBox = Utility.Create("TextBox", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0.45, 0, 0, 0),
			Size = UDim2.new(0.55, -14, 1, 0),
			Font = Enum.Font.Gotham,
			PlaceholderText = opts.PlaceholderText or "...",
			Text = "",
			TextColor3 = theme.Text,
			PlaceholderColor3 = theme.SubText,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Right,
			ClearTextOnFocus = false,
		})
		textBox.Parent = box

		local inputObj = { Value = "" }

		Utility.Connect(textBox.FocusLost, function(enterPressed)
			inputObj.Value = textBox.Text
			if opts.Flag then ModernUI.Flags[opts.Flag] = textBox.Text end
			if opts.Callback then task.spawn(opts.Callback, textBox.Text) end
			if opts.RemoveTextAfterFocusLost then textBox.Text = "" end
		end)

		if opts.Flag then
			ModernUI.Flags[opts.Flag] = ""
			ModernUI.FlagObjects[opts.Flag] = inputObj
		end

		return inputObj
	end

	-- ---------------- KEYBIND ----------------
	function tab:CreateKeybind(opts)
		opts = opts or {}
		local currentKey = opts.CurrentKeybind or "None"
		local holder = baseElementFrame(page, 40)

		local box = Utility.Create("Frame", {
			BackgroundColor3 = theme.Elevated,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 1, 0),
		}, { Utility.Corner(10), Utility.Stroke(theme.Stroke, 1) })
		box.Parent = holder

		Utility.Create("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 14, 0, 0),
			Size = UDim2.new(1, -110, 1, 0),
			Font = Enum.Font.GothamMedium,
			Text = opts.Name or "Keybind",
			TextColor3 = theme.Text,
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
		}).Parent = box

		local keyBtn = Utility.Create("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -8, 0.5, 0),
			Size = UDim2.new(0, 90, 0, 26),
			BackgroundColor3 = theme.ElevatedHi,
			BorderSizePixel = 0,
			Font = Enum.Font.GothamBold,
			Text = currentKey,
			TextColor3 = theme.Accent,
			TextSize = 12,
			AutoButtonColor = false,
		}, { Utility.Corner(8) })
		keyBtn.Parent = box

		local listening = false
		local keybindObj = { Value = currentKey }

		Utility.Connect(keyBtn.MouseButton1Click, function()
			SoundService_.Play("Click")
			listening = true
			keyBtn.Text = "..."
		end)

		Utility.Connect(UserInputService.InputBegan, function(input, gpe)
			if listening and input.UserInputType == Enum.UserInputType.Keyboard then
				listening = false
				local keyName = input.KeyCode.Name
				keybindObj.Value = keyName
				keyBtn.Text = keyName
				if opts.Flag then ModernUI.Flags[opts.Flag] = keyName end
				return
			end
			if not gpe and not listening and input.KeyCode and input.KeyCode.Name == keybindObj.Value then
				if opts.Callback then task.spawn(opts.Callback) end
			end
		end)

		if opts.Flag then
			ModernUI.Flags[opts.Flag] = currentKey
			ModernUI.FlagObjects[opts.Flag] = keybindObj
		end

		return keybindObj
	end

	-- ---------------- PARAGRAPH ----------------
	function tab:CreateParagraph(opts)
		opts = opts or {}
		local holder = Utility.Create("Frame", {
			BackgroundColor3 = theme.Elevated,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
		}, { Utility.Corner(10), Utility.Stroke(theme.Stroke, 1), Utility.Padding(12) })
		holder.Parent = page

		Utility.Create("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 18),
			Font = Enum.Font.GothamBold,
			Text = opts.Title or "Paragraph",
			TextColor3 = theme.Text,
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
		}).Parent = holder

		Utility.Create("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 0, 0, 22),
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Font = Enum.Font.Gotham,
			Text = opts.Content or "",
			TextColor3 = theme.SubText,
			TextSize = 13,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
		}).Parent = holder

		return { Instance = holder }
	end

	-- ---------------- LABEL ----------------
	function tab:CreateLabel(text)
		local label = Utility.Create("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 20),
			Font = Enum.Font.GothamMedium,
			Text = text or "",
			TextColor3 = theme.SubText,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
		})
		label.Parent = page
		return { Instance = label, Set = function(_, newText) label.Text = newText end }
	end

	-- ---------------- COLOR PICKER ----------------
	function tab:CreateColorPicker(opts)
		opts = opts or {}
		local color = opts.Color or Color3.fromRGB(255, 255, 255)
		local holder = baseElementFrame(page, 40)

		Utility.Create("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 4, 0, 0),
			Size = UDim2.new(1, -60, 1, 0),
			Font = Enum.Font.GothamMedium,
			Text = opts.Name or "Color",
			TextColor3 = theme.Text,
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
		}).Parent = holder

		local swatch = Utility.Create("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -4, 0.5, 0),
			Size = UDim2.new(0, 40, 0, 24),
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			Text = "",
			AutoButtonColor = false,
		}, { Utility.Corner(6), Utility.Stroke(theme.Stroke, 1) })
		swatch.Parent = holder

		-- simple popup with R/G/B sliders
		local popup = Utility.Create("Frame", {
			BackgroundColor3 = theme.ElevatedHi,
			BorderSizePixel = 0,
			Size = UDim2.new(0, 200, 0, 140),
			Position = UDim2.new(1, -200, 1, 4),
			Visible = false,
			ZIndex = 20,
		}, { Utility.Corner(10), Utility.Stroke(theme.Stroke, 1), Utility.Padding(10) })
		popup.Parent = holder
		Utility.AddShadow(popup, 0.6, 20)

		local colorObj = { Value = color }
		local channels = { "R", "G", "B" }
		local sliderBars = {}

		for i, ch in ipairs(channels) do
			local row = Utility.Create("Frame", {
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 0, 0, (i - 1) * 34),
				Size = UDim2.new(1, 0, 0, 30),
			})
			row.Parent = popup
			Utility.Create("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(0, 16, 0, 16),
				Font = Enum.Font.GothamBold,
				Text = ch,
				TextColor3 = theme.SubText,
				TextSize = 12,
			}).Parent = row
			local track = Utility.Create("Frame", {
				Position = UDim2.new(0, 20, 0, 4),
				Size = UDim2.new(1, -20, 0, 8),
				BackgroundColor3 = theme.Elevated,
				BorderSizePixel = 0,
			}, { Utility.Corner(4) })
			track.Parent = row
			local fill = Utility.Create("Frame", {
				Size = UDim2.new((ch == "R" and colorObj.Value.R or ch == "G" and colorObj.Value.G or colorObj.Value.B), 0, 1, 0),
				BackgroundColor3 = theme.Accent,
				BorderSizePixel = 0,
			}, { Utility.Corner(4) })
			fill.Parent = track
			local dragBtn = Utility.Create("TextButton", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Text = "" })
			dragBtn.Parent = track
			sliderBars[ch] = { Track = track, Fill = fill }

			local dragging = false
			Utility.Connect(dragBtn.InputBegan, function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
			end)
			Utility.Connect(UserInputService.InputEnded, function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
			end)
			Utility.Connect(UserInputService.InputChanged, function(input)
				if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
					local alpha = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
					fill.Size = UDim2.new(alpha, 0, 1, 0)
					local r = ch == "R" and alpha or colorObj.Value.R
					local g = ch == "G" and alpha or colorObj.Value.G
					local b = ch == "B" and alpha or colorObj.Value.B
					colorObj.Value = Color3.new(r, g, b)
					swatch.BackgroundColor3 = colorObj.Value
					if opts.Flag then ModernUI.Flags[opts.Flag] = colorObj.Value end
					if opts.Callback then task.spawn(opts.Callback, colorObj.Value) end
				end
			end)
		end

		Utility.Connect(swatch.MouseButton1Click, function()
			SoundService_.Play("Click")
			popup.Visible = not popup.Visible
		end)

		function colorObj:Set(c)
			colorObj.Value = c
			swatch.BackgroundColor3 = c
			if sliderBars.R then sliderBars.R.Fill.Size = UDim2.new(c.R, 0, 1, 0) end
			if sliderBars.G then sliderBars.G.Fill.Size = UDim2.new(c.G, 0, 1, 0) end
			if sliderBars.B then sliderBars.B.Fill.Size = UDim2.new(c.B, 0, 1, 0) end
		end

		if opts.Flag then
			ModernUI.Flags[opts.Flag] = color
			ModernUI.FlagObjects[opts.Flag] = colorObj
		end

		return colorObj
	end

end

-- ============================================================================
-- DIALOG / PROMPT
-- ============================================================================
function ModernUI:CreateDialog(opts)
	opts = opts or {}
	local theme = self.Theme

	local overlay = Utility.Create("Frame", {
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.5,
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 50,
	})
	overlay.Parent = self.ScreenGui

	local box = Utility.Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 320, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = theme.Elevated,
		BorderSizePixel = 0,
		ZIndex = 51,
	}, { Utility.Corner(14), Utility.Stroke(theme.Stroke, 1), Utility.Padding(18) })
	box.Parent = overlay
	Utility.AddShadow(box, 0.5, 40)

	Utility.Create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 22),
		Font = Enum.Font.GothamBold,
		Text = opts.Title or "Dialog",
		TextColor3 = theme.Text,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 51,
	}).Parent = box

	Utility.Create("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 28),
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Font = Enum.Font.Gotham,
		Text = opts.Content or "",
		TextColor3 = theme.SubText,
		TextSize = 13,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 51,
	}).Parent = box

	local buttonRow = Utility.Create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 70),
		Size = UDim2.new(1, 0, 0, 34),
		ZIndex = 51,
	}, {
		Utility.Create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 8),
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
		}),
	})
	buttonRow.Parent = box

	for _, buttonOpts in ipairs(opts.Buttons or { { Title = "OK" } }) do
		local btn = Utility.Create("TextButton", {
			BackgroundColor3 = buttonOpts.Accent and theme.Accent or theme.ElevatedHi,
			BorderSizePixel = 0,
			Size = UDim2.new(0, 90, 1, 0),
			Font = Enum.Font.GothamMedium,
			Text = buttonOpts.Title or "OK",
			TextColor3 = buttonOpts.Accent and Color3.new(1, 1, 1) or theme.Text,
			TextSize = 13,
			AutoButtonColor = false,
			ZIndex = 51,
		}, { Utility.Corner(8) })
		btn.Parent = buttonRow
		Utility.Ripple(btn, Color3.new(1, 1, 1))
		Utility.Connect(btn.MouseButton1Click, function()
			SoundService_.Play("Click")
			if buttonOpts.Callback then task.spawn(buttonOpts.Callback) end
			overlay:Destroy()
		end)
	end

	return { Instance = overlay }
end

-- ============================================================================
-- NOTIFY (public)
-- ============================================================================
function ModernUI:Notify(opts)
	NotificationService.Notify(opts, self.Theme)
end

-- ============================================================================
-- VISUALS / APPEARANCE TAB (built automatically for every window)
-- ============================================================================

-- Best-effort live re-theming: walk every descendant of `root` and, for any
-- color property that still matches a value from the *old* theme table,
-- swap it for the corresponding value in the *new* theme table. This lets
-- existing buttons/toggles/sliders/etc. repaint immediately without needing
-- a manual registry of every themed instance.
local COLOR_PROPS = { "BackgroundColor3", "TextColor3", "ImageColor3" }
local function LiveRetheme(root, oldTheme, newTheme)
	local function process(inst)
		for _, prop in ipairs(COLOR_PROPS) do
			local ok, current = pcall(function() return inst[prop] end)
			if ok and typeof(current) == "Color3" then
				for key, oldColor in pairs(oldTheme) do
					if typeof(oldColor) == "Color3" and current == oldColor then
						local newColor = newTheme[key]
						if newColor then
							pcall(function() inst[prop] = newColor end)
						end
						break
					end
				end
			end
		end
		for _, child in ipairs(inst:GetChildren()) do
			process(child)
		end
	end
	process(root)
end

function ModernUI:_BuildVisualsTab()
	local window = self
	local theme = window.Theme
	local visualsTab = window:CreateTab("Visuals", "palette")

	visualsTab:CreateSection("Theme")

	visualsTab:CreateDropdown({
		Name = "Theme",
		Options = { "Dark", "Light", "Custom" },
		CurrentOption = window.ThemeName,
		Flag = "ModernUI_Theme",
		Callback = function(value)
			local newDef = Themes[value] or Themes.Dark

			-- snapshot the *current* colors before we overwrite them, so the
			-- retheme pass below knows what to look for
			local oldSnapshot = {}
			for k, v in pairs(theme) do oldSnapshot[k] = v end

			-- repaint every existing element still using an old-theme color
			LiveRetheme(window.Main, oldSnapshot, newDef)

			-- mutate the theme table IN PLACE (do not reassign window.Theme
			-- to a different table) so every closure that already captured
			-- `theme` as an upvalue automatically sees the new values too
			for k, v in pairs(newDef) do theme[k] = v end
			window.ThemeName = value

			window:Notify({ Title = "Theme", Content = "Theme set to " .. value .. ".", Image = "success" })
		end,
	})

	visualsTab:CreateSlider({
		Name = "UI Scale",
		Range = { 50, 150 },
		Increment = 5,
		Suffix = "%",
		CurrentValue = 100,
		Flag = "ModernUI_Scale",
		Callback = function(value)
			local scale = window.Main:FindFirstChildOfClass("UIScale")
			if not scale then
				scale = Utility.Create("UIScale", { Scale = 1 })
				scale.Parent = window.Main
			end
			Utility.Tween(scale, { Scale = value / 100 }, 0.15)
		end,
	})

	visualsTab:CreateSection("Background")

	visualsTab:CreateToggle({
		Name = "Enable Background Image",
		CurrentValue = false,
		Flag = "ModernUI_BGEnabled",
		Callback = function(value)
			window.BackgroundImage.Visible = value
		end,
	})

	visualsTab:CreateInput({
		Name = "Background Image (asset id / url)",
		PlaceholderText = "rbxassetid://...",
		Flag = "ModernUI_BGImage",
		Callback = function(text)
			window.BackgroundImage.Image = text
		end,
	})

	visualsTab:CreateSlider({
		Name = "Background Transparency",
		Range = { 0, 100 },
		Increment = 1,
		Suffix = "%",
		CurrentValue = 85,
		Flag = "ModernUI_BGTransparency",
		Callback = function(value)
			window.BackgroundImage.ImageTransparency = value / 100
		end,
	})

	visualsTab:CreateToggle({
		Name = "Enable Background Blur",
		CurrentValue = Config.BlurEnabled,
		Flag = "ModernUI_Blur",
		Callback = function(value)
			window.Blur.Enabled = value
			Utility.Tween(window.Blur, { Size = value and 16 or 0 }, 0.2)
		end,
	})

	visualsTab:CreateSection("Colors")

	visualsTab:CreateColorPicker({
		Name = "Accent Color",
		Color = theme.Accent,
		Flag = "ModernUI_Accent",
		Callback = function(color)
			theme.Accent = color
		end,
	})

	visualsTab:CreateColorPicker({
		Name = "Glow Color",
		Color = theme.Glow,
		Flag = "ModernUI_Glow",
		Callback = function(color)
			theme.Glow = color
		end,
	})

	visualsTab:CreateSection("Behaviour")

	visualsTab:CreateToggle({
		Name = "Animations",
		CurrentValue = Config.AnimationsEnabled,
		Flag = "ModernUI_Animations",
		Callback = function(value)
			Config.AnimationsEnabled = value
		end,
	})

	visualsTab:CreateToggle({
		Name = "Sounds",
		CurrentValue = Config.SoundsEnabled,
		Flag = "ModernUI_Sounds",
		Callback = function(value)
			Config.SoundsEnabled = value
		end,
	})

	visualsTab:CreateSection("Configuration")

	visualsTab:CreateButton({
		Name = "Save Current Config",
		Callback = function()
			local ok = ConfigService.Save(window.ConfigSaving and window.ConfigSaving.FileName or "config", ModernUI.Flags)
			window:Notify({
				Title = "Configuration",
				Content = ok and "Configuration saved." or "Saving is not supported by this executor.",
				Image = ok and "success" or "error",
			})
		end,
	})

	visualsTab:CreateButton({
		Name = "Save Custom Theme",
		Callback = function()
			Themes.Custom = {}
			for k, v in pairs(theme) do Themes.Custom[k] = v end
			ConfigService.Save("custom_theme", {
				Accent = { theme.Accent.R, theme.Accent.G, theme.Accent.B },
				Glow   = { theme.Glow.R, theme.Glow.G, theme.Glow.B },
			})
			window:Notify({ Title = "Theme", Content = "Custom theme saved.", Image = "success" })
		end,
	})
end

-- ============================================================================
-- DESTROY  (full, leak-free shutdown)
-- ============================================================================
function ModernUI:Destroy()
	if self.Destroyed then return end
	self.Destroyed = true

	Utility.Tween(self.Main, { Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1 }, 0.25)

	task.delay(0.26, function()
		pcall(function()
			if self.Blur then self.Blur:Destroy() end
			if self.ScreenGui then self.ScreenGui:Destroy() end
		end)
	end)

	-- remove from global window list
	for i, w in ipairs(ModernUI.Windows or {}) do
		if w == self then table.remove(ModernUI.Windows, i) break end
	end

	-- if this was the last window, do a full library-wide cleanup
	if #(ModernUI.Windows or {}) == 0 then
		Utility.CleanupAll()
		pcall(function() SoundService_.Group:Destroy() end)
	end
end

-- Alias matching Rayfield's naming
ModernUI.Unload = ModernUI.Destroy

-- expose sub-tables for advanced users / extension
ModernUI.Config = Config
ModernUI.Assets = Assets
ModernUI.Themes = Themes
ModernUI.Utility = Utility
ModernUI.NotificationService = NotificationService
ModernUI.ConfigService = ConfigService

return ModernUI
