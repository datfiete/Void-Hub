--!strict
-- Vaxorin remote loader / V4
-- Current repository:
-- https://github.com/datfiete/Void-Hub/tree/main/CyberUI%20-%20Kopie

local sharedState = (getgenv and getgenv()) or _G
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local REPO = "https://raw.githubusercontent.com/datfiete/Void-Hub/main/CyberUI%20-%20Kopie/src"

local MODULE_PATHS = {
	"Utils/Maid",
	"Utils/Signal",
	"Utils/Tween",
	"Utils/Helpers",

	"Assets/Icons",

	"Core/Theme",
	"Core/Config",
	"Core/Notifications",

	"Elements/Toggle",
	"Elements/Button",
	"Elements/Slider",
	"Elements/Dropdown",
	"Elements/Input",
	"Elements/Keybind",
	"Elements/ColorPicker",
	"Elements/Paragraph",
	-- neu in 5.0:
	"Elements/Card",
	"Elements/Badge",
	"Elements/Progress",
	"Elements/Status",
	"Elements/Notice",
	"Elements/Stat",
	"Elements/Chart",
	"Elements/Divider",
	"Elements/IconButton",

	"Core/Section",
	"Core/Tab",
	"Core/ESPBuilder",
	"Core/ESPWorldRenderer",
	"Core/WorldRadar",
	"Core/LayoutVariants",   -- neu in 5.0
	"Core/Weather",
	"Core/Window",
}

local ACCENT = Color3.fromRGB(155, 92, 255)
local LOGO = "rbxassetid://135320038058277"

local function destroyBootstrapLoader()
	local loader = sharedState.CyberUI_BootstrapLoader
	sharedState.CyberUI_BootstrapLoader = nil

	if loader and loader.Parent then
		for _, child in loader:GetDescendants() do
			if child:IsA("TextLabel") then
				TweenService:Create(child, TweenInfo.new(0.2), { TextTransparency = 1 }):Play()
			elseif child:IsA("ImageLabel") then
				TweenService:Create(child, TweenInfo.new(0.2), { ImageTransparency = 1 }):Play()
			elseif child:IsA("Frame") then
				TweenService:Create(child, TweenInfo.new(0.22), { BackgroundTransparency = 1 }):Play()
			elseif child:IsA("UIStroke") then
				TweenService:Create(child, TweenInfo.new(0.2), { Transparency = 1 }):Play()
			end
		end
		task.delay(0.24, function()
			if loader and loader.Parent then
				loader:Destroy()
			end
		end)
	end
end

local function createBootstrapLoader()
	local player = Players.LocalPlayer
	if not player then
		return nil
	end

	local playerGui = player:WaitForChild("PlayerGui")

	local gui = Instance.new("ScreenGui")
	gui.Name = "CyberUI_BootstrapLoader"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = 2147483647
	pcall(function()
		gui.ScreenInsets = Enum.ScreenInsets.None
	end)
	gui.Parent = playerGui

	local backdrop = Instance.new("Frame")
	backdrop.Name = "Backdrop"
	backdrop.Size = UDim2.fromScale(1, 1)
	backdrop.BackgroundColor3 = Color3.fromRGB(4, 2, 10)
	backdrop.BackgroundTransparency = 0.12
	backdrop.BorderSizePixel = 0
	backdrop.Parent = gui

	-- bloom
	local bloom = Instance.new("Frame")
	bloom.Name = "Bloom"
	bloom.Size = UDim2.fromOffset(420, 420)
	bloom.Position = UDim2.fromScale(0.5, 0.5)
	bloom.AnchorPoint = Vector2.new(0.5, 0.5)
	bloom.BackgroundColor3 = ACCENT
	bloom.BackgroundTransparency = 0.92
	bloom.BorderSizePixel = 0
	bloom.Parent = backdrop
	local bloomCorner = Instance.new("UICorner")
	bloomCorner.CornerRadius = UDim.new(1, 0)
	bloomCorner.Parent = bloom

	-- Card kept for destroyBootstrapLoader compatibility (invisible full-area host)
	local card = Instance.new("Frame")
	card.Name = "Card"
	card.Size = UDim2.fromScale(1, 1)
	card.BackgroundTransparency = 1
	card.BorderSizePixel = 0
	card.Parent = gui

	local logoWrap = Instance.new("Frame")
	logoWrap.Name = "LogoWrap"
	logoWrap.Size = UDim2.fromOffset(88, 88)
	logoWrap.Position = UDim2.new(0.5, 0, 0.5, -64)
	logoWrap.AnchorPoint = Vector2.new(0.5, 0.5)
	logoWrap.BackgroundColor3 = Color3.fromRGB(20, 14, 32)
	logoWrap.BackgroundTransparency = 0.2
	logoWrap.BorderSizePixel = 0
	logoWrap.Parent = backdrop
	local logoCorner = Instance.new("UICorner")
	logoCorner.CornerRadius = UDim.new(0, 26)
	logoCorner.Parent = logoWrap
	local logoStroke = Instance.new("UIStroke")
	logoStroke.Color = ACCENT
	logoStroke.Thickness = 1.4
	logoStroke.Transparency = 0.3
	logoStroke.Parent = logoWrap

	local logo = Instance.new("ImageLabel")
	logo.Name = "Logo"
	logo.BackgroundTransparency = 1
	logo.Size = UDim2.fromScale(0.7, 0.7)
	logo.Position = UDim2.fromScale(0.5, 0.5)
	logo.AnchorPoint = Vector2.new(0.5, 0.5)
	logo.Image = LOGO
	logo.ScaleType = Enum.ScaleType.Fit
	logo.Parent = logoWrap

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.fromOffset(400, 34)
	title.Position = UDim2.new(0.5, 0, 0.5, 0)
	title.AnchorPoint = Vector2.new(0.5, 0)
	title.BackgroundTransparency = 1
	title.Text = "Vaxorin"
	title.TextColor3 = Color3.fromRGB(245, 240, 255)
	title.TextSize = 28
	title.Font = Enum.Font.GothamBold
	title.Parent = backdrop

	local status = Instance.new("TextLabel")
	status.Name = "Status"
	status.Size = UDim2.fromOffset(420, 20)
	status.Position = UDim2.new(0.5, 0, 0.5, 40)
	status.AnchorPoint = Vector2.new(0.5, 0)
	status.BackgroundTransparency = 1
	status.Text = "Loading modules…"
	status.TextColor3 = Color3.fromRGB(150, 140, 170)
	status.TextSize = 13
	status.Font = Enum.Font.GothamMedium
	status.Parent = backdrop

	local track = Instance.new("Frame")
	track.Name = "Track"
	track.Size = UDim2.fromOffset(220, 3)
	track.Position = UDim2.new(0.5, 0, 0.5, 74)
	track.AnchorPoint = Vector2.new(0.5, 0)
	track.BackgroundColor3 = Color3.fromRGB(40, 32, 55)
	track.BorderSizePixel = 0
	track.Parent = backdrop
	local trackCorner = Instance.new("UICorner")
	trackCorner.CornerRadius = UDim.new(1, 0)
	trackCorner.Parent = track

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(0.02, 1)
	fill.BackgroundColor3 = ACCENT
	fill.BorderSizePixel = 0
	fill.Parent = track
	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(1, 0)
	fillCorner.Parent = fill

	local percent = Instance.new("TextLabel")
	percent.Name = "Percent"
	percent.Size = UDim2.fromOffset(80, 18)
	percent.Position = UDim2.new(0.5, 0, 0.5, 88)
	percent.AnchorPoint = Vector2.new(0.5, 0)
	percent.BackgroundTransparency = 1
	percent.Text = "0%"
	percent.TextColor3 = Color3.fromRGB(220, 210, 240)
	percent.TextSize = 12
	percent.Font = Enum.Font.GothamBold
	percent.Parent = backdrop

	-- Put Status on card as well so setStatus keeps working (primary status is on backdrop)
	local statusRef = Instance.new("TextLabel")
	statusRef.Name = "Status"
	statusRef.BackgroundTransparency = 1
	statusRef.Size = UDim2.fromOffset(0, 0)
	statusRef.Text = ""
	statusRef.Visible = false
	statusRef.Parent = card

	sharedState.CyberUI_BootstrapLoader = gui
	return gui
end

local function setStatus(gui: ScreenGui?, text: string, progress: number?)
	if not gui then
		return
	end

	local clean = tostring(text or "")
	clean = clean:gsub("^Loading%s+", ""):gsub("%.%.%.$", "")
	clean = clean:gsub("/", " / ")
	if clean == "" then
		clean = "Loading…"
	end

	local backdrop = gui:FindFirstChild("Backdrop")
	if backdrop then
		local s = backdrop:FindFirstChild("Status")
		if s and s:IsA("TextLabel") then
			s.Text = clean
		end
		if typeof(progress) == "number" then
			local track = backdrop:FindFirstChild("Track")
			local fill = track and track:FindFirstChild("Fill")
			local percent = backdrop:FindFirstChild("Percent")
			local p = math.clamp(progress, 0, 1)
			if fill and fill:IsA("Frame") then
				TweenService:Create(fill, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
					Size = UDim2.fromScale(math.max(0.03, p), 1),
				}):Play()
			end
			if percent and percent:IsA("TextLabel") then
				percent.Text = tostring(math.floor(p * 100 + 0.5)) .. "%"
			end
		end
	end
end

local bootstrap = createBootstrapLoader()

-- Download every module with an explicit error so a bad/missing GitHub file
-- no longer looks like Vaxorin simply "closing".
local sources: { [string]: string } = {}

local _fetchIndex = 0
local _fetchTotal = #MODULE_PATHS

local function fetch(path: string): string
	_fetchIndex += 1
	local progress = _fetchIndex / math.max(1, _fetchTotal)
	setStatus(bootstrap, path, progress)

	local url = REPO .. "/" .. path .. ".lua"
	local ok, result = pcall(function()
		return game:HttpGet(url)
	end)

	if not ok then
		error(
			("Vaxorin failed to download module:\n%s\n\nURL:\n%s\n\nError:\n%s")
				:format(path, url, tostring(result)),
			2
		)
	end

	if type(result) ~= "string" or #result == 0 then
		error(
			("Vaxorin received an empty response for:\n%s\n\nURL:\n%s")
				:format(path, url),
			2
		)
	end

	return result
end

sources["init"] = fetch("init")

for _, path in MODULE_PATHS do
	sources[path] = fetch(path)
end

local exports: { [string]: any } = {}
local scriptMocks: { [string]: any } = {}

local function pathName(path: string): string
	if path == "init" then
		return "Vaxorin"
	end

	return string.match(path, "([^/]+)$") or path
end

local function parentPath(path: string): string?
	if path == "init" then
		return nil
	end

	local parent = string.match(path, "(.+)/[^/]+$")
	if parent then
		return parent
	end

	return "init"
end

local function childPath(path: string, key: string): string
	if path == "init" then
		return key
	end

	return path .. "/" .. key
end

local function hasChildModule(path: string): boolean
	local prefix = path .. "/"

	for candidatePath, _ in pairs(sources) do
		if string.sub(candidatePath, 1, #prefix) == prefix then
			return true
		end
	end

	return false
end

local function getScriptMock(path: string): any
	if scriptMocks[path] then
		return scriptMocks[path]
	end

	local mock = {}
	scriptMocks[path] = mock

	setmetatable(mock, {
		__index = function(_, key: string)
			if key == "Name" then
				return pathName(path)
			elseif key == "Parent" then
				local parent = parentPath(path)
				return if parent then getScriptMock(parent) else nil
			elseif key == "ClassName" then
				return "ModuleScript"
			end

			local nextPath = childPath(path, key)

			if sources[nextPath] or hasChildModule(nextPath) then
				return getScriptMock(nextPath)
			end

			return nil
		end,
	})

	return mock
end

local function requireModule(path: string): any
	if exports[path] then
		return exports[path]
	end

	local source = sources[path]
	if not source then
		error("Vaxorin module not found: " .. path, 2)
	end

	local chunk, compileError = loadstring(source, "CyberUI/" .. path)

	if not chunk then
		error(
			("Vaxorin failed to compile module:\n%s\n\n%s")
				:format(path, tostring(compileError)),
			2
		)
	end

	local moduleScript = getScriptMock(path)

	local function cyberRequire(target: any)
		if typeof(target) ~= "table" then
			error("Vaxorin require expected a module reference", 2)
		end

		local targetPath = target._cyberPath

		if not targetPath then
			for candidatePath, candidateMock in pairs(scriptMocks) do
				if candidateMock == target then
					targetPath = candidatePath
					break
				end
			end
		end

		if not targetPath then
			error("Vaxorin require could not resolve module", 2)
		end

		return requireModule(targetPath)
	end

	for candidatePath in pairs(sources) do
		getScriptMock(candidatePath)._cyberPath = candidatePath
	end

	local env = setmetatable({
		script = moduleScript,
		require = cyberRequire,
	}, {
		__index = getfenv and getfenv() or _G,
	})

	setfenv(chunk, env)

	local ok, result = xpcall(function()
		return chunk()
	end, function(err)
		return tostring(err) .. "\n" .. debug.traceback()
	end)

	if not ok then
		error(
			("Vaxorin failed while executing module:\n%s\n\n%s")
				:format(path, tostring(result)),
			2
		)
	end

	exports[path] = result
	return result
end

local ok, result = xpcall(function()
	setStatus(bootstrap, "Starting Vaxorin...")
	return requireModule("init")
end, function(err)
	return tostring(err) .. "\n" .. debug.traceback()
end)

if not ok then
	setStatus(bootstrap, "Vaxorin failed to load. Check the error below.")

	warn("========== VAXORIN LOAD ERROR ==========")
	warn(tostring(result))
	warn("========================================")

	if bootstrap then
		local card = bootstrap:FindFirstChild("Card")
		if card then
			local errorLabel = card:FindFirstChild("Error")
			if not errorLabel then
				errorLabel = Instance.new("TextLabel")
				errorLabel.Name = "Error"
				errorLabel.Size = UDim2.new(1, -48, 0, 28)
				errorLabel.Position = UDim2.fromOffset(34, 72)
				errorLabel.BackgroundTransparency = 1
				errorLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
				errorLabel.TextSize = 11
				errorLabel.Font = Enum.Font.Gotham
				errorLabel.TextWrapped = true
				errorLabel.TextXAlignment = Enum.TextXAlignment.Left
				errorLabel.TextYAlignment = Enum.TextYAlignment.Top
				errorLabel.Text = "See F9 console for the full error."
				errorLabel.Parent = card
			end
		end

		task.delay(10, function()
			if bootstrap and bootstrap.Parent then
				bootstrap:Destroy()
			end
			if sharedState.CyberUI_BootstrapLoader == bootstrap then
				sharedState.CyberUI_BootstrapLoader = nil
			end
		end)
	end

	error(result, 0)
end

task.delay(0.25, function()
	if sharedState.CyberUI_BootstrapLoader == bootstrap then
		destroyBootstrapLoader()
	end
end)

return result
