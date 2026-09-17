--!strict
-- Vaxorin remote loader
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

	"Core/Section",
	"Core/Tab",
	"Core/ESPBuilder",
	"Core/ESPWorldRenderer",
	"Core/WorldRadar",
	"Core/Window",
}

local function destroyBootstrapLoader()
	local loader = sharedState.CyberUI_BootstrapLoader
	sharedState.CyberUI_BootstrapLoader = nil

	if loader and loader.Parent then
		local card = loader:FindFirstChild("Card")
		if card then
			for _, child in card:GetDescendants() do
				if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") then
					TweenService:Create(child, TweenInfo.new(0.15), {
						TextTransparency = 1,
					}):Play()
				elseif child:IsA("Frame") then
					TweenService:Create(child, TweenInfo.new(0.15), {
						BackgroundTransparency = 1,
					}):Play()
				elseif child:IsA("UIStroke") then
					TweenService:Create(child, TweenInfo.new(0.15), {
						Transparency = 1,
					}):Play()
				end
			end

			TweenService:Create(card, TweenInfo.new(0.15), {
				BackgroundTransparency = 1,
			}):Play()
		end

		task.delay(0.16, function()
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
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = 2147483647

	pcall(function()
		gui.ScreenInsets = Enum.ScreenInsets.None
	end)

	gui.Parent = playerGui

	local card = Instance.new("Frame")
	card.Name = "Card"
	card.Size = UDim2.fromOffset(360, 150)
	card.Position = UDim2.fromScale(0.5, 0.5)
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
	card.BorderSizePixel = 0
	card.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = card

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(40, 40, 55)
	stroke.Thickness = 1
	stroke.Parent = card

	local accent = Instance.new("Frame")
	accent.Name = "Accent"
	accent.Size = UDim2.new(0, 4, 1, -32)
	accent.Position = UDim2.fromOffset(16, 16)
	accent.BackgroundColor3 = Color3.fromRGB(0, 255, 200)
	accent.BorderSizePixel = 0
	accent.Parent = card

	local accentCorner = Instance.new("UICorner")
	accentCorner.CornerRadius = UDim.new(0, 2)
	accentCorner.Parent = accent

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -48, 0, 28)
	title.Position = UDim2.fromOffset(34, 18)
	title.BackgroundTransparency = 1
	title.Text = "Vaxorin"
	title.TextColor3 = Color3.fromRGB(240, 240, 240)
	title.TextSize = 20
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = card

	local status = Instance.new("TextLabel")
	status.Name = "Status"
	status.Size = UDim2.new(1, -48, 0, 20)
	status.Position = UDim2.fromOffset(34, 52)
	status.BackgroundTransparency = 1
	status.Text = "Loading library..."
	status.TextColor3 = Color3.fromRGB(160, 160, 170)
	status.TextSize = 13
	status.Font = Enum.Font.GothamMedium
	status.TextXAlignment = Enum.TextXAlignment.Left
	status.Parent = card

	local track = Instance.new("Frame")
	track.Name = "Track"
	track.Size = UDim2.new(1, -48, 0, 6)
	track.Position = UDim2.fromOffset(34, 102)
	track.BackgroundColor3 = Color3.fromRGB(13, 13, 18)
	track.BorderSizePixel = 0
	track.Parent = card

	local trackCorner = Instance.new("UICorner")
	trackCorner.CornerRadius = UDim.new(0, 3)
	trackCorner.Parent = track

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(0.08, 1)
	fill.BackgroundColor3 = Color3.fromRGB(0, 255, 200)
	fill.BorderSizePixel = 0
	fill.Parent = track

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 3)
	fillCorner.Parent = fill

	TweenService:Create(fill, TweenInfo.new(2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Size = UDim2.fromScale(0.88, 1),
	}):Play()

	sharedState.CyberUI_BootstrapLoader = gui
	return gui
end

local function setStatus(gui: ScreenGui?, text: string)
	if not gui then
		return
	end

	local card = gui:FindFirstChild("Card")
	if not card then
		return
	end

	local status = card:FindFirstChild("Status")
	if status and status:IsA("TextLabel") then
		status.Text = text
	end
end

local bootstrap = createBootstrapLoader()

-- Download every module with an explicit error so a bad/missing GitHub file
-- no longer looks like Vaxorin simply "closing".
local sources: { [string]: string } = {}

local function fetch(path: string): string
	setStatus(bootstrap, "Loading " .. path .. "...")

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
