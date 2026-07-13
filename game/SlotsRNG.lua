local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Slots RNG",
   Icon = 0, -- Icon in Topbar. Can use Lucide Icons (string) or Roblox Image (number). 0 to use no icon (default).
   LoadingTitle = "Slots RNG script",
   LoadingSubtitle = "by Datfeite",
   ShowText = "Slots RNG", -- for mobile users to unhide Rayfield, change if you'd like
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

local AutoSpin = false
local AutospinHow = "Perfect"
local AutoSpinDelay = 0.10
local AutoUpgrade = false
local AutoUpgradeWhich = "luck"
local Money UpgradeBefore = nil
local Money UpgradeAfter = nil
local AutoRebirth = false

local function parseShortNumber(str)
    str = str:gsub(",", ""):gsub("%s", "") -- strip commas/spaces
    local suffixes = { K = 1e3, M = 1e6, B = 1e9, T = 1e12 }
    local num, suffix = str:match("^([%d%.]+)([KMBTkmbt]?)$")
    if not num then return 0 end
    num = tonumber(num) or 0
    if suffix and suffix ~= "" then
        num = num * (suffixes[suffix:upper()] or 1)
    end
    return math.floor(num)
end

local function getCoins()
    local ok, result = pcall(function()
        return parseShortNumber(
            game:GetService("Players").LocalPlayer
                .PlayerGui.HUD.Currency.Container.Coins.Balance.ContentText
        )
    end)
    if ok then
        return result
    else
        warn("getCoins failed:", result)
        return 0
    end
end

local CoinsLabel = game:GetService("Players").LocalPlayer.PlayerGui.HUD.Currency.Container.Coins.Balance


local SpinSlider = MainTab:CreateSlider({
    Name = "Auto Spin Delay",
    Range = {0.01, 0.99},
    Increment = 0.10,
    Suffix = "ms",
    CurrentValue = 0.10,
    Flag = "SpinningFlgSlider",
    Callback = function(AutspSld)
        AutoSpinDelay = AutspSld
    end,
})

local SpinDropdown = MainTab:CreateDropdown({
    Name = "Auto Spin",
    Options = {"Perfect", "Amazing", "Great", "Okay"},
    CurrentOption = {"Perfect"},
    MultipleOptions = false,
    Flag = "SpinningFlgDropdown",
    Callback = function(AutspDRP)
        AutospinHow = AutspDRP[1]
        print("Set Auto Spin to:", AutospinHow)
    end,
})

local SpinToggle = MainTab:CreateToggle({
    Name = "Auto Spin",
    CurrentValue = false,
    Flag = "SpinningFlg",
    Callback = function(Autsp)
        AutoSpin = Autsp
        if Autsp then
            print("Auto Spinning on:", AutospinHow, "With a", AutoSpinDelay, "Delay")
        end
    end,
})

task.spawn(function()
    while true do
        if AutoSpin then
            game:GetService("ReplicatedStorage")
                :WaitForChild("Events")
                :WaitForChild("SpinRequest")
                :FireServer(AutospinHow)
            print("Auto spun on:", AutospinHow)
        end
        task.wait(AutoSpinDelay)
    end
end)

local UpgradeDropdown = MainTab:CreateDropdown({
    Name = "Auto Upgrade",
    Options = {"payout", "luck", "meterSpeed", "zoneWidth"},
    CurrentOption = {"luck"},
    MultipleOptions = false,
    Flag = "AutoUpgradeDropdown1",
    Callback = function(Auoupg)
        AutoUpgradeWhich = Auoupg[1]
        print("Set Auto Upgrade to:", AutoUpgradeWhich)
    end,
})

local UpgradeToggle = MainTab:CreateToggle({
    Name = "Auto Upgrade",
    CurrentValue = false,
    Flag = "AutoUpgradeToggle1",
    Callback = function(AuoupgTogl)
        AutoUpgrade = AuoupgTogl
        if AuoupgTogl then
            print("Auto Upgrade Activated on:", AutoUpgradeWhich)
        end
    end,
})

task.spawn(function()
    while true do
        if AutoUpgrade then
            local before = getCoins()

            game:GetService("ReplicatedStorage")
                :WaitForChild("Events")
                :WaitForChild("UpgradeRequest")
                :FireServer(AutoUpgradeWhich)

            task.wait(0.5)

            local after = getCoins()

            if after == before then
                print("Upgrading:", AutoUpgradeWhich, "Failed - Not enough money! or Maxed")
            else
                print("Upgraded:", AutoUpgradeWhich, "| Before:", before, "| After:", after)
            end
        end
        task.wait(1)
    end
end)

local Toggle = MainTab:CreateToggle({
   Name = "Auto Rebirth",
   CurrentValue = false,
   Flag = "AutoRebirthToggle1", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   Callback = function(Autrb)
    AutoRebirth = Autrb
    if Autrb then 
        print("Auto Rebirth Activated!")
    else 
        print("Auto Rebirth Deactivated!")
    end
   end,
})

task.spawn(function()
    while true do 
        if AutoRebirth then
            game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("RebirthRequest"):FireServer()
            print("tried to Rebirth")
        end
    task.wait(10)
    end
end
)
