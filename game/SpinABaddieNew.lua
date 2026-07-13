local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Spin for Baddies",
   Icon = 0, -- Icon in Topbar. Can use Lucide Icons (string) or Roblox Image (number). 0 to use no icon (default).
   LoadingTitle = "Spin for Baddies script",
   LoadingSubtitle = "by Datfeite",
   ShowText = "Spin for Baddies", -- for mobile users to unhide Rayfield, change if you'd like
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
local AutoSpinDelay = 0.10
local AutoEquipBest = false
local AutoUnlockArea = false
local AutoClaimIndex = false

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

local Toggle = MainTab:CreateToggle({
   Name = "Auto Roll",
   CurrentValue = false,
   Flag = "AutoRollToggle", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   Callback = function(Autrotoggle)
    Autoroll = Autrotoggle 
    if Autrotoggle then 
        print("Auto Rolling Active!")
    else 
        print("Auto Rolling Deactive!")
    end
   end,
})

task.spawn(function()
    while true do 
        if Autoroll then 
            local args = {
	        "requestRoll"
            }
            game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("leifstout_networker@0.3.1"):WaitForChild("networker"):WaitForChild("_remotes"):WaitForChild("RollService"):WaitForChild("RemoteFunction"):InvokeServer(unpack(args))
            print("Rolled!")
        end
    task.wait(AutoSpinDelay)
    end
end
)

local Toggle = MainTab:CreateToggle({
   Name = "Auto Equip best",
   CurrentValue = false,
   Flag = "AutoEquipbestToggle", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   Callback = function(Aubetggl)
    AutoEquipBest = Aubetggl
    if Aubetggl then 
        print("Auto Equipping Best Active")
    else 
        print("Auto Equipping Best Deactive")
    end
   end,
})

task.spawn(function()
    while true do 
        if AutoEquipBest then 
            local args = {
	        "requestEquipBest"
            }
            game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("leifstout_networker@0.3.1"):WaitForChild("networker"):WaitForChild("_remotes"):WaitForChild("InventoryService"):WaitForChild("RemoteFunction"):InvokeServer(unpack(args))
            print("Equipped Best Baddies!")
        end
    task.wait(5)
    end
end
)

local Toggle = MainTab:CreateToggle({
   Name = "Auto Unlock Next Area",
   CurrentValue = false,
   Flag = "AutoUnlockAreaToggle", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   Callback = function(Autnnearea)
    AutoUnlockArea = Autnnearea
    if Autnnearea then 
        print("Auto Unlock Next Area Active")
    else 
        print("Auto Unlock Next Area Deactive")
    end
   end,
})

task.spawn(function()
    while true do 
        if AutoUnlockArea then 
            local args = {
	        "requestPurchaseZone"
            }
            game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("leifstout_networker@0.3.1"):WaitForChild("networker"):WaitForChild("_remotes"):WaitForChild("ZonesService"):WaitForChild("RemoteFunction"):InvokeServer(unpack(args))
        end
    task.wait(5)
    end
end
)

local Toggle = MainTab:CreateToggle({
   Name = "Auto Claim Index",
   CurrentValue = false,
   Flag = "AutoClaimIndexToggle", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   Callback = function(AutClInd)
    AutoClaimIndex = AutClInd 
    if AutClInd then 
        print("Auto Claim Index Active")
    else 
        print("Auto Claim Index Deactive")
    end
   end,
})

task.spawn(function()
    while true do 
        if AutoClaimIndex then
            local args = {
	        "requestClaimReward",
	        "basic"
            }
            game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("leifstout_networker@0.3.1"):WaitForChild("networker"):WaitForChild("_remotes"):WaitForChild("IndexService"):WaitForChild("RemoteFunction"):InvokeServer(unpack(args))
            print("Tried Claimin Basic Index")
            task.wait(1)
            local args = {
	        "requestClaimReward",
	        "big"
            }
            game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("leifstout_networker@0.3.1"):WaitForChild("networker"):WaitForChild("_remotes"):WaitForChild("IndexService"):WaitForChild("RemoteFunction"):InvokeServer(unpack(args))
            print("Tried Claimin Big Index")
            task.wait(1)
            local args = {
	        "requestClaimReward",
	        "huge"
            }
            game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("leifstout_networker@0.3.1"):WaitForChild("networker"):WaitForChild("_remotes"):WaitForChild("IndexService"):WaitForChild("RemoteFunction"):InvokeServer(unpack(args))
            print("Tried Claimin Huge Index")
            task.wait(1)
            local args = {
	        "requestClaimReward",
	        "shiny"
            }
            game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("leifstout_networker@0.3.1"):WaitForChild("networker"):WaitForChild("_remotes"):WaitForChild("IndexService"):WaitForChild("RemoteFunction"):InvokeServer(unpack(args))
            print("Tried Claimin shiny Index")
            task.wait(1)
            local args = {
	        "requestClaimReward",
	        "inverted"
            }
            game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("leifstout_networker@0.3.1"):WaitForChild("networker"):WaitForChild("_remotes"):WaitForChild("IndexService"):WaitForChild("RemoteFunction"):InvokeServer(unpack(args))
            print("Tried Claimin Inverted Index")
            task.wait(1)
        end
    task.wait(10)
    end
end
)
