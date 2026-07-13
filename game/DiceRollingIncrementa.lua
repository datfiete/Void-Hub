local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Dice Rolling Incrementa",
   Icon = 0, -- Icon in Topbar. Can use Lucide Icons (string) or Roblox Image (number). 0 to use no icon (default).
   LoadingTitle = "Dice Rolling Incrementa script",
   LoadingSubtitle = "by Datfeite",
   ShowText = "Dice Rolling Incrementa", -- for mobile users to unhide Rayfield, change if you'd like
   Theme = "Default", -- Check https://docs.sirius.menu/rayfield/configuration/themes

   ToggleUIKeybind = "K", -- The keybind to toggle the UI visibility (string like "K" or Enum.KeyCode)

   DisableRayfieldPrompts = false,
   DisableBuildWarnings = false, -- Prevents Rayfield from emitting warnings when the script has a version mismatch with the interface.

   -- ScriptID = "sid_xxxxxxxxxxxx", -- Your Script ID from developer.sirius.menu — enables analytics, managed keys, and script hosting

   ConfigurationSaving = {
      Enabled = false,
      FolderName = nil, -- Create a custom folder for your hub/game
      FileName = "Big Hub"
   },

   Discord = {
      Enabled = false, -- Prompt the user to join your Discord server if their executor supports it
      Invite = "noinvitelink", -- The Discord invite code, do not include Discord.gg/. E.g. Discord.gg/ABCD would be ABCD
      RememberJoins = true -- Set this to false to make them join the Discord every time they load it up
   },

   KeySystem = false, -- Set this to true to use our key system
   KeySettings = {
      Title = "Untitled",
      Subtitle = "Key System",
      Note = "No method of obtaining the key is provided", -- Use this to tell the user how to get a key
      FileName = "Key", -- It is recommended to use something unique, as other scripts using Rayfield may overwrite your key file
      SaveKey = true, -- The user's key will be saved, but if you change the key, they will be unable to use your script
      GrabKeyFromSite = false, -- If this is true, set Key below to the RAW site you would like Rayfield to get the key from
      Key = {"Hello"} -- List of keys that the system will accept, can be RAW file links (pastebin, github, etc.) or simple strings ("hello", "key22")
   }
})

local MainTab = Window:CreateTab("Main", 4483362458)
local DevTab = Window:CreateTab("Developer", 4483362458)

local Autoroll = false
local Autorebirth = false
local AutoUpgradeDropdown = {"Star Max Roll"}
local AutoUpgrade = false
local AutoUpgradeDropdownCoin = {"Coin Gain"}
local AutoUpgradeCoin = false

local Toggle = MainTab:CreateToggle({
   Name = "Auto Roll",
   CurrentValue = false,
   Flag = "AutoRollToggle", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   Callback = function(Autrolltg)
    Autoroll = Autrolltg 
    print("Auto rolling Active")
   end,
})

task.spawn(function()
    while true do 
        if Autoroll then 
            game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Roll"):FireServer()
        end
    task.wait(0.2)
    end
end
)


local Toggle = MainTab:CreateToggle({
   Name = "Auto Rebirth",
   CurrentValue = false,
   Flag = "AutoRebirthToggle", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   Callback = function(Autrbth)
    Autorebirth = Autrbth 
    print ("Auto rebirth Active")
   end,
})

task.spawn(function()
    while true do 
        if Autorebirth then 
            local args = {
	        "Prestige"
            }
            game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Reset"):FireServer(unpack(args))
        end
    task.wait(0.5)
    end
end
)

local Dropdown = MainTab:CreateDropdown({
   Name = "Auto Upgrade Stars",
   Options = {"Star Max Roll", "Star Min Roll", "Star Extra Dice", "Star Mega Dice", "Star Giga Dice", "Star Colossal Chance", "Star Variant Luck"},
   CurrentOption = {"Star Max Roll"},
   MultipleOptions = false,
   Flag = "AutoUpgradeDropdown1", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   Callback = function(Autmaxupf)
    AutoUpgradeDropdown = Autmaxupf[1]
    print("Changed Auto Upgrade with Stars to:", AutoUpgrade)
   end,
})

local Toggle = MainTab:CreateToggle({
   Name = "Auto Upgrade Stars",
   CurrentValue = false,
   Flag = "AutoUpgradeTogglr", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   Callback = function(Autupg)
    AutoUpgrade = Autupg 
    print("Activated Auto rolling on:", AutoUpgradeDropdown)
   end,
})

task.spawn(function()
    while true do 
        if AutoUpgrade then 
            local args = {
	        AutoUpgradeDropdown,
	        "1",
	        "Stars",
	        "Stars"
            }
            game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Upgrade"):FireServer(unpack(args))
        end
    task.wait(0.5)
    end
end
)



local Dropdown = MainTab:CreateDropdown({
   Name = "Auto Upgrade Coin",
   Options = {"Coin Gain", "Coin Multi", "Max Roll"},
   CurrentOption = {"Coin Gain"},
   MultipleOptions = false,
   Flag = "AutoUpgradeDropdown1Coin", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   Callback = function(AutoCom)
    AutoUpgradeDropdownCoin = AutoCom[1]
    print("Changed Auto Upgrade with Coins to:", AutoUpgradeDropdownCoin)
   end,
})

local Toggle = MainTab:CreateToggle({
   Name = "Auto Upgrade Coin",
   CurrentValue = false,
   Flag = "AutoUpgradeTogglrCoin", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   Callback = function(AutupgCoin)
    AutoUpgradeCoin = AutupgCoin 
    print("Activated Auto rolling on:", AutoUpgradeDropdownCoin)
   end,
})

task.spawn(function()
    while true do 
        if AutoUpgradeCoin then 
            local args = {
	        AutoUpgradeDropdownCoin,
	        "1",
	        "Stars",
	        "Stars"
            }
            game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Upgrade"):FireServer(unpack(args))
        end
    task.wait(0.5)
    end
end
)
