local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local VIM = game:GetService("VirtualInputManager")

local Executor = "unknown"
pcall(function()
    if type(getexecutorname) == "function" then
        Executor = tostring(getexecutorname())
    elseif type(identifyexecutor) == "function" then
        Executor = tostring(identifyexecutor())
    end
end)

local Vaxorin = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/datfiete/Void-Hub/refs/heads/main/CyberUI%20-%20Kopie/load.lua"
))()

pcall(function()
    if Vaxorin.Theme then
        Vaxorin.Theme.Style = "Vaxorin"
    end
end)

local avatar = ""
pcall(function()
    avatar = Players:GetUserThumbnailAsync(
        LocalPlayer.UserId,
        Enum.ThumbnailType.HeadShot,
        Enum.ThumbnailSize.Size150x150
    )
end)

local window = Vaxorin:CreateWindow({
    Title = "[☢️] Build a Reactor",
    Subtitle = "by Fietewoozle",
    Logo = "rbxassetid://135320038058277",

    Badges = {
        { Text = "Vaxorin | v1.0" },
        { Text = "Executor : " .. Executor },
    },

    Footer = {
        Avatar = avatar,
        Username = LocalPlayer.Name,
        Status = "Ready",
    },

    DiscordLink = "https://discord.gg/nTHbCmDYWd",
    ShowSearch = true,
    ShowWindowControls = true,
    ToggleKey = Enum.KeyCode.RightControl,
    TopMost = true,

    Layout = "Vaxorin", -- optional: Classic, Minecraft, Orbit, Aether, Nova, Vortex, Prism, Eclipse, Zenith

    ConfigurationSaving = {
        Enabled = true,
        AutoSave = true,
        FolderName = "Vaxorin",
        FileName = "Build a Reactor",
    },
})

window:SetProfileStatus("Ready")
window:SetWatermarkEnabled(true)

local FarmTab = window:CreateTab("Main")
local Farmsection = FarmTab:CreateSection({
    Name = "Main",
    Description = "General settings.",
})

local UserID = game.Players.LocalPlayer.UserId
local Plots = workspace.Plots
local UserPlot = nil
local CurrentPriceText = game:GetService("Players").LocalPlayer.PlayerGui.Menus.SellEnergy.MainFrame.CurrentPriceLabel.ContentText
local Price = nil
local OwnedReactorCells = tonumber(LocalPlayer.PlayerGui.HUD.EnergyCellLabel.TextLabel.ContentText)

local function CheckcurrentCellsAmount()
    local label = game:GetService("Players").LocalPlayer
        .PlayerGui.Menus.SellEnergy.MainFrame.CurrentPriceLabel

    OwnedReactorCells = tonumber(label.ContentText:match("%$(%d+)"))
end

for i, v in pairs(Plots:GetChildren()) do
    if v:GetAttribute("owner_id") == UserID then
        UserPlot = v
        print("Found user plot: " .. v.Name)
        break
    end
end

local UserComponents = UserPlot:FindFirstChild("Components")
local Slot1 = UserPlot.Components.RollDrill.Slot1
local Leverprompt = UserPlot.Components.RollDrill.SpinModel.Lever.Ball._rollPrompt.ProximityPrompt
local ReactorTouchInterest = UserPlot.Components.Reactor._collectPad.RootPart
local ReactorSellButton = LocalPlayer.PlayerGui.Menus.SellEnergy.MainFrame.SellButton

local function GetDrill()
    for i, v in pairs(Slot1:GetChildren()) do
        if v.Name ~= "Part" and v.Name ~= "RootPart" then 
            print("Found drill: " .. v.Name)
            return v
        end
    end
end

local function findproximiotyprompot()
    local Proxi = Slot1.RootPart:FindFirstChild("_buyPrompt")
    if Proxi then
        local ProximityPromt = Proxi:FindFirstChildOfClass("ProximityPrompt")
        return ProximityPromt
    end
end

local BuyRarity = {"Exclusive"}
local AutoBuyDrill = false
local AutoCollectDrillRewards = false
local AutoCollectReactor = false
local AutoSellReactor = false
local SellEnergyPrice = 10

Farmsection:CreateButton({
    Name = "Find drill On Tab Drill",
    Callback = function()
        GetDrill()
    end,
})

Farmsection:CreateDropdown({
    Name = "Buy Rarity",
    Options = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret", "Exclusive" },
    CurrentOption = "Exclusive",
    MultipleOptions = true,
    Flag = "BuyRarity.Mode",
    Save = true,
    Callback = function(value)
        BuyRarity = value
    end,
})

Farmsection:CreateToggle({
    Name = "Auto Buy Drill",
    CurrentValue = false,
    Flag = "AutoBuyDrill.Enabled",
    Save = true,
    Callback = function(value)
        AutoBuyDrill = value
        task.spawn(function()
            while AutoBuyDrill do
                local drill1 = GetDrill()
                task.wait(1)
                local drill2 = GetDrill()
                if drill1 ~= drill2 then 
                    print("Drill changed, waiting for next check...")
                elseif drill1 == drill2 then
                    if drill1 then
                        local Prompt = findproximiotyprompot()
                        if Prompt then
                            local rarity = drill1:GetAttribute("Rarity")
                            if table.find(BuyRarity, rarity) then
                                print("Buying drill: " .. drill1.Name .. " with rarity: " .. rarity)
                                fireproximityprompt(Prompt, 0)
                            else
                                fireproximityprompt(Leverprompt, 0)
                            end
                        end
                    else
                        fireproximityprompt(Leverprompt, 0)
                    end
                    task.wait(2) -- Wait for 2 seconds before checking again
                end
            end
        end)
    end,
})

Farmsection:CreateToggle({
    Name = "Auto collect Drill Rewards",
    CurrentValue = false,
    Flag = "AutocollectDrillRewards.Enabled",
    Save = true,
    Callback = function(value)
        AutoCollectDrillRewards = value
        task.spawn(function()
            while AutoCollectDrillRewards do
                for i, v in pairs(UserComponents:GetChildren()) do
                    if v.Name =="DrillSlot" then 
                        if v:GetAttribute("slot_state") == "Occupied" then 
                            local TouchIntrest = v:FindFirstChild("TouchInterest", true)
                            local TouchPart = TouchIntrest.Parent
                            if TouchIntrest then
                                firetouchinterest(LocalPlayer.Character.HumanoidRootPart, TouchPart, 0)
                                task.wait(0.1)
                                firetouchinterest(LocalPlayer.Character.HumanoidRootPart, TouchPart, 1)
                            end
                        end
                    end
                end
                task.wait(1)
            end
        end)
    end,
})

Farmsection:CreateToggle({
    Name = "Auto Collect Energy",
    CurrentValue = false,
    Flag = "AutoCollectEnergy.Enabled",
    Save = true,
    Callback = function(value)
        AutoCollectReactor = value
        task.spawn(function()
            while AutoCollectReactor do 
                if ReactorTouchInterest then 
                    firetouchinterest(LocalPlayer.Character.HumanoidRootPart, ReactorTouchInterest, 0)
                    task.wait(0.1)
                    firetouchinterest(LocalPlayer.Character.HumanoidRootPart, ReactorTouchInterest, 1)
                end
                task.wait(10)
            end
        end
        )
    end,
})

local priceParagraph = Farmsection:CreateParagraph({
	Title = "Current Energy sell Price",
	Content = tostring(Price),
})

local function CheckcurrentPrice()
    CurrentPriceText = game:GetService("Players").LocalPlayer.PlayerGui.Menus.SellEnergy.MainFrame.CurrentPriceLabel.ContentText
    if CurrentPriceText then 
        Price = tonumber(CurrentPriceText:match("%d+"))
        priceParagraph:Set(tostring(Price))
    end
end

task.spawn(function()
    CheckcurrentPrice()
    task.wait(20)
end)

Farmsection:CreateSlider({
    Name = "Auto Sell Energy",
    Min = 1,
    Max = 20,
    CurrentValue = 10,
    Rounding = 1,
    Flag = "AutoSellEnergy.Speed",
    Save = true,
    Callback = function(value)
        SellEnergyPrice = value
    end,
})

Farmsection:CreateToggle({
    Name = "Auto Sell Energy",
    CurrentValue = false,
    Flag = "Feature.Enabled",
    Save = true,
    Callback = function(value)
        AutoSellReactor = value
        task.spawn(function()
            while AutoSellReactor do
                CheckcurrentPrice()
                CheckcurrentCellsAmount()
                if OwnedReactorCells > 0 then 
                    if Price >= SellEnergyPrice then
                        firesignal(ReactorSellButton.Activated)
                    end
                    task.wait(1)
                end
                task.wait(1)
            end
        end)
    end,
})
