--!strict
local Signal = require(script.Parent.Parent.Utils.Signal)

local stylePresets = {
	Dark = {
		Background = Color3.fromRGB(13, 13, 18),
		Secondary = Color3.fromRGB(22, 22, 30),
		Text = Color3.fromRGB(240, 240, 240),
		TextMuted = Color3.fromRGB(160, 160, 170),
		Border = Color3.fromRGB(40, 40, 55),
		Accent = Color3.fromRGB(0, 255, 200),
	},
	Light = {
		Background = Color3.fromRGB(244, 244, 248),
		Secondary = Color3.fromRGB(230, 230, 235),
		Text = Color3.fromRGB(22, 22, 28),
		TextMuted = Color3.fromRGB(110, 110, 120),
		Border = Color3.fromRGB(190, 190, 200),
		Accent = Color3.fromRGB(0, 150, 255),
	},
	Cyber = {
		Background = Color3.fromRGB(15, 15, 40),
		Secondary = Color3.fromRGB(22, 22, 60),
		Text = Color3.fromRGB(225, 240, 255),
		TextMuted = Color3.fromRGB(145, 165, 190),
		Border = Color3.fromRGB(60, 90, 135),
		Accent = Color3.fromRGB(0, 255, 200),
	},
	Meng = {
		Background = Color3.fromRGB(8, 7, 14),
		Secondary = Color3.fromRGB(16, 12, 27),
		Surface = Color3.fromRGB(21, 16, 34),
		SurfaceHover = Color3.fromRGB(30, 22, 48),
		Text = Color3.fromRGB(247, 242, 255),
		TextMuted = Color3.fromRGB(157, 143, 184),
		Border = Color3.fromRGB(59, 39, 83),
		Accent = Color3.fromRGB(190, 92, 255),
		AccentAlt = Color3.fromRGB(64, 218, 255),
	},
}

local themeValues = {
	Style = "Dark",
	Background = stylePresets.Dark.Background,
	Secondary = stylePresets.Dark.Secondary,
	Accent = Color3.fromRGB(0, 255, 200),
	Text = stylePresets.Dark.Text,
	TextMuted = stylePresets.Dark.TextMuted,
	Border = stylePresets.Dark.Border,
	Success = Color3.fromRGB(80, 220, 140),
	Warning = Color3.fromRGB(255, 190, 80),
	Error = Color3.fromRGB(255, 90, 90),

	AccentAlt = Color3.fromRGB(236, 72, 153),
	Surface = Color3.fromRGB(21, 21, 29),
	SurfaceHover = Color3.fromRGB(30, 30, 42),
	Glow = Color3.fromRGB(0, 255, 200),
	SidebarAccent = Color3.fromRGB(255, 255, 255),

	Font = Enum.Font.GothamMedium,
	FontBold = Enum.Font.GothamBold,
	CornerRadius = 10,
	CornerRadiusSmall = 6,
	ElementHeight = 42,
	SidebarWidth = 180,
	WindowSize = Vector2.new(700, 500),
	Padding = 12,
	Gap = 8,

	TopBarHeight = 54,
	LogoImage = "", -- e.g. "rbxassetid://123456789", set via WindowOptions.Logo
	LogoSize = 26,
}

local function applyStyle(style)
	local preset = stylePresets[style]
	if not preset then
		return
	end
	themeValues.Background = preset.Background
	themeValues.Secondary = preset.Secondary
	themeValues.Text = preset.Text
	themeValues.TextMuted = preset.TextMuted
	themeValues.Border = preset.Border
	if preset.Accent then
		themeValues.Accent = preset.Accent
	end
end

local Theme = {
	Changed = Signal.new(),
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
		themeValues[key] = value
		Theme.Changed:Fire(key, value)
	end,
})

return Theme
