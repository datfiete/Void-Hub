local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Crab Tycoon",
    Icon = 0,
    LoadingTitle = "Crab Tycoon script",
    LoadingSubtitle = "by Datfeite",
    ShowText = "Crab Tycoon",
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

local BuyCrab = false 
local AmountBuyCrab = 1
local AutoMergeCrab = false
local CollcectShellMany = 1
local CollectShell = false
local DepositShell = false 
local CollectMoney = false 

local Dropdown = MainTab:CreateDropdown({
    Name = "Anzahl",
    Options = {"1", "5", "25", "100"},
    CurrentOption = {"1"},
    Callback = function(Option)
        local Value = Option

        if typeof(Option) == "table" then
            Value = Option[1]
        end

        local Zahl = tonumber(Value)

        if Zahl then
            AmountBuyCrab = Zahl
            print("AmountBuyCrab:", AmountBuyCrab)
            print(typeof(AmountBuyCrab))
        else
            warn("Konnte nicht in eine Zahl umwandeln:", Value)
        end
    end
})


local Toggle = MainTab:CreateToggle({
   Name = "Auto Buy Crab",
   CurrentValue = false,
   Flag = "AutoBuyCrabToggle1",
   Callback = function(AutoBuyCrabToggle1)
    BuyCrab = AutoBuyCrabToggle1
   end,
})

task.spawn(function ()
    while true do 
        if BuyCrab then 
            local Event = game:GetService("ReplicatedStorage").Remotes.BuyCrab
            Event:FireServer(
                AmountBuyCrab
            )
        end
    task.wait(1)
    end
end)

local Toggle = MainTab:CreateToggle({
   Name = "Auto Merge Crab(Have to deactivate Auto Buy Crab to Work!)",
   CurrentValue = false,
   Flag = "AutoMergeCrabToggle1", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   Callback = function(AutoMergeCrabToggle1)
    AutoMergeCrab = AutoMergeCrabToggle1
   end,
})

task.spawn(function ()
    while true do 
        if AutoMergeCrab then 
            local Event = game:GetService("ReplicatedStorage").Remotes.MergeCrab
            Event:FireServer()
        end
    task.wait(1)
    end
end)

local Slider = MainTab:CreateInput({
    Name = "Give Shells",
    PlaceholderText = "Input Number",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        local Zahl = tonumber(Text)

        if Zahl then
            print("Gültige Zahl:", Zahl)
            CollcectShellMany = Zahl -- nicht Text!
        else
            warn("Bitte nur Zahlen eingeben!")
        end
    end
})

local Button = MainTab:CreateButton({
   Name = "Collect Shells from Input(Glitches sometimes and gives wrong amount of Shells)",
   Callback = function()
    local Event = game:GetService("ReplicatedStorage").Remotes.CollectShells
    Event:FireServer(
        CollcectShellMany
    )
   end,
})

local Toggle = MainTab:CreateToggle({
   Name = "Auto Deposit Shells",
   CurrentValue = false,
   Flag = "Toggle1", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   Callback = function(AutoDepositShells)
    DepositShell = AutoDepositShells
   end,
})

task.spawn(function()
    while true do 
        if DepositShell then 
            local Event = game:GetService("ReplicatedStorage").Remotes.DepositShells
            Event:FireServer()
        end
    task.wait(5)
    end
end)

local Toggle = MainTab:CreateToggle({
   Name = "Collect Deposited Money",
   CurrentValue = false,
   Flag = "Toggle1",
   Callback = function(Value)
    CollectMoney = Value
   end,
})

task.spawn(function ()
    while true do 
        if CollectMoney then 
            local Event = game:GetService("ReplicatedStorage").Remotes.CollectCash
            Event:FireServer()
        end
    task.wait(5)
    end
end)
