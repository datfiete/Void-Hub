--!strict
-- Point-only WorldRadar UI element for developer-owned experiences.
-- Targets may be a Folder/Instance, a list of Instances, or a function returning either.
-- Optional AutoFly: flies the local character to targets with selectable modes.
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local WorldRadar = {}
WorldRadar.__index = WorldRadar

-- AutoFly modes:
--   "Nearest"      = always fly to the closest target (re-evaluates every frame)
--   "SkipVisited"  = on arrival mark target as visited; never go there again while it still exists
--   "WaitUntilGone"= lock onto a target and stay until it is destroyed/removed, then pick next
local VALID_MODES = {
	Nearest = true,
	SkipVisited = true,
	WaitUntilGone = true,
}

local MODE_LABELS = {
	Nearest = "Nearest",
	SkipVisited = "Skip done",
	WaitUntilGone = "Wait gone",
}

local MODE_ORDER = { "Nearest", "SkipVisited", "WaitUntilGone" }

local function make(className: string, props: {[string]: any}, parent: Instance): Instance
	local obj = Instance.new(className)
	for k, v in pairs(props) do
		(obj :: any)[k] = v
	end
	obj.Parent = parent
	return obj
end

local function normalizeMode(mode: any): string
	if type(mode) == "string" and VALID_MODES[mode] then
		return mode
	end
	return "Nearest"
end

function WorldRadar.new(section: any, data: any)
	local self = setmetatable({
		_Connections = {},
		_Dots = {},
		_Zoom = 1,
		_Enabled = data.DefaultActive ~= false,
		_AutoFly = data.AutoFly == true,
		_FlySpeed = typeof(data.FlySpeed) == "number" and data.FlySpeed or 80,
		_ArriveDistance = typeof(data.ArriveDistance) == "number" and data.ArriveDistance or 8,
		_PreserveHeight = data.PreserveHeight == true,
		_AutoFlyMode = normalizeMode(data.AutoFlyMode),
	}, WorldRadar)

	local theme = section.Tab.Window.Library.Theme
	local root = make("Frame", {
		Name = "WorldRadar",
		Size = UDim2.new(1, 0, 0, 340), -- slightly taller for mode row
		BackgroundTransparency = 1,
		LayoutOrder = 999,
	}, section.Inner)
	self.Instance = root

	local header = make("Frame", {
		Name = "ObjectHeader",
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundTransparency = 1,
	}, root)
	make("TextLabel", {
		Name = "ObjectTitle",
		Size = UDim2.new(1, -100, 1, 0),
		BackgroundTransparency = 1,
		Text = data.ObjectLabel or "OBJECTS",
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = theme.Text,
	}, header)

	local active = make("TextButton", {
		Name = "Activate",
		Size = UDim2.fromOffset(92, 26),
		Position = UDim2.new(1, -92, 0, 2),
		BackgroundColor3 = theme.SurfaceHover,
		Text = self._Enabled and "ACTIVE: ON" or "ACTIVE: OFF",
		TextColor3 = theme.Text,
		Font = Enum.Font.GothamSemibold,
		TextSize = 10,
		AutoButtonColor = true,
	}, header)
	make("UICorner", { CornerRadius = UDim.new(0, 6) }, active)

	local categories = make("Frame", {
		Name = "ObjectList",
		Size = UDim2.new(1, 0, 0, 28),
		Position = UDim2.fromOffset(0, 32),
		BackgroundTransparency = 1,
	}, root)
	make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 7),
	}, categories)

	local chestButton = make("TextButton", {
		Name = "ChestsFilter",
		Size = UDim2.fromOffset(90, 26),
		BackgroundColor3 = theme.Accent,
		Text = "✓  Chests",
		TextColor3 = theme.Text,
		Font = Enum.Font.GothamMedium,
		TextSize = 11,
		AutoButtonColor = true,
	}, categories)
	make("UICorner", { CornerRadius = UDim.new(0, 6) }, chestButton)

	local autoFlyButton = nil
	if data.ShowAutoFlyToggle ~= false then
		autoFlyButton = make("TextButton", {
			Name = "AutoFlyFilter",
			Size = UDim2.fromOffset(90, 26),
			BackgroundColor3 = self._AutoFly and theme.Accent or theme.SurfaceHover,
			Text = self._AutoFly and "✓  AutoFly" or "AutoFly",
			TextColor3 = theme.Text,
			Font = Enum.Font.GothamMedium,
			TextSize = 11,
			AutoButtonColor = true,
		}, categories)
		make("UICorner", { CornerRadius = UDim.new(0, 6) }, autoFlyButton)
	end

	-- Mode cycle button
	local modeButton = nil
	if data.ShowAutoFlyModeToggle ~= false then
		modeButton = make("TextButton", {
			Name = "AutoFlyMode",
			Size = UDim2.fromOffset(100, 26),
			BackgroundColor3 = theme.SurfaceHover,
			Text = MODE_LABELS[self._AutoFlyMode] or "Nearest",
			TextColor3 = theme.Text,
			Font = Enum.Font.GothamMedium,
			TextSize = 10,
			AutoButtonColor = true,
		}, categories)
		make("UICorner", { CornerRadius = UDim.new(0, 6) }, modeButton)
	end

	local radar = make("Frame", {
		Name = "PointField",
		Size = UDim2.new(1, 0, 0, 240),
		Position = UDim2.fromOffset(0, 64),
		BackgroundColor3 = theme.Background or theme.Surface,
		BackgroundTransparency = 0.05,
		BorderSizePixel = 0,
		ClipsDescendants = true,
	}, root)
	make("UICorner", { CornerRadius = UDim.new(0, 10) }, radar)
	make("UIStroke", { Color = theme.Border, Transparency = 0.2, Thickness = 1 }, radar)

	for _, scale in { 0.35, 0.68, 1 } do
		local ring = make("Frame", {
			Name = "RangeRing",
			Size = UDim2.fromScale(scale, scale),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
		}, radar)
		make("UICorner", { CornerRadius = UDim.new(1, 0) }, ring)
		make("UIStroke", { Color = theme.Border, Transparency = 0.45, Thickness = 1 }, ring)
	end
	make("Frame", {
		Name = "CrossX",
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.fromScale(0, 0.5),
		BackgroundColor3 = theme.Border,
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
	}, radar)
	make("Frame", {
		Name = "CrossY",
		Size = UDim2.new(0, 1, 1, 0),
		Position = UDim2.fromScale(0.5, 0),
		BackgroundColor3 = theme.Border,
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
	}, radar)

	local playerDot = make("Frame", {
		Name = "You",
		Size = UDim2.fromOffset(10, 10),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = theme.Accent,
		BorderSizePixel = 0,
		ZIndex = 5,
	}, radar)
	make("UICorner", { CornerRadius = UDim.new(1, 0) }, playerDot)

	local zoomOut = make("TextButton", {
		Name = "ZoomOut",
		Size = UDim2.fromOffset(28, 28),
		Position = UDim2.new(1, -64, 0, 8),
		BackgroundColor3 = theme.Surface,
		Text = "−",
		TextColor3 = theme.Text,
		Font = Enum.Font.GothamBold,
		TextSize = 18,
		ZIndex = 8,
	}, radar)
	local zoomIn = make("TextButton", {
		Name = "ZoomIn",
		Size = UDim2.fromOffset(28, 28),
		Position = UDim2.new(1, -32, 0, 8),
		BackgroundColor3 = theme.Surface,
		Text = "+",
		TextColor3 = theme.Text,
		Font = Enum.Font.GothamBold,
		TextSize = 18,
		ZIndex = 8,
	}, radar)
	for _, b in { zoomIn, zoomOut } do
		make("UICorner", { CornerRadius = UDim.new(0, 6) }, b)
	end

	local status = make("TextLabel", {
		Name = "Status",
		Size = UDim2.new(1, -16, 0, 16),
		Position = UDim2.new(0, 8, 1, -20),
		BackgroundTransparency = 1,
		Text = "0 targets · range 250",
		TextColor3 = theme.TextMuted,
		Font = Enum.Font.Gotham,
		TextSize = 10,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 7,
	}, radar)

	--------------------------------------------------------------------
	-- Flight / Noclip
	--------------------------------------------------------------------
	local noclipConnection = nil
	local flyTarget = nil :: Vector3?
	local flyConnection = nil
	local flying = false
	local hoverY = nil :: number?
	local currentTargetInstance = nil :: Instance?
	local lockedTargetInstance = nil :: Instance? -- used by WaitUntilGone
	local visitedTargets = {} :: { [Instance]: boolean } -- used by SkipVisited

	local config = {
		flySpeed = self._FlySpeed,
	}

	local function enableNoclip()
		if noclipConnection then
			return
		end
		noclipConnection = RunService.Heartbeat:Connect(function()
			local character = LocalPlayer.Character
			if not character then
				return
			end
			for _, part in ipairs(character:GetDescendants()) do
				if part:IsA("BasePart") then
					part.CanCollide = false
				end
			end
		end)
	end

	local function disableNoclip()
		if noclipConnection then
			noclipConnection:Disconnect()
			noclipConnection = nil
		end
		local character = LocalPlayer.Character
		if character then
			for _, part in ipairs(character:GetDescendants()) do
				if part:IsA("BasePart") then
					part.CanCollide = true
				end
			end
		end
	end

	local function enableFly()
		if flying then
			return
		end
		local character = LocalPlayer.Character
		if not character then
			return
		end
		local humanoid = character:FindFirstChild("Humanoid")
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if not humanoid or not hrp then
			return
		end

		flying = true
		hoverY = hrp.Position.Y
		humanoid.PlatformStand = true
		enableNoclip()

		flyConnection = RunService.Heartbeat:Connect(function()
			if not flying then
				return
			end

			local currentCharacter = LocalPlayer.Character
			local currentHrp = currentCharacter and currentCharacter:FindFirstChild("HumanoidRootPart")
			local currentHumanoid = currentCharacter and currentCharacter:FindFirstChild("Humanoid")
			if not currentHrp or not currentHumanoid or currentHumanoid.Health <= 0 then
				return
			end

			if not hoverY then
				hoverY = currentHrp.Position.Y
			end

			local target = flyTarget
			if target then
				local delta = target - currentHrp.Position
				local horizontal = Vector3.new(delta.X, 0, delta.Z)
				local horizontalDistance = horizontal.Magnitude
				local verticalError = delta.Y

				local horizontalVelocity = Vector3.zero
				if horizontalDistance > 0.5 then
					local horizontalSpeed = math.min(config.flySpeed, math.max(20, horizontalDistance * 5))
					horizontalVelocity = horizontal.Unit * horizontalSpeed
				end

				local verticalVelocity = math.clamp(verticalError * 5, -config.flySpeed, config.flySpeed)
				if math.abs(verticalError) < 0.75 then
					verticalVelocity = 0
				end

				currentHrp.AssemblyLinearVelocity = Vector3.new(
					horizontalVelocity.X,
					verticalVelocity,
					horizontalVelocity.Z
				)
				currentHrp.AssemblyAngularVelocity = Vector3.zero
			else
				hoverY = hoverY or currentHrp.Position.Y
				local verticalError = hoverY - currentHrp.Position.Y
				currentHrp.AssemblyLinearVelocity = Vector3.new(0, math.clamp(verticalError * 6, -20, 20), 0)
				currentHrp.AssemblyAngularVelocity = Vector3.zero
			end
		end)
	end

	local function disableFly()
		if not flying then
			return
		end
		flying = false
		if flyConnection then
			flyConnection:Disconnect()
			flyConnection = nil
		end
		flyTarget = nil
		hoverY = nil
		currentTargetInstance = nil
		-- keep locked/visited state so mode logic can continue cleanly after re-enable

		local character = LocalPlayer.Character
		if character then
			local hrp = character:FindFirstChild("HumanoidRootPart")
			if hrp then
				hrp.AssemblyLinearVelocity = Vector3.zero
				hrp.AssemblyAngularVelocity = Vector3.zero
			end
			local humanoid = character:FindFirstChild("Humanoid")
			if humanoid then
				humanoid.PlatformStand = false
			end
		end
		disableNoclip()
	end

	local function setFlyTarget(position: Vector3?, preserveHeight: boolean?)
		if not flying then
			enableFly()
		end
		if not position then
			flyTarget = nil
			return
		end

		-- preserveHeight == true  -> keep current flight height
		-- preserveHeight == false -> use exact target Y
		if preserveHeight and hoverY then
			position = Vector3.new(position.X, hoverY, position.Z)
		else
			hoverY = position.Y
		end
		flyTarget = position
	end

	local function setHoverHeight(y: number)
		hoverY = y
		if flyTarget then
			flyTarget = Vector3.new(flyTarget.X, y, flyTarget.Z)
		end
	end

	self.EnableFly = enableFly
	self.DisableFly = disableFly
	self.SetFlyTarget = setFlyTarget
	self.SetHoverHeight = setHoverHeight
	self.IsFlying = function()
		return flying
	end

	--------------------------------------------------------------------
	-- Target helpers
	--------------------------------------------------------------------
	local chestEnabled = true

	local function getTargets()
		local source = data.Targets
		if type(source) == "function" then
			local ok, v = pcall(source)
			if ok then
				source = v
			else
				return {}
			end
		end
		if typeof(source) == "Instance" then
			return source:GetChildren()
		end
		if type(source) == "table" then
			return source
		end
		local folder = workspace:FindFirstChild(data.FolderName or "Chests")
		return folder and folder:GetChildren() or {}
	end

	local function getPart(target: Instance): BasePart?
		if target:IsA("BasePart") then
			return target
		end
		return target:FindFirstChildWhichIsA("BasePart", true)
	end

	local function isValidTarget(target: Instance, char: Model?): boolean
		if typeof(target) ~= "Instance" then
			return false
		end
		if target == char then
			return false
		end
		if not target:IsDescendantOf(workspace) then
			return false
		end
		return getPart(target) ~= nil
	end

	-- Returns nearest target that is allowed by the current mode
	local function getBestTarget(hrp: BasePart, char: Model?): (Instance?, BasePart?, number)
		local bestInst, bestPart, bestDist = nil, nil, math.huge
		local range = (data.Range or 250) / self._Zoom
		local mode = self._AutoFlyMode

		for _, target in ipairs(getTargets()) do
			if isValidTarget(target, char) then
				-- SkipVisited: ignore already visited
				local skip = (mode == "SkipVisited" and visitedTargets[target])
				if not skip then
					local part = getPart(target)
					if part then
						local dist = (part.Position - hrp.Position).Magnitude
						if dist < bestDist and dist <= range * 1.5 then
							bestInst, bestPart, bestDist = target, part, dist
						end
					end
				end
			end
		end
		return bestInst, bestPart, bestDist
	end

	local function clearDots()
		for inst, dot in pairs(self._Dots) do
			if dot and dot.Parent then
				dot:Destroy()
			end
			self._Dots[inst] = nil
		end
	end

	local function markVisited(target: Instance?)
		if target then
			visitedTargets[target] = true
		end
	end

	local function clearVisited()
		table.clear(visitedTargets)
	end

	local function isTargetStillAlive(target: Instance?): boolean
		if not target then
			return false
		end
		if not target.Parent then
			return false
		end
		if not target:IsDescendantOf(workspace) then
			return false
		end
		return getPart(target) ~= nil
	end

	--------------------------------------------------------------------
	-- Main update (radar + AutoFly modes)
	--------------------------------------------------------------------
	local function update()
		local lp = LocalPlayer
		local char = lp and lp.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")

		if not self._Enabled or not chestEnabled or not hrp then
			clearDots()
			status.Text = "Radar paused"
			if not self._Enabled or not chestEnabled then
				if flying and self._AutoFly then
					disableFly()
				end
			end
			return
		end

		local targets = getTargets()
		local alive = {}
		local count = 0
		local range = (data.Range or 250) / self._Zoom
		local field = radar.AbsoluteSize
		local radius = math.max(1, math.min(field.X, field.Y) * 0.46)

		-- prune visited that no longer exist
		for inst in pairs(visitedTargets) do
			if not isTargetStillAlive(inst) then
				visitedTargets[inst] = nil
			end
		end

		for _, target in ipairs(targets) do
			if isValidTarget(target, char) then
				local part = getPart(target)
				if part then
					alive[target] = true
					count += 1
					local delta = part.Position - hrp.Position
					local dx, dz = delta.X, delta.Z
					local dist = math.sqrt(dx * dx + dz * dz)
					local scale = math.min(dist / range, 1)
					local px = dx / math.max(dist, 0.001) * scale * radius
					local py = dz / math.max(dist, 0.001) * scale * radius
					local dot = self._Dots[target]
					if not dot or not dot.Parent then
						dot = make("Frame", {
							Name = "TargetDot",
							Size = UDim2.fromOffset(7, 7),
							AnchorPoint = Vector2.new(0.5, 0.5),
							BackgroundColor3 = data.DotColor or Color3.fromRGB(255, 95, 110),
							BorderSizePixel = 0,
							ZIndex = 6,
						}, radar)
						make("UICorner", { CornerRadius = UDim.new(1, 0) }, dot)
						self._Dots[target] = dot
					end

					-- Colors: current = green, visited = gray, normal = red
					if target == currentTargetInstance or target == lockedTargetInstance then
						dot.BackgroundColor3 = Color3.fromRGB(80, 255, 140)
						dot.Size = UDim2.fromOffset(9, 9)
					elseif visitedTargets[target] then
						dot.BackgroundColor3 = Color3.fromRGB(140, 140, 150)
						dot.Size = UDim2.fromOffset(6, 6)
					else
						dot.BackgroundColor3 = data.DotColor or Color3.fromRGB(255, 95, 110)
						dot.Size = UDim2.fromOffset(7, 7)
					end
					dot.Position = UDim2.new(0.5, px, 0.5, py)
					dot.Visible = dist <= range
				end
			end
		end

		for inst, dot in pairs(self._Dots) do
			if not alive[inst] then
				if dot then
					dot:Destroy()
				end
				self._Dots[inst] = nil
			end
		end

		--------------------------------------------------------------------
		-- AutoFly mode logic
		--------------------------------------------------------------------
		if self._AutoFly then
			local mode = self._AutoFlyMode
			local modeTag = MODE_LABELS[mode] or mode

			if mode == "WaitUntilGone" then
				-- Stay locked on current target until it is gone
				if lockedTargetInstance and isTargetStillAlive(lockedTargetInstance) then
					local part = getPart(lockedTargetInstance)
					if part then
						currentTargetInstance = lockedTargetInstance
						local dist = (part.Position - hrp.Position).Magnitude
						if dist <= 2.5 then
							setFlyTarget(nil) -- hover on top
						else
							setFlyTarget(part.Position, self._PreserveHeight)
						end
						status.Text = string.format("%d targets · %s · locked %.0fm", count, modeTag, dist)
					else
						lockedTargetInstance = nil
					end
				else
					-- Target gone (or none locked) → pick next nearest
					lockedTargetInstance = nil
					local nearestInst, nearestPart, nearestDist = getBestTarget(hrp, char)
					if nearestPart and nearestInst then
						lockedTargetInstance = nearestInst
						currentTargetInstance = nearestInst
						setFlyTarget(nearestPart.Position, self._PreserveHeight)
						status.Text = string.format("%d targets · %s · new → %.0fm", count, modeTag, nearestDist)
					else
						currentTargetInstance = nil
						if flying then
							setFlyTarget(nil)
						end
						status.Text = string.format("%d targets · %s · idle", count, modeTag)
					end
				end
			elseif mode == "SkipVisited" then
				local nearestInst, nearestPart, nearestDist = getBestTarget(hrp, char)
				if nearestPart and nearestInst then
					currentTargetInstance = nearestInst
					if nearestDist <= self._ArriveDistance then
						-- Arrived → mark visited and immediately look for next
						markVisited(nearestInst)
						local nextInst, nextPart, nextDist = getBestTarget(hrp, char)
						if nextPart and nextInst then
							currentTargetInstance = nextInst
							setFlyTarget(nextPart.Position, self._PreserveHeight)
							status.Text = string.format("%d targets · %s · next → %.0fm", count, modeTag, nextDist)
						else
							setFlyTarget(nil)
							status.Text = string.format("%d targets · %s · all done", count, modeTag)
						end
					else
						setFlyTarget(nearestPart.Position, self._PreserveHeight)
						status.Text = string.format("%d targets · %s · → %.0fm", count, modeTag, nearestDist)
					end
				else
					currentTargetInstance = nil
					if flying then
						setFlyTarget(nil)
					end
					status.Text = string.format("%d targets · %s · idle", count, modeTag)
				end
			else
				-- Nearest (default): always re-target closest
				local nearestInst, nearestPart, nearestDist = getBestTarget(hrp, char)
				if nearestPart then
					currentTargetInstance = nearestInst
					if nearestDist <= 2.5 then
						setFlyTarget(nil)
					else
						setFlyTarget(nearestPart.Position, self._PreserveHeight)
					end
					status.Text = string.format("%d targets · %s · → %.0fm", count, modeTag, nearestDist)
				else
					currentTargetInstance = nil
					if flying then
						setFlyTarget(nil)
					end
					status.Text = string.format("%d targets · %s · idle", count, modeTag)
				end
			end
		else
			currentTargetInstance = nil
			if flying then
				disableFly()
			end
			status.Text = string.format("%d targets · range %d", count, math.floor(range))
		end
	end

	--------------------------------------------------------------------
	-- Connections
	--------------------------------------------------------------------
	table.insert(self._Connections, active.Activated:Connect(function()
		self._Enabled = not self._Enabled
		active.Text = self._Enabled and "ACTIVE: ON" or "ACTIVE: OFF"
		active.BackgroundColor3 = self._Enabled and theme.Accent or theme.SurfaceHover
		if not self._Enabled and self._AutoFly then
			disableFly()
		end
		update()
	end))

	table.insert(self._Connections, chestButton.Activated:Connect(function()
		chestEnabled = not chestEnabled
		chestButton.Text = (chestEnabled and "✓  " or "□  ") .. "Chests"
		chestButton.BackgroundColor3 = chestEnabled and theme.Accent or theme.SurfaceHover
		if not chestEnabled and self._AutoFly then
			disableFly()
		end
		update()
	end))

	if autoFlyButton then
		table.insert(self._Connections, autoFlyButton.Activated:Connect(function()
			self._AutoFly = not self._AutoFly
			autoFlyButton.Text = self._AutoFly and "✓  AutoFly" or "□  AutoFly"
			autoFlyButton.BackgroundColor3 = self._AutoFly and theme.Accent or theme.SurfaceHover
			if not self._AutoFly then
				disableFly()
			end
			update()
		end))
	end

	if modeButton then
		table.insert(self._Connections, modeButton.Activated:Connect(function()
			-- cycle modes
			local idx = 1
			for i, m in ipairs(MODE_ORDER) do
				if m == self._AutoFlyMode then
					idx = i
					break
				end
			end
			idx = idx % #MODE_ORDER + 1
			self._AutoFlyMode = MODE_ORDER[idx]
			modeButton.Text = MODE_LABELS[self._AutoFlyMode] or self._AutoFlyMode
			-- reset mode-specific state when switching
			lockedTargetInstance = nil
			if self._AutoFlyMode ~= "SkipVisited" then
				-- optional: keep visited list so user doesn't re-fly old ones if they switch back
			end
			update()
		end))
	end

	table.insert(self._Connections, zoomIn.Activated:Connect(function()
		self._Zoom = math.max(0.5, self._Zoom / 1.25)
		update()
	end))
	table.insert(self._Connections, zoomOut.Activated:Connect(function()
		self._Zoom = math.min(8, self._Zoom * 1.25)
		update()
	end))

	table.insert(self._Connections, RunService.Heartbeat:Connect(update))

	table.insert(self._Connections, LocalPlayer.CharacterAdded:Connect(function()
		if flying then
			disableFly()
		end
	end))

	self._Maid = nil
	function self:Destroy()
		disableFly()
		for _, c in ipairs(self._Connections) do
			pcall(function()
				c:Disconnect()
			end)
		end
		clearDots()
		if root and root.Parent then
			root:Destroy()
		end
	end

	function self:RefreshTheme() end

	function self:SetAutoFly(enabled: boolean)
		self._AutoFly = enabled == true
		if autoFlyButton then
			autoFlyButton.Text = self._AutoFly and "✓  AutoFly" or "□  AutoFly"
			autoFlyButton.BackgroundColor3 = self._AutoFly and theme.Accent or theme.SurfaceHover
		end
		if not self._AutoFly then
			disableFly()
		end
		update()
	end

	function self:SetFlySpeed(speed: number)
		if typeof(speed) == "number" and speed > 0 then
			self._FlySpeed = speed
			config.flySpeed = speed
		end
	end

	function self:SetAutoFlyMode(mode: string)
		self._AutoFlyMode = normalizeMode(mode)
		if modeButton then
			modeButton.Text = MODE_LABELS[self._AutoFlyMode] or self._AutoFlyMode
		end
		lockedTargetInstance = nil
		update()
	end

	function self:ClearVisited()
		clearVisited()
		update()
	end

	function self:GetAutoFlyMode(): string
		return self._AutoFlyMode
	end

	return self
end

return WorldRadar
