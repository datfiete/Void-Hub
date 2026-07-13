local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Fall sown a hole for Brainrots",
    Icon = 0,
    LoadingTitle = "Fall sown a hole for Brainrots script",
    LoadingSubtitle = "by Datfeite",
    ShowText = "Fall sown a hole for Brainrots",
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
local FarmTab = Window:CreateTab("Farm", 4483362458)
local DevTab = Window:CreateTab("Developer", 4483362458)

local autoDrop = false
local AutoMoney = false

local Toggle = MainTab:CreateToggle({
   Name = "Auto Drop",
   CurrentValue = false,
   Flag = "autoDropToggle1", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   Callback = function(autoDropToggle1)
    autoDrop = autoDropToggle1
   end,
})

task.spawn(function()
    while true do 
        if autoDrop then
            local Event = game:GetService("ReplicatedStorage").Utility.Network["Drop/RequestDrop"]
        Event:InvokeServer()
        task.wait(2)
        local Event = game:GetService("ReplicatedStorage").Utility.Network["Drop/RollLoot"]
        Event:InvokeServer(
            99999.999,
            22,
            0.999,
            4000.999
        )
        task.wait(1)
        local Event = game:GetService("ReplicatedStorage").Utility.Network["Drop/ClaimBrainrot"]
        Event:InvokeServer()
        print("done")
        end
    task.wait(1)
    end
end)

local Toggle = MainTab:CreateToggle({
   Name = "Auto Collect Money/Auto Place Best",
   CurrentValue = false,
   Flag = "AutoCollectMoney/AutoPlaceBestToggle1", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   Callback = function(AutoCollectMoneyAutoPlaceBestToggle1)
    AutoMoney = AutoCollectMoneyAutoPlaceBestToggle1
   end,
})

task.spawn(function()
    while true do 
        if AutoMoney then 
            local Event = game:GetService("ReplicatedStorage").Utility.Network["PlacementService/EquipBest"]
            Event:InvokeServer()
        end
    task.wait(10)
    end
end
)
