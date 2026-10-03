--!strict
-- Layout variants:
--   Vaxorin  = default modern shell (current Window)
--   Classic  = old CyberUI / Vaxorin 3.0 window look (from CyberUI - Kopie (3))
--   Minecraft= Sirius-style home cards + bottom dock (reference screenshots)

local Theme = require(script.Parent.Theme)
local Helpers = require(script.Parent.Parent.Utils.Helpers)
local Tween = require(script.Parent.Parent.Utils.Tween)
local Maid = require(script.Parent.Parent.Utils.Maid)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local TweenService = game:GetService("TweenService")

local LayoutVariants = {}
LayoutVariants.__index = LayoutVariants

local DOCK_ICONS = {
	{ id = "home", label = "Home", emoji = "⌂" },
	{ id = "people", label = "Friends", emoji = "👤" },
	{ id = "tabs", label = "Menu", emoji = "☰" },
	{ id = "music", label = "Music", emoji = "♪" },
	{ id = "settings", label = "Settings", emoji = "⚙" },
}

local function clean(name: string): string
	local s = name:gsub("^[%s%c]+", "")
	s = s:gsub("^⚙️ ", ""):gsub("^⚙ ", "")
	s = s:gsub("^🎨 ", ""):gsub("^🧩 ", ""):gsub("^⚔️ ", "")
	return s ~= "" and s or name
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
		_Dock = nil,
		_DockButtons = {},
		_ClockLabel = nil,
		_ActiveDock = "home",
		_PageHost = nil,
		_Original = {},
		_ClassicApplied = false,
		_ClockConn = nil,
		_StatsConn = nil,
	}, LayoutVariants)

	self:_buildMinecraftShell()
	self:SetMode(initial or "Vaxorin")
	return self
end

----------------------------------------------------------------------
-- Classic: restore old window proportions / styling from ZIP (3)
----------------------------------------------------------------------
function LayoutVariants:_applyClassicWindow()
	local w = self._Window
	if not w or not w.Main then
		return
	end

	-- Old theme defaults from CyberUI - Kopie (3)
	local oldSize = Vector2.new(820, 540)
	local oldTop = 82
	local oldSidebar = 216

	if w.Main then
		self:_remember(w.Main, "Size", w.Main.Size)
		w.Main.Size = UDim2.fromOffset(oldSize.X, oldSize.Y)
	end

	if w.TopBar then
		self:_remember(w.TopBar, "Size", w.TopBar.Size)
		w.TopBar.Size = UDim2.new(1, 0, 0, oldTop)
	end

	if w.Sidebar then
		self:_remember(w.Sidebar, "Size", w.Sidebar.Size)
		w.Sidebar.Size = UDim2.new(0, oldSidebar, 1, -(oldTop + (w._FooterHeight or 36)))
		if w.Sidebar.Position then
			self:_remember(w.Sidebar, "Position", w.Sidebar.Position)
			w.Sidebar.Position = UDim2.fromOffset(0, oldTop)
		end
	end

	if w.Pages then
		self:_remember(w.Pages, "Size", w.Pages.Size)
		self:_remember(w.Pages, "Position", w.Pages.Position)
		w.Pages.Position = UDim2.fromOffset(oldSidebar, oldTop)
		w.Pages.Size = UDim2.new(1, -oldSidebar, 1, -(oldTop + (w._FooterHeight or 36)))
	end

	self._ClassicApplied = true
end

function LayoutVariants:_restoreClassicWindow()
	if not self._ClassicApplied then
		return
	end
	for inst, props in pairs(self._Original) do
		if inst and inst.Parent then
			for prop, value in pairs(props) do
				pcall(function()
					(inst :: any)[prop] = value
				end)
			end
		end
	end
	self._Original = {}
	self._ClassicApplied = false
end

function LayoutVariants:_remember(inst: Instance, prop: string, value: any)
	if not self._Original[inst] then
		self._Original[inst] = {}
	end
	if self._Original[inst][prop] == nil then
		self._Original[inst][prop] = value
	end
end

----------------------------------------------------------------------
-- Minecraft / Sirius shell
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

	-- Soft vignette so cards pop over the game world
	local dim = Helpers.CreateFrame({
		Name = "Dim",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.55,
		Parent = root,
	})
	dim.ZIndex = 0

	-- Home area (cards)
	local home = Helpers.CreateFrame({
		Name = "Home",
		Size = UDim2.new(1, -48, 1, -120),
		Position = UDim2.fromOffset(24, 24),
		BackgroundTransparency = 1,
		Parent = root,
	})
	home.ZIndex = 2
	self._Home = home

	local homeTitle = Helpers.CreateLabel({
		Name = "HomeTitle",
		Size = UDim2.new(0, 280, 0, 28),
		Position = UDim2.fromOffset(8, 4),
		Text = "Home",
		Font = Theme.FontBold,
		TextSize = 26,
		TextColor3 = Color3.fromRGB(245, 245, 250),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = home,
	})
	local homeSub = Helpers.CreateLabel({
		Name = "HomeSub",
		Size = UDim2.new(0, 320, 0, 18),
		Position = UDim2.fromOffset(8, 34),
		Text = "What's left?",
		Font = Theme.Font,
		TextSize = 13,
		TextColor3 = Color3.fromRGB(160, 165, 180),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = home,
	})

	-- Card grid
	local grid = Helpers.CreateFrame({
		Name = "CardGrid",
		Size = UDim2.new(1, -16, 1, -70),
		Position = UDim2.fromOffset(8, 64),
		BackgroundTransparency = 1,
		Parent = home,
	})
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Vertical
	list.Padding = UDim.new(0, 12)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = grid

	-- Row 1: Server + Friends
	local row1 = Helpers.CreateFrame({
		Name = "Row1",
		Size = UDim2.new(1, 0, 0, 168),
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Parent = grid,
	})
	local row1Layout = Instance.new("UIListLayout")
	row1Layout.FillDirection = Enum.FillDirection.Horizontal
	row1Layout.Padding = UDim.new(0, 12)
	row1Layout.Parent = row1

	self:_buildServerCard(row1)
	self:_buildFriendsCard(row1)

	-- Row 2: profile / executor / discord style cards
	local row2 = Helpers.CreateFrame({
		Name = "Row2",
		Size = UDim2.new(1, 0, 0, 56),
		BackgroundTransparency = 1,
		LayoutOrder = 2,
		Parent = grid,
	})
	local row2Layout = Instance.new("UIListLayout")
	row2Layout.FillDirection = Enum.FillDirection.Horizontal
	row2Layout.Padding = UDim.new(0, 12)
	row2Layout.Parent = row2

	self:_buildProfileStrip(row2)

	-- Content host (when a tab is open instead of home)
	local contentHost = Helpers.CreateFrame({
		Name = "ContentHost",
		Size = UDim2.new(1, -48, 1, -120),
		Position = UDim2.fromOffset(24, 24),
		BackgroundColor3 = Color3.fromRGB(12, 14, 20),
		BackgroundTransparency = 0.12,
		Visible = false,
		Parent = root,
	})
	Helpers.Corner(contentHost, 16)
	Helpers.Stroke(contentHost, Color3.fromRGB(50, 54, 68), 1)
	contentHost.ZIndex = 2
	self._ContentHost = contentHost

	local pageHost = Helpers.CreateFrame({
		Name = "PageHost",
		Size = UDim2.new(1, -24, 1, -24),
		Position = UDim2.fromOffset(12, 12),
		BackgroundTransparency = 1,
		Parent = contentHost,
	})
	self._PageHost = pageHost

	-- Bottom dock (Sirius style)
	self:_buildDock(root)
end

function LayoutVariants:_card(parent: Instance, props: {
	Name: string,
	Size: UDim2,
	BackgroundColor3: Color3?,
	LayoutOrder: number?,
}): Frame
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
		BackgroundColor3 = Color3.fromRGB(18, 48, 38), -- green tint like screenshot
		LayoutOrder = 1,
	})
	-- gradient-ish top accent
	local accent = Helpers.CreateFrame({
		Name = "Accent",
		Size = UDim2.new(1, 0, 0, 3),
		BackgroundColor3 = Color3.fromRGB(60, 200, 140),
		Parent = card,
	})
	Helpers.Corner(accent, 2)

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
		local v = Helpers.CreateLabel({
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
		return v
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

	local function fstat(name: string, label: string, order: number, accent: Color3?): TextLabel
		local box = Helpers.CreateFrame({
			Name = name,
			BackgroundColor3 = Color3.fromRGB(22, 24, 32),
			BackgroundTransparency = 0.15,
			LayoutOrder = order,
			Parent = stats,
		})
		Helpers.Corner(box, 8)
		if accent then
			local bar = Helpers.CreateFrame({
				Name = "Bar",
				Size = UDim2.new(0, 3, 1, -10),
				Position = UDim2.fromOffset(6, 5),
				BackgroundColor3 = accent,
				Parent = box,
			})
			Helpers.Corner(bar, 2)
		end
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
		return card
	end

	strip("DisplayCard", displayName, "DisplayName", Color3.fromRGB(18, 20, 28), 1)
	strip("ExecutorCard", "Synapse X", "Your very own, always supported client", Color3.fromRGB(48, 18, 22), 2)
	strip("DiscordCard", "Discord", "Tap to join our Discord server for updates and more", Color3.fromRGB(16, 18, 28), 3)
end

function LayoutVariants:_buildDock(root: Frame)
	local dock = Helpers.CreateFrame({
		Name = "Dock",
		Size = UDim2.fromOffset(320, 52),
		Position = UDim2.new(0.5, -160, 1, -72),
		BackgroundColor3 = Color3.fromRGB(14, 16, 22),
		BackgroundTransparency = 0.08,
		Parent = root,
	})
	Helpers.Corner(dock, 18)
	Helpers.Stroke(dock, Color3.fromRGB(48, 52, 64), 1)
	dock.ZIndex = 5
	self._Dock = dock

	-- clock on the left of dock
	local clock = Helpers.CreateLabel({
		Name = "Clock",
		Size = UDim2.fromOffset(48, 52),
		Position = UDim2.fromOffset(10, 0),
		Text = "00:00",
		Font = Theme.FontBold,
		TextSize = 12,
		TextColor3 = Color3.fromRGB(210, 215, 230),
		Parent = dock,
	})
	self._ClockLabel = clock

	local icons = Helpers.CreateFrame({
		Name = "Icons",
		Size = UDim2.new(1, -70, 1, 0),
		Position = UDim2.fromOffset(56, 0),
		BackgroundTransparency = 1,
		Parent = dock,
	})
	local il = Instance.new("UIListLayout")
	il.FillDirection = Enum.FillDirection.Horizontal
	il.HorizontalAlignment = Enum.HorizontalAlignment.Center
	il.VerticalAlignment = Enum.VerticalAlignment.Center
	il.Padding = UDim.new(0, 6)
	il.Parent = icons

	self._DockButtons = {}
	for i, def in ipairs(DOCK_ICONS) do
		local btn = Helpers.CreateButton({
			Name = def.id,
			Size = UDim2.fromOffset(40, 40),
			Text = def.emoji,
			Font = Theme.FontBold,
			TextSize = 16,
			TextColor3 = Color3.fromRGB(180, 185, 200),
			BackgroundColor3 = Color3.fromRGB(24, 26, 34),
			BackgroundTransparency = 1,
			Parent = icons,
		})
		Helpers.Corner(btn, 12)
		btn.LayoutOrder = i
		self._DockButtons[def.id] = btn

		btn.MouseButton1Click:Connect(function()
			self:_selectDock(def.id)
		end)
	end

	-- settings gear on the far right of screen (like screenshot)
	local gear = Helpers.CreateButton({
		Name = "Gear",
		Size = UDim2.fromOffset(40, 40),
		Position = UDim2.new(1, -56, 1, -66),
		Text = "⚙",
		Font = Theme.FontBold,
		TextSize = 18,
		TextColor3 = Color3.fromRGB(200, 205, 220),
		BackgroundColor3 = Color3.fromRGB(18, 20, 28),
		BackgroundTransparency = 0.1,
		Parent = root,
	})
	Helpers.Corner(gear, 12)
	Helpers.Stroke(gear, Color3.fromRGB(50, 54, 66), 1)
	gear.ZIndex = 5
	gear.MouseButton1Click:Connect(function()
		self:_selectDock("settings")
	end)

	self:_startClock()
	self:_selectDock("home")
end

function LayoutVariants:_selectDock(id: string)
	self._ActiveDock = id
	for key, btn in pairs(self._DockButtons) do
		if key == id then
			btn.BackgroundTransparency = 0.35
			btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		else
			btn.BackgroundTransparency = 1
			btn.TextColor3 = Color3.fromRGB(180, 185, 200)
		end
	end

	if id == "home" then
		if self._Home then
			self._Home.Visible = true
		end
		if self._ContentHost then
			self._ContentHost.Visible = false
		end
		self:_restorePagesToWindow()
	elseif id == "tabs" or id == "settings" or id == "people" or id == "music" then
		if self._Home then
			self._Home.Visible = false
		end
		if self._ContentHost then
			self._ContentHost.Visible = true
		end
		self:_movePagesToHost()
		-- try to open a sensible tab
		local w = self._Window
		if w and w._Tabs then
			local targetName = if id == "settings" then "Settings" elseif id == "people" then "Player" else nil
			if targetName then
				for _, tab in ipairs(w._Tabs) do
					if tab and tab.Name and string.find(string.lower(clean(tab.Name)), string.lower(targetName)) then
						if w._selectTab then
							w:_selectTab(tab)
						end
						break
					end
				end
			end
		end
	end
end

function LayoutVariants:_startClock()
	if self._ClockConn then
		self._ClockConn:Disconnect()
	end
	local function tick()
		if self._ClockLabel then
			self._ClockLabel.Text = os.date("%H:%M")
		end
	end
	tick()
	self._ClockConn = RunService.Heartbeat:Connect(function()
		-- update once per second-ish
		if tick then
			tick()
		end
	end)
	self._Maid:Give(self._ClockConn)
end

function LayoutVariants:_startStats()
	if self._StatsConn then
		self._StatsConn:Disconnect()
	end
	local function refresh()
		local lp = Players.LocalPlayer
		local players = #Players:GetPlayers()
		local maxPlayers = Players.MaxPlayers
		if self._StatPlayers then
			self._StatPlayers.Text = tostring(players)
		end
		if self._StatMax then
			self._StatMax.Text = tostring(maxPlayers)
		end
		if self._StatLatency then
			local ping = 0
			pcall(function()
				ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
			end)
			self._StatLatency.Text = string.format("%d ms", ping)
		end
		if self._StatRegion then
			self._StatRegion.Text = "—"
		end
		-- friends (best-effort; may be 0 in many environments)
		if self._FriendInServer then
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
	end
	refresh()
	self._StatsConn = RunService.Heartbeat:Connect(function() end)
	task.spawn(function()
		while self._AltGui and self._AltGui.Parent do
			refresh()
			task.wait(2)
		end
	end)
end

function LayoutVariants:_movePagesToHost()
	local w = self._Window
	if not w or not w.Pages or not self._PageHost then
		return
	end
	if w.Pages.Parent ~= self._PageHost then
		w.Pages.Parent = self._PageHost
		w.Pages.Size = UDim2.fromScale(1, 1)
		w.Pages.Position = UDim2.fromScale(0, 0)
		w.Pages.Visible = true
	end
end

function LayoutVariants:_restorePagesToWindow()
	local w = self._Window
	if not w or not w.Pages or not w.Main then
		return
	end
	if w.Pages.Parent == self._PageHost then
		w.Pages.Parent = w.Main
		-- sizes restored when leaving Minecraft via SetMode
	end
end

----------------------------------------------------------------------
-- Public API
----------------------------------------------------------------------
function LayoutVariants:SyncTabs()
	-- Minecraft dock doesn't list every tab; Classic uses main window tabs.
end

function LayoutVariants:SetMode(mode: string)
	mode = ({ Vaxorin = "Vaxorin", Classic = "Classic", Minecraft = "Minecraft" })[mode] or "Vaxorin"
	self._Mode = mode
	local w = self._Window

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
		-- Classic = old CyberUI window (no alt shell)
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

	-- Minecraft = Sirius shell
	self:_restoreClassicWindow()
	w._Minimized = false
	if w.Main then
		w.Main.Visible = false
	end
	if self._AltGui then
		self._AltGui.Enabled = w._Visible ~= false
	end
	self:_selectDock(self._ActiveDock or "home")
end

function LayoutVariants:SetVisible(visible: boolean)
	if self._Mode == "Minecraft" then
		if self._AltGui then
			self._AltGui.Enabled = visible
		end
	elseif self._Mode == "Classic" or self._Mode == "Vaxorin" then
		local w = self._Window
		if w and w.Main then
			w.Main.Visible = visible and w._StartupComplete
		end
	end
end

function LayoutVariants:RefreshTheme()
end

function LayoutVariants:Destroy()
	if self._ClockConn then
		self._ClockConn:Disconnect()
		self._ClockConn = nil
	end
	if self._StatsConn then
		self._StatsConn:Disconnect()
		self._StatsConn = nil
	end
	self:_restorePagesToWindow()
	self:_restoreClassicWindow()
	if self._Maid then
		self._Maid:DoCleaning()
	end
	if self._AltGui and self._AltGui.Parent then
		self._AltGui:Destroy()
	end
end

return LayoutVariants
