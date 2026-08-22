--!strict

local Theme = require(script.Parent.Theme)
local Section = require(script.Parent.Section)
local Maid = require(script.Parent.Parent.Utils.Maid)
local Helpers = require(script.Parent.Parent.Utils.Helpers)
local Tween = require(script.Parent.Parent.Utils.Tween)

local Tab = {}
Tab.__index = Tab

local iconMap = {
    ["main"] = "M",
    ["home"] = "M",
    ["player"] = "P",
    ["combat"] = "C",
    ["visuals"] = "V",
    ["world"] = "W",
    ["misc"] = "X",
    ["settings"] = "S",
    ["options"] = "O",
    ["farm"] = "F",
    ["aim assist"] = "A",
}


local function cleanDisplayName(name: string): string
    local cleaned = name
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

local function getIcon(name: string): string
    local visible = cleanDisplayName(name)
    local key = string.lower(visible):gsub("^[%s%p]+", ""):gsub("[%s%p]+$", "")
    return iconMap[key] or string.upper(string.sub(visible, 1, 1))
end

export type TabHandle = {
    CreateSection: (self: TabHandle, name: string?) -> any,
    SetActive: (self: TabHandle, active: boolean) -> (),
    Show: (self: TabHandle) -> (),
    Destroy: (self: TabHandle) -> (),
}

function Tab.new(window: any, name: string): TabHandle
    local self = setmetatable({
        Window = window,
        _Name = name,
        _Maid = Maid.new(),
        _Sections = {} :: { any },
        _DefaultSection = nil :: any,
    }, Tab)

    local theme = window.Library.Theme

    -- Compact navigation item: a quiet surface with a short accent rail when active.
    local button = Helpers.CreateButton({
        Name = name,
        Size = UDim2.new(1, 0, 0, 44),
        Text = "",
        BackgroundColor3 = theme.Surface,
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        Parent = window.TabList,
    })
    Helpers.Corner(button, Theme.CornerRadiusSmall)

    local hoverFill = Instance.new("Frame")
    hoverFill.Name = "HoverFill"
    hoverFill.Size = UDim2.fromScale(1, 1)
    hoverFill.BackgroundColor3 = theme.SurfaceHover
    hoverFill.BackgroundTransparency = 1
    hoverFill.BorderSizePixel = 0
    hoverFill.ZIndex = 0
    hoverFill.Parent = button
    Helpers.Corner(hoverFill, Theme.CornerRadiusSmall)

    local activeFill = Instance.new("Frame")
    activeFill.Name = "ActiveFill"
    activeFill.Size = UDim2.fromScale(1, 1)
    activeFill.BackgroundColor3 = theme.Accent
    activeFill.BackgroundTransparency = 1
    activeFill.BorderSizePixel = 0
    activeFill.ZIndex = 1
    activeFill.Parent = button
    Helpers.Corner(activeFill, Theme.CornerRadiusSmall)
    local activeGlow = Helpers.Stroke(activeFill, theme.Accent, 1)
    activeGlow.Transparency = 0.94
    local activeGlowImage = Helpers.Glow(activeFill, theme.Accent, 8, 0.95)

    local activeGradient = Instance.new("UIGradient")
    activeGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, theme.Accent),
        ColorSequenceKeypoint.new(1, theme.AccentAlt or theme.Accent),
    })
    activeGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.90),
        NumberSequenceKeypoint.new(1, 0.97),
    })
    activeGradient.Parent = activeFill

    local indicatorGlow = Instance.new("Frame")
    indicatorGlow.Name = "IndicatorGlow"
    indicatorGlow.Size = UDim2.new(0, 7, 0, 24)
    indicatorGlow.Position = UDim2.new(0, -2, 0.5, 0)
    indicatorGlow.AnchorPoint = Vector2.new(0, 0.5)
    indicatorGlow.BackgroundColor3 = theme.Accent
    indicatorGlow.BackgroundTransparency = 0.96
    indicatorGlow.BorderSizePixel = 0
    indicatorGlow.ZIndex = 2
    indicatorGlow.Parent = button
    Helpers.Corner(indicatorGlow, 4)

    local indicator = Instance.new("Frame")
    indicator.Name = "ActiveIndicator"
    indicator.Size = UDim2.new(0, 2, 0, 22)
    indicator.Position = UDim2.new(0, 0, 0.5, 0)
    indicator.AnchorPoint = Vector2.new(0, 0.5)
    indicator.BackgroundColor3 = theme.Accent
    indicator.BackgroundTransparency = 1
    indicator.BorderSizePixel = 0
    indicator.ZIndex = 3
    indicator.Parent = button
    Helpers.Corner(indicator, 2)

    local icon = Instance.new("TextLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.fromOffset(24, 40)
    icon.Position = UDim2.fromOffset(11, 0)
    icon.BackgroundTransparency = 1
    icon.Text = getIcon(name)
    icon.Font = Theme.FontBold
    icon.TextSize = 16
    icon.TextColor3 = theme.TextMuted
    icon.TextXAlignment = Enum.TextXAlignment.Center
    icon.ZIndex = 4
    icon.Parent = button

    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, -50, 1, 0)
    label.Position = UDim2.fromOffset(47, 0)
    label.BackgroundTransparency = 1
    label.Text = cleanDisplayName(name)
    label.Font = Theme.Font
    label.TextSize = 12
    label.TextColor3 = theme.TextMuted
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextTruncate = Enum.TextTruncate.AtEnd
    label.ZIndex = 4
    label.Parent = button

    button.MouseEnter:Connect(function()
        if window._ActiveTab ~= self then
            Tween.Play(hoverFill, { BackgroundTransparency = 0.82 }, { Time = 0.12 })
            Tween.Play(icon, { TextColor3 = theme.Text }, { Time = 0.12 })
            Tween.Play(label, { TextColor3 = theme.Text }, { Time = 0.12 })
        end
    end)

    button.MouseLeave:Connect(function()
        if window._ActiveTab ~= self then
            Tween.Play(hoverFill, { BackgroundTransparency = 1 }, { Time = 0.14 })
            Tween.Play(icon, { TextColor3 = theme.TextMuted }, { Time = 0.12 })
            Tween.Play(label, { TextColor3 = theme.TextMuted }, { Time = 0.12 })
        end
    end)

    local page = Instance.new("ScrollingFrame")
    page.Name = name
    page.Visible = false
    page.Size = UDim2.fromScale(1, 1)
    page.Position = UDim2.fromOffset(0, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = theme.Accent
    page.ScrollBarImageTransparency = 0.45
    page.CanvasSize = UDim2.new()
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.ClipsDescendants = true
    page.Parent = window.Pages

    local pagePadding = Helpers.Padding(page, 0)

    local pageTopInset = 44
    local pageSideInset = 18
    local pageRightReserve = 22

    local columns = Helpers.CreateFrame({
        Name = "Columns",
        Size = UDim2.new(1, -(pageSideInset + pageRightReserve), 0, 0),
        Position = UDim2.fromOffset(pageSideInset, pageTopInset),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Parent = page,
    })

    local leftColumn = Helpers.CreateFrame({
        Name = "ColumnLeft",
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Parent = columns,
    })

    local rightColumn = Helpers.CreateFrame({
        Name = "ColumnRight",
        Size = UDim2.new(0, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Visible = false,
        Parent = columns,
    })

    local columnLayout = Instance.new("UIListLayout")
    columnLayout.FillDirection = Enum.FillDirection.Horizontal
    columnLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    columnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    columnLayout.Padding = UDim.new(0, 12)
    columnLayout.Parent = columns

    local leftLayout = Helpers.ListLayout(leftColumn, 12)
    local rightLayout = Helpers.ListLayout(rightColumn, 12)

    local function updateColumns()
        local count = #self._Sections
        local twoColumns = count > 1
        rightColumn.Visible = twoColumns

        if twoColumns then
            leftColumn.Size = UDim2.new(0.5, -6, 0, 0)
            rightColumn.Size = UDim2.new(0.5, -6, 0, 0)
        else
            leftColumn.Size = UDim2.new(1, 0, 0, 0)
            rightColumn.Size = UDim2.new(0, 0, 0, 0)
        end

        for index, section in ipairs(self._Sections) do
            if section and section.Container then
                section.Container.Parent = if twoColumns and index % 2 == 0 then rightColumn else leftColumn
                section.Container.Size = UDim2.new(1, 0, 0, 0)
            end
        end

        task.defer(function()
            page.CanvasSize = UDim2.new(
                0, 0, 0,
                math.max(leftColumn.AbsoluteSize.Y, rightColumn.AbsoluteSize.Y)
                    + pageTopInset + pagePadding.PaddingTop.Offset + pagePadding.PaddingBottom.Offset + 6
            )
        end)
    end

    self._Maid:GiveTask(columnLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.new(
            0, 0, 0,
            math.max(leftColumn.AbsoluteSize.Y, rightColumn.AbsoluteSize.Y)
                + pageTopInset + pagePadding.PaddingTop.Offset + pagePadding.PaddingBottom.Offset + 6
        )
    end))

    self.Button = button
    self.Page = page
    self._Icon = icon
    self._Label = label
    self._HoverFill = hoverFill
    self._ActiveFill = activeFill
    self._Indicator = indicator
    self._IndicatorGlow = indicatorGlow
    self._ActiveGlow = activeGlow
    self._ActiveGlowImage = activeGlowImage
    self._Columns = columns
    self._LeftColumn = leftColumn
    self._RightColumn = rightColumn
    self._UpdateColumns = updateColumns
    self._Maid:Give(button)
    self._Maid:Give(page)

    self._Maid:GiveTask(button.MouseButton1Click:Connect(function()
        if window._PlayClick then
            window._PlayClick()
        end
        window:_selectTab(self)
    end))

    self._ThemeConnection = window.Library.Theme.Changed:Connect(function()
        self:SetActive(self == window._ActiveTab)
        page.ScrollBarImageColor3 = window.Library.Theme.Accent
        activeGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, window.Library.Theme.Accent),
            ColorSequenceKeypoint.new(1, window.Library.Theme.AccentAlt or window.Library.Theme.Accent),
        })
    end)
    self._Maid:GiveTask(self._ThemeConnection)

    return self :: any
end

function Tab:SetActive(active: boolean)
    local theme = self.Window.Library.Theme
    self._ActiveFill.BackgroundColor3 = theme.Accent
    self._ActiveFill.BackgroundTransparency = if active then 0.84 else 1
    self._HoverFill.BackgroundColor3 = theme.SurfaceHover
    self._HoverFill.BackgroundTransparency = 1

    self._Indicator.BackgroundColor3 = theme.Accent
    self._Indicator.BackgroundTransparency = if active then 0 else 1
    self._IndicatorGlow.BackgroundColor3 = theme.Accent
    self._IndicatorGlow.BackgroundTransparency = if active then 0.82 else 1
    self._ActiveGlow.Color = theme.Accent
    self._ActiveGlow.Transparency = if active then 0.94 else 1
    if self._ActiveGlowImage then
        self._ActiveGlowImage.ImageColor3 = theme.Accent
        self._ActiveGlowImage.ImageTransparency = if active then 0.94 else 1
    end

    self._Icon.TextColor3 = if active then theme.Text else theme.TextMuted
    self._Label.TextColor3 = if active then theme.Text else theme.TextMuted
    self._Icon.TextSize = if active then 17 else 16
end

function Tab:RefreshTheme()
    self:SetActive(self == self.Window._ActiveTab)
    self.Page.ScrollBarImageColor3 = self.Window.Library.Theme.Accent
end

function Tab:Show()
    self.Page.Visible = true
    for _, sibling in self.Window.Pages:GetChildren() do
        if sibling:IsA("ScrollingFrame") and sibling ~= self.Page then
            sibling.Visible = false
        end
    end
end

function Tab:CreateSection(nameOrData: any)
    local name = nil
    if type(nameOrData) == "string" then
        name = nameOrData
    elseif type(nameOrData) == "table" then
        name = nameOrData.Name or nameOrData.Title or nil
    end

    local section = Section.new(self, name)
    table.insert(self._Sections, section)
    self._UpdateColumns()
    return section
end

function Tab:_getDefaultSection(): any
    if not self._DefaultSection then
        self._DefaultSection = self:CreateSection("Default")
    end
    return self._DefaultSection
end

function Tab:CreateDropdown(data: any) return self:_getDefaultSection():CreateDropdown(data) end
function Tab:CreateToggle(data: any) return self:_getDefaultSection():CreateToggle(data) end
function Tab:CreateButton(data: any) return self:_getDefaultSection():CreateButton(data) end
function Tab:CreateSlider(data: any) return self:_getDefaultSection():CreateSlider(data) end
function Tab:CreateInput(data: any) return self:_getDefaultSection():CreateInput(data) end
function Tab:CreateKeybind(data: any) return self:_getDefaultSection():CreateKeybind(data) end
function Tab:CreateColorPicker(data: any) return self:_getDefaultSection():CreateColorPicker(data) end
function Tab:CreateParagraph(data: any) return self:_getDefaultSection():CreateParagraph(data) end

function Tab:Destroy()
    for _, section in self._Sections do
        section:Destroy()
    end
    table.clear(self._Sections)
    self._Maid:DoCleaning()
end

return Tab
