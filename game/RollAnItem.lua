local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Roll An Item",
    Icon = 0,
    LoadingTitle = "Roll An Item script",
    LoadingSubtitle = "by Datfeite",
    ShowText = "Roll An Item",
    Theme = "Default",

    ToggleUIKeybind = "K",

    DisableRayfieldPrompts = false,
    DisableBuildWarnings = false,

    ConfigurationSaving = {
        Enabled = false,
        FolderName = nil,
        FileName = "Big Hub"
    },

    Discord = {
        Enabled = false,
        Invite = "noinvitelink",
        RememberJoins = true
    },

    KeySystem = false,
    KeySettings = {
        Title = "Untitled",
        Subtitle = "Key System",
        Note = "No method of obtaining the key is provided",
        FileName = "Key",
        SaveKey = true,
        GrabKeyFromSite = false,
        Key = {"Hello"}
    }
})

local MainTab = Window:CreateTab("Main", 4483362458)
local DevTab = Window:CreateTab("Developer", 4483362458)

local AutoCollect = false
local Dices = {"\tBasicDice"}
local selectedDice = nil
local AutoBuyDices = false
local AutoOpenDice = false
local AutoEquipBest = false
local AutoSell = false

local Toggle = MainTab:CreateToggle({
   Name = "Auto Collect",
   CurrentValue = false,
   Flag = "AutoCollectToggle1", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   Callback = function(AutoCollectToggle)
    AutoCollect = AutoCollectToggle
   end,
})

task.spawn(function()
    while true do 
        if AutoCollect then 
            for i = 1, 10 do 
                local args = {
                    [1] = buffer.fromstring("-"),
                    [2] = buffer.fromstring("\254\001\000\006\aPodium"..i)
                }
                game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("Shared"):WaitForChild("Warp"):WaitForChild("Index"):WaitForChild("Event"):WaitForChild("Reliable"):FireServer(unpack(args))
                task.wait(0.1)
            end
        end
    task.wait(5)
    end
end
)

local Dropdown = MainTab:CreateDropdown({
   Name = "Auto buy Dices",
   Options = {    
    "\tBasicDice",
    "\bGoldDice",
    "\vDiamondDice",
    "\vEmeraldDice",
    "\fSapphireDice",
    "\vRainbowDice",
    "\vFlamingDice",
    "\014DarkMatterDice",
    "\vQuantumDice",
    "\rCelestialDice",
    "\015SingularityDice",
    "\fGlitchedDice",
    "\bOmniDice",
    "\fWormholeDice",
    "\tToxicDice",
    "\nFrozenDice",
    "\015RadioactiveDice",
    "\fBlizzardDice",
    "\vThunderDice",
    "\nPlasmaDice",
    "\tWaterDice",
    "\bLavaDice",
    "\nGalaxyDice",
    "\tAngelDice",
   },
   CurrentOption = {"\tBasicDice"},
   MultipleOptions = false,
   Flag = "DicesDropdown1", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   Callback = function(DicesDropdown1)
    selectedDice = DicesDropdown1[1]
    print("Selected Dice: "..selectedDice)
   end,
})

local Toggle = MainTab:CreateToggle({
   Name = "Auto buy Dices",
   CurrentValue = false,
   Flag = "AutobuyDicesToggle1", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   Callback = function(AutobuyDicesToggle1)
    AutoBuyDices = AutobuyDicesToggle1
   end,
})

task.spawn(function()
    while true do 
        if AutoBuyDices then 
            if selectedDice then 
                print("Attempting to buy:", selectedDice)
                local args = {
                    [1] = buffer.fromstring("\f"),
                    [2] = buffer.fromstring("\254\001\000\006"..selectedDice)
                }
                game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("Shared"):WaitForChild("Warp"):WaitForChild("Index"):WaitForChild("Event"):WaitForChild("Reliable"):FireServer(unpack(args))
            else
                warn("No dice selected for auto buying.")
            end
        end
    task.wait(0.5)
    end
end
)

local Toggle = MainTab:CreateToggle({
   Name = "Auto Open Selected Dice",
   CurrentValue = false,
   Flag = "AutoOpenSelectedDiceToggle1", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   Callback = function(AutoOpenSelectedDiceToggle1)
    AutoOpenDice = AutoOpenSelectedDiceToggle1
   end,
})

task.spawn(function()
    while true do 
        if AutoOpenDice then 
            if selectedDice then 
                local args = {
                    [1] = buffer.fromstring("6"),
                    [2] = buffer.fromstring("\254\001\000\006"..selectedDice)
                }
                game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("Shared"):WaitForChild("Warp"):WaitForChild("Index"):WaitForChild("Event"):WaitForChild("Reliable"):FireServer(unpack(args))
            else
                warn("No dice selected for auto opening.")
            end
        end
    task.wait(0.25)
    end
end
)

local Toggle = MainTab:CreateToggle({
   Name = "Auto Equip Best",
   CurrentValue = false,
   Flag = "AutoEquipBestToggle1", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   Callback = function(AutoEquipBestToggle1)
    AutoEquipBest = AutoEquipBestToggle1
   end,
})

task.spawn(function()
    while true do 
        if AutoEquipBest then 
           local args = {
                buffer.fromstring("&"),
                buffer.fromstring("\254\000\000")
            }
            game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("Shared"):WaitForChild("Warp"):WaitForChild("Index"):WaitForChild("Event"):WaitForChild("Reliable"):FireServer(unpack(args))
        end
    task.wait(5)
    end
end
)

local Toggle = DevTab:CreateToggle({
   Name = "Auto Sell",
   CurrentValue = false,
   Flag = "AutoSellToggle1", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   Callback = function(AutoSellToggle1)
    AutoSell = AutoSellToggle1
   end,
})

task.spawn(function()
    while true do 
        if AutoSell then 
            local args = {
                buffer.fromstring("&"),
                buffer.fromstring("\254\000\000")
            }
            game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("Shared"):WaitForChild("Warp"):WaitForChild("Index"):WaitForChild("Event"):WaitForChild("Reliable"):FireServer(unpack(args))
            task.wait(1)
            local args = {
                buffer.fromstring("+"),
                buffer.fromstring("\254\000\000")
            }
            game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("Shared"):WaitForChild("Warp"):WaitForChild("Index"):WaitForChild("Event"):WaitForChild("Reliable"):FireServer(unpack(args))
        end
    task.wait(5)
    end
end
)
