-- Copy-paste ready Rayfield-style examples
-- Use any of these blocks directly in your own script.

-- This file is a copy-paste template for Roblox scripts.
-- Run it in Studio/Roblox to see the UI blocks in action.
local CyberUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/fietewoozle-dot/MyHub/main/CyberUI/load.lua"))()

local Window = CyberUI:CreateWindow({
	Name = "Developer Suite",
	Title = "Developer Suite",
	Subtitle = "Interactive elements",
	Size = Vector2.new(760, 620),
	Center = true,
	ConfigurationSaving = {
		Enabled = true,
		FolderName = "CyberUI",
		FileName = "DeveloperSuite",
		AutoSave = true,
	},
})

local Main = Window:CreateTab("Main")
local Automation = Main:CreateSection("Automation")
local Extras = Main:CreateSection("Extras")

-- Toggle
Automation:CreateToggle({
	Name = "Auto Farm",
	CurrentValue = false,
	Flag = "AutoFarm",
	Callback = function(value)
		print("Auto Farm:", value)
	end,
})

-- Slider
Automation:CreateSlider({
	Name = "Speed",
	Min = 16,
	Max = 100,
	Default = 16,
	Rounding = 1,
	Flag = "Speed",
	Callback = function(value)
		print("Speed:", value)
	end,
})

-- Dropdown
Automation:CreateDropdown({
	Name = "Rarity",
	Options = {"Common", "Rare", "Epic", "Legendary"},
	CurrentOption = {"Rare"},
	MultipleOptions = true,
	Flag = "Rarity",
	Callback = function(options)
		print("Selected:", table.concat(options, ", "))
	end,
})

-- Input
Automation:CreateInput({
	Name = "Notes",
	Placeholder = "Type something",
	Default = "Hello",
	Flag = "Notes",
	Save = false,
	Callback = function(value)
		print("Notes:", value)
	end,
})

-- Button
Automation:CreateButton({
	Name = "Notify",
	Callback = function()
		Window:Notify({
			Title = "CyberUI",
			Content = "Rayfield-style template loaded.",
			Type = "Info",
			Duration = 2,
		})
	end,
})

-- Keybind
Extras:CreateKeybind({
	Name = "Toggle Key",
	Default = Enum.KeyCode.F,
	Flag = "ExampleKeybind",
	Callback = function(key)
		print("Keybind:", key.Name)
	end,
})

-- Color Picker
Extras:CreateColorPicker({
	Name = "Accent",
	CurrentValue = Color3.fromRGB(67, 214, 255),
	Flag = "AccentPreview",
	Callback = function(color)
		print("Color:", color)
	end,
})

-- Paragraph / Info block
Extras:CreateParagraph({
	Title = "Tips",
	Content = "You can paste the rest of your Rayfield-style UI code below this block.",
})

-- Example of a second tab
local Settings = Window:CreateTab("Settings")
local SettingsSection = Settings:CreateSection("General")

SettingsSection:CreateToggle({
	Name = "Enabled",
	CurrentValue = true,
	Flag = "SettingsEnabled",
})

SettingsSection:CreateSlider({
	Name = "Volume",
	Min = 0,
	Max = 100,
	Default = 50,
	Flag = "Volume",
})

