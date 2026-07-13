--[[
	CyberUI Showcase

	Usage in Roblox (LocalScript):
		local CyberUI = loadstring(game:HttpGet("YOUR_RAW_URL"))()
		-- or require from ReplicatedStorage if bundled as a ModuleScript folder
]]

local CyberUI = require(script.Parent.src)

local window = CyberUI:CreateWindow({
	Title = "CyberUI",
	Subtitle = "Showcase",
})

local mainTab = window:CreateTab("Main")
local settingsTab = window:CreateTab("Settings")
local visualsTab = window:CreateTab("Visuals")

local introSection = mainTab:CreateSection("Welcome")
local generalSection = mainTab:CreateSection("General")
local actionSection = mainTab:CreateSection("Actions")

local preferencesSection = settingsTab:CreateSection("Preferences")
local bindsSection = settingsTab:CreateSection("Keybinds")

local themeSection = visualsTab:CreateSection("Theme")

introSection:CreateParagraph({
	Title = "CyberUI",
	Content = "All core elements are available below. Each element supports Set(), Get(), and Destroy().",
})

local enabledToggle = generalSection:CreateToggle({
	Name = "Enabled",
	Flag = "Enabled",
	Default = false,
	Callback = function(value)
		print("[CyberUI] Enabled:", value)
	end,
})

generalSection:CreateSlider({
	Name = "Walk Speed",
	Flag = "WalkSpeed",
	Min = 16,
	Max = 100,
	Default = 16,
	Rounding = 1,
})

generalSection:CreateDropdown({
	Name = "Mode",
	Flag = "Mode",
	Options = { "Legit", "Rage", "Custom" },
	Default = "Legit",
})

generalSection:CreateInput({
	Name = "Username",
	Flag = "Username",
	Placeholder = "Enter username...",
	Default = "",
})

actionSection:CreateButton({
	Name = "Run Action",
	Callback = function()
		window:Notify({
			Title = "Action",
			Content = "Button clicked.",
			Type = "Success",
			Duration = 3,
		})
	end,
})

preferencesSection:CreateToggle({
	Name = "Notifications",
	Flag = "Notifications",
	Default = true,
})

bindsSection:CreateKeybind({
	Name = "Toggle UI",
	Flag = "ToggleUI",
	Default = Enum.KeyCode.RightControl,
})

themeSection:CreateColorPicker({
	Name = "Accent Color",
	Flag = "AccentColor",
	Default = CyberUI.Theme.Accent,
	Callback = function(color)
		print("[CyberUI] Accent:", color)
	end,
})

enabledToggle:OnChanged(function(value)
	print("[CyberUI] OnChanged:", value)
end)

print("[CyberUI] Flags snapshot:", CyberUI.Flags)

return CyberUI
