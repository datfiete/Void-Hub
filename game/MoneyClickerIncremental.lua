local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Money Clicker Incremental",
   Icon = 0, -- Icon in Topbar. Can use Lucide Icons (string) or Roblox Image (number). 0 to use no icon (default).
   LoadingTitle = "SMoney Clicker Incremental script",
   LoadingSubtitle = "by Datfeite",
   ShowText = "Money Clicker Incremental", -- for mobile users to unhide Rayfield, change if you'd like
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

local AutoClicking = false
local AutoUpgradeing = false
local AutoUpgradeingDropdown = {"Currency"}
local Autorebirth = false
local MoneyBeforeUpg = game:GetService("Players").LocalPlayer.Stats.Money.Value
local MoneyAfterUpg = game:GetService("Players").LocalPlayer.Stats.Money.Value
local MoneyBeforeReb = game:GetService("Players").LocalPlayer.Stats.Money.Value
local MoneyAfterReb = game:GetService("Players").LocalPlayer.Stats.Money.Value

local Toggle = MainTab:CreateToggle({
   Name = "Auto Clicker",
   CurrentValue = false,
   Flag = "AutoClickerToggle", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   Callback = function(Aucktohl)
    AutoClicking = Aucktohl 
    print("Auto Clicker Active")
   end,
})

task.spawn(function()
    while true do 
        if AutoClicking then 
            game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("ClickMoney"):FireServer()
        end
    task.wait(0.3)
    end
end
)

local Dropdown = MainTab:CreateDropdown({
   Name = "Upgrading",
   Options = {"Currency", "Clicker"},
   CurrentOption = {"Currency"},
   MultipleOptions = false,
   Flag = "UpgradingDropdown1", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   Callback = function(upgdropw)
    AutoUpgradeingDropdown = upgdropw[1]
    print("set Auto Upgrade to:", AutoUpgradeingDropdown)
   end,
})

local Toggle = MainTab:CreateToggle({
   Name = "Auto Upgrade",
   CurrentValue = false,
   Flag = "AutoUpgradeToggle", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   Callback = function(Autougptogle)
    AutoUpgradeing = Autougptogle
    print("Auto Upgrading Active")
   end,
})

local UpgradingType = {
    ["Currency"] = 1,
    ["Clicker"] = 2,
}

task.spawn(function()
    while true do 
        if AutoUpgradeing then 
            MoneyBeforeUpg = game:GetService("Players").LocalPlayer.Stats.Money.Value
            local args = {
	        UpgradingType[AutoUpgradeingDropdown],
	        false
            }
            game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("Upgrade"):FireServer(unpack(args))
            MoneyAfterUpg = game:GetService("Players").LocalPlayer.Stats.Money.Value 
            if MoneyAfterUpg ~= MoneyBeforeUpg then
                print("Upgraded:", UpgradingType)
            end
        end
    task.wait(0.3)
    end
end
)

local Toggle = MainTab:CreateToggle({
   Name = "Auto Rebirth",
   CurrentValue = false,
   Flag = "AutoRebirthToggle", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   Callback = function(Autoretog)
    Autorebirth = Autoretog 
    print("Auto Rebirth Activated")
   end,
})

task.spawn(function()
    while true do 
        if Autorebirth then 
            MoneyBeforeReb = game:GetService("Players").LocalPlayer.Stats.Money.Value
            game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("Prestige"):FireServer()
            MoneyAfterReb = game:GetService("Players").LocalPlayer.Stats.Money.Value
            if MoneyBeforeReb ~= MoneyAfterReb then 
                print("Rebirthed")
            end
        end
    task.wait(1)
    end
end
)
