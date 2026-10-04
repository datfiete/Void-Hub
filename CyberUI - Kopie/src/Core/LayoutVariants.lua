--!strict
-- Layout variants:
--   Vaxorin  = current default shell
--   Classic  = old Vaxorin look (screenshot): NAVIGATION, no CONTROL MODULE / READY ribbon / product meta
--   Minecraft= Sirius-style home + bottom dock with real tab names + close (X)
--   Orbit    = unique vertical neon rail + floating content stage
--   Aether   = unique asymmetric command-deck layout with left nav + right status pane
--   Nova     = unique floating-capsule layout: horizontal top pill nav + centered crystal stage + cyan accents
--   Vortex   = unique radial compass layout: tabs fan-arranged around a bottom-left hub
--   Prism    = unique book-spine spectrum rail: content stage left, tall color spines right
--   Eclipse  = unique eclipse monolith: timeline command rail + corona stage + top capsule
--   Compact  = alias for Orbit

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
	-- fallback: read label text from sidebar button
	if tab.Button then
		local label = tab.Button:FindFirstChild("Label")
		if label and label:IsA("TextLabel") and label.Text ~= "" then
			return clean(label.Text)
		end
	end
	return "Tab"
end

function LayoutVariants.new(window: any, initial: string): any
	local self = setmetatable({
		_Window = window,
		_Mode = "Vaxorin",
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
		_VortexHubPos = nil,
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
	}, LayoutVariants)

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
	self:SetMode(initial or "Vaxorin")
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

	-- Collapse the V5 page header gap above sections (Columns start at Y=88 by default).
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
					-- pull sections up — remove empty header gap
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
	-- restore section top gap unless Classic chrome is active
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
	gui.Name = "VaxorinMinecraftShell"
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

	-- Top-right close (X) — always visible in Minecraft
	local closeBtn = Helpers.CreateButton({
		Name = "Close",
		Size = UDim2.fromOffset(40, 40),
		Position = UDim2.new(1, -56, 0, 16),
		Text = "×",
		Font = Theme.FontBold,
		TextSize = 22,
		TextColor3 = Color3.fromRGB(230, 230, 240),
		BackgroundColor3 = Color3.fromRGB(22, 24, 32),
		BackgroundTransparency = 0.1,
		Parent = root,
	})
	Helpers.Corner(closeBtn, 12)
	Helpers.Stroke(closeBtn, Color3.fromRGB(55, 58, 72), 1)
	closeBtn.ZIndex = 10
	self._CloseBtn = closeBtn
	closeBtn.MouseButton1Click:Connect(function()
		-- Close the whole UI (same as window close / toggle)
		if w.SetVisible then
			w:SetVisible(false)
		end
	end)

	-- HOME
	local homeScroll = Instance.new("ScrollingFrame")
	homeScroll.Name = "HomeScroll"
	homeScroll.Size = UDim2.new(1, -48, 1, -110)
	homeScroll.Position = UDim2.fromOffset(24, 20)
	homeScroll.BackgroundTransparency = 1
	homeScroll.BorderSizePixel = 0
	homeScroll.ScrollBarThickness = 4
	homeScroll.ScrollBarImageColor3 = Color3.fromRGB(100, 110, 130)
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
		Text = "What's left?",
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
	self:_buildServerCard(row1)
	self:_buildFriendsCard(row1)

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
	self:_buildProfileStrip(row2)

	-- Content (above dock)
	local contentHost = Helpers.CreateFrame({
		Name = "ContentHost",
		Size = UDim2.new(1, -48, 1, -110),
		Position = UDim2.fromOffset(24, 20),
		BackgroundColor3 = Color3.fromRGB(12, 14, 20),
		BackgroundTransparency = 0.08,
		Visible = false,
		Parent = root,
	})
	Helpers.Corner(contentHost, 16)
	Helpers.Stroke(contentHost, Color3.fromRGB(50, 54, 68), 1)
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
	Helpers.Stroke(card, Color3.fromRGB(48, 52, 66), 1)
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
		BackgroundColor3 = Color3.fromRGB(60, 200, 140),
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
			BackgroundColor3 = Color3.fromRGB(12, 28, 22),
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
			TextColor3 = Color3.fromRGB(140, 165, 150),
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
			TextColor3 = Color3.fromRGB(235, 245, 240),
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = box,
		})
	end
	self._StatPlayers = stat("Players", "Players", 1)
	self._StatMax = stat("Max", "Maximum Players", 2)
	self._StatLatency = stat("Latency", "Latency", 3)
	self._StatRegion = stat("Region", "Server Region", 4)
	self:_startStats()
end

function LayoutVariants:_buildFriendsCard(parent: Instance)
	local card = self:_card(parent, {
		Name = "FriendsCard",
		Size = UDim2.new(0.5, -6, 1, 0),
		BackgroundColor3 = Color3.fromRGB(14, 16, 22),
		LayoutOrder = 2,
	})
	Helpers.CreateLabel({
		Name = "Title",
		Size = UDim2.new(1, -24, 0, 20),
		Position = UDim2.fromOffset(14, 12),
		Text = "Friends",
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
		Text = "Find out what your friends are currently doing",
		Font = Theme.Font,
		TextSize = 11,
		TextColor3 = Color3.fromRGB(150, 155, 170),
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
			BackgroundColor3 = Color3.fromRGB(22, 24, 32),
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
			TextColor3 = Color3.fromRGB(150, 155, 170),
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
			TextColor3 = Color3.fromRGB(235, 240, 250),
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = box,
		})
	end
	self._FriendInServer = fstat("InServer", "In Server", 1, Color3.fromRGB(80, 200, 120))
	self._FriendOffline = fstat("Offline", "Offline", 2, Color3.fromRGB(120, 120, 130))
	self._FriendOnline = fstat("Online", "Online", 3, Color3.fromRGB(240, 190, 60))
	self._FriendAll = fstat("All", "All", 4, Color3.fromRGB(100, 160, 255))
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
			TextColor3 = Color3.fromRGB(245, 245, 250),
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
			TextColor3 = Color3.fromRGB(170, 175, 190),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = card,
		})
		local avatar = Instance.new("ImageLabel")
		avatar.Name = "Avatar"
		avatar.Size = UDim2.fromOffset(32, 32)
		avatar.Position = UDim2.fromOffset(10, 12)
		avatar.BackgroundColor3 = Color3.fromRGB(30, 32, 40)
		avatar.BackgroundTransparency = 0.2
		avatar.Image = string.format(
			"https://www.roblox.com/headshot-thumbnail/image?userId=%d&width=48&height=48&format=png",
			userId
		)
		avatar.Parent = card
		Helpers.Corner(avatar, 8)
	end

	strip("DisplayCard", displayName, "DisplayName", Color3.fromRGB(18, 20, 28), 1)
	strip("ExecutorCard", self._ExecutorName, self._ExecutorSub, Color3.fromRGB(48, 18, 22), 2)
	strip("DiscordCard", "Discord", "Tap to join our Discord server for updates and more", Color3.fromRGB(16, 18, 28), 3)
end

function LayoutVariants:_buildDock(root: Frame)
	local dock = Helpers.CreateFrame({
		Name = "Dock",
		Size = UDim2.fromOffset(620, 58),
		Position = UDim2.new(0.5, 0, 1, -78),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = Color3.fromRGB(14, 16, 22),
		BackgroundTransparency = 0.06,
		Parent = root,
	})
	Helpers.Corner(dock, 22)
	Helpers.Stroke(dock, Color3.fromRGB(48, 52, 64), 1)
	dock.ZIndex = 5
	self._Dock = dock

	-- Full dock uses one horizontal layout: clock | home | tabs... | close
	-- with center alignment so nothing sits too far left.
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
		TextColor3 = Color3.fromRGB(210, 215, 230),
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
		TextColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundColor3 = Color3.fromRGB(40, 44, 58),
		BackgroundTransparency = 0.2,
		LayoutOrder = 2,
		Parent = dock,
	})
	Helpers.Corner(homeBtn, 12)
	self._HomeBtn = homeBtn
	homeBtn.MouseButton1Click:Connect(function()
		self:_showHome()
	end)

	local tabScroll = Instance.new("ScrollingFrame")
	tabScroll.Name = "DockTabs"
	tabScroll.Size = UDim2.fromOffset(400, 42)
	tabScroll.BackgroundTransparency = 1
	tabScroll.BorderSizePixel = 0
	tabScroll.ScrollBarThickness = 0
	tabScroll.ScrollingDirection = Enum.ScrollingDirection.X
	tabScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	tabScroll.AutomaticCanvasSize = Enum.AutomaticSize.X
	tabScroll.ClipsDescendants = true
	tabScroll.LayoutOrder = 3
	tabScroll.Parent = dock

	local tabRow = Helpers.CreateFrame({
		Name = "Row",
		Size = UDim2.new(0, 0, 1, 0),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Parent = tabScroll,
	})
	local rowLayout = Instance.new("UIListLayout")
	rowLayout.FillDirection = Enum.FillDirection.Horizontal
	rowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	rowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	rowLayout.Padding = UDim.new(0, 6)
	rowLayout.Parent = tabRow
	self._DockTabRow = tabRow

	-- keep canvas content centered when fewer tabs than width
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
		Font = Theme.FontBold,
		TextSize = 20,
		TextColor3 = Color3.fromRGB(230, 230, 240),
		BackgroundColor3 = Color3.fromRGB(40, 28, 32),
		BackgroundTransparency = 0.25,
		LayoutOrder = 4,
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
			TextColor3 = Color3.fromRGB(200, 205, 220),
			BackgroundColor3 = Color3.fromRGB(28, 30, 40),
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
	if self._Mode == "Orbit" then
		self:_syncOrbitTabs()
	end
end

function LayoutVariants:_refreshDockHighlight()
	local active = self._ActiveTabName
	local onHome = self._ShowingHome
	if self._HomeBtn then
		self._HomeBtn.BackgroundTransparency = if onHome then 0.05 else 0.45
		self._HomeBtn.TextColor3 = if onHome then Color3.fromRGB(255, 255, 255) else Color3.fromRGB(180, 185, 200)
	end
	for name, btn in pairs(self._DockTabButtons) do
		local selected = (not onHome) and name == active
		btn.BackgroundTransparency = if selected then 0.05 else 0.35
		btn.TextColor3 = if selected then Color3.fromRGB(255, 255, 255) else Color3.fromRGB(190, 195, 210)
		btn.BackgroundColor3 = if selected then Color3.fromRGB(50, 54, 72) else Color3.fromRGB(28, 30, 40)
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

function LayoutVariants:_startStats()
	task.spawn(function()
		while self._AltGui and self._AltGui.Parent do
			local lp = Players.LocalPlayer
			if self._StatPlayers then
				self._StatPlayers.Text = tostring(#Players:GetPlayers())
			end
			if self._StatMax then
				self._StatMax.Text = tostring(Players.MaxPlayers)
			end
			if self._StatLatency then
				local ping = 0
				pcall(function()
					ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
				end)
				self._StatLatency.Text = string.format("%d ms", ping)
			end
			if self._FriendInServer and lp then
				local inServer = 0
				pcall(function()
					for _, p in ipairs(Players:GetPlayers()) do
						if p ~= lp and p:IsFriendsWith(lp.UserId) then
							inServer += 1
						end
					end
				end)
				self._FriendInServer.Text = tostring(inServer)
			end
			task.wait(2)
		end
	end)
end


----------------------------------------------------------------------
-- Orbit layout (unique): vertical neon rail + floating content stage
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
	gui.Name = "VaxorinOrbitShell"
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

	-- soft radial dim
	local dim = Helpers.CreateFrame({
		Name = "Dim",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(4, 6, 12),
		BackgroundTransparency = 0.35,
		Parent = root,
	})
	dim.ZIndex = 0

	-- Left neon rail
	local rail = Helpers.CreateFrame({
		Name = "Rail",
		Size = UDim2.fromOffset(72, 0),
		Position = UDim2.fromOffset(18, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = Color3.fromRGB(10, 12, 20),
		BackgroundTransparency = 0.08,
		Parent = root,
	})
	rail.Position = UDim2.new(0, 18, 0.5, 0)
	rail.Size = UDim2.fromOffset(72, 420)
	Helpers.Corner(rail, 24)
	local railStroke = Helpers.Stroke(rail, Color3.fromRGB(120, 80, 255), 1)
	railStroke.Transparency = 0.35
	-- accent glow line
	local glow = Helpers.CreateFrame({
		Name = "Glow",
		Size = UDim2.new(0, 3, 1, -32),
		Position = UDim2.new(1, -3, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundColor3 = Color3.fromRGB(140, 90, 255),
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

	-- Floating stage (content)
	local stage = Helpers.CreateFrame({
		Name = "Stage",
		Size = UDim2.new(1, -140, 1, -48),
		Position = UDim2.fromOffset(120, 24),
		BackgroundColor3 = Color3.fromRGB(12, 14, 22),
		BackgroundTransparency = 0.06,
		Parent = root,
	})
	Helpers.Corner(stage, 20)
	local stageStroke = Helpers.Stroke(stage, Color3.fromRGB(100, 70, 220), 1)
	stageStroke.Transparency = 0.45
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

	-- Close
	local closeBtn = Helpers.CreateButton({
		Name = "Close",
		Size = UDim2.fromOffset(40, 40),
		Position = UDim2.new(1, -56, 0, 16),
		Text = "×",
		Font = Theme.FontBold,
		TextSize = 22,
		TextColor3 = Color3.fromRGB(240, 240, 250),
		BackgroundColor3 = Color3.fromRGB(28, 18, 40),
		BackgroundTransparency = 0.1,
		Parent = root,
	})
	Helpers.Corner(closeBtn, 12)
	Helpers.Stroke(closeBtn, Color3.fromRGB(120, 80, 255), 1)
	closeBtn.ZIndex = 10
	closeBtn.MouseButton1Click:Connect(function()
		if w.SetVisible then
			w:SetVisible(false)
		end
	end)

	-- Brand pip under rail
	local brand = Helpers.CreateLabel({
		Name = "Brand",
		Size = UDim2.fromOffset(72, 20),
		Position = UDim2.new(0, 18, 0.5, 220),
		Text = "ORBIT",
		Font = Theme.FontBold,
		TextSize = 10,
		TextColor3 = Color3.fromRGB(160, 140, 255),
		Parent = root,
	})

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
		-- only restore if we were using orbit host
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
			Size = UDim2.fromOffset(48, 48),
			Text = letter,
			Font = Theme.FontBold,
			TextSize = 16,
			TextColor3 = Color3.fromRGB(210, 200, 255),
			BackgroundColor3 = Color3.fromRGB(24, 22, 40),
			BackgroundTransparency = 0.1,
			LayoutOrder = i,
			Parent = self._OrbitOrbList,
		})
		Helpers.Corner(btn, 24)
		local stroke = Helpers.Stroke(btn, Color3.fromRGB(120, 90, 255), 1)
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

	-- select active or first
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
		data.btn.BackgroundColor3 = if on then Color3.fromRGB(90, 60, 200) else Color3.fromRGB(24, 22, 40)
		data.btn.TextColor3 = if on then Color3.fromRGB(255, 255, 255) else Color3.fromRGB(210, 200, 255)
		data.stroke.Transparency = if on then 0.15 else 0.55
	end
end

----------------------------------------------------------------------
-- Aether layout (unique): asymmetric command-deck UI
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
	gui.Name = "VaxorinAetherShell"
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
		BackgroundColor3 = Color3.fromRGB(5, 7, 12),
		Parent = gui,
	})
	self._AetherRoot = root

	local backdrop = Helpers.CreateFrame({
		Name = "Backdrop",
		Size = UDim2.new(1, 0, 1, -48),
		Position = UDim2.fromOffset(0, 48),
		BackgroundColor3 = Color3.fromRGB(8, 10, 16),
		BackgroundTransparency = 0.1,
		Parent = root,
	})
	backdrop.ZIndex = 0

	local top = Helpers.CreateFrame({
		Name = "CommandHeader",
		Size = UDim2.new(1, -48, 0, 62),
		Position = UDim2.fromOffset(24, 18),
		BackgroundColor3 = Color3.fromRGB(14, 18, 28),
		BackgroundTransparency = 0.02,
		Parent = root,
	})
	Helpers.Corner(top, 18)
	Helpers.Stroke(top, Color3.fromRGB(54, 70, 96), 1)
	top.ZIndex = 3

	Helpers.CreateLabel({
		Name = "Brand",
		Size = UDim2.fromOffset(130, 22),
		Position = UDim2.fromOffset(16, 10),
		Text = "AETHER // CORE",
		Font = Theme.FontBold,
		TextSize = 13,
		TextColor3 = Color3.fromRGB(225, 232, 245),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = top,
	})

	Helpers.CreateLabel({
		Name = "Subtitle",
		Size = UDim2.fromOffset(180, 16),
		Position = UDim2.fromOffset(16, 32),
		Text = "adaptive command deck",
		Font = Theme.Font,
		TextSize = 10,
		TextColor3 = Color3.fromRGB(120, 132, 150),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = top,
	})

	self._AetherActiveTitle = Helpers.CreateLabel({
		Name = "ActiveTitle",
		Size = UDim2.new(0, 280, 0, 36),
		Position = UDim2.new(0.5, -140, 0.5, -18),
		Text = "HOME",
		Font = Theme.FontBold,
		TextSize = 14,
		TextColor3 = Color3.fromRGB(235, 240, 250),
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = top,
	})

	Helpers.CreateLabel({
		Name = "Status",
		Size = UDim2.fromOffset(120, 20),
		Position = UDim2.new(1, -178, 0.5, -10),
		Text = "● ONLINE",
		Font = Theme.FontBold,
		TextSize = 10,
		TextColor3 = Color3.fromRGB(120, 220, 170),
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = top,
	})

	local clock = Helpers.CreateLabel({
		Name = "Clock",
		Size = UDim2.fromOffset(54, 20),
		Position = UDim2.new(1, -68, 0.5, -10),
		Text = os.date("%H:%M"),
		Font = Theme.FontBold,
		TextSize = 11,
		TextColor3 = Color3.fromRGB(190, 198, 214),
		TextXAlignment = Enum.TextXAlignment.Right,
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
		BackgroundColor3 = Color3.fromRGB(12, 15, 23),
		BackgroundTransparency = 0.03,
		Parent = root,
	})
	Helpers.Corner(rail, 18)
	Helpers.Stroke(rail, Color3.fromRGB(48, 58, 76), 1)
	rail.ZIndex = 3

	Helpers.CreateLabel({
		Name = "NavLabel",
		Size = UDim2.new(1, -20, 0, 18),
		Position = UDim2.fromOffset(10, 10),
		Text = "CHANNELS",
		Font = Theme.FontBold,
		TextSize = 9,
		TextColor3 = Color3.fromRGB(105, 118, 140),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = rail,
	})

	local tabScroll = Instance.new("ScrollingFrame")
	tabScroll.Name = "Tabs"
	tabScroll.Size = UDim2.new(1, -12, 1, -48)
	tabScroll.Position = UDim2.fromOffset(6, 38)
	tabScroll.BackgroundTransparency = 1
	tabScroll.BorderSizePixel = 0
	tabScroll.ScrollBarThickness = 2
	tabScroll.ScrollBarImageColor3 = Color3.fromRGB(86, 102, 130)
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
		BackgroundColor3 = Color3.fromRGB(10, 13, 20),
		BackgroundTransparency = 0.02,
		Parent = root,
	})
	Helpers.Corner(stage, 20)
	Helpers.Stroke(stage, Color3.fromRGB(56, 68, 90), 1)
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
		TextColor3 = Color3.fromRGB(105, 118, 140),
		TextXAlignment = Enum.TextXAlignment.Left,
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
		Position = UDim2.new(1, -214, 0, 94),
		BackgroundColor3 = Color3.fromRGB(16, 17, 26),
		BackgroundTransparency = 0.02,
		Parent = root,
	})
	Helpers.Corner(side, 18)
	Helpers.Stroke(side, Color3.fromRGB(48, 58, 76), 1)
	side.ZIndex = 3

	Helpers.CreateLabel({
		Name = "PaneTitle",
		Size = UDim2.new(1, -20, 0, 22),
		Position = UDim2.fromOffset(10, 12),
		Text = "SYSTEM",
		Font = Theme.FontBold,
		TextSize = 10,
		TextColor3 = Color3.fromRGB(165, 175, 194),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = side,
	})

	local function metric(name: string, value: string, y: number)
		local card = Helpers.CreateFrame({
			Name = name,
			Size = UDim2.new(1, -20, 0, 56),
			Position = UDim2.fromOffset(10, y),
			BackgroundColor3 = Color3.fromRGB(11, 14, 21),
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
			TextColor3 = Color3.fromRGB(105, 118, 140),
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = card,
		})
		Helpers.CreateLabel({
			Name = "Value",
			Size = UDim2.new(1, -16, 0, 20),
			Position = UDim2.fromOffset(8, 24),
			Text = value,
			Font = Theme.FontBold,
			TextSize = 12,
			TextColor3 = Color3.fromRGB(230, 236, 246),
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = card,
		})
	end

	metric("MODE", "AETHER", 44)
	metric("STATE", "READY", 108)
	metric("PROFILE", "ACTIVE", 172)

	local closeBtn = Helpers.CreateButton({
		Name = "Close",
		Size = UDim2.fromOffset(42, 42),
		Position = UDim2.new(1, -66, 1, -66),
		Text = "×",
		Font = Theme.FontBold,
		TextSize = 21,
		TextColor3 = Color3.fromRGB(232, 236, 246),
		BackgroundColor3 = Color3.fromRGB(44, 24, 32),
		BackgroundTransparency = 0.05,
		Parent = root,
	})
	Helpers.Corner(closeBtn, 12)
	Helpers.Stroke(closeBtn, Color3.fromRGB(120, 64, 82), 1)
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
			TextColor3 = Color3.fromRGB(170, 180, 198),
			BackgroundColor3 = Color3.fromRGB(20, 24, 34),
			BackgroundTransparency = 0.18,
			LayoutOrder = i,
			Parent = self._AetherTabList,
		})
		Helpers.Corner(btn, 11)
		local stroke = Helpers.Stroke(btn, Color3.fromRGB(58, 72, 96), 1)
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
		data.btn.BackgroundColor3 = if on then Color3.fromRGB(46, 62, 88) else Color3.fromRGB(20, 24, 34)
		data.btn.BackgroundTransparency = if on then 0.02 else 0.18
		data.btn.TextColor3 = if on then Color3.fromRGB(245, 248, 255) else Color3.fromRGB(170, 180, 198)
		data.stroke.Transparency = if on then 0.05 else 0.45
	end
end

----------------------------------------------------------------------
-- Nova layout (unique): floating-capsule top pill nav + centered crystal stage
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
	gui.Name = "VaxorinNovaShell"
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
		BackgroundColor3 = Color3.fromRGB(4, 8, 12),
		Parent = gui,
	})
	self._NovaRoot = root

	-- soft vignette
	local dim = Helpers.CreateFrame({
		Name = "Vignette",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(0, 4, 8),
		BackgroundTransparency = 0.55,
		Parent = root,
	})
	dim.ZIndex = 0

	-- Top floating brand strip
	local brandBar = Helpers.CreateFrame({
		Name = "BrandBar",
		Size = UDim2.new(1, -80, 0, 36),
		Position = UDim2.fromOffset(40, 14),
		BackgroundColor3 = Color3.fromRGB(8, 16, 22),
		BackgroundTransparency = 0.15,
		Parent = root,
	})
	Helpers.Corner(brandBar, 18)
	Helpers.Stroke(brandBar, Color3.fromRGB(40, 90, 110), 1)
	brandBar.ZIndex = 4

	Helpers.CreateLabel({
		Name = "Brand",
		Size = UDim2.fromOffset(120, 20),
		Position = UDim2.fromOffset(16, 8),
		Text = "NOVA  ·  CAPSULE",
		Font = Theme.FontBold,
		TextSize = 11,
		TextColor3 = Color3.fromRGB(80, 210, 230),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = brandBar,
	})

	self._NovaActiveTitle = Helpers.CreateLabel({
		Name = "ActiveTitle",
		Size = UDim2.new(0, 240, 0, 20),
		Position = UDim2.new(0.5, -120, 0.5, -10),
		Text = "HOME",
		Font = Theme.FontBold,
		TextSize = 12,
		TextColor3 = Color3.fromRGB(220, 240, 250),
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = brandBar,
	})

	local clock = Helpers.CreateLabel({
		Name = "Clock",
		Size = UDim2.fromOffset(48, 20),
		Position = UDim2.new(1, -60, 0.5, -10),
		Text = os.date("%H:%M"),
		Font = Theme.FontBold,
		TextSize = 11,
		TextColor3 = Color3.fromRGB(140, 190, 200),
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = brandBar,
	})

	task.spawn(function()
		while self._NovaGui and self._NovaGui.Parent do
			clock.Text = os.date("%H:%M")
			task.wait(1)
		end
	end)

	-- Horizontal floating pill navigation (unique to Nova)
	local nav = Helpers.CreateFrame({
		Name = "PillNav",
		Size = UDim2.new(1, -80, 0, 52),
		Position = UDim2.fromOffset(40, 58),
		BackgroundColor3 = Color3.fromRGB(10, 18, 26),
		BackgroundTransparency = 0.08,
		Parent = root,
	})
	Helpers.Corner(nav, 26)
	Helpers.Stroke(nav, Color3.fromRGB(36, 80, 100), 1)
	nav.ZIndex = 4

	local navPad = Instance.new("UIPadding")
	navPad.PaddingLeft = UDim.new(0, 12)
	navPad.PaddingRight = UDim.new(0, 12)
	navPad.Parent = nav

	local navScroll = Instance.new("ScrollingFrame")
	navScroll.Name = "Scroll"
	navScroll.Size = UDim2.new(1, 0, 1, 0)
	navScroll.BackgroundTransparency = 1
	navScroll.BorderSizePixel = 0
	navScroll.ScrollBarThickness = 0
	navScroll.ScrollingDirection = Enum.ScrollingDirection.X
	navScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	navScroll.AutomaticCanvasSize = Enum.AutomaticSize.X
	navScroll.ClipsDescendants = true
	navScroll.Parent = nav

	local tabRow = Helpers.CreateFrame({
		Name = "TabRow",
		Size = UDim2.new(0, 0, 1, 0),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Parent = navScroll,
	})
	local rowLayout = Instance.new("UIListLayout")
	rowLayout.FillDirection = Enum.FillDirection.Horizontal
	rowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	rowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	rowLayout.Padding = UDim.new(0, 8)
	rowLayout.Parent = tabRow
	self._NovaTabRow = tabRow

	-- keep pills centered when few tabs
	rowLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		local width = rowLayout.AbsoluteContentSize.X
		navScroll.CanvasSize = UDim2.fromOffset(math.max(width, navScroll.AbsoluteSize.X), 0)
		if width < navScroll.AbsoluteSize.X then
			tabRow.Position = UDim2.fromOffset(math.floor((navScroll.AbsoluteSize.X - width) / 2), 0)
		else
			tabRow.Position = UDim2.fromOffset(0, 0)
		end
	end)

	-- Centered crystal stage
	local stage = Helpers.CreateFrame({
		Name = "CrystalStage",
		Size = UDim2.new(1, -80, 1, -180),
		Position = UDim2.fromOffset(40, 124),
		BackgroundColor3 = Color3.fromRGB(8, 14, 20),
		BackgroundTransparency = 0.04,
		Parent = root,
	})
	Helpers.Corner(stage, 22)
	local stageStroke = Helpers.Stroke(stage, Color3.fromRGB(50, 140, 160), 1)
	stageStroke.Transparency = 0.4
	stage.ZIndex = 2
	self._NovaStage = stage

	-- subtle top accent line on stage
	local accent = Helpers.CreateFrame({
		Name = "Accent",
		Size = UDim2.new(1, -40, 0, 2),
		Position = UDim2.fromOffset(20, 0),
		BackgroundColor3 = Color3.fromRGB(60, 200, 220),
		BackgroundTransparency = 0.35,
		Parent = stage,
	})
	Helpers.Corner(accent, 1)

	local pageHost = Helpers.CreateFrame({
		Name = "PageHost",
		Size = UDim2.new(1, -28, 1, -28),
		Position = UDim2.fromOffset(14, 14),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Parent = stage,
	})
	self._NovaPageHost = pageHost

	-- Bottom status strip
	local status = Helpers.CreateFrame({
		Name = "StatusStrip",
		Size = UDim2.new(1, -80, 0, 36),
		Position = UDim2.new(0, 40, 1, -52),
		BackgroundColor3 = Color3.fromRGB(8, 16, 22),
		BackgroundTransparency = 0.12,
		Parent = root,
	})
	Helpers.Corner(status, 18)
	Helpers.Stroke(status, Color3.fromRGB(36, 80, 100), 1)
	status.ZIndex = 4

	Helpers.CreateLabel({
		Name = "StatusLeft",
		Size = UDim2.new(0.4, 0, 1, 0),
		Position = UDim2.fromOffset(16, 0),
		Text = "●  LINKED",
		Font = Theme.FontBold,
		TextSize = 10,
		TextColor3 = Color3.fromRGB(80, 220, 180),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = status,
	})

	Helpers.CreateLabel({
		Name = "StatusMid",
		Size = UDim2.new(0.3, 0, 1, 0),
		Position = UDim2.new(0.35, 0, 0, 0),
		Text = "NOVA LAYOUT",
		Font = Theme.FontBold,
		TextSize = 10,
		TextColor3 = Color3.fromRGB(120, 170, 190),
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = status,
	})

	Helpers.CreateLabel({
		Name = "StatusRight",
		Size = UDim2.new(0.3, -16, 1, 0),
		Position = UDim2.new(0.7, 0, 0, 0),
		Text = self._ExecutorName or "EXEC",
		Font = Theme.Font,
		TextSize = 10,
		TextColor3 = Color3.fromRGB(140, 180, 200),
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = status,
	})

	-- Floating close
	local closeBtn = Helpers.CreateButton({
		Name = "Close",
		Size = UDim2.fromOffset(40, 40),
		Position = UDim2.new(1, -52, 0, 14),
		Text = "×",
		Font = Theme.FontBold,
		TextSize = 20,
		TextColor3 = Color3.fromRGB(200, 230, 240),
		BackgroundColor3 = Color3.fromRGB(20, 40, 50),
		BackgroundTransparency = 0.1,
		Parent = root,
	})
	Helpers.Corner(closeBtn, 20)
	Helpers.Stroke(closeBtn, Color3.fromRGB(50, 140, 160), 1)
	closeBtn.ZIndex = 10
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
			Name = "NovaPill_" .. i,
			Size = UDim2.fromOffset(0, 36),
			AutomaticSize = Enum.AutomaticSize.X,
			Text = "  " .. label .. "  ",
			Font = Theme.FontBold,
			TextSize = 12,
			TextColor3 = Color3.fromRGB(160, 200, 210),
			BackgroundColor3 = Color3.fromRGB(16, 28, 36),
			BackgroundTransparency = 0.2,
			LayoutOrder = i,
			Parent = self._NovaTabRow,
		})
		Helpers.Corner(btn, 18)
		local stroke = Helpers.Stroke(btn, Color3.fromRGB(40, 100, 120), 1)
		stroke.Transparency = 0.5

		self._NovaTabs[label] = {
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
		if self._NovaActiveTitle then
			self._NovaActiveTitle.Text = string.upper(activeLabel)
		end
		self:_highlightNova(activeLabel)
		self:_mountNovaPages()
	end
end

function LayoutVariants:_highlightNova(label: string)
	for name, data in pairs(self._NovaTabs or {}) do
		local on = name == label
		data.btn.BackgroundColor3 = if on then Color3.fromRGB(30, 90, 110) else Color3.fromRGB(16, 28, 36)
		data.btn.BackgroundTransparency = if on then 0.05 else 0.2
		data.btn.TextColor3 = if on then Color3.fromRGB(230, 250, 255) else Color3.fromRGB(160, 200, 210)
		data.stroke.Transparency = if on then 0.1 else 0.5
		data.stroke.Color = if on then Color3.fromRGB(60, 200, 220) else Color3.fromRGB(40, 100, 120)
	end
end

----------------------------------------------------------------------
-- Vortex layout (unique): radial compass hub with fan-arranged tabs
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
	gui.Name = "VaxorinVortexShell"
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
		BackgroundColor3 = Color3.fromRGB(3, 5, 10),
		Parent = gui,
	})
	self._VortexRoot = root

	-- deep vignette
	Helpers.CreateFrame({
		Name = "Vignette",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.45,
		Parent = root,
	}).ZIndex = 0

	-- Right-side content stage
	local stage = Helpers.CreateFrame({
		Name = "Stage",
		Size = UDim2.new(1, -290, 1, -60),
		Position = UDim2.fromOffset(260, 30),
		BackgroundColor3 = Color3.fromRGB(10, 12, 22),
		BackgroundTransparency = 0.04,
		Parent = root,
	})
	Helpers.Corner(stage, 24)
	local stageStroke = Helpers.Stroke(stage, Color3.fromRGB(110, 70, 220), 1)
	stageStroke.Transparency = 0.5
	stage.ZIndex = 2
	self._VortexStage = stage

	-- top accent line on stage
	Helpers.CreateFrame({
		Name = "Accent",
		Size = UDim2.new(1, -60, 0, 2),
		Position = UDim2.fromOffset(30, 0),
		BackgroundColor3 = Color3.fromRGB(180, 110, 255),
		BackgroundTransparency = 0.35,
		Parent = stage,
	}).ZIndex = 3

	local pageHost = Helpers.CreateFrame({
		Name = "PageHost",
		Size = UDim2.new(1, -28, 1, -28),
		Position = UDim2.fromOffset(14, 14),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Parent = stage,
	})
	self._VortexPageHost = pageHost

	-- Top-left brand
	Helpers.CreateLabel({
		Name = "Brand",
		Size = UDim2.fromOffset(240, 22),
		Position = UDim2.fromOffset(28, 30),
		Text = "VORTEX // RADIAL",
		Font = Theme.FontBold,
		TextSize = 13,
		TextColor3 = Color3.fromRGB(205, 175, 255),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = root,
	}).ZIndex = 3

	Helpers.CreateLabel({
		Name = "BrandSub",
		Size = UDim2.fromOffset(240, 14),
		Position = UDim2.fromOffset(28, 52),
		Text = "compass command",
		Font = Theme.Font,
		TextSize = 10,
		TextColor3 = Color3.fromRGB(140, 122, 190),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = root,
	}).ZIndex = 3

	self._VortexActiveLabel = Helpers.CreateLabel({
		Name = "ActiveLabel",
		Size = UDim2.fromOffset(260, 20),
		Position = UDim2.fromOffset(28, 76),
		Text = "● HOME",
		Font = Theme.FontBold,
		TextSize = 11,
		TextColor3 = Color3.fromRGB(230, 200, 255),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = root,
	})
	self._VortexActiveLabel.ZIndex = 3

	-- Clock
	local clock = Helpers.CreateLabel({
		Name = "Clock",
		Size = UDim2.fromOffset(60, 20),
		Position = UDim2.new(1, -110, 0, 34),
		Text = os.date("%H:%M"),
		Font = Theme.FontBold,
		TextSize = 11,
		TextColor3 = Color3.fromRGB(190, 175, 225),
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = root,
	})
	clock.ZIndex = 3
	task.spawn(function()
		while self._VortexGui and self._VortexGui.Parent do
			clock.Text = os.date("%H:%M")
			task.wait(1)
		end
	end)

	-- Close button (top-right)
	local closeBtn = Helpers.CreateButton({
		Name = "Close",
		Size = UDim2.fromOffset(38, 38),
		Position = UDim2.new(1, -58, 0, 24),
		Text = "×",
		Font = Theme.FontBold,
		TextSize = 20,
		TextColor3 = Color3.fromRGB(235, 220, 255),
		BackgroundColor3 = Color3.fromRGB(30, 20, 46),
		BackgroundTransparency = 0.05,
		Parent = root,
	})
	Helpers.Corner(closeBtn, 19)
	Helpers.Stroke(closeBtn, Color3.fromRGB(130, 85, 220), 1)
	closeBtn.ZIndex = 5
	closeBtn.MouseButton1Click:Connect(function()
		if w.SetVisible then
			w:SetVisible(false)
		end
	end)

	-- Radial hub (bottom-left anchor)
	local hubX, hubY = 120, 120
	self._VortexHubPos = Vector2.new(hubX, hubY)

	-- decorative outer ring
	local ring = Instance.new("Frame")
	ring.Name = "Ring"
	ring.Size = UDim2.fromOffset(190, 190)
	ring.Position = UDim2.new(0, hubX - 95, 1, -(hubY + 95))
	ring.BackgroundTransparency = 1
	ring.ZIndex = 4
	ring.Parent = root
	Helpers.Corner(ring, 95)
	local ringStroke = Helpers.Stroke(ring, Color3.fromRGB(120, 70, 200), 1)
	ringStroke.Transparency = 0.68

	-- inner dashed ring
	local ring2 = Instance.new("Frame")
	ring2.Name = "RingInner"
	ring2.Size = UDim2.fromOffset(130, 130)
	ring2.Position = UDim2.new(0, hubX - 65, 1, -(hubY + 65))
	ring2.BackgroundTransparency = 1
	ring2.ZIndex = 4
	ring2.Parent = root
	Helpers.Corner(ring2, 65)
	local ring2Stroke = Helpers.Stroke(ring2, Color3.fromRGB(90, 55, 160), 1)
	ring2Stroke.Transparency = 0.75

	-- central hub
	local hub = Helpers.CreateFrame({
		Name = "Hub",
		Size = UDim2.fromOffset(76, 76),
		Position = UDim2.new(0, hubX - 38, 1, -(hubY + 38)),
		BackgroundColor3 = Color3.fromRGB(26, 16, 44),
		BackgroundTransparency = 0.02,
		Parent = root,
	})
	Helpers.Corner(hub, 38)
	local hubStroke = Helpers.Stroke(hub, Color3.fromRGB(165, 95, 255), 1.5)
	hubStroke.Transparency = 0.15
	hub.ZIndex = 6
	self._VortexHub = hub

	local homeBtn = Helpers.CreateButton({
		Name = "HomeBtn",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "⌂",
		Font = Theme.FontBold,
		TextSize = 28,
		TextColor3 = Color3.fromRGB(242, 224, 255),
		Parent = hub,
	})
	homeBtn.ZIndex = 7
	homeBtn.MouseButton1Click:Connect(function()
		self:_showVortexHome()
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
	if not self._VortexGui or not self._VortexRoot then
		return
	end

	-- clear old
	for _, data in pairs(self._VortexTabs or {}) do
		if data.btn and data.btn.Parent then
			data.btn:Destroy()
		end
		if data.tick and data.tick.Parent then
			data.tick:Destroy()
		end
	end
	self._VortexTabs = {}

	local w = self._Window
	if not w or not w._Tabs then
		return
	end

	local n = #w._Tabs
	if n == 0 then
		return
	end

	local R = 110
	local tabSize = 48
	local hubX = self._VortexHubPos.X
	local hubY = self._VortexHubPos.Y

	-- angles spread from 85° (nearly straight up) down to 15° (right)
	local angleStart, angleEnd = 85, 15

	for i, tab in ipairs(w._Tabs) do
		local label = tabDisplayName(tab)
		local letter = string.upper(string.sub(label, 1, 1))
		local t = if n == 1 then 0.5 else (i - 1) / (n - 1)
		local angleDeg = angleStart - t * (angleStart - angleEnd)
		local angle = math.rad(angleDeg)

		local cx = hubX + math.cos(angle) * R
		local cyFromBottom = hubY + math.sin(angle) * R

		local btn = Helpers.CreateButton({
			Name = "VortexTab_" .. i,
			Size = UDim2.fromOffset(tabSize, tabSize),
			Position = UDim2.new(0, cx - tabSize / 2, 1, -(cyFromBottom + tabSize / 2)),
			Text = letter,
			Font = Theme.FontBold,
			TextSize = 17,
			TextColor3 = Color3.fromRGB(222, 205, 255),
			BackgroundColor3 = Color3.fromRGB(22, 16, 36),
			BackgroundTransparency = 0.08,
			Parent = self._VortexRoot,
		})
		Helpers.Corner(btn, tabSize / 2)
		local stroke = Helpers.Stroke(btn, Color3.fromRGB(140, 80, 240), 1)
		stroke.Transparency = 0.5
		btn.ZIndex = 6

		-- tiny radial tick line toward hub
		local tick = Helpers.CreateFrame({
			Name = "Tick",
			Size = UDim2.fromOffset(3, 10),
			Position = UDim2.new(
				0,
				cx + math.cos(angle + math.pi) * (tabSize / 2 + 6) - 1.5,
				1,
				-(cyFromBottom + math.sin(angle + math.pi) * (tabSize / 2 + 6))
			),
			BackgroundColor3 = Color3.fromRGB(150, 90, 250),
			BackgroundTransparency = 0.4,
			Parent = self._VortexRoot,
		})
		Helpers.Corner(tick, 1)
		tick.ZIndex = 5

		self._VortexTabs[label] = {
			btn = btn,
			stroke = stroke,
			tick = tick,
			tab = tab,
		}

		btn.MouseButton1Click:Connect(function()
			if w._selectTab then
				w:_selectTab(tab)
			end
			self:_highlightVortex(label)
			self:_mountVortexPages()
			if self._VortexActiveLabel then
				self._VortexActiveLabel.Text = "● " .. string.upper(label)
			end
		end)
	end

	-- pick active or first
	local activeLabel: string? = nil
	if w._ActiveTab then
		activeLabel = tabDisplayName(w._ActiveTab)
	elseif w._Tabs[1] then
		activeLabel = tabDisplayName(w._Tabs[1])
		if w._selectTab then
			w:_selectTab(w._Tabs[1])
		end
	end

	if activeLabel then
		self:_highlightVortex(activeLabel)
		self:_mountVortexPages()
		if self._VortexActiveLabel then
			self._VortexActiveLabel.Text = "● " .. string.upper(activeLabel)
		end
	end
end

function LayoutVariants:_highlightVortex(label: string)
	for name, data in pairs(self._VortexTabs or {}) do
		local on = name == label
		data.btn.BackgroundColor3 = if on then Color3.fromRGB(115, 60, 220) else Color3.fromRGB(22, 16, 36)
		data.btn.BackgroundTransparency = if on then 0 else 0.08
		data.btn.TextColor3 = if on then Color3.fromRGB(255, 255, 255) else Color3.fromRGB(222, 205, 255)
		data.stroke.Transparency = if on then 0.02 else 0.5
		data.stroke.Color = if on then Color3.fromRGB(230, 160, 255) else Color3.fromRGB(140, 80, 240)
		if data.tick then
			data.tick.BackgroundColor3 = if on then Color3.fromRGB(230, 160, 255) else Color3.fromRGB(150, 90, 250)
			data.tick.BackgroundTransparency = if on then 0.05 else 0.4
		end
	end
end

function LayoutVariants:_showVortexHome()
	local w = self._Window
	if w and w._Tabs and w._Tabs[1] then
		local label = tabDisplayName(w._Tabs[1])
		if w._selectTab then
			w:_selectTab(w._Tabs[1])
		end
		self:_highlightVortex(label)
		self:_mountVortexPages()
		if self._VortexActiveLabel then
			self._VortexActiveLabel.Text = "● " .. string.upper(label)
		end
	end
end

----------------------------------------------------------------------
-- Prism layout (unique): book-spine spectrum rail + left content stage
----------------------------------------------------------------------
local PRISM_HUES = { 0.0, 0.09, 0.16, 0.38, 0.55, 0.7, 0.82, 0.95 }

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
	gui.Name = "VaxorinPrismShell"
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
		BackgroundColor3 = Color3.fromRGB(6, 5, 12),
		Parent = gui,
	})
	self._PrismRoot = root

	-- spectral diagonal wash (unique background: rotated color bands)
	for i = 1, 6 do
		local band = Helpers.CreateFrame({
			Name = "Band" .. i,
			Size = UDim2.new(1, 160, 0, 110),
			Position = UDim2.new(0, -80, 0, 120 * (i - 1) - 60),
			Rotation = -8,
			BackgroundColor3 = Color3.fromHSV((i - 1) / 6, 0.5, 0.15),
			BackgroundTransparency = 0.3,
			Parent = root,
		})
		band.ZIndex = 0
	end

	-- top header strip
	local header = Helpers.CreateFrame({
		Name = "Header",
		Size = UDim2.new(1, -110, 0, 44),
		Position = UDim2.fromOffset(30, 18),
		BackgroundColor3 = Color3.fromRGB(12, 10, 22),
		BackgroundTransparency = 0.08,
		Parent = root,
	})
	Helpers.Corner(header, 14)
	local headerStroke = Helpers.Stroke(header, Color3.fromHSV(0.75, 0.45, 0.85), 1)
	headerStroke.Transparency = 0.6

	Helpers.CreateLabel({
		Name = "Brand",
		Size = UDim2.fromOffset(170, 20),
		Position = UDim2.fromOffset(14, 5),
		Text = "PRISM // SPECTRUM",
		Font = Theme.FontBold,
		TextSize = 13,
		TextColor3 = Color3.fromRGB(235, 225, 250),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = header,
	})

	Helpers.CreateLabel({
		Name = "Sub",
		Size = UDim2.fromOffset(170, 14),
		Position = UDim2.fromOffset(14, 26),
		Text = "book-spine navigation",
		Font = Theme.Font,
		TextSize = 10,
		TextColor3 = Color3.fromRGB(150, 140, 175),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = header,
	})

	self._PrismActiveLabel = Helpers.CreateLabel({
		Name = "Active",
		Size = UDim2.new(0, 320, 0, 22),
		Position = UDim2.new(0.5, -160, 0.5, -11),
		Text = "● HOME",
		Font = Theme.FontBold,
		TextSize = 13,
		TextColor3 = Color3.fromRGB(245, 240, 255),
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = header,
	})

	local clock = Helpers.CreateLabel({
		Name = "Clock",
		Size = UDim2.fromOffset(56, 20),
		Position = UDim2.new(1, -70, 0.5, -10),
		Text = os.date("%H:%M"),
		Font = Theme.FontBold,
		TextSize = 11,
		TextColor3 = Color3.fromRGB(200, 190, 225),
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = header,
	})

	task.spawn(function()
		while self._PrismGui and self._PrismGui.Parent do
			clock.Text = os.date("%H:%M")
			task.wait(1)
		end
	end)

	-- LEFT content stage (unique: stage on the left, spines on the right)
	local stage = Helpers.CreateFrame({
		Name = "Stage",
		Size = UDim2.new(1, -350, 1, -120),
		Position = UDim2.fromOffset(30, 90),
		BackgroundColor3 = Color3.fromRGB(11, 10, 20),
		BackgroundTransparency = 0.04,
		Parent = root,
	})
	Helpers.Corner(stage, 18)
	local stageStroke = Helpers.Stroke(stage, Color3.fromRGB(120, 100, 180), 1)
	stageStroke.Transparency = 0.55
	stage.ZIndex = 2
	self._PrismStage = stage

	local pageHost = Helpers.CreateFrame({
		Name = "PageHost",
		Size = UDim2.new(1, -24, 1, -24),
		Position = UDim2.fromOffset(12, 12),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Parent = stage,
	})
	self._PrismPageHost = pageHost

	-- RIGHT book-spine rail
	local rail = Helpers.CreateFrame({
		Name = "SpineRail",
		Size = UDim2.new(0, 280, 1, -120),
		Position = UDim2.new(1, -310, 0, 90),
		BackgroundTransparency = 1,
		Parent = root,
	})
	rail.ZIndex = 3

	local railScroll = Instance.new("ScrollingFrame")
	railScroll.Name = "Scroll"
	railScroll.Size = UDim2.fromScale(1, 1)
	railScroll.BackgroundTransparency = 1
	railScroll.BorderSizePixel = 0
	railScroll.ScrollBarThickness = 0
	railScroll.ScrollingDirection = Enum.ScrollingDirection.X
	railScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	railScroll.AutomaticCanvasSize = Enum.AutomaticSize.X
	railScroll.ClipsDescendants = true
	railScroll.Parent = rail

	local spineRow = Helpers.CreateFrame({
		Name = "Spines",
		Size = UDim2.new(0, 0, 1, 0),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Parent = railScroll,
	})
	local spineLayout = Instance.new("UIListLayout")
	spineLayout.FillDirection = Enum.FillDirection.Horizontal
	spineLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	spineLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	spineLayout.Padding = UDim.new(0, 8)
	spineLayout.Parent = spineRow
	self._PrismSpineRow = spineRow

	-- keep spines centered when they fit without scrolling
	spineLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		local width = spineLayout.AbsoluteContentSize.X
		railScroll.CanvasSize = UDim2.fromOffset(math.max(width, railScroll.AbsoluteSize.X), 0)
		if width < railScroll.AbsoluteSize.X then
			spineRow.Position = UDim2.fromOffset(math.floor((railScroll.AbsoluteSize.X - width) / 2), 0)
		else
			spineRow.Position = UDim2.fromOffset(0, 0)
		end
	end)

	-- close (top-right, floats over the spectral bands)
	local closeBtn = Helpers.CreateButton({
		Name = "Close",
		Size = UDim2.fromOffset(38, 38),
		Position = UDim2.new(1, -52, 0, 20),
		Text = "×",
		Font = Theme.FontBold,
		TextSize = 20,
		TextColor3 = Color3.fromRGB(240, 232, 250),
		BackgroundColor3 = Color3.fromRGB(30, 22, 44),
		BackgroundTransparency = 0.06,
		Parent = root,
	})
	Helpers.Corner(closeBtn, 12)
	Helpers.Stroke(closeBtn, Color3.fromRGB(150, 110, 220), 1)
	closeBtn.ZIndex = 10
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
		if child:IsA("Frame") or child:IsA("GuiButton") then
			child:Destroy()
		end
	end
	self._PrismTabs = {}

	local w = self._Window
	if not w or not w._Tabs then
		return
	end

	local SPINE_H = 300

	for i, tab in ipairs(w._Tabs) do
		local label = tabDisplayName(tab)
		local hue = PRISM_HUES[((i - 1) % #PRISM_HUES) + 1]
		local accent = Color3.fromHSV(hue, 0.75, 1)

		-- tall book-spine card
		local spine = Helpers.CreateFrame({
			Name = "Spine_" .. i,
			Size = UDim2.fromOffset(52, SPINE_H),
			BackgroundColor3 = Color3.fromRGB(16, 14, 26),
			BackgroundTransparency = 0.05,
			LayoutOrder = i,
			Parent = self._PrismSpineRow,
		})
		Helpers.Corner(spine, 12)
		local stroke = Helpers.Stroke(spine, accent, 1)
		stroke.Transparency = 0.5
		spine.ZIndex = 4

		-- spectral edge bar
		local edge = Helpers.CreateFrame({
			Name = "Edge",
			Size = UDim2.new(0, 4, 1, -16),
			Position = UDim2.fromOffset(6, 8),
			BackgroundColor3 = accent,
			BackgroundTransparency = 0.15,
			Parent = spine,
		})
		Helpers.Corner(edge, 2)

		-- rotated vertical title (reads bottom-to-top like a book spine)
		local vname = Helpers.CreateLabel({
			Name = "VName",
			Size = UDim2.fromOffset(SPINE_H - 70, 22),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Rotation = 90,
			Text = string.upper(label),
			Font = Theme.FontBold,
			TextSize = 13,
			TextColor3 = Color3.fromRGB(225, 218, 240),
			TextXAlignment = Enum.TextXAlignment.Center,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = spine,
		})

		Helpers.CreateLabel({
			Name = "Index",
			Size = UDim2.fromOffset(52, 20),
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 1, -28),
			Text = string.format("%02d", i),
			Font = Theme.FontBold,
			TextSize = 10,
			TextColor3 = accent,
			TextXAlignment = Enum.TextXAlignment.Center,
			Parent = spine,
		})

		local btn = Helpers.CreateButton({
			Name = "Hit",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = "",
			Parent = spine,
		})
		btn.ZIndex = 6

		self._PrismTabs[label] = {
			spine = spine,
			stroke = stroke,
			edge = edge,
			vname = vname,
			accent = accent,
			height = SPINE_H,
			tab = tab,
		}

		btn.MouseButton1Click:Connect(function()
			if w._selectTab then
				w:_selectTab(tab)
			end
			self._ActiveTabName = label
			self._ShowingHome = false
			if self._PrismActiveLabel then
				self._PrismActiveLabel.Text = "● " .. string.upper(label)
			end
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
		if self._PrismActiveLabel then
			self._PrismActiveLabel.Text = "● " .. string.upper(activeLabel)
		end
		self:_highlightPrism(activeLabel)
		self:_mountPrismPages()
	end
end

function LayoutVariants:_highlightPrism(label: string)
	local TweenService = game:GetService("TweenService")
	for name, data in pairs(self._PrismTabs or {}) do
		if data.spine and data.spine.Parent then
			local on = name == label
			-- active spine slides open like a book pulled off the shelf
			TweenService:Create(
				data.spine,
				TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{
					Size = UDim2.fromOffset(if on then 84 else 52, data.height),
					BackgroundColor3 = if on then Color3.fromRGB(34, 28, 52) else Color3.fromRGB(16, 14, 26),
				}
			):Play()
			data.stroke.Transparency = if on then 0.05 else 0.5
			data.edge.BackgroundTransparency = if on then 0 else 0.15
			data.vname.TextColor3 = if on then Color3.fromRGB(255, 255, 255) else Color3.fromRGB(225, 218, 240)
		end
	end
end

----------------------------------------------------------------------
-- Public API
----------------------------------------------------------------------

----------------------------------------------------------------------
-- Eclipse layout (unique): monolith timeline + corona stage + top capsule
----------------------------------------------------------------------
function LayoutVariants:_ensureEclipse()
        if self._EclipseGui then
                self:_syncEclipseTabs()
                return
        end
        local w = self._Window
        local parent = w._TopGuiParent or (w.Gui and w.Gui.Parent)
        if not parent then return end

        local gui = Instance.new("ScreenGui")
        gui.Name = "VaxorinEclipseShell"
        gui.ResetOnSpawn = false
        gui.IgnoreGuiInset = true
        gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        gui.DisplayOrder = 2147483640
        gui.Enabled = false
        gui.Parent = parent
        self._EclipseGui = gui

        local root = Helpers.CreateFrame({
                Name = "Root",
                Size = UDim2.fromScale(1,1),
                BackgroundColor3 = Color3.fromRGB(7, 7, 11),
                Parent = gui,
        })
        self._EclipseRoot = root

        -- vignette + subtle aurora
        local vign = Helpers.CreateFrame({
                Name = "Vignette",
                Size = UDim2.fromScale(1,1),
                BackgroundColor3 = Color3.fromRGB(0,0,0),
                BackgroundTransparency = 0.42,
                Parent = root,
        })
        vign.ZIndex = 0

        local auroraTop = Helpers.CreateFrame({
                Name = "AuroraTop",
                Size = UDim2.new(1, 0, 0, 220),
                Position = UDim2.fromOffset(0, -40),
                Rotation = -3,
                BackgroundColor3 = Color3.fromRGB(255, 180, 80),
                BackgroundTransparency = 0.92,
                Parent = root,
        })
        auroraTop.ZIndex = 0
        local grad1 = Instance.new("UIGradient")
        grad1.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 220, 120)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 120, 60)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(140, 60, 255)),
        })
        grad1.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.6),
                NumberSequenceKeypoint.new(1, 1),
        })
        grad1.Rotation = 90
        grad1.Parent = auroraTop

        -- Top capsule nav (centered)
        local topCapsule = Helpers.CreateFrame({
                Name = "TopCapsule",
                Size = UDim2.new(0, 720, 0, 48),
                Position = UDim2.new(0.5, -360, 0, 18),
                BackgroundColor3 = Color3.fromRGB(18, 16, 24),
                BackgroundTransparency = 0.06,
                Parent = root,
        })
        Helpers.Corner(topCapsule, 24)
        local capStroke = Helpers.Stroke(topCapsule, Color3.fromRGB(255, 200, 100), 1)
        capStroke.Transparency = 0.55
        topCapsule.ZIndex = 5

        Helpers.CreateLabel({
                Name = "Brand",
                Size = UDim2.fromOffset(220, 20),
                Position = UDim2.fromOffset(18, 5),
                Text = "ECLIPSE // MONOLITH",
                Font = Theme.FontBold,
                TextSize = 11,
                TextColor3 = Color3.fromRGB(255, 228, 180),
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = topCapsule,
        })

        self._EclipseActiveLabel = Helpers.CreateLabel({
                Name = "Active",
                Size = UDim2.new(1, -300, 0, 18),
                Position = UDim2.fromOffset(18, 25),
                Text = "● HOME",
                Font = Theme.FontBold,
                TextSize = 10,
                TextColor3 = Color3.fromRGB(255, 200, 130),
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = topCapsule,
        })

        local clock = Helpers.CreateLabel({
                Name = "Clock",
                Size = UDim2.fromOffset(72, 20),
                Position = UDim2.new(1, -126, 0, 14),
                Text = os.date("%H:%M"),
                Font = Theme.FontBold,
                TextSize = 12,
                TextColor3 = Color3.fromRGB(230, 210, 180),
                TextXAlignment = Enum.TextXAlignment.Right,
                Parent = topCapsule,
        })
        self._EclipseClock = clock
        task.spawn(function()
                while self._EclipseGui and self._EclipseGui.Parent do
                        clock.Text = os.date("%H:%M")
                        task.wait(1)
                end
        end)

        local closeBtn = Helpers.CreateButton({
                Name = "Close",
                Size = UDim2.fromOffset(34, 34),
                Position = UDim2.new(1, -40, 0.5, -17),
                Text = "×",
                Font = Theme.FontBold,
                TextSize = 20,
                TextColor3 = Color3.fromRGB(255, 235, 200),
                BackgroundColor3 = Color3.fromRGB(40, 28, 20),
                BackgroundTransparency = 0.15,
                Parent = topCapsule,
        })
        Helpers.Corner(closeBtn, 18)
        Helpers.Stroke(closeBtn, Color3.fromRGB(255, 180, 80), 1)
        closeBtn.ZIndex = 6
        closeBtn.MouseButton1Click:Connect(function()
                if w.SetVisible then w:SetVisible(false) end
        end)

        -- Left timeline rail (command rail)
        local timelineWrap = Helpers.CreateFrame({
                Name = "TimelineWrap",
                Size = UDim2.new(0, 220, 1, -96),
                Position = UDim2.fromOffset(24, 84),
                BackgroundColor3 = Color3.fromRGB(13, 12, 18),
                BackgroundTransparency = 0.06,
                Parent = root,
        })
        Helpers.Corner(timelineWrap, 18)
        local _st2 = Helpers.Stroke(timelineWrap, Color3.fromRGB(70, 58, 42), 1)
        _st2.Transparency = 0.5
        timelineWrap.ZIndex = 3

        -- vertical line
        local line = Helpers.CreateFrame({
                Name = "Line",
                Size = UDim2.new(0, 2, 1, -40),
                Position = UDim2.fromOffset(20, 20),
                BackgroundColor3 = Color3.fromRGB(90, 72, 48),
                BackgroundTransparency = 0.35,
                Parent = timelineWrap,
        })
        Helpers.Corner(line, 1)

        local tlScroll = Instance.new("ScrollingFrame")
        tlScroll.Name = "TLScroll"
        tlScroll.Size = UDim2.new(1, -12, 1, -12)
        tlScroll.Position = UDim2.fromOffset(6, 6)
        tlScroll.BackgroundTransparency = 1
        tlScroll.BorderSizePixel = 0
        tlScroll.ScrollBarThickness = 0
        tlScroll.CanvasSize = UDim2.new(0,0,0,0)
        tlScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        tlScroll.Parent = timelineWrap

        local tlList = Helpers.CreateFrame({
                Name = "TLList",
                Size = UDim2.new(1, -8, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Parent = tlScroll,
        })
        local tlLayout = Instance.new("UIListLayout")
        tlLayout.Padding = UDim.new(0, 10)
        tlLayout.SortOrder = Enum.SortOrder.LayoutOrder
        tlLayout.Parent = tlList
        self._EclipseTimeline = tlList

        
        -- Center corona stage (content) - ENHANCED
        local stage = Helpers.CreateFrame({
                Name = "Stage",
                Size = UDim2.new(1, -284, 1, -96),
                Position = UDim2.new(0, 260, 0, 84),
                BackgroundColor3 = Color3.fromRGB(14, 13, 20),
                BackgroundTransparency = 0.03,
                Parent = root,
        })
        Helpers.Corner(stage, 22)
        -- double stroke for corona effect - OUTER (animated)
        local outerStroke = Helpers.Stroke(stage, Color3.fromRGB(255, 160, 60), 2)
        outerStroke.Transparency = 0.45
        -- inner corona
        local innerGlow = Helpers.CreateFrame({
                Name = "InnerGlow",
                Size = UDim2.new(1, 8, 1, 8),
                Position = UDim2.fromOffset(-4, -4),
                BackgroundTransparency = 1,
                Parent = stage,
        })
        Helpers.Corner(innerGlow, 24)
        local innerStroke = Helpers.Stroke(innerGlow, Color3.fromRGB(255, 220, 140), 1)
        innerStroke.Transparency = 0.75
        -- animated pulse for corona (makes it unique for video)
        task.spawn(function()
                local ts = game:GetService("TweenService")
                while self._EclipseGui and self._EclipseGui.Parent do
                        local t1 = ts:Create(outerStroke, TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 0.15})
                        local t2 = ts:Create(innerStroke, TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 0.45})
                        t1:Play() t2:Play() t1.Completed:Wait()
                        local t3 = ts:Create(outerStroke, TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 0.55})
                        local t4 = ts:Create(innerStroke, TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 0.85})
                        t3:Play() t4:Play() t3.Completed:Wait()
                end
        end)
        stage.ZIndex = 2
        self._EclipseStage = stage


        local stageHeader = Helpers.CreateFrame({
                Name = "StageHeader",
                Size = UDim2.new(1, -24, 0, 2),
                Position = UDim2.fromOffset(12, 10),
                BackgroundColor3 = Color3.fromRGB(255, 185, 90),
                BackgroundTransparency = 0.4,
                Parent = stage,
        })
        Helpers.Corner(stageHeader, 1)

        local pageHost = Helpers.CreateFrame({
                Name = "PageHost",
                Size = UDim2.new(1, -28, 1, -40),
                Position = UDim2.fromOffset(14, 30),
                BackgroundTransparency = 1,
                ClipsDescendants = true,
                Parent = stage,
        })
        self._EclipsePageHost = pageHost

        -- bottom status (executor + linked)
        local status = Helpers.CreateFrame({
                Name = "Status",
                Size = UDim2.new(0, 220, 0, 28),
                Position = UDim2.new(0, 24, 1, -36),
                BackgroundColor3 = Color3.fromRGB(18, 16, 12),
                BackgroundTransparency = 0.2,
                Parent = root,
        })
        Helpers.Corner(status, 14)
        local _st1 = Helpers.Stroke(status, Color3.fromRGB(90, 72, 48), 1)
        _st1.Transparency = 0.6
        Helpers.CreateLabel({
                Name = "L",
                Size = UDim2.new(0.5, -8, 1, 0),
                Position = UDim2.fromOffset(12, 0),
                Text = "● LINKED",
                Font = Theme.FontBold,
                TextSize = 9,
                TextColor3 = Color3.fromRGB(120, 220, 140),
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = status,
        })
        Helpers.CreateLabel({
                Name = "R",
                Size = UDim2.new(0.5, -8, 1, 0),
                Position = UDim2.new(0.5, 0, 0, 0),
                Text = self._ExecutorName or "EXEC",
                Font = Theme.Font,
                TextSize = 9,
                TextColor3 = Color3.fromRGB(180, 160, 130),
                TextXAlignment = Enum.TextXAlignment.Right,
                Parent = status,
        })

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
        if not w or not w.Pages or not self._EclipsePageHost then return end
        self:_ensurePagesHome()
        if w.Pages.Parent ~= self._EclipsePageHost then
                w.Pages.Parent = self._EclipsePageHost
        end
        w.Pages.Size = UDim2.fromScale(1,1)
        w.Pages.Position = UDim2.fromScale(0,0)
        w.Pages.Visible = true
        self:_setContentHeaderCollapsed(true)
end

function LayoutVariants:_syncEclipseTabs()
        if not self._EclipseTimeline then return end
        for _, child in ipairs(self._EclipseTimeline:GetChildren()) do
                if child:IsA("Frame") or child:IsA("TextButton") then child:Destroy() end
        end
        self._EclipseTabs = {}
        local w = self._Window
        if not w or not w._Tabs then return end

        for i, tab in ipairs(w._Tabs) do
                local label = tabDisplayName(tab)

                local row = Helpers.CreateFrame({
                        Name = "Row_"..i,
                        Size = UDim2.new(1, 0, 0, 46),
                        Position = UDim2.fromOffset(0, 0),
                        BackgroundColor3 = Color3.fromRGB(18, 16, 22),
                        BackgroundTransparency = 0.35,
                        LayoutOrder = i,
                        Parent = self._EclipseTimeline,
                })
                Helpers.Corner(row, 12)
                local rowStroke = Helpers.Stroke(row, Color3.fromRGB(60, 52, 38), 1)
                rowStroke.Transparency = 0.6

                -- dot on timeline
                local dot = Helpers.CreateFrame({
                        Name = "Dot",
                        Size = UDim2.fromOffset(12, 12),
                        Position = UDim2.fromOffset(14, 17),
                        BackgroundColor3 = Color3.fromRGB(80, 70, 54),
                        Parent = row,
                })
                Helpers.Corner(dot, 6)
                local dotStroke = Helpers.Stroke(dot, Color3.fromRGB(120, 100, 70), 1)
                dotStroke.Transparency = 0.5

                Helpers.CreateLabel({
                        Name = "Idx",
                        Size = UDim2.fromOffset(28, 16),
                        Position = UDim2.fromOffset(34, 4),
                        Text = string.format("%02d", i),
                        Font = Theme.FontBold,
                        TextSize = 9,
                        TextColor3 = Color3.fromRGB(140, 125, 95),
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Parent = row,
                })

                local title = Helpers.CreateLabel({
                        Name = "Title",
                        Size = UDim2.new(1, -58, 0, 16),
                        Position = UDim2.fromOffset(34, 20),
                        Text = string.upper(label),
                        Font = Theme.FontBold,
                        TextSize = 11,
                        TextColor3 = Color3.fromRGB(225, 215, 190),
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextTruncate = Enum.TextTruncate.AtEnd,
                        Parent = row,
                })

                local hit = Helpers.CreateButton({
                        Name = "Hit",
                        Size = UDim2.fromScale(1,1),
                        BackgroundTransparency = 1,
                        Text = "",
                        Parent = row,
                })
                hit.ZIndex = 5

                self._EclipseTabs[label] = { row=row, stroke=rowStroke, dot=dot, dotStroke=dotStroke, title=title, tab=tab }

                hit.MouseButton1Click:Connect(function()
                        if w._selectTab then w:_selectTab(tab) end
                        self._ActiveTabName = label
                        self._ShowingHome = false
                        if self._EclipseActiveLabel then self._EclipseActiveLabel.Text = "● "..string.upper(label) end
                        self:_highlightEclipse(label)
                        self:_mountEclipsePages()
                end)
        end

        local activeLabel = nil
        if w._ActiveTab then activeLabel = tabDisplayName(w._ActiveTab)
        elseif w._Tabs[1] then activeLabel = tabDisplayName(w._Tabs[1]) end
        if activeLabel then
                self._ActiveTabName = activeLabel
                self._ShowingHome = false
                if self._EclipseActiveLabel then self._EclipseActiveLabel.Text = "● "..string.upper(activeLabel) end
                self:_highlightEclipse(activeLabel)
                self:_mountEclipsePages()
        end
end

function LayoutVariants:_highlightEclipse(label: string)
        for name, data in pairs(self._EclipseTabs or {}) do
                local on = name == label
                data.row.BackgroundColor3 = if on then Color3.fromRGB(42, 32, 18) else Color3.fromRGB(18, 16, 22)
                data.row.BackgroundTransparency = if on then 0.08 else 0.35
                data.stroke.Color = if on then Color3.fromRGB(255, 185, 90) else Color3.fromRGB(60, 52, 38)
                data.stroke.Transparency = if on then 0.15 else 0.6
                data.dot.BackgroundColor3 = if on then Color3.fromRGB(255, 195, 90) else Color3.fromRGB(80, 70, 54)
                data.dotStroke.Color = if on then Color3.fromRGB(255, 220, 140) else Color3.fromRGB(120, 100, 70)
                data.title.TextColor3 = if on then Color3.fromRGB(255, 240, 210) else Color3.fromRGB(225, 215, 190)
        end
end


function LayoutVariants:SetMode(mode: string)
	mode = ({
		Vaxorin = "Vaxorin",
		Classic = "Classic",
		Minecraft = "Minecraft",
		Orbit = "Orbit",
		Aether = "Aether",
		Nova = "Nova",
		Vortex = "Vortex",
		Prism = "Prism",
		Eclipse = "Eclipse",
		Compact = "Orbit",
	})[mode] or "Vaxorin"
	local prev = self._Mode
	self._Mode = mode
	local w = self._Window

	if (prev == "Minecraft" or prev == "Orbit" or prev == "Aether" or prev == "Nova" or prev == "Vortex" or prev == "Prism" or prev == "Eclipse")
		and mode ~= "Minecraft" and mode ~= "Orbit" and mode ~= "Aether" and mode ~= "Nova" and mode ~= "Vortex" and mode ~= "Prism" and mode ~= "Eclipse" then
		self:_restorePagesToWindow()
		if self._AltGui then
			self._AltGui.Enabled = false
		end
		self:_setOrbitVisible(false)
		self:_setAetherVisible(false)
		self:_setNovaVisible(false)
		self:_setVortexVisible(false)
		self:_setPrismVisible(false)
		self:_setEclipseVisible(false)
	end

	if mode == "Vaxorin" then
		self:_setEclipseVisible(false)
		self:_setAetherVisible(false)
		self:_setNovaVisible(false)
		self:_setVortexVisible(false)
		self:_setPrismVisible(false)
		if self._AltGui then
			self._AltGui.Enabled = false
		end
		self:_restorePagesToWindow()
		self:_restoreClassicWindow()
		if w.Main then
			w.Main.Visible = w._StartupComplete and w._Visible
		end
		if w.TopBar then
			w.TopBar.Visible = true
		end
		if w.Sidebar then
			w.Sidebar.Visible = true
		end
		if w.Pages then
			w.Pages.Visible = true
		end
		return
	end

	if mode == "Classic" then
		self:_setEclipseVisible(false)
		self:_setAetherVisible(false)
		self:_setNovaVisible(false)
		self:_setVortexVisible(false)
		self:_setPrismVisible(false)
		if self._AltGui then
			self._AltGui.Enabled = false
		end
		self:_restorePagesToWindow()
		self:_applyClassicWindow()
		if w.Main then
			w.Main.Visible = w._StartupComplete and w._Visible
		end
		if w.TopBar then
			w.TopBar.Visible = true
		end
		if w.Sidebar then
			w.Sidebar.Visible = true
		end
		if w.Pages then
			w.Pages.Visible = true
		end
		return
	end

	-- Minecraft
	if mode == "Minecraft" then
		self:_setEclipseVisible(false)
		self:_setAetherVisible(false)
		self:_setNovaVisible(false)
		self:_setVortexVisible(false)
		self:_setPrismVisible(false)
		self:_restoreClassicWindow()
		self:_setOrbitVisible(false)
		w._Minimized = false
		if w.Main then
			w.Main.Visible = false
		end
		if self._AltGui then
			self._AltGui.Enabled = w._Visible ~= false
		end
		self:SyncTabs()
		self:_showHome()
		return
	end

	-- Orbit — unique vertical neon rail layout
	if mode == "Orbit" then
		self:_setEclipseVisible(false)
		self:_setAetherVisible(false)
		self:_setNovaVisible(false)
		self:_setVortexVisible(false)
		self:_setPrismVisible(false)
		self:_restoreClassicWindow()
		if self._AltGui then
			self._AltGui.Enabled = false
		end
		w._Minimized = false
		if w.Main then
			w.Main.Visible = false
		end
		self:_ensureOrbit()
		self:_setOrbitVisible(w._Visible ~= false)
		self:SyncTabs()
		return
	end

	-- Aether — unique asymmetric command-deck layout.
	if mode == "Aether" then
		self:_setEclipseVisible(false)
		self:_setNovaVisible(false)
		self:_setVortexVisible(false)
		self:_setPrismVisible(false)
		self:_restoreClassicWindow()
		if self._AltGui then
			self._AltGui.Enabled = false
		end
		w._Minimized = false
		if w.Main then
			w.Main.Visible = false
		end
		self:_ensureAether()
		self:_setAetherVisible(w._Visible ~= false)
		self:_syncAetherTabs()
		return
	end

	-- Nova — unique floating-capsule layout with horizontal pill nav + crystal stage
	if mode == "Nova" then
		self:_setEclipseVisible(false)
		self:_setAetherVisible(false)
		self:_setVortexVisible(false)
		self:_setPrismVisible(false)
		self:_restoreClassicWindow()
		if self._AltGui then
			self._AltGui.Enabled = false
		end
		self:_setOrbitVisible(false)
		w._Minimized = false
		if w.Main then
			w.Main.Visible = false
		end
		self:_ensureNova()
		self:_setNovaVisible(w._Visible ~= false)
		self:_syncNovaTabs()
		return
	end

	-- Vortex — unique radial compass layout with fan-arranged tabs around a hub
	if mode == "Vortex" then
		self:_setEclipseVisible(false)
		self:_setAetherVisible(false)
		self:_setNovaVisible(false)
		self:_setOrbitVisible(false)
		self:_setPrismVisible(false)
		self:_restoreClassicWindow()
		if self._AltGui then
			self._AltGui.Enabled = false
		end
		w._Minimized = false
		if w.Main then
			w.Main.Visible = false
		end
		self:_ensureVortex()
		self:_setVortexVisible(w._Visible ~= false)
		self:_syncVortexTabs()
		return
	end
	-- Prism -- unique book-spine spectrum rail (content left, spines right).
	if mode == "Prism" then
		self:_setEclipseVisible(false)
		self:_setAetherVisible(false)
		self:_setNovaVisible(false)
		self:_setVortexVisible(false)
		self:_setOrbitVisible(false)
		self:_restoreClassicWindow()
		if self._AltGui then
			self._AltGui.Enabled = false
		end
		w._Minimized = false
		if w.Main then
			w.Main.Visible = false
		end
		self:_ensurePrism()
		self:_setPrismVisible(w._Visible ~= false)
		self:_syncPrismTabs()
		return
	end

	-- Eclipse -- unique eclipse monolith: timeline command rail + corona stage + top capsule
	if mode == "Eclipse" then
		self:_setAetherVisible(false)
		self:_setNovaVisible(false)
		self:_setVortexVisible(false)
		self:_setPrismVisible(false)
		self:_setOrbitVisible(false)
		self:_restoreClassicWindow()
		if self._AltGui then
			self._AltGui.Enabled = false
		end
		w._Minimized = false
		if w.Main then
			w.Main.Visible = false
		end
		self:_ensureEclipse()
		self:_setEclipseVisible(w._Visible ~= false)
		self:_syncEclipseTabs()
		return
	end
end

function LayoutVariants:SetVisible(visible: boolean)
	if self._Mode == "Minecraft" then
		if self._AltGui then
			self._AltGui.Enabled = visible
		end
	elseif self._Mode == "Orbit" then
		self:_setOrbitVisible(visible)
	elseif self._Mode == "Aether" then
		self:_setAetherVisible(visible)
	elseif self._Mode == "Nova" then
		self:_setNovaVisible(visible)
	elseif self._Mode == "Vortex" then
		self:_setVortexVisible(visible)
	elseif self._Mode == "Prism" then
		self:_setPrismVisible(visible)
	elseif self._Mode == "Eclipse" then
		self:_setEclipseVisible(visible)
	else
		local w = self._Window
		if w and w.Main then
			w.Main.Visible = visible and w._StartupComplete
		end
	end
end

function LayoutVariants:RefreshTheme()
end

function LayoutVariants:Destroy()
	self:_restorePagesToWindow()
	self:_restoreClassicWindow()
	if self._Maid then
		self._Maid:DoCleaning()
	end
	if self._AltGui and self._AltGui.Parent then
		self._AltGui:Destroy()
	end
	if self._OrbitGui and self._OrbitGui.Parent then
		self._OrbitGui:Destroy()
	end
	if self._AetherGui and self._AetherGui.Parent then
		self._AetherGui:Destroy()
	end
	if self._NovaGui and self._NovaGui.Parent then
		self._NovaGui:Destroy()
	end
	if self._VortexGui and self._VortexGui.Parent then
		self._VortexGui:Destroy()
	end
	if self._PrismGui and self._PrismGui.Parent then
		self._PrismGui:Destroy()
	end
	if self._EclipseGui and self._EclipseGui.Parent then
		self._EclipseGui:Destroy()
	end
end

return LayoutVariants