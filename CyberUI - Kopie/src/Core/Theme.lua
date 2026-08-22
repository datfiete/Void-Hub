--!strict
local Signal = require(script.Parent.Parent.Utils.Signal)

-- Vaxorin's design tokens.  The library still accepts the old "Meng" preset
-- as an alias so existing scripts do not break.
local stylePresets = {
    Vaxorin = {
        Background = Color3.fromRGB(6, 8, 13),
        Secondary = Color3.fromRGB(10, 12, 18),
        Surface = Color3.fromRGB(14, 16, 24),
        SurfaceHover = Color3.fromRGB(20, 22, 31),
        ElementBackground = Color3.fromRGB(12, 15, 22),
        ElementHover = Color3.fromRGB(19, 21, 30),
        Text = Color3.fromRGB(244, 244, 248),
        TextMuted = Color3.fromRGB(148, 151, 166),
        Border = Color3.fromRGB(34, 38, 50),
        BorderStrong = Color3.fromRGB(51, 55, 70),
        Accent = Color3.fromRGB(161, 76, 255),
        AccentAlt = Color3.fromRGB(116, 92, 255),
        AccentSoft = Color3.fromRGB(108, 52, 178),
    },
    Dark = {
        Background = Color3.fromRGB(9, 10, 14),
        Secondary = Color3.fromRGB(14, 16, 22),
        Surface = Color3.fromRGB(18, 21, 29),
        SurfaceHover = Color3.fromRGB(24, 28, 38),
        ElementBackground = Color3.fromRGB(15, 18, 24),
        ElementHover = Color3.fromRGB(22, 25, 33),
        Text = Color3.fromRGB(242, 243, 247),
        TextMuted = Color3.fromRGB(154, 158, 171),
        Border = Color3.fromRGB(40, 44, 54),
        BorderStrong = Color3.fromRGB(58, 63, 77),
        Accent = Color3.fromRGB(142, 91, 255),
        AccentAlt = Color3.fromRGB(94, 112, 255),
    },
    Light = {
        Background = Color3.fromRGB(242, 244, 248),
        Secondary = Color3.fromRGB(251, 252, 254),
        Surface = Color3.fromRGB(255, 255, 255),
        SurfaceHover = Color3.fromRGB(246, 247, 251),
        ElementBackground = Color3.fromRGB(247, 248, 251),
        ElementHover = Color3.fromRGB(238, 240, 245),
        Text = Color3.fromRGB(24, 26, 32),
        TextMuted = Color3.fromRGB(104, 108, 119),
        Border = Color3.fromRGB(215, 219, 228),
        BorderStrong = Color3.fromRGB(190, 195, 207),
        Accent = Color3.fromRGB(128, 70, 240),
        AccentAlt = Color3.fromRGB(75, 108, 235),
    },
    Cyber = {
        Background = Color3.fromRGB(8, 11, 18),
        Secondary = Color3.fromRGB(12, 16, 24),
        Surface = Color3.fromRGB(17, 22, 32),
        SurfaceHover = Color3.fromRGB(24, 30, 42),
        ElementBackground = Color3.fromRGB(13, 18, 26),
        ElementHover = Color3.fromRGB(21, 27, 38),
        Text = Color3.fromRGB(230, 237, 248),
        TextMuted = Color3.fromRGB(145, 158, 180),
        Border = Color3.fromRGB(44, 56, 77),
        BorderStrong = Color3.fromRGB(63, 79, 106),
        Accent = Color3.fromRGB(61, 220, 255),
        AccentAlt = Color3.fromRGB(120, 92, 255),
    },
    -- Backwards-compatible alias.
    Meng = {
        Background = Color3.fromRGB(6, 8, 13),
        Secondary = Color3.fromRGB(10, 12, 18),
        Surface = Color3.fromRGB(14, 16, 24),
        SurfaceHover = Color3.fromRGB(20, 22, 31),
        ElementBackground = Color3.fromRGB(12, 15, 22),
        ElementHover = Color3.fromRGB(19, 21, 30),
        Text = Color3.fromRGB(244, 244, 248),
        TextMuted = Color3.fromRGB(148, 151, 166),
        Border = Color3.fromRGB(34, 38, 50),
        BorderStrong = Color3.fromRGB(51, 55, 70),
        Accent = Color3.fromRGB(161, 76, 255),
        AccentAlt = Color3.fromRGB(116, 92, 255),
        AccentSoft = Color3.fromRGB(108, 52, 178),
    },
}

local themeValues = {
    Style = "Vaxorin",
    Background = stylePresets.Vaxorin.Background,
    Secondary = stylePresets.Vaxorin.Secondary,
    Surface = stylePresets.Vaxorin.Surface,
    SurfaceHover = stylePresets.Vaxorin.SurfaceHover,
    ElementBackground = stylePresets.Vaxorin.ElementBackground,
    ElementHover = stylePresets.Vaxorin.ElementHover,
    Text = stylePresets.Vaxorin.Text,
    TextMuted = stylePresets.Vaxorin.TextMuted,
    Border = stylePresets.Vaxorin.Border,
    BorderStrong = stylePresets.Vaxorin.BorderStrong,
    Accent = stylePresets.Vaxorin.Accent,
    AccentAlt = stylePresets.Vaxorin.AccentAlt,
    AccentSoft = stylePresets.Vaxorin.AccentSoft,

    Success = Color3.fromRGB(76, 220, 137),
    Warning = Color3.fromRGB(247, 185, 78),
    Error = Color3.fromRGB(245, 92, 105),

    Font = Enum.Font.GothamMedium,
    FontBold = Enum.Font.GothamBold,

    CornerRadius = 12,
    CornerRadiusSmall = 8,
    ElementHeight = 42,
    SidebarWidth = 220,
    WindowSize = Vector2.new(1180, 760),
    Padding = 16,
    Gap = 10,

    TopBarHeight = 104,
    LogoImage = "",
    LogoSize = 72,
}

local function applyStyle(style)
    local preset = stylePresets[style] or stylePresets.Vaxorin
    themeValues.Background = preset.Background
    themeValues.Secondary = preset.Secondary
    themeValues.Surface = preset.Surface or preset.Secondary
    themeValues.SurfaceHover = preset.SurfaceHover or preset.Secondary
    themeValues.ElementBackground = preset.ElementBackground or preset.Background
    themeValues.ElementHover = preset.ElementHover or preset.Secondary
    themeValues.Text = preset.Text
    themeValues.TextMuted = preset.TextMuted
    themeValues.Border = preset.Border
    themeValues.BorderStrong = preset.BorderStrong or preset.Border
    themeValues.Accent = preset.Accent
    themeValues.AccentAlt = preset.AccentAlt or preset.Accent
    themeValues.AccentSoft = preset.AccentSoft or preset.Accent
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
