--!strict

local Theme = require(script.Parent.Parent.Core.Theme)
local Maid = require(script.Parent.Parent.Utils.Maid)
local Helpers = require(script.Parent.Parent.Utils.Helpers)

local Paragraph = {}
Paragraph.__index = Paragraph

export type ParagraphOptions = {
	Title: string?,
	Content: string?,
}

export type ParagraphHandle = {
	Set: (self: ParagraphHandle, content: string) -> (),
	Get: (self: ParagraphHandle) -> string,
	SetTitle: (self: ParagraphHandle, title: string) -> (),
	GetTitle: (self: ParagraphHandle) -> string,
	Destroy: (self: ParagraphHandle) -> (),
}

function Paragraph.new(section: any, data: ParagraphOptions): ParagraphHandle
	local self = setmetatable({
		_Section = section,
		_Data = data,
		_Maid = Maid.new(),
		_Title = data.Title or "",
		_Content = data.Content or "",
	}, Paragraph)

	local library = section.Tab.Window.Library

	local row = Helpers.CreateFrame({
		Name = "Paragraph",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = library.Theme.Background,
		Parent = section.Inner,
	})
	Helpers.Corner(row, Theme.CornerRadiusSmall)
	Helpers.Padding(row, 12)
	Helpers.ListLayout(row, 6)

	local titleLabel = Helpers.CreateLabel({
		Name = "Title",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = self._Title,
		Font = Theme.FontBold,
		TextSize = 15,
		TextWrapped = true,
		Visible = self._Title ~= "",
		Parent = row,
	})

	local contentLabel = Helpers.CreateLabel({
		Name = "Content",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = self._Content,
		TextColor3 = library.Theme.TextMuted,
		TextWrapped = true,
		Parent = row,
	})

	self.Instance = row
	self.TitleLabel = titleLabel
	self.ContentLabel = contentLabel

	return self :: any
end

function Paragraph:RefreshTheme()
	local theme = self._Section.Tab.Window.Library.Theme
	self.Instance.BackgroundColor3 = theme.Background
	self.TitleLabel.TextColor3 = theme.Text
	self.ContentLabel.TextColor3 = theme.TextMuted
end

function Paragraph:Set(content: string)
	self._Content = content
	self.ContentLabel.Text = content
end

function Paragraph:Get(): string
	return self._Content
end

function Paragraph:SetTitle(title: string)
	self._Title = title
	self.TitleLabel.Text = title
	self.TitleLabel.Visible = title ~= ""
end

function Paragraph:GetTitle(): string
	return self._Title
end

function Paragraph:Destroy()
	self._Maid:DoCleaning()
end

return Paragraph
