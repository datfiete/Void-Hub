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
    Destroy: (self: SectionHandle) -> (),
}

function Section.new(tab: any, name: string?): SectionHandle
    local self = setmetatable({
        Tab = tab,
        _Name = name,
        _Maid = Maid.new(),
        _Elements = {} :: { any },
    }, Section)

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
        BackgroundColor3 = tab.Window.Library.Theme.Surface,
        BackgroundTransparency = 0.02,
        Parent = container,
    })
    Helpers.Corner(inner, Theme.CornerRadius)
    Helpers.Stroke(inner, tab.Window.Library.Theme.Border, 1)
    Helpers.Padding(inner, 14, 13)

    local layout = Helpers.ListLayout(inner, 8)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    local header = nil
    local headerLabel = nil
    if name and name ~= "" then
        header = Helpers.CreateFrame({
            Name = "Header",
            Size = UDim2.new(1, 0, 0, 24),
            BackgroundTransparency = 1,
            Parent = inner,
        })

        headerLabel = Helpers.CreateLabel({
            Name = "HeaderLabel",
            Size = UDim2.new(1, -4, 1, 0),
            Position = UDim2.fromOffset(1, 0),
            Text = name,
            Font = Theme.FontBold,
            TextSize = 15,
            TextColor3 = tab.Window.Library.Theme.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = header,
        })
    end

    local themeConnection = tab.Window.Library.Theme.Changed:Connect(function(key)
        if key == "Style" or key == "Accent" or key == "Secondary" or key == "Surface" or key == "Border" or key == "Text" then
            inner.BackgroundColor3 = tab.Window.Library.Theme.Surface
            local stroke = inner:FindFirstChildOfClass("UIStroke")
            if stroke then
                stroke.Color = tab.Window.Library.Theme.Border
            end
            if headerLabel then
                headerLabel.TextColor3 = tab.Window.Library.Theme.Text
            end
        end
    end)
    self._Maid:GiveTask(themeConnection)

    self.Container = container
    self.Inner = inner
    self.Header = header
    self._HeaderLabel = headerLabel
    self._Maid:Give(container)

    return self :: any
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
    for _, element in self._Elements do
        if element.RefreshTheme then
            element:RefreshTheme()
        end
    end
end

function Section:_track(element: any)
    table.insert(self._Elements, element)
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
function Section:CreateLabel(data: any) return self:CreateParagraph(data) end
function Section:CreateInfo(data: any) return self:CreateParagraph(data) end

function Section:Destroy()
    self._Maid:DoCleaning()
    table.clear(self._Elements)
end

return Section
