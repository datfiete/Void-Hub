local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "My Fishing Brainrots",
   Icon = 0, -- Icon in Topbar. Can use Lucide Icons (string) or Roblox Image (number). 0 to use no icon (default).
   LoadingTitle = "My Fishing Brainrots script",
   LoadingSubtitle = "by Datfeite",
   ShowText = "My Fishing Brainrots", -- for mobile users to unhide Rayfield, change if you'd like
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

local rootPart = game.Players.LocalPlayer.Character:WaitForChild("HumanoidRootPart")
local player = game.Players.LocalPlayer
local Character = player.Character or player.CharacterAdded:Wait()

local AutoFarm = false
local AutoSellBox = false
local CollectDelay = 10
local Rebirth = false
local AutoHatchEggs = false

local WantedRarities = {
    Common = true
}


local MyPlot

for _, plot in ipairs(workspace.CoreObjects.Plots:GetChildren()) do
    local owner = plot:GetAttribute("Owner")

    if owner == player.Name or owner == player.UserId then
        MyPlot = plot
        break
    end
end

if MyPlot then
    print("Found my plot:", MyPlot.Name)
else
    warn("Could not find your plot!")
end


local Dropdown = MainTab:CreateDropdown({
    Name = "Wanted Rarity",
    Options = {
        "Common",
        "Uncommon",
        "Rare",
        "Epic",
        "Legendary",
        "Mythic",
        "Secret"
    },
    CurrentOption = {"Common"},
    MultipleOptions = true,
    Flag = "WantedRarity",
    Callback = function(Options)
        WantedRarities = {}

        for _, rarity in ipairs(Options) do
            WantedRarities[rarity] = true
        end

        print("Selected rarities:")
        for rarity in pairs(WantedRarities) do
            print("-", rarity)
        end
    end,
})

local Toggle = MainTab:CreateToggle({
    Name = "Auto Farm",
    CurrentValue = false,
    Flag = "AutoFarm",
    Callback = function(Value)
        AutoFarm = Value
    end,
})
task.spawn(function()
    local player = game.Players.LocalPlayer

    local targetPositions = {
        Vector3.new(109.80724334716797, 13.18349838256836, 157.54095458984375),
        Vector3.new(109.80724334716797, 13.036458969116211, 157.54095458984375),
        Vector3.new(109.80724334716797, 14.339973449707031, 157.54095458984375),
    }

    local radius = 2
    local buying = false

    while task.wait(0.1) do
        if not AutoFarm or buying then
            continue
        end

        local eggs = workspace.CoreObjects.Eggs:GetChildren()

        local foundEgg = nil
        local foundRarity = nil

        -- STEP 1: find valid egg first (NO ACTION YET)
        for _, egg in ipairs(eggs) do
            local pos = egg.WorldPivot.Position
            local atSpawn = false

            for _, targetPos in ipairs(targetPositions) do
                if (pos - targetPos).Magnitude <= radius then
                    atSpawn = true
                    break
                end
            end

            if atSpawn then
                local rarityLabel = egg:FindFirstChild("Rarity", true)

                if rarityLabel and rarityLabel:IsA("TextLabel") then
                    local rarity = rarityLabel.Text

                    if WantedRarities[rarity] then
                        foundEgg = egg
                        foundRarity = rarity
                        break
                    end
                end
            end
        end

        -- STEP 2: act ONCE
        if foundEgg then
            buying = true

            warn("Found:", foundEgg.Name, foundRarity)

            game:GetService("ReplicatedStorage")
                .Shared.Packages.Networker["RF/BuyEgg"]
                :InvokeServer(foundEgg.Name, 1)

            task.wait(0.25)

            game:GetService("ReplicatedStorage")
                .Shared.Packages.Networker["RF/RequestEggSpawn"]
                :InvokeServer()

            buying = false
        else
            -- STEP 3: only ONE request per cycle (not per egg)
            game:GetService("ReplicatedStorage")
                .Shared.Packages.Networker["RF/RequestEggSpawn"]
                :InvokeServer()
        end
    end
end)

local Slider = MainTab:CreateSlider({
   Name = "Collect Delay",
   Range = {5, 500},
   Increment = 5,
   Suffix = "sec",
   CurrentValue = 10,
   Flag = "CollectDelaySlider1", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   Callback = function(Value)
   CollectDelay = Value
   end,
})

local Toggle = MainTab:CreateToggle({
   Name = "Auto Collect Box",
   CurrentValue = false,
   Callback = function(Value)
    AutoSellBox = Value
   end,
})

task.spawn(function()
    while task.wait(CollectDelay) do
        if AutoSellBox then
            local Event = game:GetService("ReplicatedStorage").Shared.Packages.Networker["RE/PickupBoxes"]
            Event:FireServer()
        end
    end
end)

local Toggle = MainTab:CreateToggle({
   Name = "Auto Rebirth",
   CurrentValue = false,
   Flag = "AutoRebirthToggle1", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   Callback = function(Value)
    Rebirth = Value
   end,
})

task.spawn(function()
    while task.wait(1) do
        if Rebirth then
            local Event = game:GetService("ReplicatedStorage").Shared.Packages.Networker["RF/Rebirth"]
            Event:InvokeServer()
        end
    end
end)


local Toggle = MainTab:CreateToggle({
   Name = "Auto Hatch Eggs",
   CurrentValue = false,
   Flag = "AutoHatchEggsToggle1", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   Callback = function(Value)
    AutoHatchEggs = Value
   end,
})

task.spawn(function()
    while task.wait(0.5) do
        if AutoHatchEggs then
            for _, stand in ipairs(MyPlot.Stands:GetChildren()) do

                for _, obj in ipairs(stand:GetChildren()) do
                    if obj:IsA("Model") then

                        local timer = obj:FindFirstChild("Timer", true)

                        if timer and timer:IsA("TextLabel") and timer.Text == "READY!" then
                            warn("READY:", obj.Name)

                            local prompt = obj:FindFirstChild("HatchEgg", true)

                            if prompt and prompt:IsA("ProximityPrompt") then
                                fireproximityprompt(prompt)
                                warn("Prompt fired:", obj.Name)
                            else
                                warn("No ProximityPrompt found in:", obj.Name)
                            end
                        end
                    end
                end

            end
        end
    end
end)

