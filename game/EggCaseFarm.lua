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
    Title = "My Script",
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
local Farmsection = Farmtab:CreateSection("Auto Farm")

local YourPlot = Player:GetAttribute("Plot")

if not YourPlot then
    warn("Plot attribute not found!")
    return
end

local AutoFarm = false
local SelectedRarity = {"Common"}
local AlreadyBought = {}

local RarityOption = {}

for i, v in pairs(game:GetService("ReplicatedStorage").Assets.UI.UIGradient:GetChildren()) do 
    table.insert(RarityOption, v.Name)
end

local function isInTable(value, tbl)
    for _, v in ipairs(tbl) do
        if v == value then
            return true
        end
    end
    return false
end

Farmsection:CreateDropdown({
    Name = "Rarity To Auto buy",
    Options = RarityOption,
    CurrentOption = "Common",
    MultipleOptions = true,
    Flag = "RarityToAutobuy",
    Save = true,
    Callback = function(value)
        SelectedRarity = value
        for q, w in pairs(SelectedRarity) do 
            print(SelectedRarity)
        end
    end,
})

Farmsection:CreateToggle({
    Name = "Auto Buy selected Egg",
    CurrentValue = false,
    Flag = "AutoBuyselectedEgg",
    Save = false,
    Callback = function(value)
        print("Toggle changed:", value)
        AutoFarm = value
    end,
})


task.spawn(function ()
    while task.wait(0.5) do
        if AutoFarm then 
            local plotFolder = workspace.Plots:FindFirstChild(YourPlot)

            if plotFolder then
                local spawnedCases = plotFolder.Plot_Models.BaseModel.PackConveyor.SpawnedCase
                local ButtonPrompt = plotFolder.Plot_Models.BaseModel.ButtonModel.PacketClick.ProximityPrompt
                local ButtonPromptParent = ButtonPrompt.Parent

                local boughtAnything = false

                for _, v in ipairs(spawnedCases:GetChildren()) do
                    if not v.Parent then
                        AlreadyBought[v] = nil
                    end

                    if not AlreadyBought[v] then
                        local rarity = v:GetAttribute("Rarity")

                        -- Nur ausgewählte Rarity kaufen
                        if isInTable(rarity, SelectedRarity) then
                            local prompt = v:FindFirstChildWhichIsA("ProximityPrompt", true)

                            if prompt then
                                AlreadyBought[v] = true
                                fireproximityprompt(prompt)
                                print("Bought:", v.Name, "| Rarity:", rarity)
                                boughtAnything = true

                                task.wait(0.15)
                            end
                        end
                    end
                end

                -- IMMER den Button drücken, auch wenn nichts gekauft wurde
                if ButtonPrompt then
                    RootPart.CFrame = CFrame.new(ButtonPromptParent.Position + Vector3.new(0, 3, 0))
                    task.wait(0.2)
                    fireproximityprompt(ButtonPrompt)

                    if boughtAnything then
                        print("Pressed Packet Button (Bought something)")
                    else
                        print("Pressed Packet Button (No matching rarity)")
                    end

                    task.wait(0.5)
                end
            end
        end
    end
end)
