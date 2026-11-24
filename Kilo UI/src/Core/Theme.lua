--!strict
-- Kilo UI Premium Design System
-- Commercial-grade theme engine with live transitions, gradient accents,
-- and hand-tuned presets for dark/light/cyber/neon palettes.
local Signal = require(script.Parent.Parent.Utils.Signal)
local Tween = require(script.Parent.Parent.Utils.Tween)

-- Color utility: linear interpolate between two Color3 values
local function lerpColor(a: Color3, b: Color3, t: number): Color3
	return Color3.new(
		a.R + (b.R - a.R) * t,
		a.G + (b.G - a.G) * t,
		a.B + (b.B - a.B) * t
	)
end

-- Color utility: convert hex string to Color3
local function hexToColor3(hex: string): Color3
	hex = hex:gsub("#", "")
	local r = tonumber(hex:sub(1, 2), 16) or 255
	local g = tonumber(hex:sub(3, 4), 16) or 255
	local b = tonumber(hex:sub(5, 6), 16) or 255
	return Color3.fromRGB(r, g, b)
end

-- Premium style presets. Each is a complete, hand-tuned design token set.
local stylePresets = {
	-- Kilo: signature blue/cyan cyber palette (default, premium)
	Kilo = {
		Background = Color3.fromRGB(8, 12, 20),
		Secondary = Color3.fromRGB(12, 18, 28),
		Surface = Color3.fromRGB(16, 22, 34),
		SurfaceHover = Color3.fromRGB(24, 32, 48),
		ElementBackground = Color3.fromRGB(14, 20, 30),
		ElementHover = Color3.fromRGB(22, 30, 44),
		Text = Color3.fromRGB(238, 244, 250),
		TextMuted = Color3.fromRGB(150, 165, 185),
		Border = Color3.fromRGB(36, 52, 76),
		BorderStrong = Color3.fromRGB(54, 72, 104),
		Accent = Color3.fromRGB(0, 180, 255),
		AccentAlt = Color3.fromRGB(80, 220, 255),
		AccentSoft = Color3.fromRGB(0, 140, 200),
		GradientStart = Color3.fromRGB(0, 180, 255),
		GradientEnd = Color3.fromRGB(120, 90, 255),
	},
	-- Obsidian: deep charcoal with violet accent
	Obsidian = {
		Background = Color3.fromRGB(6, 6, 10),
		Secondary = Color3.fromRGB(10, 10, 16),
		Surface = Color3.fromRGB(14, 14, 22),
		SurfaceHover = Color3.fromRGB(20, 20, 30),
		ElementBackground = Color3.fromRGB(12, 12, 20),
		ElementHover = Color3.fromRGB(18, 18, 28),
		Text = Color3.fromRGB(245, 245, 250),
		TextMuted = Color3.fromRGB(155, 155, 170),
		Border = Color3.fromRGB(35, 35, 50),
		BorderStrong = Color3.fromRGB(50, 50, 70),
		Accent = Color3.fromRGB(160, 90, 255),
		AccentAlt = Color3.fromRGB(200, 130, 255),
		AccentSoft = Color3.fromRGB(110, 60, 200),
		GradientStart = Color3.fromRGB(160, 90, 255),
		GradientEnd = Color3.fromRGB(255, 60, 160),
	},
	-- Aurora: polar night with magenta/cyan shift
	Aurora = {
		Background = Color3.fromRGB(4, 8, 16),
		Secondary = Color3.fromRGB(8, 14, 26),
		Surface = Color3.fromRGB(12, 20, 36),
		SurfaceHover = Color3.fromRGB(18, 28, 48),
		ElementBackground = Color3.fromRGB(10, 16, 28),
		ElementHover = Color3.fromRGB(16, 24, 40),
		Text = Color3.fromRGB(240, 248, 255),
		TextMuted = Color3.fromRGB(140, 160, 185),
		Border = Color3.fromRGB(30, 45, 70),
		BorderStrong = Color3.fromRGB(45, 62, 95),
		Accent = Color3.fromRGB(0, 255, 200),
		AccentAlt = Color3.fromRGB(255, 0, 200),
		AccentSoft = Color3.fromRGB(0, 200, 160),
		GradientStart = Color3.fromRGB(0, 255, 200),
		GradientEnd = Color3.fromRGB(255, 0, 200),
	},
	-- Void: pure black void with electric accent
	Void = {
		Background = Color3.fromRGB(0, 0, 0),
		Secondary = Color3.fromRGB(4, 4, 6),
		Surface = Color3.fromRGB(8, 8, 12),
		SurfaceHover = Color3.fromRGB(14, 14, 20),
		ElementBackground = Color3.fromRGB(6, 6, 10),
		ElementHover = Color3.fromRGB(12, 12, 18),
		Text = Color3.fromRGB(255, 255, 255),
		TextMuted = Color3.fromRGB(160, 160, 170),
		Border = Color3.fromRGB(25, 25, 35),
		BorderStrong = Color3.fromRGB(38, 38, 52),
		Accent = Color3.fromRGB(0, 255, 255),
		AccentAlt = Color3.fromRGB(100, 255, 255),
		AccentSoft = Color3.fromRGB(0, 180, 200),
		GradientStart = Color3.fromRGB(0, 255, 255),
		GradientEnd = Color3.fromRGB(255, 0, 255),
	},
	-- Neon: dark synthwave with hot pink/cyan
	Neon = {
		Background = Color3.fromRGB(10, 5, 15),
		Secondary = Color3.fromRGB(18, 8, 26),
		Surface = Color3.fromRGB(24, 12, 36),
		SurfaceHover = Color3.fromRGB(32, 18, 48),
		ElementBackground = Color3.fromRGB(20, 10, 30),
		ElementHover = Color3.fromRGB(28, 14, 42),
		Text = Color3.fromRGB(255, 240, 255),
		TextMuted = Color3.fromRGB(180, 140, 200),
		Border = Color3.fromRGB(45, 25, 60),
		BorderStrong = Color3.fromRGB(60, 35, 75),
		Accent = Color3.fromRGB(255, 0, 255),
		AccentAlt = Color3.fromRGB(0, 255, 255),
		AccentSoft = Color3.fromRGB(180, 0, 180),
		GradientStart = Color3.fromRGB(255, 0, 255),
		GradientEnd = Color3.fromRGB(0, 255, 255),
	},
	-- Solar: warm gold/amber on dark
	Solar = {
		Background = Color3.fromRGB(14, 10, 6),
		Secondary = Color3.fromRGB(22, 16, 10),
		Surface = Color3.fromRGB(30, 22, 14),
		SurfaceHover = Color3.fromRGB(40, 30, 20),
		ElementBackground = Color3.fromRGB(26, 18, 12),
		ElementHover = Color3.fromRGB(34, 24, 16),
		Text = Color3.fromRGB(255, 245, 230),
		TextMuted = Color3.fromRGB(190, 160, 120),
		Border = Color3.fromRGB(55, 40, 25),
		BorderStrong = Color3.fromRGB(75, 55, 35),
		Accent = Color3.fromRGB(255, 170, 40),
		AccentAlt = Color3.fromRGB(255, 210, 100),
		AccentSoft = Color3.fromRGB(200, 130, 30),
		GradientStart = Color3.fromRGB(255, 170, 40),
		GradientEnd = Color3.fromRGB(255, 60, 0),
	},
	-- Deep: burgundy/maroon elegant
	Deep = {
		Background = Color3.fromRGB(20, 12, 16),
		Secondary = Color3.fromRGB(28, 16, 22),
		Surface = Color3.fromRGB(36, 20, 28),
		SurfaceHover = Color3.fromRGB(48, 28, 38),
		ElementBackground = Color3.fromRGB(32, 18, 26),
		ElementHover = Color3.fromRGB(44, 26, 34),
		Text = Color3.fromRGB(250, 235, 242),
		TextMuted = Color3.fromRGB(160, 120, 140),
		Border = Color3.fromRGB(50, 30, 40),
		BorderStrong = Color3.fromRGB(70, 40, 55),
		Accent = Color3.fromRGB(255, 120, 180),
		AccentAlt = Color3.fromRGB(255, 160, 200),
		AccentSoft = Color3.fromRGB(180, 80, 130),
		GradientStart = Color3.fromRGB(255, 120, 180),
		GradientEnd = Color3.fromRGB(120, 40, 100),
	},
	-- Frost: icy white/blue clean
	Frost = {
		Background = Color3.fromRGB(240, 245, 250),
		Secondary = Color3.fromRGB(232, 238, 245),
		Surface = Color3.fromRGB(255, 255, 255),
		SurfaceHover = Color3.fromRGB(245, 248, 252),
		ElementBackground = Color3.fromRGB(248, 250, 254),
		ElementHover = Color3.fromRGB(240, 244, 250),
		Text = Color3.fromRGB(20, 26, 34),
		TextMuted = Color3.fromRGB(100, 115, 130),
		Border = Color3.fromRGB(200, 210, 220),
		BorderStrong = Color3.fromRGB(170, 185, 200),
		Accent = Color3.fromRGB(40, 140, 255),
		AccentAlt = Color3.fromRGB(80, 180, 255),
		AccentSoft = Color3.fromRGB(30, 110, 200),
		GradientStart = Color3.fromRGB(40, 140, 255),
		GradientEnd = Color3.fromRGB(120, 200, 255),
	},
	-- Emerald: forest green elegant
	Emerald = {
		Background = Color3.fromRGB(6, 14, 12),
		Secondary = Color3.fromRGB(10, 20, 16),
		Surface = Color3.fromRGB(14, 28, 22),
		SurfaceHover = Color3.fromRGB(20, 40, 32),
		ElementBackground = Color3.fromRGB(12, 24, 18),
		ElementHover = Color3.fromRGB(18, 36, 28),
		Text = Color3.fromRGB(230, 250, 240),
		TextMuted = Color3.fromRGB(120, 170, 150),
		Border = Color3.fromRGB(30, 60, 48),
		BorderStrong = Color3.fromRGB(42, 84, 64),
		Accent = Color3.fromRGB(40, 220, 140),
		AccentAlt = Color3.fromRGB(80, 240, 180),
		AccentSoft = Color3.fromRGB(30, 170, 110),
		GradientStart = Color3.fromRGB(40, 220, 140),
		GradientEnd = Color3.fromRGB(0, 150, 100),
	},
	-- Crimson: deep red premium
	Crimson = {
		Background = Color3.fromRGB(16, 6, 8),
		Secondary = Color3.fromRGB(24, 10, 12),
		Surface = Color3.fromRGB(32, 14, 16),
		SurfaceHover = Color3.fromRGB(48, 20, 24),
		ElementBackground = Color3.fromRGB(28, 12, 14),
		ElementHover = Color3.fromRGB(40, 18, 22),
		Text = Color3.fromRGB(250, 232, 236),
		TextMuted = Color3.fromRGB(170, 110, 120),
		Border = Color3.fromRGB(60, 25, 30),
		BorderStrong = Color3.fromRGB(80, 35, 42),
		Accent = Color3.fromRGB(240, 60, 90),
		AccentAlt = Color3.fromRGB(255, 100, 120),
		AccentSoft = Color3.fromRGB(180, 40, 70),
		GradientStart = Color3.fromRGB(240, 60, 90),
		GradientEnd = Color3.fromRGB(120, 20, 40),
	},
}

-- Theme value store. The active theme reads from here.
local themeValues = {
	Style = "Kilo",
	Background = stylePresets.Kilo.Background,
	Secondary = stylePresets.Kilo.Secondary,
	Surface = stylePresets.Kilo.Surface,
	SurfaceHover = stylePresets.Kilo.SurfaceHover,
	ElementBackground = stylePresets.Kilo.ElementBackground,
	ElementHover = stylePresets.Kilo.ElementHover,
	Text = stylePresets.Kilo.Text,
	TextMuted = stylePresets.Kilo.TextMuted,
	Border = stylePresets.Kilo.Border,
	BorderStrong = stylePresets.Kilo.BorderStrong,
	Accent = stylePresets.Kilo.Accent,
	AccentAlt = stylePresets.Kilo.AccentAlt,
	AccentSoft = stylePresets.Kilo.AccentSoft,
	GradientStart = stylePresets.Kilo.GradientStart,
	GradientEnd = stylePresets.Kilo.GradientEnd,

	Success = Color3.fromRGB(76, 220, 137),
	Warning = Color3.fromRGB(247, 185, 78),
	Error = Color3.fromRGB(245, 92, 105),

	Font = Enum.Font.GothamMedium,
	FontBold = Enum.Font.GothamBold,
	FontMono = Enum.Font.Code,

	CornerRadius = 14,
	CornerRadiusSmall = 10,
	ElementHeight = 44,
	SidebarWidth = 202,
	WindowSize = Vector2.new(920, 600),
	Padding = 18,
	Gap = 12,

	TopBarHeight = 72,
	LogoImage = "",
	LogoSize = 50,

	-- Animation timing presets
	EaseFast = 0.14,
	EaseNormal = 0.24,
	EaseSlow = 0.38,
}

local function applyStyle(style: string)
	local preset = stylePresets[style] or stylePresets.Kilo
	themeValues.Background = preset.Background
	themeValues.Secondary = preset.Secondary
	themeValues.Surface = preset.Surface
	themeValues.SurfaceHover = preset.SurfaceHover
	themeValues.ElementBackground = preset.ElementBackground
	themeValues.ElementHover = preset.ElementHover
	themeValues.Text = preset.Text
	themeValues.TextMuted = preset.TextMuted
	themeValues.Border = preset.Border
	themeValues.BorderStrong = preset.BorderStrong
	themeValues.Accent = preset.Accent
	themeValues.AccentAlt = preset.AccentAlt
	themeValues.AccentSoft = preset.AccentSoft
	themeValues.GradientStart = preset.GradientStart or preset.Accent
	themeValues.GradientEnd = preset.GradientEnd or preset.AccentAlt

	-- Layout scales per style family
	if style == "Deep" then
		themeValues.CornerRadius = 10
		themeValues.CornerRadiusSmall = 8
		themeValues.ElementHeight = 40
		themeValues.SidebarWidth = 188
		themeValues.WindowSize = Vector2.new(760, 520)
		themeValues.Padding = 16
		themeValues.Gap = 10
		themeValues.TopBarHeight = 62
		themeValues.LogoSize = 32
	else
		themeValues.CornerRadius = 14
		themeValues.CornerRadiusSmall = 10
		themeValues.ElementHeight = 44
		themeValues.SidebarWidth = 202
		themeValues.WindowSize = Vector2.new(920, 600)
		themeValues.Padding = 18
		themeValues.Gap = 12
		themeValues.TopBarHeight = 72
		themeValues.LogoSize = 50
	end
end

local Theme = {
	Changed = Signal.new(),
	Lerp = lerpColor,
	Hex = hexToColor3,
}

setmetatable(Theme, {
	__index = function(_, key)
		return themeValues[key]
	end,
	__newindex = function(_, key, value)
		if key == "Changed" then
			rawset(Theme, key, value)
			return
		end
		if key == "Style" then
			themeValues.Style = value
			applyStyle(value)
			Theme.Changed:Fire("Style", value)
			return
		end
		if key == "Accent" or key == "GradientStart" or key == "GradientEnd" then
			themeValues[key] = value
			Theme.Changed:Fire(key, value)
			return
		end
		themeValues[key] = value
		Theme.Changed:Fire(key, value)
	end,
})

Theme.Styles = {
	"Kilo", "Obsidian", "Aurora", "Void", "Neon", "Solar", "Deep",
	"Frost", "Emerald", "Crimson", "Vaxorin", "Dark", "Light", "Cyber",
}

function Theme.GetStyles()
	return Theme.Styles
end

function Theme.GetPreset(style: string)
	return stylePresets[style] or stylePresets.Kilo
end

return Theme
