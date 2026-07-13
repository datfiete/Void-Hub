--!strict

local Theme = require(script.Parent.Theme)
local Maid = require(script.Parent.Parent.Utils.Maid)
local Helpers = require(script.Parent.Parent.Utils.Helpers)
local Tween = require(script.Parent.Parent.Utils.Tween)

local Notifications = {}
Notifications.__index = Notifications

export type NotificationOptions = {
	Title: string?,
	Content: string?,
	Duration: number?,
	Type: ("Info" | "Success" | "Warning" | "Error")?,
}

export type NotificationHandle = {
	Destroy: (self: NotificationHandle) -> (),
}

function Notifications.new(library: { Theme: typeof(Theme) })
	local self = setmetatable({
		Library = library,
		_Maid = Maid.new(),
		_Container = nil :: Frame?,
	}, Notifications)

	return self
end

function Notifications:_getContainer(): Frame
	if self._Container then
		return self._Container
	end

	local Players = game:GetService("Players")
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "CyberUI_Notifications"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui
	self._Maid:Give(screenGui)

	local container = Helpers.CreateFrame({
		Name = "Container",
		Size = UDim2.new(0, 320, 1, -40),
		Position = UDim2.new(1, -20, 0, 20),
		AnchorPoint = Vector2.new(1, 0),
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = screenGui,
	})

	Helpers.ListLayout(container, 8)
	self._Container = container
	return container
end

function Notifications:_resolveAccent(typeName: string?): Color3
	if typeName == "Success" then
		return self.Library.Theme.Success
	elseif typeName == "Warning" then
		return self.Library.Theme.Warning
	elseif typeName == "Error" then
		return self.Library.Theme.Error
	end
	return self.Library.Theme.Accent
end

function Notifications:Notify(options: NotificationOptions): NotificationHandle
	local container = self:_getContainer()
	local maid = Maid.new()

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
		Size = UDim2.new(0, 3, 1, 0),
		BackgroundColor3 = self:_resolveAccent(options.Type),
		Parent = card,
	})

	local content = Helpers.CreateFrame({
		Name = "Content",
		Size = UDim2.new(1, -10, 0, 0),
		Position = UDim2.new(0, 10, 0, 0),
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

	card.BackgroundTransparency = 1
	accent.BackgroundTransparency = 1
	Tween.Play(card, { BackgroundTransparency = 0 })
	Tween.Play(accent, { BackgroundTransparency = 0 })

	local duration = options.Duration or 4
	task.delay(duration, function()
		if card.Parent then
			Tween.Play(card, { BackgroundTransparency = 1 })
			task.delay(0.2, function()
				maid:DoCleaning()
			end)
		end
	end)

	local handle = {
		Destroy = function()
			maid:DoCleaning()
		end,
	}

	maid:Give(card)
	return handle
end

function Notifications:Destroy()
	self._Maid:DoCleaning()
	self._Container = nil
end

return Notifications
