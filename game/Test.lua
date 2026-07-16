--!strict
-- Void Hub Full Feature Example Script
-- Shows many features etc

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/datfiete/Void-Hub/refs/heads/main/CyberUI/load.lua"))()

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local RootPart = Character:WaitForChild("HumanoidRootPart")
local Executor = getexecutorname()
local Avatar = Players:GetUserThumbnailAsync(
    Player.UserId,
    Enum.ThumbnailType.HeadShot,
    Enum.ThumbnailSize.Size150x150
)

Library.Theme.Style = "Meng"

local Window = Library:CreateWindow({
    Title = "Void Hub",
    Subtitle = "Universal Script Hub",
    BackgroundImage = "rbxassetid://106318186489675",

    Logo = "rbxassetid://128228297210141",
    Badges = {
        { Text = "Void Hub | v1.0" },
        { Text = "Executor: " .. Executor },
    },

    Footer = {
        Avatar = Avatar,
        Username = Player.Name,
    },


    ConfigurationSaving = {
        Enabled = true,
        AutoSave = true,
    },

    ShowSearch = true,
    ShowWindowControls = true,
    ToggleKey = Enum.KeyCode.RightControl,
})

local MainTab = Window:CreateTab("Main")
local PlayerTab = Window:CreateTab("Player")
local MiscTab = Window:CreateTab("Misc")


local FarmSection = MainTab:CreateSection("Farming")
local CombatSection = MainTab:CreateSection("Combat")
local FeaturesSection = MainTab:CreateSection("Other Things")
local MovementSection = PlayerTab:CreateSection("Movement")
local InfoSection = MiscTab:CreateSection("Information")

FarmSection:CreateParagraph({
	Title = "Auto Farm",
	Content = "Automatically farm resources in the current area.",
})

FarmSection:CreateToggle({
	Name = "Auto Farm",
	CurrentValue = false,
	Flag = "Main.AutoFarm",
	Callback = function(value: boolean)
		print("Auto Farm:", value)
        if value then 
            Window:Notify({
                Title = "Auto Farm Toggle",
                Content = "Auto Farm Toggle has been Activated",
                Type = "Success",
                Duration = 4,
            })
        else 
            Window:Notify({
                Title = "Auto Farm Toggle",
                Content = "Auto Farm Toggle has been Deactivated",
                Type = "Success",
                Duration = 4,
            })
        end
	end,
})

FarmSection:CreateDropdown({
	Name = "Farm Location",
	Options = {"Starter Zone", "Forest", "Cave", "Ocean"},
	CurrentOption = "Starter Zone",
    MultipleOptions = false,
	Flag = "Main.FarmLocation",
	Callback = function(value: string)
		print("Farm Location:", value)
	end,
})

FarmSection:CreateDropdown({
	Name = "Farm Location",
	Options = {"Starter Zone", "Forest", "Cave", "Ocean"},
	CurrentOption = "Starter Zone",
    MultipleOptions = true,
	Flag = "Main.FarmLocation",
	Callback = function(value: string)
		print("Farm Location:", value)
	end,
})

FarmSection:CreateSlider({
	Name = "Farm Speed",
	Min = 1,
	Max = 10,
	CurrentValue = 5,
	Rounding = 1,
	Flag = "Main.FarmSpeed",
	Callback = function(value: number)
		print("Farm Speed:", value)
	end,
})

FarmSection:CreateButton({
	Name = "Teleport To Farm",
	Callback = function()
		print("Teleporting...")
	end,
})

CombatSection:CreateToggle({
	Name = "Auto Attack",
	CurrentValue = false,
	Flag = "Main.AutoAttack",
	Callback = function(value: boolean)
		print("Auto Attack:", value)
	end,
})

CombatSection:CreateKeybind({
	Name = "Attack Keybind",
	Default = Enum.KeyCode.E,
	Flag = "Main.AttackKey",
	Callback = function(key: Enum.KeyCode)
		print("Attack Key set to:", key)
	end,
})

FeaturesSection:CreateParagraph({
	Title = "Notifications",
	Content = "The Notification Colors changes with the Ui colors!",
})

FeaturesSection:CreateButton({
	Name = "Success Botification",
	Callback = function()
		Window:Notify({
            Title = "Success!",
            Content = "This is a Success Notification.",
            Type = "Success",
            Duration = 4,
        })
	end,
})

FeaturesSection:CreateButton({
	Name = "Info Botification",
	Callback = function()
		Window:Notify({
            Title = "Info!",
            Content = "This is a Info Notification.",
            Type = "Info",
            Duration = 4,
        })
	end,
})

FeaturesSection:CreateButton({
	Name = "Warning Botification",
	Callback = function()
		Window:Notify({
            Title = "Warning!",
            Content = "This is a Warning Notification.",
            Type = "Warning",
            Duration = 4,
        })
	end,
})

FeaturesSection:CreateButton({
	Name = "Error Botification",
	Callback = function()
		Window:Notify({
            Title = "Error!",
            Content = "This is a Error Notification.",
            Type = "Error",
            Duration = 4,
        })
	end,
})

FeaturesSection:CreateColorPicker({
	Name = "Color Picker",
	CurrentValue = Color3.fromRGB(255, 255, 255),
	Flag = "Player.NametagColor",
	Callback = function(color: Color3)
		print("Nametag Color:", color)
	end,
})

FeaturesSection:CreateInput({
	Name = "Input Thingi",
	PlaceholderText = "Enter a name...",
	Flag = "Player.CustomName",
	Callback = function(value: string)
		print("Custom Name:", value)
        Window:Notify({
            Title = "Dunno",
            Content = "You Typed: " .. value,
            Type = "Success",
            Duration = 4,
        })
	end,
})

MovementSection:CreateSlider({
	Name = "WalkSpeed",
	Min = 16,
	Max = 200,
	CurrentValue = 16,
	Rounding = 1,
	Flag = "Player.WalkSpeed",
	Callback = function(value: number)
		local character = game.Players.LocalPlayer.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = value
		end
	end,
})

MovementSection:CreateSlider({
	Name = "JumpPower",
	Min = 50,
	Max = 300,
	CurrentValue = 50,
	Rounding = 1,
	Flag = "Player.JumpPower",
	Callback = function(value: number)
		local character = game.Players.LocalPlayer.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.JumpPower = value
		end
	end,
})

MovementSection:CreateToggle({
	Name = "Infinite Jump",
	CurrentValue = false,
	Flag = "Player.InfiniteJump",
	Callback = function(value: boolean)
		print("Infinite Jump:", value)
	end,
})

InfoSection:CreateParagraph({
	Title = "About Void Hub",
	Content = "Void Hub is actively being developed. Please report bugs or detections in our Discord.",
})

InfoSection:CreateButton({
	Name = "Join Discord",
	Callback = function()
		setclipboard("https://discord.gg/j5UnnSsSjV")
	end,
})

InfoSection:CreateButton({
	Name = "Reload Configuration",
	Callback = function()
		Library:LoadConfiguration()
	end,
})


Window:Notify({
	Title = "Welcome!",
	Content = "Void Hub successfully loaded.",
	Type = "Success",
	Duration = 4,
})

task.spawn(function()
	task.wait(1)
	Library:LoadConfiguration()
end)

print("Test Loaded")
