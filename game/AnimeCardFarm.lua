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
    Title = "[UPD🃏] Anime Card Farm",
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
})

local Farmtab = window:CreateTab("Main")
local Farmsection = Farmtab:CreateSection("Main Section")

local PlotNumber = tostring(game:GetService("Players").LocalPlayer.PlotNumber.Value)
print(PlotNumber)
local ProxiBoxlocation = workspace.MAP.Plots[PlotNumber].Plot_N0.BoxBaseModel.ProxiBox
local ProxiBoxen = workspace.MAP.Plots[PlotNumber].Plot_N0.BoxBaseModel.ProxiBox.ProximityPrompt
local ProxiSellBoxen = workspace.MAP.Plots[PlotNumber].Plot_N0.SellPart.ProximityPrompt
local TeleSellBox = workspace.MAP.Plots[PlotNumber].Plot_N0.AntonySAMAA

local AutoOpen = false
local AutoRoll = false
local AutoSellBox = false
local SellDelay = 10

local Packs = {}

for _, pack in ipairs(game:GetService("ReplicatedStorage").Models.PackImage:GetChildren()) do
    table.insert(Packs, pack.Name)
end

local SelectedPack = {"Ice Pack"}

local function isInTable(value, tbl)
    for _, v in ipairs(tbl) do
        if v == value then
            return true
        end
    end
    return false
end

Farmsection:CreateDropdown({
    Name = "Buy Pack on Convey",
    Options = Packs,
    CurrentOption = "Ice Pack",
    MultipleOptions = true,
    Flag = "GameMode",
    Save = true,
    Callback = function(value)
        print("Selected Buy Pack on Convey:", value)
        SelectedPack = value
    end,
})

Farmsection:CreateToggle({
    Name = "Auto Spin Convey",
    CurrentValue = false,
    Flag = "MyFeature",
    Save = false,
    Callback = function(value)
        print("Auto Spin Convey changed:", value)
        AutoRoll = value
    end,
})

local ConveySpawn = workspace.MAP.Plots[PlotNumber].Plot_N0.ButtonPart.ClickDetector

task.spawn(function()
    while task.wait(0.5) do
        if AutoRoll and SelectedPack then
            for _, v in pairs(workspace.MAP.Plots[PlotNumber].Plot_N0.LocalConveyorModels:GetChildren()) do
                if isInTable(v.Name, SelectedPack) then
                    local Main = v:FindFirstChild("Main")
                    local Prompt = Main and Main:FindFirstChildOfClass("ProximityPrompt")

                    if Main and Prompt then
                        fireproximityprompt(Prompt)
                        task.wait(0.5)
                        fireclickdetector(ConveySpawn)
                        task.wait(0.5)
                    end
                else
                    fireclickdetector(ConveySpawn)
                    task.wait(0.5)
                end
            end
        end
    end
end)

Farmsection:CreateToggle({
    Name = "Auto Open Packs",
    CurrentValue = false,
    Flag = "MyFeature",
    Save = false,
    Callback = function(value)
        print("Auto Open Packs changed:", value)
        AutoOpen = value
    end,
})

task.spawn(function()
    while task.wait(1) do
        if AutoOpen then
            for _, v in pairs(workspace.MAP.Plots[PlotNumber].Plot_N0:GetChildren()) do
                if v.Name:sub(1, 8) == "CardSlot" then
                    local Pack = v:FindFirstChildWhichIsA("Model")

                    if Pack then
                        local PromptOpen1 = v:FindFirstChild("PromptHolder")
                        local GuiHolder = Pack:FindFirstChild("GuiHolder")

                        if PromptOpen1 and GuiHolder then
                            local PromptOpen2 = PromptOpen1:FindFirstChild("ProximityPrompt")
                            local BillboardGuiTimer = GuiHolder:FindFirstChild("BillboardGuiTimer")

                            if PromptOpen2 and BillboardGuiTimer then
                                local FrameProgressBar = BillboardGuiTimer:FindFirstChild("FrameProgressBar")

                                if FrameProgressBar then
                                    local Timer = FrameProgressBar:FindFirstChild("Timer")

                                    if Timer then
                                        local Text = Timer.ContentText or Timer.Text
                                        print(Text)

                                        if Text == "READY" then
                                            Character:MoveTo(v.WorldPivot.Position + Vector3.new(0, 3, 0))
                                            task.wait(0.5)
                                            fireproximityprompt(PromptOpen2)
                                            print("Opened Pack at: " .. v.Name)
                                        end
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

Farmsection:CreateSlider({
    Name = "Sell Delay",
    Min = 1,
    Max = 100,
    CurrentValue = 10,
    Rounding = 1,
    Flag = "SpeedValue",
    Save = true,
    Callback = function(value)
        print("Sell Delay :", value)
        SellDelay = value
    end,
})

Farmsection:CreateToggle({
    Name = "Auto sell Box",
    CurrentValue = false,
    Flag = "MyFeature",
    Save = false,
    Callback = function(value)
        print("Auto sell Box changed:", value)
        AutoSellBox = value
    end,
})

task.spawn(function ()
    while task.wait(SellDelay) do 
        if AutoSellBox then 
            RootPart.CFrame = ProxiBoxlocation.CFrame + Vector3.new(0, 3, 0)
            task.wait(0.5)
            fireproximityprompt(ProxiBoxen)
            task.wait(0.5)
            game.Players.LocalPlayer.Character.Humanoid:EquipTool(
                game.Players.LocalPlayer.Backpack.Box
            )
            task.wait(0.2)
            Character:MoveTo(TeleSellBox.WorldPivot.Position + Vector3.new(0, 3, 0))
            task.wait(0.2)
            fireproximityprompt(ProxiSellBoxen)
            task.wait(0.1)
            if game.Players.LocalPlayer.Backpack.Box then 
                fireproximityprompt(ProxiSellBoxen)
                task.wait(0.1)
            end
        end
    end
end)
