-- Blox Fruits: dump EnemySpawns + live Enemies + Locations
-- Execute in-game, then paste from clipboard into chat.
-- Output is ready to send for island/level/pos updates.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local LP = Players.LocalPlayer

local function avg(list)
	if #list == 0 then return nil end
	local x, y, z = 0, 0, 0
	for _, p in ipairs(list) do
		x += p.X
		y += p.Y
		z += p.Z
	end
	local n = #list
	return Vector3.new(x / n, y / n, z / n)
end

local lines = {}
local function add(s)
	table.insert(lines, s)
end

local map = Workspace:GetAttribute("MAP") or "?"
local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
local playerPos = hrp and string.format("%.1f, %.1f, %.1f", hrp.Position.X, hrp.Position.Y, hrp.Position.Z) or "?"

add("=== EnemySpawns DUMP ===")
add("MAP=" .. tostring(map))
add("PlaceId=" .. tostring(game.PlaceId))
add("PlayerPos=" .. playerPos)

local wo = Workspace:FindFirstChild("_WorldOrigin")
local spawns = wo and wo:FindFirstChild("EnemySpawns")
if not spawns then
	add("ERROR: Workspace._WorldOrigin.EnemySpawns not found")
else
	add("Path=Workspace._WorldOrigin.EnemySpawns")
	add("Class=" .. spawns.ClassName)
	add("ChildCount=" .. #spawns:GetChildren())
	add("--- UNIQUE NAMES + AVG POSITION ---")

	local groups = {}
	for _, child in ipairs(spawns:GetChildren()) do
		local name = child.Name
		local pos = nil
		if child:IsA("BasePart") then
			pos = child.Position
		elseif child:IsA("Model") then
			local p = child.PrimaryPart or child:FindFirstChildWhichIsA("BasePart")
			if p then pos = p.Position end
		end
		if not groups[name] then
			groups[name] = { count = 0, positions = {}, attrs = {} }
		end
		groups[name].count += 1
		if pos then table.insert(groups[name].positions, pos) end
		pcall(function()
			for k, v in pairs(child:GetAttributes()) do
				groups[name].attrs[k] = v
			end
		end)
	end

	local names = {}
	for n in pairs(groups) do table.insert(names, n) end
	table.sort(names)

	for _, name in ipairs(names) do
		local g = groups[name]
		local a = avg(g.positions)
		local posStr = a and string.format("(%.1f, %.1f, %.1f)", a.X, a.Y, a.Z) or "nil"
		local attrParts = {}
		for k, v in pairs(g.attrs) do
			table.insert(attrParts, tostring(k) .. "=" .. tostring(v))
		end
		table.sort(attrParts)
		local attrStr = #attrParts > 0 and table.concat(attrParts, ";") or ""
		add(string.format("%s | count=%d | avgPos=%s | attrs={%s}", name, g.count, posStr, attrStr))
	end
end

add("--- LIVE workspace.Enemies ---")
local enemies = Workspace:FindFirstChild("Enemies")
if enemies then
	for _, m in ipairs(enemies:GetChildren()) do
		if m:IsA("Model") then
			local hum = m:FindFirstChildOfClass("Humanoid")
			local root = m:FindFirstChild("HumanoidRootPart")
			local hp = hum and math.floor(hum.Health) or -1
			local pos = root and string.format("(%.1f, %.1f, %.1f)", root.Position.X, root.Position.Y, root.Position.Z) or "?"
			local boss = m:GetAttribute("isBoss")
			add(string.format("%s | hp=%s | pos=%s | isBossAttr=%s", m.Name, tostring(hp), pos, tostring(boss)))
		end
	end
else
	add("(no Enemies folder)")
end

add("--- Locations (sample) ---")
local locs = wo and wo:FindFirstChild("Locations")
if locs then
	for _, loc in ipairs(locs:GetChildren()) do
		local pos = nil
		if loc:IsA("BasePart") then
			pos = loc.Position
		elseif loc:IsA("Model") then
			local p = loc.PrimaryPart or loc:FindFirstChildWhichIsA("BasePart")
			if p then pos = p.Position end
		end
		if pos then
			add(string.format("%s | (%.1f, %.1f, %.1f)", loc.Name, pos.X, pos.Y, pos.Z))
		else
			add(loc.Name .. " | (no part)")
		end
	end
end

add("--- END DUMP ---")

local text = table.concat(lines, "\n")
print(text)

local ok = pcall(function()
	if setclipboard then
		setclipboard(text)
	elseif toclipboard then
		toclipboard(text)
	end
end)

if ok then
	print("[BF Dump] Copied to clipboard (" .. #lines .. " lines)")
else
	print("[BF Dump] Clipboard failed — copy from F9 output")
end
