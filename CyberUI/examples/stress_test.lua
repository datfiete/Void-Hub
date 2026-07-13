-- CyberUI stress test
-- Place this in a LocalScript under StarterPlayerScripts or run it directly in a LocalScript.

local CyberUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/fietewoozle-dot/MyHub/main/CyberUI/load.lua"))()

local window = CyberUI:CreateWindow({
	Title = "CyberUI Stress Test",
	Subtitle = "Try lots of tabs and controls",
	Size = Vector2.new(900, 700),
})

local function createSection(tab, name)
	return tab:CreateSection(name)
end

local function createManyControls(section)
	for i = 1, 8 do
		section:CreateToggle({
			Name = "Toggle " .. i,
			Flag = "Toggle" .. i,
			Default = i % 2 == 0,
		})
	end

	for i = 1, 8 do
		section:CreateSlider({
			Name = "Slider " .. i,
			Flag = "Slider" .. i,
			Min = 0,
			Max = 100,
			Default = i * 10,
			Rounding = 1,
		})
	end

	for i = 1, 6 do
		section:CreateDropdown({
			Name = "Dropdown " .. i,
			Flag = "Dropdown" .. i,
			Options = { "One", "Two", "Three", "Four" },
			Default = "Two",
		})
	end

	for i = 1, 4 do
		section:CreateInput({
			Name = "Input " .. i,
			Flag = "Input" .. i,
			Placeholder = "Type here",
			Default = "Value " .. i,
		})
	end

	for i = 1, 3 do
		section:CreateButton({
			Name = "Button " .. i,
			Callback = function()
				window:Notify({
					Title = "Button Pressed",
					Content = "Button " .. i .. " was pressed",
					Type = "Info",
					Duration = 2,
				})
			end,
		})
	end

	section:CreateParagraph({
		Title = "Info",
		Content = "This stress test is meant to reveal layout issues when the UI grows large.",
	})
end

for i = 1, 8 do
	local tab = window:CreateTab("Tab " .. i)
	for j = 1, 3 do
		createManyControls(createSection(tab, "Section " .. j))
	end
end

window:Notify({
	Title = "Stress Test Ready",
	Content = "This window contains many tabs and controls. Try resizing, switching tabs, and changing values.",
	Type = "Success",
	Duration = 4,
})

print("CyberUI stress test loaded")
