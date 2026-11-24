--!strict
-- Kilo UI Layout variants.
--   Kilo      = current default shell (island + dynamic header)
--   Classic   = old Kilo look: NAVIGATION, no control module / ready ribbon / product meta
--   Minecraft = Sirius-style home + bottom dock with real tab names + close (X)
--   Orbit     = vertical neon rail + floating content stage
--   Aether    = asymmetric command-deck layout with left nav + right status pane
--   Nova      = floating-capsule layout: top pill nav + centered crystal stage + cyan accents
--   Vortex    = radial compass layout: tabs fan-arranged around a bottom-left hub
--   Prism     = book-spine spectrum rail: content stage left, tall color spines right
--   Eclipse   = eclipse monolith: timeline command rail + corona stage + top capsule

local Theme = require(script.Parent.Theme)
local Helpers = require(script.Parent.Parent.Utils.Helpers)
local Maid = require(script.Parent.Parent.Utils.Maid)

local Players = game:GetService("Players")
local Stats = game:GetService("Stats")

local LayoutVariants = {}
LayoutVariants.__index = LayoutVariants

local CLASSIC = {
	WindowSize = Vector2.new(820, 540),
	TopBarHeight = 82,
	SidebarWidth = 216,
}

local function detectExecutor(): (string, string)
	local name: string? = nil
	pcall(function()
		if typeof(identifyexecutor) == "function" then
			name = tostring(identifyexecutor())
		end
	end)
	if not name or name == "" or name == "nil" then
		pcall(function()
			if typeof(getexecutorname) == "function" then
				name = tostring(getexecutorname())
			end
		end)
	end
	if not name or name == "" or name == "nil" then
		if rawget(_G, "syn") or typeof(secure_call) == "function" then
			name = "Synapse X"
		elseif rawget(_G, "KRNL_LOADED") then
			name = "Krnl"
		elseif typeof(fluxus) == "table" or rawget(_G, "Fluxus") then
			name = "Fluxus"
		elseif typeof(isexecutorclosure) == "function" then
			name = "Unknown Executor"
		else
			name = "Roblox Client"
		end
	end
	local lower = string.lower(name :: string)
	local subtitle = name .. " — detected"
	if string.find(lower, "synapse") then
		subtitle = "Synapse X — supported client"
	elseif string.find(lower, "krnl") then
		subtitle = "Krnl — free executor"
	elseif string.find(lower, "fluxus") then
		subtitle = "Fluxus — mobile & PC"
	elseif string.find(lower, "delta") then
		subtitle = "Delta — supported client"
	elseif name == "Roblox Client" then
		subtitle = "Running inside Roblox (no executor detected)"
	end
	return name :: string, subtitle
end

local function clean(name: string): string
	local s = tostring(name or ""):gsub("^[%s%c]+", "")
	for _, prefix in {
		"⚙️ ", "⚙ ", "🎨 ", "🧩 ", "⌨️ ", "🔧 ", "💡 ", "🌐 ", "👤 ", "⚔️ ",
		"🧠 ", "📦 ", "⭐ ", "✨ ", "💎 ", "🛠️ ", "🛠 ",
	} do
		if s:sub(1, #prefix) == prefix then
			s = s:sub(#prefix + 1)
			break
		end
	end
	return s ~= "" and s or tostring(name or "Tab")
end

local function tabDisplayName(tab: any): string
	if type(tab) ~= "table" then
		return "Tab"
	end
	local raw = tab._Name or tab.Name or tab.Title
	if type(raw) == "string" and raw ~= "" then
		return clean(raw)
	end
	if tab.Button then
		local label = tab.Button:FindFirstChild("Label")
		if label and label:IsA("TextLabel") and label.Text ~= "" then
			return clean(label.Text)
		end
	end
	return "Tab"
end

local function placeCloseButton(parent: Instance, w: any, opts: any): TextButton
	opts = opts or {}
	local btn = Instance.new("TextButton")
	btn.Name = opts.Name or "Close"
	btn.Size = opts.Size or UDim2.fromOffset(42, 42)
	btn.AnchorPoint = Vector2.new(1, 0)
	btn.Position = opts.Position or UDim2.new(1, -20, 0, 20)
	btn.BackgroundColor3 = opts.BackgroundColor3 or Color3.fromRGB(22, 24, 34)
	btn.BackgroundTransparency = opts.BackgroundTransparency or 0.08
	btn.BorderSizePixel = 0
	btn.AutoButtonColor = false
	btn.Text = "×"
	btn.Font = Theme.FontBold
	btn.TextSize = opts.TextSize or 22
	btn.TextColor3 = opts.TextColor3 or Color3.fromRGB(235, 235, 245)
	btn.TextXAlignment = Enum.TextXAlignment.Center
	btn.TextYAlignment = Enum.TextYAlignment.Center
	btn.ZIndex = opts.ZIndex or 50
	btn.Parent = parent
	Helpers.Corner(btn, opts.Corner or 12)
	if opts.StrokeColor then
		Helpers.Stroke(btn, opts.StrokeColor, 1)
	end
	btn.MouseButton1Click:Connect(function()
		if w and w.SetVisible then
			w:SetVisible(false)
		end
	end)
	return btn
end

function LayoutVariants.new(window: any, initial: string): any
	local self = setmetatable({
		_Window = window,
		_Mode = "Kilo",
		_Maid = Maid.new(),
		_AltGui = nil,
		_Root = nil,
		_Home = nil,
		_ContentHost = nil,
		_PageHost = nil,
		_Dock = nil,
		_DockTabRow = nil,
		_DockTabButtons = {},
		_HomeBtn = nil,
		_CloseBtn = nil,
		_ClockLabel = nil,
		_ActiveTabName = nil,
		_ShowingHome = true,
		_AetherGui = nil,
		_AetherRoot = nil,
		_AetherStage = nil,
		_AetherPageHost = nil,
		_AetherTabList = nil,
		_AetherTabs = {},
		_AetherActiveTitle = nil,
		_NovaGui = nil,
		_NovaRoot = nil,
		_NovaStage = nil,
		_NovaPageHost = nil,
		_NovaTabRow = nil,
		_NovaTabs = {},
		_NovaActiveTitle = nil,
		_VortexGui = nil,
		_VortexRoot = nil,
		_VortexStage = nil,
		_VortexPageHost = nil,
		_VortexHub = nil,
		_VortexTabs = {},
		_VortexActiveLabel = nil,
		_PrismGui = nil,
		_PrismRoot = nil,
		_PrismStage = nil,
		_PrismPageHost = nil,
		_PrismSpineRow = nil,
		_PrismTabs = {},
		_PrismActiveLabel = nil,
		_EclipseGui = nil,
		_EclipseRoot = nil,
		_EclipseStage = nil,
		_EclipsePageHost = nil,
		_EclipseTimeline = nil,
		_EclipseTabs = {},
		_EclipseActiveLabel = nil,
		_EclipseClock = nil,
		_ExecutorName = "Unknown",
		_ExecutorSub = "",
		_PagesHome = nil,
		_ClassicSnapshot = nil,
		_ClassicApplied = false,
		_ChromeHidden = false,
	} , LayoutVariants)

	if window.Pages then
		self._PagesHome = {
			Parent = window.Pages.Parent,
			Size = window.Pages.Size,
			Position = window.Pages.Position,
		}
	end

	local execName, execSub = detectExecutor()
	self._ExecutorName = execName
	self._ExecutorSub = execSub

	self:_buildMinecraftShell()
	self:SetMode(initial or "Kilo")
	return self
end

----------------------------------------------------------------------
-- Classic
----------------------------------------------------------------------
function LayoutVariants:_snapshotClassic()
	local w = self._Window
	if self._ClassicSnapshot or not w or not w.Main then
		return
	end
	self._ClassicSnapshot = {
		MainSize = w.Main.Size,
		TopBarSize = w.TopBar and w.TopBar.Size or nil,
		ContentSize = w._ContentArea and w._ContentArea.Size or nil,
		ContentPos = w._ContentArea and w._ContentArea.Position or nil,
		SidebarSize = w.Sidebar and w.Sidebar.Size or nil,
		PagesSize = w.Pages and w.Pages.Size or nil,
		PagesPos = w.Pages and w.Pages.Position or nil,
		SidebarWidth = w._SidebarWidth,
		TopBarHeight = w._TopBarHeight,
		NavText = (w._NavLabel and w._NavLabel.Text) or "WORKSPACE",
	}
end

function LayoutVariants:_setClassicChrome(hidden: boolean)
	local w = self._Window
	if not w then
		return
	end
	if w._StatusRibbon then
		w._StatusRibbon.Visible = not hidden
	end
	if w._ProductMeta then
		w._ProductMeta.Visible = not hidden
	end
	if w._NavLabel then
		w._NavLabel.Text = if hidden then "NAVIGATION" else (self._ClassicSnapshot and self._ClassicSnapshot.NavText) or "WORKSPACE"
	end
	if w._Tabs then
		for _, tab in ipairs(w._Tabs) do
			if tab._PageHeader then
				tab._PageHeader.Visible = not hidden
				if hidden then
					tab._PageHeader.Size = UDim2.new(1, 0, 0, 0)
				else
					tab._PageHeader.Size = UDim2.new(1, -(18 + 22), 0, 62)
				end
			end
			if tab._PageEyebrow then
				tab._PageEyebrow.Visible = not hidden
			end
			if tab._PageTitle then
				tab._PageTitle.Visible = not hidden
			end
			if tab._PageLine then
				tab._PageLine.Visible = not hidden
			end
			if tab._Columns then
				if hidden then
					tab._Columns.Position = UDim2.fromOffset(18, 12)
				else
					tab._Columns.Position = UDim2.fromOffset(18, 88)
				end
			end
		end
	end
	self._ChromeHidden = hidden
end

function LayoutVariants:_applyClassicWindow()
	local w = self._Window
	if not w or not w.Main then
		return
	end
	self:_snapshotClassic()

	local top = CLASSIC.TopBarHeight
	local side = CLASSIC.SidebarWidth
	local size = CLASSIC.WindowSize

	w.Main.Size = UDim2.fromOffset(size.X, size.Y)
	w._SidebarWidth = side
	w._TopBarHeight = top

	if w.TopBar then
		w.TopBar.Size = UDim2.new(1, 0, 0, top)
	end
	if w._ContentArea then
		w._ContentArea.Position = UDim2.new(0, 0, 0, top)
		w._ContentArea.Size = UDim2.new(1, 0, 1, -top)
	end
	if w.Sidebar then
		w.Sidebar.Size = UDim2.new(0, side, 1, 0)
	end
	if w.Pages then
		w.Pages.Position = UDim2.new(0, side, 0, 0)
		w.Pages.Size = UDim2.new(1, -side, 1, 0)
	end

	self:_setClassicChrome(true)
	self._ClassicApplied = true
end

function LayoutVariants:_restoreClassicWindow()
	local w = self._Window
	local snap = self._ClassicSnapshot
	if self._ChromeHidden then
		self:_setClassicChrome(false)
	end
	if not self._ClassicApplied or not snap or not w then
		self._ClassicApplied = false
		return
	end

	if w.Main and snap.MainSize then
		w.Main.Size = snap.MainSize
	end
	if w.TopBar and snap.TopBarSize then
		w.TopBar.Size = snap.TopBarSize
	end
	if w._ContentArea then
		if snap.ContentSize then
			w._ContentArea.Size = snap.ContentSize
		end
		if snap.ContentPos then
			w._ContentArea.Position = snap.ContentPos
		end
	end
	if w.Sidebar and snap.SidebarSize then
		w.Sidebar.Size = snap.SidebarSize
	end
	if w.Pages then
		if snap.PagesSize then
			w.Pages.Size = snap.PagesSize
		end
		if snap.PagesPos then
			w.Pages.Position = snap.PagesPos
		end
	end
	if snap.SidebarWidth then
		w._SidebarWidth = snap.SidebarWidth
	end
	if snap.TopBarHeight then
		w._TopBarHeight = snap.TopBarHeight
	end
	self._ClassicApplied = false
end

function LayoutVariants:_setContentHeaderCollapsed(collapsed: boolean)
	local w = self._Window
	if not w or not w._Tabs then
		return
	end
	for _, tab in ipairs(w._Tabs) do
		if tab._PageHeader then
			tab._PageHeader.Visible = not collapsed
			tab._PageHeader.Size = if collapsed then UDim2.new(1, 0, 0, 0) else UDim2.new(1, -(18 + 22), 0, 62)
		end
		if tab._PageEyebrow then
			tab._PageEyebrow.Visible = not collapsed
		end
		if tab._PageTitle then
			tab._PageTitle.Visible = not collapsed
		end
		if tab._PageLine then
			tab._PageLine.Visible = not collapsed
		end
		if tab._Columns then
			tab._Columns.Position = if collapsed then UDim2.fromOffset(18, 12) else UDim2.fromOffset(18, 88)
		end
	end
end

----------------------------------------------------------------------
-- Pages reparent
----------------------------------------------------------------------
function LayoutVariants:_ensurePagesHome()
	local w = self._Window
	if self._PagesHome or not w or not w.Pages then
		return
	end
	self._PagesHome = {
		Parent = w.Pages.Parent,
		Size = w.Pages.Size,
		Position = w.Pages.Position,
	}
end

function LayoutVariants:_movePagesToHost()
	local w = self._Window
	if not w or not w.Pages or not self._PageHost then
		return
	end
	self:_ensurePagesHome()
	if w.Pages.Parent ~= self._PageHost then
		w.Pages.Parent = self._PageHost
	end
	w.Pages.Size = UDim2.fromScale(1, 1)
	w.Pages.Position = UDim2.fromScale(0, 0)
	w.Pages.Visible = true
	self:_setContentHeaderCollapsed(true)
end

function LayoutVariants:_restorePagesToWindow()
	local w = self._Window
	local home = self._PagesHome
	if not w or not w.Pages or not home then
		return
	end
	if home.Parent and w.Pages.Parent ~= home.Parent then
		w.Pages.Parent = home.Parent
	end
	if home.Size then
		w.Pages.Size = home.Size
	end
	if home.Position then
		w.Pages.Position = home.Position
	end
	w.Pages.Visible = true
	if not self._ChromeHidden then
		self:_setContentHeaderCollapsed(false)
	end
end

----------------------------------------------------------------------
-- Minecraft shell
----------------------------------------------------------------------
function LayoutVariants:_buildMinecraftShell()
	local w = self._Window
	local parent = w._TopGuiParent or (w.Gui and w.Gui.Parent)
	if not parent then
		return
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "KiloMinecraftShell"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = 2147483646
	gui.Enabled = false
	gui.Parent = parent
	self._AltGui = gui

	local root = Helpers.CreateFrame({
		Name = "Root",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Parent = gui,
	})
	self._Root = root

	Helpers.CreateFrame({
		Name = "Dim",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.55,
		Parent = root,
	}).ZIndex = 0

	local closeBtn = Helpers.CreateButton({
		Name = "Close",
		Size = UDim2.fromOffset(40, 40),
		Position = UDim2.new(1, -20, 0, 20),
		AnchorPoint = Vector2.new(1, 0),
		Text = "×",
		TextXAlignment = Enum.TextXAlignment.Center,
		Font = Theme.FontBold,
		TextSize = 22,
		TextColor3 = Color3.fromRGB(230, 230, 240),
		BackgroundColor3 = Color3.fromRGB(22, 24, 32),
		BackgroundTransparency = 0.1,
		ZIndex = 50,
		Parent = root,
	})
	Helpers.Corner(closeBtn, 12)
	Helpers.Stroke(closeBtn, Color3.fromRGB(55, 58, 72), 1)
	closeBtn.ZIndex = 10
	self._CloseBtn = closeBtn
	closeBtn.MouseButton1Click:Connect(function()
		if w.SetVisible then
			w:SetVisible(false)
		end
	end)

	local homeScroll = Instance.new("ScrollingFrame")
	homeScroll.Name = "HomeScroll"
	homeScroll.Size = UDim2.new(1, -80, 1, -120)
	homeScroll.Position = UDim2.new(0.5, 0, 0, 24)
	homeScroll.AnchorPoint = Vector2.new(0.5, 0)
	homeScroll.BackgroundTransparency = 1
	homeScroll.BorderSizePixel = 0
	homeScroll.ScrollBarThickness = 4
	homeScroll.ScrollBarImageColor3 = Theme.Accent
	homeScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	homeScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	homeScroll.ScrollingDirection = Enum.ScrollingDirection.Y
	homeScroll.ZIndex = 2
	homeScroll.Parent = root
	self._Home = homeScroll

	local homeInner = Helpers.CreateFrame({
		Name = "Inner",
		Size = UDim2.new(1, -8, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = homeScroll,
	})
	Helpers.Padding(homeInner, Rect.new(0, 0, 8, 20))
	local homeLayout = Instance.new("UIListLayout")
	homeLayout.FillDirection = Enum.FillDirection.Vertical
	homeLayout.Padding = UDim.new(0, 12)
	homeLayout.SortOrder = Enum.SortOrder.LayoutOrder
	homeLayout.Parent = homeInner

	Helpers.CreateLabel({
		Name = "HomeTitle",
		Size = UDim2.new(1, 0, 0, 28),
		Text = "Home",
		Font = Theme.FontBold,
		TextSize = 26,
		TextColor3 = Color3.fromRGB(245, 245, 250),
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 0,
		Parent = homeInner,
	})
	Helpers.CreateLabel({
		Name = "HomeSub",
		Size = UDim2.new(1, 0, 0, 18),
		Text = "Kilo UI",
		Font = Theme.Font,
		TextSize = 13,
		TextColor3 = Color3.fromRGB(160, 165, 180),
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 1,
		Parent = homeInner,
	})

	local row1 = Helpers.CreateFrame({
		Name = "Row1",
		Size = UDim2.new(1, 0, 0, 168),
		BackgroundTransparency = 1,
		LayoutOrder = 2,
		Parent = homeInner,
	})
	local r1 = Instance.new("UIListLayout")
	r1.FillDirection = Enum.FillDirection.Horizontal
	r1.Padding = UDim.new(0, 12)
	r1.Parent = row1

	local row2 = Helpers.CreateFrame({
		Name = "Row2",
		Size = UDim2.new(1, 0, 0, 56),
		BackgroundTransparency = 1,
		LayoutOrder = 3,
		Parent = homeInner,
	})
	local r2 = Instance.new("UIListLayout")
	r2.FillDirection = Enum.FillDirection.Horizontal
	r2.Padding = UDim.new(0, 12)
	r2.Parent = row2

	local contentHost = Helpers.CreateFrame({
		Name = "ContentHost",
		Size = UDim2.new(1, -80, 1, -120),
		Position = UDim2.new(0.5, 0, 0, 24),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = Theme.Background,
		BackgroundTransparency = 0.08,
		Visible = false,
		Parent = root,
	})
	Helpers.Corner(contentHost, 16)
	Helpers.Stroke(contentHost, Theme.BorderStrong, 1)
	contentHost.ZIndex = 2
	self._ContentHost = contentHost

	local pageHost = Helpers.CreateFrame({
		Name = "PageHost",
		Size = UDim2.new(1, -20, 1, -20),
		Position = UDim2.fromOffset(10, 10),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Parent = contentHost,
	})
	self._PageHost = pageHost

	self:_buildDock(root)
end

function LayoutVariants:_card(parent: Instance, props: any): Frame
	local card = Helpers.CreateFrame({
		Name = props.Name,
		Size = props.Size,
		BackgroundColor3 = props.BackgroundColor3 or Color3.fromRGB(16, 18, 26),
		BackgroundTransparency = 0.08,
		LayoutOrder = props.LayoutOrder or 0,
		Parent = parent,
	})
	Helpers.Corner(card, 14)
	Helpers.Stroke(card, Theme.BorderStrong, 1)
	return card
end

function LayoutVariants:_buildServerCard(parent: Instance)
	local card = self:_card(parent, {
		Name = "ServerCard",
		Size = UDim2.new(0.5, -6, 1, 0),
		BackgroundColor3 = Color3.fromRGB(18, 48, 38),
		LayoutOrder = 1,
	})
	Helpers.CreateFrame({
		Name = "Accent",
		Size = UDim2.new(1, 0, 0, 3),
		BackgroundColor3 = Theme.Accent,
		Parent = card,
	})
	Helpers.CreateLabel({
		Name = "Title",
		Size = UDim2.new(1, -24, 0, 20),
		Position = UDim2.fromOffset(14, 12),
		Text = "Server",
		Font = Theme.FontBold,
		TextSize = 15,
		TextColor3 = Color3.fromRGB(240, 245, 250),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = card,
	})
	Helpers.CreateLabel({
		Name = "Sub",
		Size = UDim2.new(1, -24, 0, 16),
		Position = UDim2.fromOffset(14, 32),
		Text = "Information on the session you're currently in",
		Font = Theme.Font,
		TextSize = 11,
		TextColor3 = Color3.fromRGB(150, 170, 160),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = card,
	})
	local stats = Helpers.CreateFrame({
		Name = "Stats",
		Size = UDim2.new(1, -24, 0, 90),
		Position = UDim2.fromOffset(14, 56),
		BackgroundTransparency = 1,
		Parent = card,
	})
	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.new(0.5, -6, 0, 40)
	grid.CellPadding = UDim2.fromOffset(8, 6)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = stats
	local function stat(name: string, label: string, order: number): TextLabel
		local box = Helpers.CreateFrame({
			Name = name,
			BackgroundColor3 = Theme.Background,
			BackgroundTransparency = 0.25,
			LayoutOrder = order,
			Parent = stats,
		})
		Helpers.Corner(box, 8)
		Helpers.CreateLabel({
			Name = "L",
			Size = UDim2.new(1, -12, 0, 14),
			Position = UDim2.fromOffset(8, 4),
			Text = label,
			Font = Theme.Font,
			TextSize = 10,
			TextColor3 = Theme.TextMuted,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = box,
		})
		return Helpers.CreateLabel({
			Name = "V",
			Size = UDim2.new(1, -12, 0, 16),
			Position = UDim2.fromOffset(8, 18),
			Text = "—",
			Font = Theme.FontBold,
			TextSize = 13,
			TextColor3 = Theme.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = box,
		})
	end
	self._StatPlayers = stat("Players", "Players", 1)
	self._StatMax = stat("Max", "Maximum Players", 2)
	self._StatLatency = stat("Latency", "Latency", 3)
	self._StatRegion = stat("Region", "Server Region", 4)
end

function LayoutVariants:_buildFriendsCard(parent: Instance)
	local card = self:_card(parent, {
		Name = "FriendsCard",
		Size = UDim2.new(0.5, -6, 1, 0),
		BackgroundColor3 = Theme.Background,
		LayoutOrder = 2,
	})
	Helpers.CreateLabel({
		Name = "Title",
		Size = UDim2.new(1, -24, 0, 20),
		Position = UDim2.fromOffset(14, 12),
		Text = "Friends",
		Font = Theme.FontBold,
		TextSize = 15,
		TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = card,
	})
	Helpers.CreateLabel({
		Name = "Sub",
		Size = UDim2.new(1, -24, 0, 16),
		Position = UDim2.fromOffset(14, 32),
		Text = "Find out what your friends are currently doing",
		Font = Theme.Font,
		TextSize = 11,
		TextColor3 = Theme.TextMuted,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = card,
	})
	local stats = Helpers.CreateFrame({
		Name = "Stats",
		Size = UDim2.new(1, -24, 0, 90),
		Position = UDim2.fromOffset(14, 56),
		BackgroundTransparency = 1,
		Parent = card,
	})
	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.new(0.5, -6, 0, 40)
	grid.CellPadding = UDim2.fromOffset(8, 6)
	grid.Parent = stats
	local function fstat(name: string, label: string, order: number, accent: Color3): TextLabel
		local box = Helpers.CreateFrame({
			Name = name,
			BackgroundColor3 = Theme.Secondary,
			BackgroundTransparency = 0.15,
			LayoutOrder = order,
			Parent = stats,
		})
		Helpers.Corner(box, 8)
		local bar = Helpers.CreateFrame({
			Name = "Bar",
			Size = UDim2.new(0, 3, 1, -10),
			Position = UDim2.fromOffset(6, 5),
			BackgroundColor3 = accent,
			Parent = box,
		})
		Helpers.Corner(bar, 2)
		Helpers.CreateLabel({
			Name = "L",
			Size = UDim2.new(1, -16, 0, 14),
			Position = UDim2.fromOffset(14, 4),
			Text = label,
			Font = Theme.Font,
			TextSize = 10,
			TextColor3 = Theme.TextMuted,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = box,
		})
		return Helpers.CreateLabel({
			Name = "V",
			Size = UDim2.new(1, -16, 0, 16),
			Position = UDim2.fromOffset(14, 18),
			Text = "0",
			Font = Theme.FontBold,
			TextSize = 13,
			TextColor3 = Theme.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = box,
		})
	end
	self._FriendInServer = fstat("InServer", "In Server", 1, Theme.Accent)
	self._FriendOffline = fstat("Offline", "Offline", 2, Theme.TextMuted)
	self._FriendOnline = fstat("Online", "Online", 3, Theme.Warning or Color3.fromRGB(247, 185, 78))
	self._FriendAll = fstat("All", "All", 4, Theme.AccentAlt)
end

function LayoutVariants:_buildProfileStrip(parent: Instance)
	local lp = Players.LocalPlayer
	local displayName = lp and (lp.DisplayName or lp.Name) or "Player"
	local userId = lp and lp.UserId or 0

	local function strip(name: string, title: string, sub: string, color: Color3, order: number)
		local card = self:_card(parent, {
			Name = name,
			Size = UDim2.new(0.33, -8, 1, 0),
			BackgroundColor3 = color,
			LayoutOrder = order,
		})
		Helpers.CreateLabel({
			Name = "Title",
			Size = UDim2.new(1, -56, 0, 18),
			Position = UDim2.fromOffset(48, 10),
			Text = title,
			Font = Theme.FontBold,
			TextSize = 13,
			TextColor3 = Theme.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = card,
		})
		Helpers.CreateLabel({
			Name = "Sub",
			Size = UDim2.new(1, -56, 0, 14),
			Position = UDim2.fromOffset(48, 30),
			Text = sub,
			Font = Theme.Font,
			TextSize = 11,
			TextColor3 = Theme.TextMuted,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = card,
		})
		local avatar = Instance.new("ImageLabel")
		avatar.Name = "Avatar"
		avatar.Size = UDim2.fromOffset(32, 32)
		avatar.Position = UDim2.fromOffset(10, 12)
		avatar.BackgroundColor3 = Theme.ElementBackground
		avatar.BackgroundTransparency = 0.2
		avatar.Image = string.format(
			"https://www.roblox.com/headshot-thumbnail/image?userId=%d&width=48&height=48&format=png",
			userId
		)
		avatar.Parent = card
		Helpers.Corner(avatar, 8)
	end

	strip("DisplayCard", displayName, "DisplayName", Theme.Secondary, 1)
	strip("ExecutorCard", self._ExecutorName, self._ExecutorSub, Theme.Background, 2)
	strip("DiscordCard", "Discord", "Tap to join our Discord server for updates and more", Theme.Surface, 3)
end

function LayoutVariants:_buildDock(root: Frame)
	local dock = Helpers.CreateFrame({
		Name = "Dock",
		Size = UDim2.fromOffset(680, 58),
		Position = UDim2.new(0.5, 0, 1, -80),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = Theme.Secondary,
		BackgroundTransparency = 0.06,
		Parent = root,
	})
	Helpers.Corner(dock, 22)
	Helpers.Stroke(dock, Theme.BorderStrong, 1)
	dock.ZIndex = 5
	self._Dock = dock

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 14)
	pad.PaddingRight = UDim.new(0, 14)
	pad.Parent = dock

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = dock

	local clock = Helpers.CreateLabel({
		Name = "Clock",
		Size = UDim2.fromOffset(46, 40),
		Text = os.date("%H:%M"),
		Font = Theme.FontBold,
		TextSize = 13,
		TextColor3 = Theme.Text,
		LayoutOrder = 1,
		Parent = dock,
	})
	self._ClockLabel = clock

	local homeBtn = Helpers.CreateButton({
		Name = "Home",
		Size = UDim2.fromOffset(40, 40),
		Text = "⌂",
		Font = Theme.FontBold,
		TextSize = 18,
		TextColor3 = Theme.Text,
		BackgroundColor3 = Theme.Background,
		BackgroundTransparency = 0.2,
		LayoutOrder = 2,
		ZIndex = 50,
		Parent = dock,
	})
	Helpers.Corner(homeBtn, 12)
	self._HomeBtn = homeBtn
	homeBtn.MouseButton1Click:Connect(function()
		self:_showHome()
	end)

	local tabScroll = Instance.new("ScrollingFrame")
	tabScroll.Name = "DockTabs"
	tabScroll.Size = UDim2.fromOffset(460, 42)
	tabScroll.BackgroundTransparency = 1
	tabScroll.BorderSizePixel = 0
	tabScroll.ScrollBarThickness = 0
	tabScroll.ScrollingDirection = Enum.ScrollingDirection.X
	tabScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	tabScroll.AutomaticCanvasSize = Enum.AutomaticSize.X
	tabScroll.ClipsDescendants = true
	tabScroll.LayoutOrder = 3
	tabScroll.ZIndex = 50
	tabScroll.Parent = dock

	local tabRow = Helpers.CreateFrame({
		Name = "Row",
		Size = UDim2.new(0, 0, 1, 0),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		ZIndex = 50,
		Parent = tabScroll,
	})
	local rowLayout = Instance.new("UIListLayout")
	rowLayout.FillDirection = Enum.FillDirection.Horizontal
	rowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	rowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	rowLayout.Padding = UDim.new(0, 6)
	rowLayout.Parent = tabRow
	self._DockTabRow = tabRow

	rowLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		local width = rowLayout.AbsoluteContentSize.X
		tabScroll.CanvasSize = UDim2.fromOffset(math.max(width, tabScroll.AbsoluteSize.X), 0)
		if width < tabScroll.AbsoluteSize.X then
			tabRow.Position = UDim2.fromOffset(math.floor((tabScroll.AbsoluteSize.X - width) / 2), 0)
		else
			tabRow.Position = UDim2.fromOffset(0, 0)
		end
	end)

	local dockClose = Helpers.CreateButton({
		Name = "DockClose",
		Size = UDim2.fromOffset(40, 40),
		Text = "×",
		TextXAlignment = Enum.TextXAlignment.Center,
		Font = Theme.FontBold,
		TextSize = 20,
		TextColor3 = Theme.Text,
		BackgroundColor3 = Theme.Background,
		BackgroundTransparency = 0.25,
		LayoutOrder = 4,
		ZIndex = 50,
		Parent = dock,
	})
	Helpers.Corner(dockClose, 12)
	dockClose.MouseButton1Click:Connect(function()
		local w = self._Window
		if w and w.SetVisible then
			w:SetVisible(false)
		end
	end)

	task.spawn(function()
		while self._AltGui and self._AltGui.Parent do
			if self._ClockLabel then
				self._ClockLabel.Text = os.date("%H:%M")
			end
			task.wait(1)
		end
	end)
end

function LayoutVariants:SyncTabs()
	if not self._DockTabRow then
		return
	end
	for _, child in ipairs(self._DockTabRow:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	self._DockTabButtons = {}

	local w = self._Window
	if not w or not w._Tabs then
		return
	end

	for i, tab in ipairs(w._Tabs) do
		local label = tabDisplayName(tab)
		local btn = Helpers.CreateButton({
			Name = "DockTab_" .. i,
			Size = UDim2.fromOffset(0, 34),
			AutomaticSize = Enum.AutomaticSize.X,
			Text = "  " .. label .. "  ",
			Font = Theme.Font,
			TextSize = 12,
			TextColor3 = Theme.TextMuted,
			TextXAlignment = Enum.TextXAlignment.Center,
			BackgroundColor3 = Theme.Background,
			BackgroundTransparency = 0.25,
			LayoutOrder = i,
			Parent = self._DockTabRow,
		})
		Helpers.Corner(btn, 10)
		self._DockTabButtons[label] = btn

		btn.MouseButton1Click:Connect(function()
			if w._selectTab then
				w:_selectTab(tab)
			end
			self:_showTabContent(label)
		end)
	end

	self:_refreshDockHighlight()
end

function LayoutVariants:_refreshDockHighlight()
	local active = self._ActiveTabName
	local onHome = self._ShowingHome
	if self._HomeBtn then
		self._HomeBtn.BackgroundTransparency = if onHome then 0.05 else 0.45
		self._HomeBtn.TextColor3 = if onHome then Theme.Text else Theme.TextMuted
	end
	for name, btn in pairs(self._DockTabButtons) do
		local selected = (not onHome) and name == active
		btn.BackgroundTransparency = if selected then 0.05 else 0.35
		btn.TextColor3 = if selected then Theme.Text else Theme.TextMuted
		btn.BackgroundColor3 = if selected then Theme.Secondary else Theme.Background
	end
end

function LayoutVariants:_showHome()
	self._ShowingHome = true
	self._ActiveTabName = nil
	if self._Home then
		self._Home.Visible = true
	end
	if self._ContentHost then
		self._ContentHost.Visible = false
	end
	self:_restorePagesToWindow()
	self:_refreshDockHighlight()
end

function LayoutVariants:_showTabContent(tabName: string)
	self._ShowingHome = false
	self._ActiveTabName = tabName
	if self._Home then
		self._Home.Visible = false
	end
	if self._ContentHost then
		self._ContentHost.Visible = true
	end
	self:_movePagesToHost()
	self:_refreshDockHighlight()
end

----------------------------------------------------------------------
-- Orbit layout
----------------------------------------------------------------------
function LayoutVariants:_ensureOrbit()
	if self._OrbitGui then
		self:_syncOrbitTabs()
		return
	end
	local w = self._Window
	local parent = w._TopGuiParent or (w.Gui and w.Gui.Parent)
	if not parent then
		return
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "KiloOrbitShell"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = 2147483645
	gui.Enabled = false
	gui.Parent = parent
	self._OrbitGui = gui

	local root = Helpers.CreateFrame({
		Name = "Root",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Parent = gui,
	})
	self._OrbitRoot = root

	local dim = Helpers.CreateFrame({
		Name = "Dim",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(4, 6, 12),
		BackgroundTransparency = 0.35,
		Parent = root,
	})
	dim.ZIndex = 0

	local rail = Helpers.CreateFrame({
		Name = "Rail",
		Size = UDim2.fromOffset(84, 440),
		Position = UDim2.new(0, 28, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = Theme.Secondary,
		BackgroundTransparency = 0.08,
		Parent = root,
	})
	Helpers.Corner(rail, 24)
	Helpers.Stroke(rail, Theme.Accent, 1)
	local railStroke = Helpers.Stroke(rail, Theme.Accent, 1)
	railStroke.Transparency = 0.35
	local glow = Helpers.CreateFrame({
		Name = "Glow",
		Size = UDim2.new(0, 3, 1, -32),
		Position = UDim2.new(1, -3, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundColor3 = Theme.Accent,
		Parent = rail,
	})
	Helpers.Corner(glow, 2)
	self._OrbitRail = rail

	local railScroll = Instance.new("ScrollingFrame")
	railScroll.Name = "OrbScroll"
	railScroll.Size = UDim2.new(1, -8, 1, -56)
	railScroll.Position = UDim2.fromOffset(4, 12)
	railScroll.BackgroundTransparency = 1
	railScroll.BorderSizePixel = 0
	railScroll.ScrollBarThickness = 0
	railScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	railScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	railScroll.ScrollingDirection = Enum.ScrollingDirection.Y
	railScroll.Parent = rail

	local orbList = Helpers.CreateFrame({
		Name = "Orbs",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = railScroll,
	})
	local ol = Instance.new("UIListLayout")
	ol.FillDirection = Enum.FillDirection.Vertical
	ol.HorizontalAlignment = Enum.HorizontalAlignment.Center
	ol.Padding = UDim.new(0, 10)
	ol.Parent = orbList
	self._OrbitOrbList = orbList
	self._OrbitOrbs = {}

	local stage = Helpers.CreateFrame({
		Name = "Stage",
		Size = UDim2.new(1, -160, 1, -56),
		Position = UDim2.fromOffset(132, 28),
		BackgroundColor3 = Theme.Background,
		BackgroundTransparency = 0.06,
		Parent = root,
	})
	Helpers.Corner(stage, 20)
	Helpers.Stroke(stage, Theme.Accent, 1)
	self._OrbitStage = stage

	local stageHost = Helpers.CreateFrame({
		Name = "Host",
		Size = UDim2.new(1, -24, 1, -24),
		Position = UDim2.fromOffset(12, 12),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Parent = stage,
	})
	self._OrbitPageHost = stageHost

	local closeBtn = Helpers.CreateButton({
		Name = "Close",
		Size = UDim2.fromOffset(40, 40),
		Position = UDim2.new(1, -20, 0, 20),
		AnchorPoint = Vector2.new(1, 0),
		Text = "×",
		TextXAlignment = Enum.TextXAlignment.Center,
		Font = Theme.FontBold,
		TextSize = 22,
		TextColor3 = Theme.Text,
		BackgroundColor3 = Theme.Background,
		BackgroundTransparency = 0.1,
		Parent = root,
	})
	Helpers.Corner(closeBtn, 12)
	Helpers.Stroke(closeBtn, Theme.Accent, 1)
	closeBtn.ZIndex = 10
	closeBtn.MouseButton1Click:Connect(function()
		if w.SetVisible then
			w:SetVisible(false)
		end
	end)

	self:_syncOrbitTabs()
end

function LayoutVariants:_setOrbitVisible(visible: boolean)
	if self._OrbitGui then
		self._OrbitGui.Enabled = visible
	end
	if visible then
		self:_mountOrbitPages()
		self:_syncOrbitTabs()
	else
		if self._OrbitPageHost and self._Window and self._Window.Pages then
			if self._Window.Pages.Parent == self._OrbitPageHost then
				self:_restorePagesToWindow()
			end
		end
	end
end

function LayoutVariants:_mountOrbitPages()
	local w = self._Window
	if not w or not w.Pages or not self._OrbitPageHost then
		return
	end
	self:_ensurePagesHome()
	if w.Pages.Parent ~= self._OrbitPageHost then
		w.Pages.Parent = self._OrbitPageHost
	end
	w.Pages.Size = UDim2.fromScale(1, 1)
	w.Pages.Position = UDim2.fromScale(0, 0)
	w.Pages.Visible = true
	self:_setContentHeaderCollapsed(true)
end

function LayoutVariants:_syncOrbitTabs()
	if not self._OrbitOrbList then
		return
	end
	for _, child in ipairs(self._OrbitOrbList:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	self._OrbitOrbs = {}

	local w = self._Window
	if not w or not w._Tabs then
		return
	end

	for i, tab in ipairs(w._Tabs) do
		local label = tabDisplayName(tab)
		local letter = string.upper(string.sub(label, 1, 1))
		local btn = Helpers.CreateButton({
			Name = "Orb_" .. i,
			Size = UDim2.fromOffset(52, 52),
			Text = letter,
			Font = Theme.FontBold,
			TextSize = 16,
			TextColor3 = Theme.TextMuted,
			TextXAlignment = Enum.TextXAlignment.Center,
			BackgroundColor3 = Theme.Background,
			BackgroundTransparency = 0.1,
			LayoutOrder = i,
			Parent = self._OrbitOrbList,
		})
		Helpers.Corner(btn, 24)
		local stroke = Helpers.Stroke(btn, Theme.Accent, 1)
		stroke.Transparency = 0.55
		self._OrbitOrbs[label] = { btn = btn, stroke = stroke, tab = tab }

		btn.MouseButton1Click:Connect(function()
			if w._selectTab then
				w:_selectTab(tab)
			end
			self:_highlightOrbit(label)
			self:_mountOrbitPages()
		end)
	end

	local activeLabel = nil
	if w._ActiveTab then
		activeLabel = tabDisplayName(w._ActiveTab)
	elseif w._Tabs[1] then
		activeLabel = tabDisplayName(w._Tabs[1])
		if w._selectTab then
			w:_selectTab(w._Tabs[1])
		end
	end
	if activeLabel then
		self:_highlightOrbit(activeLabel)
		self:_mountOrbitPages()
	end
end

function LayoutVariants:_highlightOrbit(label: string)
	for name, data in pairs(self._OrbitOrbs or {}) do
		local on = name == label
		data.btn.BackgroundColor3 = if on then Theme.Secondary else Theme.Background
		data.btn.TextColor3 = if on then Theme.Text else Theme.TextMuted
		data.stroke.Transparency = if on then 0.15 else 0.55
	end
end

----------------------------------------------------------------------
-- Aether layout
----------------------------------------------------------------------
function LayoutVariants:_ensureAether()
	if self._AetherGui then
		self:_syncAetherTabs()
		return
	end

	local w = self._Window
	local parent = w._TopGuiParent or (w.Gui and w.Gui.Parent)
	if not parent then
		return
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "KiloAetherShell"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = 2147483644
	gui.Enabled = false
	gui.Parent = parent
	self._AetherGui = gui

	local root = Helpers.CreateFrame({
		Name = "Root",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Theme.Background,
		Parent = gui,
	})
	self._AetherRoot = root

	local backdrop = Helpers.CreateFrame({
		Name = "Backdrop",
		Size = UDim2.new(1, 0, 1, -48),
		Position = UDim2.fromOffset(0, 48),
		BackgroundColor3 = Theme.Background,
		BackgroundTransparency = 0.1,
		Parent = root,
	})
	backdrop.ZIndex = 0

	local top = Helpers.CreateFrame({
		Name = "CommandHeader",
		Size = UDim2.new(1, -240, 0, 62),
		Position = UDim2.fromOffset(24, 18),
		BackgroundColor3 = Theme.Secondary,
		BackgroundTransparency = 0.02,
		Parent = root,
	})
	Helpers.Corner(top, 18)
	Helpers.Stroke(top, Theme.BorderStrong, 1)
	top.ZIndex = 3

	Helpers.CreateLabel({
		Name = "Brand",
		Size = UDim2.fromOffset(130, 22),
		Position = UDim2.fromOffset(16, 10),
		Text = "KILO // CORE",
		Font = Theme.FontBold,
		TextSize = 13,
		TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = top,
	})

	Helpers.CreateLabel({
		Name = "Subtitle",
		Size = UDim2.fromOffset(180, 16),
		Position = UDim2.fromOffset(16, 32),
		Text = "adaptive command deck",
		Font = Theme.Font,
		TextSize = 10,
		TextColor3 = Theme.TextMuted,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = top,
	})

	self._AetherActiveTitle = Helpers.CreateLabel({
		Name = "ActiveTitle",
		Size = UDim2.new(0, 280, 0, 36),
		Position = UDim2.new(0.5, -140, 0.5, -18),
		Text = "HOME",
		Font = Theme.FontBold,
		TextSize = 14,
		TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = top,
	})

	Helpers.CreateLabel({
		Name = "Status",
		Size = UDim2.fromOffset(100, 20),
		Position = UDim2.new(1, -80, 0.5, -10),
		AnchorPoint = Vector2.new(1, 0),
		Text = "● ONLINE",
		Font = Theme.FontBold,
		TextSize = 10,
		TextColor3 = Theme.Success or Color3.fromRGB(76, 220, 137),
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = top,
	})

	local clock = Helpers.CreateLabel({
		Name = "Clock",
		Size = UDim2.fromOffset(54, 20),
		Position = UDim2.new(1, -16, 0.5, -10),
		AnchorPoint = Vector2.new(1, 0),
		Text = os.date("%H:%M"),
		Font = Theme.FontBold,
		TextSize = 11,
		TextColor3 = Theme.TextMuted,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = top,
	})

	task.spawn(function()
		while self._AetherGui and self._AetherGui.Parent do
			clock.Text = os.date("%H:%M")
			task.wait(1)
		end
	end)

	local rail = Helpers.CreateFrame({
		Name = "NavRail",
		Size = UDim2.new(0, 112, 1, -118),
		Position = UDim2.fromOffset(24, 94),
		BackgroundColor3 = Theme.Secondary,
		BackgroundTransparency = 0.03,
		Parent = root,
	})
	Helpers.Corner(rail, 18)
	Helpers.Stroke(rail, Theme.BorderStrong, 1)
	rail.ZIndex = 3

	Helpers.CreateLabel({
		Name = "NavLabel",
		Size = UDim2.new(1, -20, 0, 18),
		Position = UDim2.fromOffset(10, 10),
		Text = "CHANNELS",
		Font = Theme.FontBold,
		TextSize = 9,
		TextColor3 = Theme.TextMuted,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = rail,
	})

	local tabScroll = Instance.new("ScrollingFrame")
	tabScroll.Name = "Tabs"
	tabScroll.Size = UDim2.new(1, -12, 1, -48)
	tabScroll.Position = UDim2.fromOffset(6, 38)
	tabScroll.BackgroundTransparency = 1
	tabScroll.BorderSizePixel = 0
	tabScroll.ScrollBarThickness = 2
	tabScroll.ScrollBarImageColor3 = Theme.Accent
	tabScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	tabScroll.ScrollingDirection = Enum.ScrollingDirection.Y
	tabScroll.Parent = rail

	local tabList = Helpers.CreateFrame({
		Name = "TabList",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = tabScroll,
	})
	local tabLayout = Instance.new("UIListLayout")
	tabLayout.FillDirection = Enum.FillDirection.Vertical
	tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	tabLayout.Padding = UDim.new(0, 7)
	tabLayout.Parent = tabList
	self._AetherTabList = tabList

	local stage = Helpers.CreateFrame({
		Name = "Stage",
		Size = UDim2.new(1, -370, 1, -118),
		Position = UDim2.fromOffset(152, 94),
		BackgroundColor3 = Theme.Background,
		BackgroundTransparency = 0.02,
		Parent = root,
	})
	Helpers.Corner(stage, 20)
	Helpers.Stroke(stage, Theme.BorderStrong, 1)
	stage.ZIndex = 2
	self._AetherStage = stage

	local stageHeader = Helpers.CreateFrame({
		Name = "StageHeader",
		Size = UDim2.new(1, -28, 0, 34),
		Position = UDim2.fromOffset(14, 12),
		BackgroundTransparency = 1,
		Parent = stage,
	})
	Helpers.CreateLabel({
		Name = "Hint",
		Size = UDim2.new(1, -20, 1, 0),
		Text = "SELECT A CHANNEL FROM THE LEFT RAIL",
		Font = Theme.FontBold,
		TextSize = 9,
		TextColor3 = Theme.TextMuted,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = stageHeader,
	})

	local pageHost = Helpers.CreateFrame({
		Name = "PageHost",
		Size = UDim2.new(1, -28, 1, -58),
		Position = UDim2.fromOffset(14, 48),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Parent = stage,
	})
	self._AetherPageHost = pageHost

	local side = Helpers.CreateFrame({
		Name = "StatusPane",
		Size = UDim2.new(0, 190, 1, -118),
		Position = UDim2.new(1, -24, 0, 94),
		AnchorPoint = Vector2.new(1, 0),
		BackgroundColor3 = Theme.Secondary,
		BackgroundTransparency = 0.02,
		Parent = root,
	})
	Helpers.Corner(side, 18)
	Helpers.Stroke(side, Theme.BorderStrong, 1)
	side.ZIndex = 3

	Helpers.CreateLabel({
		Name = "PaneTitle",
		Size = UDim2.new(1, -20, 0, 22),
		Position = UDim2.fromOffset(10, 12),
		Text = "SYSTEM",
		Font = Theme.FontBold,
		TextSize = 10,
		TextColor3 = Theme.TextMuted,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = side,
	})

	local function metric(name: string, value: string, y: number)
		local card = Helpers.CreateFrame({
			Name = name,
			Size = UDim2.new(1, -20, 0, 56),
			Position = UDim2.fromOffset(10, y),
			BackgroundColor3 = Theme.Background,
			BackgroundTransparency = 0.08,
			Parent = side,
		})
		Helpers.Corner(card, 10)
		Helpers.CreateLabel({
			Name = "Label",
			Size = UDim2.new(1, -16, 0, 14),
			Position = UDim2.fromOffset(8, 7),
			Text = name,
			Font = Theme.Font,
			TextSize = 9,
			TextColor3 = Theme.TextMuted,
			TextXAlignment = Enum.TextXAlignment.Center,
			Parent = card,
		})
		Helpers.CreateLabel({
			Name = "Value",
			Size = UDim2.new(1, -16, 0, 20),
			Position = UDim2.fromOffset(8, 24),
			Text = value,
			Font = Theme.FontBold,
			TextSize = 12,
			TextColor3 = Theme.Text,
			TextXAlignment = Enum.TextXAlignment.Center,
			Parent = card,
		})
	end

	metric("MODE", "KILO", 44)
	metric("STATE", "READY", 108)
	metric("PROFILE", "ACTIVE", 172)

	local closeBtn = Helpers.CreateButton({
		Name = "Close",
		Size = UDim2.fromOffset(42, 42),
		Position = UDim2.new(1, -66, 1, -66),
		Text = "×",
		Font = Theme.FontBold,
		TextSize = 21,
		TextColor3 = Theme.Text,
		BackgroundColor3 = Theme.Background,
		BackgroundTransparency = 0.05,
		Parent = root,
	})
	Helpers.Corner(closeBtn, 12)
	Helpers.Stroke(closeBtn, Theme.Accent, 1)
	closeBtn.ZIndex = 5
	closeBtn.MouseButton1Click:Connect(function()
		if w.SetVisible then
			w:SetVisible(false)
		end
	end)

	self:_syncAetherTabs()
end

function LayoutVariants:_setAetherVisible(visible: boolean)
	if self._AetherGui then
		self._AetherGui.Enabled = visible
	end
	if visible then
		self:_mountAetherPages()
		self:_syncAetherTabs()
	else
		if self._AetherPageHost and self._Window and self._Window.Pages then
			if self._Window.Pages.Parent == self._AetherPageHost then
				self:_restorePagesToWindow()
			end
		end
	end
end

function LayoutVariants:_mountAetherPages()
	local w = self._Window
	if not w or not w.Pages or not self._AetherPageHost then
		return
	end
	self:_ensurePagesHome()
	if w.Pages.Parent ~= self._AetherPageHost then
		w.Pages.Parent = self._AetherPageHost
	end
	w.Pages.Size = UDim2.fromScale(1, 1)
	w.Pages.Position = UDim2.fromScale(0, 0)
	w.Pages.Visible = true
	self:_setContentHeaderCollapsed(true)
end

function LayoutVariants:_syncAetherTabs()
	if not self._AetherTabList then
		return
	end

	for _, child in ipairs(self._AetherTabList:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	self._AetherTabs = {}

	local w = self._Window
	if not w or not w._Tabs then
		return
	end

	for i, tab in ipairs(w._Tabs) do
		local label = tabDisplayName(tab)
		local btn = Helpers.CreateButton({
			Name = "AetherTab_" .. i,
			Size = UDim2.new(1, -8, 0, 42),
			Text = string.upper(string.sub(label, 1, 1)) .. "\n" .. label,
			Font = Theme.FontBold,
			TextSize = 9,
			TextColor3 = Theme.TextMuted,
			BackgroundColor3 = Theme.Background,
			BackgroundTransparency = 0.18,
			LayoutOrder = i,
			Parent = self._AetherTabList,
		})
		Helpers.Corner(btn, 11)
		local stroke = Helpers.Stroke(btn, Theme.BorderStrong, 1)
		stroke.Transparency = 0.45

		self._AetherTabs[label] = {
			btn = btn,
			stroke = stroke,
			tab = tab,
		}

		btn.MouseButton1Click:Connect(function()
			if w._selectTab then
				w:_selectTab(tab)
			end
			self._ActiveTabName = label
			self._ShowingHome = false
			if self._AetherActiveTitle then
				self._AetherActiveTitle.Text = string.upper(label)
			end
			self:_highlightAether(label)
			self:_mountAetherPages()
		end)
	end

	local activeLabel = nil
	if w._ActiveTab then
		activeLabel = tabDisplayName(w._ActiveTab)
	elseif w._Tabs[1] then
		activeLabel = tabDisplayName(w._Tabs[1])
		if w._selectTab then
			w:_selectTab(w._Tabs[1])
		end
	end

	if activeLabel then
		self._ActiveTabName = activeLabel
		self._ShowingHome = false
		if self._AetherActiveTitle then
			self._AetherActiveTitle.Text = string.upper(activeLabel)
		end
		self:_highlightAether(activeLabel)
		self:_mountAetherPages()
	end
end

function LayoutVariants:_highlightAether(label: string)
	for name, data in pairs(self._AetherTabs or {}) do
		local on = name == label
		data.btn.BackgroundColor3 = if on then Theme.Secondary else Theme.Background
		data.btn.BackgroundTransparency = if on then 0.02 else 0.18
		data.btn.TextColor3 = if on then Theme.Text else Theme.TextMuted
		data.stroke.Transparency = if on then 0.05 else 0.45
	end
end

----------------------------------------------------------------------
-- Nova layout
----------------------------------------------------------------------
function LayoutVariants:_ensureNova()
	if self._NovaGui then
		self:_syncNovaTabs()
		return
	end

	local w = self._Window
	local parent = w._TopGuiParent or (w.Gui and w.Gui.Parent)
	if not parent then
		return
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "KiloNovaShell"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = 2147483643
	gui.Enabled = false
	gui.Parent = parent
	self._NovaGui = gui

	local root = Helpers.CreateFrame({
		Name = "Root",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Theme.Background,
		Parent = gui,
	})
	self._NovaRoot = root

	local dim = Helpers.CreateFrame({
		Name = "Vignette",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.55,
		Parent = root,
	})
	dim.ZIndex = 0

	local nav = Helpers.CreateFrame({
		Name = "Nav",
		Size = UDim2.new(1, -48, 0, 56),
		Position = UDim2.fromOffset(24, 24),
		BackgroundColor3 = Theme.Secondary,
		BackgroundTransparency = 0.1,
		Parent = root,
	})
	Helpers.Corner(nav, 20)
	Helpers.Stroke(nav, Theme.BorderStrong, 1)
	nav.ZIndex = 3

	local navList = Instance.new("Frame")
	navList.Name = "List"
	navList.Size = UDim2.new(1, -20, 1, 0)
	navList.Position = UDim2.fromOffset(10, 0)
	navList.BackgroundTransparency = 1
	navList.Parent = nav
	local navLayout = Instance.new("UIListLayout")
	navLayout.FillDirection = Enum.FillDirection.Horizontal
	navLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	navLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	navLayout.Padding = UDim.new(0, 10)
	navLayout.Parent = navList
	self._NovaTabRow = navList

	local stage = Helpers.CreateFrame({
		Name = "Stage",
		Size = UDim2.new(1, -48, 1, -104),
		Position = UDim2.fromOffset(24, 88),
		BackgroundColor3 = Theme.Background,
		BackgroundTransparency = 0.02,
		Parent = root,
	})
	Helpers.Corner(stage, 24)
	Helpers.Stroke(stage, Theme.Accent, 1)
	stage.ZIndex = 2
	self._NovaStage = stage

	local pageHost = Helpers.CreateFrame({
		Name = "PageHost",
		Size = UDim2.new(1, -28, 1, -28),
		Position = UDim2.fromOffset(14, 14),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Parent = stage,
	})
	self._NovaPageHost = pageHost

	local closeBtn = Helpers.CreateButton({
		Name = "Close",
		Size = UDim2.fromOffset(42, 42),
		Position = UDim2.new(1, -66, 1, -66),
		Text = "×",
		Font = Theme.FontBold,
		TextSize = 21,
		TextColor3 = Theme.Text,
		BackgroundColor3 = Theme.Background,
		BackgroundTransparency = 0.05,
		Parent = root,
	})
	Helpers.Corner(closeBtn, 12)
	Helpers.Stroke(closeBtn, Theme.Accent, 1)
	closeBtn.ZIndex = 5
	closeBtn.MouseButton1Click:Connect(function()
		if w.SetVisible then
			w:SetVisible(false)
		end
	end)

	self:_syncNovaTabs()
end

function LayoutVariants:_setNovaVisible(visible: boolean)
	if self._NovaGui then
		self._NovaGui.Enabled = visible
	end
	if visible then
		self:_mountNovaPages()
		self:_syncNovaTabs()
	else
		if self._NovaPageHost and self._Window and self._Window.Pages then
			if self._Window.Pages.Parent == self._NovaPageHost then
				self:_restorePagesToWindow()
			end
		end
	end
end

function LayoutVariants:_mountNovaPages()
	local w = self._Window
	if not w or not w.Pages or not self._NovaPageHost then
		return
	end
	self:_ensurePagesHome()
	if w.Pages.Parent ~= self._NovaPageHost then
		w.Pages.Parent = self._NovaPageHost
	end
	w.Pages.Size = UDim2.fromScale(1, 1)
	w.Pages.Position = UDim2.fromScale(0, 0)
	w.Pages.Visible = true
	self:_setContentHeaderCollapsed(true)
end

function LayoutVariants:_syncNovaTabs()
	if not self._NovaTabRow then
		return
	end

	for _, child in ipairs(self._NovaTabRow:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	self._NovaTabs = {}

	local w = self._Window
	if not w or not w._Tabs then
		return
	end

	for i, tab in ipairs(w._Tabs) do
		local label = tabDisplayName(tab)
		local btn = Helpers.CreateButton({
			Name = "NovaTab_" .. i,
			Size = UDim2.fromOffset(0, 34),
			AutomaticSize = Enum.AutomaticSize.X,
			Text = "  " .. label .. "  ",
			Font = Theme.FontBold,
			TextSize = 12,
			TextColor3 = Theme.TextMuted,
			BackgroundColor3 = Theme.Background,
			BackgroundTransparency = 0.18,
			LayoutOrder = i,
			Parent = self._NovaTabRow,
		})
		Helpers.Corner(btn, 12)
		local stroke = Helpers.Stroke(btn, Theme.BorderStrong, 1)
		stroke.Transparency = 0.45

		self._NovaTabs[label] = { btn = btn, stroke = stroke, tab = tab }

		btn.MouseButton1Click:Connect(function()
			if w._selectTab then
				w:_selectTab(tab)
			end
			self._ActiveTabName = label
			self._ShowingHome = false
			if self._NovaActiveTitle then
				self._NovaActiveTitle.Text = string.upper(label)
			end
			self:_highlightNova(label)
			self:_mountNovaPages()
		end)
	end

	local activeLabel = nil
	if w._ActiveTab then
		activeLabel = tabDisplayName(w._ActiveTab)
	elseif w._Tabs[1] then
		activeLabel = tabDisplayName(w._Tabs[1])
		if w._selectTab then
			w:_selectTab(w._Tabs[1])
		end
	end

	if activeLabel then
		self._ActiveTabName = activeLabel
		self._ShowingHome = false
		self:_highlightNova(activeLabel)
		self:_mountNovaPages()
	end
end

function LayoutVariants:_highlightNova(label: string)
	for name, data in pairs(self._NovaTabs or {}) do
		local on = name == label
		data.btn.BackgroundColor3 = if on then Theme.Secondary else Theme.Background
		data.btn.BackgroundTransparency = if on then 0.02 else 0.18
		data.btn.TextColor3 = if on then Theme.Text else Theme.TextMuted
		data.stroke.Transparency = if on then 0.05 else 0.45
	end
end

----------------------------------------------------------------------
-- Vortex layout
----------------------------------------------------------------------
function LayoutVariants:_ensureVortex()
	if self._VortexGui then
		self:_syncVortexTabs()
		return
	end

	local w = self._Window
	local parent = w._TopGuiParent or (w.Gui and w.Gui.Parent)
	if not parent then
		return
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "KiloVortexShell"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = 2147483642
	gui.Enabled = false
	gui.Parent = parent
	self._VortexGui = gui

	local root = Helpers.CreateFrame({
		Name = "Root",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Parent = gui,
	})
	self._VortexRoot = root

	local dim = Helpers.CreateFrame({
		Name = "Dim",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(2, 3, 7),
		BackgroundTransparency = 0.4,
		Parent = root,
	})
	dim.ZIndex = 0

	local hub = Helpers.CreateFrame({
		Name = "Hub",
		Size = UDim2.fromOffset(200, 200),
		Position = UDim2.new(0.5, -100, 0.5, -100),
		BackgroundColor3 = Theme.Background,
		BackgroundTransparency = 0.05,
		Parent = root,
	})
	Helpers.Corner(hub, 100)
	Helpers.Stroke(hub, Theme.Accent, 1)
	self._VortexHub = hub

	local stage = Helpers.CreateFrame({
		Name = "Stage",
		Size = UDim2.new(1, -80, 1, -80),
		Position = UDim2.fromOffset(40, 40),
		BackgroundColor3 = Theme.Background,
		BackgroundTransparency = 0.02,
		Parent = root,
	})
	Helpers.Corner(stage, 24)
	Helpers.Stroke(stage, Theme.BorderStrong, 1)
	stage.ZIndex = 2
	self._VortexStage = stage

	local pageHost = Helpers.CreateFrame({
		Name = "PageHost",
		Size = UDim2.new(1, -28, 1, -28),
		Position = UDim2.fromOffset(14, 14),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Parent = stage,
	})
	self._VortexPageHost = pageHost

	local closeBtn = Helpers.CreateButton({
		Name = "Close",
		Size = UDim2.fromOffset(42, 42),
		Position = UDim2.new(1, -66, 1, -66),
		Text = "×",
		Font = Theme.FontBold,
		TextSize = 21,
		TextColor3 = Theme.Text,
		BackgroundColor3 = Theme.Background,
		BackgroundTransparency = 0.05,
		Parent = root,
	})
	Helpers.Corner(closeBtn, 12)
	Helpers.Stroke(closeBtn, Theme.Accent, 1)
	closeBtn.ZIndex = 5
	closeBtn.MouseButton1Click:Connect(function()
		if w.SetVisible then
			w:SetVisible(false)
		end
	end)

	self:_syncVortexTabs()
end

function LayoutVariants:_setVortexVisible(visible: boolean)
	if self._VortexGui then
		self._VortexGui.Enabled = visible
	end
	if visible then
		self:_mountVortexPages()
		self:_syncVortexTabs()
	else
		if self._VortexPageHost and self._Window and self._Window.Pages then
			if self._Window.Pages.Parent == self._VortexPageHost then
				self:_restorePagesToWindow()
			end
		end
	end
end

function LayoutVariants:_mountVortexPages()
	local w = self._Window
	if not w or not w.Pages or not self._VortexPageHost then
		return
	end
	self:_ensurePagesHome()
	if w.Pages.Parent ~= self._VortexPageHost then
		w.Pages.Parent = self._VortexPageHost
	end
	w.Pages.Size = UDim2.fromScale(1, 1)
	w.Pages.Position = UDim2.fromScale(0, 0)
	w.Pages.Visible = true
	self:_setContentHeaderCollapsed(true)
end

function LayoutVariants:_syncVortexTabs()
	if not self._VortexHub then
		return
	end

	for _, child in ipairs(self._VortexHub:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	self._VortexTabs = {}

	local w = self._Window
	if not w or not w._Tabs then
		return
	end

	local count = #w._Tabs
	local radius = 70
	for i, tab in ipairs(w._Tabs) do
		local label = tabDisplayName(tab)
		local angle = (i - 1) * (2 * math.pi / count)
		local x = math.cos(angle) * radius
		local y = math.sin(angle) * radius
		local btn = Helpers.CreateButton({
			Name = "VortexTab_" .. i,
			Size = UDim2.fromOffset(40, 40),
			Position = UDim2.new(0.5, x - 20, 0.5, y - 20),
			Text = string.sub(label, 1, 1),
			Font = Theme.FontBold,
			TextSize = 12,
			TextColor3 = Theme.Text,
			BackgroundColor3 = Theme.Secondary,
			BackgroundTransparency = 0.1,
			LayoutOrder = i,
			Parent = self._VortexHub,
		})
		Helpers.Corner(btn, 20)
		Helpers.Stroke(btn, Theme.Accent, 1)

		self._VortexTabs[label] = { btn = btn, tab = tab }

		btn.MouseButton1Click:Connect(function()
			if w._selectTab then
				w:_selectTab(tab)
			end
			self._ActiveTabName = label
			self._ShowingHome = false
			self:_highlightVortex(label)
			self:_mountVortexPages()
		end)
	end

	local activeLabel = nil
	if w._ActiveTab then
		activeLabel = tabDisplayName(w._ActiveTab)
	elseif w._Tabs[1] then
		activeLabel = tabDisplayName(w._Tabs[1])
		if w._selectTab then
			w:_selectTab(w._Tabs[1])
		end
	end

	if activeLabel then
		self._ActiveTabName = activeLabel
		self._ShowingHome = false
		self:_highlightVortex(activeLabel)
		self:_mountVortexPages()
	end
end

function LayoutVariants:_highlightVortex(label: string)
	for name, data in pairs(self._VortexTabs or {}) do
		local on = name == label
		data.btn.BackgroundTransparency = if on then 0.02 else 0.1
		data.btn.TextColor3 = if on then Theme.Text else Theme.TextMuted
	end
end

----------------------------------------------------------------------
-- Prism layout
----------------------------------------------------------------------
function LayoutVariants:_ensurePrism()
	if self._PrismGui then
		self:_syncPrismTabs()
		return
	end

	local w = self._Window
	local parent = w._TopGuiParent or (w.Gui and w.Gui.Parent)
	if not parent then
		return
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "KiloPrismShell"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = 2147483641
	gui.Enabled = false
	gui.Parent = parent
	self._PrismGui = gui

	local root = Helpers.CreateFrame({
		Name = "Root",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Parent = gui,
	})
	self._PrismRoot = root

	local dim = Helpers.CreateFrame({
		Name = "Dim",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(4, 6, 12),
		BackgroundTransparency = 0.3,
		Parent = root,
	})
	dim.ZIndex = 0

	local stage = Helpers.CreateFrame({
		Name = "Stage",
		Size = UDim2.new(0.6, -24, 1, -48),
		Position = UDim2.fromOffset(24, 24),
		BackgroundColor3 = Theme.Background,
		BackgroundTransparency = 0.02,
		Parent = root,
	})
	Helpers.Corner(stage, 20)
	Helpers.Stroke(stage, Theme.BorderStrong, 1)
	stage.ZIndex = 2
	self._PrismStage = stage

	local pageHost = Helpers.CreateFrame({
		Name = "PageHost",
		Size = UDim2.new(1, -28, 1, -28),
		Position = UDim2.fromOffset(14, 14),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Parent = stage,
	})
	self._PrismPageHost = pageHost

	local spineRow = Helpers.CreateFrame({
		Name = "SpineRow",
		Size = UDim2.new(0.4, -24, 1, -48),
		Position = UDim2.new(0.6, 0, 0, 24),
		BackgroundTransparency = 1,
		Parent = root,
	})
	Helpers.CreateFrame({
		Name = "Divider",
		Size = UDim2.new(0, 1, 1, 0),
		Position = UDim2.fromOffset(0, 0),
		BackgroundColor3 = Theme.Border,
		BackgroundTransparency = 0.5,
		Parent = spineRow,
	}).ZIndex = 1
	self._PrismSpineRow = spineRow

	local spineList = Instance.new("Frame")
	spineList.Name = "List"
	spineList.Size = UDim2.new(1, 0, 1, 0)
	spineList.BackgroundTransparency = 1
	spineList.Parent = spineRow
	local spineLayout = Instance.new("UIListLayout")
	spineLayout.FillDirection = Enum.FillDirection.Vertical
	spineLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	spineLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	spineLayout.Padding = UDim.new(0, 10)
	spineLayout.Parent = spineList

	local closeBtn = Helpers.CreateButton({
		Name = "Close",
		Size = UDim2.fromOffset(42, 42),
		Position = UDim2.new(1, -66, 1, -66),
		Text = "×",
		Font = Theme.FontBold,
		TextSize = 21,
		TextColor3 = Theme.Text,
		BackgroundColor3 = Theme.Background,
		BackgroundTransparency = 0.05,
		Parent = root,
	})
	Helpers.Corner(closeBtn, 12)
	Helpers.Stroke(closeBtn, Theme.Accent, 1)
	closeBtn.ZIndex = 5
	closeBtn.MouseButton1Click:Connect(function()
		if w.SetVisible then
			w:SetVisible(false)
		end
	end)

	self:_syncPrismTabs()
end

function LayoutVariants:_setPrismVisible(visible: boolean)
	if self._PrismGui then
		self._PrismGui.Enabled = visible
	end
	if visible then
		self:_mountPrismPages()
		self:_syncPrismTabs()
	else
		if self._PrismPageHost and self._Window and self._Window.Pages then
			if self._Window.Pages.Parent == self._PrismPageHost then
				self:_restorePagesToWindow()
			end
		end
	end
end

function LayoutVariants:_mountPrismPages()
	local w = self._Window
	if not w or not w.Pages or not self._PrismPageHost then
		return
	end
	self:_ensurePagesHome()
	if w.Pages.Parent ~= self._PrismPageHost then
		w.Pages.Parent = self._PrismPageHost
	end
	w.Pages.Size = UDim2.fromScale(1, 1)
	w.Pages.Position = UDim2.fromScale(0, 0)
	w.Pages.Visible = true
	self:_setContentHeaderCollapsed(true)
end

function LayoutVariants:_syncPrismTabs()
	if not self._PrismSpineRow then
		return
	end

	for _, child in ipairs(self._PrismSpineRow:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	self._PrismTabs = {}

	local w = self._Window
	if not w or not w._Tabs then
		return
	end

	for i, tab in ipairs(w._Tabs) do
		local label = tabDisplayName(tab)
		local btn = Helpers.CreateButton({
			Name = "PrismTab_" .. i,
			Size = UDim2.fromOffset(44, 120),
			Text = label,
			Font = Theme.FontBold,
			TextSize = 11,
			TextColor3 = Theme.TextMuted,
			BackgroundColor3 = Theme.Background,
			BackgroundTransparency = 0.18,
			LayoutOrder = i,
			Parent = self._PrismSpineRow,
		})
		Helpers.Corner(btn, 12)
		local stroke = Helpers.Stroke(btn, Theme.BorderStrong, 1)
		stroke.Transparency = 0.45

		self._PrismTabs[label] = { btn = btn, stroke = stroke, tab = tab }

		btn.MouseButton1Click:Connect(function()
			if w._selectTab then
				w:_selectTab(tab)
			end
			self._ActiveTabName = label
			self._ShowingHome = false
			self:_highlightPrism(label)
			self:_mountPrismPages()
		end)
	end

	local activeLabel = nil
	if w._ActiveTab then
		activeLabel = tabDisplayName(w._ActiveTab)
	elseif w._Tabs[1] then
		activeLabel = tabDisplayName(w._Tabs[1])
		if w._selectTab then
			w:_selectTab(w._Tabs[1])
		end
	end

	if activeLabel then
		self._ActiveTabName = activeLabel
		self._ShowingHome = false
		self:_highlightPrism(activeLabel)
		self:_mountPrismPages()
	end
end

function LayoutVariants:_highlightPrism(label: string)
	for name, data in pairs(self._PrismTabs or {}) do
		local on = name == label
		data.btn.BackgroundColor3 = if on then Theme.Secondary else Theme.Background
		data.btn.BackgroundTransparency = if on then 0.02 else 0.18
		data.btn.TextColor3 = if on then Theme.Text else Theme.TextMuted
		data.stroke.Transparency = if on then 0.05 else 0.45
	end
end

----------------------------------------------------------------------
-- Eclipse layout
----------------------------------------------------------------------
function LayoutVariants:_ensureEclipse()
	if self._EclipseGui then
		self:_syncEclipseTabs()
		return
	end

	local w = self._Window
	local parent = w._TopGuiParent or (w.Gui and w.Gui.Parent)
	if not parent then
		return
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "KiloEclipseShell"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = 2147483640
	gui.Enabled = false
	gui.Parent = parent
	self._EclipseGui = gui

	local root = Helpers.CreateFrame({
		Name = "Root",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Theme.Background,
		Parent = gui,
	})
	self._EclipseRoot = root

	local dim = Helpers.CreateFrame({
		Name = "Dim",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.5,
		Parent = root,
	})
	dim.ZIndex = 0

	local top = Helpers.CreateFrame({
		Name = "TopCapsule",
		Size = UDim2.new(1, -48, 0, 56),
		Position = UDim2.fromOffset(24, 24),
		BackgroundColor3 = Theme.Secondary,
		BackgroundTransparency = 0.1,
		Parent = root,
	})
	Helpers.Corner(top, 28)
	Helpers.Stroke(top, Theme.BorderStrong, 1)
	top.ZIndex = 3

	local timeline = Helpers.CreateFrame({
		Name = "Timeline",
		Size = UDim2.new(1, -48, 0, 200),
		Position = UDim2.fromOffset(24, 94),
		BackgroundColor3 = Theme.Secondary,
		BackgroundTransparency = 0.05,
		Parent = root,
	})
	Helpers.Corner(timeline, 18)
	Helpers.Stroke(timeline, Theme.BorderStrong, 1)
	timeline.ZIndex = 3
	self._EclipseTimeline = timeline

	local stage = Helpers.CreateFrame({
		Name = "Stage",
		Size = UDim2.new(1, -48, 1, -314),
		Position = UDim2.fromOffset(24, 306),
		BackgroundColor3 = Theme.Background,
		BackgroundTransparency = 0.02,
		Parent = root,
	})
	Helpers.Corner(stage, 24)
	Helpers.Stroke(stage, Theme.Accent, 1)
	stage.ZIndex = 2
	self._EclipseStage = stage

	local pageHost = Helpers.CreateFrame({
		Name = "PageHost",
		Size = UDim2.new(1, -28, 1, -28),
		Position = UDim2.fromOffset(14, 14),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Parent = stage,
	})
	self._EclipsePageHost = pageHost

	local closeBtn = Helpers.CreateButton({
		Name = "Close",
		Size = UDim2.fromOffset(42, 42),
		Position = UDim2.new(1, -66, 1, -66),
		Text = "×",
		Font = Theme.FontBold,
		TextSize = 21,
		TextColor3 = Theme.Text,
		BackgroundColor3 = Theme.Background,
		BackgroundTransparency = 0.05,
		Parent = root,
	})
	Helpers.Corner(closeBtn, 12)
	Helpers.Stroke(closeBtn, Theme.Accent, 1)
	closeBtn.ZIndex = 5
	closeBtn.MouseButton1Click:Connect(function()
		if w.SetVisible then
			w:SetVisible(false)
		end
	end)

	self:_syncEclipseTabs()
end

function LayoutVariants:_setEclipseVisible(visible: boolean)
	if self._EclipseGui then
		self._EclipseGui.Enabled = visible
	end
	if visible then
		self:_mountEclipsePages()
		self:_syncEclipseTabs()
	else
		if self._EclipsePageHost and self._Window and self._Window.Pages then
			if self._Window.Pages.Parent == self._EclipsePageHost then
				self:_restorePagesToWindow()
			end
		end
	end
end

function LayoutVariants:_mountEclipsePages()
	local w = self._Window
	if not w or not w.Pages or not self._EclipsePageHost then
		return
	end
	self:_ensurePagesHome()
	if w.Pages.Parent ~= self._EclipsePageHost then
		w.Pages.Parent = self._EclipsePageHost
	end
	w.Pages.Size = UDim2.fromScale(1, 1)
	w.Pages.Position = UDim2.fromScale(0, 0)
	w.Pages.Visible = true
	self:_setContentHeaderCollapsed(true)
end

function LayoutVariants:_syncEclipseTabs()
	if not self._EclipseTimeline then
		return
	end

	for _, child in ipairs(self._EclipseTimeline:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	self._EclipseTabs = {}

	local w = self._Window
	if not w or not w._Tabs then
		return
	end

	for i, tab in ipairs(w._Tabs) do
		local label = tabDisplayName(tab)
		local btn = Helpers.CreateButton({
			Name = "EclipseTab_" .. i,
			Size = UDim2.new(1, -20, 0, 44),
			Position = UDim2.fromOffset(10, 0),
			Text = label,
			Font = Theme.FontBold,
			TextSize = 12,
			TextColor3 = Theme.TextMuted,
			BackgroundColor3 = Theme.Background,
			BackgroundTransparency = 0.18,
			LayoutOrder = i,
			Parent = self._EclipseTimeline,
		})
		Helpers.Corner(btn, 12)
		local stroke = Helpers.Stroke(btn, Theme.BorderStrong, 1)
		stroke.Transparency = 0.45

		self._EclipseTabs[label] = { btn = btn, stroke = stroke, tab = tab }

		btn.MouseButton1Click:Connect(function()
			if w._selectTab then
				w:_selectTab(tab)
			end
			self._ActiveTabName = label
			self._ShowingHome = false
			self:_highlightEclipse(label)
			self:_mountEclipsePages()
		end)
	end

	local listLayout = Instance.new("UIListLayout")
	listLayout.FillDirection = Enum.FillDirection.Vertical
	listLayout.Padding = UDim.new(0, 8)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = self._EclipseTimeline

	local activeLabel = nil
	if w._ActiveTab then
		activeLabel = tabDisplayName(w._ActiveTab)
	elseif w._Tabs[1] then
		activeLabel = tabDisplayName(w._Tabs[1])
		if w._selectTab then
			w:_selectTab(w._Tabs[1])
		end
	end

	if activeLabel then
		self._ActiveTabName = activeLabel
		self._ShowingHome = false
		self:_highlightEclipse(activeLabel)
		self:_mountEclipsePages()
	end
end

function LayoutVariants:_highlightEclipse(label: string)
	for name, data in pairs(self._EclipseTabs or {}) do
		local on = name == label
		data.btn.BackgroundColor3 = if on then Theme.Secondary else Theme.Background
		data.btn.BackgroundTransparency = if on then 0.02 else 0.18
		data.btn.TextColor3 = if on then Theme.Text else Theme.TextMuted
		data.stroke.Transparency = if on then 0.05 else 0.45
	end
end

----------------------------------------------------------------------
-- SetMode / public API
----------------------------------------------------------------------
function LayoutVariants:SetMode(mode: string)
	if self._AltGui then
		self._AltGui.Enabled = false
	end
	if self._OrbitGui then
		self._OrbitGui.Enabled = false
	end
	if self._AetherGui then
		self._AetherGui.Enabled = false
	end
	if self._NovaGui then
		self._NovaGui.Enabled = false
	end
	if self._VortexGui then
		self._VortexGui.Enabled = false
	end
	if self._PrismGui then
		self._PrismGui.Enabled = false
	end
	if self._EclipseGui then
		self._EclipseGui.Enabled = false
	end

	self._Mode = mode

	if mode == "Minecraft" then
		self:_setMinecraftVisible(true)
	elseif mode == "Orbit" then
		self:_setOrbitVisible(true)
	elseif mode == "Aether" then
		self:_setAetherVisible(true)
	elseif mode == "Nova" then
		self:_setNovaVisible(true)
	elseif mode == "Vortex" then
		self:_setVortexVisible(true)
	elseif mode == "Prism" then
		self:_setPrismVisible(true)
	elseif mode == "Eclipse" then
		self:_setEclipseVisible(true)
	elseif mode == "Classic" then
		self:_applyClassicWindow()
	else
		-- Kilo default: keep window chrome as-is
		self:_restoreClassicWindow()
	end
end

function LayoutVariants:_setMinecraftVisible(visible: boolean)
	if self._AltGui then
		self._AltGui.Enabled = visible
	end
	if visible then
		self:_mountMinecraftPages()
		self:SyncTabs()
	else
		if self._PageHost and self._Window and self._Window.Pages then
			if self._Window.Pages.Parent == self._PageHost then
				self:_restorePagesToWindow()
			end
		end
	end
end

function LayoutVariants:_mountMinecraftPages()
	local w = self._Window
	if not w or not w.Pages or not self._PageHost then
		return
	end
	self:_ensurePagesHome()
	if w.Pages.Parent ~= self._PageHost then
		w.Pages.Parent = self._PageHost
	end
	w.Pages.Size = UDim2.fromScale(1, 1)
	w.Pages.Position = UDim2.fromScale(0, 0)
	w.Pages.Visible = true
	self:_setContentHeaderCollapsed(true)
end

function LayoutVariants:GetMode(): string
	return self._Mode
end

function LayoutVariants:Destroy()
	self._Maid:DoCleaning()
	if self._AltGui then
		self._AltGui:Destroy()
	end
	if self._OrbitGui then
		self._OrbitGui:Destroy()
	end
	if self._AetherGui then
		self._AetherGui:Destroy()
	end
	if self._NovaGui then
		self._NovaGui:Destroy()
	end
	if self._VortexGui then
		self._VortexGui:Destroy()
	end
	if self._PrismGui then
		self._PrismGui:Destroy()
	end
	if self._EclipseGui then
		self._EclipseGui:Destroy()
	end
end

return LayoutVariants
