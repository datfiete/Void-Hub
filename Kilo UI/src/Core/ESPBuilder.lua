--!strict
-- Kilo UI ESP / Visual Layout Designer.
-- A renderer-agnostic visual editor focused on designing ESP layouts and
-- exporting data. The actual world/entity renderer is supplied by ESPWorldRenderer.
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
local PRESETS = { "Custom", "Minimal", "Classic", "Kilo", "Compact", "Full" }

local DEFAULTS: { [string]: { [string]: any } } = {
    Box = { Name = "Box", X = 125, Y = 90, Width = 170, Height = 250, Color = Color3.fromRGB(0, 180, 255), Thickness = 2, Transparency = 0, Anchor = "Center" },
    Name = { Name = "Name", X = 145, Y = 62, Width = 130, Height = 24, Text = "{name}", Color = Color3.fromRGB(245, 245, 248), TextSize = 14, Anchor = "Center" },
    Health = { Name = "Health", X = 145, Y = 34, Width = 130, Height = 22, Text = "{health}/{maxhealth}", Color = Color3.fromRGB(76, 220, 137), TextSize = 13, Anchor = "Center" },
    Distance = { Name = "Distance", X = 145, Y = 350, Width = 130, Height = 22, Text = "{distance}", Color = Color3.fromRGB(220, 225, 235), TextSize = 13, Anchor = "Center" },
    HealthBar = { Name = "Health Bar", X = 116, Y = 92, Width = 6, Height = 246, Color = Color3.fromRGB(76, 220, 137), Thickness = 0, Anchor = "Center" },
    Tracer = { Name = "Tracer", X = 210, Y = 385, Width = 2, Height = 42, Color = Color3.fromRGB(0, 180, 255), Thickness = 2, Anchor = "Center" },
    Weapon = { Name = "Weapon", X = 300, Y = 132, Width = 105, Height = 22, Text = "{weapon}", Color = Color3.fromRGB(245, 245, 248), TextSize = 11, Anchor = "Left" },
    Status = { Name = "Status", X = 300, Y = 158, Width = 105, Height = 22, Text = "{team}", Color = Color3.fromRGB(247, 185, 78), TextSize = 11, Anchor = "Left" },
    CustomText = { Name = "Custom Text", X = 300, Y = 184, Width = 105, Height = 22, Text = "{team} / {distance}", Color = Color3.fromRGB(245, 245, 248), TextSize = 11, Anchor = "Left" },
    Team = { Name = "Team", X = 300, Y = 158, Width = 105, Height = 22, Text = "{team}", Color = Color3.fromRGB(247, 185, 78), TextSize = 11, Anchor = "Left" },
    Class = { Name = "Class", X = 300, Y = 184, Width = 105, Height = 22, Text = "{class}", Color = Color3.fromRGB(190, 190, 210), TextSize = 11, Anchor = "Left" },
    State = { Name = "State", X = 300, Y = 210, Width = 105, Height = 22, Text = "{state}", Color = Color3.fromRGB(190, 190, 210), TextSize = 11, Anchor = "Left" },
    HealthPercent = { Name = "Health %", X = 145, Y = 6, Width = 130, Height = 22, Text = "{health_percent}", Color = Color3.fromRGB(76, 220, 137), TextSize = 11, Anchor = "Center" },
    FilledBox = { Name = "Filled Box", X = 125, Y = 90, Width = 170, Height = 250, Color = Color3.fromRGB(0, 180, 255), Transparency = 0.82, Anchor = "Center" },
    CornerBox = { Name = "Corner Box", X = 125, Y = 90, Width = 170, Height = 250, Color = Color3.fromRGB(0, 180, 255), Thickness = 2, Anchor = "Center" },
    HeadMarker = { Name = "Head Marker", X = 198, Y = 96, Width = 24, Height = 24, Color = Color3.fromRGB(0, 180, 255), Thickness = 2, Anchor = "Center" },
    Skeleton = { Name = "Skeleton", X = 160, Y = 105, Width = 100, Height = 215, Color = Color3.fromRGB(0, 180, 255), Thickness = 2, Anchor = "Center" },
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

local TYPE_ICON_KEYS: { [string]: string } = {
    Box = "box",
    CornerBox = "corner_box",
    FilledBox = "filled_box",
    Name = "name",
    Health = "health",
    HealthPercent = "health",
    HealthBar = "health_bar",
    Distance = "distance",
    Tracer = "tracer",
    HeadMarker = "head",
    Skeleton = "skeleton",
    Weapon = "weapon",
    Team = "team",
    Class = "class",
    State = "class",
    Status = "team",
    CustomText = "name",
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

local function addUiIcon(parent: Instance, groupName: string, key: string, size: number, x: number, y: number, zIndex: number?)
    local group = Icons[groupName]
    local asset = if type(group) == "table" then group[key] else nil
    if not asset or asset == "" then
        return nil
    end
    return createIconLabel({
        Size = UDim2.fromOffset(size, size),
        Position = UDim2.fromOffset(x, y),
        Image = asset,
        ImageColor3 = Theme.Text,
        ZIndex = zIndex or 2,
        Parent = parent,
    })
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
    gui.Name = "KiloESPDesigner"
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
        Text = "K",
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
        Text = "Kilo ESP Builder",
        TextColor3 = Theme.Text,
        TextSize = 17,
        Font = Theme.FontBold,
        Parent = header,
    })
    Helpers.CreateLabel({
        Name = "Subtitle",
        Size = UDim2.new(0, 480, 0, 18),
        Position = UDim2.fromOffset(112, 34),
        Text = "Design your ESP layout visually.",
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
    addUiIcon(presetButton, "Editor", "presets", 16, 10, 13, 3)
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
    addUiIcon(customAdd, "Actions", "add_element", 16, 12, 12, 3)

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
    zoomOut.Text = ""
    addUiIcon(zoomOut, "Transform", "zoom_out", 16, 8, 8, 3)
    local zoomLabel = Helpers.CreateLabel({ Name = "Zoom", Size = UDim2.fromOffset(52, 32), Position = UDim2.new(1, -72, 0, 38), Text = "100%", TextColor3 = Theme.Text, TextSize = 9, Font = Theme.FontBold, TextXAlignment = Enum.TextXAlignment.Center, Parent = preview })
    local zoomIn = Helpers.CreateButton({ Name = "ZoomIn", Size = UDim2.fromOffset(32, 32), Position = UDim2.new(1, -32, 0, 38), Text = "+", TextColor3 = Theme.TextMuted, TextSize = 16, BackgroundColor3 = Theme.ElementBackground, Parent = preview })
    Helpers.Corner(zoomIn, 7)
    zoomIn.Text = ""
    addUiIcon(zoomIn, "Transform", "zoom_in", 16, 8, 8, 3)

    local canvasHost = Helpers.CreateFrame({ Name = "CanvasHost", Size = UDim2.new(1, -24, 1, -82), Position = UDim2.fromOffset(12, 76), BackgroundColor3 = Theme.Secondary, Parent = preview })
    Helpers.Corner(canvasHost, Theme.CornerRadiusSmall)
    local canvasStroke = Helpers.Stroke(canvasHost, Theme.Border, 1)
    canvasHost.ClipsDescendants = true

    local designCanvas = Helpers.CreateFrame({ Name = "DesignCanvas", Size = UDim2.fromOffset(DESIGN_W, DESIGN_H), Position = UDim2.new(0.5, -DESIGN_W / 2, 0.5, -DESIGN_H / 2), BackgroundColor3 = Theme.Background, Parent = canvasHost })
    Helpers.Corner(designCanvas, 10)
    local designStroke = Helpers.Stroke(designCanvas, Theme.BorderStrong, 1)
    designCanvas.ClipsDescendants = true

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
    addUiIcon(addLayerButton, "Actions", "add_element", 16, 12, 9, 3)

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
    undoButton.Text = ""
    addUiIcon(undoButton, "Actions", "undo", 16, 9, 7, 3)
    local redoButton = Helpers.CreateButton({ Name = "Redo", Size = UDim2.fromOffset(34, 30), Text = "REDO", TextColor3 = Theme.TextMuted, TextSize = 16, BackgroundColor3 = Theme.ElementBackground, Parent = footer })
    Helpers.Corner(redoButton, 7)
    redoButton.Text = ""
    addUiIcon(redoButton, "Actions", "redo", 16, 9, 7, 3)
    local footerHint = Helpers.CreateLabel({ Name = "Hint", Size = UDim2.new(1, -520, 0, 30), Text = "Click an element to select it  |  Drag to move  |  Drag the corner handle to resize", TextColor3 = Theme.TextMuted, TextSize = 8, Parent = footer })
    footerHint.LayoutOrder = 5
    local footerZoom = Helpers.CreateLabel({ Name = "Zoom", Size = UDim2.fromOffset(100, 30), Text = "Zoom 100%", TextColor3 = Theme.TextMuted, TextSize = 8, TextXAlignment = Enum.TextXAlignment.Right, Parent = footer })
    footerZoom.LayoutOrder = 6

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
    modalClose.Text = ""
    addUiIcon(modalClose, "Navigation", "close", 14, 10, 8, 103)

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
                addUiIcon(load, "Editor", "load", 14, 5, 8, 105)
                local del = Helpers.CreateButton({ Size = UDim2.fromOffset(54, 30), Position = UDim2.new(1, -58, 0, 9), Text = "DELETE", TextColor3 = Theme.Error, TextSize = 7, Font = Theme.FontBold, BackgroundColor3 = Theme.ElementBackground, Parent = row })
                del.ZIndex = 104
                Helpers.Corner(del, 6)
                addUiIcon(del, "Editor", "delete", 14, 5, 8, 105)
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
            local dx = input.Position.X - resizeStart.X
            local dy = input.Position.Y - resizeStart.Y
            element.Width = math.clamp(startW + dx / s, 4, DESIGN_W - element.X)
            element.Height = math.clamp(startH + dy / s, 4, DESIGN_H - element.Y)
            clampElement(element)
            render()
            updateSelection()
        end))
        self._SelectionMaid:GiveTask(UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                resizing = false
            end
        end))
    end

    render = function()
        for id, inst in pairs(previewInstances) do
            inst:Destroy()
        end
        table.clear(previewInstances)

        for id, element in pairs(self._Elements) do
            if element.Visible == false then continue end
            local dot = Instance.new("Frame")
            dot.Name = id
            dot.Position = UDim2.fromOffset(element.X, element.Y)
            dot.Size = UDim2.fromOffset(element.Width, element.Height)
            dot.BackgroundTransparency = 1
            dot.BorderSizePixel = 0
            dot.ZIndex = 4
            dot.Parent = designCanvas

            local inner = Instance.new("Frame")
            inner.Name = "Inner"
            inner.Size = UDim2.new(1, 0, 1, 0)
            inner.BackgroundColor3 = element.Color or Theme.Accent
            inner.BackgroundTransparency = math.clamp(element.Transparency or 0, 0, 1)
            inner.BorderSizePixel = 0
            inner.ZIndex = 4
            inner.Parent = dot

            if element.Type == "Box" or element.Type == "CornerBox" or element.Type == "FilledBox" then
                local stroke = Instance.new("UIStroke")
                stroke.Color = element.Color or Theme.Accent
                stroke.Thickness = math.max(element.Thickness or 2, 1)
                stroke.Transparency = math.clamp(element.Transparency or 0, 0, 1)
                stroke.Parent = dot
            end

            if element.Type == "Name" or element.Type == "Health" or element.Type == "Distance" or element.Type == "Weapon" or element.Type == "Status" or element.Type == "Team" or element.Type == "Class" or element.Type == "State" or element.Type == "HealthPercent" or element.Type == "CustomText" then
                local label = Instance.new("TextLabel")
                label.Name = "Label"
                label.Size = UDim2.new(1, 0, 1, 0)
                label.BackgroundTransparency = 1
                label.Text = displayText(element, self._Sample)
                label.TextColor3 = element.Color or Theme.Text
                label.TextSize = math.clamp(element.TextSize or 12, 6, 40)
                label.Font = Theme.FontBold
                label.TextXAlignment = Enum.TextXAlignment.Center
                label.TextYAlignment = Enum.TextYAlignment.Center
                label.TextStrokeTransparency = 0.5
                label.ZIndex = 5
                label.Parent = dot
            end

            previewInstances[id] = dot
        end
    end

    refreshLayers = function()
        for _, child in ipairs(layerList:GetChildren()) do
            if child:IsA("GuiButton") then
                child:Destroy()
            end
        end
        table.clear(listButtons)
        for _, elementType in ipairs(TYPE_ORDER) do
            for id, element in pairs(self._Elements) do
                if element.Type == elementType then
                    local row = Helpers.CreateButton({ Name = "Layer_" .. id, Size = UDim2.new(1, -2, 0, 34), Text = "", AutoButtonColor = false, BackgroundColor3 = element.Id == self._Selected and Theme.AccentSoft or Theme.ElementBackground, Parent = layerList })
                    row.ZIndex = 10
                    Helpers.Corner(row, 6)
                    Helpers.Stroke(row, element.Id == self._Selected and Theme.Accent or Theme.Border, 1)
                    local label = Helpers.CreateLabel({ Size = UDim2.new(1, -60, 1, 0), Position = UDim2.fromOffset(8, 0), Text = element.Name .. "  ·  " .. element.Type, TextColor3 = Theme.Text, TextSize = 8, Font = Theme.FontBold, TextXAlignment = Enum.TextXAlignment.Left, Parent = row })
                    label.ZIndex = 11
                    local glyph = Helpers.CreateLabel({ Size = UDim2.fromOffset(30, 30), Position = UDim2.new(1, -38, 0, 2), Text = TYPE_GLYPHS[element.Type] or "?", TextColor3 = element.Color or Theme.Text, TextSize = 10, Font = Theme.FontBold, TextXAlignment = Enum.TextXAlignment.Center, Parent = row })
                    glyph.ZIndex = 11
                    listButtons[id] = row
                    self._Maid:GiveTask(row.MouseButton1Click:Connect(function()
                        self._Selected = id
                        updateSelection()
                        refreshProperties()
                        refreshLayers()
                    end))
                end
            end
        end
    end

    local function refreshComponentList()
        for _, child in ipairs(componentList:GetChildren()) do
            if child:IsA("GuiButton") then
                child:Destroy()
            end
        end
        table.clear(componentButtons)
        for _, elementType in ipairs(TYPE_ORDER) do
            local row = Helpers.CreateButton({ Name = "Comp_" .. elementType, Size = UDim2.new(1, -24, 0, 44), Text = "", AutoButtonColor = false, BackgroundColor3 = Theme.ElementBackground, Parent = componentList })
            row.ZIndex = 10
            Helpers.Corner(row, 8)
            Helpers.Stroke(row, Theme.Border, 1)
            local icon = createIconLabel({ Size = UDim2.fromOffset(20, 20), Position = UDim2.fromOffset(10, 12), Image = getTypeIcon(elementType) or "", ImageColor3 = Theme.Accent, ZIndex = 11, Parent = row })
            local label = Helpers.CreateLabel({ Size = UDim2.new(1, -44, 1, 0), Position = UDim2.fromOffset(40, 0), Text = TYPE_LABELS[elementType] or elementType, TextColor3 = Theme.Text, TextSize = 9, Font = Theme.FontBold, TextXAlignment = Enum.TextXAlignment.Left, Parent = row })
            label.ZIndex = 11
            local desc = Helpers.CreateLabel({ Size = UDim2.new(1, -44, 0, 14), Position = UDim2.fromOffset(40, 26), Text = TYPE_DESCRIPTIONS[elementType] or "", TextColor3 = Theme.TextMuted, TextSize = 7, Parent = row })
            desc.ZIndex = 11
            componentButtons[elementType] = row
            self._Maid:GiveTask(row.MouseButton1Click:Connect(function()
                pushHistory()
                local id = nextId(elementType)
                local el = cloneElement(DEFAULTS[elementType] or { Type = elementType, Name = elementType })
                el.Id = id
                self._Elements[id] = el
                table.insert(self._Order, id)
                self._Selected = id
                render()
                refreshLayers()
                refreshProperties()
                updateSelection()
                notifyChanged()
            end))
        end
    end

    refreshComponentList()

    function self:SetSample(sample: { [string]: any })
        if type(sample) == "table" then
            for k, v in pairs(sample) do
                self._Sample[k] = v
            end
        end
        render()
        refreshProperties()
    end

    function self:AddElement(elementType: string, data: any?): string
        pushHistory()
        local id = nextId(elementType)
        local el = cloneElement(DEFAULTS[elementType] or { Type = elementType, Name = elementType })
        el.Id = id
        if type(data) == "table" then
            for k, v in pairs(data) do
                el[k] = v
            end
        end
        el.Id = id
        self._Elements[id] = el
        table.insert(self._Order, id)
        self._Selected = id
        render()
        refreshLayers()
        refreshProperties()
        updateSelection()
        notifyChanged()
        return id
    end

    function self:RemoveElement(id: string)
        if not self._Elements[id] then return end
        pushHistory()
        self._Elements[id] = nil
        for i, v in ipairs(self._Order) do
            if v == id then
                table.remove(self._Order, i)
                break
            end
        end
        if self._Selected == id then
            self._Selected = nil
        end
        render()
        refreshLayers()
        refreshProperties()
        updateSelection()
        notifyChanged()
    end

    function self:DuplicateElement(id: string?): string?
        if not id or not self._Elements[id] then return nil end
        pushHistory()
        local source = self._Elements[id]
        local newId = nextId(source.Type)
        local copy = cloneElement(source)
        copy.Id = newId
        copy.X = math.clamp(copy.X + 12, 0, DESIGN_W - copy.Width)
        copy.Y = math.clamp(copy.Y + 12, 0, DESIGN_H - copy.Height)
        self._Elements[newId] = copy
        table.insert(self._Order, newId)
        self._Selected = newId
        render()
        refreshLayers()
        refreshProperties()
        updateSelection()
        notifyChanged()
        return newId
    end

    function self:MoveElement(id: string, deltaX: number, deltaY: number)
        local el = self._Elements[id]
        if not el then return end
        pushHistory()
        el.X = math.clamp(el.X + deltaX, 0, DESIGN_W - el.Width)
        el.Y = math.clamp(el.Y + deltaY, 0, DESIGN_H - el.Height)
        render()
        refreshLayers()
        notifyChanged()
    end

    function self:GetLayout(): { [string]: any }
        local elements = {}
        for _, id in ipairs(self._Order) do
            local el = self._Elements[id]
            if el then
                table.insert(elements, cloneElement(el))
            end
        end
        return {
            Version = 2,
            Preset = self._Preset,
            Canvas = { Width = DESIGN_W, Height = DESIGN_H },
            Elements = elements,
        }
    end

    function self:SetLayout(layout: { [string]: any })
        if type(layout) ~= "table" then
            return
        end
        pushHistory()
        self._Elements = {}
        self._Order = {}
        self._Selected = nil
        self._Preset = tostring(layout.Preset or "Custom")
        for _, el in ipairs(layout.Elements or {}) do
            local id = tostring(el.Id or "element_" .. (#self._Order + 1))
            local parsed = cloneElement(el)
            parsed.Id = id
            self._Elements[id] = parsed
            table.insert(self._Order, id)
        end
        render()
        refreshLayers()
        refreshProperties()
        updateSelection()
        notifyChanged()
    end

    function self:Export(): { [string]: any }
        return self:GetLayout()
    end

    function self:SetPreset(preset: string)
        self._Preset = preset
        notifyChanged()
    end

    function self:GetPresets(): { string }
        return PRESETS
    end

    function self:OnChanged(callback: (layout: any) -> ()): RBXScriptConnection
        return self._Changed.Event:Connect(callback)
    end

    function self:Close()
        gui.Enabled = false
    end

    function self:Open()
        gui.Enabled = true
        render()
        refreshLayers()
        refreshProperties()
    end

    return self :: any
end

return ESPBuilder
