--!strict
local Signal = require(script.Parent.Parent.Utils.Signal)

-- Vaxorin's design tokens.  The library still accepts the old "Meng" preset
-- as an alias so existing scripts do not break.
local stylePresets = {
    Vaxorin = {
        -- Layered neutral surfaces keep content readable without relying on glow.
        Background = Color3.fromRGB(8, 10, 16),
        Secondary = Color3.fromRGB(12, 15, 23),
        Surface = Color3.fromRGB(18, 22, 32),
        SurfaceHover = Color3.fromRGB(27, 32, 45),
        ElementBackground = Color3.fromRGB(15, 19, 28),
        ElementHover = Color3.fromRGB(25, 31, 43),
        Text = Color3.fromRGB(242, 244, 250),
        TextMuted = Color3.fromRGB(155, 163, 180),
        Border = Color3.fromRGB(42, 48, 65),
        BorderStrong = Color3.fromRGB(61, 69, 90),
        Accent = Color3.fromRGB(126, 103, 255),
        AccentAlt = Color3.fromRGB(69, 157, 255),
        AccentSoft = Color3.fromRGB(82, 72, 173),
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
    Deep = {
        -- Inspired by Deep Fishing hub palette (mauve / soft pink accent)
        Background = Color3.fromRGB(24, 14, 20),
        Secondary = Color3.fromRGB(29, 17, 24),
        Surface = Color3.fromRGB(35, 20, 29),
        SurfaceHover = Color3.fromRGB(54, 32, 45),
        ElementBackground = Color3.fromRGB(35, 20, 29),
        ElementHover = Color3.fromRGB(54, 32, 45),
        Text = Color3.fromRGB(248, 232, 240),
        TextMuted = Color3.fromRGB(150, 112, 132),
        Border = Color3.fromRGB(50, 29, 41),
        BorderStrong = Color3.fromRGB(70, 40, 55),
        Accent = Color3.fromRGB(255, 158, 200),
        AccentAlt = Color3.fromRGB(255, 120, 180),
        AccentSoft = Color3.fromRGB(180, 90, 130),
    },

    Sakura = {
        Background = Color3.fromRGB(28, 16, 24),
        Secondary = Color3.fromRGB(36, 22, 32),
        Surface = Color3.fromRGB(44, 28, 40),
        SurfaceHover = Color3.fromRGB(62, 38, 54),
        ElementBackground = Color3.fromRGB(40, 26, 36),
        ElementHover = Color3.fromRGB(58, 36, 50),
        Text = Color3.fromRGB(255, 236, 244),
        TextMuted = Color3.fromRGB(196, 140, 168),
        Border = Color3.fromRGB(72, 42, 60),
        BorderStrong = Color3.fromRGB(96, 56, 78),
        Accent = Color3.fromRGB(255, 145, 190),
        AccentAlt = Color3.fromRGB(255, 110, 170),
        AccentSoft = Color3.fromRGB(200, 90, 140),
    },
    Midnight = {
        Background = Color3.fromRGB(8, 10, 18),
        Secondary = Color3.fromRGB(12, 14, 24),
        Surface = Color3.fromRGB(16, 20, 32),
        SurfaceHover = Color3.fromRGB(24, 30, 46),
        ElementBackground = Color3.fromRGB(14, 18, 28),
        ElementHover = Color3.fromRGB(22, 28, 42),
        Text = Color3.fromRGB(230, 236, 250),
        TextMuted = Color3.fromRGB(120, 132, 160),
        Border = Color3.fromRGB(36, 44, 66),
        BorderStrong = Color3.fromRGB(52, 64, 96),
        Accent = Color3.fromRGB(96, 140, 255),
        AccentAlt = Color3.fromRGB(140, 100, 255),
        AccentSoft = Color3.fromRGB(70, 100, 200),
    },
    Ocean = {
        Background = Color3.fromRGB(8, 16, 22),
        Secondary = Color3.fromRGB(12, 22, 30),
        Surface = Color3.fromRGB(16, 28, 38),
        SurfaceHover = Color3.fromRGB(22, 40, 52),
        ElementBackground = Color3.fromRGB(14, 24, 34),
        ElementHover = Color3.fromRGB(20, 36, 48),
        Text = Color3.fromRGB(230, 244, 250),
        TextMuted = Color3.fromRGB(110, 150, 170),
        Border = Color3.fromRGB(30, 56, 70),
        BorderStrong = Color3.fromRGB(42, 78, 96),
        Accent = Color3.fromRGB(56, 200, 220),
        AccentAlt = Color3.fromRGB(40, 160, 255),
        AccentSoft = Color3.fromRGB(40, 140, 160),
    },
    Emerald = {
        Background = Color3.fromRGB(8, 16, 14),
        Secondary = Color3.fromRGB(12, 22, 18),
        Surface = Color3.fromRGB(16, 30, 24),
        SurfaceHover = Color3.fromRGB(24, 44, 34),
        ElementBackground = Color3.fromRGB(14, 26, 20),
        ElementHover = Color3.fromRGB(22, 40, 30),
        Text = Color3.fromRGB(230, 248, 238),
        TextMuted = Color3.fromRGB(110, 160, 130),
        Border = Color3.fromRGB(32, 60, 48),
        BorderStrong = Color3.fromRGB(44, 84, 64),
        Accent = Color3.fromRGB(52, 220, 140),
        AccentAlt = Color3.fromRGB(40, 200, 180),
        AccentSoft = Color3.fromRGB(40, 150, 100),
    },
    Crimson = {
        Background = Color3.fromRGB(18, 8, 10),
        Secondary = Color3.fromRGB(26, 12, 14),
        Surface = Color3.fromRGB(34, 16, 18),
        SurfaceHover = Color3.fromRGB(50, 22, 26),
        ElementBackground = Color3.fromRGB(30, 14, 16),
        ElementHover = Color3.fromRGB(46, 20, 24),
        Text = Color3.fromRGB(250, 232, 234),
        TextMuted = Color3.fromRGB(170, 110, 118),
        Border = Color3.fromRGB(64, 28, 34),
        BorderStrong = Color3.fromRGB(90, 38, 46),
        Accent = Color3.fromRGB(240, 72, 96),
        AccentAlt = Color3.fromRGB(255, 120, 80),
        AccentSoft = Color3.fromRGB(180, 50, 70),
    },
    Amber = {
        Background = Color3.fromRGB(16, 12, 8),
        Secondary = Color3.fromRGB(24, 18, 12),
        Surface = Color3.fromRGB(32, 24, 16),
        SurfaceHover = Color3.fromRGB(46, 34, 22),
        ElementBackground = Color3.fromRGB(28, 20, 14),
        ElementHover = Color3.fromRGB(42, 30, 20),
        Text = Color3.fromRGB(250, 242, 230),
        TextMuted = Color3.fromRGB(170, 140, 100),
        Border = Color3.fromRGB(60, 44, 28),
        BorderStrong = Color3.fromRGB(84, 60, 36),
        Accent = Color3.fromRGB(255, 180, 60),
        AccentAlt = Color3.fromRGB(255, 140, 40),
        AccentSoft = Color3.fromRGB(200, 130, 40),
    },
    Frost = {
        Background = Color3.fromRGB(12, 14, 18),
        Secondary = Color3.fromRGB(18, 20, 26),
        Surface = Color3.fromRGB(24, 28, 36),
        SurfaceHover = Color3.fromRGB(34, 40, 52),
        ElementBackground = Color3.fromRGB(20, 24, 32),
        ElementHover = Color3.fromRGB(30, 36, 48),
        Text = Color3.fromRGB(236, 242, 250),
        TextMuted = Color3.fromRGB(140, 150, 170),
        Border = Color3.fromRGB(48, 56, 70),
        BorderStrong = Color3.fromRGB(70, 80, 100),
        Accent = Color3.fromRGB(180, 220, 255),
        AccentAlt = Color3.fromRGB(140, 200, 255),
        AccentSoft = Color3.fromRGB(100, 150, 200),
    },
    Rose = {
        Background = Color3.fromRGB(20, 10, 14),
        Secondary = Color3.fromRGB(28, 14, 20),
        Surface = Color3.fromRGB(38, 18, 26),
        SurfaceHover = Color3.fromRGB(54, 26, 36),
        ElementBackground = Color3.fromRGB(32, 16, 22),
        ElementHover = Color3.fromRGB(50, 24, 34),
        Text = Color3.fromRGB(255, 236, 242),
        TextMuted = Color3.fromRGB(180, 120, 140),
        Border = Color3.fromRGB(70, 34, 48),
        BorderStrong = Color3.fromRGB(96, 46, 64),
        Accent = Color3.fromRGB(255, 90, 140),
        AccentAlt = Color3.fromRGB(255, 130, 170),
        AccentSoft = Color3.fromRGB(200, 60, 110),
    },
    Neon = {
        Background = Color3.fromRGB(6, 6, 12),
        Secondary = Color3.fromRGB(10, 10, 18),
        Surface = Color3.fromRGB(14, 14, 26),
        SurfaceHover = Color3.fromRGB(22, 22, 40),
        ElementBackground = Color3.fromRGB(12, 12, 22),
        ElementHover = Color3.fromRGB(20, 20, 36),
        Text = Color3.fromRGB(240, 244, 255),
        TextMuted = Color3.fromRGB(130, 140, 180),
        Border = Color3.fromRGB(40, 40, 70),
        BorderStrong = Color3.fromRGB(60, 60, 110),
        Accent = Color3.fromRGB(0, 255, 200),
        AccentAlt = Color3.fromRGB(180, 80, 255),
        AccentSoft = Color3.fromRGB(0, 180, 150),
    },
    Sunset = {
        Background = Color3.fromRGB(18, 10, 14),
        Secondary = Color3.fromRGB(26, 14, 18),
        Surface = Color3.fromRGB(36, 18, 24),
        SurfaceHover = Color3.fromRGB(52, 26, 32),
        ElementBackground = Color3.fromRGB(30, 16, 20),
        ElementHover = Color3.fromRGB(48, 24, 30),
        Text = Color3.fromRGB(255, 240, 236),
        TextMuted = Color3.fromRGB(180, 130, 120),
        Border = Color3.fromRGB(70, 36, 40),
        BorderStrong = Color3.fromRGB(96, 48, 52),
        Accent = Color3.fromRGB(255, 120, 90),
        AccentAlt = Color3.fromRGB(255, 80, 140),
        AccentSoft = Color3.fromRGB(200, 80, 70),
    },
    Forest = {
        Background = Color3.fromRGB(10, 14, 10),
        Secondary = Color3.fromRGB(14, 20, 14),
        Surface = Color3.fromRGB(18, 28, 18),
        SurfaceHover = Color3.fromRGB(26, 40, 26),
        ElementBackground = Color3.fromRGB(16, 24, 16),
        ElementHover = Color3.fromRGB(24, 36, 24),
        Text = Color3.fromRGB(232, 244, 232),
        TextMuted = Color3.fromRGB(120, 150, 120),
        Border = Color3.fromRGB(36, 56, 36),
        BorderStrong = Color3.fromRGB(50, 78, 50),
        Accent = Color3.fromRGB(120, 200, 90),
        AccentAlt = Color3.fromRGB(80, 180, 120),
        AccentSoft = Color3.fromRGB(80, 140, 70),
    },
    Slate = {
        Background = Color3.fromRGB(14, 14, 16),
        Secondary = Color3.fromRGB(20, 20, 24),
        Surface = Color3.fromRGB(28, 28, 34),
        SurfaceHover = Color3.fromRGB(40, 40, 48),
        ElementBackground = Color3.fromRGB(24, 24, 28),
        ElementHover = Color3.fromRGB(36, 36, 44),
        Text = Color3.fromRGB(240, 240, 244),
        TextMuted = Color3.fromRGB(140, 140, 150),
        Border = Color3.fromRGB(50, 50, 58),
        BorderStrong = Color3.fromRGB(70, 70, 80),
        Accent = Color3.fromRGB(160, 170, 190),
        AccentAlt = Color3.fromRGB(120, 140, 180),
        AccentSoft = Color3.fromRGB(100, 110, 130),
    },
    -- Backwards-compatible alias.
    Meng = {
        Background = Color3.fromRGB(4, 6, 10),
        Secondary = Color3.fromRGB(8, 11, 17),
        Surface = Color3.fromRGB(13, 17, 25),
        SurfaceHover = Color3.fromRGB(24, 29, 41),
        ElementBackground = Color3.fromRGB(10, 14, 21),
        ElementHover = Color3.fromRGB(22, 28, 39),
        Text = Color3.fromRGB(244, 244, 248),
        TextMuted = Color3.fromRGB(148, 151, 166),
        Border = Color3.fromRGB(34, 38, 50),
        BorderStrong = Color3.fromRGB(51, 55, 70),
        Accent = Color3.fromRGB(139, 92, 246),
        AccentAlt = Color3.fromRGB(59, 130, 246),
        AccentSoft = Color3.fromRGB(91, 62, 180),
    },

    -- ============================================================
    -- APEX  —  premium glass + electric cyan / magenta redesign
    -- ============================================================
    Apex = {
        Background = Color3.fromRGB(6, 7, 12),
        Secondary = Color3.fromRGB(10, 11, 18),
        Surface = Color3.fromRGB(14, 16, 26),
        SurfaceHover = Color3.fromRGB(22, 25, 40),
        ElementBackground = Color3.fromRGB(12, 14, 22),
        ElementHover = Color3.fromRGB(20, 23, 36),
        Text = Color3.fromRGB(245, 248, 255),
        TextMuted = Color3.fromRGB(140, 150, 175),
        Border = Color3.fromRGB(38, 44, 68),
        BorderStrong = Color3.fromRGB(55, 65, 100),
        Accent = Color3.fromRGB(0, 230, 255),          -- electric cyan
        AccentAlt = Color3.fromRGB(255, 70, 180),      -- hot magenta
        AccentSoft = Color3.fromRGB(0, 160, 200),
    },
}

local themeValues = {
    Style = "Apex",
    Background = stylePresets.Apex.Background,
    Secondary = stylePresets.Apex.Secondary,
    Surface = stylePresets.Apex.Surface,
    SurfaceHover = stylePresets.Apex.SurfaceHover,
    ElementBackground = stylePresets.Apex.ElementBackground,
    ElementHover = stylePresets.Apex.ElementHover,
    Text = stylePresets.Apex.Text,
    TextMuted = stylePresets.Apex.TextMuted,
    Border = stylePresets.Apex.Border,
    BorderStrong = stylePresets.Apex.BorderStrong,
    Accent = stylePresets.Apex.Accent,
    AccentAlt = stylePresets.Apex.AccentAlt,
    AccentSoft = stylePresets.Apex.AccentSoft,

    Success = Color3.fromRGB(60, 230, 160),
    Warning = Color3.fromRGB(255, 190, 70),
    Error = Color3.fromRGB(255, 80, 110),

    Font = Enum.Font.GothamMedium,
    FontBold = Enum.Font.GothamBold,

    CornerRadius = 14,
    CornerRadiusSmall = 10,
    ElementHeight = 44,
    SidebarWidth = 200,
    WindowSize = Vector2.new(920, 600),
    Padding = 18,
    Gap = 12,

    TopBarHeight = 68,
    LogoImage = "",
    LogoSize = 42,
    Focus = stylePresets.Apex.Accent,
    DisabledText = stylePresets.Apex.TextMuted,
    Overlay = Color3.fromRGB(4, 5, 10),
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
    themeValues.Focus = preset.Accent
    themeValues.DisabledText = preset.TextMuted
    themeValues.Overlay = preset.Background

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
    elseif style == "Apex" then
        themeValues.CornerRadius = 14
        themeValues.CornerRadiusSmall = 10
        themeValues.ElementHeight = 44
        themeValues.SidebarWidth = 200
        themeValues.WindowSize = Vector2.new(920, 600)
        themeValues.Padding = 18
        themeValues.Gap = 12
        themeValues.TopBarHeight = 68
        themeValues.LogoSize = 42
    else
        themeValues.CornerRadius = 12
        themeValues.CornerRadiusSmall = 8
        themeValues.ElementHeight = 42
        themeValues.SidebarWidth = 196
        themeValues.WindowSize = Vector2.new(900, 590)
        themeValues.Padding = 16
        themeValues.Gap = 10
        themeValues.TopBarHeight = 64
        themeValues.LogoSize = 40
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

Theme.Styles = {
    "Apex", "Vaxorin", "Deep", "Sakura", "Midnight", "Ocean", "Emerald",
    "Crimson", "Amber", "Frost", "Rose", "Neon", "Sunset", "Forest", "Slate",
    "Dark", "Light", "Cyber", "Meng",
}

function Theme.GetStyles()
    return Theme.Styles
end

return Theme
