--!strict

-- Vaxorin Custom ESP / Visual Layout Designer
-- A renderer-agnostic visual editor. It is intentionally focused on designing
-- the layout and exporting data; the actual world/entity renderer is supplied
-- by the host script.

local Theme = require(script.Parent.Theme)
local Maid = require(script.Parent.Parent.Utils.Maid)
local Helpers = require(script.Parent.Parent.Utils.Helpers)
local Icons = require(script.Parent.Parent.Assets.Icons)

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local ESPBuilder = {}
ESPBuilder.__index = ESPBuilder

export type ElementData = {
    Id: string,
    Type: string,
    Name: string,
    X: number,
    Y: number,
    Width: number,
    Height: number,
    Text: string?,
    Color: Color3?,
    Visible: boolean?,
    Thickness: number?,
    Transparency: number?,
    TextSize: number?,
    Anchor: string?,
}

export type ESPBuilderHandle = {
    Gui: ScreenGui,
    SetSample: (self: ESPBuilderHandle, sample: { [string]: any }) -> (),
    AddElement: (self: ESPBuilderHandle, elementType: string, data: any?) -> string,
    RemoveElement: (self: ESPBuilderHandle, id: string) -> (),
    DuplicateElement: (self: ESPBuilderHandle, id: string?) -> string?,
    MoveElement: (self: ESPBuilderHandle, id: string, deltaX: number, deltaY: number) -> (),
    GetLayout: (self: ESPBuilderHandle) -> { [string]: any },
    SetLayout: (self: ESPBuilderHandle, layout: { [string]: any }) -> (),
    Export: (self: ESPBuilderHandle) -> { [string]: any },
    SetPreset: (self: ESPBuilderHandle, preset: string) -> (),
    GetPresets: (self: ESPBuilderHandle) -> { string },
    OnChanged: (self: ESPBuilderHandle, callback: (layout: any) -> ()) -> RBXScriptConnection,
    Close: (self: ESPBuilderHandle) -> (),
    Open: (self: ESPBuilderHandle) -> (),
}

local DESIGN_W = 420
local DESIGN_H = 430
local PRESETS = { "Custom", "Minimal", "Classic", "Cyber", "Compact", "Full" }

local DEFAULTS: { [string]: { [string]: any } } = {
    Box = { Name = "Box", X = 125, Y = 90, Width = 170, Height = 250, Color = Color3.fromRGB(161, 76, 255), Thickness = 2, Transparency = 0, Anchor = "Center" },
    Name = { Name = "Name", X = 145, Y = 62, Width = 130, Height = 24, Text = "{name}", Color = Color3.fromRGB(245, 245, 248), TextSize = 14, Anchor = "Center" },
    Health = { Name = "Health", X = 145, Y = 34, Width = 130, Height = 22, Text = "{health}/{maxhealth}", Color = Color3.fromRGB(76, 220, 137), TextSize = 13, Anchor = "Center" },
    Distance = { Name = "Distance", X = 145, Y = 350, Width = 130, Height = 22, Text = "{distance}", Color = Color3.fromRGB(220, 225, 235), TextSize = 13, Anchor = "Center" },
    HealthBar = { Name = "Health Bar", X = 116, Y = 92, Width = 6, Height = 246, Color = Color3.fromRGB(76, 220, 137), Thickness = 0, Anchor = "Center" },
    Tracer = { Name = "Tracer", X = 210, Y = 385, Width = 2, Height = 42, Color = Color3.fromRGB(161, 76, 255), Thickness = 2, Anchor = "Center" },
    Weapon = { Name = "Weapon", X = 300, Y = 132, Width = 105, Height = 22, Text = "{weapon}", Color = Color3.fromRGB(245, 245, 248), TextSize = 11, Anchor = "Left" },
    Status = { Name = "Status", X = 300, Y = 158, Width = 105, Height = 22, Text = "{team}", Color = Color3.fromRGB(247, 185, 78), TextSize = 11, Anchor = "Left" },
    CustomText = { Name = "Custom Text", X = 300, Y = 184, Width = 105, Height = 22, Text = "{team} / {distance}", Color = Color3.fromRGB(245, 245, 248), TextSize = 11, Anchor = "Left" },
    Team = { Name = "Team", X = 300, Y = 158, Width = 105, Height = 22, Text = "{team}", Color = Color3.fromRGB(247, 185, 78), TextSize = 11, Anchor = "Left" },
    Class = { Name = "Class", X = 300, Y = 184, Width = 105, Height = 22, Text = "{class}", Color = Color3.fromRGB(190, 190, 210), TextSize = 11, Anchor = "Left" },
    State = { Name = "State", X = 300, Y = 210, Width = 105, Height = 22, Text = "{state}", Color = Color3.fromRGB(190, 190, 210), TextSize = 11, Anchor = "Left" },
    HealthPercent = { Name = "Health %", X = 145, Y = 6, Width = 130, Height = 22, Text = "{health_percent}", Color = Color3.fromRGB(76, 220, 137), TextSize = 11, Anchor = "Center" },
    FilledBox = { Name = "Filled Box", X = 125, Y = 90, Width = 170, Height = 250, Color = Color3.fromRGB(161, 76, 255), Transparency = 0.82, Anchor = "Center" },
    CornerBox = { Name = "Corner Box", X = 125, Y = 90, Width = 170, Height = 250, Color = Color3.fromRGB(161, 76, 255), Thickness = 2, Anchor = "Center" },
    HeadMarker = { Name = "Head Marker", X = 198, Y = 96, Width = 24, Height = 24, Color = Color3.fromRGB(161, 76, 255), Thickness = 2, Anchor = "Center" },
    Skeleton = { Name = "Skeleton", X = 160, Y = 105, Width = 100, Height = 215, Color = Color3.fromRGB(161, 76, 255), Thickness = 2, Anchor = "Center" },
}

local TYPE_ORDER = { "Box", "CornerBox", "FilledBox", "Name", "Health", "HealthPercent", "HealthBar", "Distance", "Tracer", "HeadMarker", "Skeleton", "Weapon", "Team", "Class", "State", "Status", "CustomText" }
local TYPE_LABELS = {
    Box = "Box",
    Name = "Name",
    Health = "Health",
    HealthBar = "Health Bar",
    Distance = "Distance",
    Tracer = "Tracer",
    Weapon = "Weapon",
    Status = "Status",
    CustomText = "Custom Text",
    Team = "Team",
    Class = "Class",
    State = "State",
    HealthPercent = "Health %",
    FilledBox = "Filled Box",
    CornerBox = "Corner Box",
    HeadMarker = "Head Marker",
    Skeleton = "Skeleton",
}

local TYPE_GLYPHS = {
    Box = "BOX", CornerBox = "CORN", FilledBox = "FILL", Name = "TXT", Health = "HP", HealthPercent = "%",
    HealthBar = "BAR", Distance = "DIST", Tracer = "LINE", HeadMarker = "HEAD", Skeleton = "SKEL", Weapon = "ITEM",
    Team = "TEAM", Class = "CLASS", State = "STATE", Status = "STATUS", CustomText = "TEXT",
}

-- Maps ESPBuilder element types → Icons.ESP asset keys.
local TYPE_ICON_KEYS: { [string]: string } = {
    Box = "box",
    CornerBox = "corner_box",
    FilledBox = "filled_box",
    Name = "name",
    Health = "health",
    HealthPercent = "health_percent",
    HealthBar = "health_bar",
    Distance = "distance",
    Tracer = "tracer",
    HeadMarker = "head_marker",
    Skeleton = "skeleton",
    Weapon = "weapon",
    Team = "team",
    Class = "class",
    State = "state",
    Status = "status",
    CustomText = "custom_text",
}

local function getTypeIcon(elementType: string): string?
    local key = TYPE_ICON_KEYS[elementType]
    if not key then
        return nil
    end
    local group = Icons.ESP
    if type(group) == "table" then
        return group[key]
    end
    return nil
end

local function createIconLabel(props: {
    Size: UDim2?,
    Position: UDim2?,
    AnchorPoint: Vector2?,
    Image: string?,
    ImageColor3: Color3?,
    ImageTransparency: number?,
    ZIndex: number?,
    Parent: Instance?,
}): ImageLabel
    local icon = Instance.new("ImageLabel")
    icon.Name = "Icon"
    icon.BackgroundTransparency = 1
    icon.BorderSizePixel = 0
    icon.Size = props.Size or UDim2.fromOffset(20, 20)
    icon.Position = props.Position or UDim2.fromOffset(0, 0)
    if props.AnchorPoint then
        icon.AnchorPoint = props.AnchorPoint
    end
    icon.Image = props.Image or ""
    icon.ImageColor3 = props.ImageColor3 or Theme.Text
    icon.ImageTransparency = props.ImageTransparency or 0
    icon.ScaleType = Enum.ScaleType.Fit
    icon.ZIndex = props.ZIndex or 1
    if props.Parent then
        icon.Parent = props.Parent
    end
    return icon
end

local TYPE_DESCRIPTIONS = {
    Box = "Outline around the target", CornerBox = "Corner-only target outline", FilledBox = "Transparent fill over the target",
    Name = "Display the player name", Health = "Display current health", HealthPercent = "Display health percentage",
    HealthBar = "Vertical health bar", Distance = "Display target distance", Tracer = "Line from target to screen edge",
    HeadMarker = "Marker over the head", Skeleton = "Draw the character skeleton", Weapon = "Display equipped weapon",
    Team = "Display the player's team", Class = "Display the target class", State = "Display the target state",
    Status = "Display additional target status", CustomText = "Custom text with tokens",
}

local function cloneTable(source: { [string]: any }): { [string]: any }
    local out = {}
    for key, value in source do
        out[key] = value
    end
    return out
end

local function cloneElement(source: { [string]: any }): ElementData
    return {
        Id = tostring(source.Id or "element"),
        Type = tostring(source.Type or "CustomText"),
        Name = tostring(source.Name or source.Type or "Element"),
        X = tonumber(source.X) or 0,
        Y = tonumber(source.Y) or 0,
        Width = math.max(4, tonumber(source.Width) or 100),
        Height = math.max(4, tonumber(source.Height) or 24),
        Text = if source.Text ~= nil then tostring(source.Text) else nil,
        Color = if typeof(source.Color) == "Color3" then source.Color else nil,
        Visible = source.Visible ~= false,
        Thickness = math.max(1, tonumber(source.Thickness) or 2),
        Transparency = math.clamp(tonumber(source.Transparency) or 0, 0, 1),
        TextSize = math.clamp(tonumber(source.TextSize) or 12, 6, 40),
        Anchor = tostring(source.Anchor or "Center"),
    }
end

local function color3ToTable(color: Color3?): { R: number, G: number, B: number }
    local c = color or Color3.new(1, 1, 1)
    return {
        R = math.floor(c.R * 255 + 0.5),
        G = math.floor(c.G * 255 + 0.5),
        B = math.floor(c.B * 255 + 0.5),
    }
end

local function tableToColor3(value: any, fallback: Color3): Color3
    if typeof(value) == "Color3" then
        return value
    end
    if type(value) == "table" then
        return Color3.fromRGB(
            math.clamp(tonumber(value.R) or math.floor(fallback.R * 255), 0, 255),
            math.clamp(tonumber(value.G) or math.floor(fallback.G * 255), 0, 255),
            math.clamp(tonumber(value.B) or math.floor(fallback.B * 255), 0, 255)
        )
    end
    return fallback
end

local function parseHex(text: string): Color3?
    local value = string.gsub(text, "#", "")
    if #value ~= 6 then
        return nil
    end
    local r = tonumber(string.sub(value, 1, 2), 16)
    local g = tonumber(string.sub(value, 3, 4), 16)
    local b = tonumber(string.sub(value, 5, 6), 16)
    if not r or not g or not b then
        return nil
    end
    return Color3.fromRGB(r, g, b)
end

local function displayText(element: ElementData, sample: { [string]: any }): string
    local text = element.Text or element.Name
    local health = tonumber(sample.Health) or 0
    local maxHealth = math.max(tonumber(sample.MaxHealth) or 100, 1)
    local distance = tonumber(sample.Distance) or 0
    local percent = math.floor(math.clamp(health / maxHealth, 0, 1) * 100 + 0.5)
    local replacements = {
        ["{name}"] = tostring(sample.Name or "Tom23"),
        ["{health}"] = tostring(health),
        ["{maxhealth}"] = tostring(maxHealth),
        ["{health_percent}"] = tostring(percent) .. "%",
        ["{distance}"] = tostring(distance) .. "m",
        ["{weapon}"] = tostring(sample.Weapon or "Pulse Rifle"),
        ["{team}"] = tostring(sample.Team or "Enemy"),
        ["{class}"] = tostring(sample.Class or "Player"),
        ["{state}"] = tostring(sample.State or "Normal"),
    }
    for key, value in replacements do
        text = string.gsub(text, key, function()
            return value
        end)
    end
    return text
end

function ESPBuilder.new(options: any?): ESPBuilderHandle
    local data = if type(options) == "table" then options else {}
    local self = setmetatable({
        _Maid = Maid.new(),
        _PropertyMaid = Maid.new(),
        _SelectionMaid = Maid.new(),
        _Elements = {} :: { [string]: ElementData },
        _Order = {} :: { string },
        _Selected = nil :: string?,
        _NextId = 0,
        _Preset = "Custom",
        _Zoom = 1,
        _History = {} :: { [number]: any },
        _HistoryIndex = 0,
        _SavedLayouts = type(data.SavedLayouts) == "table" and data.SavedLayouts or {},
        _Changed = Instance.new("BindableEvent"),
        _Sample = {
            Name = tostring(data.SampleName or "Tom23"),
            Health = tonumber(data.SampleHealth) or 58,
            MaxHealth = tonumber(data.SampleMaxHealth) or 100,
            Distance = tonumber(data.SampleDistance) or 42,
            Weapon = tostring(data.SampleWeapon or "Pulse Rifle"),
            Team = tostring(data.SampleTeam or "Enemy"),
            Class = tostring(data.SampleClass or "Player"),
            State = "Normal",
        },
    }, ESPBuilder)

    local parent = data.Parent
    if not parent then
        local localPlayer = Players.LocalPlayer
        if not localPlayer then
            error("ESPBuilder requires a LocalPlayer or an explicit Parent")
        end
        parent = localPlayer:WaitForChild("PlayerGui")
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "VaxorinESPDesigner"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.DisplayOrder = 1001
    gui.Parent = parent
    self.Gui = gui
    gui.Enabled = false

    local width = math.clamp(tonumber(data.Width) or 1380, 1180, 1600)
    local height = math.clamp(tonumber(data.Height) or 760, 620, 900)

    local panel = Helpers.CreateFrame({
        Name = "ESPStudio",
        Size = UDim2.fromOffset(width, height),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Theme.Surface,
        Parent = gui,
    })
    panel.Active = true
    Helpers.Corner(panel, Theme.CornerRadius)
    local panelStroke = Helpers.Stroke(panel, Theme.BorderStrong, 1)
    local panelGlow = Helpers.Glow(panel, Theme.Accent, 16, 0.94)

    local header = Helpers.CreateFrame({
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 66),
        BackgroundColor3 = Theme.Secondary,
        Parent = panel,
    })
    header.Active = true
    Helpers.Corner(header, Theme.CornerRadius)

    local backButton = Helpers.CreateButton({ Name = "Back", Size = UDim2.fromOffset(42, 38), Position = UDim2.fromOffset(12, 14), Text = "", TextColor3 = Theme.Text, TextSize = 24, BackgroundColor3 = Theme.ElementBackground, Parent = header })
    Helpers.Corner(backButton, 10)
    Helpers.Stroke(backButton, Theme.Border, 1)
    do
        local backIcon = Icons.Navigation and Icons.Navigation.back
        if backIcon and backIcon ~= "" then
            createIconLabel({
                Size = UDim2.fromOffset(20, 20),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                AnchorPoint = Vector2.new(0.5, 0.5),
                Image = backIcon,
                ImageColor3 = Theme.Text,
                Parent = backButton,
            })
        else
            backButton.Text = "←"
            backButton.TextSize = 18
            backButton.Font = Theme.FontBold
        end
    end

    local logo = Helpers.CreateFrame({
        Name = "Logo",
        Size = UDim2.fromOffset(38, 38),
        Position = UDim2.fromOffset(62, 14),
        BackgroundColor3 = Theme.ElementBackground,
        Parent = header,
    })
    Helpers.Corner(logo, 10)
    Helpers.Stroke(logo, Theme.Accent, 1)
    Helpers.CreateLabel({
        Name = "LogoGlyph",
        Size = UDim2.fromScale(1, 1),
        Text = "V",
        TextColor3 = Theme.Accent,
        TextSize = 23,
        Font = Theme.FontBold,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = logo,
    })

    Helpers.CreateLabel({
        Name = "Title",
        Size = UDim2.new(0, 340, 0, 25),
        Position = UDim2.fromOffset(112, 9),
        Text = "ESP Builder",
        TextColor3 = Theme.Text,
        TextSize = 17,
        Font = Theme.FontBold,
        Parent = header,
    })
    Helpers.CreateLabel({
        Name = "Subtitle",
        Size = UDim2.new(0, 480, 0, 18),
        Position = UDim2.fromOffset(112, 34),
        Text = "Create and preview your ESP layout visually.",
        TextColor3 = Theme.TextMuted,
        TextSize = 9,
        Parent = header,
    })

    local presetButton = Helpers.CreateButton({
        Name = "Preset",
        Size = UDim2.fromOffset(170, 42),
        Position = UDim2.new(1, -590, 0, 12),
        Text = "Preset\nCustom",
        TextColor3 = Theme.Text,
        TextSize = 9,
        Font = Theme.FontBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundColor3 = Theme.ElementBackground,
        Parent = header,
    })
    Helpers.Corner(presetButton, 8)
    Helpers.Stroke(presetButton, Theme.Border, 1)
    local presetChevron = Helpers.CreateLabel({
        Name = "Chevron",
        Size = UDim2.fromOffset(25, 42),
        Position = UDim2.new(1, -30, 0, 0),
        Text = "DOWN",
        TextColor3 = Theme.TextMuted,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = presetButton,
    })

    local function decorateHeaderAction(button: TextButton, iconKey: string, label: string)
        button.Text = ""
        local nav = Icons.Navigation
        local asset = if type(nav) == "table" then nav[iconKey] else nil
        if asset and asset ~= "" then
            createIconLabel({
                Size = UDim2.fromOffset(16, 16),
                Position = UDim2.fromOffset(10, 13),
                Image = asset,
                ImageColor3 = Theme.Text,
                Parent = button,
            })
            Helpers.CreateLabel({
                Size = UDim2.new(1, -30, 1, 0),
                Position = UDim2.fromOffset(28, 0),
                Text = label,
                TextColor3 = Theme.Text,
                TextSize = 10,
                Font = Theme.FontBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = button,
            })
        else
            button.Text = label
            button.TextSize = 10
            button.Font = Theme.FontBold
            button.TextColor3 = Theme.Text
        end
    end

    local saveButton = Helpers.CreateButton({ Name = "Save", Size = UDim2.fromOffset(82, 42), Position = UDim2.new(1, -414, 0, 12), Text = "", TextColor3 = Theme.Text, TextSize = 10, Font = Theme.FontBold, BackgroundColor3 = Theme.ElementBackground, Parent = header })
    Helpers.Corner(saveButton, 8)
    Helpers.Stroke(saveButton, Theme.Border, 1)
    decorateHeaderAction(saveButton, "save", "SAVE")

    local importButton = Helpers.CreateButton({ Name = "Import", Size = UDim2.fromOffset(82, 42), Position = UDim2.new(1, -326, 0, 12), Text = "", TextColor3 = Theme.Text, TextSize = 10, Font = Theme.FontBold, BackgroundColor3 = Theme.ElementBackground, Parent = header })
    Helpers.Corner(importButton, 8)
    Helpers.Stroke(importButton, Theme.Border, 1)
    decorateHeaderAction(importButton, "import", "IMPORT")

    local exportButton = Helpers.CreateButton({ Name = "Export", Size = UDim2.fromOffset(92, 42), Position = UDim2.new(1, -218, 0, 12), Text = "", TextColor3 = Theme.Text, TextSize = 10, Font = Theme.FontBold, BackgroundColor3 = Theme.ElementBackground, Parent = header })
    Helpers.Corner(exportButton, 8)
    Helpers.Stroke(exportButton, Theme.Border, 1)
    decorateHeaderAction(exportButton, "export", "EXPORT")

    local doneButton = Helpers.CreateButton({ Name = "Done", Size = UDim2.fromOffset(96, 42), Position = UDim2.new(1, -114, 0, 12), Text = "Done", TextColor3 = Color3.new(1, 1, 1), TextSize = 10, Font = Theme.FontBold, BackgroundColor3 = Theme.Accent, Parent = header })
    Helpers.Corner(doneButton, 8)

    local body = Helpers.CreateFrame({ Name = "Body", Size = UDim2.new(1, -24, 1, -130), Position = UDim2.fromOffset(12, 72), BackgroundTransparency = 1, Parent = panel })

    -- Left: component library.
    local components = Helpers.CreateFrame({ Name = "Components", Size = UDim2.new(0, 250, 1, 0), BackgroundColor3 = Theme.Background, Parent = body })
    Helpers.Corner(components, Theme.CornerRadiusSmall)
    local componentsStroke = Helpers.Stroke(components, Theme.Border, 1)
    Helpers.CreateLabel({ Name = "Title", Size = UDim2.new(1, -24, 0, 24), Position = UDim2.fromOffset(12, 9), Text = "ELEMENTS", TextColor3 = Theme.Text, TextSize = 11, Font = Theme.FontBold, Parent = components })
    local search = Helpers.CreateTextBox({ Name = "Search", Size = UDim2.new(1, -24, 0, 34), Position = UDim2.fromOffset(12, 38), PlaceholderText = "Search elements...", Text = "", TextColor3 = Theme.Text, PlaceholderColor3 = Theme.TextMuted, TextSize = 9, BackgroundColor3 = Theme.ElementBackground, Parent = components })
    Helpers.Corner(search, 7)
    Helpers.Stroke(search, Theme.Border, 1)

    local componentList = Instance.new("ScrollingFrame")
    componentList.Name = "ComponentList"
    componentList.Size = UDim2.new(1, -24, 1, -142)
    componentList.Position = UDim2.fromOffset(12, 82)
    componentList.BackgroundTransparency = 1
    componentList.BorderSizePixel = 0
    componentList.ScrollBarThickness = 3
    componentList.AutomaticCanvasSize = Enum.AutomaticSize.Y
    componentList.CanvasSize = UDim2.new()
    componentList.Parent = components
    Helpers.ListLayout(componentList, 7)

    local customAdd = Helpers.CreateButton({ Name = "CustomAdd", Size = UDim2.new(1, -24, 0, 40), Position = UDim2.new(0, 12, 1, -52), Text = "+  Add custom element", TextColor3 = Theme.Accent, TextSize = 10, Font = Theme.FontBold, BackgroundColor3 = Theme.AccentSoft, Parent = components })
    Helpers.Corner(customAdd, 7)
    Helpers.Stroke(customAdd, Theme.Accent, 1)

    -- Center: live designer.
    local preview = Helpers.CreateFrame({ Name = "Preview", Size = UDim2.new(1, -770, 1, 0), Position = UDim2.fromOffset(258, 0), BackgroundColor3 = Theme.Background, Parent = body })
    Helpers.Corner(preview, Theme.CornerRadiusSmall)
    local previewStroke = Helpers.Stroke(preview, Theme.Border, 1)
    Helpers.CreateLabel({ Name = "Title", Size = UDim2.new(1, -24, 0, 24), Position = UDim2.fromOffset(12, 9), Text = "LIVE PREVIEW", TextColor3 = Theme.Text, TextSize = 11, Font = Theme.FontBold, Parent = preview })

    local entityButton = Helpers.CreateButton({ Name = "Entity", Size = UDim2.fromOffset(155, 32), Position = UDim2.fromOffset(12, 38), Text = "PLAYER", TextColor3 = Theme.Text, TextSize = 9, BackgroundColor3 = Theme.ElementBackground, Parent = preview })
    Helpers.Corner(entityButton, 7)
    Helpers.Stroke(entityButton, Theme.Border, 1)
    local stateButton = Helpers.CreateButton({ Name = "State", Size = UDim2.fromOffset(135, 32), Position = UDim2.fromOffset(174, 38), Text = "NORMAL", TextColor3 = Theme.Text, TextSize = 9, BackgroundColor3 = Theme.ElementBackground, Parent = preview })
    Helpers.Corner(stateButton, 7)

    local zoomOut = Helpers.CreateButton({ Name = "ZoomOut", Size = UDim2.fromOffset(32, 32), Position = UDim2.new(1, -106, 0, 38), Text = "-", TextColor3 = Theme.TextMuted, TextSize = 16, BackgroundColor3 = Theme.ElementBackground, Parent = preview })
    Helpers.Corner(zoomOut, 7)
    local zoomLabel = Helpers.CreateLabel({ Name = "Zoom", Size = UDim2.fromOffset(52, 32), Position = UDim2.new(1, -72, 0, 38), Text = "100%", TextColor3 = Theme.Text, TextSize = 9, Font = Theme.FontBold, TextXAlignment = Enum.TextXAlignment.Center, Parent = preview })
    local zoomIn = Helpers.CreateButton({ Name = "ZoomIn", Size = UDim2.fromOffset(32, 32), Position = UDim2.new(1, -32, 0, 38), Text = "+", TextColor3 = Theme.TextMuted, TextSize = 16, BackgroundColor3 = Theme.ElementBackground, Parent = preview })
    Helpers.Corner(zoomIn, 7)

    local canvasHost = Helpers.CreateFrame({ Name = "CanvasHost", Size = UDim2.new(1, -24, 1, -82), Position = UDim2.fromOffset(12, 76), BackgroundColor3 = Theme.Secondary, Parent = preview })
    Helpers.Corner(canvasHost, Theme.CornerRadiusSmall)
    local canvasStroke = Helpers.Stroke(canvasHost, Theme.Border, 1)
    canvasHost.ClipsDescendants = true

    local designCanvas = Helpers.CreateFrame({ Name = "DesignCanvas", Size = UDim2.fromOffset(DESIGN_W, DESIGN_H), Position = UDim2.new(0.5, -DESIGN_W / 2, 0.5, -DESIGN_H / 2), BackgroundColor3 = Theme.Background, Parent = canvasHost })
    Helpers.Corner(designCanvas, 10)
    local designStroke = Helpers.Stroke(designCanvas, Theme.BorderStrong, 1)
    designCanvas.ClipsDescendants = true

    -- Editor grid.
    local grid = Helpers.CreateFrame({ Name = "Grid", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = designCanvas })
    grid.ZIndex = 1
    for x = 1, 9 do
        local line = Helpers.CreateFrame({ Name = "V" .. x, Size = UDim2.new(0, 1, 1, 0), Position = UDim2.new(x / 10, 0, 0, 0), BackgroundColor3 = Theme.Border, BackgroundTransparency = 0.84, Parent = grid })
        line.ZIndex = 1
    end
    for y = 1, 8 do
        local line = Helpers.CreateFrame({ Name = "H" .. y, Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, y / 9, 0), BackgroundColor3 = Theme.Border, BackgroundTransparency = 0.86, Parent = grid })
        line.ZIndex = 1
    end

    -- Dummy character.
    local dummy = Helpers.CreateFrame({ Name = "Dummy", Size = UDim2.fromOffset(100, 215), Position = UDim2.fromOffset(160, 105), BackgroundTransparency = 1, Parent = designCanvas })
    dummy.ZIndex = 3
    local head = Helpers.CreateFrame({ Name = "Head", Size = UDim2.fromOffset(42, 42), Position = UDim2.fromOffset(29, 0), BackgroundColor3 = Theme.TextMuted, Parent = dummy })
    Helpers.Corner(head, 8)
    local torso = Helpers.CreateFrame({ Name = "Torso", Size = UDim2.fromOffset(58, 72), Position = UDim2.fromOffset(21, 48), BackgroundColor3 = Theme.TextMuted, Parent = dummy })
    Helpers.Corner(torso, 7)
    local leftArm = Helpers.CreateFrame({ Name = "LeftArm", Size = UDim2.fromOffset(16, 70), Position = UDim2.fromOffset(2, 49), BackgroundColor3 = Theme.TextMuted, Parent = dummy })
    Helpers.Corner(leftArm, 6)
    local rightArm = Helpers.CreateFrame({ Name = "RightArm", Size = UDim2.fromOffset(16, 70), Position = UDim2.fromOffset(82, 49), BackgroundColor3 = Theme.TextMuted, Parent = dummy })
    Helpers.Corner(rightArm, 6)
    local leftLeg = Helpers.CreateFrame({ Name = "LeftLeg", Size = UDim2.fromOffset(25, 82), Position = UDim2.fromOffset(22, 120), BackgroundColor3 = Theme.TextMuted, Parent = dummy })
    Helpers.Corner(leftLeg, 6)
    local rightLeg = Helpers.CreateFrame({ Name = "RightLeg", Size = UDim2.fromOffset(25, 82), Position = UDim2.fromOffset(53, 120), BackgroundColor3 = Theme.TextMuted, Parent = dummy })
    Helpers.Corner(rightLeg, 6)

    local centerGuide = Helpers.CreateFrame({ Name = "CenterGuide", Size = UDim2.new(0, 1, 1, -20), Position = UDim2.new(0.5, 0, 0, 10), BackgroundColor3 = Theme.Accent, BackgroundTransparency = 0.9, Parent = designCanvas })
    centerGuide.ZIndex = 2

    -- Right-middle: layer list.
    local layers = Helpers.CreateFrame({ Name = "Layers", Size = UDim2.fromOffset(235, 1), Position = UDim2.new(1, -502, 0, 0), BackgroundColor3 = Theme.Background, Parent = body })
    layers.Size = UDim2.new(0, 235, 1, 0)
    Helpers.Corner(layers, Theme.CornerRadiusSmall)
    local layersStroke = Helpers.Stroke(layers, Theme.Border, 1)
    Helpers.CreateLabel({ Name = "Title", Size = UDim2.new(1, -24, 0, 24), Position = UDim2.fromOffset(12, 9), Text = "ELEMENT LIST", TextColor3 = Theme.Text, TextSize = 11, Font = Theme.FontBold, Parent = layers })
    local layerList = Instance.new("ScrollingFrame")
    layerList.Name = "LayerList"
    layerList.Size = UDim2.new(1, -24, 1, -72)
    layerList.Position = UDim2.fromOffset(12, 38)
    layerList.BackgroundTransparency = 1
    layerList.BorderSizePixel = 0
    layerList.ScrollBarThickness = 3
    layerList.AutomaticCanvasSize = Enum.AutomaticSize.Y
    layerList.CanvasSize = UDim2.new()
    layerList.Parent = layers
    Helpers.ListLayout(layerList, 6)
    local addLayerButton = Helpers.CreateButton({ Name = "Add", Size = UDim2.new(1, -24, 0, 34), Position = UDim2.new(0, 12, 1, -46), Text = "+  Add element", TextColor3 = Theme.Accent, TextSize = 9, Font = Theme.FontBold, BackgroundColor3 = Theme.AccentSoft, Parent = layers })
    Helpers.Corner(addLayerButton, 7)
    Helpers.Stroke(addLayerButton, Theme.Accent, 1)

    -- Far right: properties.
    local properties = Helpers.CreateFrame({ Name = "Properties", Size = UDim2.fromOffset(255, 1), Position = UDim2.new(1, -255, 0, 0), BackgroundColor3 = Theme.Background, Parent = body })
    properties.Size = UDim2.new(0, 255, 1, 0)
    Helpers.Corner(properties, Theme.CornerRadiusSmall)
    local propertiesStroke = Helpers.Stroke(properties, Theme.Border, 1)
    Helpers.CreateLabel({ Name = "Title", Size = UDim2.new(1, -24, 0, 24), Position = UDim2.fromOffset(12, 9), Text = "PROPERTIES", TextColor3 = Theme.Text, TextSize = 11, Font = Theme.FontBold, Parent = properties })
    local propertyScroll = Instance.new("ScrollingFrame")
    propertyScroll.Name = "PropertyScroll"
    propertyScroll.Size = UDim2.new(1, -20, 1, -42)
    propertyScroll.Position = UDim2.fromOffset(10, 34)
    propertyScroll.BackgroundTransparency = 1
    propertyScroll.BorderSizePixel = 0
    propertyScroll.ScrollBarThickness = 3
    propertyScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    propertyScroll.CanvasSize = UDim2.new()
    propertyScroll.Parent = properties
    Helpers.ListLayout(propertyScroll, 7)

    local footer = Helpers.CreateFrame({ Name = "Footer", Size = UDim2.new(1, -24, 0, 42), Position = UDim2.new(0, 12, 1, -50), BackgroundColor3 = Theme.Background, Parent = panel })
    Helpers.Corner(footer, 8)
    Helpers.Stroke(footer, Theme.Border, 1)
    local footerLayout = Helpers.ListLayout(footer, 7, true, Enum.FillDirection.Horizontal)
    footerLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    local layoutButton = Helpers.CreateButton({ Name = "Layout", Size = UDim2.fromOffset(150, 30), Text = "LAYOUT  DOWN", TextColor3 = Theme.Text, TextSize = 9, BackgroundColor3 = Theme.ElementBackground, Parent = footer })
    Helpers.Corner(layoutButton, 7)
    Helpers.Stroke(layoutButton, Theme.Border, 1)
    local undoButton = Helpers.CreateButton({ Name = "Undo", Size = UDim2.fromOffset(34, 30), Text = "UNDO", TextColor3 = Theme.TextMuted, TextSize = 16, BackgroundColor3 = Theme.ElementBackground, Parent = footer })
    Helpers.Corner(undoButton, 7)
    local redoButton = Helpers.CreateButton({ Name = "Redo", Size = UDim2.fromOffset(34, 30), Text = "REDO", TextColor3 = Theme.TextMuted, TextSize = 16, BackgroundColor3 = Theme.ElementBackground, Parent = footer })
    Helpers.Corner(redoButton, 7)
    local footerHint = Helpers.CreateLabel({ Name = "Hint", Size = UDim2.new(1, -520, 0, 30), Text = "Click an element to select it  |  Drag to move  |  Drag the corner handle to resize", TextColor3 = Theme.TextMuted, TextSize = 8, Parent = footer })
    footerHint.LayoutOrder = 5
    local footerZoom = Helpers.CreateLabel({ Name = "Zoom", Size = UDim2.fromOffset(100, 30), Text = "Zoom 100%", TextColor3 = Theme.TextMuted, TextSize = 8, TextXAlignment = Enum.TextXAlignment.Right, Parent = footer })
    footerZoom.LayoutOrder = 6

    -- Save / Import manager. Saved layouts live in a shared table supplied by Window,
    -- so closing and reopening the designer in the same window keeps them available.
    local modal = Helpers.CreateFrame({ Name = "StorageModal", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.38, Visible = false, Parent = gui })
    modal.ZIndex = 100

    local modalPanel = Helpers.CreateFrame({ Name = "Panel", Size = UDim2.fromOffset(520, 470), Position = UDim2.new(0.5, -260, 0.5, -235), BackgroundColor3 = Theme.Background, Parent = modal })
    modalPanel.ZIndex = 101
    Helpers.Corner(modalPanel, 12)
    Helpers.Stroke(modalPanel, Theme.BorderStrong, 1)
    local modalTitle = Helpers.CreateLabel({ Name = "Title", Size = UDim2.new(1, -80, 0, 34), Position = UDim2.fromOffset(18, 14), Text = "Saved Layouts", TextColor3 = Theme.Text, TextSize = 14, Font = Theme.FontBold, Parent = modalPanel })
    modalTitle.ZIndex = 102
    local modalClose = Helpers.CreateButton({ Name = "Close", Size = UDim2.fromOffset(34, 30), Position = UDim2.new(1, -46, 0, 12), Text = "X", TextColor3 = Theme.TextMuted, TextSize = 11, BackgroundColor3 = Theme.ElementBackground, Parent = modalPanel })
    modalClose.ZIndex = 102
    Helpers.Corner(modalClose, 7)

    local nameInput = Helpers.CreateTextBox({ Name = "NameInput", Size = UDim2.new(1, -36, 0, 36), Position = UDim2.fromOffset(18, 58), PlaceholderText = "Layout name...", Text = "", TextColor3 = Theme.Text, PlaceholderColor3 = Theme.TextMuted, TextSize = 10, BackgroundColor3 = Theme.ElementBackground, Parent = modalPanel })
    nameInput.ZIndex = 102
    Helpers.Corner(nameInput, 7)
    Helpers.Stroke(nameInput, Theme.Border, 1)
    local modalAction = Helpers.CreateButton({ Name = "Action", Size = UDim2.fromOffset(110, 36), Position = UDim2.new(1, -128, 0, 58), Text = "SAVE", TextColor3 = Color3.new(1,1,1), TextSize = 9, Font = Theme.FontBold, BackgroundColor3 = Theme.Accent, Parent = modalPanel })
    modalAction.ZIndex = 102
    Helpers.Corner(modalAction, 7)

    local savedList = Instance.new("ScrollingFrame")
    savedList.Name = "SavedList"
    savedList.Size = UDim2.new(1, -36, 1, -112)
    savedList.Position = UDim2.fromOffset(18, 102)
    savedList.BackgroundTransparency = 1
    savedList.BorderSizePixel = 0
    savedList.ScrollBarThickness = 3
    savedList.AutomaticCanvasSize = Enum.AutomaticSize.Y
    savedList.CanvasSize = UDim2.new()
    savedList.ZIndex = 102
    savedList.Parent = modalPanel
    Helpers.ListLayout(savedList, 6)

    local modalHint = Helpers.CreateLabel({ Name = "Hint", Size = UDim2.new(1, -36, 0, 22), Position = UDim2.new(0, 18, 1, -28), Text = "Saved layouts are kept for this UI session. Use Export for a portable JSON copy.", TextColor3 = Theme.TextMuted, TextSize = 8, Parent = modalPanel })
    modalHint.ZIndex = 102

    local modalMode = "import"
    local function closeStorageModal()
        modal.Visible = false
    end

    local function refreshSavedList()
        for _, child in ipairs(savedList:GetChildren()) do
            if child:IsA("GuiButton") or child:IsA("TextLabel") then
                child:Destroy()
            end
        end
        local count = 0
        for _, entry in ipairs(self._SavedLayouts) do
            if type(entry) == "table" and type(entry.Layout) == "table" then
                count += 1
                local row = Helpers.CreateButton({ Name = "Saved", Size = UDim2.new(1, -2, 0, 48), Text = "", AutoButtonColor = false, BackgroundColor3 = Theme.ElementBackground, Parent = savedList })
                row.ZIndex = 103
                Helpers.Corner(row, 7)
                Helpers.Stroke(row, Theme.Border, 1)
                local title = Helpers.CreateLabel({ Size = UDim2.new(1, -140, 0, 20), Position = UDim2.fromOffset(12, 5), Text = tostring(entry.Name or "Unnamed"), TextColor3 = Theme.Text, TextSize = 9, Font = Theme.FontBold, Parent = row })
                title.ZIndex = 104
                local details = Helpers.CreateLabel({ Size = UDim2.new(1, -140, 0, 15), Position = UDim2.fromOffset(12, 26), Text = tostring(#(entry.Layout.Elements or {})) .. " elements", TextColor3 = Theme.TextMuted, TextSize = 7, Parent = row })
                details.ZIndex = 104
                local load = Helpers.CreateButton({ Size = UDim2.fromOffset(54, 30), Position = UDim2.new(1, -116, 0, 9), Text = "LOAD", TextColor3 = Theme.Text, TextSize = 8, Font = Theme.FontBold, BackgroundColor3 = Theme.AccentSoft, Parent = row })
                load.ZIndex = 104
                Helpers.Corner(load, 6)
                local del = Helpers.CreateButton({ Size = UDim2.fromOffset(54, 30), Position = UDim2.new(1, -58, 0, 9), Text = "DELETE", TextColor3 = Theme.Error, TextSize = 7, Font = Theme.FontBold, BackgroundColor3 = Theme.ElementBackground, Parent = row })
                del.ZIndex = 104
                Helpers.Corner(del, 6)
                local captured = entry
                self._Maid:GiveTask(load.MouseButton1Click:Connect(function()
                    self:SetLayout(cloneTable(captured.Layout))
                    self._Preset = tostring(captured.Layout.Preset or "Custom")
                    closeStorageModal()
                end))
                self._Maid:GiveTask(del.MouseButton1Click:Connect(function()
                    for i, value in ipairs(self._SavedLayouts) do
                        if value == captured then table.remove(self._SavedLayouts, i); break end
                    end
                    refreshSavedList()
                end))
            end
        end
        if count == 0 then
            local empty = Helpers.CreateLabel({ Size = UDim2.new(1, -2, 0, 60), Text = "No saved layouts yet.\nPress SAVE to create one.", TextColor3 = Theme.TextMuted, TextSize = 9, TextWrapped = true, Parent = savedList })
            empty.ZIndex = 103
        end
    end

    local function openImportModal()
        modalMode = "import"
        modalTitle.Text = "Saved Layouts"
        nameInput.Visible = false
        modalAction.Visible = false
        modalHint.Text = "Select LOAD to use a saved layout. Export creates a portable JSON copy."
        savedList.Position = UDim2.fromOffset(18, 58)
        savedList.Size = UDim2.new(1, -36, 1, -88)
        refreshSavedList()
        modal.Visible = true
    end

    local function openSaveModal()
        modalMode = "save"
        modalTitle.Text = "Save Layout"
        nameInput.Visible = true
        modalAction.Visible = true
        nameInput.Text = "Layout " .. tostring(#self._SavedLayouts + 1)
        modalHint.Text = "Enter a name, then press SAVE. Existing names will be replaced."
        savedList.Position = UDim2.fromOffset(18, 104)
        savedList.Size = UDim2.new(1, -36, 1, -134)
        refreshSavedList()
        modal.Visible = true
        task.defer(function()
            pcall(function() nameInput:CaptureFocus() end)
        end)
    end

    local previewInstances: { [string]: GuiObject } = {}
    local previewHitboxes: { [string]: TextButton } = {}
    local selectedOverlay: Frame? = nil
    local selectedHandles: { TextButton } = {}
    local listButtons: { [string]: TextButton } = {}
    local componentButtons: { [string]: TextButton } = {}
    local render: () -> ()
    local refreshLayers: () -> ()
    local refreshProperties: () -> ()
    local updateSelection: () -> ()

    local function getSelected(): ElementData?
        if self._Selected then
            return self._Elements[self._Selected]
        end
        return nil
    end

    local function pushHistory()
        while #self._History > self._HistoryIndex do
            table.remove(self._History)
        end
        table.insert(self._History, self:GetLayout())
        if #self._History > 30 then
            table.remove(self._History, 1)
        end
        self._HistoryIndex = #self._History
    end

    local function notifyChanged()
        self._Changed:Fire(self:GetLayout())
    end

    local function nextId(elementType: string): string
        self._NextId += 1
        return string.lower(string.gsub(elementType, "%s", "_")) .. "_" .. tostring(self._NextId)
    end

    local function scale(): number
        return designCanvas.AbsoluteSize.X / DESIGN_W
    end

    local function clampElement(element: ElementData)
        element.Width = math.clamp(element.Width, 4, DESIGN_W)
        element.Height = math.clamp(element.Height, 4, DESIGN_H)
        element.X = math.clamp(element.X, 0, math.max(0, DESIGN_W - element.Width))
        element.Y = math.clamp(element.Y, 0, math.max(0, DESIGN_H - element.Height))
    end

    local function makePropertyLabel(text: string): TextLabel
        return Helpers.CreateLabel({ Size = UDim2.new(1, 0, 0, 17), Text = text, TextColor3 = Theme.TextMuted, TextSize = 8, Font = Theme.FontBold, Parent = propertyScroll })
    end

    local function makeTextProperty(labelText: string, value: string, callback: (string) -> ())
        makePropertyLabel(labelText)
        local box = Helpers.CreateTextBox({ Size = UDim2.new(1, 0, 0, 30), Text = value, TextColor3 = Theme.Text, TextSize = 9, BackgroundColor3 = Theme.ElementBackground, Parent = propertyScroll })
        Helpers.Corner(box, 6)
        Helpers.Stroke(box, Theme.Border, 1)
        self._PropertyMaid:GiveTask(box.FocusLost:Connect(function()
            callback(box.Text)
        end))
        return box
    end

    local function makeNumberProperty(labelText: string, value: number, callback: (number) -> ())
        makePropertyLabel(labelText)
        local box = Helpers.CreateTextBox({ Size = UDim2.new(1, 0, 0, 30), Text = tostring(math.floor(value + 0.5)), TextColor3 = Theme.Text, TextSize = 9, BackgroundColor3 = Theme.ElementBackground, Parent = propertyScroll })
        Helpers.Corner(box, 6)
        Helpers.Stroke(box, Theme.Border, 1)
        self._PropertyMaid:GiveTask(box.FocusLost:Connect(function()
            local n = tonumber(box.Text)
            if n then callback(n) end
            refreshProperties()
            render()
            refreshLayers()
            notifyChanged()
        end))
        return box
    end

    local function makeToggle(labelText: string, value: boolean, callback: (boolean) -> ())
        local button = Helpers.CreateButton({ Size = UDim2.new(1, 0, 0, 32), Text = labelText .. "     " .. (if value then "ON" else "OFF"), TextColor3 = if value then Theme.Text else Theme.TextMuted, TextSize = 9, BackgroundColor3 = if value then Theme.AccentSoft else Theme.ElementBackground, Parent = propertyScroll })
        Helpers.Corner(button, 6)
        Helpers.Stroke(button, if value then Theme.Accent else Theme.Border, 1)
        self._PropertyMaid:GiveTask(button.MouseButton1Click:Connect(function()
            callback(not value)
            refreshProperties()
            render()
            refreshLayers()
            notifyChanged()
        end))
        return button
    end

    local function makeChoice(labelText: string, value: string, choices: { string }, callback: (string) -> ())
        makePropertyLabel(labelText)
        local index = table.find(choices, value) or 1
        local button = Helpers.CreateButton({ Size = UDim2.new(1, 0, 0, 30), Text = value .. "  DOWN", TextColor3 = Theme.Text, TextSize = 9, BackgroundColor3 = Theme.ElementBackground, Parent = propertyScroll })
        Helpers.Corner(button, 6)
        Helpers.Stroke(button, Theme.Border, 1)
        self._PropertyMaid:GiveTask(button.MouseButton1Click:Connect(function()
            index = index % #choices + 1
            callback(choices[index])
            refreshProperties()
            render()
            refreshLayers()
            notifyChanged()
        end))
        return button
    end

    local function addColorProperty(element: ElementData)
        makePropertyLabel("COLOR")
        local row = Helpers.CreateFrame({ Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = Theme.ElementBackground, Parent = propertyScroll })
        Helpers.Corner(row, 6)
        Helpers.Stroke(row, Theme.Border, 1)
        local swatch = Helpers.CreateFrame({ Size = UDim2.fromOffset(22, 22), Position = UDim2.fromOffset(6, 5), BackgroundColor3 = element.Color or Theme.Accent, Parent = row })
        Helpers.Corner(swatch, 5)
        local hex = Helpers.CreateTextBox({ Size = UDim2.new(1, -38, 1, 0), Position = UDim2.fromOffset(34, 0), Text = Helpers.ColorToHex(element.Color or Theme.Accent), TextColor3 = Theme.Text, TextSize = 9, BackgroundTransparency = 1, Parent = row })
        self._PropertyMaid:GiveTask(hex.FocusLost:Connect(function()
            local color = parseHex(hex.Text)
            if color then
                element.Color = color
            end
            refreshProperties()
            render()
            notifyChanged()
        end))
    end

    local function clearPropertyScroll()
        self._PropertyMaid:DoCleaning()
        for _, child in propertyScroll:GetChildren() do
            if child:IsA("GuiObject") then
                child:Destroy()
            end
        end
    end

    refreshProperties = function()
        clearPropertyScroll()
        local element = getSelected()
        if not element then
            Helpers.CreateLabel({ Size = UDim2.new(1, -8, 0, 70), Text = "Select an element to edit its\nposition, size, text and style.", TextColor3 = Theme.TextMuted, TextSize = 9, TextWrapped = true, Parent = propertyScroll })
            return
        end

        local title = Helpers.CreateLabel({ Size = UDim2.new(1, 0, 0, 38), Text = element.Name .. "\n" .. string.upper(element.Type), TextColor3 = Theme.Text, TextSize = 11, Font = Theme.FontBold, TextYAlignment = Enum.TextYAlignment.Center, Parent = propertyScroll })
        title.TextXAlignment = Enum.TextXAlignment.Left
        makeTextProperty("ELEMENT NAME", element.Name, function(v) element.Name = v end)
        makePropertyLabel("POSITION")
        makeNumberProperty("X", element.X, function(v) element.X = v end)
        makeNumberProperty("Y", element.Y, function(v) element.Y = v end)
        makePropertyLabel("SIZE")
        makeNumberProperty("Width", element.Width, function(v) element.Width = v end)
        makeNumberProperty("Height", element.Height, function(v) element.Height = v end)

        if element.Text ~= nil or element.Type == "Name" or element.Type == "Health" or element.Type == "Distance" or element.Type == "Weapon" or element.Type == "Status" or element.Type == "Team" or element.Type == "Class" or element.Type == "State" or element.Type == "HealthPercent" or element.Type == "CustomText" then
            makeTextProperty("TEXT / FORMAT", element.Text or "", function(v) element.Text = v end)
            if element.Type == "CustomText" then
                local hint = Helpers.CreateLabel({ Size = UDim2.new(1, 0, 0, 44), Text = "Tokens: {name}  {health}  {maxhealth}\n{health_percent}  {distance}  {weapon}\n{team}  {class}  {state}", TextColor3 = Theme.TextMuted, TextSize = 7, TextWrapped = true, Parent = propertyScroll })
                hint.LayoutOrder = 999
            end
        end

        makeNumberProperty("Text Size", element.TextSize or 12, function(v) element.TextSize = math.clamp(v, 6, 40) end)
        makeChoice("ANCHOR", element.Anchor or "Center", { "Center", "Left", "Right", "Top", "Bottom" }, function(v) element.Anchor = v end)
        addColorProperty(element)
        makeNumberProperty("Line width", element.Thickness or 2, function(v) element.Thickness = math.max(1, v) end)
        makeNumberProperty("Transparency (0-1)", element.Transparency or 0, function(v) element.Transparency = math.clamp(v, 0, 1) end)
        makeToggle("Visible", element.Visible ~= false, function(v) element.Visible = v end)

        local duplicate = Helpers.CreateButton({ Size = UDim2.new(1, 0, 0, 30), Text = "Duplicate Element", TextColor3 = Theme.Text, TextSize = 9, BackgroundColor3 = Theme.ElementBackground, Parent = propertyScroll })
        Helpers.Corner(duplicate, 6)
        Helpers.Stroke(duplicate, Theme.Border, 1)
        self._PropertyMaid:GiveTask(duplicate.MouseButton1Click:Connect(function()
            self:DuplicateElement(element.Id)
        end))

        local remove = Helpers.CreateButton({ Size = UDim2.new(1, 0, 0, 30), Text = "Remove Element", TextColor3 = Theme.Error, TextSize = 9, BackgroundColor3 = Theme.ElementBackground, Parent = propertyScroll })
        Helpers.Corner(remove, 6)
        Helpers.Stroke(remove, Theme.Border, 1)
        self._PropertyMaid:GiveTask(remove.MouseButton1Click:Connect(function()
            self:RemoveElement(element.Id)
        end))
    end

    updateSelection = function()
        if selectedOverlay then
            selectedOverlay:Destroy()
            selectedOverlay = nil
        end
        table.clear(selectedHandles)
        local element = getSelected()
        if not element then return end
        local object = previewInstances[element.Id]
        if not object then return end

        selectedOverlay = Helpers.CreateFrame({ Name = "Selection", Size = object.Size, Position = object.Position, BackgroundTransparency = 1, Parent = designCanvas })
        selectedOverlay.ZIndex = 50
        selectedOverlay.Active = false
        Helpers.Stroke(selectedOverlay, Theme.Accent, 1)

        local handle = Helpers.CreateButton({ Name = "ResizeHandle", Size = UDim2.fromOffset(10, 10), Position = UDim2.new(1, -5, 1, -5), Text = "", BackgroundColor3 = Theme.Accent, Parent = selectedOverlay })
        handle.ZIndex = 55
        Helpers.Corner(handle, 3)
        table.insert(selectedHandles, handle)

        self._SelectionMaid:DoCleaning()
        local resizing = false
        local resizeStart = Vector2.zero
        local startW = element.Width
        local startH = element.Height
        self._SelectionMaid:GiveTask(handle.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                pushHistory()
                resizing = true
                resizeStart = input.Position
                startW = element.Width
                startH = element.Height
            end
        end))
        self._SelectionMaid:GiveTask(UserInputService.InputChanged:Connect(function(input)
            if not resizing then return end
            if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
            local s = scale()
            element.Width = math.clamp(startW + (input.Position.X - resizeStart.X) / s, 4, DESIGN_W - element.X)
            element.Height = math.clamp(startH + (input.Position.Y - resizeStart.Y) / s, 4, DESIGN_H - element.Y)
            render()
            refreshLayers()
        end))
        self._SelectionMaid:GiveTask(UserInputService.InputEnded:Connect(function(input)
            if resizing and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
                resizing = false
                refreshProperties()
                notifyChanged()
            end
        end))
    end

    local function createPreviewLine(parent: Instance, x1: number, y1: number, x2: number, y2: number, thickness: number, color: Color3)
        local line = Helpers.CreateFrame({ Size = UDim2.fromOffset(math.max((Vector2.new(x2, y2) - Vector2.new(x1, y1)).Magnitude, 1), math.max(thickness, 1)), BackgroundColor3 = color, Parent = parent })
        line.AnchorPoint = Vector2.new(0.5, 0.5)
        line.Position = UDim2.fromOffset((x1 + x2) * 0.5, (y1 + y2) * 0.5)
        line.Rotation = math.deg(math.atan2(y2 - y1, x2 - x1))
        line.BorderSizePixel = 0
        return line
    end

    local function getDesignBox()
        for _, id in ipairs(self._Order) do
            local candidate = self._Elements[id]
            if candidate and candidate.Type == "Box" and candidate.Visible ~= false then
                return candidate
            end
        end
        return { X = 125, Y = 90, Width = 170, Height = 250 }
    end

    local function designPosition(element: ElementData)
        local box = getDesignBox()
        local sx = math.max(box.Width, 1) / 170
        local sy = math.max(box.Height, 1) / 250
        local centerX = box.X + box.Width * 0.5
        local centerY = box.Y + box.Height * 0.5
        local baseCenterX = 210
        local baseCenterY = 215
        local cx = centerX + ((element.X + element.Width * 0.5) - baseCenterX) * sx
        local cy = centerY + ((element.Y + element.Height * 0.5) - baseCenterY) * sy
        return cx - element.Width * sx * 0.5, cy - element.Height * sy * 0.5, element.Width * sx, element.Height * sy
    end

    local function renderElement(element: ElementData)
        local object = previewInstances[element.Id]
        local isText = element.Type == "Name" or element.Type == "Health" or element.Type == "HealthPercent" or element.Type == "Distance" or element.Type == "Weapon" or element.Type == "Team" or element.Type == "Class" or element.Type == "State" or element.Type == "Status" or element.Type == "CustomText"
        if not object then
            if isText then
                object = Helpers.CreateLabel({ Name = "ESP_" .. element.Id, Text = "", TextColor3 = element.Color or Theme.Text, TextSize = element.TextSize or 12, Font = Theme.FontBold, BackgroundTransparency = 1, TextStrokeTransparency = 0.6, TextXAlignment = if element.Anchor == "Left" then Enum.TextXAlignment.Left else if element.Anchor == "Right" then Enum.TextXAlignment.Right else Enum.TextXAlignment.Center, Parent = designCanvas })
            else
                object = Helpers.CreateFrame({ Name = "ESP_" .. element.Id, BackgroundColor3 = element.Color or Theme.Accent, BackgroundTransparency = element.Transparency or 0, Parent = designCanvas })
            end
            object.ZIndex = 8
            previewInstances[element.Id] = object
        end

        local hitbox = previewHitboxes[element.Id]
        if not hitbox then
            hitbox = Helpers.CreateButton({ Name = "Hitbox_" .. element.Id, Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Parent = designCanvas })
            hitbox.Active = true
            previewHitboxes[element.Id] = hitbox
            local captured = element.Id
            self._Maid:GiveTask(hitbox.InputBegan:Connect(function(input)
                if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
                local current = self._Elements[captured]
                if not current then return end
                self._Selected = captured
                refreshLayers()
                refreshProperties()
                updateSelection()
                pushHistory()
                local start = input.Position
                local startX, startY = current.X, current.Y
                local moving = true
                local moveConnection
                local endConnection
                moveConnection = UserInputService.InputChanged:Connect(function(changed)
                    if not moving then return end
                    if changed.UserInputType ~= Enum.UserInputType.MouseMovement and changed.UserInputType ~= Enum.UserInputType.Touch then return end
                    local s = scale()
                    current.X = math.clamp(startX + (changed.Position.X - start.X) / s, 0, DESIGN_W - current.Width)
                    current.Y = math.clamp(startY + (changed.Position.Y - start.Y) / s, 0, DESIGN_H - current.Height)
                    render()
                    if selectedOverlay then
                        local selectedObject = previewInstances[captured]
                        if selectedObject then
                            selectedOverlay.Position = selectedObject.Position
                        end
                    end
                end)
                endConnection = UserInputService.InputEnded:Connect(function(ended)
                    if ended.UserInputType == Enum.UserInputType.MouseButton1 or ended.UserInputType == Enum.UserInputType.Touch then
                        moving = false
                        if moveConnection then moveConnection:Disconnect() end
                        if endConnection then endConnection:Disconnect() end
                        refreshProperties()
                        refreshLayers()
                        notifyChanged()
                    end
                end)
            end))
        end

        for _, child in object:GetChildren() do
            if child:IsA("UIStroke") or child:IsA("Frame") or child:IsA("UICorner") then
                child:Destroy()
            end
        end

        local previewX, previewY, previewW, previewH = designPosition(element)
        object.Position = UDim2.fromOffset(previewX, previewY)
        object.Size = UDim2.fromOffset(previewW, previewH)
        object.Visible = element.Visible ~= false
        object.ZIndex = if element.Type == "FilledBox" then 4 else 8
        hitbox.Position = object.Position
        hitbox.Size = object.Size
        hitbox.Visible = object.Visible
        local orderIndex = table.find(self._Order, element.Id) or 1
        hitbox.ZIndex = 40 + orderIndex
        local color = element.Color or Theme.Accent

        if isText and object:IsA("TextLabel") then
            object.Text = displayText(element, self._Sample)
            object.TextColor3 = color
            object.TextSize = element.TextSize or 12
            object.TextXAlignment = if element.Anchor == "Left" then Enum.TextXAlignment.Left else if element.Anchor == "Right" then Enum.TextXAlignment.Right else Enum.TextXAlignment.Center
            object.TextYAlignment = Enum.TextYAlignment.Center
            object.TextStrokeTransparency = math.clamp((element.Transparency or 0) + 0.35, 0, 1)
        elseif object:IsA("Frame") then
            object.BackgroundColor3 = color
            object.BackgroundTransparency = element.Transparency or 0
            if element.Type == "Box" then
                object.BackgroundTransparency = 1
                local stroke = Helpers.Stroke(object, color, element.Thickness or 2)
                stroke.Name = "ESPStroke"
            elseif element.Type == "CornerBox" then
                object.BackgroundTransparency = 1
                local t = math.max(element.Thickness or 2, 1)
                local len = math.max(math.min(element.Width, element.Height) * 0.22, 8)
                local parts = {
                    {0, 0, len, t}, {0, 0, t, len}, {element.Width-len, 0, len, t}, {element.Width-t, 0, t, len},
                    {0, element.Height-t, len, t}, {0, element.Height-len, t, len}, {element.Width-len, element.Height-t, len, t}, {element.Width-t, element.Height-len, t, len},
                }
                for i, part in ipairs(parts) do
                    local f = Helpers.CreateFrame({ Name = "Corner" .. tostring(i), Size = UDim2.fromOffset(part[3], part[4]), Position = UDim2.fromOffset(part[1], part[2]), BackgroundColor3 = color, Parent = object })
                    f.ZIndex = 9
                end
            elseif element.Type == "FilledBox" then
                object.BackgroundTransparency = math.clamp(element.Transparency or 0.82, 0, 1)
            elseif element.Type == "HeadMarker" then
                object.BackgroundTransparency = 1
                Helpers.Corner(object, 1)
                local stroke = Helpers.Stroke(object, color, element.Thickness or 2)
                stroke.Name = "MarkerStroke"
            elseif element.Type == "Skeleton" then
                object.BackgroundTransparency = 1
                local t = math.max(element.Thickness or 2, 1)
                local x = element.Width * 0.5
                local points = {
                    {x, 8, x, 48}, {x, 48, x, 112}, {x, 60, 18, 82}, {x, 60, element.Width-18, 82},
                    {18, 82, 12, 142}, {element.Width-18, 82, element.Width-12, 142},
                    {x, 112, x-18, 174}, {x, 112, x+18, 174}, {x-18, 174, x-20, element.Height-4}, {x+18, 174, x+20, element.Height-4},
                }
                for i, p in ipairs(points) do
                    local f = createPreviewLine(object, p[1], p[2], p[3], p[4], t, color)
                    f.ZIndex = 9
                    f.Name = "Bone" .. tostring(i)
                end
            elseif element.Type == "HealthBar" then
                object.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
                object.BackgroundTransparency = 0.25
                local ratio = math.clamp((tonumber(self._Sample.Health) or 0) / math.max(tonumber(self._Sample.MaxHealth) or 100, 1), 0, 1)
                local fill = Helpers.CreateFrame({ Name = "Fill", Size = UDim2.new(1, 0, ratio, 0), Position = UDim2.new(0, 0, 1 - ratio, 0), BackgroundColor3 = color, Parent = object })
                fill.ZIndex = 9
            elseif element.Type == "Tracer" then
                object.BackgroundTransparency = 1
                local centerX = element.Width * 0.5
                local line = createPreviewLine(object, centerX, 0, centerX, element.Height, math.max(element.Thickness or element.Width or 2, 1), color)
                line.Name = "TracerLine"
                line.ZIndex = 9
            end
        end
    end

    render = function()
        for _, id in self._Order do
            local element = self._Elements[id]
            if element then
                clampElement(element)
                renderElement(element)
            end
        end
        for id, object in previewInstances do
            if not self._Elements[id] then
                object:Destroy()
                previewInstances[id] = nil
                local hitbox = previewHitboxes[id]
                if hitbox then
                    hitbox:Destroy()
                    previewHitboxes[id] = nil
                end
            end
        end
        if selectedOverlay then
            local selected = getSelected()
            local object = selected and previewInstances[selected.Id]
            if object then
                selectedOverlay.Size = object.Size
                selectedOverlay.Position = object.Position
                selectedOverlay.Visible = object.Visible
            end
        end
        zoomLabel.Text = tostring(math.floor(self._Zoom * 100 + 0.5)) .. "%"
        footerZoom.Text = "Zoom " .. tostring(math.floor(self._Zoom * 100 + 0.5)) .. "%"
    end

    local function refreshComponents()
        for _, child in componentList:GetChildren() do
            if child:IsA("GuiButton") then child:Destroy() end
        end
        table.clear(componentButtons)
        local query = string.lower(search.Text or "")
        for _, elementType in TYPE_ORDER do
            local label = TYPE_LABELS[elementType]
            if query == "" or string.find(string.lower(label), query, 1, true) then
                local button = Helpers.CreateButton({ Size = UDim2.new(1, -2, 0, 48), Text = "", BackgroundColor3 = Theme.ElementBackground, Parent = componentList })
                Helpers.Corner(button, 7)
                Helpers.Stroke(button, Theme.Border, 1)

                local iconAsset = getTypeIcon(elementType)
                if iconAsset and iconAsset ~= "" then
                    createIconLabel({
                        Size = UDim2.fromOffset(22, 22),
                        Position = UDim2.fromOffset(12, 13),
                        Image = iconAsset,
                        ImageColor3 = Theme.Accent,
                        Parent = button,
                    })
                else
                    Helpers.CreateLabel({
                        Size = UDim2.fromOffset(30, 48),
                        Position = UDim2.fromOffset(8, 0),
                        Text = TYPE_GLYPHS[elementType] or "EL",
                        TextColor3 = Theme.Accent,
                        TextSize = 16,
                        Font = Theme.FontBold,
                        TextXAlignment = Enum.TextXAlignment.Center,
                        Parent = button,
                    })
                end

                Helpers.CreateLabel({ Size = UDim2.new(1, -50, 0, 20), Position = UDim2.fromOffset(46, 5), Text = label, TextColor3 = Theme.Text, TextSize = 9, Font = Theme.FontBold, Parent = button })
                Helpers.CreateLabel({ Size = UDim2.new(1, -50, 0, 16), Position = UDim2.fromOffset(46, 25), Text = TYPE_DESCRIPTIONS[elementType] or "Additional target information", TextColor3 = Theme.TextMuted, TextSize = 7, Parent = button })
                componentButtons[elementType] = button
                self._Maid:GiveTask(button.MouseButton1Click:Connect(function() self:AddElement(elementType) end))
            end
        end
    end

    refreshLayers = function()
        for _, child in layerList:GetChildren() do
            if child:IsA("GuiButton") or child:IsA("Frame") then child:Destroy() end
        end
        table.clear(listButtons)
        for reverse = #self._Order, 1, -1 do
            local id = self._Order[reverse]
            local element = self._Elements[id]
            if element then
                local row = Helpers.CreateButton({ Size = UDim2.new(1, -2, 0, 46), Text = "", BackgroundColor3 = if self._Selected == id then Theme.AccentSoft else Theme.ElementBackground, Parent = layerList })
                Helpers.Corner(row, 7)
                Helpers.Stroke(row, if self._Selected == id then Theme.Accent else Theme.Border, 1)
                local eye = Helpers.CreateButton({ Size = UDim2.fromOffset(28, 42), Position = UDim2.fromOffset(2, 2), Text = if element.Visible ~= false then "ON" else "OFF", TextColor3 = if element.Visible ~= false then Theme.Accent else Theme.TextMuted, TextSize = 13, BackgroundTransparency = 1, Parent = row })

                local layerIconAsset = getTypeIcon(element.Type)
                local textOffset = 34
                if layerIconAsset and layerIconAsset ~= "" then
                    createIconLabel({
                        Size = UDim2.fromOffset(16, 16),
                        Position = UDim2.fromOffset(32, 15),
                        Image = layerIconAsset,
                        ImageColor3 = if self._Selected == id then Theme.Accent else Theme.TextMuted,
                        Parent = row,
                    })
                    textOffset = 54
                end

                local name = Helpers.CreateLabel({ Size = UDim2.new(1, -(textOffset + 40), 0, 20), Position = UDim2.fromOffset(textOffset, 5), Text = element.Name, TextColor3 = Theme.Text, TextSize = 9, Font = Theme.FontBold, Parent = row })
                local typeLabel = Helpers.CreateLabel({ Size = UDim2.new(1, -(textOffset + 40), 0, 15), Position = UDim2.fromOffset(textOffset, 24), Text = TYPE_LABELS[element.Type] or element.Type, TextColor3 = Theme.TextMuted, TextSize = 7, Parent = row })
                local move = Helpers.CreateLabel({ Size = UDim2.fromOffset(30, 42), Position = UDim2.new(1, -34, 0, 2), Text = "DRAG", TextColor3 = Theme.TextMuted, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Center, Parent = row })
                listButtons[id] = row
                local captured = id
                self._Maid:GiveTask(row.MouseButton1Click:Connect(function() self._Selected = captured; refreshLayers(); refreshProperties(); updateSelection() end))
                self._Maid:GiveTask(eye.MouseButton1Click:Connect(function()
                    element.Visible = not (element.Visible ~= false)
                    refreshLayers(); render(); refreshProperties(); notifyChanged()
                end))
            end
        end
    end

    function self:AddElement(elementType: string, elementData: any?): string
        local defaults = DEFAULTS[elementType] or DEFAULTS.CustomText
        local source = cloneTable(defaults)
        if type(elementData) == "table" then
            for key, value in elementData do source[key] = value end
        end
        local id = tostring(source.Id or nextId(elementType))
        source.Id = id
        source.Type = elementType
        local element = cloneElement(source)
        element.Color = element.Color or Theme.Accent
        self._Elements[id] = element
        table.insert(self._Order, id)
        self._Selected = id
        pushHistory()
        refreshLayers(); refreshProperties(); render(); updateSelection(); notifyChanged()
        return id
    end

    function self:RemoveElement(id: string)
        if not self._Elements[id] then return end
        pushHistory()
        self._Elements[id] = nil
        for i, value in self._Order do
            if value == id then table.remove(self._Order, i); break end
        end
        if self._Selected == id then self._Selected = self._Order[#self._Order] end
        refreshLayers(); refreshProperties(); render(); updateSelection(); notifyChanged()
    end

    function self:DuplicateElement(id: string?): string?
        local source = self._Elements[id or self._Selected or ""]
        if not source then return nil end
        local copy = cloneTable(source :: any)
        copy.Id = nextId(source.Type)
        copy.Name = source.Name .. " Copy"
        copy.X = math.min(DESIGN_W - source.Width, source.X + 12)
        copy.Y = math.min(DESIGN_H - source.Height, source.Y + 12)
        return self:AddElement(source.Type, copy)
    end

    function self:MoveElement(id: string, deltaX: number, deltaY: number)
        local element = self._Elements[id]
        if not element then return end
        element.X += deltaX
        element.Y += deltaY
        clampElement(element)
        render(); refreshLayers(); refreshProperties(); notifyChanged()
    end

    function self:SetSample(sample: { [string]: any })
        for key, value in sample do self._Sample[key] = value end
        render()
    end

    function self:GetLayout(): { [string]: any }
        local elements = {}
        for _, id in self._Order do
            local element = self._Elements[id]
            if element then
                table.insert(elements, {
                    Id = element.Id,
                    Type = element.Type,
                    Name = element.Name,
                    X = element.X,
                    Y = element.Y,
                    Width = element.Width,
                    Height = element.Height,
                    Text = element.Text,
                    Visible = element.Visible ~= false,
                    Thickness = element.Thickness,
                    Transparency = element.Transparency,
                    TextSize = element.TextSize,
                    Anchor = element.Anchor,
                    Color = color3ToTable(element.Color),
                })
            end
        end
        return {
            Version = 2,
            Canvas = { Width = DESIGN_W, Height = DESIGN_H },
            Preset = self._Preset,
            Elements = elements,
        }
    end

    function self:Export(): { [string]: any }
        local layout = self:GetLayout()
        local encoded = ""
        pcall(function() encoded = game:GetService("HttpService"):JSONEncode(layout) end)
        if encoded ~= "" and setclipboard then
            pcall(function() setclipboard(encoded) end)
        end
        if type(data.OnExport) == "function" then
            pcall(data.OnExport, layout, encoded)
        end
        return layout
    end

    function self:SetLayout(layout: { [string]: any })
        table.clear(self._Elements)
        table.clear(self._Order)
        self._Selected = nil
        self._NextId = 0
        self._Preset = tostring(layout.Preset or "Custom")
        for _, raw in ipairs(layout.Elements or {}) do
            local elementType = tostring(raw.Type or "CustomText")
            local defaults = DEFAULTS[elementType] or DEFAULTS.CustomText
            local source = cloneTable(defaults)
            for key, value in raw do source[key] = value end
            source.Color = tableToColor3(raw.Color, defaults.Color or Theme.Accent)
            local element = cloneElement(source)
            element.Id = tostring(source.Id or nextId(elementType))
            element.Type = elementType
            element.Color = element.Color or Theme.Accent
            self._Elements[element.Id] = element
            table.insert(self._Order, element.Id)
        end
        self._Selected = self._Order[#self._Order]
        refreshLayers(); refreshProperties(); render(); updateSelection(); notifyChanged()
    end

    function self:SetPreset(preset: string)
        if not table.find(PRESETS, preset) then return end
        if preset == "Custom" then
            self._Preset = preset
            presetButton.Text = "Preset\n" .. preset
            return
        end
        pushHistory()
        table.clear(self._Elements)
        table.clear(self._Order)
        self._Selected = nil
        local definitions = {}
        if preset == "Minimal" then
            definitions = { { "Box", {} }, { "Name", {} }, { "HealthBar", {} } }
        elseif preset == "Classic" then
            definitions = { { "Box", {} }, { "Name", {} }, { "Health", {} }, { "Distance", {} } }
        elseif preset == "Cyber" then
            definitions = { { "Box", { Color = Theme.Accent } }, { "Name", {} }, { "Health", {} }, { "Distance", {} }, { "Tracer", {} }, { "Status", {} } }
        elseif preset == "Compact" then
            definitions = { { "Box", { X = 145, Y = 100, Width = 130, Height = 205 } }, { "Name", { X = 145, Y = 76, Width = 130 } }, { "Health", { X = 145, Y = 310, Width = 130 } }, { "Distance", { X = 145, Y = 334, Width = 130 } } }
        elseif preset == "Full" then
            definitions = {
                { "Box", {} }, { "CornerBox", {} }, { "Name", {} }, { "Health", {} },
                { "HealthBar", {} }, { "Distance", {} }, { "HeadMarker", {} }, { "Skeleton", {} },
                { "Tracer", {} }, { "Team", {} }, { "Weapon", {} }, { "State", {} },
            }
        end
        self._Preset = preset
        for _, definition in definitions do self:AddElement(definition[1], definition[2]) end
        presetButton.Text = "Preset\n" .. preset
        refreshLayers(); refreshProperties(); render(); updateSelection(); notifyChanged()
    end

    function self:GetPresets(): { string }
        return table.clone(PRESETS)
    end

    function self:OnChanged(callback: (layout: any) -> ())
        return self._Changed.Event:Connect(callback)
    end

    local presetIndex = 1
    self._Maid:GiveTask(presetButton.MouseButton1Click:Connect(function()
        presetIndex = presetIndex % #PRESETS + 1
        self:SetPreset(PRESETS[presetIndex])
    end))
    self._Maid:GiveTask(backButton.MouseButton1Click:Connect(function()
        if type(data.OnBack) == "function" then
            pcall(data.OnBack, self:GetLayout())
        else
            self:Close()
        end
    end))
    self._Maid:GiveTask(saveButton.MouseButton1Click:Connect(function() openSaveModal() end))
    self._Maid:GiveTask(importButton.MouseButton1Click:Connect(function() openImportModal() end))
    self._Maid:GiveTask(modalClose.MouseButton1Click:Connect(closeStorageModal))
    self._Maid:GiveTask(modalAction.MouseButton1Click:Connect(function()
        local name = string.gsub(tostring(nameInput.Text or ""), "^%s*(.-)%s*$", "%1")
        if name == "" then name = "Layout " .. tostring(#self._SavedLayouts + 1) end
        local layout = self:GetLayout()
        local saved = { Name = name, Layout = cloneTable(layout), SavedAt = os.time() }
        local replaced = false
        for i, entry in ipairs(self._SavedLayouts) do
            if type(entry) == "table" and tostring(entry.Name or "") == name then
                self._SavedLayouts[i] = saved
                replaced = true
                break
            end
        end
        if not replaced then table.insert(self._SavedLayouts, saved) end
        if type(data.OnSave) == "function" then pcall(data.OnSave, layout, name, cloneTable(self._SavedLayouts)) end
        closeStorageModal()
    end))
    self._Maid:GiveTask(exportButton.MouseButton1Click:Connect(function() self:Export() end))
    self._Maid:GiveTask(doneButton.MouseButton1Click:Connect(function() self:Close() end))
    self._Maid:GiveTask(customAdd.MouseButton1Click:Connect(function() self:AddElement("CustomText", { Name = "Custom Text", Text = "{name}" }) end))
    self._Maid:GiveTask(addLayerButton.MouseButton1Click:Connect(function() self:AddElement("CustomText", { Name = "Custom Text", Text = "{name}" }) end))
    self._Maid:GiveTask(search:GetPropertyChangedSignal("Text"):Connect(refreshComponents))

    self._Maid:GiveTask(zoomOut.MouseButton1Click:Connect(function()
        self._Zoom = math.clamp(self._Zoom - 0.1, 0.6, 1.5)
        designCanvas.Size = UDim2.fromOffset(DESIGN_W * self._Zoom, DESIGN_H * self._Zoom)
        designCanvas.Position = UDim2.new(0.5, -(DESIGN_W * self._Zoom) / 2, 0.5, -(DESIGN_H * self._Zoom) / 2)
        render(); updateSelection()
    end))
    self._Maid:GiveTask(zoomIn.MouseButton1Click:Connect(function()
        self._Zoom = math.clamp(self._Zoom + 0.1, 0.6, 1.5)
        designCanvas.Size = UDim2.fromOffset(DESIGN_W * self._Zoom, DESIGN_H * self._Zoom)
        designCanvas.Position = UDim2.new(0.5, -(DESIGN_W * self._Zoom) / 2, 0.5, -(DESIGN_H * self._Zoom) / 2)
        render(); updateSelection()
    end))

    self._Maid:GiveTask(layoutButton.MouseButton1Click:Connect(function()
        -- Layout button intentionally cycles the preview zoom back to 100%.
        self._Zoom = 1
        designCanvas.Size = UDim2.fromOffset(DESIGN_W, DESIGN_H)
        designCanvas.Position = UDim2.new(0.5, -DESIGN_W / 2, 0.5, -DESIGN_H / 2)
        render(); updateSelection()
    end))

    self._Maid:GiveTask(undoButton.MouseButton1Click:Connect(function()
        if self._HistoryIndex <= 1 then return end
        self._HistoryIndex -= 1
        local snapshot = self._History[self._HistoryIndex]
        if snapshot then self:SetLayout(snapshot) end
    end))
    self._Maid:GiveTask(redoButton.MouseButton1Click:Connect(function()
        if self._HistoryIndex >= #self._History then return end
        self._HistoryIndex += 1
        local snapshot = self._History[self._HistoryIndex]
        if snapshot then self:SetLayout(snapshot) end
    end))

    -- Drag the entire studio from the header.
    local draggingWindow = false
    local windowDragStart = Vector2.zero
    local windowStart = UDim2.fromScale(0.5, 0.5)
    self._Maid:GiveTask(header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingWindow = true
            windowDragStart = input.Position
            windowStart = panel.Position
        end
    end))
    self._Maid:GiveTask(header.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then draggingWindow = false end
    end))
    self._Maid:GiveTask(UserInputService.InputChanged:Connect(function(input)
        if not draggingWindow then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local delta = input.Position - windowDragStart
        panel.Position = UDim2.new(windowStart.X.Scale, windowStart.X.Offset + delta.X, windowStart.Y.Scale, windowStart.Y.Offset + delta.Y)
    end))

    function self:Close()
        if gui and gui.Parent then
            gui.Enabled = false
        end
    end

    function self:Open()
        if gui and gui.Parent then
            gui.Enabled = true
        end
    end

    local function refreshTheme()
        panel.BackgroundColor3 = Theme.Surface
        panelStroke.Color = Theme.BorderStrong
        panelGlow.ImageColor3 = Theme.Accent
        header.BackgroundColor3 = Theme.Secondary
        components.BackgroundColor3 = Theme.Background
        componentsStroke.Color = Theme.Border
        preview.BackgroundColor3 = Theme.Background
        previewStroke.Color = Theme.Border
        canvasHost.BackgroundColor3 = Theme.Secondary
        canvasStroke.Color = Theme.Border
        designCanvas.BackgroundColor3 = Theme.Background
        designStroke.Color = Theme.BorderStrong
        centerGuide.BackgroundColor3 = Theme.Accent
        layers.BackgroundColor3 = Theme.Background
        layersStroke.Color = Theme.Border
        properties.BackgroundColor3 = Theme.Background
        propertiesStroke.Color = Theme.Border
        doneButton.BackgroundColor3 = Theme.Accent
        backButton.BackgroundColor3 = Theme.ElementBackground
        importButton.BackgroundColor3 = Theme.ElementBackground
        refreshComponents()
        refreshLayers()
        refreshProperties()
        render()
        updateSelection()
    end
    self._Maid:GiveTask(Theme.Changed:Connect(refreshTheme))

    refreshComponents()
    local initialLayout = data.Layout
    if type(initialLayout) == "table" and type(initialLayout.Elements) == "table" then
        self:SetLayout(initialLayout)
    else
        self:AddElement("Box")
        self:AddElement("Health", { X = 145, Y = 34 })
        self:AddElement("Name", { X = 145, Y = 62 })
        self:AddElement("Distance", { X = 145, Y = 350 })
    end
    self._Selected = self._Order[1]
    pushHistory()
    refreshLayers()
    refreshProperties()
    render()
    updateSelection()

    return self :: ESPBuilderHandle
end

return ESPBuilder