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
    Title = "Aura For Brainrots!",
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
    ShowSearch = true,
    ShowWindowControls = true,
    ConfigurationSaving = {
        Enabled = true,
        AutoSave = true,
    },
})


local Farmtab = window:CreateTab("Farm")
local Farmsection = Farmtab:CreateSection("Farm")
local Moneysection = Farmtab:CreateSection("Money")
local Teleportsection = Farmtab:CreateSection("Teleport")

local Plot = workspace:WaitForChild("Plot_" .. Player.Name)

-- Variables
local AutoFarm = false
local MultiAutoFarm = false
local SelectedStages = {"OG"}
local AutoMoney = false
local AutoMoneyDelay = 5
local MutationToCollect = {"Normal"}

local Items = game:GetService("ReplicatedStorage").Items:GetChildren()
local ItemNames = {}

for _, item in ipairs(Items) do
    table.insert(ItemNames, item.Name)
end

local StageOptions = {}
for _, spawner in ipairs(workspace.ItemSpawners:GetChildren()) do
    table.insert(StageOptions, spawner.Name)
end

local function isInTable(value, tbl)
    for _, v in ipairs(tbl) do
        if v == value then
            return true
        end
    end
    return false
end

-- UI
Farmsection:CreateParagraph({
    Title = "Tips",
    Content = "Multi Carrie not Active is recommended for stability!",
})

Farmsection:CreateDropdown({
    Name = "Which Stage to Auto Farm",
    Options = StageOptions,
    CurrentOption = {"OG"},
    MultipleOptions = true,
    Flag = "StageAutoFarm",
    Save = true,
    Callback = function(value)
        SelectedStages = value
    end,
})

Farmsection:CreateDropdown({
    Name = "Auto Farm Multi Carrie Active?",
    Options = {"Multi Carrie not Active", "MultiCarrie Active"},
    CurrentOption = {"Multi Carrie not Active"},
    MultipleOptions = false,
    Flag = "MultiCarrieMode",
    Save = true,
    Callback = function(value)
        MultiAutoFarm = (value[1] == "MultiCarrie Active")
    end,
})

Farmsection:CreateDropdown({
    Name = "Only Farm Brainrot with Mutation",
    Options = ItemNames,
    CurrentOption = {"Normal"},
    MultipleOptions = true,
    Flag = "MutationFilter",
    Save = true,
    Callback = function(value)
        MutationToCollect = value
    end,
})

Farmsection:CreateToggle({
    Name = "Auto Farm Brainrots",
    CurrentValue = false,
    Flag = "AutoFarmToggle",
    Save = true,
    Callback = function(value)
        AutoFarm = value
    end,
})

-- Auto Farm Loop
task.spawn(function()
    while task.wait(0.8) do
        if not AutoFarm then continue end

        for _, spawner in ipairs(workspace.ItemSpawners:GetChildren()) do
            if isInTable(spawner.Name, SelectedStages) then
                for _, spawnedItem in ipairs(spawner:GetChildren()) do
                    if spawnedItem.Name == "SpawnedItem" and spawnedItem:IsA("Model") then
                        local InfoUI = spawnedItem:FindFirstChildOfClass("BillboardGui")
                        if not InfoUI then continue end

                        local TextLabels = InfoUI:FindFirstChild("TextLabels")
                        if not TextLabels then continue end

                        local MutationLabel = TextLabels:FindFirstChild("Mutation")
                        if not MutationLabel then continue end

                        if isInTable(MutationLabel.ContentText, MutationToCollect) then
                            RootPart.CFrame = CFrame.new(spawnedItem.WorldPivot.Position + Vector3.new(0, 4, 0))

                            task.wait(0.35)

                            local Cube = spawnedItem:FindFirstChild("Cube.010") or spawnedItem:FindFirstChildOfClass("MeshPart")
                            local Prompt = Cube and Cube:FindFirstChildOfClass("ProximityPrompt")

                            if Prompt then
                                fireproximityprompt(Prompt)
                                task.wait(0.15)
                            end

                            if not MultiAutoFarm then
                                RootPart.CFrame = CFrame.new(Plot.WorldPivot.Position + Vector3.new(0, 4, 0))
                                task.wait(0.4)
                            end
                        end
                    end
                end
            end
        end

        if MultiAutoFarm then
            RootPart.CFrame = CFrame.new(Plot.WorldPivot.Position + Vector3.new(0, 4, 0))
            task.wait(0.7)
        end
    end
end)

-- Money Section
Moneysection:CreateSlider({
    Name = "Auto Collect Money Delay",
    Min = 1,
    Max = 60,
    CurrentValue = 5,
    Rounding = 1,
    Flag = "MoneyDelay",
    Save = true,
    Callback = function(value)
        AutoMoneyDelay = value
    end,
})

Moneysection:CreateToggle({
    Name = "Auto Collect Money",
    CurrentValue = false,
    Flag = "AutoMoneyToggle",
    Save = true,
    Callback = function(value)
        AutoMoney = value
    end,
})

task.spawn(function()
    while task.wait(AutoMoneyDelay) do
        if not AutoMoney then continue end

        for _, v in ipairs(Plot:GetChildren()) do
            if v:IsA("Model") and v.Name ~= "BaseUpgrade" then
                local folder = v:FindFirstChildOfClass("Folder")
                if not folder then continue end

                for _, padModel in ipairs(folder:GetChildren()) do
                    local UpgradePad = padModel:FindFirstChild("YourPadPart")
                    if not UpgradePad then continue end

                    local CollectPart = UpgradePad:FindFirstChild("CollectTouch")
                    if CollectPart then
                        firetouchinterest(RootPart, CollectPart, 0)
                        task.wait(0.08)
                        firetouchinterest(RootPart, CollectPart, 1)
                        task.wait(0.12)
                    end
                end
            end
        end
    end
end)

-- Teleport Section
Teleportsection:CreateDropdown({
    Name = "Teleport to Stage",
    Options = StageOptions,
    CurrentOption = {"OG"},
    MultipleOptions = false,
    Flag = "TeleportStage",
    Save = true,
    Callback = function(value)
        local spawner = workspace.ItemSpawners:FindFirstChild(value)

        if spawner and spawner:IsA("BasePart") then
            RootPart.CFrame = spawner.CFrame + Vector3.new(0, 3, 0)
        else
            warn("Spawner not found or not a Part:", value)
        end
    end,
})
