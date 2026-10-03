--!strict

local Theme = require(script.Parent.Theme)
local Toggle = require(script.Parent.Parent.Elements.Toggle)
local Button = require(script.Parent.Parent.Elements.Button)
local Slider = require(script.Parent.Parent.Elements.Slider)
local Dropdown = require(script.Parent.Parent.Elements.Dropdown)
local Input = require(script.Parent.Parent.Elements.Input)
local Keybind = require(script.Parent.Parent.Elements.Keybind)
local ColorPicker = require(script.Parent.Parent.Elements.ColorPicker)
local Paragraph = require(script.Parent.Parent.Elements.Paragraph)
local WorldRadar = require(script.Parent.WorldRadar)
local Maid = require(script.Parent.Parent.Utils.Maid)
local Helpers = require(script.Parent.Parent.Utils.Helpers)

local Section = {}
Section.__index = Section

export type SectionHandle = {
    CreateToggle: (self: SectionHandle, data: any) -> any,
    CreateButton: (self: SectionHandle, data: any) -> any,
    CreateSlider: (self: SectionHandle, data: any) -> any,
    CreateDropdown: (self: SectionHandle, data: any) -> any,
    CreateInput: (self: SectionHandle, data: any) -> any,
    CreateKeybind: (self: SectionHandle, data: any) -> any,
    CreateColorPicker: (self: SectionHandle, data: any) -> any,
    CreateParagraph: (self: SectionHandle, data: any) -> any,
    CreateWorldRadar: (self: SectionHandle, data: any?) -> any,
    CreateCard: (self: SectionHandle, data: any) -> any,
    CreateBadge: (self: SectionHandle, data: any) -> any,
    CreateProgress: (self: SectionHandle, data: any) -> any,
    CreateStatus: (self: SectionHandle, data: any) -> any,
    Destroy: (self: SectionHandle) -> (),
}

function Section.new(tab: any, name: string?, description: string?): SectionHandle
    local self = setmetatable({
        Tab = tab,
        _Name = name,
        _Description = description,
        _Maid = Maid.new(),
        _Elements = {} :: { any },
    }, Section)

    local theme = tab.Window.Library.Theme

    local container = Helpers.CreateFrame({
        Name = name or "Section",
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Parent = tab.Page,
    })

    local inner = Helpers.CreateFrame({
        Name = "Inner",
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = theme.Surface,
        BackgroundTransparency = 0.015,
        Parent = container,
    })
    Helpers.Corner(inner, Theme.CornerRadius)
    local innerStroke = Helpers.Stroke(inner, theme.Border, 1)
    innerStroke.Transparency = 0.16
    -- Subtle accent light without inserting a GuiObject into the section's
    -- UIListLayout. Image-based glow children would be measured as layout
    -- items and create the giant empty boxes seen in earlier builds.
    local innerGlow = Helpers.Stroke(inner, theme.Accent, 2)
    innerGlow.Transparency = 0.90
    Helpers.Padding(inner, 16, 16)

    local layout = Helpers.ListLayout(inner, 10)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    local header = nil
    local headerLabel = nil
    local headerDescription = nil
    local headerAccent = nil

    if name and name ~= "" then
        header = Helpers.CreateFrame({
            Name = "Header",
            Size = UDim2.new(1, 0, 0, 48),
            BackgroundTransparency = 1,
            Parent = inner,
        })

        headerAccent = Helpers.CreateFrame({
            Name = "Accent", 
            Size = UDim2.new(0, 4, 0, 34),
            Position = UDim2.new(0, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundColor3 = theme.Accent,
            BorderSizePixel = 0,
            Parent = header,
        })
        Helpers.Corner(headerAccent, 2)

        headerLabel = Helpers.CreateLabel({
            Name = "HeaderLabel",
            Size = UDim2.new(1, -20, 0, 24),
            Position = UDim2.fromOffset(14, 0),
            Text = name,
            Font = Theme.FontBold,
            TextSize = 18,
            TextColor3 = theme.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = header,
        })

        headerDescription = Helpers.CreateLabel({
            Name = "HeaderDescription",
            Size = UDim2.new(1, -20, 0, 18),
            Position = UDim2.fromOffset(14, 25),
            Text = description or ("Configure " .. string.lower(name)),
            Font = Theme.Font,
            TextSize = 12,
            TextColor3 = theme.TextMuted,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = header,
        })
    end

    local themeConnection = tab.Window.Library.Theme.Changed:Connect(function(key)
        if key == "Style" or key == "Accent" or key == "Surface" or key == "Border" or key == "Text" or key == "TextMuted" then
            local currentTheme = tab.Window.Library.Theme
            inner.BackgroundColor3 = currentTheme.Surface
            innerStroke.Color = currentTheme.Border
            if headerLabel then
                headerLabel.TextColor3 = currentTheme.Text
            end
            if headerDescription then
                headerDescription.TextColor3 = currentTheme.TextMuted
            end
            if headerAccent then
                headerAccent.BackgroundColor3 = currentTheme.Accent
            end
        end
    end)
    self._Maid:GiveTask(themeConnection)

    self.Container = container
    self.Inner = inner
    self.Header = header
    self._HeaderLabel = headerLabel
    self._HeaderDescription = headerDescription
    self._Description = description
    self._HeaderAccent = headerAccent
    self._InnerGlow = innerGlow
    self._Maid:Give(container)

    return self :: any
end

function Section:SetDescription(description: string)
    self._Description = description
    if self._HeaderDescription then
        self._HeaderDescription.Text = description or ""
    end
end

function Section:RefreshTheme()
    local theme = self.Tab.Window.Library.Theme
    self.Inner.BackgroundColor3 = theme.Surface
    local stroke = self.Inner:FindFirstChildOfClass("UIStroke")
    if stroke then
        stroke.Color = theme.Border
    end
    if self._HeaderLabel then
        self._HeaderLabel.TextColor3 = theme.Text
    end
    if self._HeaderDescription then
        self._HeaderDescription.TextColor3 = theme.TextMuted
    end
    if self._HeaderAccent then
        self._HeaderAccent.BackgroundColor3 = theme.Accent
    end
    if self._InnerGlow then
        self._InnerGlow.Color = theme.Accent
    end
    for _, element in self._Elements do
        if element.RefreshTheme then
            element:RefreshTheme()
        end
        if element._VaxorinGlow then
            element._VaxorinGlow.Color = theme.Accent
        end
    end
end

function Section:_track(element: any)
    table.insert(self._Elements, element)

    -- Use a non-layout-affecting stroke for element glow. A child ImageLabel
    -- glow would be included by the parent UIListLayout and inflate the row.
    if element.Instance and element.Instance:IsA("GuiObject") and not element.Switch then
        local glow = Helpers.Stroke(element.Instance, self.Tab.Window.Library.Theme.Accent, 2)
        glow.Transparency = 0.93
        element._VaxorinGlow = glow
    end

    self._Maid:Give(function()
        element:Destroy()
    end)
    return element
end

function Section:CreateToggle(data: any) return self:_track(Toggle.new(self, data)) end
function Section:CreateButton(data: any) return self:_track(Button.new(self, data)) end
function Section:CreateSlider(data: any) return self:_track(Slider.new(self, data)) end
function Section:CreateDropdown(data: any) return self:_track(Dropdown.new(self, data)) end
function Section:CreateInput(data: any) return self:_track(Input.new(self, data)) end
function Section:CreateKeybind(data: any) return self:_track(Keybind.new(self, data)) end
function Section:CreateColorPicker(data: any) return self:_track(ColorPicker.new(self, data)) end
function Section:CreateParagraph(data: any) return self:_track(Paragraph.new(self, data)) end
function Section:CreateWorldRadar(data: any?) return self:_track(WorldRadar.new(self, data or {})) end

local function simpleCard(section, data, kind)
    data = data or {}
    local theme = section.Tab.Window.Library.Theme
    local card = Helpers.CreateFrame({
        Name = data.Name or kind,
        Size = UDim2.new(1, 0, 0, data.Height or 64),
        BackgroundColor3 = data.BackgroundColor or theme.ElementBackground,
        BackgroundTransparency = data.BackgroundTransparency or 0.04,
        Parent = section.Inner,
    })
    Helpers.Corner(card, Theme.CornerRadiusSmall)
    local stroke = Helpers.Stroke(card, data.BorderColor or theme.Border, 1)
    stroke.Transparency = 0.18
    if data.Title then
        Helpers.CreateLabel({ Name = "Title", Size = UDim2.new(1, -24, 0, 18), Position = UDim2.fromOffset(12, 10), Text = tostring(data.Title), Font = Theme.FontBold, TextSize = 13, TextColor3 = theme.Text, TextXAlignment = Enum.TextXAlignment.Left, Parent = card })
    end
    if data.Content then
        Helpers.CreateLabel({ Name = "Content", Size = UDim2.new(1, -24, 0, 30), Position = UDim2.fromOffset(12, data.Title and 30 or 10), Text = tostring(data.Content), Font = Theme.Font, TextSize = 11, TextColor3 = theme.TextMuted, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, Parent = card })
    end
    local handle = { Instance = card, Destroy = function() if card.Parent then card:Destroy() end end, RefreshTheme = function() card.BackgroundColor3 = theme.ElementBackground; stroke.Color = theme.Border end }
    return handle
end

function Section:CreateCard(data: any) return self:_track(simpleCard(self, data, "Card")) end

function Section:CreateBadge(data: any)
    data = data or {}
    local theme = self.Tab.Window.Library.Theme
    local badge = Helpers.CreateFrame({ Name = data.Name or "Badge", Size = UDim2.fromOffset(data.Width or 96, data.Height or 28), BackgroundColor3 = data.Color or theme.Accent, BackgroundTransparency = 0.78, Parent = self.Inner })
    Helpers.Corner(badge, 999)
    local stroke = Helpers.Stroke(badge, data.Color or theme.Accent, 1)
    stroke.Transparency = 0.28
    Helpers.CreateLabel({ Name = "Text", Size = UDim2.new(1, -16, 1, 0), Position = UDim2.fromOffset(8, 0), Text = data.Text or "STATUS", Font = Theme.FontBold, TextSize = data.TextSize or 10, TextColor3 = data.Color or theme.Accent, TextXAlignment = Enum.TextXAlignment.Center, Parent = badge })
    return self:_track({ Instance = badge, Destroy = function() if badge.Parent then badge:Destroy() end end, RefreshTheme = function() if not data.Color then stroke.Color = theme.Accent end end })
end

function Section:CreateProgress(data: any)
    data = data or {}
    local theme = self.Tab.Window.Library.Theme
    local root = Helpers.CreateFrame({ Name = data.Name or "Progress", Size = UDim2.new(1, 0, 0, 52), BackgroundTransparency = 1, Parent = self.Inner })
    local label = Helpers.CreateLabel({ Name = "Label", Size = UDim2.new(1, -70, 0, 18), Text = data.Title or "Progress", Font = Theme.FontBold, TextSize = 11, TextColor3 = theme.Text, TextXAlignment = Enum.TextXAlignment.Left, Parent = root })
    local valueLabel = Helpers.CreateLabel({ Name = "Value", Size = UDim2.fromOffset(60, 18), Position = UDim2.new(1, -60, 0, 0), Text = "0%", Font = Theme.FontBold, TextSize = 10, TextColor3 = theme.Accent, TextXAlignment = Enum.TextXAlignment.Right, Parent = root })
    local track = Helpers.CreateFrame({ Name = "Track", Size = UDim2.new(1, 0, 0, 7), Position = UDim2.fromOffset(0, 30), BackgroundColor3 = theme.Background, Parent = root })
    Helpers.Corner(track, 4)
    local fill = Helpers.CreateFrame({ Name = "Fill", Size = UDim2.fromScale(0, 1), BackgroundColor3 = data.Color or theme.Accent, Parent = track })
    Helpers.Corner(fill, 4)
    local TweenService = game:GetService("TweenService")
    local handle = { Instance = root, Set = function(_, value) value = math.clamp(tonumber(value) or 0, 0, 1); valueLabel.Text = tostring(math.floor(value * 100 + 0.5)) .. "%"; TweenService:Create(fill, TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Size = UDim2.fromScale(value, 1) }):Play() end, Destroy = function() if root.Parent then root:Destroy() end end, RefreshTheme = function() if not data.Color then fill.BackgroundColor3 = theme.Accent end; label.TextColor3 = theme.Text; valueLabel.TextColor3 = theme.Accent end }
    handle:Set(data.CurrentValue or 0)
    return self:_track(handle)
end

function Section:CreateStatus(data: any)
    data = data or {}
    local theme = self.Tab.Window.Library.Theme
    local root = Helpers.CreateFrame({ Name = data.Name or "Status", Size = UDim2.new(1, 0, 0, 48), BackgroundColor3 = theme.ElementBackground, BackgroundTransparency = 0.02, Parent = self.Inner })
    Helpers.Corner(root, Theme.CornerRadiusSmall)
    local dot = Helpers.CreateFrame({ Name = "Dot", Size = UDim2.fromOffset(8, 8), Position = UDim2.fromOffset(14, 20), BackgroundColor3 = data.Color or theme.Success, Parent = root })
    Helpers.Corner(dot, 4)
    local title = Helpers.CreateLabel({ Name = "Title", Size = UDim2.new(1, -44, 0, 18), Position = UDim2.fromOffset(32, 8), Text = data.Title or "System Status", Font = Theme.FontBold, TextSize = 11, TextColor3 = theme.Text, Parent = root })
    local body = Helpers.CreateLabel({ Name = "Content", Size = UDim2.new(1, -44, 0, 16), Position = UDim2.fromOffset(32, 26), Text = data.Content or "Operational", Font = Theme.Font, TextSize = 10, TextColor3 = theme.TextMuted, Parent = root })
    local handle = { Instance = root, Set = function(_, titleText, contentText) title.Text = tostring(titleText or title.Text); body.Text = tostring(contentText or body.Text) end, Destroy = function() if root.Parent then root:Destroy() end end, RefreshTheme = function() title.TextColor3 = theme.Text; body.TextColor3 = theme.TextMuted end }
    return self:_track(handle)
end
function Section:CreateLabel(data: any) return self:CreateParagraph(data) end
function Section:CreateInfo(data: any) return self:CreateParagraph(data) end

function Section:Destroy()
    self._Maid:DoCleaning()
    table.clear(self._Elements)
end

return Section
