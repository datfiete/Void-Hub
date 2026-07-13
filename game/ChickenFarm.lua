local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local RootPart = Character:WaitForChild("HumanoidRootPart")
local Executor = getexecutorname()

local Avatar = Players:GetUserThumbnailAsync(
    Player.UserId,
    Enum.ThumbnailType.HeadShot,
    Enum.ThumbnailSize.Size150x150
)

local CyberUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/fietewoozle-dot/MyHub/main/CyberUI/load.lua"))()

CyberUI.Theme.Style = "Meng"

local window = CyberUI:CreateWindow({
    Title = "[UPD🥚] Chicken Farm 🐣",
    Subtitle = "by fietewoozle",
    BackgroundImage = "rbxassetid://106318186489675",

    Logo = "rbxassetid://128228297210141",
    Badges = {
        { Text = "Void Hub | v1.0" },
        { Text = "Executor: " .. Executor },
    },

    Footer = {
        Avatar = Avatar,
        Username = Player.Name,
    },


    ConfigurationSaving = {
        Enabled = true,
        AutoSave = true,
    },

    ShowSearch = true,
    ShowWindowControls = true,
    ToggleKey = Enum.KeyCode.RightControl,
})

local Farmtab = window:CreateTab("Farm")
local Farmsection = Farmtab:CreateSection("Auto Farm")

local Buttons = workspace.Plots[Player.Name].Buttons
local DepositPart= Buttons.DepositEggs.Hitbox
local CommectMoneyPart = Buttons.CollectMoney.Button
local MergePart = Buttons.MergeChickens.Button
local AutoUogradeMoneyPart = Buttons.UpgradeProcess

local BuyChicken = Buttons.BuyChickens
local BuyAmountOption = {}
local BuyAmountOptionSelected = "Buy1"
local AutoBuyEggs = false
local AutoBuyEggsDelay = 5

for i, v in pairs(BuyChicken:GetChildren()) do 
    table.insert(BuyAmountOption, v.Name)
end

local AutoConnectEggs = false
local AutoConnectEggsDelay = 5
local AutoDeposit = false
local AutoDepositDelay = 5
local AutoMerge = false
local AutoMergeDelay = 5
local AutoCollectMoney = false
local AutoCollectMoneyDelay = 5
local AutoUogradeMoney = false
local AutoUogradeMoneyDelay = 5

Farmsection:CreateSlider({
    Name = "Auto Collect Eggs Delay",
    Min = 1,
    Max = 100,
    CurrentValue = 5,
    Rounding = 1,
    Flag = "AutoCollectEggsDelay",
    Save = true,
    Callback = function(value)
        AutoConnectEggsDelay = value
    end,
})

Farmsection:CreateToggle({
    Name = "Auto Collect Eggs",
    CurrentValue = false,
    Flag = "MyFeature",
    Save = false,
    Callback = function(value)
        print("Toggle changed:", value)
        AutoConnectEggs = value
    end,
})

task.spawn(function ()
    while task.wait(AutoConnectEggsDelay) do 
        if AutoConnectEggs then 
            for i, v in pairs(workspace.Eggs:GetChildren()) do 
                local TouchPart = v:FindFirstChild("Part")
                if TouchPart then 
                    firetouchinterest(RootPart, TouchPart, 0)
                    task.wait(0.08)
                    firetouchinterest(RootPart, TouchPart, 1)
                end
            end
        end
    end
end)

Farmsection:CreateSlider({
    Name = "Auto Deposit Delay",
    Min = 1,
    Max = 100,
    CurrentValue = 5,
    Rounding = 1,
    Flag = "AutoDepositDelay",
    Save = true,
    Callback = function(value)
        AutoDepositDelay = value
    end,
})

Farmsection:CreateToggle({
    Name = "Auto Deposit",
    CurrentValue = false,
    Flag = "MyFeature",
    Save = false,
    Callback = function(value)
        print("Toggle changed:", value)
        AutoDeposit = value
    end,
})

task.spawn(function ()
    while task.wait(AutoDepositDelay) do 
        if AutoDeposit then 
            firetouchinterest(RootPart, DepositPart, 0)
            task.wait(0.08)
            firetouchinterest(RootPart, DepositPart, 1)
        end
    end
end)

Farmsection:CreateSlider({
    Name = "Auto Collect Money Delay",
    Min = 1,
    Max = 100,
    CurrentValue = 5,
    Rounding = 1,
    Flag = "AutoCollectMoneyDelay",
    Save = true,
    Callback = function(value)
        AutoMergeDelay = value
    end,
})

Farmsection:CreateToggle({
    Name = "Auto Collect Money",
    CurrentValue = false,
    Flag = "MyFeature",
    Save = false,
    Callback = function(value)
        print("Toggle changed:", value)
        AutoCollectMoney = value
    end,
})

task.spawn(function ()
    while task.wait(AutoMergeDelay) do 
        if AutoCollectMoney then 
            firetouchinterest(RootPart, CommectMoneyPart, 0)
            task.wait(0.08)
            firetouchinterest(RootPart, CommectMoneyPart, 1)
        end
    end
end)

Farmsection:CreateSlider({
    Name = "Auto Merge Delay",
    Min = 1,
    Max = 100,
    CurrentValue = 5,
    Rounding = 1,
    Flag = "AutoMergeDelay",
    Save = true,
    Callback = function(value)
        AutoCollectMoneyDelay = value
    end,
})

Farmsection:CreateToggle({
    Name = "Auto Merge",
    CurrentValue = false,
    Flag = "MyFeature",
    Save = false,
    Callback = function(value)
        print("Toggle changed:", value)
        AutoMerge = value
    end,
})

task.spawn(function ()
    while task.wait(AutoCollectMoneyDelay) do 
        if AutoMerge then 
            firetouchinterest(RootPart, MergePart, 0)
            task.wait(0.08)
            firetouchinterest(RootPart, MergePart, 1)
        end
    end
end)

Farmsection:CreateDropdown({
    Name = "Auto Buy Eggs amount",
    Options = BuyAmountOption,
    CurrentOption = "Buy1",
    MultipleOptions = false,
    Flag = "AutoBuyEggsamount",
    Save = true,
    Callback = function(value)
        print("Selected To Buy:", value)
        BuyAmountOptionSelected = value
    end,
})

Farmsection:CreateSlider({
    Name = "Auto Buy Eggs Delay",
    Min = 1,
    Max = 100,
    CurrentValue = 5,
    Rounding = 1,
    Flag = "AutoBuyEggsDelay",
    Save = true,
    Callback = function(value)
        AutoBuyEggsDelay = value
    end,
})

Farmsection:CreateToggle({
    Name = "Auto Buy Eggs(Teleport)",
    CurrentValue = false,
    Flag = "MyFeature",
    Save = false,
    Callback = function(value)
        print("Toggle changed:", value)
        AutoBuyEggs = value
    end,
})

task.spawn(function ()
    while task.wait(AutoBuyEggsDelay) do 
        if AutoBuyEggs then 
            Character:MoveTo(BuyChicken[BuyAmountOptionSelected].WorldPivot.Position + Vector3.new(0, 3, 0))
        end
    end
end)

Farmsection:CreateSlider({
    Name = "Auto Upgrade Money Deposit Delay",
    Min = 1,
    Max = 100,
    CurrentValue = 5,
    Rounding = 1,
    Flag = "AutoUpgradeMoneyDepositDelay",
    Save = true,
    Callback = function(value)
        AutoUogradeMoneyDelay = value
    end,
})

Farmsection:CreateToggle({
    Name = "Auto Upgrade Money Deposit",
    CurrentValue = false,
    Flag = "MyFeature",
    Save = false,
    Callback = function(value)
        print("Toggle changed:", value)
        AutoUogradeMoney = value
    end,
})

task.spawn(function ()
    while task.wait(AutoUogradeMoneyDelay) do 
        if AutoUogradeMoney then 
            Character:MoveTo(AutoUogradeMoneyPart.WorldPivot.Position + Vector3.new(0, 3, 0))
        end
    end
end)