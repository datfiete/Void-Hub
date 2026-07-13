local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Keyboard Incremental",
   Icon = 0, -- Icon in Topbar. Can use Lucide Icons (string) or Roblox Image (number). 0 to use no icon (default).
   LoadingTitle = "Keyboard Incremental script",
   LoadingSubtitle = "by Datfeite",
   ShowText = "Keyboard Incremental", -- for mobile users to unhide Rayfield, change if you'd like
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

local AutoClick = false
local AutoClickRisky = false
local Autorebirth = false
local AutoMultiplierUpgrade = false
local AutoUpgrade = false
local AutoClickOpt = {}
local MultiplierUpgradeDropdown = {}
local UpgradeDropdown = "KeyValue"
local rootPart = game.Players.LocalPlayer.Character:WaitForChild("HumanoidRootPart")


local Dropdown = MainTab:CreateDropdown({
   Name = "Auto Level",
   Options = {"Normal", "Slime", "Emitter", "Lava", "Space"},
   CurrentOption = {"Normal"},
   MultipleOptions = false,
   Flag = "AutoClickDropdown1", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   Callback = function(Autgleeg1wf)
    AutoClickOpt = Autgleeg1wf[1]
    print("Changed Auto Clicking to:", Autgleeg1wf[1])
   end,
})

local Toggle = MainTab:CreateToggle({
   Name = "Auto Level",
   CurrentValue = false,
   Flag = "AutoClickToggle1", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   Callback = function(Autgleeg1)
    AutoClick = Autgleeg1 
    if Autgleeg1 then 
        print("Auto Clicking Active")
    else 
        print("Auto Clicking Active")
    end
   end,
})

task.spawn(function()
    while true do 
        if AutoClick then 
            local Event = game:GetService("ReplicatedStorage").Network_Unreliable
            Event:FireServer(
            "pressKey",
            Vector3.new(-223.73649597168, 265.28344726562, 24.649969100952),
            AutoClickOpt[1]
            )
        end
    task.wait(0.1)
    end
end
)

local Toggle = MainTab:CreateToggle({
   Name = "Auto Click, With keys(riskier)",
   CurrentValue = false,
   Flag = "AutoClickWithkeysToggle1", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   Callback = function(Autrisky)
    AutoClickRisky = Autrisky 
   end,
})

task.spawn(function()  -- Use task.spawn instead of task.wait
    while true do
        if AutoClickRisky then
            local spawnPad = workspace.Map.Area1.KeySpawner.SpawnPad
            if spawnPad then
                for _, v in pairs(spawnPad:GetChildren()) do
                    if v:IsA("BasePart") then
                        rootPart.CFrame = v.CFrame * CFrame.new(0, 5, 0)
                        task.wait(0.08)  -- Slightly faster but not too spammy
                    end
                end
            end
        end
        task.wait(0.5)
    end
end)

local Toggle = MainTab:CreateToggle({
   Name = "Auto Rebirth(Not Recomended)",
   CurrentValue = false,
   Flag = "AutoRebirthToggle1", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   Callback = function(Authedbgsdhbgws)
    Autorebirth = Authedbgsdhbgws
   end,
})

task.spawn(function()
    while true do 
        if Autorebirth then 
            local Event = game:GetService("ReplicatedStorage").Network_Unreliable
            Event:FireServer(
            "attemptRebirth"
            )
        end
    task.wait(1)
    end
end
)

local Dropdown = MainTab:CreateDropdown({
   Name = "Multiplier Upgrade",
   Options = {"KeyMultiplier", "PopupMultiplier", "StepRadius"},
   CurrentOption = {"KeyMultiplier"},
   MultipleOptions = false,
   Flag = "MultiplierUpgradeDropdown1", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   Callback = function(Multupgdrop)
    MultiplierUpgradeDropdown = Multupgdrop[1]
    print("set Multiplier Upgrade to:", Multupgdrop[1])
   end,
})

local Toggle = MainTab:CreateToggle({
   Name = "Multiplier Upgrade",
   CurrentValue = false,
   Flag = "MultiplierUpgradeToggle1", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   Callback = function(Mulrhfdqauaopghwqaiouv)
    AutoMultiplierUpgrade = Mulrhfdqauaopghwqaiouv
   end,
})

task.spawn(function()
    while true do 
        if AutoMultiplierUpgrade then 
            local Event = game:GetService("ReplicatedStorage").Network_Unreliable
            Event:FireServer(
                "attemptUpgrade",
                "Multipliers",
                MultiplierUpgradeDropdown[1] --ändern
            )
            print(AutoMultiplierUpgrade)
        end
    task.wait(1)
    end
end
)

local Dropdown = MainTab:CreateDropdown({
   Name = "Auto Upgrade",
   Options = {"KeyValue", "Expansion", "PopupRate"},
   CurrentOption = {"KeyValue"},
   MultipleOptions = false,
   Flag = "AutoUpgradeDropdown1", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   Callback = function(Aurdhdfhdfh)
    UpgradeDropdown = Aurdhdfhdfh[1]
    print("Changed Auto Upgrade to:", UpgradeDropdown)
   end,
})

task.spawn(function()
    while true do 
        if AutoUpgrade then 
            local Event = game:GetService("ReplicatedStorage").Network_Unreliable
            Event:FireServer(
                "attemptUpgrade",
                "Upgrades",
                UpgradeDropdown,
                true
            )
        end
    task.wait(1)
    end
end
)

local Toggle = MainTab:CreateToggle({
   Name = "Auto Upgrade",
   CurrentValue = false,
   Flag = "AutoUpgradeToggle1", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   Callback = function(Aurhsdfh)
    AutoUpgrade = Aurhsdfh 
   end,
})
