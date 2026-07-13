local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local Executor = getexecutorname()

local Avatar = Players:GetUserThumbnailAsync(
    Player.UserId,
    Enum.ThumbnailType.HeadShot,
    Enum.ThumbnailSize.Size150x150
)

local CyberUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/datfiete/Void-Hub/main/CyberUI/load.lua"))()

CyberUI.Theme.Style = "Meng"

local window = CyberUI:CreateWindow({
    Title = "Sell Lemons",
    Subtitle = "by fietewoozle",

    Logo = "rbxassetid://128228297210141",
    Badges = {
        { Text = "Void Hub | v1.0" },
        { Text = "Executor: " .. Executor },
    },

    Footer = {
        Avatar = Avatar,
        Username = Player.Name,
    },

    ShowSearch = true,
    ShowWindowControls = true,
})

local YouTycoon = nil

for _, tycoon in ipairs(workspace:GetChildren()) do
    local owner = tycoon:FindFirstChild("Owner", true)

    if owner then
        if owner:IsA("ObjectValue") and owner.Value == Player then
            YouTycoon = tycoon
            break
        elseif owner:IsA("StringValue") and owner.Value == Player.Name then
            YouTycoon = tycoon
            break
        end
    end
end

if YouTycoon then
    print("Your Tycoon is:", YouTycoon.Name)
else
    warn("No Tycoon found!")
end

if not YouTycoon then
    warn("No Tycoon found!")
    return
end

local Farmtab = window:CreateTab("Farm")
local AutoFarmsection = Farmtab:CreateSection("AutoFarm")

local Character = Player.Character or Player.CharacterAdded:Wait()
local RootPart = Character:WaitForChild("HumanoidRootPart")

local AutoBuyButtons = false
local categories = {"Multiplier", "Other", "Structure", "Decor"}
local AutoUpgrade = false
local AutocollectLemonstrees = false

local Purchases = YouTycoon:FindFirstChild("Purchases")

if not Purchases then
    warn("Purchases nicht gefunden in:", YouTycoon.Name)
    return
end

local UpgradeDelay = 0.1

local UpgradeEvents = {
    ["Lemon Dash"] = Purchases.LemonDash.LemonDash.LemonDash.Upgrade,
    ["Lemon Stand"] = Purchases["Lemon Stand"]["Lemon Stand"]["Lemon Stand"].Upgrade,
    ["Lemon Depot"] = Purchases["Lemon Depot"]["Lemon Depot"]["Lemon Depot"].Upgrade,
}

local SelectedUpgrades = {"Lemon Stand"}

AutoFarmsection:CreateToggle({
    Name = "Auto Buy Buttons",
    CurrentValue = false,
    Flag = "MyFeature",
    Save = false,
    Callback = function(value)
        print("Toggle changed:", value)
        AutoBuyButtons = value
    end,
})

task.spawn(function ()
    while task.wait(1) do 
        if AutoBuyButtons then 
            for _, w in ipairs(Purchases:GetChildren()) do
                local buttons = w:FindFirstChild("Buttons")

                if buttons then
                    for _, category in ipairs(categories) do
                        local folder = buttons:FindFirstChild(category)

                        if folder then
                            for _, v in ipairs(folder:GetChildren()) do
                                local button = v:FindFirstChild("Button")

                                if button
                                    and v:GetAttribute("Enabled")
                                    and not v:GetAttribute("Purchased") then


                                    if button:FindFirstChildOfClass("TouchTransmitter") then
                                        firetouchinterest(RootPart, button, 0)
                                        task.wait(0.05)
                                        firetouchinterest(RootPart, button, 1)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)

AutoFarmsection:CreateDropdown({
    Name = "Auto Upgrade Options",
    Options = {"Lemon Dash", "Lemon Stand", "Lemon Depot"},
    CurrentOption = "Lemon Stand",
    MultipleOptions = true,
    Flag = "GameMode",
    Save = true,
    Callback = function(value)
        print("Selected mode:", value)
        SelectedUpgrades = value
    end,
})

AutoFarmsection:CreateSlider({
    Name = "Auto Upgrade Delay",
    Min = 0.01,
    Max = 5,
    CurrentValue = 0.1,
    Rounding = 0.01,
    Flag = "SpeedValue",
    Save = true,
    Callback = function(value)
        UpgradeDelay = value
    end,
})

AutoFarmsection:CreateToggle({
    Name = "Auto Upgrade",
    CurrentValue = false,
    Flag = "MyFeature",
    Save = false,
    Callback = function(value)
        print("Toggle changed:", value)
        AutoUpgrade = value
    end,
})

task.spawn(function()
    while task.wait(UpgradeDelay) do
        if AutoUpgrade then
            for _, upgradeName in ipairs(SelectedUpgrades) do
                local Event = UpgradeEvents[upgradeName]

                if Event then
                    Event:InvokeServer(1)
                    print("Upgraded:", upgradeName)
                end
            end
        end
    end
end)

AutoFarmsection:CreateToggle({
    Name = "Auto Collect Lemons from trees",
    CurrentValue = false,
    Flag = "MyFeature",
    Save = false,
    Callback = function(value)
        print("Toggle changed:", value)
        AutocollectLemonstrees = value
    end,
})

task.spawn(function ()
    while task.wait(0.5) do 
        if AutocollectLemonstrees then 
            for _, obj in ipairs(workspace.Tycoon6.Constant.Trees:GetDescendants()) do
                if obj:IsA("ClickDetector") then
                    local part = obj.Parent

                    Character:MoveTo(part.Position + Vector3.new(0, 3, 0))

                    task.wait(0.2)
                    fireclickdetector(obj)
                end
            end
        end
    end
end)
