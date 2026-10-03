--!strict
-- Layout variants:
--   Vaxorin  = current default shell
--   Classic  = old Vaxorin look (screenshot): NAVIGATION, no CONTROL MODULE / READY ribbon / product meta
--   Minecraft= Sirius-style home + bottom dock with real tab names + close (X)
--   Compact  = minimal floating bottom bar (extra idea)

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

	if w._Tabs then
		for _, tab in ipairs(w._Tabs) do
			if tab._PageEyebrow then
				tab._PageEyebrow.Visible = not hidden
			end
			-- Old UI had simpler page tops — hide the whole V5 page header block in Classic
			if tab._PageHeader then
				tab._PageHeader.Visible = not hidden
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
	-- Centered dock: [clock] ........ [home + tabs centered] ........ [close]
	local dock = Helpers.CreateFrame({
		Name = "Dock",
		Size = UDim2.fromOffset(580, 56),
		Position = UDim2.new(0.5, -290, 1, -76),
		BackgroundColor3 = Color3.fromRGB(14, 16, 22),
		BackgroundTransparency = 0.06,
		Parent = root,
	})
	Helpers.Corner(dock, 20)
	Helpers.Stroke(dock, Color3.fromRGB(48, 52, 64), 1)
	dock.ZIndex = 5
	self._Dock = dock

	local clock = Helpers.CreateLabel({
		Name = "Clock",
		Size = UDim2.fromOffset(48, 56),
		Position = UDim2.fromOffset(14, 0),
		Text = os.date("%H:%M"),
		Font = Theme.FontBold,
		TextSize = 13,
		TextColor3 = Color3.fromRGB(210, 215, 230),
		Parent = dock,
	})
	self._ClockLabel = clock

	local dockClose = Helpers.CreateButton({
		Name = "DockClose",
		Size = UDim2.fromOffset(40, 40),
		Position = UDim2.new(1, -50, 0.5, -20),
		Text = "×",
		Font = Theme.FontBold,
		TextSize = 20,
		TextColor3 = Color3.fromRGB(230, 230, 240),
		BackgroundColor3 = Color3.fromRGB(40, 28, 32),
		BackgroundTransparency = 0.25,
		Parent = dock,
	})
	Helpers.Corner(dockClose, 12)
	dockClose.MouseButton1Click:Connect(function()
		local w = self._Window
		if w and w.SetVisible then
			w:SetVisible(false)
		end
	end)

	-- Center cluster (home + tabs) — truly centered in the dock
	local center = Helpers.CreateFrame({
		Name = "CenterCluster",
		Size = UDim2.new(1, -120, 0, 44),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Parent = dock,
	})

	local centerLayout = Instance.new("UIListLayout")
	centerLayout.FillDirection = Enum.FillDirection.Horizontal
	centerLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	centerLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	centerLayout.Padding = UDim.new(0, 8)
	centerLayout.Parent = center

	local homeBtn = Helpers.CreateButton({
		Name = "Home",
		Size = UDim2.fromOffset(40, 40),
		Text = "⌂",
		Font = Theme.FontBold,
		TextSize = 18,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundColor3 = Color3.fromRGB(40, 44, 58),
		BackgroundTransparency = 0.2,
		LayoutOrder = 0,
		Parent = center,
	})
	Helpers.Corner(homeBtn, 12)
	self._HomeBtn = homeBtn
	homeBtn.MouseButton1Click:Connect(function()
		self:_showHome()
	end)

	local tabScroll = Instance.new("ScrollingFrame")
	tabScroll.Name = "DockTabs"
	tabScroll.Size = UDim2.new(0, 360, 0, 40)
	tabScroll.BackgroundTransparency = 1
	tabScroll.BorderSizePixel = 0
	tabScroll.ScrollBarThickness = 0
	tabScroll.ScrollingDirection = Enum.ScrollingDirection.X
	tabScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	tabScroll.AutomaticCanvasSize = Enum.AutomaticSize.X
	tabScroll.ClipsDescendants = true
	tabScroll.LayoutOrder = 1
	tabScroll.Parent = center

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
		Size = UDim2.new(1, -130, 1, -48),
		Position = UDim2.fromOffset(110, 24),
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
-- Public API
----------------------------------------------------------------------
function LayoutVariants:SetMode(mode: string)
	mode = ({ Vaxorin = "Vaxorin", Classic = "Classic", Minecraft = "Minecraft", Orbit = "Orbit", Compact = "Orbit" })[mode] or "Vaxorin"
	local prev = self._Mode
	self._Mode = mode
	local w = self._Window

	if (prev == "Minecraft" or prev == "Orbit") and mode ~= "Minecraft" and mode ~= "Orbit" then
		self:_restorePagesToWindow()
		if self._AltGui then
			self._AltGui.Enabled = false
		end
		self:_setOrbitVisible(false)
	end

	if mode == "Vaxorin" then
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
end

function LayoutVariants:SetVisible(visible: boolean)
	if self._Mode == "Minecraft" then
		if self._AltGui then
			self._AltGui.Enabled = visible
		end
	elseif self._Mode == "Orbit" then
		self:_setOrbitVisible(visible)
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
end

return LayoutVariants
