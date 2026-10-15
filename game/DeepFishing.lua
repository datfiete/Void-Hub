local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local VIM = game:GetService("VirtualInputManager")
local Workspace = game:GetService("Workspace")

local Executor = "unknown"
pcall(function()
	if type(getexecutorname) == "function" then
		Executor = tostring(getexecutorname())
	elseif type(identifyexecutor) == "function" then
		Executor = tostring(identifyexecutor())
	end
end)

local Vaxorin = loadstring(game:HttpGet(
	"https://raw.githubusercontent.com/datfiete/Void-Hub/refs/heads/main/CyberUI%20-%20Kopie/load.lua"
))()

pcall(function()
	if Vaxorin.Theme then
		Vaxorin.Theme.Style = "Vaxorin"
	end
end)

local avatar = ""
pcall(function()
	avatar = Players:GetUserThumbnailAsync(
		LocalPlayer.UserId,
		Enum.ThumbnailType.HeadShot,
		Enum.ThumbnailSize.Size150x150
	)
end)

local window = Vaxorin:CreateWindow({
	Title = "[PETS] Deep Fishing🎣",
	Subtitle = "by Fietewoozle",
	Logo = "rbxassetid://135320038058277",

	Badges = {
		{ Text = "Vaxorin | v1.0" },
		{ Text = "Executor : " .. Executor },
	},

	Footer = {
		Avatar = avatar,
		Username = LocalPlayer.Name,
		Status = "Ready",
	},

	DiscordLink = "https://discord.gg/example",
	ShowSearch = true,
	ShowWindowControls = true,
	ToggleKey = Enum.KeyCode.RightControl,
	TopMost = true,

	ConfigurationSaving = {
		Enabled = true,
		AutoSave = true,
		FolderName = "Vaxorin",
		FileName = "Deep Fishing",
	},
})

window:SetProfileStatus("Ready")
window:SetWatermarkEnabled(true)

local Farmtab = window:CreateTab("Main")
local Farmsection = Farmtab:CreateSection({
	Name = "Main",
	Description = "Fishing settings",
})

Farmsection:CreateNotice({
	Title = "INFO",
	Content = "Turn on both toggles for full auto. Use Mode to choose target priority."
})

----------------------------------------------------------------
-- Variables
----------------------------------------------------------------
local MultiLabel = LocalPlayer.PlayerGui.HUD.Fishing.Hook.TextLabel

local AutoThrow = false
local AutoFish  = false
local Mode      = "Closest"   -- "Closest" or "Highest Value"

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------
local function GetBait()
	for _, v in ipairs(Workspace:GetChildren()) do
		if v:IsA("BasePart") and v.Name == "Bait" and v:FindFirstChild("Bounce1") then
			return v
		end
	end
end

local function IsFish(obj)
	if not obj:IsA("Model") then return false end
	local name = obj.Name
	if name:find("Boss") or name:find("Kite") or name:find("Toxic") then return false end
	if Players:FindFirstChild(name) then return false end
	return true
end

local function GetTargetFish()
	local bait = GetBait()
	if not bait then return nil, 0 end

	local bestFish = nil
	local bestScore = -math.huge
	local bestDist  = math.huge
	local count = 0

	for _, obj in ipairs(Workspace:GetChildren()) do
		if IsFish(obj) then
			local pos = obj:GetPivot().Position

			-- Only fish that are clearly above the bait
			if pos.Y > bait.Position.Y + 1.2 then
				count = count + 1

				local dist = (pos - bait.Position).Magnitude
				local price = 0

				if Mode == "Highest Value" then
					local hitbox = obj:FindFirstChild("Hitbox")
					if hitbox then
						local tag = hitbox:FindFirstChild("RarityTag")
						if tag then
							local label = tag:FindFirstChild("Price")
							if label and label:IsA("TextLabel") then
								price = tonumber(label.Text:match("[%d%.]+")) or 0
							end
						end
					end
				end

				-- Score system
				local score = (Mode == "Highest Value") and price or -dist

				if score > bestScore or (score == bestScore and dist < bestDist) then
					bestScore = score
					bestDist  = dist
					bestFish  = obj
				end
			end
		end
	end

	return bestFish, count
end

local function SetMovement(left, right)
	VIM:SendKeyEvent(left,  Enum.KeyCode.Left,  false, game)
	VIM:SendKeyEvent(right, Enum.KeyCode.Right, false, game)
	VIM:SendKeyEvent(left,  Enum.KeyCode.A,     false, game)
	VIM:SendKeyEvent(right, Enum.KeyCode.D,     false, game)
end

----------------------------------------------------------------
-- UI
----------------------------------------------------------------
Farmsection:CreateDropdown({
	Name = "Target Mode",
	Options = {"Closest", "Highest Value"},
	CurrentOption = {"Closest"},
	MultipleOptions = false,
	Flag = "Feature.Mode",
	Save = true,
	Callback = function(v)
		if type(v) == "table" then v = v[1] end
		Mode = v or "Closest"
	end,
})

----------------------------------------------------------------
-- Auto Throw
----------------------------------------------------------------
Farmsection:CreateToggle({
	Name = "Auto Throw",
	CurrentValue = false,
	Flag = "Feature.AutoThrow",
	Save = true,
	Callback = function(value)
		AutoThrow = value

		if not value then return end

		task.spawn(function()
			while AutoThrow do
				local _, count = GetTargetFish()

				if count == 0 then
					-- Throw
					VIM:SendMouseButtonEvent(0, 0, 0, true, game, 1)
					task.wait(0.32)
					VIM:SendMouseButtonEvent(0, 0, 0, false, game, 1)
					task.wait(1.0)
				end

				task.wait(0.12)
			end
		end)
	end,
})

----------------------------------------------------------------
-- Auto Fish (move + reel)
----------------------------------------------------------------
Farmsection:CreateToggle({
	Name = "Auto Fish",
	CurrentValue = false,
	Flag = "Feature.AutoFish",
	Save = true,
	Callback = function(value)
		AutoFish = value

		if not value then
			SetMovement(false, false)
			VIM:SendMouseButtonEvent(0, 0, 0, false, game, 1)
			return
		end

		task.spawn(function()
			while AutoFish do
				local fish, count = GetTargetFish()
				local bait = GetBait()

				if fish and bait and count > 0 then
					-- Keep mouse held (reeling)
					VIM:SendMouseButtonEvent(0, 0, 0, true, game, 1)

					-- Perfect catch
					if MultiLabel.Text == "x2.0" then
						VIM:SendMouseButtonEvent(0, 0, 0, false, game, 1)
						task.wait(0.09)
					end

					-- Move on Z axis
					local diffZ = fish:GetPivot().Position.Z - bait.Position.Z

					if diffZ < -1.0 then
						SetMovement(false, true)   -- Right
					elseif diffZ > 1.0 then
						SetMovement(true, false)   -- Left
					else
						SetMovement(false, false)
					end
				else
					SetMovement(false, false)
				end

				task.wait(0.025) -- very responsive
			end

			SetMovement(false, false)
			VIM:SendMouseButtonEvent(0, 0, 0, false, game, 1)
		end)
	end,
})