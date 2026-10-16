local SELF = [===[
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
if not game:IsLoaded() then game.Loaded:Wait() end
local LP = Players.LocalPlayer or Players.PlayerAdded:Wait()
local env = (getgenv and getgenv()) or _G
if env.needle_farm and env.needle_farm.stop then pcall(env.needle_farm.stop) end
local HttpService = game:GetService("HttpService")
local match_maps = { [108628039999641] = "FARMHOUSE", [83445806734780] = "BASEMENT" }
local state_dir = "needle"
local state_file = "needle/state.json"
local SELF = ...
local queue_payload = type(SELF) == "string" and ("getgenv().needle_queued = true\nlocal SELF = [===" .. "["
	.. SELF .. "]===" .. "]\nloadstring(SELF, \"=needle\")(SELF)\n") or nil
local function load_state()
	if not (isfile and readfile) then return {} end
	local ok, raw = pcall(function()
		if not isfile(state_file) then return nil end
		return readfile(state_file)
	end)
	if not ok or type(raw) ~= "string" then return {} end
	local ok2, data = pcall(function() return HttpService:JSONDecode(raw) end)
	if ok2 and type(data) == "table" then return data end
	return {}
end
local function save_state(data)
	if not writefile then return end
	pcall(function()
		if makefolder and isfolder and not isfolder(state_dir) then makefolder(state_dir) end
		writefile(state_file, HttpService:JSONEncode(data))
	end)
end
local saved = load_state()
local saved_cfg = type(saved.cfg) == "table" and saved.cfg or {}
local queued_start = env.needle_queued == true
env.needle_queued = nil
local rejoin = {
	on = queued_start and saved.rejoin == true,
	map = saved.map or match_maps[game.PlaceId] or "FARMHOUSE",
	difficulty = saved.difficulty or "NORMAL",
	size = tonumber(saved.size) or 1,
}
local cfg = {
	farm = false, gems = false, rareFirst = false, autoSell = false, useTools = false,
	needle = false,
	buyDrone = false, buyTools = false, buyUpgrades = false, buyDroneUpgrades = false, buyToolUpgrades = false,
}
if queued_start then
	for k in pairs(cfg) do cfg[k] = saved_cfg[k] == true end
end
local session = (queued_start and type(saved.session) == "string" and saved.session)
	or (tostring(os.time()) .. "-" .. tostring(math.random(1000, 9999)))
local last_sig
local function state_sig()
	local keys = {}
	for k in pairs(cfg) do keys[#keys + 1] = k end
	table.sort(keys)
	local parts = { session, tostring(rejoin.on), tostring(rejoin.map), tostring(rejoin.difficulty), tostring(rejoin.size) }
	for _, k in ipairs(keys) do parts[#parts + 1] = k .. "=" .. tostring(cfg[k]) end
	return table.concat(parts, "|")
end
local function persist(force)
	local sig = state_sig()
	if not force and sig == last_sig then return false end
	local snap = {}
	for k, v in pairs(cfg) do snap[k] = v end
	save_state({
		session = session,
		saved_at = os.time(),
		rejoin = rejoin.on,
		map = rejoin.map,
		difficulty = rejoin.difficulty,
		size = rejoin.size,
		cfg = snap,
	})
	last_sig = sig
	return true
end
local watch_alive = true
task.spawn(function()
	while watch_alive do
		pcall(persist)
		task.wait(1)
	end
end)
local function queue_self()
	local q = queue_on_teleport or queueonteleport or queueteleport
	if not (q and queue_payload) then return false end
	if clearqueueonteleport then pcall(clearqueueonteleport) end
	return (pcall(q, queue_payload))
end
local function unqueue_self()
	if clearqueueonteleport then pcall(clearqueueonteleport) end
end
local function root_part()
	local c = LP and LP.Character
	return c and c:FindFirstChild("HumanoidRootPart")
end
local function idle_pad()
	local r = root_part()
	if not r then return nil end
	local best, best_dist
	for _, pad in ipairs(Workspace:GetChildren()) do
		if pad.Name == "Teleporter" and pad:GetAttribute("PartyStatus") == "Idle" then
			local ok, pivot = pcall(function() return pad:GetPivot().Position end)
			if ok then
				local d = (pivot - r.Position).Magnitude
				if not best_dist or d < best_dist then best, best_dist = pad, d end
			end
		end
	end
	return best
end
local function create_party()
	local spawn_deadline = os.clock() + 20
	while not root_part() and os.clock() < spawn_deadline do task.wait(0.25) end
	if not root_part() then return false end
	local pad = idle_pad()
	if not pad then return false end
	local spot = pad:GetPivot().Position
	local deadline = os.clock() + 8
	while os.clock() < deadline and pad:GetAttribute("PartyStatus") ~= "Setup" do
		local r = root_part()
		if not r then return false end
		r.CFrame = CFrame.new(spot + Vector3.new(0, 3, 0))
		pcall(function() r.AssemblyLinearVelocity = Vector3.zero end)
		RunService.Heartbeat:Wait()
	end
	if pad:GetAttribute("PartyStatus") ~= "Setup" then return false end
	local ok, party = pcall(function() return require(RS.Shared.Services.PartyService.PartyServiceClient) end)
	if not (ok and type(party) == "table" and party.networker) then return false end
	queue_self()
	return (pcall(function()
		party.networker:fire("CreateParty", rejoin.map, rejoin.size, rejoin.difficulty)
	end))
end

-- ── CyberUI / Vaxorin loader ──────────────────────────────────────────────
local Vaxorin = loadstring(game:HttpGet(
	"https://raw.githubusercontent.com/datfiete/Void-Hub/refs/heads/main/CyberUI%20-%20Kopie/load.lua"
))()

local in_match = match_maps[game.PlaceId] ~= nil or RS:FindFirstChild("NeedleHaystack") ~= nil
if not in_match then
	local running_lobby = true
	local Window = Vaxorin:CreateWindow({
		Title = "needle",
		Subtitle = "lobby · auto rejoin",
		ToggleKey = Enum.KeyCode.RightControl,
		ShowSearch = false,
		ShowWindowControls = true,
	})
	local tab = Window:CreateTab("rejoin")
	local section = tab:CreateSection({ Name = "next match" })
	local info = section:CreateParagraph({
		Title = "settings",
		Content = "loading...",
	})
	local function refresh()
		pcall(function()
			info:Set(("map: %s\ndifficulty: %s\nparty size: %s"):format(rejoin.map, rejoin.difficulty, tostring(rejoin.size)))
		end)
	end
	refresh()
	section:CreateToggle({
		Name = "auto start a match",
		Flag = "rejoin",
		Default = rejoin.on,
		Callback = function(v)
			rejoin.on = v
			if v then queue_self() else unqueue_self() end
			persist()
		end,
	})
	section:CreateButton({
		Name = "start a match now",
		Callback = function() task.spawn(create_party) end,
	})
	section:CreateButton({
		Name = "next map",
		Callback = function()
			rejoin.map = rejoin.map == "FARMHOUSE" and "BASEMENT" or "FARMHOUSE"
			persist()
			refresh()
		end,
	})
	section:CreateButton({
		Name = "next difficulty",
		Callback = function()
			rejoin.difficulty = rejoin.difficulty == "NORMAL" and "HARD" or "NORMAL"
			persist()
			refresh()
		end,
	})
	section:CreateButton({
		Name = "party size 1-4",
		Callback = function()
			rejoin.size = (rejoin.size % 4) + 1
			persist()
			refresh()
		end,
	})
	task.spawn(function()
		while running_lobby do
			if rejoin.on then
				if create_party() then task.wait(12) else task.wait(4) end
			else
				task.wait(1)
			end
		end
	end)
	pcall(function()
		Vaxorin:Notify({
			Title = "needle loaded",
			Content = "RightControl to toggle · lobby mode",
			Type = "Success",
			Duration = 4,
		})
	end)
	env.needle_farm = {
		cfg = cfg,
		rejoin = rejoin,
		stop = function()
			running_lobby = false
			pcall(persist, true)
			watch_alive = false
			pcall(function() Window:Destroy() end)
		end,
	}
	return
end

local NH = RS:WaitForChild("NeedleHaystack")
local R = {}
for _, name in ipairs({ "PickHay", "SellHay", "BuyShopItem", "BuyUpgrade", "DeployDrone", "PitchforkDig",
	"TntAction", "VacuumAction", "NeedleHandIn", "NeedleTargetChanged", "CollectGem" }) do
	R[name] = NH:WaitForChild(name, 10)
end
local okCfg, Config = pcall(require, NH:WaitForChild("Config"))
if not okCfg or type(Config) ~= "table" then Config = {} end
local pick_cd = (tonumber(Config.PICK_COOLDOWN) or 0.55) + 0.04
local fork_cd = (tonumber(Config.PITCHFORK_COOLDOWN) or 0.85) + 0.05
local dig_radius = tonumber(Config.NEEDLE_DIG_RADIUS) or 5.5
local sell_tag = Config.SELL_PART_NAME or "SellPart"
local running = true
local conns = {}
local function root()
	local c = LP.Character
	return c and c:FindFirstChild("HumanoidRootPart")
end
local function attr(name, default)
	local v = LP:GetAttribute(name)
	if v == nil then return default end
	return v
end
local function pickDelay()
	local live = tonumber(attr("HayPickCooldown", nil))
	return live and (live + 0.04) or pick_cd
end
local function cash()
	local ls = LP:FindFirstChild("leaderstats")
	local c = ls and ls:FindFirstChild("Cash")
	return (c and tonumber(c.Value)) or 0
end
local function hayFolder()
	return Workspace:FindFirstChild("HaystackClient")
end
local function moveTo(pos)
	local r = root()
	if not r then return false end
	r.CFrame = CFrame.new(pos + Vector3.new(0, 3, 1.5))
	pcall(function() r.AssemblyLinearVelocity = Vector3.zero end)
	return true
end
local function settle(frames)
	for _ = 1, frames or 2 do RunService.Heartbeat:Wait() end
end
local recentlyPicked = {}
local mutation_value = {}
do
	local list = Config.HAY_MUTATIONS
	if type(list) == "table" then
		for _, m in ipairs(list) do
			if type(m) == "table" and m.Name then
				mutation_value[tostring(m.Name)] = tonumber(m.ValueMultiplier) or 1
			end
		end
	end
end
local function chooseTarget()
	local hc, r = hayFolder(), root()
	if not (hc and r) then return nil end
	local me, now = r.Position, os.clock()
	local best, bestDist
	local rare, rareDist, rareMult
	for _, piece in ipairs(hc:GetChildren()) do
		local id = piece:GetAttribute("HayId")
		local stamp = id and recentlyPicked[id]
		if id and not (stamp and now - stamp < 6) then
			local d = (piece.Position - me).Magnitude
			if cfg.rareFirst then
				local mult = mutation_value[tostring(piece:GetAttribute("HayMutation"))]
				if mult and mult > 1 and (not rareMult or mult > rareMult or (mult == rareMult and d < rareDist)) then
					rare, rareDist, rareMult = piece, d, mult
				end
			end
			if not bestDist or d < bestDist then best, bestDist = piece, d end
		end
	end
	return rare or best
end
local function grabCandidates(target)
	local count = tonumber(attr("HayGrabCount", 1)) or 1
	local radius = tonumber(attr("HayGrabRadius", 1.35)) or 1.35
	local list = {}
	if count <= 1 or radius <= 0 then return list end
	local ok, parts = pcall(function() return Workspace:GetPartBoundsInRadius(target.Position, radius) end)
	if not ok then return list end
	for _, p in ipairs(parts) do
		local id = p:GetAttribute("HayId")
		if id and p ~= target and p.Parent == target.Parent then
			list[#list + 1] = id
			if #list >= count * 3 then break end
		end
	end
	return list
end
local function pickPiece(piece)
	local id = piece and piece:GetAttribute("HayId")
	if not id then return end
	recentlyPicked[id] = os.clock()
	R.PickHay:FireServer(id, grabCandidates(piece))
	return id
end
local recentGems = {}
local function collectNearestGem()
	local folder = Workspace:FindFirstChild("GemsClient")
	local r = root()
	if not (folder and r) then return false end
	local best, bestDist, bestId
	local now = os.clock()
	for _, model in ipairs(folder:GetChildren()) do
		local part = model:FindFirstChildWhichIsA("BasePart", true)
		local id = part and part:GetAttribute("GemId")
		if id and not (recentGems[id] and now - recentGems[id] < 4) then
			local d = (part.Position - r.Position).Magnitude
			if not bestDist or d < bestDist then best, bestDist, bestId = part, d, id end
		end
	end
	if not best then return false end
	recentGems[bestId] = now
	r.CFrame = CFrame.new(best.Position + Vector3.new(0, 2.5, 0))
	pcall(function() r.AssemblyLinearVelocity = Vector3.zero end)
	local holdUntil = os.clock() + (bestDist > 30 and 0.35 or 0.05)
	while os.clock() < holdUntil do RunService.Heartbeat:Wait() end
	pcall(function() R.CollectGem:FireServer(bestId) end)
	task.wait(0.15)
	return true
end
local function sellPart()
	local best, bestSize
	for _, p in ipairs(CollectionService:GetTagged(sell_tag)) do
		if p:IsA("BasePart") and p:IsDescendantOf(Workspace) then
			local s = p.Size.X * p.Size.Y * p.Size.Z
			if not bestSize or s > bestSize then best, bestSize = p, s end
		end
	end
	return best
end
local function sellNow()
	local part, r = sellPart(), root()
	if not (part and r) then return end
	local stand = part.Position + part.CFrame.LookVector * 6 + Vector3.new(0, 2, 0)
	local cam = Workspace.CurrentCamera
	local previous = cam.CameraType
	pcall(function()
		cam.CameraType = Enum.CameraType.Scriptable
		cam.CFrame = CFrame.lookAt(stand + Vector3.new(0, 1.5, 0), part.Position)
	end)
	local startHeld = tonumber(attr("HayHeld", 0)) or 0
	for _ = 1, 4 do
		local holdUntil = os.clock() + 0.5
		while os.clock() < holdUntil do
			r.CFrame = CFrame.lookAt(stand, part.Position)
			pcall(function() r.AssemblyLinearVelocity = Vector3.zero end)
			RunService.Heartbeat:Wait()
		end
		R.SellHay:FireServer()
		task.wait(0.7)
		if (tonumber(attr("HayHeld", 0)) or 0) < startHeld then break end
	end
	pcall(function() cam.CameraType = previous end)
end
local okHotbar, Hotbar = pcall(function() return require(LP.PlayerScripts:WaitForChild("HotbarSlots", 10)) end)
if not okHotbar or type(Hotbar) ~= "table" then Hotbar = nil end
local tnt_slot = tonumber(Config.TNT_SLOT_INDEX) or 2
local fork_slot = tonumber(Config.PITCHFORK_SLOT_INDEX) or 3
local vacuum_slot = tonumber(Config.VACUUM_SLOT_INDEX) or 5
local tnt_light_time = (tonumber(Config.TNT_LIGHT_TIME) or 0.48) + 0.07
local vacuum_tick = tonumber(Config.VACUUM_TICK) or 0.1
local lastFork, tntReadyAt, tntLit, lastVacuum, vacuumOn = 0, 0, false, 0, false
if R.TntAction then
	conns[#conns + 1] = R.TntAction.OnClientEvent:Connect(function(state, value)
		if state == "lit" then
			tntLit = true
			tntReadyAt = os.clock() + (tonumber(attr("TntCooldown", nil)) or tonumber(Config.TNT_COOLDOWN) or 20) + 0.1
		elseif state == "denied" then
			tntReadyAt = os.clock() + (tonumber(value) or 1) + 0.1
		end
	end)
end
local function equip(slot)
	if not Hotbar then return false end
	local ok, current = pcall(Hotbar.getEquipped)
	if ok and current == slot then return true end
	pcall(Hotbar.select, slot)
	local ok2, now = pcall(Hotbar.getEquipped)
	return ok2 and now == slot
end
local function stopTools()
	if vacuumOn then
		vacuumOn = false
		pcall(function() R.VacuumAction:FireServer("Stop") end)
	end
end
local function throwTnt(target)
	local r = root()
	if not (r and R.TntAction) then return end
	local stand = target.Position + Vector3.new(0, 3, 6)
	local face = CFrame.lookAt(stand, Vector3.new(target.Position.X, stand.Y, target.Position.Z))
	r.CFrame = face
	pcall(function() r.AssemblyLinearVelocity = Vector3.zero end)
	equip(tnt_slot)
	settle(3)
	tntLit = false
	R.TntAction:FireServer("light")
	local t0 = os.clock()
	while running and not tntLit and os.clock() - t0 < 1 do RunService.Heartbeat:Wait() end
	if not tntLit then
		if tntReadyAt < os.clock() then tntReadyAt = os.clock() + 3 end
		return
	end
	local holdUntil = os.clock() + tnt_light_time
	while os.clock() < holdUntil do
		r.CFrame = face
		pcall(function() r.AssemblyLinearVelocity = Vector3.zero end)
		RunService.Heartbeat:Wait()
	end
	R.TntAction:FireServer("throw", face * CFrame.new(0, 1, -1), face.LookVector * 26 + Vector3.new(0, 6, 0))
end
local function vacuumTick(target)
	local r = root()
	if not (r and R.VacuumAction) or not equip(vacuum_slot) then return end
	if not vacuumOn then
		vacuumOn = true
		pcall(function() R.VacuumAction:FireServer("Start") end)
	end
	if os.clock() - lastVacuum >= vacuum_tick then
		lastVacuum = os.clock()
		local ids = grabCandidates(target)
		local id = target:GetAttribute("HayId")
		if id then table.insert(ids, 1, id) end
		pcall(function() R.VacuumAction:FireServer("Tick", target.Position, r.Position, ids) end)
	end
end
local function useTools(target)
	if not (cfg.useTools and target) then return false end
	if attr("TntOwned", false) and os.clock() >= tntReadyAt then
		stopTools()
		throwTnt(target)
		moveTo(target.Position)
		settle()
	end
	if attr("VacuumOwned", false) and not attr("VacuumOverheated", false) then
		vacuumTick(target)
		return false
	end
	stopTools()
	if attr("PitchforkOwned", false) and equip(fork_slot) then
		local id = target:GetAttribute("HayId")
		local cd = (tonumber(attr("PitchforkCooldown", nil)) or (fork_cd - 0.05)) + 0.05
		if id and os.clock() - lastFork >= cd then
			lastFork = os.clock()
			recentlyPicked[id] = lastFork
			pcall(function() R.PitchforkDig:FireServer(id) end)
			return true
		end
	end
	return false
end
local needleId, needlePos, claiming = nil, nil, false
local function findObjective()
	local hc = hayFolder()
	if hc then
		for _, piece in ipairs(hc:GetChildren()) do
			if piece:GetAttribute("IsNeedleObjective") then return piece end
		end
	end
	return nil
end
local function pieceById(id)
	local hc = hayFolder()
	if not (hc and id) then return nil end
	for _, piece in ipairs(hc:GetChildren()) do
		if piece:GetAttribute("HayId") == id then return piece end
	end
	return nil
end
local function nearestAround(pos, radius)
	local hc = hayFolder()
	if not hc then return nil end
	local best, bestDist
	for _, piece in ipairs(hc:GetChildren()) do
		local d = (piece.Position - pos).Magnitude
		if d <= radius and (not bestDist or d < bestDist) then best, bestDist = piece, d end
	end
	return best
end
local function handIn()
	local npc = Workspace:FindFirstChild("NPC")
	local farmer = npc and npc:FindFirstChild("Farmer_NPC")
	local r = root()
	if not (farmer and r) then return end
	local pivot = farmer:GetPivot()
	for _ = 1, 5 do
		if not attr("NeedleOwned", false) then break end
		r.CFrame = CFrame.lookAt(pivot.Position + pivot.LookVector * 5 + Vector3.new(0, 2, 0), pivot.Position)
		settle(3)
		R.NeedleHandIn:FireServer()
		task.wait(1)
	end
end
local function claimNeedle()
	if claiming then return end
	claiming = true
	stopTools()
	local deadline = os.clock() + 180
	while running and cfg.needle and os.clock() < deadline and not attr("NeedleOwned", false) do
		local objective = findObjective()
		if objective then
			needlePos = objective.Position
			moveTo(objective.Position)
			settle()
			R.PickHay:FireServer("Objective")
		else
			local anchor = pieceById(needleId)
			if anchor then needlePos = anchor.Position end
			if needlePos then
				moveTo(needlePos)
				settle()
				local dig = nearestAround(needlePos, dig_radius)
				if dig then pickPiece(dig) end
			end
		end
		task.wait(pickDelay())
	end
	if attr("NeedleOwned", false) then handIn() end
	claiming = false
end
if R.NeedleTargetChanged then
	conns[#conns + 1] = R.NeedleTargetChanged.OnClientEvent:Connect(function(id)
		if typeof(id) == "number" then
			needleId = id
			local piece = pieceById(id)
			if piece then needlePos = piece.Position end
		end
	end)
end
task.spawn(function()
	while running do
		if cfg.farm and not claiming then
			local held = tonumber(attr("HayHeld", 0)) or 0
			local capacity = tonumber(attr("HayCapacity", 25)) or 25
			local bagFull = held >= capacity or (attr("InfiniteBagOwned", false) and held >= 200)
			if cfg.autoSell and bagFull then
				sellNow()
			else
				if cfg.gems and collectNearestGem() then
					task.wait(0.05)
				end
				local target = chooseTarget()
				if target and moveTo(target.Position) then
					settle()
					if useTools(target) then
						local nextTarget = chooseTarget()
						if nextTarget then pickPiece(nextTarget) end
					else
						pickPiece(target)
					end
				end
				task.wait(pickDelay())
			end
		else
			if not cfg.farm then stopTools() end
			task.wait(0.25)
		end
	end
end)
task.spawn(function()
	while running do
		if cfg.gems and not cfg.farm and not claiming then
			if not collectNearestGem() then task.wait(0.5) end
		else
			task.wait(0.5)
		end
	end
end)
task.spawn(function()
	while running do
		if cfg.needle and not claiming then
			if attr("NeedleOwned", false) then
				handIn()
			elseif needleId or findObjective() then
				task.spawn(claimNeedle)
			end
		end
		task.wait(1)
	end
end)
task.spawn(function()
	while running do
		if cfg.buyDrone then
			if not attr("DroneOwned", false) and (tonumber(attr("Gems", 0)) or 0) >= 40 then
				pcall(function() R.BuyShopItem:FireServer("Drone") end)
			elseif attr("DroneOwned", false) and not attr("DroneDeployed", false) then
				pcall(function() R.DeployDrone:FireServer() end)
			end
		end
		if cfg.buyTools then
			local c = cash()
			if not attr("PitchforkOwned", false) and c >= 8 then
				pcall(function() R.BuyShopItem:FireServer("Pitchfork") end)
			elseif not attr("TntOwned", false) and c >= 25 then
				pcall(function() R.BuyShopItem:FireServer("Tnt") end)
			elseif not attr("VacuumOwned", false) and c >= 69.99 then
				pcall(function() R.BuyShopItem:FireServer("Vacuum") end)
			end
		end
		if cfg.buyUpgrades then
			for _, track in ipairs({ "Grab", "Capacity", "Speed", "Value", "HandHold" }) do
				pcall(function() R.BuyUpgrade:FireServer(track) end)
			end
		end
		if cfg.buyDroneUpgrades and attr("DroneOwned", false) then
			for _, track in ipairs({ "DroneGrab", "DroneCapacity", "DroneSpeed" }) do
				pcall(function() R.BuyUpgrade:FireServer(track) end)
			end
		end
		if cfg.buyToolUpgrades then
			for _, tool in ipairs({
				{ owned = "PitchforkOwned", tracks = { "Pitchfork", "PitchforkCooldown", "PitchforkHold" } },
				{ owned = "TntOwned", tracks = { "TntPower", "TntCooldown", "TntLuck" } },
				{ owned = "VacuumOwned", tracks = { "VacuumPower", "VacuumRuntime", "VacuumCooling" } },
			}) do
				if attr(tool.owned, false) then
					for _, track in ipairs(tool.tracks) do
						pcall(function() R.BuyUpgrade:FireServer(track) end)
					end
				end
			end
		end
		task.wait(3)
	end
end)
local returning = false
local function save_match_settings()
	local map = NH:GetAttribute("Map")
	local difficulty = NH:GetAttribute("Difficulty")
	if map then rejoin.map = map end
	if difficulty then rejoin.difficulty = difficulty end
	persist()
end
local function return_to_lobby()
	if returning then return end
	returning = true
	save_match_settings()
	persist(true)
	queue_self()
	task.wait(2)
	pcall(function() NH.ReturnToLobby:FireServer() end)
end
save_match_settings()
if rejoin.on then queue_self() end
if NH:FindFirstChild("NeedleRoundCompleted") then
	conns[#conns + 1] = NH.NeedleRoundCompleted.OnClientEvent:Connect(function()
		if rejoin.on then task.spawn(return_to_lobby) end
	end)
end
task.spawn(function()
	while running do
		if rejoin.on and NH:GetAttribute("RoundFinishedElapsed") ~= nil then
			return_to_lobby()
		end
		task.wait(1)
	end
end)

-- ── Match UI (CyberUI / Vaxorin) ──────────────────────────────────────────
local Window = Vaxorin:CreateWindow({
	Title = "needle",
	Subtitle = "by fietewoozle",
	ToggleKey = Enum.KeyCode.RightControl,
	ShowSearch = true,
	ShowWindowControls = true,
})

local TFarm = Window:CreateTab("farm")
local statusS = TFarm:CreateSection({ Name = "status" })
local statusPara = statusS:CreateParagraph({
	Title = "live",
	Content = "loading...",
})
task.spawn(function()
	while running do
		pcall(function()
			statusPara:Set(("cash: $%.2f\nbag: %s / %s\ngems: %s\nneedle: %s"):format(
				cash(), tostring(attr("HayHeld", 0)), tostring(attr("HayCapacity", "?")), tostring(attr("Gems", 0)),
				attr("NeedleOwned", false) and "in hand" or (claiming and "claiming now" or (needleId and ("revealed, hay id " .. needleId) or "not revealed yet"))))
		end)
		task.wait(0.5)
	end
end)
local farmS = TFarm:CreateSection({ Name = "hay" })
farmS:CreateToggle({
	Name = "auto farm hay",
	Flag = "farm",
	Default = cfg.farm,
	Callback = function(v) cfg.farm = v persist() end,
})
farmS:CreateToggle({
	Name = "auto pickup gems",
	Flag = "gems",
	Default = cfg.gems,
	Callback = function(v) cfg.gems = v persist() end,
})
farmS:CreateToggle({
	Name = "rare hay first",
	Flag = "rareFirst",
	Default = cfg.rareFirst,
	Callback = function(v) cfg.rareFirst = v persist() end,
})
farmS:CreateToggle({
	Name = "auto sell when bag is full",
	Flag = "autoSell",
	Default = cfg.autoSell,
	Callback = function(v) cfg.autoSell = v persist() end,
})
farmS:CreateToggle({
	Name = "use owned tools",
	Flag = "useTools",
	Default = cfg.useTools,
	Callback = function(v) cfg.useTools = v persist() end,
})
farmS:CreateButton({
	Name = "sell now",
	Callback = function() task.spawn(sellNow) end,
})

local TNeedle = Window:CreateTab("needle")
local needleS = TNeedle:CreateSection({ Name = "needle" })
needleS:CreateToggle({
	Name = "auto claim + hand in the needle",
	Flag = "needle",
	Default = cfg.needle,
	Callback = function(v) cfg.needle = v persist() end,
})
needleS:CreateButton({
	Name = "hand in now",
	Callback = function() task.spawn(handIn) end,
})

local TShop = Window:CreateTab("shop")
local shopS = TShop:CreateSection({ Name = "auto buy" })
shopS:CreateToggle({
	Name = "buy + deploy drone",
	Flag = "buyDrone",
	Default = cfg.buyDrone,
	Callback = function(v) cfg.buyDrone = v persist() end,
})
shopS:CreateToggle({
	Name = "buy tools with cash",
	Flag = "buyTools",
	Default = cfg.buyTools,
	Callback = function(v) cfg.buyTools = v persist() end,
})
shopS:CreateToggle({
	Name = "buy cash upgrades",
	Flag = "buyUpgrades",
	Default = cfg.buyUpgrades,
	Callback = function(v) cfg.buyUpgrades = v persist() end,
})
shopS:CreateToggle({
	Name = "buy drone upgrades",
	Flag = "buyDroneUpgrades",
	Default = cfg.buyDroneUpgrades,
	Callback = function(v) cfg.buyDroneUpgrades = v persist() end,
})
shopS:CreateToggle({
	Name = "buy tool upgrades",
	Flag = "buyToolUpgrades",
	Default = cfg.buyToolUpgrades,
	Callback = function(v) cfg.buyToolUpgrades = v persist() end,
})

local TRejoin = Window:CreateTab("rejoin")
local rejoinS = TRejoin:CreateSection({ Name = "after the match" })
local rejoinPara = rejoinS:CreateParagraph({
	Title = "next match",
	Content = "loading...",
})
local function refreshRejoin()
	pcall(function()
		rejoinPara:Set(("map: %s\ndifficulty: %s\nparty size: %s"):format(rejoin.map, rejoin.difficulty, tostring(rejoin.size)))
	end)
end
refreshRejoin()
rejoinS:CreateToggle({
	Name = "auto rejoin when the match ends",
	Flag = "rejoin",
	Default = rejoin.on,
	Callback = function(v)
		rejoin.on = v
		if v then queue_self() else unqueue_self() end
		persist()
	end,
})
rejoinS:CreateButton({
	Name = "return to lobby now",
	Callback = function() task.spawn(return_to_lobby) end,
})
rejoinS:CreateButton({
	Name = "next map",
	Callback = function()
		rejoin.map = rejoin.map == "FARMHOUSE" and "BASEMENT" or "FARMHOUSE"
		persist()
		refreshRejoin()
	end,
})
rejoinS:CreateButton({
	Name = "next difficulty",
	Callback = function()
		rejoin.difficulty = rejoin.difficulty == "NORMAL" and "HARD" or "NORMAL"
		persist()
		refreshRejoin()
	end,
})
rejoinS:CreateButton({
	Name = "party size 1-4",
	Callback = function()
		rejoin.size = (rejoin.size % 4) + 1
		persist()
		refreshRejoin()
	end,
})

pcall(function()
	Vaxorin:Notify({
		Title = "needle loaded",
		Content = "RightControl to toggle the menu",
		Type = "Success",
		Duration = 4,
	})
end)

env.needle_farm = {
	cfg = cfg,
	rejoin = rejoin,
	stop = function()
		running = false
		pcall(persist, true)
		watch_alive = false
		stopTools()
		for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
		pcall(function() Window:Destroy() end)
	end,
}
]===]
loadstring(SELF, "=needle")(SELF)
