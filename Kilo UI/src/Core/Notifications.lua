--!strict

local Theme = require(script.Parent.Theme)
local Maid = require(script.Parent.Parent.Utils.Maid)
local Helpers = require(script.Parent.Parent.Utils.Helpers)
local Tween = require(script.Parent.Parent.Utils.Tween)

local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local CLICK_SOUND_ID = "rbxassetid://876939830"
local NOTIFY_SOUND_IDS = {
	Info = "rbxassetid://9113486434",
	Success = "rbxassetid://9113486434",
	Warning = "rbxassetid://9113486434",
	Error = "rbxassetid://9113486434",
}

local Notifications = {}
Notifications.__index = Notifications

export type NotificationOptions = {
	Title: string?,
	Content: string?,
	Duration: number?,
	Type: ("Info" | "Success" | "Warning" | "Error")?,
	Persistent: boolean?,
	Sound: boolean?,
	Actions: { { Text: string, Callback: (() -> ())? } }?,
}

export type NotificationHandle = {
	Destroy: (self: NotificationHandle) -> (),
}

function Notifications.new(library: { Theme: typeof(Theme) })
	local self = setmetatable({
		Library = library,
		_Maid = Maid.new(),
		_Container = nil :: Frame?,
		_SoundEnabled = true,
	}, Notifications)

	local clickSound = Instance.new("Sound")
	clickSound.Name = "KiloUINotifyClick"
	clickSound.SoundId = CLICK_SOUND_ID
	clickSound.Volume = 0.3
	clickSound.Parent = SoundService
	self._Maid:Give(clickSound)

	return self
end

function Notifications:_getContainer(): Frame
	if self._Container then
		return self._Container
	end

	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local parent = playerGui
	pcall(function()
		if type(gethui) == "function" then
			local hidden = gethui()
			if typeof(hidden) == "Instance" then parent = hidden end
		elseif type(get_hidden_gui) == "function" then
			local hidden = get_hidden_gui()
			if typeof(hidden) == "Instance" then parent = hidden end
		end
	end)

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "KiloUI_Notifications"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.DisplayOrder = 2147483647
	pcall(function()
		screenGui.ScreenInsets = Enum.ScreenInsets.None
	end)
	screenGui.Parent = parent
	self._Maid:Give(screenGui)

	local container = Helpers.CreateFrame({
		Name = "Container",
		Size = UDim2.new(0, 340, 1, -40),
		Position = UDim2.new(1, -20, 0, 20),
		AnchorPoint = Vector2.new(1, 0),
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = screenGui,
	})

	Helpers.ListLayout(container, 10)
	self._Container = container
	return container
end

function Notifications:_resolveAccent(typeName: string?): Color3
	if typeName == "Success" then
		return self.Library.Theme.Success or Color3.fromRGB(76, 220, 137)
	elseif typeName == "Warning" then
		return self.Library.Theme.Warning or Color3.fromRGB(247, 185, 78)
	elseif typeName == "Error" then
		return self.Library.Theme.Error or Color3.fromRGB(255, 80, 95)
	end
	return self.Library.Theme.Accent or Color3.fromRGB(0, 180, 255)
end

local function playNotifySound(typeName: string?)
	local id = NOTIFY_SOUND_IDS[typeName or "Info"] or NOTIFY_SOUND_IDS.Info
	local ok, snd = pcall(function()
		local s = Instance.new("Sound")
		s.SoundId = id
		s.Volume = 0.35
		s.Parent = SoundService
		s:Play()
		game:GetService("Debris"):AddItem(s, 5)
		return s
	end)
	return ok and snd or nil
end

function Notifications:Notify(options: NotificationOptions): NotificationHandle
	local container = self:_getContainer()
	local maid = Maid.new()

	if options.Sound ~= false then
		playNotifySound(options.Type)
	end

	local card = Helpers.CreateFrame({
		Name = "Notification",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = self.Library.Theme.Secondary,
		LayoutOrder = os.clock(),
		Parent = container,
	})
	Helpers.Corner(card, Theme.CornerRadiusSmall)
	Helpers.Stroke(card, self.Library.Theme.Border, 1)
	Helpers.Padding(card, 12)

	local accent = Helpers.CreateFrame({
		Name = "Accent",
		Size = UDim2.new(0, 3, 1, -24),
		Position = UDim2.fromOffset(0, 12),
		BackgroundColor3 = self:_resolveAccent(options.Type),
		Parent = card,
	})

	local content = Helpers.CreateFrame({
		Name = "Content",
		Size = UDim2.new(1, -16, 0, 0),
		Position = UDim2.new(0, 16, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = card,
	})
	Helpers.ListLayout(content, 4)

	if options.Title then
		Helpers.CreateLabel({
			Name = "Title",
			Size = UDim2.new(1, 0, 0, 18),
			Text = options.Title,
			Font = Theme.FontBold,
			TextSize = 15,
			Parent = content,
		})
	end

	if options.Content then
		Helpers.CreateLabel({
			Name = "Body",
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Text = options.Content,
			TextColor3 = self.Library.Theme.TextMuted,
			TextWrapped = true,
			Parent = content,
		})
	end

	if options.Actions and #options.Actions > 0 then
		local actions = Helpers.CreateFrame({
			Name = "Actions",
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Parent = content,
		})
		Helpers.ListLayout(actions, 6, true, Enum.FillDirection.Horizontal)
		for _, action in ipairs(options.Actions) do
			local btn = Helpers.CreateButton({
				Name = "Action",
				Size = UDim2.new(0.5, -3, 0, 26),
				Text = action.Text,
				TextColor3 = self:_resolveAccent(options.Type),
				TextSize = 10,
				Font = Theme.FontBold,
				BackgroundColor3 = Color3.new(1, 1, 1),
				BackgroundTransparency = 0.92,
				Parent = actions,
			})
			Helpers.Corner(btn, 6)
			Helpers.Stroke(btn, self:_resolveAccent(options.Type), 1)
			btn.MouseButton1Click:Connect(function()
				if action.Callback then
					task.spawn(action.Callback)
				end
				maid:DoCleaning()
			end)
		end
	end

	card.BackgroundTransparency = 1
	accent.BackgroundTransparency = 1
	Tween.Play(card, { BackgroundTransparency = 0 })
	Tween.Play(accent, { BackgroundTransparency = 0 })

	local handle = {
		Destroy = function()
			maid:DoCleaning()
		end,
	}

	if options.Persistent then
		maid:Give(card)
		return handle
	end

	local duration = options.Duration or 4
	task.delay(duration, function()
		if card.Parent then
			Tween.Play(card, { BackgroundTransparency = 1 })
			task.delay(0.25, function()
				maid:DoCleaning()
			end)
		end
	end)

	maid:Give(card)
	return handle
end

function Notifications:Destroy()
	self._Maid:DoCleaning()
	self._Container = nil
end

return Notifications
