--!strict

local Theme = require(script.Parent.Theme)
local Tab = require(script.Parent.Tab)
local Maid = require(script.Parent.Parent.Utils.Maid)
local Helpers = require(script.Parent.Parent.Utils.Helpers)
local Tween = require(script.Parent.Parent.Utils.Tween)
local ESPBuilder = require(script.Parent.ESPBuilder)
local ESPWorldRenderer = require(script.Parent.ESPWorldRenderer)
local LayoutVariants = require(script.Parent.LayoutVariants)

local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local Stats = game:GetService("Stats")

local GUI_NAME = "Vaxorin"
local VERSION = "5.0"
local Old_Vaxorin_Logo = "rbxassetid://135320038058277"
local Bad_Vaxorin_Logo = "rbxassetid://132857255558778"
local Vaxorin_Logo = "rbxassetid://89182255271217"
local LEGACY_LOGO = "rbxassetid://128228297210141"


-- Inline weather (no separate module — works with older load.lua MODULE_PATHS)

local function createWeather(parent: Instance)
	local RunService = game:GetService("RunService")
	local layer = Instance.new("Frame")
	layer.Name = "WeatherLayer"
	layer.BackgroundTransparency = 1
	layer.Size = UDim2.fromScale(1, 1)
	layer.ZIndex = 100
	layer.ClipsDescendants = false
	layer.Visible = false
	layer.Active = false
	layer.Parent = parent

	-- Deep-Fishing style particles use soft glow sprites, not solid rectangles
	local STAR = "rbxassetid://99851851"
	local GLOW = "rbxassetid://6014261993"

	local presets = {
		Rain = {
			count = 70,
			vy = { 280, 460 }, vx = { -25, 10 },
			size = { 1, 2, 14, 22 }, -- minW maxW minH maxH
			color = Color3.fromRGB(180, 210, 240),
			image = nil, -- thin frame streaks
			rot = 12,
			spin = 0,
			trans = { 0.25, 0.55 },
		},
		Snow = {
			count = 48,
			vy = { 28, 70 }, vx = { -40, 40 },
			size = { 6, 14, 6, 14 },
			color = Color3.fromRGB(255, 255, 255),
			image = STAR,
			rot = 0,
			spin = 25,
			trans = { 0.05, 0.35 },
		},
		Sakura = {
			count = 36,
			vy = { 35, 75 }, vx = { -60, 60 },
			size = { 8, 16, 8, 16 },
			color = Color3.fromRGB(255, 150, 190),
			image = STAR,
			rot = 0,
			spin = 80,
			trans = { 0.05, 0.3 },
		},
		Stars = {
			count = 50,
			vy = { 6, 18 }, vx = { -10, 10 },
			size = { 4, 12, 4, 12 },
			color = Color3.fromRGB(255, 245, 255),
			image = STAR,
			rot = 0,
			spin = 10,
			trans = { 0.1, 0.6 },
			twinkle = true,
		},
		Leaves = {
			count = 28,
			vy = { 45, 95 }, vx = { -90, 90 },
			size = { 10, 18, 8, 14 },
			color = Color3.fromRGB(210, 150, 60),
			image = STAR,
			rot = 0,
			spin = 120,
			trans = { 0.05, 0.25 },
		},
	}

	local api = {
		_kind = "None",
		_items = {} :: { any },
		_conn = nil :: RBXScriptConnection?,
		_scope = "Screen",
		_screenParent = parent,
		_uiParent = nil,
	}

	function api:SetParentTargets(screenParent: Instance?, uiParent: Instance?)
		self._screenParent = screenParent or self._screenParent
		self._uiParent = uiParent
	end

	function api:SetScope(scope: string)
		scope = scope or "Screen"
		self._scope = scope
		local target = if scope == "UI" and self._uiParent then self._uiParent else self._screenParent
		if target and layer.Parent ~= target then
			layer.Parent = target
		end
		layer.ClipsDescendants = (scope == "UI")
		-- Behind chrome when inside UI, above dim when full-screen
		layer.ZIndex = if scope == "UI" then 2 else 100
	end

	function api:Set(kind: string)
		kind = kind or "None"
		if self._conn then
			self._conn:Disconnect()
			self._conn = nil
		end
		for _, item in self._items do
			if item.inst then item.inst:Destroy() end
		end
		table.clear(self._items)
		self._kind = kind
		local preset = presets[kind]
		if not preset then
			layer.Visible = false
			return
		end
		layer.Visible = true
		local rng = Random.new()

		for i = 1, preset.count do
			local w = rng:NextInteger(preset.size[1], preset.size[2])
			local h = rng:NextInteger(preset.size[3], preset.size[4])
			local inst: GuiObject
			if preset.image then
				local img = Instance.new("ImageLabel")
				img.BackgroundTransparency = 1
				img.Image = preset.image
				img.ImageColor3 = preset.color
				img.ImageTransparency = rng:NextNumber(preset.trans[1], preset.trans[2])
				img.ScaleType = Enum.ScaleType.Fit
				inst = img
			else
				local f = Instance.new("Frame")
				f.BorderSizePixel = 0
				f.BackgroundColor3 = preset.color
				f.BackgroundTransparency = rng:NextNumber(preset.trans[1], preset.trans[2])
				inst = f
			end
			inst.Size = UDim2.fromOffset(w, h)
			inst.AnchorPoint = Vector2.new(0.5, 0.5)
			inst.ZIndex = 101
			inst.Active = false
			inst.Parent = layer

			local abs = layer.AbsoluteSize
			local startX = rng:NextNumber(0, math.max(abs.X, 200))
			local startY = rng:NextNumber(-abs.Y * 0.3, math.max(abs.Y, 200))
			inst.Position = UDim2.fromOffset(startX, startY)
			inst.Rotation = preset.rot + rng:NextNumber(-20, 20)

			self._items[i] = {
				inst = inst,
				x = startX,
				y = startY,
				vx = rng:NextNumber(preset.vx[1], preset.vx[2]),
				vy = rng:NextNumber(preset.vy[1], preset.vy[2]),
				spin = (if preset.spin ~= 0 then rng:NextNumber(-preset.spin, preset.spin) else 0),
				baseT = if inst:IsA("ImageLabel") then inst.ImageTransparency else inst.BackgroundTransparency,
				phase = rng:NextNumber(0, math.pi * 2),
				twinkle = preset.twinkle == true,
				isImage = inst:IsA("ImageLabel"),
			}
		end

		self._conn = RunService.RenderStepped:Connect(function(dt)
			dt = math.clamp(dt, 0, 0.05)
			local abs = layer.AbsoluteSize
			if abs.X < 4 or abs.Y < 4 then
				return
			end
			local t = os.clock()
			for _, item in self._items do
				local inst = item.inst
				if not inst or not inst.Parent then
					continue
				end
				-- continuous velocity — never "stop"
				item.x += item.vx * dt + math.sin(t * 1.4 + item.phase) * 18 * dt
				item.y += item.vy * dt
				inst.Rotation += item.spin * dt

				if item.twinkle then
					local pulse = 0.15 + 0.45 * (0.5 + 0.5 * math.sin(t * 3.2 + item.phase))
					if item.isImage then
						(inst :: ImageLabel).ImageTransparency = pulse
					end
				end

				-- recycle past edges
				if item.y > abs.Y + 40 then
					item.y = rng:NextNumber(-50, -10)
					item.x = rng:NextNumber(0, abs.X)
				elseif item.x < -40 then
					item.x = abs.X + 20
				elseif item.x > abs.X + 40 then
					item.x = -20
				end

				inst.Position = UDim2.fromOffset(item.x, item.y)
			end
		end)
	end

	function api:Destroy()
		if self._conn then self._conn:Disconnect() end
		for _, item in self._items do
			if item.inst then item.inst:Destroy() end
		end
		layer:Destroy()
	end

	return api
end


-- Soft 9-slice drop shadow, used behind the main window for real depth instead
-- of a flat card floating on nothing.
local SHADOW_IMAGE = "rbxassetid://6014261993"
local SHADOW_SLICE_CENTER = Rect.new(49, 49, 450, 450)

-- Short, unobtrusive UI click. Toggleable via Options -> Sound Effects.
local CLICK_SOUND_ID = "rbxassetid://876939830"
local function cleanDisplayName(name: string): string
    -- Keep the visible tab label free of emoji/symbol prefixes that may render
    -- as empty squares on some executor/Roblox font combinations.
    local cleaned = name
    cleaned = cleaned:gsub("^[%s%c]+", "")
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

local function createMagnifier(parent: Instance, theme: any)
    local root = Helpers.CreateFrame({
        Name = "SearchIcon",
        Size = UDim2.fromOffset(22, 22),
        Position = UDim2.fromOffset(10, 11),
        BackgroundTransparency = 1,
        Parent = parent,
    })
    root.ZIndex = 3

    local ring = Helpers.CreateFrame({
        Name = "Ring",
        Size = UDim2.fromOffset(12, 12),
        Position = UDim2.fromOffset(2, 2),
        BackgroundTransparency = 1,
        Parent = root,
    })
    local stroke = Helpers.Stroke(ring, theme.TextMuted, 2)
    stroke.Transparency = 0.08
    Helpers.Corner(ring, 999)

    local handle = Helpers.CreateFrame({
        Name = "Handle",
        Size = UDim2.fromOffset(8, 2),
        Position = UDim2.fromOffset(12, 14),
        Rotation = 45,
        BackgroundColor3 = theme.TextMuted,
        BorderSizePixel = 0,
        Parent = root,
    })
    Helpers.Corner(handle, 2)

    return root, stroke, handle
end


-- How often (seconds) the bottom info bar / watermark refreshes.
-- Was previously recalculated every single Heartbeat frame (~60x/sec) for no reason.
local INFO_BAR_REFRESH_INTERVAL = 1
local WATERMARK_REFRESH_INTERVAL = 0.5

local Window = {}
Window.__index = Window

export type WindowOptions = {
	Title: string?,
	Subtitle: string?,
	Size: Vector2?,
	Center: boolean?,
	BackgroundImage: string?,
	Logo: string?,
	Badges: { { Text: string, Color: Color3? } }?,
	Footer: { Avatar: string?, Username: string? }?,
	ShowSearch: boolean?,
	ShowWindowControls: boolean?,
	ToggleKey: Enum.KeyCode?,
	TopMost: boolean?,
	HideCoreUI: boolean?,
}

export type DeveloperPanelHandle = {
	SetStats: (self: DeveloperPanelHandle, stats: { [string]: any }) -> (),
	SetContent: (self: DeveloperPanelHandle, content: string) -> (),
	Close: (self: DeveloperPanelHandle) -> (),
	Open: (self: DeveloperPanelHandle) -> (),
}

export type WindowHandle = {
	CreateTab: (self: WindowHandle, name: string) -> any,
	CreateDeveloperWindow: (self: WindowHandle, options: any?) -> DeveloperPanelHandle,
	OpenDeveloperWindow: (self: WindowHandle, options: any?) -> DeveloperPanelHandle,
	CreateESPBuilder: (self: WindowHandle, options: any?) -> any,
	CreateESPWorldRenderer: (self: WindowHandle, options: any?) -> any,
	CreateNotice: (self: WindowHandle, data: any) -> any,
	CreateStat: (self: WindowHandle, data: any) -> any,
	CreateDivider: (self: WindowHandle, data: any?) -> any,
	CreateIconButton: (self: WindowHandle, data: any?) -> any,
	CreateCard: (self: WindowHandle, data: any) -> any,
	CreateBadge: (self: WindowHandle, data: any) -> any,
	CreateProgress: (self: WindowHandle, data: any) -> any,
	CreateStatus: (self: WindowHandle, data: any) -> any,
	Notify: (self: WindowHandle, options: any) -> any,
	Destroy: (self: WindowHandle) -> (),
}

-- Safely resolve the executor name without ever throwing.
local function getExecutorName(): string
	local ok, result = pcall(function()
		if syn and syn.getexecutorname then
			return syn.getexecutorname()
		elseif getexecutorname then
			return getexecutorname()
		elseif identifyexecutor then
			local name = identifyexecutor()
			return name
		end
		return "Unknown"
	end)
	if ok and typeof(result) == "string" and result ~= "" then
		return result
	end
	return "Unknown"
end


-- Extracted from Window.new so the compiler stays under the 200 local-register limit.
local function startCinematicBoot(ctx)
	local library = ctx.Library
	local data = ctx.Data
	local windowName = ctx.WindowName
	local screenGui = ctx.ScreenGui
	local sharedState = ctx.SharedState

-- ============================================
-- CINEMATIC BOOT SEQUENCE (continuous handoff)
-- Reuses the module-loader GUI when present so the logo never blinks out.
-- ============================================
local bootLogoAsset = data.Logo
if bootLogoAsset == nil or bootLogoAsset == "" or bootLogoAsset == LEGACY_LOGO then
	bootLogoAsset = Vaxorin_Logo
end

local sharedBootstrap = sharedState.CyberUI_BootstrapLoader
sharedState.CyberUI_BootstrapLoader = nil

local loadingGui: ScreenGui
local bootBackdrop: Frame
local logoWrap: Frame
local logoImage: ImageLabel?
local logoScale: UIScale
local logoStroke: UIStroke?
local bootTitle: TextLabel
local bootSub: TextLabel
local bootTrack: Frame
local bootFill: Frame
local bootStatus: TextLabel
local bootPercent: TextLabel
local bootBloom: Frame
local reusedBootstrap = false

local function ensureUIScale(parent: Instance): UIScale
	local s = parent:FindFirstChildOfClass("UIScale")
	if s then return s end
	local n = Instance.new("UIScale")
	n.Scale = 1
	n.Parent = parent
	return n
end

if sharedBootstrap and sharedBootstrap.Parent then
	reusedBootstrap = true
	loadingGui = sharedBootstrap
	loadingGui.Name = "VaxorinBoot"
	loadingGui.DisplayOrder = 2147483646
	bootBackdrop = loadingGui:FindFirstChild("Backdrop") :: any
	if not bootBackdrop then
		bootBackdrop = Helpers.CreateFrame({
			Name = "Backdrop",
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.fromRGB(4, 2, 10),
			BackgroundTransparency = 0.05,
			Parent = loadingGui,
		})
	end

	logoWrap = bootBackdrop:FindFirstChild("LogoWrap") :: any
	if not logoWrap then
		logoWrap = Helpers.CreateFrame({
			Name = "LogoWrap",
			Size = UDim2.fromOffset(88, 88),
			Position = UDim2.new(0.5, 0, 0.5, -64),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = library.Theme.Secondary,
			BackgroundTransparency = 0.15,
			Parent = bootBackdrop,
		})
		Helpers.Corner(logoWrap, 26)
	end
	logoScale = ensureUIScale(logoWrap)
	logoStroke = logoWrap:FindFirstChildOfClass("UIStroke")
	if not logoStroke then
		logoStroke = Helpers.Stroke(logoWrap, library.Theme.Accent, 1.5)
		logoStroke.Transparency = 0.25
	end
	logoImage = logoWrap:FindFirstChild("Logo") :: any
	if logoImage and logoImage:IsA("ImageLabel") then
		logoImage.Image = tostring(bootLogoAsset)
		logoImage.ImageTransparency = 0
	else
		logoImage = Instance.new("ImageLabel")
		logoImage.Name = "Logo"
		logoImage.BackgroundTransparency = 1
		logoImage.Size = UDim2.fromScale(0.7, 0.7)
		logoImage.Position = UDim2.fromScale(0.5, 0.5)
		logoImage.AnchorPoint = Vector2.new(0.5, 0.5)
		logoImage.Image = tostring(bootLogoAsset)
		logoImage.ScaleType = Enum.ScaleType.Fit
		logoImage.Parent = logoWrap
	end

	-- Brand title from phase 1 becomes bootSub; window name becomes bootTitle
	bootTitle = bootBackdrop:FindFirstChild("Title") :: any
	if not bootTitle then
		bootTitle = Helpers.CreateLabel({
			Name = "Title",
			Size = UDim2.fromOffset(520, 40),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0),
			Text = "Vaxorin",
			Font = Theme.FontBold,
			TextSize = 28,
			TextColor3 = library.Theme.Text,
			Parent = bootBackdrop,
		})
	end
	bootSub = bootBackdrop:FindFirstChild("WindowTitle") :: any
	if not bootSub then
		bootSub = Helpers.CreateLabel({
			Name = "WindowTitle",
			Size = UDim2.fromOffset(520, 22),
			Position = UDim2.new(0.5, 0, 0.5, 36),
			AnchorPoint = Vector2.new(0.5, 0),
			Text = windowName,
			Font = Theme.FontBold,
			TextSize = 14,
			TextColor3 = library.Theme.Accent,
			TextTransparency = 1,
			Parent = bootBackdrop,
		})
	end

	bootStatus = bootBackdrop:FindFirstChild("Status") :: any
	bootTrack = bootBackdrop:FindFirstChild("Track") :: any
	bootFill = bootTrack and bootTrack:FindFirstChild("Fill") :: any
	bootPercent = bootBackdrop:FindFirstChild("Percent") :: any
	if not bootTrack then
		bootTrack = Helpers.CreateFrame({
			Name = "Track",
			Size = UDim2.fromOffset(220, 3),
			Position = UDim2.new(0.5, 0, 0.5, 74),
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundColor3 = Color3.fromRGB(40, 32, 55),
			Parent = bootBackdrop,
		})
		Helpers.Corner(bootTrack, 2)
		bootFill = Helpers.CreateFrame({
			Name = "Fill",
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = library.Theme.Accent,
			Parent = bootTrack,
		})
		Helpers.Corner(bootFill, 2)
	end
	if not bootStatus then
		bootStatus = Helpers.CreateLabel({
			Name = "Status",
			Size = UDim2.fromOffset(400, 18),
			Position = UDim2.new(0.5, 0, 0.5, 92),
			AnchorPoint = Vector2.new(0.5, 0),
			Text = "Ready",
			Font = Theme.Font,
			TextSize = 12,
			TextColor3 = library.Theme.TextMuted,
			Parent = bootBackdrop,
		})
	end
	if not bootPercent then
		bootPercent = Helpers.CreateLabel({
			Name = "Percent",
			Size = UDim2.fromOffset(80, 18),
			Position = UDim2.new(0.5, 0, 0.5, 112),
			AnchorPoint = Vector2.new(0.5, 0),
			Text = "100%",
			Font = Theme.FontBold,
			TextSize = 11,
			TextColor3 = library.Theme.Text,
			Parent = bootBackdrop,
		})
	end

	bootBloom = bootBackdrop:FindFirstChild("Bloom") :: any
	if not bootBloom then
		bootBloom = Helpers.CreateFrame({
			Name = "Bloom",
			Size = UDim2.fromOffset(420, 420),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = library.Theme.Accent,
			BackgroundTransparency = 0.92,
			Parent = bootBackdrop,
		})
		Helpers.Corner(bootBloom, 999)
		bootBloom.ZIndex = 0
	end
else
	-- Cold start (no module loader) — build full boot GUI
	loadingGui = Instance.new("ScreenGui")
	loadingGui.Name = "VaxorinBoot"
	loadingGui.ResetOnSpawn = false
	loadingGui.IgnoreGuiInset = true
	loadingGui.DisplayOrder = 2147483646
	loadingGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	local bootParent = screenGui.Parent
	if not bootParent then
		pcall(function()
			loadingGui.Parent = game:GetService("CoreGui")
		end)
		if not loadingGui.Parent then
			bootParent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
			loadingGui.Parent = bootParent
		end
	else
		loadingGui.Parent = bootParent
	end
	print("[Vaxorin] boot started")

	bootBackdrop = Helpers.CreateFrame({
		Name = "Backdrop",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(4, 2, 10),
		BackgroundTransparency = 0.05,
		Parent = loadingGui,
	})
	bootBloom = Helpers.CreateFrame({
		Name = "Bloom",
		Size = UDim2.fromOffset(120, 120),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = library.Theme.Accent,
		BackgroundTransparency = 0.96,
		Parent = bootBackdrop,
	})
	Helpers.Corner(bootBloom, 999)

	logoWrap = Helpers.CreateFrame({
		Name = "LogoWrap",
		Size = UDim2.fromOffset(96, 96),
		Position = UDim2.new(0.5, 0, 0.5, -70),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = library.Theme.Secondary,
		BackgroundTransparency = 0.15,
		Parent = bootBackdrop,
	})
	Helpers.Corner(logoWrap, 28)
	logoStroke = Helpers.Stroke(logoWrap, library.Theme.Accent, 1.5)
	logoStroke.Transparency = 0.25
	logoScale = ensureUIScale(logoWrap)
	logoScale.Scale = 0.4
	logoImage = Instance.new("ImageLabel")
	logoImage.Name = "Logo"
	logoImage.BackgroundTransparency = 1
	logoImage.Size = UDim2.fromScale(0.72, 0.72)
	logoImage.Position = UDim2.fromScale(0.5, 0.5)
	logoImage.AnchorPoint = Vector2.new(0.5, 0.5)
	logoImage.Image = tostring(bootLogoAsset)
	logoImage.ScaleType = Enum.ScaleType.Fit
	logoImage.ImageTransparency = 1
	logoImage.Parent = logoWrap

	bootTitle = Helpers.CreateLabel({
		Name = "Title",
		Size = UDim2.fromOffset(520, 40),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0),
		Text = "Vaxorin",
		Font = Theme.FontBold,
		TextSize = 28,
		TextColor3 = library.Theme.Text,
		TextTransparency = 1,
		Parent = bootBackdrop,
	})
	bootSub = Helpers.CreateLabel({
		Name = "WindowTitle",
		Size = UDim2.fromOffset(520, 22),
		Position = UDim2.new(0.5, 0, 0.5, 36),
		AnchorPoint = Vector2.new(0.5, 0),
		Text = windowName,
		Font = Theme.FontBold,
		TextSize = 14,
		TextColor3 = library.Theme.Accent,
		TextTransparency = 1,
		Parent = bootBackdrop,
	})
	bootTrack = Helpers.CreateFrame({
		Name = "Track",
		Size = UDim2.fromOffset(220, 3),
		Position = UDim2.new(0.5, 0, 0.5, 74),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = Color3.fromRGB(40, 32, 55),
		Parent = bootBackdrop,
	})
	Helpers.Corner(bootTrack, 2)
	bootFill = Helpers.CreateFrame({
		Name = "Fill",
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = library.Theme.Accent,
		Parent = bootTrack,
	})
	Helpers.Corner(bootFill, 2)
	bootStatus = Helpers.CreateLabel({
		Name = "Status",
		Size = UDim2.fromOffset(400, 18),
		Position = UDim2.new(0.5, 0, 0.5, 92),
		AnchorPoint = Vector2.new(0.5, 0),
		Text = "Booting…",
		Font = Theme.Font,
		TextSize = 12,
		TextColor3 = library.Theme.TextMuted,
		TextTransparency = 1,
		Parent = bootBackdrop,
	})
	bootPercent = Helpers.CreateLabel({
		Name = "Percent",
		Size = UDim2.fromOffset(80, 18),
		Position = UDim2.new(0.5, 0, 0.5, 112),
		AnchorPoint = Vector2.new(0.5, 0),
		Text = "0%",
		Font = Theme.FontBold,
		TextSize = 11,
		TextColor3 = library.Theme.Text,
		TextTransparency = 1,
		Parent = bootBackdrop,
	})
end

if not reusedBootstrap then
	print("[Vaxorin] boot started")
else
	print("[Vaxorin] boot started")
end

-- Rings + particles (always add for phase 2 polish)
local function makeRing(size: number, transparency: number)
	local ring = Instance.new("Frame")
	ring.Name = "Ring"
	ring.Size = UDim2.fromOffset(size, size)
	ring.Position = UDim2.fromScale(0.5, 0.5)
	ring.AnchorPoint = Vector2.new(0.5, 0.5)
	ring.BackgroundTransparency = 1
	ring.ZIndex = 0
	ring.Parent = bootBackdrop
	local stroke = Instance.new("UIStroke")
	stroke.Color = library.Theme.Accent
	stroke.Thickness = 1.2
	stroke.Transparency = 1 -- fade in
	stroke.Parent = ring
	Helpers.Corner(ring, 999)
	return ring, stroke
end
local ring1, ringStroke1 = makeRing(200, 0.75)
local ring2, ringStroke2 = makeRing(280, 0.85)
local ring3, ringStroke3 = makeRing(360, 0.92)

local particleFolder = bootBackdrop:FindFirstChild("Particles")
if not particleFolder then
	particleFolder = Instance.new("Folder")
	particleFolder.Name = "Particles"
	particleFolder.Parent = bootBackdrop
end
local particles = {}
for i = 1, 16 do
	local p = Instance.new("Frame")
	p.Size = UDim2.fromOffset(math.random(2, 4), math.random(2, 4))
	p.Position = UDim2.fromScale(math.random(), math.random())
	p.AnchorPoint = Vector2.new(0.5, 0.5)
	p.BackgroundColor3 = library.Theme.Accent
	p.BackgroundTransparency = 0.5
	p.BorderSizePixel = 0
	p.Parent = particleFolder
	Helpers.Corner(p, 999)
	particles[i] = p
end

local bootCard = logoWrap

-- PHASE HAND-OFF ANIMATION
task.spawn(function()
	-- Logo STAYS — only a gentle pulse, never fade out
	Tween.Play(logoScale, { Scale = 1.06 }, {
		Time = 0.28,
		EasingStyle = Enum.EasingStyle.Quad,
		EasingDirection = Enum.EasingDirection.Out,
	})
	task.wait(0.12)
	Tween.Play(logoScale, { Scale = 1 }, {
		Time = 0.35,
		EasingStyle = Enum.EasingStyle.Back,
		EasingDirection = Enum.EasingDirection.Out,
	})
	if logoImage then
		Tween.Play(logoImage, { ImageTransparency = 0 }, { Time = 0.2 })
	end
	if logoStroke then
		Tween.Play(logoStroke, { Transparency = 0.2, Color = library.Theme.Accent }, { Time = 0.3 })
	end
	Tween.Play(logoWrap, {
		BackgroundTransparency = 0.12,
		Size = UDim2.fromOffset(96, 96),
		Position = UDim2.new(0.5, 0, 0.5, -70),
	}, { Time = 0.35 })

	-- Morph brand label: "Vaxorin" shrinks into eyebrow, window title rises in
	bootTitle.Text = "Vaxorin"
	Tween.Play(bootTitle, {
		TextSize = 11,
		TextColor3 = library.Theme.TextMuted,
		TextTransparency = 0,
		Position = UDim2.new(0.5, 0, 0.5, -22), -- above window title, clear gap
	}, { Time = 0.4 })

	bootSub.Text = windowName
	bootSub.TextTransparency = 1
	bootSub.Position = UDim2.new(0.5, 0, 0.5, 24)
	Tween.Play(bootSub, {
		TextTransparency = 0,
		Position = UDim2.new(0.5, 0, 0.5, 0),
		TextSize = 26,
		TextColor3 = library.Theme.Text,
	}, {
		Time = 0.45,
		EasingStyle = Enum.EasingStyle.Quint,
		EasingDirection = Enum.EasingDirection.Out,
	})

	-- Track / status under title
	Tween.Play(bootTrack, {
		Position = UDim2.new(0.5, 0, 0.5, 42),
		BackgroundTransparency = 0.15,
	}, { Time = 0.3 })
	if bootFill then
		Tween.Play(bootFill, { Size = UDim2.fromScale(1, 1), BackgroundColor3 = library.Theme.Accent }, { Time = 0.35 })
	end
	Tween.Play(bootStatus, {
		Position = UDim2.new(0.5, 0, 0.5, 56),
		TextTransparency = 0,
	}, { Time = 0.3 })
	Tween.Play(bootPercent, {
		Position = UDim2.new(0.5, 0, 0.5, 74),
		TextTransparency = 0,
	}, { Time = 0.3 })

	bootStatus.Text = "Mounting interface…"
	bootPercent.Text = "100%"

	-- Rings fade in + spin
	Tween.Play(ringStroke1, { Transparency = 0.72 }, { Time = 0.5 })
	Tween.Play(ringStroke2, { Transparency = 0.82 }, { Time = 0.55 })
	Tween.Play(ringStroke3, { Transparency = 0.9 }, { Time = 0.6 })
	Tween.Play(bootBloom, {
		Size = UDim2.fromOffset(560, 560),
		BackgroundTransparency = 0.9,
	}, { Time = 0.7 })

	task.spawn(function()
		local t = 0
		while loadingGui.Parent do
			t += task.wait()
			ring1.Rotation = t * 28
			ring2.Rotation = -t * 18
			ring3.Rotation = t * 12
			for i, p in particles do
				local base = i / #particles
				local y = (base + t * 0.04 * (0.5 + (i % 3) * 0.2)) % 1.2 - 0.1
				local x = (0.15 + (i * 0.041) % 0.7) + math.sin(t * 0.8 + i) * 0.03
				p.Position = UDim2.fromScale(x, y)
				p.BackgroundTransparency = 0.35 + (y % 1) * 0.45
			end
		end
	end)

	local phases = {
		{ 0.55, "Hydrating theme…" },
		{ 0.72, "Wiring controls…" },
		{ 0.88, "Linking config…" },
		{ 1.00, "Ready" },
	}
	for _, phase in phases do
		local value, status = phase[1], phase[2]
		bootStatus.Text = status
		bootPercent.Text = tostring(math.floor(value * 100)) .. "%"
		if bootFill then
			Tween.Play(bootFill, { Size = UDim2.fromScale(value, 1) }, {
				Time = 0.22,
				EasingStyle = Enum.EasingStyle.Quint,
				EasingDirection = Enum.EasingDirection.Out,
			})
		end
		Tween.Play(logoScale, { Scale = 1.03 }, { Time = 0.1 })
		task.wait(0.1)
		Tween.Play(logoScale, { Scale = 1 }, { Time = 0.14 })
		task.wait(0.14)
	end
end)

return {
		BootGui = loadingGui,
		BootCard = bootCard,
		BootStatus = bootStatus,
		BootFill = bootFill,
		BootBloom = bootBloom,
		BootLogoScale = logoScale,
	}
end

function Window.new(library: any, options: WindowOptions?): WindowHandle
	local data = (typeof(options) == "table") and options or {}
	local self = setmetatable({
		Library = library,
		_Maid = Maid.new(),
		_Tabs = {} :: { any },
		_ActiveTab = nil :: any,
		_StartupTime = os.clock(),
	}, Window)

	local Players = game:GetService("Players")
	local localPlayer = Players.LocalPlayer and Players.LocalPlayer.Name or "Player"
	local UserInputService = game:GetService("UserInputService")
	local RunService = game:GetService("RunService")
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local sharedState = (getgenv and getgenv()) or _G

	-- Prefer the executor's hidden/CoreGui container when available. This gets
	-- CyberUI out of the normal PlayerGui layer and above most game UI.
	-- It still cannot guarantee drawing over Roblox's own pause/CoreGui menus.
	local function getTopGuiParent(): Instance
		local ok, hidden = pcall(function()
			if gethui then
				return gethui()
			end
			if get_hidden_gui then
				return get_hidden_gui()
			end
			return nil
		end)
		if ok and typeof(hidden) == "Instance" then
			return hidden
		end
		return playerGui
	end

	local topGuiParent = getTopGuiParent()
	self._TopGuiParent = topGuiParent

	-- ============================================
	-- CLICK SOUND
	-- ============================================
	self._SoundEnabled = true
	local clickSound = Instance.new("Sound")
	clickSound.Name = "VaxorinClick"
	clickSound.SoundId = CLICK_SOUND_ID
	clickSound.Volume = 0.35
	clickSound.Parent = SoundService
	self._Maid:Give(clickSound)

	local function playClick()
		if self._SoundEnabled then
			clickSound:Play()
		end
	end
	self._PlayClick = playClick

	-- Clean up old GUI in both PlayerGui and any hidden GUI container.
	for _, container in { playerGui, topGuiParent } do
		if typeof(container) == "Instance" then
			for _, child in container:GetChildren() do
				if child:IsA("ScreenGui") and child.Name == "Vaxorin" then
					child:Destroy()
				end
			end
		end
	end
	local oldBlur = Lighting:FindFirstChild("VaxorinBlur")
	if oldBlur then
		oldBlur:Destroy()
	end

	-- ============================================
	-- BACKGROUND BLUR ("acrylic" look behind the window)
	-- Off by default until the window is actually visible/enabled by the user,
	-- and always cleaned up on Destroy() so it never lingers in Lighting.
	-- ============================================
	self._BlurEnabled = false
	local blurEffect = Instance.new("BlurEffect")
	blurEffect.Name = "VaxorinBlur"
	blurEffect.Size = 0
	blurEffect.Enabled = true
	blurEffect.Parent = Lighting
	self._Maid:Give(blurEffect)
	self._BlurEffect = blurEffect

	local function applyBlurTarget()
		local targetSize = (self._BlurEnabled and self._Visible and not self._Minimized) and 14 or 0
		Tween.Play(blurEffect, { Size = targetSize }, { Time = 0.25 })
	end
	self._ApplyBlurTarget = applyBlurTarget

	-- Create main ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "Vaxorin"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	-- Maximum practical layering for game-created UI. When the executor exposes
	-- gethui/get_hidden_gui, use that container so CyberUI sits above normal
	-- PlayerGui ScreenGuis. 2147483647 is the maximum signed DisplayOrder.
	screenGui.DisplayOrder = data.DisplayOrder or 2147483647
	screenGui.IgnoreGuiInset = data.IgnoreGuiInset ~= false
	pcall(function()
		screenGui.ScreenInsets = Enum.ScreenInsets.None
	end)
	screenGui.Parent = topGuiParent
	self._Maid:Give(screenGui)

	-- Optional "top-most" mode: hide Roblox's normal in-game CoreGui so
	-- CyberUI remains above chat, player list, backpack, health, emotes, etc.
	-- The Roblox pause/menu layer itself cannot be covered by game UI.
	self._CoreUIState = nil
	if data.TopMost ~= false and data.HideCoreUI ~= false then
		local StarterGui = game:GetService("StarterGui")
		local GuiService = game:GetService("GuiService")
		local coreTypes = {
			Enum.CoreGuiType.PlayerList,
			Enum.CoreGuiType.Health,
			Enum.CoreGuiType.Backpack,
			Enum.CoreGuiType.Chat,
			Enum.CoreGuiType.EmotesMenu,
			Enum.CoreGuiType.SelfView,
			Enum.CoreGuiType.Captures,
			Enum.CoreGuiType.AvatarSwitcher,
		}
		self._CoreUIState = { Topbar = nil, Types = {} }
		for _, coreType in coreTypes do
			local ok, enabled = pcall(function()
				return StarterGui:GetCoreGuiEnabled(coreType)
			end)
			if ok then
				table.insert(self._CoreUIState.Types, { Type = coreType, Enabled = enabled })
				pcall(function() StarterGui:SetCoreGuiEnabled(coreType, false) end)
			end
		end
		pcall(function()
			self._CoreUIState.Topbar = true
			StarterGui:SetCore("TopbarEnabled", false)
		end)
		self._Maid:Give(function()
			for _, entry in self._CoreUIState and self._CoreUIState.Types or {} do
				pcall(function() StarterGui:SetCoreGuiEnabled(entry.Type, entry.Enabled) end)
			end
			if self._CoreUIState and self._CoreUIState.Topbar then
				pcall(function() StarterGui:SetCore("TopbarEnabled", true) end)
			end
		end)
		pcall(function()
			GuiService.GuiNavigationEnabled = true
		end)
	end

	local windowName = data.Name or data.Title or GUI_NAME
	local windowSubtitle = data.Subtitle or data.Description or nil -- nil = don't render a subtitle at all
	local windowSize = data.Size or data.WindowSize or Theme.WindowSize

	if typeof(windowSize) == "UDim2" then
		windowSize = Vector2.new(windowSize.X.Offset, windowSize.Y.Offset)
	elseif typeof(windowSize) == "number" then
		windowSize = Vector2.new(windowSize, windowSize)
	elseif typeof(windowSize) ~= "Vector2" then
		windowSize = Vector2.new(820, 540)
	end

	local showSearch = data.ShowSearch ~= false
	local showWindowControls = data.ShowWindowControls ~= false
	local topBarHeight = Theme.TopBarHeight or 72
	local infoBarHeight = 0 -- Vaxorin keeps the content area clean; optional info bar remains available internally

	-- Resize limits
	local minWindowSize = Vector2.new(640, 430)
	local maxWindowSize = Vector2.new(1180, 760)

	-- Keep the default window comfortably inside the current viewport. This is
	-- especially important on small emulator resolutions where a fixed desktop
	-- size can otherwise consume the entire screen.
	local camera = workspace.CurrentCamera
	local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
	local effectiveMinSize = Vector2.new(
		math.min(minWindowSize.X, viewport.X * 0.76),
		math.min(minWindowSize.Y, viewport.Y * 0.76)
	)
	local viewportMax = Vector2.new(
		viewport.X * 0.82,
		viewport.Y * 0.82
	)
	maxWindowSize = Vector2.new(
		math.max(effectiveMinSize.X, math.min(maxWindowSize.X, viewportMax.X)),
		math.max(effectiveMinSize.Y, math.min(maxWindowSize.Y, viewportMax.Y))
	)
	windowSize = Vector2.new(
		math.clamp(windowSize.X, effectiveMinSize.X, maxWindowSize.X),
		math.clamp(windowSize.Y, effectiveMinSize.Y, maxWindowSize.Y)
	)

	-- Cinematic boot (extracted to avoid Luau 200-local limit in Window.new)
	local bootRefs = startCinematicBoot({
		Library = library,
		Data = data,
		WindowName = windowName,
		ScreenGui = screenGui,
		SharedState = sharedState,
		Self = self,
	})
	if bootRefs then
		self._BootGui = bootRefs.BootGui
		self._BootCard = bootRefs.BootCard
		self._BootStatus = bootRefs.BootStatus
		self._BootFill = bootRefs.BootFill
		self._BootBloom = bootRefs.BootBloom
		self._BootLogoScale = bootRefs.BootLogoScale
		self._FirstReveal = true
	end

	-- ============================================
	-- MAIN WINDOW
	-- ============================================
	local main = Helpers.CreateFrame({
		Name = "Main",
		Size = UDim2.fromOffset(windowSize.X, windowSize.Y),
		Position = if data.Center ~= false then UDim2.fromScale(0.5, 0.5) else UDim2.fromOffset(40, 40),
		AnchorPoint = if data.Center ~= false then Vector2.new(0.5, 0.5) else Vector2.new(0, 0),
		BackgroundColor3 = library.Theme.Background,
		BackgroundTransparency = 0.03,
		Visible = false,
		Parent = screenGui,
	})
	Helpers.Corner(main, Theme.CornerRadius)
	local mainCorner = main:FindFirstChildOfClass("UICorner")
	local mainStroke = Helpers.Stroke(main, library.Theme.Border, 1)
	main.ClipsDescendants = true

	-- ============================================
	-- DROP SHADOW
	-- Parented as a sibling (not a child) of `main`, since `main` clips
	-- descendants and would cut the shadow off. Position/size stay in sync
	-- with `main` through cheap event-driven bindings, not a per-frame loop.
	-- ============================================
	local shadow = Instance.new("ImageLabel")
	shadow.Name = "MainShadow"
	shadow.BackgroundTransparency = 1
	shadow.Image = SHADOW_IMAGE
	shadow.ImageColor3 = Color3.new(0, 0, 0)
	shadow.ImageTransparency = 0.45
	shadow.ScaleType = Enum.ScaleType.Slice
	shadow.SliceCenter = SHADOW_SLICE_CENTER
	shadow.ZIndex = 0
	shadow.Parent = screenGui

	local function syncShadow()
		shadow.AnchorPoint = main.AnchorPoint
		shadow.Position = main.Position
		shadow.Size = UDim2.new(main.Size.X.Scale, main.Size.X.Offset + 46, main.Size.Y.Scale, main.Size.Y.Offset + 46)
		shadow.Visible = main.Visible
	end
	syncShadow()
	self._Maid:GiveTask(main:GetPropertyChangedSignal("Position"):Connect(syncShadow))
	self._Maid:GiveTask(main:GetPropertyChangedSignal("Size"):Connect(syncShadow))
	self._Maid:GiveTask(main:GetPropertyChangedSignal("Visible"):Connect(syncShadow))
	self._Maid:Give(shadow)

	-- True soft glow: use the same shadow texture as the drop shadow, tint it
	-- with the accent and keep it very transparent. This reads as light
	-- around the shell instead of a thicker purple border.
	local ambientGlow = Instance.new("ImageLabel")
	ambientGlow.Name = "AmbientGlow"
	ambientGlow.BackgroundTransparency = 1
	ambientGlow.BorderSizePixel = 0
	ambientGlow.Image = SHADOW_IMAGE
	ambientGlow.ImageColor3 = library.Theme.Accent
	ambientGlow.ImageTransparency = 0.86
	ambientGlow.ScaleType = Enum.ScaleType.Slice
	ambientGlow.SliceCenter = SHADOW_SLICE_CENTER
	ambientGlow.ZIndex = 0
	ambientGlow.Parent = screenGui
	local function syncAmbientGlow()
		ambientGlow.AnchorPoint = main.AnchorPoint
		ambientGlow.Position = main.Position
		ambientGlow.Size = UDim2.new(main.Size.X.Scale, main.Size.X.Offset + 28, main.Size.Y.Scale, main.Size.Y.Offset + 28)
		ambientGlow.Visible = main.Visible
	end
	syncAmbientGlow()
	self._Maid:GiveTask(main:GetPropertyChangedSignal("Position"):Connect(syncAmbientGlow))
	self._Maid:GiveTask(main:GetPropertyChangedSignal("Size"):Connect(syncAmbientGlow))
	self._Maid:GiveTask(main:GetPropertyChangedSignal("Visible"):Connect(syncAmbientGlow))
	self._Maid:Give(ambientGlow)

	local glowStroke = Instance.new("UIStroke")
	glowStroke.Name = "AccentEdge"
	glowStroke.Color = library.Theme.Accent
	glowStroke.Thickness = 1
	glowStroke.Transparency = 0.72
	glowStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	glowStroke.Parent = main
	self._Maid:Give(glowStroke)
	self._AmbientGlow = ambientGlow

	-- Background Image
	local backgroundImage = Instance.new("ImageLabel")
	backgroundImage.AnchorPoint = Vector2.new(0, 0)
	backgroundImage.Position = UDim2.new(0, 0, 0, 0)
	backgroundImage.Name = "BackgroundImage"
	backgroundImage.Size = UDim2.fromScale(1, 1)
	backgroundImage.BackgroundTransparency = 1
	backgroundImage.Image = data.BackgroundImage or ""
	backgroundImage.ImageTransparency = 0.66
	backgroundImage.ScaleType = Enum.ScaleType.Crop
	backgroundImage.ZIndex = 0
	backgroundImage.Parent = main
	Helpers.Corner(backgroundImage, Theme.CornerRadius)
	self._BackgroundImage = backgroundImage

	-- Overlay
	local overlay = Instance.new("Frame")
	overlay.Name = "BackgroundOverlay"
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = Color3.new(0, 0, 0)
	overlay.BackgroundTransparency = 0.56
	overlay.BorderSizePixel = 0
	overlay.ZIndex = 1
	overlay.Parent = main
	Helpers.Corner(overlay, Theme.CornerRadius)

	-- ============================================
	-- QUIET BACKDROP
	-- No floating circles, scanlines, or decorative geometry. The background
	-- image and a restrained vignette do the visual work.
	-- ============================================
	local atmosphere = Instance.new("Frame")
	atmosphere.Name = "Vignette"
	atmosphere.Size = UDim2.fromScale(1, 1)
	atmosphere.BackgroundTransparency = 0.94
	atmosphere.BackgroundColor3 = library.Theme.Background
	atmosphere.BorderSizePixel = 0
	atmosphere.ZIndex = 2
	atmosphere.Parent = main
	Helpers.Corner(atmosphere, Theme.CornerRadius)

	local atmosphereGradient = Instance.new("UIGradient")
	atmosphereGradient.Name = "VignetteGradient"
	atmosphereGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, library.Theme.Background),
		ColorSequenceKeypoint.new(0.48, Color3.new(1, 1, 1)),
		ColorSequenceKeypoint.new(1, library.Theme.Background),
	})
	atmosphereGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.12),
		NumberSequenceKeypoint.new(0.5, 0.92),
		NumberSequenceKeypoint.new(1, 0.12),
	})
	atmosphereGradient.Rotation = 0
	atmosphereGradient.Parent = atmosphere

	-- ============================================
	-- TOP BAR
	-- A clean product header with a fixed control zone. The left content can
	-- grow, but it can never occupy the close/minimize area.
	-- ============================================
	local topBar = Helpers.CreateFrame({
		Name = "TopBar",
		Size = UDim2.new(1, 0, 0, topBarHeight),
		Position = UDim2.fromOffset(0, 0),
		BackgroundColor3 = library.Theme.Secondary,
		BackgroundTransparency = 0.10,
		Active = true,
		Selectable = true,
		Parent = main,
	})
	topBar.ZIndex = 20
	local topBarCorner = Helpers.Corner(topBar, Theme.CornerRadius)

	local topBarGradient = Instance.new("UIGradient")
	topBarGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, library.Theme.Secondary),
		ColorSequenceKeypoint.new(0.55, library.Theme.Secondary),
		ColorSequenceKeypoint.new(1, library.Theme.Background),
	})
	topBarGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.02),
		NumberSequenceKeypoint.new(0.55, 0.06),
		NumberSequenceKeypoint.new(1, 0.16),
	})
	topBarGradient.Rotation = 0
	topBarGradient.Parent = topBar

	local topDivider = Instance.new("Frame")
	topDivider.Name = "Divider"
	topDivider.Size = UDim2.new(1, 0, 0, 1)
	topDivider.Position = UDim2.new(0, 0, 1, -1)
	topDivider.BackgroundColor3 = library.Theme.Border
	topDivider.BackgroundTransparency = 0.72
	topDivider.BorderSizePixel = 0
	topDivider.ZIndex = 30
	topDivider.Parent = topBar

	-- Subtle product-lighting details keep the header from feeling like a flat
	-- black block without turning it into a neon banner.
	local topAccentRail = Instance.new("Frame")
	topAccentRail.Name = "AccentRail"
	topAccentRail.Size = UDim2.new(0, 220, 0, 2)
	topAccentRail.Position = UDim2.new(0, 22, 1, -3)
	topAccentRail.BackgroundColor3 = library.Theme.Accent
	topAccentRail.BackgroundTransparency = 0.14
	topAccentRail.BorderSizePixel = 0
	topAccentRail.ZIndex = 31
	topAccentRail.Parent = topBar
	local topAccentGradient = Instance.new("UIGradient")
	topAccentGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, library.Theme.Accent),
		ColorSequenceKeypoint.new(0.65, library.Theme.AccentAlt or library.Theme.Accent),
		ColorSequenceKeypoint.new(1, library.Theme.Background),
	})
	topAccentGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.75, 0.18),
		NumberSequenceKeypoint.new(1, 1),
	})
	topAccentGradient.Parent = topAccentRail

	local topAmbient = Instance.new("Frame")
	topAmbient.Name = "AmbientLight"
	topAmbient.Size = UDim2.new(0.42, 0, 0, 3)
	topAmbient.Position = UDim2.new(0, 120, 1, -4)
	topAmbient.BackgroundColor3 = library.Theme.Accent
	topAmbient.BackgroundTransparency = 0.92
	topAmbient.BorderSizePixel = 0
	topAmbient.ZIndex = 30
	topAmbient.Parent = topBar

	local logoSize = Theme.LogoSize or 50
	local logoAsset = if data.Logo == nil or data.Logo == LEGACY_LOGO then Vaxorin_Logo else data.Logo

	local brand = Helpers.CreateFrame({
		Name = "Brand",
		Size = UDim2.new(0, 390, 1, 0),
		Position = UDim2.fromOffset(22, 0),
		BackgroundTransparency = 1,
		Parent = topBar,
	})

	local logoFrame = Helpers.CreateFrame({
		Name = "LogoFrame",
		Size = UDim2.fromOffset(logoSize + 4, logoSize + 4),
		Position = UDim2.new(0, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = library.Theme.Background,
		Parent = brand,
	})
	Helpers.Corner(logoFrame, 13)
	local logoStroke = Helpers.Stroke(logoFrame, library.Theme.BorderStrong or library.Theme.Border, 1)
	local logoAccentStroke = Helpers.Stroke(logoFrame, library.Theme.Accent, 1)
	logoAccentStroke.Transparency = 0.62

	local logoImage = Instance.new("ImageLabel")
	logoImage.Name = "Logo"
	logoImage.BackgroundTransparency = 1
	logoImage.Size = UDim2.fromScale(1, 1)
	logoImage.Position = UDim2.fromScale(0.5, 0.5)
	logoImage.AnchorPoint = Vector2.new(0.5, 0.5)
	logoImage.Image = logoAsset
	logoImage.ScaleType = Enum.ScaleType.Fit
	logoImage.ZIndex = 31
	logoImage.Parent = logoFrame
	Helpers.Corner(logoImage, 12)
	logoFrame.Active = true
	logoImage.Active = true

	local discordInvite = data.DiscordLink or "https://discord.gg/9jZTsy7Wtb"
	self._Maid:GiveTask(logoFrame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			playClick()
			if setclipboard then
				pcall(setclipboard, discordInvite)
			end
			self:Notify({
				Title = "Vaxorin",
				Content = "Discord invite copied to clipboard!",
				Type = "Success",
				Duration = 3,
			})
		end
	end))

	local titleContainer = Helpers.CreateFrame({
		Name = "TitleContainer",
		Size = UDim2.new(1, -(logoSize + 18), 1, 0),
		Position = UDim2.new(0, logoSize + 18, 0, 0),
		BackgroundTransparency = 1,
		Parent = brand,
	})
	local titleLayout = Instance.new("UIListLayout")
	titleLayout.FillDirection = Enum.FillDirection.Vertical
	titleLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	titleLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	titleLayout.Padding = UDim.new(0, 1)
	titleLayout.Parent = titleContainer

	local subtitle: TextLabel? = nil
	if windowSubtitle and windowSubtitle ~= "" then
		subtitle = Helpers.CreateLabel({
			Name = "Subtitle",
			Size = UDim2.new(1, 0, 0, 20),
			Text = windowSubtitle,
			Font = Theme.Font,
			TextColor3 = library.Theme.Accent,
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = titleContainer,
		})
		subtitle.ZIndex = 31
	end

	local title = Helpers.CreateLabel({
		Name = "Title",
		Size = UDim2.new(1, 0, 0, 34),
		Text = windowName,
		Font = Theme.FontBold,
		TextSize = 24,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = library.Theme.Text,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = titleContainer,
	})
	title.ZIndex = 31

	local productMeta = Helpers.CreateLabel({
		Name = "ProductMeta",
		Size = UDim2.new(1, 0, 0, 13),
		Position = UDim2.fromOffset(1, 57),
		Text = "VAXORIN  /  COMMAND CENTER  /  3.2",
		Font = Theme.FontBold,
		TextSize = 9,
		TextColor3 = library.Theme.TextMuted,
		TextTransparency = 0.18,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = titleContainer,
	})
	productMeta.ZIndex = 31

	local controlWidth = showWindowControls and 112 or 0
	local headerControlGap = showWindowControls and 20 or 14
	local brandWidth = 394

	-- Reserve a real rectangle for badges instead of letting an auto-sized
	-- container compete with the window controls. The badges are right-aligned
	-- inside that rectangle, so their right edge is always protected.
	local badgeHolder = Helpers.CreateFrame({
		Name = "Badges",
		Size = UDim2.new(1, -(brandWidth + controlWidth + headerControlGap + 16), 0, 34),
		Position = UDim2.new(0, brandWidth, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundTransparency = 1,
		ClipsDescendants = false,
		Parent = topBar,
	})
	badgeHolder.ZIndex = 31

	local badgeLayout = Instance.new("UIListLayout")
	badgeLayout.FillDirection = Enum.FillDirection.Horizontal
	badgeLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	badgeLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	badgeLayout.Padding = UDim.new(0, 8)
	badgeLayout.Parent = badgeHolder

	local badgeData = data.Badges or {
		{ Text = "Vaxorin", Color = library.Theme.Accent },
		{ Text = VERSION, Color = library.Theme.AccentAlt },
	}

	self._TopBadges = {}
	for i, badge in badgeData do
		local followTheme = badge.Color == nil
		local color = badge.Color or library.Theme.Accent
		local pill = Helpers.CreateFrame({
			Name = "Badge" .. i,
			Size = UDim2.new(0, 0, 0, 28),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundColor3 = color,
			BackgroundTransparency = 0.9,
			Parent = badgeHolder,
		})
		pill.ZIndex = 32
		pill:SetAttribute("FollowTheme", followTheme)
		Helpers.Corner(pill, 7)
		local badgeStroke = Helpers.Stroke(pill, color, 1)
		badgeStroke.Name = "BadgeStroke"
		badgeStroke.Transparency = 0.08
		local badgeGlow = Helpers.Stroke(pill, color, 2)
		badgeGlow.Name = "BadgeGlow"
		badgeGlow.Transparency = 0.88
		Helpers.Padding(pill, 9, 4)
		local badgeLabel = Helpers.CreateLabel({
			Name = "Label",
			Size = UDim2.new(0, 0, 1, 0),
			AutomaticSize = Enum.AutomaticSize.X,
			Text = badge.Text,
			Font = Theme.FontBold,
			TextSize = 11,
			TextColor3 = color,
			TextXAlignment = Enum.TextXAlignment.Center,
			Parent = pill,
		})
		badgeLabel.ZIndex = 33
		table.insert(self._TopBadges, {
			Pill = pill,
			Label = badgeLabel,
			Stroke = badgeStroke,
			Glow = badgeGlow,
			FollowTheme = followTheme,
			FixedColor = badge.Color,
		})
	end

	local minimizeButton, closeButton
	if showWindowControls then
		local controls = Helpers.CreateFrame({
			Name = "WindowControls",
			Size = UDim2.fromOffset(104, 44),
			Position = UDim2.new(1, -14, 0.5, 0),
			AnchorPoint = Vector2.new(1, 0.5),
			BackgroundTransparency = 1,
			Parent = topBar,
		})
		controls.ZIndex = 34
		local controlLayout = Instance.new("UIListLayout")
		controlLayout.FillDirection = Enum.FillDirection.Horizontal
		controlLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
		controlLayout.VerticalAlignment = Enum.VerticalAlignment.Center
		controlLayout.Padding = UDim.new(0, 8)
		controlLayout.Parent = controls

		minimizeButton = Instance.new("TextButton")
		minimizeButton.Name = "Minimize"
		minimizeButton.Size = UDim2.fromOffset(42, 42)
		minimizeButton.BackgroundColor3 = library.Theme.Background
		minimizeButton.BackgroundTransparency = 0.05
		minimizeButton.Text = "—"
		minimizeButton.Font = Theme.FontBold
		minimizeButton.TextSize = 18
		minimizeButton.TextColor3 = library.Theme.TextMuted
		minimizeButton.AutoButtonColor = false
		minimizeButton.ZIndex = 35
		minimizeButton.Parent = controls
		Helpers.Corner(minimizeButton, 10)
		Helpers.Stroke(minimizeButton, library.Theme.Border, 1)

		closeButton = Instance.new("TextButton")
		closeButton.Name = "Close"
		closeButton.Size = UDim2.fromOffset(42, 42)
		closeButton.BackgroundColor3 = library.Theme.Background
		closeButton.BackgroundTransparency = 0.05
		closeButton.Text = "×"
		closeButton.Font = Theme.Font
		closeButton.TextSize = 24
		closeButton.TextColor3 = library.Theme.TextMuted
		closeButton.AutoButtonColor = false
		closeButton.ZIndex = 35
		closeButton.Parent = controls
		Helpers.Corner(closeButton, 10)
		Helpers.Stroke(closeButton, library.Theme.Border, 1)

		self._Maid:GiveTask(closeButton.MouseEnter:Connect(function()
			Tween.Play(closeButton, { BackgroundColor3 = Color3.fromRGB(130, 45, 68), TextColor3 = Color3.new(1, 1, 1) }, { Time = 0.12 })
		end))
		self._Maid:GiveTask(closeButton.MouseLeave:Connect(function()
			Tween.Play(closeButton, { BackgroundColor3 = library.Theme.Background, TextColor3 = library.Theme.TextMuted }, { Time = 0.12 })
		end))
		self._Maid:GiveTask(minimizeButton.MouseEnter:Connect(function()
			Tween.Play(minimizeButton, { BackgroundColor3 = library.Theme.SurfaceHover, TextColor3 = library.Theme.Text }, { Time = 0.12 })
		end))
		self._Maid:GiveTask(minimizeButton.MouseLeave:Connect(function()
			Tween.Play(minimizeButton, { BackgroundColor3 = library.Theme.Background, TextColor3 = library.Theme.TextMuted }, { Time = 0.12 })
		end))
	end

	-- ============================================
	-- FLOATING BUTTON
	-- ============================================
	-- ============================================
	-- DYNAMIC ISLAND (open control — Deep Fishing style)
	-- Compact top-center pill; expands slightly on hover.
	-- ============================================
	local island = Instance.new("CanvasGroup")
	island.Name = "Island"
	island.Size = UDim2.fromOffset(168, 34)
	island.Position = UDim2.new(0.5, 0, 0, 10)
	island.AnchorPoint = Vector2.new(0.5, 0)
	island.BackgroundColor3 = Color3.fromRGB(30, 30, 34)
	island.BackgroundTransparency = 0
	island.BorderSizePixel = 0
	island.Visible = false
	island.ZIndex = 55
	island.Parent = screenGui
	Helpers.Corner(island, 16)
	local islandStroke = Helpers.Stroke(island, library.Theme.Border, 1)
	islandStroke.Transparency = 0.35
	self._IslandStroke = islandStroke

	local islandCompact = Helpers.CreateFrame({
		Name = "Compact",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(30, 30, 34),
		BackgroundTransparency = 0,
		Parent = island,
	})
	Helpers.Corner(islandCompact, 16)

	local islandIcon = Instance.new("ImageLabel")
	islandIcon.Name = "Icon"
	islandIcon.BackgroundTransparency = 1
	islandIcon.Size = UDim2.fromOffset(18, 18)
	islandIcon.Position = UDim2.new(0, 12, 0.5, 0)
	islandIcon.AnchorPoint = Vector2.new(0, 0.5)
	islandIcon.Image = logoAsset
	islandIcon.ScaleType = Enum.ScaleType.Fit
	islandIcon.ZIndex = 56
	islandIcon.Parent = islandCompact

	local islandTitle = Helpers.CreateLabel({
		Name = "Title",
		Size = UDim2.new(1, -70, 1, 0),
		Position = UDim2.fromOffset(36, 0),
		Text = "Vaxorin",
		Font = Theme.FontBold,
		TextSize = 12,
		TextColor3 = library.Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = islandCompact,
	})
	islandTitle.ZIndex = 56

	-- Accent bars (right side), like Deep Fishing island signal marks
	local bars = Helpers.CreateFrame({
		Name = "Bars",
		Size = UDim2.fromOffset(18, 16),
		Position = UDim2.new(1, -14, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundTransparency = 1,
		Parent = islandCompact,
	})
	bars.ZIndex = 56
	for i, h in ipairs({ 13, 15, 4, 4 }) do
		local bar = Instance.new("Frame")
		bar.Name = "Bar" .. i
		bar.Size = UDim2.fromOffset(3, h)
		bar.Position = UDim2.new(0, (i - 1) * 5, 0.5, 0)
		bar.AnchorPoint = Vector2.new(0, 0.5)
		bar.BackgroundColor3 = library.Theme.Accent
		bar.BorderSizePixel = 0
		bar.ZIndex = 57
		bar.Parent = bars
		Helpers.Corner(bar, 1)
	end

	local islandHit = Instance.new("TextButton")
	islandHit.Name = "Hit"
	islandHit.Size = UDim2.fromScale(1, 1)
	islandHit.BackgroundTransparency = 1
	islandHit.Text = ""
	islandHit.ZIndex = 58
	islandHit.Parent = island

	-- Keep legacy name so existing SetVisible logic still finds a toggle control
	local floatingButton = islandHit
	floatingButton.Name = "FloatingToggle"
	self._FloatingButton = island
	self._FloatingIcon = islandIcon
	self._IslandTitle = islandTitle
	self._IslandBars = bars
	self._IslandCompact = islandCompact

	-- Activity panel (hover info) — Deep Fishing style
	-- Clip host so the card appears to slide out of the island
	local islandActivityHost = Instance.new("Frame")
	islandActivityHost.Name = "ActivityHost"
	islandActivityHost.BackgroundTransparency = 1
	islandActivityHost.BorderSizePixel = 0
	islandActivityHost.ClipsDescendants = true
	islandActivityHost.Visible = false
	islandActivityHost.ZIndex = 59
	islandActivityHost.AnchorPoint = Vector2.new(0.5, 0)
	islandActivityHost.Size = UDim2.fromOffset(320, 0)
	islandActivityHost.Parent = screenGui
	self._IslandActivityHost = islandActivityHost

	local islandActivity = Instance.new("Frame")
	islandActivity.Name = "Activity"
	islandActivity.Size = UDim2.fromOffset(300, 148)
	islandActivity.Position = UDim2.new(0.5, 0, 0, 0)
	islandActivity.AnchorPoint = Vector2.new(0.5, 0)
	islandActivity.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
	islandActivity.BackgroundTransparency = 0.02
	islandActivity.Visible = true
	islandActivity.ZIndex = 60
	islandActivity.Parent = islandActivityHost
	Helpers.Corner(islandActivity, 14)
	Helpers.Stroke(islandActivity, library.Theme.Border, 1)
	Helpers.Padding(islandActivity, 12)

	-- Header row: avatar + name + session
	local actAvatar = Instance.new("ImageLabel")
	actAvatar.Name = "Avatar"
	actAvatar.Size = UDim2.fromOffset(32, 32)
	actAvatar.Position = UDim2.fromOffset(0, 0)
	actAvatar.BackgroundColor3 = library.Theme.ElementBackground
	actAvatar.BorderSizePixel = 0
	actAvatar.Image = ""
	actAvatar.ZIndex = 61
	actAvatar.Parent = islandActivity
	Helpers.Corner(actAvatar, 16)
	local lp = Players.LocalPlayer
	pcall(function()
		if lp then
			actAvatar.Image = Players:GetUserThumbnailAsync(
				lp.UserId,
				Enum.ThumbnailType.HeadShot,
				Enum.ThumbnailSize.Size48x48
			)
		end
	end)

	local actTitle = Helpers.CreateLabel({
		Name = "ActTitle",
		Size = UDim2.new(1, -100, 0, 16),
		Position = UDim2.fromOffset(40, 0),
		Text = (lp and (lp.DisplayName or lp.Name)) or tostring(localPlayer),
		Font = Theme.FontBold,
		TextSize = 13,
		TextColor3 = library.Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = islandActivity,
	})
	actTitle.ZIndex = 61

	local actGame = Helpers.CreateLabel({
		Name = "ActGame",
		Size = UDim2.new(1, -100, 0, 14),
		Position = UDim2.fromOffset(40, 16),
		Text = "Vaxorin",
		Font = Theme.Font,
		TextSize = 10,
		TextColor3 = library.Theme.TextMuted,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = islandActivity,
	})
	actGame.ZIndex = 61
	pcall(function()
		local info = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
		if info and info.Name then actGame.Text = info.Name end
	end)

	local actSession = Helpers.CreateLabel({
		Name = "ActSession",
		Size = UDim2.fromOffset(64, 16),
		Position = UDim2.new(1, 0, 0, 0),
		AnchorPoint = Vector2.new(1, 0),
		Text = "0m 0s",
		Font = Theme.FontBold,
		TextSize = 11,
		TextColor3 = library.Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = islandActivity,
	})
	actSession.ZIndex = 61

	local actSessionLbl = Helpers.CreateLabel({
		Name = "ActSessionLbl",
		Size = UDim2.fromOffset(64, 12),
		Position = UDim2.new(1, 0, 0, 16),
		AnchorPoint = Vector2.new(1, 0),
		Text = "session",
		Font = Theme.Font,
		TextSize = 9,
		TextColor3 = library.Theme.TextMuted,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = islandActivity,
	})
	actSessionLbl.ZIndex = 61

	-- FPS / Ping row
	local actFpsVal = Helpers.CreateLabel({
		Name = "ActFps",
		Size = UDim2.fromOffset(90, 18),
		Position = UDim2.fromOffset(0, 42),
		Text = "— fps",
		Font = Theme.FontBold,
		TextSize = 14,
		TextColor3 = Color3.fromRGB(120, 255, 160),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = islandActivity,
	})
	actFpsVal.ZIndex = 61
	local actFpsLbl = Helpers.CreateLabel({
		Name = "ActFpsLbl",
		Size = UDim2.fromOffset(90, 12),
		Position = UDim2.fromOffset(0, 58),
		Text = "FRAME RATE",
		Font = Theme.Font,
		TextSize = 8,
		TextColor3 = library.Theme.TextMuted,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = islandActivity,
	})
	actFpsLbl.ZIndex = 61

	local actPingVal = Helpers.CreateLabel({
		Name = "ActPing",
		Size = UDim2.fromOffset(90, 18),
		Position = UDim2.fromOffset(110, 42),
		Text = "— ms",
		Font = Theme.FontBold,
		TextSize = 14,
		TextColor3 = Color3.fromRGB(120, 255, 160),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = islandActivity,
	})
	actPingVal.ZIndex = 61
	local actPingLbl = Helpers.CreateLabel({
		Name = "ActPingLbl",
		Size = UDim2.fromOffset(90, 12),
		Position = UDim2.fromOffset(110, 58),
		Text = "PING",
		Font = Theme.Font,
		TextSize = 8,
		TextColor3 = library.Theme.TextMuted,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = islandActivity,
	})
	actPingLbl.ZIndex = 61

	-- Status chips row
	local chips = Helpers.CreateFrame({
		Name = "Chips",
		Size = UDim2.new(1, 0, 0, 20),
		Position = UDim2.fromOffset(0, 76),
		BackgroundTransparency = 1,
		Parent = islandActivity,
	})
	chips.ZIndex = 61
	local chipsLayout = Instance.new("UIListLayout")
	chipsLayout.FillDirection = Enum.FillDirection.Horizontal
	chipsLayout.Padding = UDim.new(0, 6)
	chipsLayout.Parent = chips

	local function makeChip(name: string, text: string): TextLabel
		local chip = Instance.new("TextLabel")
		chip.Name = name
		chip.AutomaticSize = Enum.AutomaticSize.X
		chip.Size = UDim2.fromOffset(0, 18)
		chip.BackgroundColor3 = library.Theme.ElementBackground or Color3.fromRGB(30, 30, 36)
		chip.BackgroundTransparency = 0.1
		chip.BorderSizePixel = 0
		chip.Font = Theme.Font
		chip.TextSize = 10
		chip.TextColor3 = library.Theme.Text
		chip.Text = text
		chip.ZIndex = 62
		chip.Parent = chips
		Helpers.Corner(chip, 6)
		local pad = Instance.new("UIPadding")
		pad.PaddingLeft = UDim.new(0, 8)
		pad.PaddingRight = UDim.new(0, 8)
		pad.Parent = chip
		return chip
	end
	local chipPlayers = makeChip("Players", "Players 0")
	local chipRunning = makeChip("Running", "Ready")
	local chipTab = makeChip("Tab", "Tab Home")

	local actDesc = Helpers.CreateLabel({
		Name = "ActDesc",
		Size = UDim2.new(1, 0, 0, 14),
		Position = UDim2.fromOffset(0, 100),
		Text = "Vaxorin",
		Font = Theme.Font,
		TextSize = 10,
		TextColor3 = library.Theme.TextMuted,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = islandActivity,
	})
	actDesc.ZIndex = 61

	local actHint = Helpers.CreateLabel({
		Name = "ActHint",
		Size = UDim2.new(1, 0, 0, 14),
		Position = UDim2.fromOffset(0, 118),
		Text = "Click or press RCtrl to open",
		Font = Theme.Font,
		TextSize = 10,
		TextColor3 = library.Theme.TextMuted,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = islandActivity,
	})
	actHint.ZIndex = 61

	self._IslandActivity = islandActivity
	self._IslandActStatus = chipRunning
	self._IslandActStats = actFpsVal
	self._IslandActFps = actFpsVal
	self._IslandActPing = actPingVal
	self._IslandActSession = actSession
	self._IslandActPlayers = chipPlayers
	self._IslandActTab = chipTab
	self._IslandActGame = actGame
	self._IslandActAvatar = actAvatar
	self._IslandSessionStart = os.clock()

	-- Classic circular open button (legacy)
	local classicBtn = Instance.new("ImageButton")
	classicBtn.Name = "ClassicOpen"
	classicBtn.Size = UDim2.fromOffset(50, 50)
	classicBtn.Position = UDim2.new(0, 43, 0.5, 0)
	classicBtn.AnchorPoint = Vector2.new(0, 0.5)
	classicBtn.BackgroundColor3 = library.Theme.Background
	classicBtn.BackgroundTransparency = 0
	classicBtn.Image = ""
	classicBtn.AutoButtonColor = false
	classicBtn.Visible = false
	classicBtn.ZIndex = 55
	classicBtn.Parent = screenGui
	Helpers.Corner(classicBtn, 12)
	local classicStroke = Helpers.Stroke(classicBtn, library.Theme.Border, 1.3)
	local classicIcon = Instance.new("ImageLabel")
	classicIcon.BackgroundTransparency = 1
	classicIcon.Size = UDim2.fromOffset(23, 23)
	classicIcon.Position = UDim2.fromScale(0.5, 0.5)
	classicIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	classicIcon.Image = logoAsset
	classicIcon.ScaleType = Enum.ScaleType.Fit
	classicIcon.ZIndex = 56
	classicIcon.Parent = classicBtn
	self._ClassicOpen = classicBtn
	self._ClassicStroke = classicStroke

	function self:_applyOpenStyle(style: string)
		style = style or "Island"
		self._OpenStyle = style
		local useIsland = style ~= "Button"
		if island then
			-- visibility controlled by SetVisible; just track preferred control
			island:SetAttribute("Preferred", useIsland)
		end
		if classicBtn then
			classicBtn:SetAttribute("Preferred", not useIsland)
		end
		-- If currently hidden UI, show the right control
		if not self._Visible and self._StartupComplete then
			if useIsland then
				island.Visible = true
				classicBtn.Visible = false
				self._FloatingButton = island
			else
				island.Visible = false
				classicBtn.Visible = true
				self._FloatingButton = classicBtn
			end
		end
	end

	-- Island hover → separate info card (island itself stays the same size)
	local activityScale = Instance.new("UIScale")
	activityScale.Name = "Pop"
	activityScale.Scale = 0.9
	activityScale.Parent = islandActivity

	local ACTIVITY_H = 160
	local activityFollowConn = nil :: RBXScriptConnection?

	local function placeActivityHost()
		local host = self._IslandActivityHost or islandActivityHost
		if not host then return end
		-- Follow island Position (works after drag) in the same ScreenGui space
		local yOff = island.Position.Y.Offset + island.AbsoluteSize.Y + 10
		host.AnchorPoint = Vector2.new(0.5, 0)
		host.Position = UDim2.new(
			island.Position.X.Scale,
			island.Position.X.Offset,
			island.Position.Y.Scale,
			yOff
		)
	end

	local function showIslandActivity()
		local host = self._IslandActivityHost or islandActivityHost
		placeActivityHost()
		host.Size = UDim2.fromOffset(320, 0)
		host.Visible = true
		islandActivity.BackgroundColor3 = library.Theme.Secondary or Color3.fromRGB(18, 18, 22)
		if actTitle then actTitle.TextColor3 = library.Theme.Text end
		if actGame then actGame.TextColor3 = library.Theme.TextMuted end
		if actHint then actHint.TextColor3 = library.Theme.TextMuted end
		if actFpsVal then actFpsVal.TextColor3 = Color3.fromRGB(120, 255, 160) end
		if actPingVal then actPingVal.TextColor3 = Color3.fromRGB(120, 255, 160) end
		islandActivity.Position = UDim2.new(0.5, 0, 0, 0)
		Tween.Play(host, { Size = UDim2.fromOffset(320, ACTIVITY_H) }, { Time = 0.22, EasingStyle = Enum.EasingStyle.Quint })
		if activityFollowConn then activityFollowConn:Disconnect() end
		activityFollowConn = game:GetService("RunService").RenderStepped:Connect(function()
			if host.Visible then
				placeActivityHost()
			end
		end)
		self._Maid:GiveTask(activityFollowConn)
		for _, bar in bars:GetChildren() do
			if bar:IsA("Frame") then
				Tween.Play(bar, { BackgroundColor3 = library.Theme.AccentAlt or library.Theme.Accent }, { Time = 0.12 })
			end
		end
	end

	local function hideIslandActivity()
		local host = self._IslandActivityHost
		if not host or not host.Visible then
			return
		end
		if activityFollowConn then
			activityFollowConn:Disconnect()
			activityFollowConn = nil
		end
		Tween.Play(host, { Size = UDim2.fromOffset(320, 0) }, { Time = 0.16, EasingStyle = Enum.EasingStyle.Quint })
		task.delay(0.16, function()
			if host then host.Visible = false end
		end)
		for _, bar in bars:GetChildren() do
			if bar:IsA("Frame") then
				Tween.Play(bar, { BackgroundColor3 = library.Theme.Accent }, { Time = 0.12 })
			end
		end
	end

	self._Maid:GiveTask(islandHit.MouseEnter:Connect(showIslandActivity))

	self._Maid:GiveTask(classicBtn.MouseEnter:Connect(function()
		Tween.Play(classicBtn, { BackgroundColor3 = library.Theme.SurfaceHover }, { Time = 0.12 })
	end))
	self._Maid:GiveTask(classicBtn.MouseLeave:Connect(function()
		Tween.Play(classicBtn, { BackgroundColor3 = library.Theme.Background }, { Time = 0.12 })
	end))
	self._Maid:GiveTask(classicBtn.MouseButton1Click:Connect(function()
		playClick()
		self:SetVisible(true)
	end))

	-- Live stats for island activity (always running)
	self._LiveFps = 0
	self._LivePing = 0
	do
		local frames, last = 0, os.clock()
		self._Maid:GiveTask(game:GetService("RunService").RenderStepped:Connect(function()
			frames += 1
			local now = os.clock()
			if now - last >= 0.4 then
				self._LiveFps = math.floor(frames / (now - last) + 0.5)
				frames = 0
				last = now
			end
		end))
		self._Maid:GiveTask(task.spawn(function()
			while true do
				local ping = 0
				pcall(function()
					local okFps = workspace:GetRealPhysicsFPS()
					if typeof(okFps) == "number" and okFps > 0 and (self._LiveFps or 0) < 1 then
						self._LiveFps = math.floor(okFps + 0.5)
					end
				end)
				pcall(function()
					local item = Stats.Network.ServerStatsItem["Data Ping"]
					if item and item.GetValue then
						ping = math.floor((item:GetValue() or 0) + 0.5)
					end
				end)
				if ping == 0 then
					pcall(function()
						local localPlayer = game:GetService("Players").LocalPlayer
						if localPlayer and localPlayer.GetNetworkPing then
							ping = math.floor(localPlayer:GetNetworkPing() * 1000 + 0.5)
						end
					end)
				end
				self._LivePing = ping
				local fps = self._LiveFps or 0
				local ping = self._LivePing or 0
				if self._IslandActFps then
					self._IslandActFps.Text = string.format("%d fps", fps)
				elseif self._IslandActStats then
					self._IslandActStats.Text = string.format("%d fps", fps)
				end
				if self._IslandActPing then
					self._IslandActPing.Text = string.format("%d ms", ping)
				end
				if self._IslandActSession and self._IslandSessionStart then
					local sec = math.floor(os.clock() - self._IslandSessionStart)
					local m = math.floor(sec / 60)
					local s = sec % 60
					self._IslandActSession.Text = string.format("%dm %02ds", m, s)
				end
				if self._IslandActPlayers then
					self._IslandActPlayers.Text = string.format("Players %d/%d", #Players:GetPlayers(), Players.MaxPlayers)
				end
				if self._IslandActTab and self._ActiveTab then
					local n = self._ActiveTab.Name or self._ActiveTab._Name or "Home"
					self._IslandActTab.Text = "Tab " .. tostring(n)
				end
				if self._IslandActStatus then
					local st = "Ready"
					if self._FooterStatus and self._FooterStatus.Text and self._FooterStatus.Text ~= "" then
						st = self._FooterStatus.Text
					end
					self._IslandActStatus.Text = st
				end
				task.wait(0.35)
			end
		end))
	end


	self._Maid:GiveTask(islandHit.MouseLeave:Connect(function()
		task.delay(0.12, function()
			-- stay open if pointer moved onto the revealed card
		end)
		hideIslandActivity()
	end))
	islandActivityHost.Active = true
	self._Maid:GiveTask(islandActivityHost.MouseEnter:Connect(function()
		local host = self._IslandActivityHost
		if host then host.Visible = true end
	end))
	self._Maid:GiveTask(islandActivityHost.MouseLeave:Connect(hideIslandActivity))

	-- Drag-vs-click distinction: only treat it as a "toggle" click if the pointer
	-- barely moved. Previously any drag would also fire SetVisible(true) on release.
	local FLOAT_CLICK_THRESHOLD = 4
	local floatMovedDistance = 0

	self._FloatDragging = false
	self._FloatDragStart = Vector2.new()
	self._FloatStart = UDim2.new()
	self._FloatDragInputType = nil :: Enum.UserInputType?

	self._Maid:GiveTask(floatingButton.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			self._FloatDragging = true
			self._FloatDragStart = input.Position
			local target = self._FloatingButton or floatingButton
			self._FloatStart = target.Position
			self._FloatDragInputType = input.UserInputType
			floatMovedDistance = 0
		end
	end))

	self._Maid:GiveTask(UserInputService.InputChanged:Connect(function(input)
		if not self._FloatDragging or self._FloatDragInputType == nil then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			local delta = input.Position - self._FloatDragStart
			floatMovedDistance = delta.Magnitude
			local target = self._FloatingButton or floatingButton
			target.Position = UDim2.new(
				self._FloatStart.X.Scale,
				self._FloatStart.X.Offset + delta.X,
				self._FloatStart.Y.Scale,
				self._FloatStart.Y.Offset + delta.Y
			)
		end
	end))

	self._Maid:GiveTask(UserInputService.InputEnded:Connect(function(input)
		if self._FloatDragInputType ~= nil and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			self._FloatDragging = false
			self._FloatDragInputType = nil
			if floatMovedDistance <= FLOAT_CLICK_THRESHOLD then
				playClick()
				self:SetVisible(true)
			end
		end
	end))

	self._Maid:Give(island)
	-- Weather layer on full ScreenGui so particles are always visible
	self._Weather = createWeather(screenGui)
	self._Weather:SetParentTargets(screenGui, main)
	self._WeatherKind = "None"
	self._WeatherScope = "Screen"
	self._OpenStyle = "Island" -- or "Button"

	-- Dim in SEPARATE ScreenGui with lower DisplayOrder — never covers Vaxorin UI
	local dimGui = Instance.new("ScreenGui")
	dimGui.Name = "VaxorinDimGui"
	dimGui.ResetOnSpawn = false
	dimGui.IgnoreGuiInset = true
	dimGui.DisplayOrder = math.max(0, (screenGui.DisplayOrder or 100) - 20)
	dimGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	dimGui.Parent = screenGui.Parent
	self._DimGui = dimGui

	local dim = Instance.new("Frame")
	dim.Name = "VaxorinDim"
	dim.Size = UDim2.fromScale(1, 1)
	dim.BackgroundColor3 = Color3.new(0, 0, 0)
	dim.BackgroundTransparency = 1
	dim.BorderSizePixel = 0
	dim.Active = false
	dim.Visible = true
	dim.Parent = dimGui
	self._Dim = dim
	self._DimAmount = self._DimAmount or 0.45

	main.ZIndex = 50
	screenGui.DisplayOrder = math.max(screenGui.DisplayOrder or 100, dimGui.DisplayOrder + 20)

	-- Window open/close scale
	local mainScale = Instance.new("UIScale")
	mainScale.Name = "OpenScale"
	mainScale.Scale = 1
	mainScale.Parent = main
	self._MainScale = mainScale


	-- ============================================
	-- WATERMARK (compact draggable FPS / Ping / Uptime pill)
	-- Off by default, toggled from Options -> General.
	-- ============================================
	self._WatermarkEnabled = false

	local watermark = Helpers.CreateFrame({
		Name = "Watermark",
		Size = UDim2.new(0, 0, 0, 30),
		AutomaticSize = Enum.AutomaticSize.X,
		Position = UDim2.new(1, -18, 1, -18),
	AnchorPoint = Vector2.new(1, 1),
		BackgroundColor3 = library.Theme.Secondary,
		BackgroundTransparency = 0.1,
		Visible = false,
		Parent = screenGui,
	})
	watermark.ZIndex = 40
	Helpers.Corner(watermark, 9)
	local watermarkStroke = Helpers.Stroke(watermark, library.Theme.Border, 1)
	Helpers.Padding(watermark, 12, 0)

	local watermarkLayout = Instance.new("UIListLayout")
	watermarkLayout.FillDirection = Enum.FillDirection.Horizontal
	watermarkLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	watermarkLayout.Padding = UDim.new(0, 12)
	watermarkLayout.Parent = watermark

	local function watermarkStat(labelText: string)
		local lbl = Helpers.CreateLabel({
			Name = labelText:gsub("[^%w]", "") .. "Stat",
			Size = UDim2.new(0, 0, 1, 0),
			AutomaticSize = Enum.AutomaticSize.X,
			Text = labelText,
			Font = Theme.FontBold,
			TextSize = 12,
			TextColor3 = library.Theme.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = watermark,
		})
		return lbl
	end

	local watermarkDot = Instance.new("Frame")
	watermarkDot.Name = "AccentDot"
	watermarkDot.Size = UDim2.fromOffset(6, 6)
	watermarkDot.BackgroundColor3 = library.Theme.Accent
	watermarkDot.BorderSizePixel = 0
	watermarkDot.Parent = watermark
	Helpers.Corner(watermarkDot, 999)

	local watermarkTitle = watermarkStat(windowName)
	watermarkTitle.TextColor3 = library.Theme.Accent
	local watermarkFps = watermarkStat("60 FPS")
	local watermarkPing = watermarkStat("0 ms")
	local watermarkUptime = watermarkStat("00:00:00")

	-- Simple drag support, matching the floating button's behavior.
	local wmDragging = false
	local wmDragStart = Vector2.new()
	local wmStart = UDim2.new()
	local wmDragInputType = nil :: Enum.UserInputType?

	self._Maid:GiveTask(watermark.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			wmDragging = true
			wmDragStart = input.Position
			wmStart = watermark.Position
			wmDragInputType = input.UserInputType
		end
	end))
	self._Maid:GiveTask(UserInputService.InputChanged:Connect(function(input)
		if not wmDragging or wmDragInputType == nil then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			local delta = input.Position - wmDragStart
			watermark.Position = UDim2.new(
				wmStart.X.Scale, wmStart.X.Offset + delta.X,
				wmStart.Y.Scale, wmStart.Y.Offset + delta.Y
			)
		end
	end))
	self._Maid:GiveTask(UserInputService.InputEnded:Connect(function(input)
		if wmDragInputType ~= nil and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			wmDragging = false
			wmDragInputType = nil
		end
	end))

	local wmFrameCount = 0
	local wmFrameAccumulator = 0
	local wmRefreshAccumulator = 0

	self._Maid:GiveTask(RunService.Heartbeat:Connect(function(dt)
		if not self._WatermarkEnabled then
			return
		end
		wmFrameCount += 1
		wmFrameAccumulator += dt
		wmRefreshAccumulator += dt

		if wmRefreshAccumulator >= WATERMARK_REFRESH_INTERVAL then
			local fps = wmFrameAccumulator > 0 and math.round(wmFrameCount / wmFrameAccumulator) or 0
			wmFrameCount = 0
			wmFrameAccumulator = 0
			wmRefreshAccumulator = 0

			watermarkFps.Text = tostring(fps) .. " FPS"

			local ok, pingMs = pcall(function()
				local network = Stats.Network
				local ping = network:FindFirstChild("ServerStatsItem") and network.ServerStatsItem:FindFirstChild("Data Ping")
				return ping and math.round(ping:GetValue()) or 0
			end)
			watermarkPing.Text = (ok and pingMs or 0) .. " ms"

			local uptime = os.clock() - self._StartupTime
			local hours = math.floor(uptime / 3600)
			local minutes = math.floor((uptime % 3600) / 60)
			local seconds = math.floor(uptime % 60)
			watermarkUptime.Text = string.format("%02d:%02d:%02d", hours, minutes, seconds)
		end
	end))

	self._Maid:Give(watermark)
	self._Watermark = watermark

	function self:SetWatermarkEnabled(enabled: boolean)
		self._WatermarkEnabled = enabled
		watermark.Visible = enabled
	end

	-- ============================================
	-- WINDOW DRAGGING
	-- ============================================
	local dragging = false
	local dragStart = Vector2.new()
	local windowStart = UDim2.new()
	local dragInputType = nil :: Enum.UserInputType?

	self._Maid:GiveTask(topBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			windowStart = main.Position
			dragInputType = input.UserInputType
		end
	end))

	self._Maid:GiveTask(UserInputService.InputChanged:Connect(function(input)
		if not dragging or dragInputType == nil then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			local delta = input.Position - dragStart
			main.Position = UDim2.new(
				windowStart.X.Scale,
				windowStart.X.Offset + delta.X,
				windowStart.Y.Scale,
				windowStart.Y.Offset + delta.Y
			)
		end
	end))

	self._Maid:GiveTask(UserInputService.InputEnded:Connect(function(input)
		if dragInputType ~= nil and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			dragging = false
			dragInputType = nil
			-- Remember where the user left the window
			self._MainBasePos = main.Position
			if self.Library and self.Library.SetSession then
				pcall(function()
					self.Library:SetSession("WindowPos", {
						XS = main.Position.X.Scale,
						XO = main.Position.X.Offset,
						YS = main.Position.Y.Scale,
						YO = main.Position.Y.Offset,
					})
				end)
			end
		end
	end))

	-- ============================================
	-- RESIZE HANDLE
	-- ============================================
	local resizeHandle = Instance.new("Frame")
	resizeHandle.Name = "ResizeHandle"
	resizeHandle.Size = UDim2.fromOffset(16, 16)
	resizeHandle.Position = UDim2.new(1, -4, 1, -4)
	resizeHandle.AnchorPoint = Vector2.new(1, 1)
	resizeHandle.BackgroundTransparency = 1
	resizeHandle.Active = true
	resizeHandle.Selectable = true
	resizeHandle.ZIndex = 25
	resizeHandle.Parent = main

	for i = 1, 3 do
		local line = Instance.new("Frame")
		line.Name = "Line" .. i
		line.Size = UDim2.fromOffset(2, 2 + i * 3)
		line.Position = UDim2.new(1, -4 - (i * 5), 1, -4)
		line.AnchorPoint = Vector2.new(1, 1)
		line.BackgroundColor3 = library.Theme.TextMuted
		line.BorderSizePixel = 0
		line.Rotation = 45
		line.ZIndex = 26
		line.Parent = resizeHandle
	end

	local resizing = false
	local resizeStart = Vector2.new()
	local sizeStart = UDim2.new()
	local resizeInputType = nil :: Enum.UserInputType?

	self._Maid:GiveTask(resizeHandle.InputBegan:Connect(function(input)
		if self._Minimized then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			resizing = true
			resizeStart = input.Position
			sizeStart = main.Size
			resizeInputType = input.UserInputType
		end
	end))

	self._Maid:GiveTask(UserInputService.InputChanged:Connect(function(input)
		if not resizing or resizeInputType == nil then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			local delta = input.Position - resizeStart
			local newX = math.clamp(sizeStart.X.Offset + delta.X, minWindowSize.X, maxWindowSize.X)
			local newY = math.clamp(sizeStart.Y.Offset + delta.Y, minWindowSize.Y, maxWindowSize.Y)
			main.Size = UDim2.fromOffset(newX, newY)
			-- Keep windowSize in sync so un-minimizing restores the resized dimensions
			-- instead of snapping back to the original startup size.
			windowSize = Vector2.new(newX, newY)
		end
	end))

	self._Maid:GiveTask(UserInputService.InputEnded:Connect(function(input)
		if resizeInputType ~= nil and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			resizing = false
			resizeInputType = nil
		end
	end))

	self._Maid:GiveTask(resizeHandle.MouseEnter:Connect(function()
		for _, line in resizeHandle:GetChildren() do
			Tween.Play(line, { BackgroundColor3 = library.Theme.Accent }, { Time = 0.12 })
		end
	end))
	self._Maid:GiveTask(resizeHandle.MouseLeave:Connect(function()
		for _, line in resizeHandle:GetChildren() do
			Tween.Play(line, { BackgroundColor3 = library.Theme.TextMuted }, { Time = 0.12 })
		end
	end))

	self._ResizeHandle = resizeHandle

	-- ============================================
	-- CONTENT AREA
	-- ============================================
	local contentArea = Helpers.CreateFrame({
		Name = "ContentArea",
		Size = UDim2.new(1, 0, 1, -topBarHeight),
		Position = UDim2.new(0, 0, 0, topBarHeight),
		BackgroundTransparency = 1,
		Parent = main,
	})
	contentArea.ZIndex = 10

	-- Small status capsule in the new header/content gutter. It provides a
	-- deliberate visual transition so the cards do not begin directly under the
	-- top bar, while remaining independent from the page layout.
	local statusRibbon = Helpers.CreateFrame({
		Name = "StatusRibbon",
		Size = UDim2.fromOffset(190, 28),
		Position = UDim2.new(1, -130, 0, 7),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = library.Theme.Surface,
		BackgroundTransparency = 0.08,
		Parent = contentArea,
	})
	statusRibbon.ZIndex = 50
	Helpers.Corner(statusRibbon, 9)
	local statusStroke = Helpers.Stroke(statusRibbon, library.Theme.BorderStrong or library.Theme.Border, 1)
	statusStroke.Transparency = 0.18
	local statusGlow = Helpers.Stroke(statusRibbon, library.Theme.Accent, 1)
	statusGlow.Transparency = 0.86

	local statusDot = Instance.new("Frame")
	statusDot.Name = "Dot"
	statusDot.Size = UDim2.fromOffset(6, 6)
	statusDot.Position = UDim2.fromOffset(12, 11)
	statusDot.BackgroundColor3 = library.Theme.Success
	statusDot.BorderSizePixel = 0
	statusDot.Parent = statusRibbon
	Helpers.Corner(statusDot, 3)

	Helpers.CreateLabel({
		Name = "Text",
		Size = UDim2.new(1, -30, 1, 0),
		Position = UDim2.fromOffset(26, 0),
		Text = "VAXORIN  •  READY",
		Font = Theme.FontBold,
		TextSize = 9,
		TextColor3 = library.Theme.TextMuted,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = statusRibbon,
	})

	self._StatusRibbon = statusRibbon
	self._StatusStroke = statusStroke
	self._StatusGlow = statusGlow
	self._StatusDot = statusDot
	self._ProductMeta = productMeta

	-- Sidebar
	local sidebar = Helpers.CreateFrame({
		Name = "Sidebar",
		Size = UDim2.new(0, Theme.SidebarWidth, 1, 0),
		Position = UDim2.fromOffset(0, 0),
		BackgroundColor3 = library.Theme.Secondary,
		BackgroundTransparency = 0,
		Parent = contentArea,
	})
	local sidebarCorner = Helpers.Corner(sidebar, Theme.CornerRadius)
	sidebar.ClipsDescendants = true
	sidebar.ZIndex = 10
	Helpers.Padding(sidebar, 16)


	local navLabel = Helpers.CreateLabel({
		Name = "NavigationLabel",
		Size = UDim2.new(1, 0, 0, 16),
		Position = UDim2.new(0, 0, 0, if showSearch then 50 else 8),
		Text = "WORKSPACE",
		Font = Theme.FontBold,
		TextSize = 10,
		TextColor3 = library.Theme.TextMuted,
		TextTransparency = 0.12,
		Parent = sidebar,
	})

	local searchBox
	local searchIconStroke
	local searchIconHandle
	local searchTop = 0
	if showSearch then
		local searchHolder = Helpers.CreateFrame({
			Name = "SearchHolder",
			Size = UDim2.new(1, 0, 0, 40),
			Position = UDim2.fromOffset(0, 0),
			BackgroundColor3 = library.Theme.Background,
			BackgroundTransparency = 0.02,
			Parent = sidebar,
		})
		Helpers.Corner(searchHolder, Theme.CornerRadiusSmall)
		local searchStroke = Helpers.Stroke(searchHolder, library.Theme.Border, 1)
		searchStroke.Transparency = 0.28
		self._SearchHolder = searchHolder
		self._SearchStroke = searchStroke

		local searchIcon, searchIconStroke, searchIconHandle = createMagnifier(searchHolder, library.Theme)

		searchBox = Instance.new("TextBox")
		searchBox.Name = "SearchBox"
		searchBox.Size = UDim2.new(1, -46, 1, 0)
		searchBox.Position = UDim2.fromOffset(40, 0)
		searchBox.BackgroundTransparency = 1
		searchBox.PlaceholderText = "Search..."
		searchBox.Text = ""
		searchBox.Font = Theme.Font
		searchBox.TextSize = 13
		searchBox.TextColor3 = library.Theme.Text
		searchBox.PlaceholderColor3 = library.Theme.TextMuted
		searchBox.TextXAlignment = Enum.TextXAlignment.Left
		searchBox.ClearTextOnFocus = false
		searchBox.Parent = searchHolder
		searchTop = 62
	else
		searchTop = 28
	end

	local searchResults = Helpers.CreateFrame({
		Name = "SearchResults",
		Size = UDim2.new(1, 0, 0, 0),
		Position = UDim2.fromOffset(0, if showSearch then 48 else 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Visible = false,
		BackgroundColor3 = library.Theme.Surface,
		BackgroundTransparency = 0.02,
		ZIndex = 60,
		Parent = sidebar,
	})
	Helpers.Corner(searchResults, Theme.CornerRadiusSmall)
	local searchResultsStroke = Helpers.Stroke(searchResults, library.Theme.Border, 1)
	searchResultsStroke.Transparency = 0.16
	Helpers.Padding(searchResults, 6, 6)
	local searchResultsLayout = Helpers.ListLayout(searchResults, 4)
	searchResultsLayout.SortOrder = Enum.SortOrder.LayoutOrder

	self._SearchResults = searchResults
	self._SearchResultsStroke = searchResultsStroke

	local footerHeight = 68
	local tabList = Instance.new("ScrollingFrame")
	tabList.Name = "TabList"
	tabList.Size = UDim2.new(1, 0, 1, -(searchTop + footerHeight + 12))
	tabList.Position = UDim2.new(0, 0, 0, searchTop)
	tabList.BackgroundTransparency = 1
	tabList.BorderSizePixel = 0
	tabList.Active = true
	tabList.ScrollingEnabled = true
	tabList.ScrollingDirection = Enum.ScrollingDirection.Y
	tabList.ScrollBarThickness = 2
	tabList.ScrollBarImageColor3 = library.Theme.Accent
	tabList.ScrollBarImageTransparency = 0.75
	tabList.AutomaticCanvasSize = Enum.AutomaticSize.Y
	tabList.CanvasSize = UDim2.new()
	tabList.ClipsDescendants = true
	tabList.Parent = sidebar
	local tabLayout = Helpers.ListLayout(tabList, 5)
	tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left

	local footer = Helpers.CreateFrame({
		Name = "FooterBar",
		Size = UDim2.new(1, 0, 0, footerHeight),
		Position = UDim2.new(0, 0, 1, -footerHeight),
		BackgroundColor3 = library.Theme.ElementBackground or library.Theme.Secondary,
		BackgroundTransparency = 0,
		Parent = sidebar,
	})
	Helpers.Corner(footer, Theme.CornerRadiusSmall)
	local footerStroke = Helpers.Stroke(footer, library.Theme.BorderStrong or library.Theme.Border, 1)
	footerStroke.Transparency = 0.05
	self._Footer = footer
	self._FooterStroke = footerStroke
	local footerAccent = Instance.new("Frame")
	footerAccent.Name = "FooterAccent"
	footerAccent.Size = UDim2.new(1, 0, 0, 2)
	footerAccent.Position = UDim2.fromOffset(0, 0)
	footerAccent.BackgroundColor3 = library.Theme.Accent
	footerAccent.BorderSizePixel = 0
	footerAccent.ZIndex = 2
	footerAccent.Parent = footer
	self._FooterAccent = footerAccent

	local avatarImage = Instance.new("ImageLabel")
	avatarImage.Name = "Avatar"
	local defaultAvatar = ""
	pcall(function()
		local image, ready = Players:GetUserThumbnailAsync(Players.LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
		if ready then defaultAvatar = image end
	end)
	avatarImage.Size = UDim2.fromOffset(42, 42)
	avatarImage.Position = UDim2.fromOffset(10, 17)
	avatarImage.BackgroundTransparency = 1
	avatarImage.Image = if data.Footer and data.Footer.Avatar then data.Footer.Avatar else defaultAvatar
	avatarImage.ScaleType = Enum.ScaleType.Crop
	avatarImage.Parent = footer
	Helpers.Corner(avatarImage, 22)
	Helpers.Stroke(avatarImage, library.Theme.BorderStrong or library.Theme.Border, 1)

	local footerName = Helpers.CreateLabel({
		Name = "WelcomeLabel",
		Size = UDim2.new(1, -62, 0, 18),
		Position = UDim2.fromOffset(58, 12),
		Text = "Welcome, " .. (data.Footer and data.Footer.Username or localPlayer),
		TextTruncate = Enum.TextTruncate.AtEnd,
		Font = Theme.FontBold,
		TextSize = 11,
		TextColor3 = library.Theme.Text,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = footer,
	})

	local footerStatus = Helpers.CreateLabel({
		Name = "Status",
		Size = UDim2.new(1, -62, 0, 17),
		Position = UDim2.fromOffset(58, 35),
		Text = (data.Footer and (data.Footer.Status or data.Footer.Role or data.Footer.Badge)) or "Premium User",
		Font = Theme.FontBold,
		TextSize = 11,
		TextColor3 = library.Theme.Accent,
		Parent = footer,
	})

	-- ============================================
	-- PAGES
	-- ============================================
	local pages = Instance.new("Frame")
	pages.Name = "Pages"
	pages.Position = UDim2.new(0, Theme.SidebarWidth, 0, 0)
	pages.Size = UDim2.new(1, -Theme.SidebarWidth, 1, 0)
	pages.BackgroundTransparency = 1
	pages.BorderSizePixel = 0
	pages.ClipsDescendants = true
	pages.ZIndex = 10
	pages.Parent = contentArea

	-- ============================================
	-- INFO BAR (bottom of main)
	-- ============================================
	local infoBar = Helpers.CreateFrame({
		Name = "InfoBar",
		Size = UDim2.new(1, 0, 0, infoBarHeight),
		Position = UDim2.new(0, 0, 1, -infoBarHeight),
		BackgroundColor3 = library.Theme.Secondary,
		BackgroundTransparency = 1,
		Visible = false,
		Parent = main,
	})
	Helpers.Corner(infoBar, Theme.CornerRadius, { BottomLeft = true, BottomRight = true })
	local infoBarCorner = infoBar:FindFirstChildOfClass("UICorner")
	Helpers.Stroke(infoBar, library.Theme.Border, 0.5)

	local infoLayout = Instance.new("UIListLayout")
	infoLayout.Name = "InfoLayout"
	infoLayout.FillDirection = Enum.FillDirection.Horizontal
	infoLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	infoLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	infoLayout.Padding = UDim.new(0, 20)
	infoLayout.Parent = infoBar

	local infoRefs = {}

	local function createInfoItem(labelText: string, initialValue: string)
		local container = Instance.new("Frame")
		container.Name = "InfoItem"
		container.Size = UDim2.new(0, 0, 1, 0)
		container.AutomaticSize = Enum.AutomaticSize.X
		container.BackgroundTransparency = 1
		container.Parent = infoBar

		local itemLayout = Instance.new("UIListLayout")
		itemLayout.FillDirection = Enum.FillDirection.Horizontal
		itemLayout.VerticalAlignment = Enum.VerticalAlignment.Center
		itemLayout.Parent = container

		local label = Helpers.CreateLabel({
			Name = "Label",
			Size = UDim2.new(0, 0, 1, 0),
			AutomaticSize = Enum.AutomaticSize.X,
			Text = labelText,
			TextColor3 = library.Theme.TextMuted,
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = container,
		})

		local value = Helpers.CreateLabel({
			Name = "Value",
			Size = UDim2.new(0, 0, 1, 0),
			AutomaticSize = Enum.AutomaticSize.X,
			Text = initialValue,
			TextColor3 = library.Theme.Text,
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Left,
			Font = Theme.FontBold,
			Parent = container,
		})

		return { Container = container, Label = label, Value = value }
	end

	local executorName = getExecutorName()

	local uptimeRef = createInfoItem("Executor: ", executorName)
	table.insert(infoRefs, uptimeRef)
	table.insert(infoRefs, createInfoItem("v", VERSION))
	local uptimeItem = createInfoItem("Uptime: ", "00:00:00")
	table.insert(infoRefs, uptimeItem)
	local playersItem = createInfoItem("Players: ", tostring(#Players:GetPlayers()) .. " / " .. tostring(Players.MaxPlayers))
	table.insert(infoRefs, playersItem)
	local timeItem = createInfoItem("Time: ", os.date("%I:%M %p"))
	table.insert(infoRefs, timeItem)

	-- Only the dynamic items get updated on a timer; Executor/Version never change.
	local function updateInfoBar()
		local uptime = os.clock() - self._StartupTime
		local hours = math.floor(uptime / 3600)
		local minutes = math.floor((uptime % 3600) / 60)
		local seconds = math.floor(uptime % 60)
		uptimeItem.Value.Text = string.format("%02d:%02d:%02d", hours, minutes, seconds)

		playersItem.Value.Text = tostring(#Players:GetPlayers()) .. " / " .. tostring(Players.MaxPlayers)
		timeItem.Value.Text = os.date("%I:%M %p")
	end

	-- Throttled updates instead of once-per-frame: massively cheaper, and a clock
	-- doesn't need sub-second precision anyway.
	local infoBarAccumulator = 0
	self._Maid:GiveTask(RunService.Heartbeat:Connect(function(dt)
		infoBarAccumulator += dt
		if infoBarAccumulator >= INFO_BAR_REFRESH_INTERVAL then
			infoBarAccumulator = 0
			updateInfoBar()
		end
	end))

	self._Maid:GiveTask(Players.PlayerAdded:Connect(updateInfoBar))
	self._Maid:GiveTask(Players.PlayerRemoving:Connect(updateInfoBar))

	-- ============================================
	-- SEARCH FUNCTIONALITY
	-- ============================================
	if searchBox then
		local previouslyMatched = {} :: { [Instance]: boolean }

		self._Maid:GiveTask(searchBox:GetPropertyChangedSignal("Text"):Connect(function()
			local query = searchBox.Text:lower()

			for _, child in tabList:GetChildren() do
				if child:IsA("GuiObject") then
					local matches = query == "" or child.Name:lower():find(query, 1, true) ~= nil
					child.Visible = matches

					if matches and query ~= "" and not previouslyMatched[child] then
						local isActiveTab = self._ActiveTab and self._ActiveTab.Button == child
						local restColor = if isActiveTab then library.Theme.Secondary else library.Theme.Background

						Tween.Play(child, { BackgroundColor3 = library.Theme.Accent }, { Time = 0.12 })
						task.delay(0.12, function()
							if child and child.Parent then
								Tween.Play(child, { BackgroundColor3 = restColor }, { Time = 0.35 })
							end
						end)
					end

					previouslyMatched[child] = matches
				end
			end
		end))
	end

	-- ============================================
	-- THEME REFRESH
	-- ============================================
	local function refreshWindowTheme()
		local fadeT = 0.28
		Tween.Play(main, { BackgroundColor3 = library.Theme.Background }, { Time = fadeT })
		Tween.Play(topBar, { BackgroundColor3 = library.Theme.Secondary }, { Time = fadeT })
		topBarGradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, library.Theme.Secondary),
			ColorSequenceKeypoint.new(0.55, library.Theme.Secondary),
			ColorSequenceKeypoint.new(1, library.Theme.Background),
		})
		topBarGradient.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.02),
			NumberSequenceKeypoint.new(0.55, 0.06),
			NumberSequenceKeypoint.new(1, 0.16),
		})
		topDivider.BackgroundColor3 = library.Theme.Border
		topAccentRail.BackgroundColor3 = library.Theme.Accent
		topAccentGradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, library.Theme.Accent),
			ColorSequenceKeypoint.new(0.65, library.Theme.AccentAlt or library.Theme.Accent),
			ColorSequenceKeypoint.new(1, library.Theme.Background),
		})
		topAmbient.BackgroundColor3 = library.Theme.Accent
		productMeta.TextColor3 = library.Theme.TextMuted
		statusRibbon.BackgroundColor3 = library.Theme.Surface
		statusStroke.Color = library.Theme.BorderStrong or library.Theme.Border
		statusGlow.Color = library.Theme.Accent
		statusDot.BackgroundColor3 = library.Theme.Success
		logoFrame.BackgroundColor3 = library.Theme.Background
		logoStroke.Color = library.Theme.BorderStrong or library.Theme.Border
		logoAccentStroke.Color = library.Theme.Accent
		Tween.Play(sidebar, { BackgroundColor3 = library.Theme.Secondary }, { Time = 0.28 })
		navLabel.TextColor3 = library.Theme.TextMuted
		if searchBox then
			searchBox.TextColor3 = library.Theme.Text
			searchBox.PlaceholderColor3 = library.Theme.TextMuted
		end
		if self._SearchHolder then
			self._SearchHolder.BackgroundColor3 = library.Theme.Background
		end
		if self._SearchStroke then
			self._SearchStroke.Color = library.Theme.Border
		end
		if self._SearchResults then
			self._SearchResults.BackgroundColor3 = library.Theme.Surface
		end
		local footerBg = library.Theme.ElementBackground or library.Theme.Surface or library.Theme.Secondary
		Tween.Play(footer, { BackgroundColor3 = footerBg, BackgroundTransparency = 0 }, { Time = 0.28 })
		if self._FooterStroke then
			self._FooterStroke.Color = library.Theme.Accent
			self._FooterStroke.Transparency = 0.55
		end
		if self._FooterAccent then
			self._FooterAccent.BackgroundColor3 = library.Theme.Accent
		end
		if footerName then
			footerName.TextColor3 = library.Theme.Text
		end
		if footerStatus then
			footerStatus.TextColor3 = library.Theme.Accent
		end
		for _, d in footer:GetDescendants() do
			if d:IsA("UIStroke") and d ~= self._FooterStroke then
				d.Color = library.Theme.BorderStrong or library.Theme.Border
			elseif d:IsA("TextLabel") then
				if d.Name == "Status" then
					d.TextColor3 = library.Theme.Accent
				elseif d.Name ~= "ActHint" then
					d.TextColor3 = library.Theme.Text
				end
			end
		end
		if minimizeButton then
			minimizeButton.BackgroundColor3 = library.Theme.Background
		end
		if closeButton then
			closeButton.BackgroundColor3 = library.Theme.Background
		end
		if self._FloatingButton then
			self._FloatingButton.BackgroundColor3 = Color3.fromRGB(30, 30, 34)
			if self._IslandCompact then
				self._IslandCompact.BackgroundColor3 = Color3.fromRGB(30, 30, 34)
			end
		end
		if self._IslandStroke then
			self._IslandStroke.Color = library.Theme.Border
		end
		if self._FloatingStroke then
			self._FloatingStroke.Color = library.Theme.Border
		end
		if self._IslandTitle then
			self._IslandTitle.TextColor3 = library.Theme.Text
		end
		if self._IslandBars then
			for _, bar in self._IslandBars:GetChildren() do
				if bar:IsA("Frame") then
					bar.BackgroundColor3 = library.Theme.Accent
				end
			end
		end
		atmosphere.BackgroundColor3 = library.Theme.Background
		atmosphereGradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, library.Theme.Background),
			ColorSequenceKeypoint.new(0.48, Color3.new(1, 1, 1)),
			ColorSequenceKeypoint.new(1, library.Theme.Background),
		})
		title.TextColor3 = library.Theme.Text
		if subtitle then
			subtitle.TextColor3 = library.Theme.Accent
		end
		if minimizeButton then
			minimizeButton.TextColor3 = library.Theme.TextMuted
		end
		if closeButton then
			closeButton.TextColor3 = library.Theme.TextMuted
		end
		if mainStroke then
			mainStroke.Color = library.Theme.Border
		end
		if glowStroke then
			glowStroke.Color = library.Theme.Accent
		end
		if watermarkStroke then
			watermarkStroke.Color = library.Theme.Border
		end
		watermark.BackgroundColor3 = library.Theme.Secondary
		watermarkTitle.TextColor3 = library.Theme.Accent
		watermarkFps.TextColor3 = library.Theme.Text
		watermarkPing.TextColor3 = library.Theme.Text
		watermarkUptime.TextColor3 = library.Theme.Text

		for _, ref in infoRefs do
			if ref.Label then
				ref.Label.TextColor3 = library.Theme.TextMuted
			end
			if ref.Value then
				ref.Value.TextColor3 = library.Theme.Text
			end
		end

		-- Top-bar badges: follow Accent (unless a fixed Color was passed in CreateWindow)
		if self._TopBadges then
			for i, ref in self._TopBadges do
				local color = if ref.FollowTheme then library.Theme.Accent else (ref.FixedColor or library.Theme.Accent)
				-- second badge can use AccentAlt when following theme
				if ref.FollowTheme and i == 2 and library.Theme.AccentAlt then
					color = library.Theme.AccentAlt
				end
				Tween.Play(ref.Pill, { BackgroundColor3 = color }, { Time = 0.22 })
				Tween.Play(ref.Label, { TextColor3 = color }, { Time = 0.22 })
				if ref.Stroke then
					Tween.Play(ref.Stroke, { Color = color }, { Time = 0.22 })
				end
				if ref.Glow then
					Tween.Play(ref.Glow, { Color = color }, { Time = 0.22 })
				end
			end
		else
			for _, child in badgeHolder:GetChildren() do
				if child:IsA("Frame") and child.Name:match("^Badge") then
					local label = child:FindFirstChild("Label")
					local color = library.Theme.Accent
					Tween.Play(child, { BackgroundColor3 = color }, { Time = 0.22 })
					if label then
						Tween.Play(label, { TextColor3 = color }, { Time = 0.22 })
					end
					for _, d in child:GetChildren() do
						if d:IsA("UIStroke") then
							Tween.Play(d, { Color = color }, { Time = 0.22 })
						end
					end
				end
			end
		end

		if self._SearchIconStroke then
			self._SearchIconStroke.Color = library.Theme.TextMuted
		end
		if self._SearchIconHandle then
			self._SearchIconHandle.BackgroundColor3 = library.Theme.TextMuted
		end
		if self._SearchResultsStroke then
			self._SearchResultsStroke.Color = library.Theme.Border
		end

		if resizeHandle then
			for _, line in resizeHandle:GetChildren() do
				if line:IsA("Frame") and line.Name:match("^Line") then
					line.BackgroundColor3 = library.Theme.TextMuted
				end
			end
		end

		for _, tab in self._Tabs do
			if tab and tab.RefreshTheme then
				tab:RefreshTheme()
			end
		end
	end

	self._Maid:GiveTask(library.Theme.Changed:Connect(refreshWindowTheme))

	-- ============================================
	-- MINIMIZE / CLOSE
	-- ============================================
	if minimizeButton then
		self._Maid:GiveTask(minimizeButton.MouseButton1Click:Connect(function()
			playClick()
			self._Minimized = not self._Minimized
			if self._Minimized then
				Tween.Play(main, { Size = UDim2.fromOffset(windowSize.X, topBarHeight) }, { Time = 0.18 })
			else
				Tween.Play(main, { Size = UDim2.fromOffset(windowSize.X, windowSize.Y) }, { Time = 0.18 })
			end
			if self._ApplyBlurTarget then
				self._ApplyBlurTarget()
			end
		end))
	end

	if closeButton then
		self._Maid:GiveTask(closeButton.MouseButton1Click:Connect(function()
			playClick()
			self:SetVisible(false)
		end))
	end

	-- ============================================
	-- KEYBIND
	-- ============================================
	self._ToggleKeybind = data.ToggleKey or Enum.KeyCode.RightControl
	self._Maid:GiveTask(UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if self._ToggleKeybind ~= nil and self._ToggleKeybind ~= Enum.KeyCode.Unknown and input.KeyCode == self._ToggleKeybind then
			self:Toggle()
		end
	end))

	-- ============================================
	-- SELF REFS
	-- ============================================
	self.Gui = screenGui
	self.Main = main
	self.TopBar = topBar
	self._TopAccentRail = topAccentRail
	self._TopAmbient = topAmbient
	self._ProductMeta = productMeta
	self.Sidebar = sidebar
	self.TabList = tabList
	self.Pages = pages
	self.TitleLabel = title
	self.SearchBox = searchBox
	self._SearchIconStroke = searchIconStroke
	self._SearchIconHandle = searchIconHandle
	self._AvatarImage = avatarImage
	self._NavLabel = navLabel
	self._FooterName = footerName
	self._FooterStatus = footerStatus
	self._LoadingFrame = self._BootGui
	self._ContentArea = contentArea
	self._TopBarHeight = topBarHeight
	self._SidebarWidth = Theme.SidebarWidth
	self._LayoutMode = data.Layout or "Vaxorin"
	self._Visible = true
	self._Minimized = false
	self._StartupComplete = false
	self._OptionsTab = nil
	self.RefreshTheme = refreshWindowTheme
	self._InfoBar = infoBar
	self._InfoRefs = infoRefs
	self._ResizeHandle = resizeHandle
	self._WindowSize = function()
		return windowSize
	end
	self._CornerInstances = { mainCorner, topBarCorner, sidebarCorner, infoBarCorner }

	self._LayoutVariants = LayoutVariants.new(self, data.Layout or "Vaxorin")

	local function clearSearchResults()
		for _, child in searchResults:GetChildren() do
			if child:IsA("GuiButton") or child:IsA("TextLabel") or child:IsA("Frame") then
				child:Destroy()
			end
		end
	end

	local function rebuildSearchResults(query: string)
		query = string.lower(string.gsub(query or "", "^%s*(.-)%s*$", "%1"))
		clearSearchResults()
		if query == "" then
			searchResults.Visible = false
			return
		end

		local matches = {}
		for _, tab in self._Tabs do
			local tabName = tostring(tab._Name or "")
			local tabMatches = string.find(string.lower(tabName), query, 1, true) ~= nil
			if tabMatches then
				table.insert(matches, { Kind = "Tab", Tab = tab, Title = cleanDisplayName(tabName), Detail = "Tab" })
			end
			for _, section in tab._Sections or {} do
				local sectionName = tostring(section._Name or "")
				local sectionMatch = string.find(string.lower(sectionName), query, 1, true) ~= nil
				if sectionMatch then
					table.insert(matches, { Kind = "Section", Tab = tab, Section = section, Title = cleanDisplayName(sectionName), Detail = cleanDisplayName(tabName) .. " / Section" })
				end
				for _, element in section._Elements or {} do
					local elementName = ""
					if element._Data then
						elementName = tostring(element._Data.Name or element._Data.Title or element._Data.Label or "")
					end
					if elementName ~= "" and string.find(string.lower(elementName), query, 1, true) then
						table.insert(matches, { Kind = "Element", Tab = tab, Section = section, Element = element, Title = elementName, Detail = cleanDisplayName(tabName) .. " / " .. cleanDisplayName(sectionName) })
					end
				end
			end
		end

		local limit = math.min(#matches, 8)
		for i = 1, limit do
			local match = matches[i]
			local result = Helpers.CreateButton({
				Name = "Result" .. i,
				Size = UDim2.new(1, 0, 0, 42),
				Text = "",
				BackgroundColor3 = library.Theme.Background,
				BackgroundTransparency = 0.15,
				AutoButtonColor = false,
				ZIndex = 61,
				Parent = searchResults,
			})
			Helpers.Corner(result, Theme.CornerRadiusSmall)
			local resultStroke = Helpers.Stroke(result, library.Theme.Border, 1)
			resultStroke.Transparency = 0.45
			Helpers.CreateLabel({ Name = "Title", Size = UDim2.new(1, -18, 0, 18), Position = UDim2.fromOffset(9, 5), Text = match.Title, Font = Theme.FontBold, TextSize = 11, TextColor3 = library.Theme.Text, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 62, Parent = result })
			Helpers.CreateLabel({ Name = "Detail", Size = UDim2.new(1, -18, 0, 15), Position = UDim2.fromOffset(9, 22), Text = match.Detail, Font = Theme.Font, TextSize = 9, TextColor3 = library.Theme.TextMuted, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 62, Parent = result })
			result.MouseEnter:Connect(function()
				Tween.Play(result, { BackgroundTransparency = 0.02 }, { Time = 0.1 })
			end)
			result.MouseLeave:Connect(function()
				Tween.Play(result, { BackgroundTransparency = 0.15 }, { Time = 0.1 })
			end)
			result.MouseButton1Click:Connect(function()
				searchBox.Text = ""
				searchResults.Visible = false
				self:_selectTab(match.Tab)
				local target = if match.Element and match.Element.Instance then match.Element.Instance else (match.Section and match.Section.Container)
				if target then
					task.defer(function()
						match.Tab.Page.CanvasPosition = Vector2.new(0, math.max(0, target.AbsolutePosition.Y - match.Tab.Page.AbsolutePosition.Y - 18))
					end)
				end
			end)
		end
		searchResults.Visible = limit > 0
		if limit == 0 then
			local empty = Helpers.CreateLabel({ Name = "Empty", Size = UDim2.new(1, 0, 0, 24), Text = "No sections or elements found", Font = Theme.Font, TextSize = 10, TextColor3 = library.Theme.TextMuted, TextXAlignment = Enum.TextXAlignment.Center, Parent = searchResults })
			searchResults.Visible = true
		end
	end

	if searchBox then
		self._Maid:GiveTask(searchBox:GetPropertyChangedSignal("Text"):Connect(function()
			rebuildSearchResults(searchBox.Text)
		end))
	end

	function self:SetProfileStatus(status: string)
		if self._FooterStatus then
			self._FooterStatus.Text = tostring(status)
		end
	end

	function self:SetProfile(username: string?, status: string?, avatar: string?)
		if username and self._FooterName then
			self._FooterName.Text = "Welcome, " .. tostring(username)
		end
		if status and self._FooterStatus then
			self._FooterStatus.Text = tostring(status)
		end
		if avatar and self._FooterName then
			local footer = self._FooterName.Parent
			local image = footer and footer:FindFirstChild("Avatar")
			if image and image:IsA("ImageLabel") then
				image.Image = avatar
			end
		end
	end

	function self:SetCornerRadius(radius: number)
		radius = math.clamp(radius, 0, 24)
		for _, corner in self._CornerInstances do
			if corner then
				corner.CornerRadius = UDim.new(0, radius)
			end
		end
	end

	-- ============================================
	-- STARTUP COMPLETE
	-- ============================================
	self._Maid:GiveTask(task.delay(2.4, function()
		if not self.Gui then return end
		if self._BootGui and self._BootGui.Parent then
			local backdrop = self._BootGui:FindFirstChild("Backdrop")
			-- Flash bloom + logo shrink, then dissolve
			if self._BootBloom then
				Tween.Play(self._BootBloom, {
					Size = UDim2.fromOffset(900, 900),
					BackgroundTransparency = 0.82,
				}, { Time = 0.28 })
			end
			if self._BootLogoScale then
				Tween.Play(self._BootLogoScale, { Scale = 1.15 }, {
					Time = 0.2,
					EasingStyle = Enum.EasingStyle.Back,
					EasingDirection = Enum.EasingDirection.Out,
				})
			end
			task.wait(0.16)
			if self._BootLogoScale then
				Tween.Play(self._BootLogoScale, { Scale = 0.6 }, { Time = 0.22 })
			end
			if backdrop then
				for _, child in backdrop:GetDescendants() do
					if child:IsA("TextLabel") then
						Tween.Play(child, { TextTransparency = 1 }, { Time = 0.28 })
					elseif child:IsA("ImageLabel") then
						Tween.Play(child, { ImageTransparency = 1 }, { Time = 0.28 })
					elseif child:IsA("Frame") then
						Tween.Play(child, { BackgroundTransparency = 1 }, { Time = 0.3 })
					elseif child:IsA("UIStroke") then
						Tween.Play(child, { Transparency = 1 }, { Time = 0.25 })
					end
				end
				Tween.Play(backdrop, { BackgroundTransparency = 1 }, { Time = 0.35 })
			end
			task.wait(0.38)
			if self._BootGui and self._BootGui.Parent then
				self._BootGui:Destroy()
			end
			self._BootGui = nil
		end
		print("[Vaxorin] boot finished")
		self._StartupComplete = true
		self:SetVisible(self._Visible)
	end))

	local restoredLayout = data.Layout or "Vaxorin"
	if self.Library then
		local fromFlag = self.Library:_getSavedFlag("Vaxorin.Visual.Layout", nil, true)
		local fromSession = self.Library.GetSession and self.Library:GetSession("Layout", nil)
		restoredLayout = fromFlag or fromSession or restoredLayout
	end
	-- Apply saved theme so Home / chrome use correct colors from the start
	pcall(function()
		local style = self.Library:_getSavedFlag("Vaxorin.Theme.Style", self.Library.Theme.Style, true)
		if style then
			self.Library.Theme.Style = style
		end
	end)
	-- Restore open control + weather (no Home tab — dashboard via Island hover / footer)
	pcall(function()
		local openStyle = self.Library:_getSavedFlag("Vaxorin.Visual.OpenStyle", self._OpenStyle or "Island", true)
		if self._applyOpenStyle then self:_applyOpenStyle(openStyle) end
		local weather = self.Library:_getSavedFlag("Vaxorin.Visual.Weather", "None", true)
		if weather and self._Weather then
			self._WeatherKind = weather
			self._Weather:Set(weather)
		end
		local dimPct = self.Library:_getSavedFlag("Vaxorin.Visual.DimAmount", 45, true)
		if typeof(dimPct) == "number" then
			self._DimAmount = math.clamp(dimPct / 100, 0, 1)
		end
	end)
	-- Footer click opens a lightweight dashboard notify for now
	if footer then
		footer.Active = true
		self._Maid:GiveTask(footer.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				local fpsText = self._IslandActStats and self._IslandActStats.Text or ""
				self:Notify({
					Title = "Dashboard",
					Content = string.format("%s\n%s\nPlace %s", 
						(footerName and footerName.Text) or "Welcome",
						fpsText,
						tostring(game.PlaceId)),
					Type = "Info",
					Duration = 3,
				})
			end
		end))
	end
	self:_createHomeTab()
	self:SetLayout(restoredLayout)
	return self :: any
end

-- ============================================
-- METHODS
-- ============================================

function Window:SetBackgroundImage(value: string)
	local bg = self._BackgroundImage
	if not bg then
		return
	end

	local images = {
		["Solo Leveling"] = "rbxassetid://139001765478120",
		["Gojo"] = "rbxassetid://111578938106815",
		["Sukuna"] = "rbxassetid://106318186489675",
		["Cid Kagenou"] = "rbxassetid://113248988511733",
	}

	bg.Image = images[value] or ""
end

function Window:SetBackgroundOverlayTransparency(value: number)
	local overlay = self.Main and self.Main:FindFirstChild("BackgroundOverlay")
	if overlay then
		overlay.BackgroundTransparency = math.clamp(value, 0, 1)
	end
end

function Window:_selectTab(tab: any)
	if self._ActiveTab == tab then
		return
	end

	local previousTab = self._ActiveTab

	for _, existingTab in self._Tabs do
		if existingTab and existingTab.SetActive then
			existingTab:SetActive(existingTab == tab)
		end
	end

	self._ActiveTab = tab

	local direction = 1
	if previousTab then
		local prevIndex, newIndex
		for i, t in self._Tabs do
			if t == previousTab then
				prevIndex = i
			end
			if t == tab then
				newIndex = i
			end
		end
		if prevIndex and newIndex and newIndex < prevIndex then
			direction = -1
		end
	end

	local newPage = tab.Page
	local oldPage = previousTab and previousTab.Page

	if oldPage and oldPage ~= newPage then
		oldPage.Visible = false
		oldPage.Position = UDim2.fromOffset(0, 0)
	end

	local slideDistance = self.Pages.AbsoluteSize.X * 0.25

	newPage.Visible = true
	newPage.Position = UDim2.fromOffset(slideDistance * direction, 0)
	Tween.Play(newPage, { Position = UDim2.fromOffset(0, 0) }, { Time = 0.2 })
end

function Window:SetLayout(mode: string)
	local normalized = ({ Vaxorin = "Vaxorin", Classic = "Classic", Minecraft = "Minecraft", Orbit = "Orbit", Aether = "Aether", Nova = "Nova", Vortex = "Vortex", Prism = "Prism", Eclipse = "Eclipse", Zenith = "Zenith", Compact = "Orbit", Expanded = "Vaxorin" })[mode] or "Vaxorin"
	self._LayoutMode = normalized
	if self._LayoutVariants then
		self._LayoutVariants:SetMode(normalized)
	end
	if self._LayoutModeLabel then self._LayoutModeLabel.Text = normalized .. " interface" end
	return normalized
end


function Window:_createHomeTab()
	if self._HomeTab then
		return self._HomeTab
	end

	local library = self.Library
	local Players = game:GetService("Players")
	local Stats = game:GetService("Stats")
	local RunService = game:GetService("RunService")
	local localPlayer = Players.LocalPlayer
	local theme = library.Theme

	local homeTab = Tab.new(self, "Home")
	self._HomeTab = homeTab
	table.insert(self._Tabs, 1, homeTab)
	if self._LayoutVariants and self._LayoutVariants.SyncTabs then
		self._LayoutVariants:SyncTabs()
	end

	if homeTab._PageTitle then
		homeTab._PageTitle.Text = "Welcome back"
	end
	if homeTab._PageEyebrow then
		homeTab._PageEyebrow.Text = "HOME"
	end

	local displayName = localPlayer.DisplayName or localPlayer.Name
	local userName = localPlayer.Name

	local welcomeSec = homeTab:CreateSection({
		Name = "Welcome",
		Description = "Your account",
	})
	welcomeSec:CreateParagraph({
		Title = "WELCOME BACK",
		Content = displayName .. "\n@" .. userName,
	})
	welcomeSec:CreateButton({
		Name = "Copy Username",
		Callback = function()
			if setclipboard then pcall(setclipboard, userName) end
			self:Notify({ Title = "Username", Content = "@" .. userName, Type = "Success", Duration = 2 })
		end,
	})

	local perfSec = homeTab:CreateSection({
		Name = "Performance",
		Description = "FPS · Ping · Session",
	})
	local fpsChart = perfSec:CreateChart({
		Label = "FPS",
		Bars = 20,
		Max = 150,
		Color = Color3.fromRGB(120, 255, 160),
	})
	local pingChart = perfSec:CreateChart({
		Label = "PING",
		Bars = 20,
		Max = 120,
		Color = Color3.fromRGB(100, 190, 255),
		Suffix = " ms",
	})
	local metaLbl = Helpers.CreateLabel({
		Name = "Meta",
		Size = UDim2.new(1, 0, 0, 16),
		Text = "0/0 players · 0s session",
		Font = Theme.Font,
		TextSize = 11,
		TextColor3 = theme.TextMuted,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = perfSec.Inner,
	})

	local gameSec = homeTab:CreateSection({
		Name = "Server",
		Description = "Place actions",
	})
	local gameName = "Unknown"
	local creatorName = ""
	pcall(function()
		local info = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
		if info then
			gameName = info.Name or gameName
			creatorName = (info.Creator and info.Creator.Name) or ""
		end
	end)
	gameSec:CreateParagraph({
		Title = gameName,
		Content = (creatorName ~= "" and ("by " .. creatorName) or "In-game")
			.. string.format("\nPlace %s", tostring(game.PlaceId)),
	})
	gameSec:CreateButton({
		Name = "Rejoin",
		Callback = function()
			pcall(function()
				game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, localPlayer)
			end)
		end,
	})
	gameSec:CreateButton({
		Name = "Server Hop",
		Callback = function()
			pcall(function()
				game:GetService("TeleportService"):Teleport(game.PlaceId, localPlayer)
			end)
		end,
	})
	gameSec:CreateButton({
		Name = "Copy Job ID",
		Callback = function()
			if setclipboard then pcall(setclipboard, game.JobId) end
			self:Notify({ Title = "JobId", Content = "Copied", Type = "Info", Duration = 2 })
		end,
	})
	gameSec:CreateButton({
		Name = "Copy Place ID",
		Callback = function()
			if setclipboard then pcall(setclipboard, tostring(game.PlaceId)) end
			self:Notify({ Title = "PlaceId", Content = "Copied", Type = "Info", Duration = 2 })
		end,
	})

	-- Favorites: dedicated holder so rebuild never duplicates section-tracked toggles
	local favSec = homeTab:CreateSection({
		Name = "Favorites",
		Description = "Star toggles · control them here",
	})
	local favHint = favSec:CreateParagraph({
		Title = "Pinned",
		Content = "Tap ★ on any toggle to pin it here.",
	})
	local favHolder = Helpers.CreateFrame({
		Name = "FavHolder",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = favSec.Inner,
	})
	Helpers.ListLayout(favHolder, 6)
	local favBuiltKey = ""

	local function rebuildFavorites()
		if not library.GetFavorites then
			return
		end
		local favs = library:GetFavorites()
		local key = table.concat(favs, "\0")
		if key == favBuiltKey then
			-- sync switch visuals only
			for _, child in favHolder:GetChildren() do
				if child:IsA("Frame") and child:GetAttribute("Flag") then
					local flag = child:GetAttribute("Flag")
					local on = library.Flags and library.Flags[flag] == true
					local sw = child:FindFirstChild("Switch")
					local knob = sw and sw:FindFirstChild("Knob")
					if sw and knob then
						sw.BackgroundColor3 = if on then library.Theme.Accent else library.Theme.Border
						knob.Position = if on then UDim2.new(1, -19, 0.5, 0) else UDim2.new(0, 3, 0.5, 0)
					end
				end
			end
			return
		end
		favBuiltKey = key

		for _, child in favHolder:GetChildren() do
			if child:IsA("Frame") or child:IsA("TextButton") then
				child:Destroy()
			end
		end

		if #favs == 0 then
			if favHint then
				if favHint.Instance then favHint.Instance.Visible = true end
				if favHint.Set then favHint:Set("Tap ★ on any toggle to pin it here.") end
			end
			return
		end
		if favHint then
			if favHint.Instance then favHint.Instance.Visible = true end
			if favHint.Set then favHint:Set(#favs .. " pinned · toggle below") end
		end

		for _, flag in ipairs(favs) do
			local on = library.Flags and library.Flags[flag] == true
			local row = Helpers.CreateFrame({
				Name = "Fav_" .. tostring(flag):gsub("[^%w]", "_"),
				Size = UDim2.new(1, 0, 0, Theme.ElementHeight or 40),
				BackgroundColor3 = library.Theme.ElementBackground or library.Theme.Background,
				BackgroundTransparency = 0.05,
				Parent = favHolder,
			})
			row:SetAttribute("Flag", flag)
			Helpers.Corner(row, Theme.CornerRadiusSmall or 8)

			Helpers.CreateLabel({
				Size = UDim2.new(1, -56, 1, 0),
				Position = UDim2.fromOffset(12, 0),
				Text = tostring(flag),
				Font = Theme.Font,
				TextSize = 13,
				TextColor3 = library.Theme.Text,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Parent = row,
			})

			local switch = Helpers.CreateFrame({
				Name = "Switch",
				Size = UDim2.fromOffset(42, 22),
				Position = UDim2.new(1, -12, 0.5, 0),
				AnchorPoint = Vector2.new(1, 0.5),
				BackgroundColor3 = if on then library.Theme.Accent else library.Theme.Border,
				Parent = row,
			})
			Helpers.Corner(switch, 999)
			local knob = Helpers.CreateFrame({
				Name = "Knob",
				Size = UDim2.fromOffset(16, 16),
				Position = if on then UDim2.new(1, -19, 0.5, 0) else UDim2.new(0, 3, 0.5, 0),
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundColor3 = library.Theme.Text,
				Parent = switch,
			})
			Helpers.Corner(knob, 999)

			local hit = Helpers.CreateButton({
				Name = "Hit",
				Size = UDim2.fromScale(1, 1),
				Text = "",
				BackgroundTransparency = 1,
				ZIndex = 3,
				Parent = row,
			})
			hit.MouseButton1Click:Connect(function()
				local cur = library.Flags and library.Flags[flag] == true
				local nextV = not cur
				if library._setFlag then
					library:_setFlag(flag, nextV, true)
				elseif library.Flags then
					library.Flags[flag] = nextV
				end
				local control = library._FlagControls and library._FlagControls[flag]
				if control and control.Set then
					pcall(function()
						control:Set(nextV, true)
					end)
				end
				switch.BackgroundColor3 = if nextV then library.Theme.Accent else library.Theme.Border
				Tween.Play(knob, {
					Position = if nextV then UDim2.new(1, -19, 0.5, 0) else UDim2.new(0, 3, 0.5, 0),
				}, { Time = 0.12 })
			end)
		end
	end

	local healthSec = homeTab:CreateSection({
		Name = "Script Health",
		Description = "Errors & config",
	})
	local healthParagraph = healthSec:CreateParagraph({
		Title = "Status",
		Content = "Healthy · no recent errors",
	})

	if homeTab._UpdateColumns then
		homeTab._UpdateColumns()
	end

	local sessionStart = os.clock()
	local frames, last = 0, os.clock()
	local fpsValue = 0

	self._Maid:GiveTask(RunService.RenderStepped:Connect(function()
		frames += 1
		local now = os.clock()
		if now - last >= 0.45 then
			fpsValue = math.floor(frames / (now - last) + 0.5)
			frames = 0
			last = now
		end
	end))

	self._Maid:GiveTask(task.spawn(function()
		while self.Gui and self.Gui.Parent do
			local ping = 0
			pcall(function()
				local item = Stats.Network.ServerStatsItem["Data Ping"]
				if item then ping = math.floor((item:GetValue() or 0) + 0.5) end
			end)
			if ping == 0 then
				pcall(function()
					if localPlayer.GetNetworkPing then
						ping = math.floor(localPlayer:GetNetworkPing() * 1000 + 0.5)
					end
				end)
			end

			if fpsChart and fpsChart.Push then
				fpsChart:Push(fpsValue)
			end
			if pingChart and pingChart.Push then
				pingChart:Push(ping)
			end

			local sec = math.floor(os.clock() - sessionStart)
			if metaLbl then
				metaLbl.Text = string.format(
					"%d/%d players · %dm %02ds session",
					#Players:GetPlayers(),
					Players.MaxPlayers,
					math.floor(sec / 60),
					sec % 60
				)
			end

			rebuildFavorites()

			if library.GetHealth and healthParagraph and healthParagraph.Set then
				local h = library:GetHealth()
				local errs = h.errors or {}
				if #errs == 0 then
					healthParagraph:Set((h.dirty and "Config dirty · " or "") .. "Healthy · no recent errors")
				else
					local lines = {}
					for i = 1, math.min(4, #errs) do
						table.insert(lines, `{errs[i].Source}: {errs[i].Message}`)
					end
					healthParagraph:Set(table.concat(lines, "\n"))
				end
			end

			task.wait(0.5)
		end
	end))

	if not self._ActiveTab then
		self:_selectTab(homeTab)
	end
	if self._OptionsTab then
		self:_ensureOptionsLast()
	end

	return homeTab
end

function Window:_ensureOptionsLast()
	if not self._OptionsTab or not self._Tabs then
		return
	end
	local tabs = self._Tabs
	local idx = nil
	for i, t in ipairs(tabs) do
		if t == self._OptionsTab then
			idx = i
			break
		end
	end
	if idx then
		table.remove(tabs, idx)
	end
	table.insert(tabs, self._OptionsTab)
	-- LayoutOrder on tab buttons if present
	for i, t in ipairs(tabs) do
		if t and t.Button then
			t.Button.LayoutOrder = i
		end
	end
	if self._LayoutVariants and self._LayoutVariants.SyncTabs then
		pcall(function()
			self._LayoutVariants:SyncTabs()
		end)
	end
end

function Window:CreateTab(name: string)
	local tab = Tab.new(self, name)
	table.insert(self._Tabs, tab)
	if self._LayoutVariants and self._LayoutVariants.SyncTabs then self._LayoutVariants:SyncTabs() end

	if not self._OptionsTab then
		self:_createOptionsTab()
	else
		self:_ensureOptionsLast()
	end

	local savedTab = nil
	if self.Library and self.Library.GetSession then
		savedTab = self.Library:GetSession("LastTab", nil)
	end

	if not self._ActiveTab then
		self:_selectTab(tab)
	elseif savedTab and name == savedTab then
		self:_selectTab(tab)
	end

	return tab
end

function Window:_createOptionsTab()
	if self._OptionsTab then
		return self._OptionsTab
	end

	local optionsTab = Tab.new(self, "Options")
	self._OptionsTab = optionsTab
	table.insert(self._Tabs, optionsTab) -- always at end
	self:_ensureOptionsLast()
	if self._LayoutVariants and self._LayoutVariants.SyncTabs then self._LayoutVariants:SyncTabs() end

	self.Library.Theme.Style = self.Library:_getSavedFlag("Vaxorin.Theme.Style", self.Library.Theme.Style, true)
	self.Library.Theme.Background = self.Library:_getSavedFlag("Vaxorin.Theme.Background", self.Library.Theme.Background, true)
	self.Library.Theme.Secondary = self.Library:_getSavedFlag("Vaxorin.Theme.Secondary", self.Library.Theme.Secondary, true)
	self.Library.Theme.Accent = self.Library:_getSavedFlag("Vaxorin.Theme.Accent", self.Library.Theme.Accent, true)
	self.Library.Theme.Text = self.Library:_getSavedFlag("Vaxorin.Theme.Text", self.Library.Theme.Text, true)
	self.Library.Theme.Border = self.Library:_getSavedFlag("Vaxorin.Theme.Border", self.Library.Theme.Border, true)

	local visualSection = optionsTab:CreateSection("🎨 Visual")
	visualSection:CreateParagraph({
		Title = "Customize your experience",
		Content = "Choose the look and feel of Vaxorin.",
	})

	visualSection:CreateDropdown({
		Name = "Theme Preset",
		Options = { "Vaxorin", "Deep", "Sakura", "Midnight", "Ocean", "Emerald", "Crimson", "Amber", "Frost", "Rose", "Neon", "Sunset", "Forest", "Slate", "Dark", "Light", "Cyber" },
		CurrentOption = self.Library.Theme.Style,
		Flag = "Vaxorin.Theme.Style",
		Save = true,
		Callback = function(value)
			if type(value) == "table" then value = value[1] end
			self.Library.Theme.Style = tostring(value or "Vaxorin")
			if self.RefreshTheme then self:RefreshTheme() end
		end,
	})

	visualSection:CreateDropdown({
		Name = "Open Control",
		Options = { "Island", "Button" },
		CurrentOption = self._OpenStyle or "Island",
		Flag = "Vaxorin.Visual.OpenStyle",
		Save = true,
		Callback = function(value)
			if type(value) == "table" then value = value[1] end
			if self._applyOpenStyle then
				self:_applyOpenStyle(tostring(value or "Island"))
			else
				self._OpenStyle = tostring(value or "Island")
			end
		end,
	})

	visualSection:CreateDropdown({
		Name = "Weather",
		Options = { "None", "Rain", "Snow", "Sakura", "Stars", "Leaves" },
		CurrentOption = self._WeatherKind or "None",
		Flag = "Vaxorin.Visual.Weather",
		Save = true,
		Callback = function(value)
			if type(value) == "table" then value = value[1] end
			value = tostring(value or "None")
			self._WeatherKind = value
			if self._Weather then
				self._Weather:Set(value)
			end
		end,
	})

	visualSection:CreateDropdown({
		Name = "Weather Scope",
		Options = { "Screen", "UI" },
		CurrentOption = self._WeatherScope or "Screen",
		Flag = "Vaxorin.Visual.WeatherScope",
		Save = true,
		Callback = function(value)
			if type(value) == "table" then value = value[1] end
			value = tostring(value or "Screen")
			self._WeatherScope = value
			if self._Weather and self._Weather.SetScope then
				self._Weather:SetScope(value)
			end
		end,
	})

	visualSection:CreateSlider({
		Name = "Background Dim",
		Min = 0,
		Max = 100,
		Default = math.floor((self._DimAmount or 0.45) * 100 + 0.5),
		Flag = "Vaxorin.Visual.DimAmount",
		Save = true,
		Callback = function(value)
			local n = tonumber(value) or 45
			self._DimAmount = math.clamp(n / 100, 0, 1)
			if self._Dim and self._Visible then
				Tween.Play(self._Dim, { BackgroundTransparency = 1 - self._DimAmount }, { Time = 0.12 })
			end
		end,
	})

	visualSection:CreateDropdown({
		Name = "Layout",
		Options = { "Vaxorin", "Classic", "Minecraft", "Orbit", "Aether", "Nova", "Vortex", "Prism", "Eclipse", "Zenith" },
		CurrentOption = self._LayoutMode,
		Flag = "Vaxorin.Visual.Layout",
		Callback = function(value)
			self:SetLayout(value)
		end,
	})

	-- Profiles (requires ConfigurationSaving.Enabled = true)
	local profileSection = optionsTab:CreateSection("Profiles")
	profileSection:CreateParagraph({
		Title = "Config profiles",
		Content = "Save and load full setting snapshots. Needs ConfigurationSaving enabled in CreateWindow.",
	})

	local profileNames = {}
	if self.Library and self.Library.GetProfiles then
		profileNames = self.Library:GetProfiles()
	end
	if #profileNames == 0 then
		profileNames = { "(none yet)" }
	end

	local activeProfile = "(none yet)"
	if self.Library and self.Library.GetSession then
		activeProfile = self.Library:GetSession("ActiveProfile", nil) or profileNames[1]
	end

	local profileDropdown
	profileDropdown = profileSection:CreateDropdown({
		Name = "Profile",
		Options = profileNames,
		CurrentOption = activeProfile,
		Flag = "Vaxorin.Session.ActiveProfile",
		Save = false,
		Callback = function(value)
			if value and value ~= "(none yet)" and self.Library and self.Library.LoadProfile then
				local ok = self.Library:LoadProfile(value)
				if self.Library.Notify then
					self.Library:Notify({
						Title = if ok then "Profile loaded" else "Load failed",
						Content = tostring(value),
						Duration = 2,
					})
				end
			end
		end,
	})

	profileSection:CreateInput({
		Name = "New profile name",
		PlaceholderText = "e.g. Farm, PvP",
		CurrentValue = "",
		Flag = "Vaxorin.Session.ProfileDraft",
		Save = false,
		Callback = function() end,
	})

	profileSection:CreateButton({
		Name = "Save current as profile",
		Callback = function()
			if not self.Library or not self.Library.SaveProfile then
				return
			end
			local draft = self.Library.Flags["Vaxorin.Session.ProfileDraft"]
			local name = if type(draft) == "string" and draft ~= "" then draft else nil
			if not name and self.Library.GetSession then
				name = self.Library:GetSession("ActiveProfile", nil)
			end
			if not name or name == "" or name == "(none yet)" then
				name = "Profile " .. tostring(os.time() % 10000)
			end
			local ok = self.Library:SaveProfile(name)
			if self.Library.Notify then
				self.Library:Notify({
					Title = if ok then "Profile saved" else "Save failed",
					Content = tostring(name),
					Duration = 2,
				})
			end
			if ok and profileDropdown and profileDropdown.Set then
				local names = self.Library:GetProfiles()
				if profileDropdown.RefreshOptions then
					profileDropdown:RefreshOptions(names)
				end
				profileDropdown:Set(name)
			end
		end,
	})

	profileSection:CreateButton({
		Name = "Delete selected profile",
		Callback = function()
			if not self.Library or not self.Library.DeleteProfile then
				return
			end
			local name = self.Library:GetSession("ActiveProfile", nil)
				or self.Library.Flags["Vaxorin.Session.ActiveProfile"]
			if not name or name == "(none yet)" then
				return
			end
			local ok = self.Library:DeleteProfile(name)
			if self.Library.Notify then
				self.Library:Notify({
					Title = if ok then "Profile deleted" else "Delete failed",
					Content = tostring(name),
					Duration = 2,
				})
			end
		end,
	})

	local themeColorPickers = {}
	local colorConfigs = {
		Accent = { Name = "Accent Color", Flag = "Vaxorin.Theme.Accent" },
		Background = { Name = "Background Color", Flag = "Vaxorin.Theme.Background" },
		Secondary = { Name = "Secondary Color", Flag = "Vaxorin.Theme.Secondary" },
		Text = { Name = "Text Color", Flag = "Vaxorin.Theme.Text" },
		Border = { Name = "Border Color", Flag = "Vaxorin.Theme.Border" },
	}

	for key, config in colorConfigs do
		themeColorPickers[key] = visualSection:CreateColorPicker({
			Name = config.Name,
			CurrentValue = self.Library.Theme[key],
			Flag = config.Flag,
			Callback = function(color)
				self.Library.Theme[key] = color
			end,
		})
	end

	self._Maid:GiveTask(self.Library.Theme.Changed:Connect(function(key)
		if key ~= "Style" then
			return
		end
		for propName, picker in themeColorPickers do
			if picker and picker.Set then
				picker:Set(self.Library.Theme[propName])
			end
		end
	end))

	visualSection:CreateInput({
		Name = "Custom Background",
		PlaceholderText = "rbxassetid://123456789",
		Callback = function(value)
			if value == "" then
				return
			end
			if not value:match("^rbxassetid://") then
				value = "rbxassetid://" .. value
			end
			if self._BackgroundImage then
				self._BackgroundImage.Image = value
			end
		end,
	})

	visualSection:CreateDropdown({
		Name = "Background Presets",
		Options = { "Solo Leveling", "Gojo", "Sukuna", "Cid Kagenou", "None" },
		Callback = function(value: string)
			self:SetBackgroundImage(value)
		end,
	})

	visualSection:CreateSlider({
		Name = "Overlay Transparency",
		Min = 0,
		Max = 1,
		CurrentValue = 0.65,
		Rounding = 0.01,
		Callback = function(value: number)
			self:SetBackgroundOverlayTransparency(value)
		end,
		Flag = "Vaxorin.Background.OverlayTransparency",
	})

	visualSection:CreateSlider({
		Name = "Corner Roundness",
		Min = 0,
		Max = 20,
		CurrentValue = Theme.CornerRadius,
		Rounding = 0,
		Callback = function(value: number)
			self:SetCornerRadius(value)
		end,
		Flag = "Vaxorin.Visual.CornerRadius",
	})

	visualSection:CreateToggle({
		Name = "Background Blur",
		CurrentValue = false,
		Flag = "Vaxorin.Visual.Blur",
		Callback = function(value: boolean)
			self._BlurEnabled = value
			if self._ApplyBlurTarget then
				self._ApplyBlurTarget()
			end
		end,
	})

	local featuresSection = optionsTab:CreateSection("✨ New in V5")
	featuresSection:CreateBadge({ Text = "V5 MEGA UPDATE", Color = self.Library.Theme.Accent, Width = 128 })
	featuresSection:CreateCard({ Title = "New component system", Content = "Cards, badges, progress, status, notices, stats, dividers and icon actions are now first-class elements." })
	featuresSection:CreateStatus({ Title = "Interface", Content = "All systems operational" })
	featuresSection:CreateProgress({ Title = "UI engine", CurrentValue = 1 })
	featuresSection:CreateNotice({ Title = "Interface variants", Content = "Switch the entire shell: Vaxorin, Classic, Minecraft, Orbit, Aether, Nova, Vortex, Prism, Eclipse, Zenith." })
	featuresSection:CreateStat({ Label = "Element modules", Value = "20+", Delta = "NEW" })
	featuresSection:CreateDivider({})
	featuresSection:CreateIconButton({ Text = "Preview Classic", Callback = function() self:SetLayout("Classic") end })
	featuresSection:CreateIconButton({ Text = "Preview Minecraft", Callback = function() self:SetLayout("Minecraft") end })
	featuresSection:CreateIconButton({ Text = "Preview Orbit", Callback = function() self:SetLayout("Orbit") end })
	featuresSection:CreateIconButton({ Text = "Preview Aether", Callback = function() self:SetLayout("Aether") end })
	featuresSection:CreateIconButton({ Text = "Preview Nova", Callback = function() self:SetLayout("Nova") end })
	featuresSection:CreateIconButton({ Text = "Preview Vortex", Callback = function() self:SetLayout("Vortex") end })
	featuresSection:CreateIconButton({ Text = "Preview Prism", Callback = function() self:SetLayout("Prism") end })
	featuresSection:CreateIconButton({ Text = "Preview Eclipse", Callback = function() self:SetLayout("Eclipse") end })
	featuresSection:CreateIconButton({ Text = "Preview Zenith", Callback = function() self:SetLayout("Zenith") end })

	local generalSection = optionsTab:CreateSection("🧩 General")
	generalSection:CreateParagraph({
		Title = "Quality of life",
		Content = "Small extras that don't change how the UI looks, just how it feels.",
	})

	generalSection:CreateToggle({
		Name = "Sound Effects",
		CurrentValue = true,
		Flag = "Vaxorin.General.Sound",
		Callback = function(value: boolean)
			self._SoundEnabled = value
		end,
	})

	generalSection:CreateToggle({
		Name = "Show Watermark",
		CurrentValue = false,
		Flag = "Vaxorin.General.Watermark",
		Callback = function(value: boolean)
			self:SetWatermarkEnabled(value)
		end,
	})

	local configSection = optionsTab:CreateSection("⚙️ Configuration")
	configSection:CreateParagraph({
		Title = "Save & Restore",
		Content = "Your settings are automatically saved.",
	})

	configSection:CreateToggle({
		Name = "Configuration Saving",
		CurrentValue = self.Library._ConfigEnabled,
		Save = false,
		Callback = function(value)
			self.Library._ConfigEnabled = value
		end,
	})

	configSection:CreateToggle({
		Name = "Auto Save",
		CurrentValue = self.Library._AutoSave,
		Save = false,
		Callback = function(value)
			self.Library._AutoSave = value
		end,
	})

	configSection:CreateButton({
		Name = "💾 Save Configuration",
		Callback = function()
			local ok, err = pcall(function()
				self.Library:SaveConfiguration()
			end)
			self:Notify({
				Title = ok and "Saved" or "Save Failed",
				Content = ok and "Configuration saved successfully!" or tostring(err),
				Type = ok and "Success" or "Error",
			})
		end,
	})

	configSection:CreateButton({
		Name = "📂 Load Configuration",
		Callback = function()
			local ok, err = pcall(function()
				self.Library:LoadConfiguration()
			end)
			self:Notify({
				Title = ok and "Loaded" or "Load Failed",
				Content = ok and "Configuration loaded successfully!" or tostring(err),
				Type = ok and "Success" or "Error",
			})
		end,
	})

	local keybindSection = optionsTab:CreateSection("⌨️ Keybinds")
	keybindSection:CreateParagraph({
		Title = "Toggle UI",
		Content = "Press this key to show/hide the interface.",
	})

	local toggleKeybind = keybindSection:CreateKeybind({
		Name = "Toggle UI",
		Default = self._ToggleKeybind,
		Flag = "Vaxorin.ToggleKey",
		Callback = function(key)
			self._ToggleKeybind = key
		end,
	})

	self._Maid:GiveTask(toggleKeybind:OnChanged(function(key)
		self._ToggleKeybind = key
	end))

	local discordSection = optionsTab:CreateSection("💬 Discord")
	discordSection:CreateButton({
		Name = "📋 Copy Discord Invite",
		Callback = function()
			local invite = "https://discord.gg/9jZTsy7Wtb"
			if setclipboard then
				setclipboard(invite)
			end

			self:Notify({
				Title = "Discord",
				Content = "Invite copied to clipboard!",
				Type = "Success",
				Duration = 4,
			})
		end,
	})

	return optionsTab
end


-- ============================================
-- DEVELOPER WINDOW
-- ============================================
-- Opens a separate, draggable panel that developers can use for live stats,
-- debug values, counters, status information, or any other text.
--
-- Example:
-- local dev = Window:CreateDeveloperWindow({
--     Title = "Developer Stats",
--     Stats = {
--         Players = #game:GetService("Players"):GetPlayers(),
--         FPS = 60,
--         Status = "Online",
--     },
-- })
--
-- Update it later:
-- dev:SetStats({ Players = 12, FPS = 144, Status = "Running" })
-- dev:SetContent("Custom developer text")
function Window:CreateDeveloperWindow(options: any?): DeveloperPanelHandle
	local data = (typeof(options) == "table") and options or {}
	local parent = self._TopGuiParent or self.Gui.Parent
	local existing = self._DeveloperGui
	if existing then
		existing:Destroy()
	end

	local developerGui = Instance.new("ScreenGui")
	developerGui.Name = "VaxorinDeveloper"
	developerGui.ResetOnSpawn = false
	developerGui.IgnoreGuiInset = true
	developerGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	developerGui.DisplayOrder = 999
	developerGui.Parent = parent
	self._DeveloperGui = developerGui

	local width = tonumber(data.Width) or 360
	local height = tonumber(data.Height) or 300
	local titleText = tostring(data.Title or "Developer Panel")

	local panel = Instance.new("Frame")
	panel.Name = "DeveloperPanel"
	panel.Size = UDim2.fromOffset(width, height)
	panel.Position = UDim2.new(0.5, -width / 2, 0.5, -height / 2)
	panel.BackgroundColor3 = Theme.Surface
	panel.BorderSizePixel = 0
	panel.Active = true
	panel.Parent = developerGui
	Helpers.Corner(panel, Theme.CornerRadius)
	Helpers.Stroke(panel, Theme.BorderStrong, 1)
	Helpers.Glow(panel, Theme.Accent, 10, 0.94)

	local top = Instance.new("Frame")
	top.Name = "Header"
	top.Size = UDim2.new(1, 0, 0, 48)
	top.BackgroundColor3 = Theme.Secondary
	top.BorderSizePixel = 0
	top.Active = true
	top.Parent = panel

	local title = Helpers.CreateLabel({
		Name = "Title",
		Size = UDim2.new(1, -56, 1, 0),
		Position = UDim2.fromOffset(16, 0),
		Text = titleText,
		TextColor3 = Theme.Text,
		TextSize = 15,
		Font = Theme.FontBold,
		Parent = top,
	})

	local close = Helpers.CreateButton({
		Name = "Close",
		Size = UDim2.fromOffset(40, 40),
		Position = UDim2.new(1, -44, 0, 4),
		Text = "×",
		TextColor3 = Theme.TextMuted,
		TextSize = 22,
		Font = Theme.FontBold,
		BackgroundTransparency = 1,
		Parent = top,
	})
	close.MouseButton1Click:Connect(function()
		developerGui:Destroy()
		if self._DeveloperGui == developerGui then
			self._DeveloperGui = nil
		end
	end)

	local accent = Instance.new("Frame")
	accent.Name = "Accent"
	accent.Size = UDim2.new(1, 0, 0, 2)
	accent.Position = UDim2.fromOffset(0, 46)
	accent.BackgroundColor3 = Theme.Accent
	accent.BorderSizePixel = 0
	accent.Parent = top

	local content = Instance.new("ScrollingFrame")
	content.Name = "Content"
	content.Size = UDim2.new(1, -24, 1, -64)
	content.Position = UDim2.fromOffset(12, 56)
	content.BackgroundTransparency = 1
	content.BorderSizePixel = 0
	content.ScrollBarThickness = 4
	content.CanvasSize = UDim2.new()
	content.AutomaticCanvasSize = Enum.AutomaticSize.Y
	content.ScrollingDirection = Enum.ScrollingDirection.Y
	content.Parent = panel

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 7)
	layout.Parent = content

	local padding = Instance.new("UIPadding")
	padding.PaddingBottom = UDim.new(0, 8)
	padding.Parent = content

	local panelHandle = {} :: any
	local function clearContent()
		for _, child in content:GetChildren() do
			if child:IsA("TextLabel") or child:IsA("Frame") then
				child:Destroy()
			end
		end
	end

	function panelHandle:SetStats(stats: { [string]: any })
		clearContent()
		local entries = {}
		for key, value in stats do
			table.insert(entries, { Key = tostring(key), Value = tostring(value) })
		end
		table.sort(entries, function(a, b)
			return a.Key < b.Key
		end)

		for index, entry in entries do
			local row = Instance.new("Frame")
			row.Name = "Stat_" .. tostring(index)
			row.Size = UDim2.new(1, 0, 0, 34)
			row.BackgroundColor3 = Theme.ElementBackground
			row.BorderSizePixel = 0
			row.LayoutOrder = index
			row.Parent = content
			Helpers.Corner(row, Theme.CornerRadiusSmall)

			Helpers.CreateLabel({
				Name = "Key",
				Size = UDim2.new(0.5, -12, 1, 0),
				Position = UDim2.fromOffset(12, 0),
				Text = entry.Key,
				TextColor3 = Theme.TextMuted,
				TextSize = 13,
				Parent = row,
			})

			Helpers.CreateLabel({
				Name = "Value",
				Size = UDim2.new(0.5, -12, 1, 0),
				Position = UDim2.new(0.5, 0, 0, 0),
				Text = entry.Value,
				TextColor3 = Theme.Text,
				TextSize = 13,
				Font = Theme.FontBold,
				TextXAlignment = Enum.TextXAlignment.Right,
				Parent = row,
			})
		end
	end

	function panelHandle:SetContent(text: string)
		clearContent()
		local label = Helpers.CreateLabel({
			Name = "DeveloperContent",
			Size = UDim2.new(1, -12, 0, 0),
			Text = tostring(text or ""),
			TextColor3 = Theme.Text,
			TextSize = 13,
			TextWrapped = true,
			AutomaticSize = Enum.AutomaticSize.Y,
			Parent = content,
		})
		label.LayoutOrder = 1
	end

	function panelHandle:Close()
		if developerGui.Parent then
			developerGui:Destroy()
		end
		if self._DeveloperGui == developerGui then
			self._DeveloperGui = nil
		end
	end

	function panelHandle:Open()
		if not developerGui.Parent then
			developerGui.Parent = parent
		end
		developerGui.Enabled = true
	end

	-- Simple drag support for the header.
	local UserInputService = game:GetService("UserInputService")
	local dragging = false
	local dragStart: Vector2
	local startPos: UDim2
	local dragInput: InputObject?

	top.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = panel.Position
		end
	end)

	top.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	top.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and input == dragInput then
			local delta = input.Position - dragStart
			panel.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)

	if type(data.Stats) == "table" then
		panelHandle:SetStats(data.Stats)
	elseif data.Content ~= nil then
		panelHandle:SetContent(tostring(data.Content))
	end

	return panelHandle
end

function Window:OpenDeveloperWindow(options: any?): DeveloperPanelHandle
	return self:CreateDeveloperWindow(options)
end

-- Opens the visual Custom ESP Designer. The returned layout is renderer-agnostic
-- and can be consumed by a project-specific ESP/overlay renderer.
function Window:CreateESPBuilder(options: any?)
	local data = (typeof(options) == "table") and options or {}
	if self._ESPBuilder then
		pcall(function() self._ESPBuilder:Close() end)
		self._ESPBuilder = nil
	end
	data.Parent = self._TopGuiParent or self.Gui.Parent
	local builder = ESPBuilder.new(data)
	self._ESPBuilder = builder
	return builder
end

function Window:CreateESPWorldRenderer(options: any?)
	local data = (typeof(options) == "table") and options or {}
	if self._ESPWorldRenderer then
		pcall(function() self._ESPWorldRenderer:Destroy() end)
		self._ESPWorldRenderer = nil
	end
	data.Parent = self._TopGuiParent or self.Gui.Parent
	local renderer = ESPWorldRenderer.new(data)
	self._ESPWorldRenderer = renderer
	return renderer
end


function Window:CreateFolder(name: string)
	return self:CreateTab(name)
end

function Window:_getActiveTab(): any
	if self._ActiveTab then
		return self._ActiveTab
	end
	return self._Tabs[1]
end

function Window:CreateSection(nameOrData: any)
	local tab = self:_getActiveTab()
	if not tab then
		return nil
	end
	return tab:CreateSection(nameOrData)
end

function Window:CreateDropdown(data: any)
	local tab = self:_getActiveTab()
	if not tab then
		return nil
	end
	return tab:CreateDropdown(data)
end

function Window:CreateToggle(data: any)
	local tab = self:_getActiveTab()
	if not tab then
		return nil
	end
	return tab:CreateToggle(data)
end

function Window:CreateButton(data: any)
	local tab = self:_getActiveTab()
	if not tab then
		return nil
	end
	return tab:CreateButton(data)
end

function Window:CreateSlider(data: any)
	local tab = self:_getActiveTab()
	if not tab then
		return nil
	end
	return tab:CreateSlider(data)
end

function Window:CreateInput(data: any)
	local tab = self:_getActiveTab()
	if not tab then
		return nil
	end
	return tab:CreateInput(data)
end

function Window:CreateKeybind(data: any)
	local tab = self:_getActiveTab()
	if not tab then
		return nil
	end
	return tab:CreateKeybind(data)
end

function Window:CreateColorPicker(data: any)
	local tab = self:_getActiveTab()
	if not tab then
		return nil
	end
	return tab:CreateColorPicker(data)
end

function Window:CreateParagraph(data: any)
	local tab = self:_getActiveTab()
	if not tab then
		return nil
	end
	return tab:CreateParagraph(data)
end

function Window:CreateNotice(data: any) local tab=self:_getActiveTab(); if not tab then return nil end; return tab:CreateNotice(data) end
function Window:CreateStat(data: any) local tab=self:_getActiveTab(); if not tab then return nil end; return tab:CreateStat(data) end
function Window:CreateDivider(data: any?) local tab=self:_getActiveTab(); if not tab then return nil end; return tab:CreateDivider(data) end
function Window:CreateIconButton(data: any?) local tab=self:_getActiveTab(); if not tab then return nil end; return tab:CreateIconButton(data) end
function Window:CreateCard(data: any) local tab=self:_getActiveTab(); if not tab then return nil end; return tab:CreateCard(data) end
function Window:CreateBadge(data: any) local tab=self:_getActiveTab(); if not tab then return nil end; return tab:CreateBadge(data) end
function Window:CreateProgress(data: any) local tab=self:_getActiveTab(); if not tab then return nil end; return tab:CreateProgress(data) end
function Window:CreateStatus(data: any) local tab=self:_getActiveTab(); if not tab then return nil end; return tab:CreateStatus(data) end

function Window:SetVisible(visible: boolean)
	self._FloatDragging = false
	self._FloatDragInputType = nil
	self._Visible = visible

	if self.Gui then
		self.Gui.Enabled = true
	end
	if self._LayoutVariants and self._LayoutVariants.SetVisible then
		self._LayoutVariants:SetVisible(visible)
	end

	if self._ApplyBlurTarget then
		self._ApplyBlurTarget()
	end

	local function hideOpenControls()
		if self._IslandActivityHost then self._IslandActivityHost.Visible = false end
		if self._IslandActivity then self._IslandActivity.Visible = true end
		local islandBtn = self.Gui and self.Gui:FindFirstChild("Island")
		if islandBtn and islandBtn.Visible then
			local scale = islandBtn:FindFirstChild("IslandPopScale")
			if not scale then
				scale = Instance.new("UIScale")
				scale.Name = "IslandPopScale"
				scale.Scale = 1
				scale.Parent = islandBtn
			end
			Tween.Play(scale, { Scale = 0.82 }, {
				Time = 0.16,
				EasingStyle = Enum.EasingStyle.Quint,
				EasingDirection = Enum.EasingDirection.In,
			})
			if islandBtn:IsA("CanvasGroup") then
				Tween.Play(islandBtn, { GroupTransparency = 1 }, { Time = 0.16 })
			end
			task.delay(0.17, function()
				if islandBtn then
					islandBtn.Visible = false
					if scale then scale.Scale = 1 end
					if islandBtn:IsA("CanvasGroup") then
						islandBtn.GroupTransparency = 0
					end
				end
			end)
		elseif islandBtn then
			islandBtn.Visible = false
		end
		if self._ClassicOpen and self._ClassicOpen.Visible then
			local c = self._ClassicOpen
			local scale = c:FindFirstChild("IslandPopScale")
			if not scale then
				scale = Instance.new("UIScale")
				scale.Name = "IslandPopScale"
				scale.Scale = 1
				scale.Parent = c
			end
			Tween.Play(scale, { Scale = 0.7 }, { Time = 0.14 })
			task.delay(0.15, function()
				if c then
					c.Visible = false
					if scale then scale.Scale = 1 end
				end
			end)
		elseif self._ClassicOpen then
			self._ClassicOpen.Visible = false
		end
	end

	local function showOpenControls()
		if not self._StartupComplete then return end
		local useIsland = (self._OpenStyle or "Island") ~= "Button"
		local islandBtn = self.Gui and self.Gui:FindFirstChild("Island")
		if self._ClassicOpen then self._ClassicOpen.Visible = false end
		if islandBtn then islandBtn.Visible = false end
		if useIsland and islandBtn then
			self._FloatingButton = islandBtn
			local scale = islandBtn:FindFirstChild("IslandPopScale")
			if not scale then
				scale = Instance.new("UIScale")
				scale.Name = "IslandPopScale"
				scale.Parent = islandBtn
			end
			scale.Scale = 0.72
			islandBtn.Size = UDim2.fromOffset(168, 34)
			if islandBtn:IsA("CanvasGroup") then
				islandBtn.GroupTransparency = 1
			end
			islandBtn.Visible = true
			-- soft drop-in from slightly above
			local basePos = islandBtn.Position
			islandBtn.Position = UDim2.new(
				basePos.X.Scale, basePos.X.Offset,
				basePos.Y.Scale, basePos.Y.Offset - 12
			)
			Tween.Play(scale, { Scale = 1 }, {
				Time = 0.32,
				EasingStyle = Enum.EasingStyle.Back,
				EasingDirection = Enum.EasingDirection.Out,
			})
			Tween.Play(islandBtn, { Position = basePos }, {
				Time = 0.3,
				EasingStyle = Enum.EasingStyle.Quint,
				EasingDirection = Enum.EasingDirection.Out,
			})
			if islandBtn:IsA("CanvasGroup") then
				Tween.Play(islandBtn, { GroupTransparency = 0 }, { Time = 0.28 })
			end
		elseif self._ClassicOpen then
			self._FloatingButton = self._ClassicOpen
			local c = self._ClassicOpen
			local scale = c:FindFirstChild("IslandPopScale")
			if not scale then
				scale = Instance.new("UIScale")
				scale.Name = "IslandPopScale"
				scale.Parent = c
			end
			scale.Scale = 0.6
			c.Size = UDim2.fromOffset(50, 50)
			c.Visible = true
			Tween.Play(scale, { Scale = 1 }, {
				Time = 0.3,
				EasingStyle = Enum.EasingStyle.Back,
				EasingDirection = Enum.EasingDirection.Out,
			})
		end
	end

	if visible then
		hideOpenControls()
		if self.Main and self._StartupComplete then
			self.Main.Visible = true
			if not self._MainScale or not self._MainScale.Parent then
				local s = Instance.new("UIScale")
				s.Name = "OpenScale"
				s.Scale = 1
				s.Parent = self.Main
				self._MainScale = s
			end
			local base = self._MainBasePos or self.Main.Position
			self._MainBasePos = base
			local first = self._FirstReveal == true
			self._FirstReveal = false
			if first then
				-- Cinematic first reveal after boot
				self._MainScale.Scale = 0.72
				self.Main.Position = UDim2.new(
					base.X.Scale, base.X.Offset,
					base.Y.Scale, base.Y.Offset + 42
				)
				if self.Main:IsA("Frame") then
					-- soft pop shadow via transparency if available
				end
				Tween.Play(self._MainScale, { Scale = 1 }, {
					Time = 0.48,
					EasingStyle = Enum.EasingStyle.Back,
					EasingDirection = Enum.EasingDirection.Out,
				})
				Tween.Play(self.Main, { Position = base }, {
					Time = 0.45,
					EasingStyle = Enum.EasingStyle.Quint,
					EasingDirection = Enum.EasingDirection.Out,
				})
			else
				self._MainScale.Scale = 0.9
				self.Main.Position = UDim2.new(
					base.X.Scale, base.X.Offset,
					base.Y.Scale, base.Y.Offset + 16
				)
				Tween.Play(self._MainScale, { Scale = 1 }, {
					Time = 0.26,
					EasingStyle = Enum.EasingStyle.Back,
					EasingDirection = Enum.EasingDirection.Out,
				})
				Tween.Play(self.Main, { Position = base }, {
					Time = 0.26,
					EasingStyle = Enum.EasingStyle.Quint,
					EasingDirection = Enum.EasingDirection.Out,
				})
			end
		end
		if self._Dim then
			self._Dim.Visible = true
			local amount = math.clamp(self._DimAmount or 0.45, 0, 1)
			self._Dim.BackgroundTransparency = 1
			Tween.Play(self._Dim, { BackgroundTransparency = 1 - amount }, { Time = 0.25 })
		end
	else
		if self._Dim then
			Tween.Play(self._Dim, { BackgroundTransparency = 1 }, { Time = 0.2 })
		end
		if self.Main and self.Main.Visible then
			-- Snapshot current place BEFORE close anim so reopen keeps it
			self._MainBasePos = self.Main.Position
			local base = self._MainBasePos
			if self._MainScale then
				Tween.Play(self._MainScale, { Scale = 0.9 }, {
					Time = 0.16,
					EasingStyle = Enum.EasingStyle.Quint,
					EasingDirection = Enum.EasingDirection.In,
				})
			end
			Tween.Play(self.Main, {
				Position = UDim2.new(base.X.Scale, base.X.Offset, base.Y.Scale, base.Y.Offset + 14),
			}, { Time = 0.16, EasingStyle = Enum.EasingStyle.Quint, EasingDirection = Enum.EasingDirection.In })
			task.delay(0.17, function()
				if self.Main and not self._Visible then
					self.Main.Visible = false
					if self._MainScale then self._MainScale.Scale = 1 end
					-- Restore exact saved spot (not center)
					if self._MainBasePos then
						self.Main.Position = self._MainBasePos
					end
				end
				showOpenControls()
			end)
		else
			if self.Main then self.Main.Visible = false end
			showOpenControls()
		end
	end
end

function Window:Toggle()
	self:SetVisible(not self._Visible)
end

function Window:Notify(options: any)
	if self.Library and self.Library.Notifications and self.Library.Notifications.Notify then
		return self.Library.Notifications:Notify(options)
	end

	game:GetService("StarterGui"):SetCore("SendNotification", {
		Title = options.Title or "Vaxorin",
		Text = options.Content or options.Text or "",
		Duration = options.Duration or 5,
		Icon = Vaxorin_Logo,
	})
end

function Window:Destroy()
	if self._Destroyed then
		return
	end
	self._Destroyed = true

	if self._Weather and self._Weather.Destroy then
		pcall(function() self._Weather:Destroy() end)
		self._Weather = nil
	end
	if self._DimGui then
		pcall(function() self._DimGui:Destroy() end)
		self._DimGui = nil
	end
	if self._LayoutVariants then
		pcall(function() self._LayoutVariants:Destroy() end)
		self._LayoutVariants = nil
	end
	if self._DeveloperGui then
		self._DeveloperGui:Destroy()
		self._DeveloperGui = nil
	end
	if self._ESPBuilder then
		pcall(function() self._ESPBuilder:Close() end)
		self._ESPBuilder = nil
	end
	if self._ESPWorldRenderer then
		pcall(function() self._ESPWorldRenderer:Destroy() end)
		self._ESPWorldRenderer = nil
	end
	for _, tab in self._Tabs do
		if tab and tab.Destroy then
			tab:Destroy()
		end
	end
	table.clear(self._Tabs)
	self._ActiveTab = nil
	self._Maid:DoCleaning()
	if self.Gui then
		self.Gui:Destroy()
		self.Gui = nil
	end

	-- Keep Library._Windows accurate when a single window is destroyed.
	local library = self.Library
	if library and type(library._Windows) == "table" then
		for i = #library._Windows, 1, -1 do
			if library._Windows[i] == self then
				table.remove(library._Windows, i)
			end
		end
	end
end

print("🌌 Vaxorin loaded successfully!")
return Window