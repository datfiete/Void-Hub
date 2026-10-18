--!strict

local Theme = require(script.Parent.Parent.Core.Theme)
local Maid = require(script.Parent.Parent.Utils.Maid)
local Helpers = require(script.Parent.Parent.Utils.Helpers)

local Paragraph = {}
Paragraph.__index = Paragraph

export type ParagraphOptions = {
	Title: string?,
	Content: string?,
	-- Auto-bind content to an Instance property, e.g. "workspace.Fish.WeightLabel.ContentText"
	Path: string?,
	Bind: string?, -- alias of Path
	-- Or explicit:
	Instance: Instance?,
	Property: string?,
	-- Optional title bind
	TitlePath: string?,
	-- Formatting
	Format: string?, -- e.g. "Weight: {value}"
	Prefix: string?,
	Suffix: string?,
	-- How often to re-resolve missing paths / poll (seconds)
	PollInterval: number?,
}

export type ParagraphHandle = {
	Set: (self: ParagraphHandle, content: string) -> (),
	Get: (self: ParagraphHandle) -> string,
	SetTitle: (self: ParagraphHandle, title: string) -> (),
	GetTitle: (self: ParagraphHandle) -> string,
	BindPath: (self: ParagraphHandle, path: string, isTitle: boolean?) -> boolean,
	Unbind: (self: ParagraphHandle) -> (),
	Destroy: (self: ParagraphHandle) -> (),
}

local function splitPath(path: string): { string }
	local parts = {}
	for part in string.gmatch(path, "[^%.]+") do
		table.insert(parts, part)
	end
	return parts
end

local function resolveRoot(name: string): Instance?
	local lower = string.lower(name)
	if lower == "game" then
		return game
	end
	if lower == "workspace" or lower == "workspace" then
		return workspace
	end
	if lower == "players" then
		return game:GetService("Players")
	end
	if lower == "replicatedstorage" then
		return game:GetService("ReplicatedStorage")
	end
	if lower == "lighting" then
		return game:GetService("Lighting")
	end
	if lower == "startergui" then
		return game:GetService("StarterGui")
	end
	-- fallback: child of game or workspace
	local fromGame = game:FindFirstChild(name)
	if fromGame then
		return fromGame
	end
	return workspace:FindFirstChild(name)
end

-- Returns instance, propertyName (property is last segment if it is a property)
local function resolvePath(path: string): (Instance?, string?)
	if type(path) ~= "string" or path == "" then
		return nil, nil
	end
	local parts = splitPath(path)
	if #parts < 2 then
		return nil, nil
	end

	local root = resolveRoot(parts[1])
	if not root then
		return nil, nil
	end

	local current: Instance = root
	-- Walk all but last segment as instances; last may be property OR instance
	for i = 2, #parts - 1 do
		local child = current:FindFirstChild(parts[i])
		if not child then
			return nil, nil
		end
		current = child
	end

	local last = parts[#parts]
	-- Prefer property on current if it exists
	local okProp, _ = pcall(function()
		return (current :: any)[last]
	end)
	if okProp then
		-- Could be a child with same name — prefer child if Instance
		local child = current:FindFirstChild(last)
		if child and typeof((current :: any)[last]) == "Instance" and (current :: any)[last] == child then
			-- last segment is a child, no property — invalid for bind
			return child, nil
		end
		-- If FindFirstChild exists and property read returns non-instance text-like, use property
		if child and typeof((current :: any)[last]) ~= "Instance" then
			return current, last
		end
		if not child then
			return current, last
		end
		-- Ambiguous: child exists AND property exists as Instance → treat as child path incomplete
		return current, last
	end

	local child = current:FindFirstChild(last)
	if child then
		return child, nil
	end
	return nil, nil
end

local function readProperty(inst: Instance, prop: string): string?
	local ok, value = pcall(function()
		return (inst :: any)[prop]
	end)
	if not ok or value == nil then
		return nil
	end
	return tostring(value)
end

function Paragraph.new(section: any, data: ParagraphOptions): ParagraphHandle
	data = data or {} :: any
	local self = setmetatable({
		_Section = section,
		_Data = data,
		_Maid = Maid.new(),
		_BindMaid = Maid.new(),
		_Title = data.Title or "",
		_Content = data.Content or "",
		_Format = data.Format,
		_Prefix = data.Prefix or "",
		_Suffix = data.Suffix or "",
		_PollInterval = tonumber(data.PollInterval) or 0.35,
	}, Paragraph)

	local library = section.Tab.Window.Library

	local row = Helpers.CreateFrame({
		Name = "Paragraph",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = library.Theme.ElementBackground or library.Theme.Background,
		Parent = section.Inner,
	})
	Helpers.Corner(row, Theme.CornerRadiusSmall)
	local rowStroke = Helpers.Stroke(row, library.Theme.Border, 1)
	local rowGlow = Helpers.Stroke(row, library.Theme.Accent, 2)
	self._RowStroke = rowStroke
	self._RowGlow = rowGlow
	rowGlow.Transparency = 0.95
	rowStroke.Transparency = 0.18
	Helpers.Padding(row, 12)
	Helpers.ListLayout(row, 6)

	local titleLabel = Helpers.CreateLabel({
		Name = "Title",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = self._Title,
		Font = Theme.FontBold,
		TextSize = 17,
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

	self.RowGlow = rowGlow
	self.Instance = row
	self.TitleLabel = titleLabel
	self.ContentLabel = contentLabel

	-- Initial binds from options
	local path = data.Path or data.Bind
	if type(path) == "string" and path ~= "" then
		self:BindPath(path, false)
	elseif data.Instance and type(data.Property) == "string" then
		self:_bindInstance(data.Instance, data.Property, false)
	end
	if type(data.TitlePath) == "string" and data.TitlePath ~= "" then
		self:BindPath(data.TitlePath, true)
	end

	return self :: any
end

function Paragraph:_formatValue(raw: string): string
	local text = raw
	if self._Format and self._Format ~= "" then
		text = string.gsub(self._Format, "{value}", raw)
		text = string.gsub(text, "{VALUE}", raw)
	end
	return tostring(self._Prefix or "") .. text .. tostring(self._Suffix or "")
end

function Paragraph:_applyBound(value: string, isTitle: boolean?)
	local formatted = self:_formatValue(value)
	if isTitle then
		self:SetTitle(formatted)
	else
		self:Set(formatted)
	end
end

function Paragraph:_bindInstance(inst: Instance, prop: string, isTitle: boolean?)
	local function push()
		local value = readProperty(inst, prop)
		if value ~= nil then
			self:_applyBound(value, isTitle)
		end
	end
	push()

	-- Property changed signal when available
	local okSignal, signal = pcall(function()
		return inst:GetPropertyChangedSignal(prop)
	end)
	if okSignal and signal then
		self._BindMaid:GiveTask(signal:Connect(push))
	end

	-- Light poll as fallback (some values change without signals / replication lag)
	self._BindMaid:GiveTask(task.spawn(function()
		while true do
			task.wait(self._PollInterval)
			if not self.Instance or not self.Instance.Parent then
				break
			end
			if not inst.Parent then
				break
			end
			push()
		end
	end))
end

function Paragraph:BindPath(path: string, isTitle: boolean?): boolean
	if not isTitle then
		-- reset content bind only — keep title bind by re-binding both is complex; clear all binds then re-apply title if needed
		self._BindMaid:DoCleaning()
		self._BindMaid = Maid.new()
		self._ContentPath = path
	else
		self._TitlePath = path
	end

	local inst, prop = resolvePath(path)
	if inst and prop then
		self:_bindInstance(inst, prop, isTitle)
		return true
	end

	-- Path not ready yet — retry until found
	self._BindMaid:GiveTask(task.spawn(function()
		while true do
			task.wait(self._PollInterval)
			if not self.Instance or not self.Instance.Parent then
				break
			end
			local i2, p2 = resolvePath(path)
			if i2 and p2 then
				self:_bindInstance(i2, p2, isTitle)
				break
			end
		end
	end))
	return false
end

function Paragraph:Unbind()
	self._BindMaid:DoCleaning()
	self._BindMaid = Maid.new()
	self._ContentPath = nil
	self._TitlePath = nil
end

function Paragraph:RefreshTheme()
	local theme = self._Section.Tab.Window.Library.Theme
	local Tween = require(script.Parent.Parent.Utils.Tween)
	Tween.Play(self.Instance, { BackgroundColor3 = theme.ElementBackground or theme.Background }, { Time = 0.22 })
	Tween.Play(self.TitleLabel, { TextColor3 = theme.Text }, { Time = 0.22 })
	Tween.Play(self.ContentLabel, { TextColor3 = theme.TextMuted }, { Time = 0.22 })
	if self._RowStroke then
		Tween.Play(self._RowStroke, { Color = theme.Border }, { Time = 0.22 })
	end
	if self._RowGlow then
		Tween.Play(self._RowGlow, { Color = theme.Accent }, { Time = 0.22 })
	end
	for _, d in self.Instance:GetDescendants() do
		if d:IsA("UIStroke") then
			if d.Transparency > 0.5 then
				Tween.Play(d, { Color = theme.Accent }, { Time = 0.22 })
			else
				Tween.Play(d, { Color = theme.Border }, { Time = 0.22 })
			end
		end
	end
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
	self:Unbind()
	self._Maid:DoCleaning()
	if self.Instance and self.Instance.Parent then
		self.Instance:Destroy()
	end
end

return Paragraph
