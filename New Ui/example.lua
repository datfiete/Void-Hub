--[[
	ModernUI - Beispielskript
	Zeigt alle wichtigen Komponenten in einem Rayfield-artigen Aufbau.
]]

local ModernUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/fietewoozle-dot/MyHub/refs/heads/main/New%20Ui/ModernUI_fixed.lua"))()

local Window = ModernUI:CreateWindow({
	Name = "Beispiel Hub",
	Theme = "Dark",
	Discord = { Invite = "https://discord.gg/pmJABXQtw" },
	ConfigurationSaving = { Enabled = true, FileName = "beispiel_config" },
})

-- ===================== TAB: Main =====================
local MainTab = Window:CreateTab("Main", "home")

MainTab:CreateSection("Aktionen")

MainTab:CreateButton({
	Name = "Sage Hallo",
	Callback = function()
		Window:Notify({ Title = "Hallo", Content = "Button wurde gedrückt!", Image = "success" })
	end,
})

MainTab:CreateToggle({
	Name = "Auto-Farm",
	CurrentValue = false,
	Flag = "AutoFarm",
	Callback = function(value)
		print("Auto-Farm:", value)
	end,
})

MainTab:CreateSlider({
	Name = "WalkSpeed",
	Range = { 16, 200 },
	Increment = 1,
	Suffix = "",
	CurrentValue = 16,
	Flag = "WalkSpeedSlider",
	Callback = function(value)
		local char = game.Players.LocalPlayer.Character
		if char and char:FindFirstChild("Humanoid") then
			char.Humanoid.WalkSpeed = value
		end
	end,
})

MainTab:CreateDropdown({
	Name = "Zielmodus",
	Options = { "Nächster Spieler", "Schwächster", "Zufällig" },
	CurrentOption = "Nächster Spieler",
	Flag = "TargetMode",
	Callback = function(option)
		print("Modus:", option)
	end,
})

MainTab:CreateInput({
	Name = "Chat-Nachricht",
	PlaceholderText = "Nachricht eingeben...",
	Flag = "ChatInput",
	Callback = function(text)
		print("Eingegeben:", text)
	end,
})

MainTab:CreateKeybind({
	Name = "UI Toggle",
	CurrentKeybind = "RightShift",
	Flag = "UIToggleKey",
	Callback = function()
		print("Keybind ausgelöst")
	end,
})

MainTab:CreateParagraph({
	Title = "Über dieses Script",
	Content = "Dies ist ein Beispiel, das zeigt, wie man alle ModernUI Komponenten verwendet.",
})

MainTab:CreateLabel("Einfacher Hinweistext ohne Rahmen")

MainTab:CreateColorPicker({
	Name = "ESP Farbe",
	Color = Color3.fromRGB(114, 137, 218),
	Flag = "ESPColor",
	Callback = function(color)
		print("Farbe:", color)
	end,
})

-- ===================== TAB: Extra =====================
local ExtraTab = Window:CreateTab("Extra", "star")

ExtraTab:CreateSection("Dialoge")

ExtraTab:CreateButton({
	Name = "Bestätigungsdialog anzeigen",
	Callback = function()
		Window:CreateDialog({
			Title = "Bist du sicher?",
			Content = "Diese Aktion kann nicht rückgängig gemacht werden.",
			Buttons = {
				{ Title = "Abbrechen" },
				{
					Title = "Bestätigen",
					Accent = true,
					Callback = function()
						Window:Notify({ Title = "Bestätigt", Content = "Aktion ausgeführt.", Image = "success" })
					end,
				},
			},
		})
	end,
})

ExtraTab:CreateButton({
	Name = "Warnung anzeigen",
	Callback = function()
		Window:Notify({ Title = "Achtung", Content = "Das ist eine Warnung.", Image = "warning" })
	end,
})

ExtraTab:CreateButton({
	Name = "Fehler anzeigen",
	Callback = function()
		Window:Notify({ Title = "Fehler", Content = "Etwas ist schiefgelaufen.", Image = "error" })
	end,
})

-- Der "Visuals"-Tab (Theme, Skalierung, Hintergrund, Farben, Sounds, Config)
-- wird automatisch von der Bibliothek erstellt - keine weitere Aktion nötig.
