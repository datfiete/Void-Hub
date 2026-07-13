local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Spin an Anime",
   Icon = 0, -- Icon in Topbar. Can use Lucide Icons (string) or Roblox Image (number). 0 to use no icon (default).
   LoadingTitle = "Spin an Anime script",
   LoadingSubtitle = "by Datfeite",
   ShowText = "Spin an Anime", -- for mobile users to unhide Rayfield, change if you'd like
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

local Block = {"CommonBlock"}
local BuyBlock = false
local SpinBlock = false
local AutoopenBlock = false
local EquippedDice = game:GetService("Players").LocalPlayer.PlayerGui.Main.DiceContainer.Selected.Button.DiceName.ContentText
local AutoMoney = false
local AutoUpgrade = false
local WhichAutoUpgrade = {"Playerluck"}
local OldAutoUpgrade = nil
local NewAutoUpgrade = nil
local Rebirth = false
local OldAutoRebirth = nil
local NewAutoRebirth = nil
local AutoEgg = false
local AutoEggSelect = {"Basic"}
local AutoIndex = false
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Function to get block options from AutoBuyBlockPurchases children
local function GetBlockOptions()
    local options = {}
    local autoBuyFolder = LocalPlayer:FindFirstChild("AutoBuyBlockPurchases")
    if autoBuyFolder then
        for _, child in ipairs(autoBuyFolder:GetChildren()) do
            table.insert(options, child.Name)
        end
    end
    return options
end

local blockOptions = GetBlockOptions()

local function removeSpaces(str)
    return str:gsub("%s+", "")  -- removes all whitespace (spaces, tabs, newlines)
end

local function getEquippedDice()
    local player = game:GetService("Players").LocalPlayer
    local content = player.PlayerGui.Main.DiceContainer.Selected.Button.DiceName.ContentText
    return content
end

local Paragraph = MainTab:CreateParagraph({Title = "Your Data", Content = "Loading..."})

task.spawn(function()
    while true do
        local stats = game:GetService("Players").LocalPlayer.Stats

        local content = table.concat({
            "Money: " .. stats.Coins.Value,
            "Rebirths: " .. stats.Rebirths.Value,
            "Diamonds: " .. stats.Diamonds.Value
        }, "\n")

        Paragraph:Set({
            Title = "Your Data",
            Content = content
        })

        task.wait(0.5)
    end
end)


local Button = DevTab:CreateButton({
   Name = "Equipped Dice",
   Callback = function()
    print(EquippedDice)
   end,
})

local Dropdown = MainTab:CreateDropdown({
    Name = "Auto Buy Block",
    Options = blockOptions,
    CurrentOption = {blockOptions[1] or ""},
    MultipleOptions = false,
    Flag = "BuyBlockDropdown",
    Callback = function(BayBlock)
        Block = BayBlock[1]
        if BayBlock then
            print("Set Autobuy Block to:", BayBlock[1])
        end
    end,
})

local Toggle = MainTab:CreateToggle({
   Name = "Auto Buy Block",
   CurrentValue = false,
   Flag = "BuyBlockToggle", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   Callback = function(ByBlock)
    BuyBlock = ByBlock 
    if ByBlock then 
        print("Auto buying enabled for:", Block)
    else 
        print("Auto buying Disabled")
    end
   end,
})

task.spawn(function()
    while true do
        if BuyBlock then 
            local args = {
	        Block
            }
            game:GetService("ReplicatedStorage"):WaitForChild("Network"):WaitForChild("Client"):WaitForChild("PurchaseItem"):InvokeServer(unpack(args))
            print("bought:", Block)
        end
    task.wait(0.1)
    end
end
)

local Toggle = MainTab:CreateToggle({
   Name = "Auto open EQUIPPED Block",
   CurrentValue = false,
   Flag = "AutoopenBlocks", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   Callback = function(auopbl)
    AutoopenBlock = auopbl
    if auopbl then 
        print("Auto openeing Blocks Enabled")
    else 
        print("Auto openeing Blocks Disabled")
    end
   end,
})

task.spawn(function()
    while true do
        if AutoopenBlock then
            local diceName = removeSpaces(getEquippedDice())

            if diceName and diceName ~= "" then
                game:GetService("ReplicatedStorage")
                    :WaitForChild("Network")
                    :WaitForChild("Client")
                    :WaitForChild("RollBlock")
                    :InvokeServer(diceName)

                print("rolled:", diceName)
            end
        end

        task.wait(0.5)
    end
end)

local Toggle = MainTab:CreateToggle({
   Name = "Auto Money",
   CurrentValue = false,
   Flag = "Moneymoneymoney", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   Callback = function(Aumon)
    AutoMoney = Aumon
    if Aumon then 
        print("Collect Money ON")
    else 
        print("Collect Money OFF")
    end
   end,
})

task.spawn(function()
    while true do
        if AutoMoney then
            game:GetService("ReplicatedStorage"):WaitForChild("Network"):WaitForChild("Client"):WaitForChild("EquipBestEntities"):InvokeServer()
        end
    task.wait(10)
    end
end
)


local Dropdown = MainTab:CreateDropdown({
   Name = "Upgrade",
   Options = {"PlayerLuck", "GlobalIncome"},
   CurrentOption = {"PlayerLuck"},
   MultipleOptions = false,
   Flag = "UpgradeDropdown", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   Callback = function(Upgdr)
    WhichAutoUpgrade = Upgdr[1]
    if Upgdr then 
        print("set Upgrade to:", Upgdr[1])
    end
   end,
})


local Toggle = MainTab:CreateToggle({
   Name = "Upgrade",
   CurrentValue = false,
   Flag = "UpgradeToggle", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   Callback = function(Upgtg)
    AutoUpgrade = Upgtg
    if Upgtg then 
        print("Auto Upgrade active on:", WhichAutoUpgrade[1])
    else 
        print("Auto Upgrade Deactivated")
    end
   end,
})

task.spawn(function()
    while true do 
        if AutoUpgrade then
        OldAutoUpgrade = game:GetService("Players").LocalPlayer.Stats.Coins.Value
            if OldAutoUpgrade == NewAutoUpgrade then 
                print("Not Enough Money!")
            else 
                local args = {
	            WhichAutoUpgrade
                }
                game:GetService("ReplicatedStorage"):WaitForChild("Network"):WaitForChild("Client"):WaitForChild("PurchaseUpgrade"):InvokeServer(unpack(args))
                print("Upgraded", WhichAutoUpgrade)
                NewAutoUpgrade = game:GetService("Players").LocalPlayer.Stats.Coins.Value
            end
        end
    task.wait(0.5)
    end
end
)

local Toggle = MainTab:CreateToggle({
   Name = "Auto Rebirth",
   CurrentValue = false,
   Flag = "RebirthToggle", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   Callback = function(Rebte)
    Rebirth = Rebte
    if Rebte then 
        print("Activeted Auto Rebirth")
    else 
        print("Deactiveted Auto Rebirth")
    end
   end,
})

task.spawn(function()
    while true do 
        if Rebirth then 
            OldAutoRebirth = game:GetService("Players").LocalPlayer.Stats.Rebirths.Value
            game:GetService("ReplicatedStorage"):WaitForChild("Network"):WaitForChild("Client"):WaitForChild("Rebirth"):InvokeServer()
            task.wait(0.5)
            NewAutoRebirth = game:GetService("Players").LocalPlayer.Stats.Rebirths.Value 
            if OldAutoRebirth == NewAutoRebirth then 
                print("Failed to Rebirth!")
            else 
                print("Rebirthed to Rebirth:", NewAutoRebirth)
            end
        end
    task.wait(10)
    end
end
)

local Dropdown = MainTab:CreateDropdown({
   Name = "Auto Egg",
   Options = {"Basic", "Coconut", "Crocodile", "Yeti", "Cupcake", "GoldenBasic"},
   CurrentOption = {"Basic"},
   MultipleOptions = false,
   Flag = "AutoEggDropdown", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   Callback = function(AutegDd)
    AutoEggDropdown = AutegDd[1] 
    if AutegDd then 
        print("Changed Auto egg to:", AutegDd[1])
    end
   end,
})

local Toggle = MainTab:CreateToggle({
   Name = "Auto Egg",
   CurrentValue = false,
   Flag = "AutoEggToggle", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   Callback = function(Auteg)
    AutoEgg = Auteg 
    if Auteg then 
        print("Auto Egg Active on:", AutoEggDropdown)

    end
   end,
})

task.spawn(function()
    while true do 
        if AutoEgg then 
            local args = {
	        AutoEggDropdown,
	        1
            }
            game:GetService("ReplicatedStorage"):WaitForChild("Network"):WaitForChild("Client"):WaitForChild("Hatch"):InvokeServer(unpack(args))
            print("opened:", AutoEggDropdown)
        end
    task.wait(5)
    end
end
)

local Toggle = MainTab:CreateToggle({
   Name = "Auto Claim Index",
   CurrentValue = false,
   Flag = "AutoIndexToggle", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   Callback = function(AutIx)
    AutoIndex = AutIx 
    if AutIx then 
        print("Auto Claim Index")
    end
   end,
})

task.spawn(function()
    while true do 
        if AutoIndex then 
            game:GetService("ReplicatedStorage"):WaitForChild("Network"):WaitForChild("Client"):WaitForChild("ClaimAllIndexRewards"):FireServer()
            print("Claimed Index")
        end
    task.wait(15)
    end
end
)
