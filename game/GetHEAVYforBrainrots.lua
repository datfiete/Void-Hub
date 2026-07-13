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

local CyberUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/datfiete/Void-Hub/main/CyberUI/load.lua"))()

CyberUI.Theme.Style = "Meng"

local window = CyberUI:CreateWindow({
    Title = "[🍔] Get HEAVY for Brainrots",
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

local function TeleportTo(position)
    RootPart.CFrame = CFrame.new(position + Vector3.new(0, 4, 0))  -- 4 Studs über dem Punkt
    RootPart.Velocity = Vector3.new(0, 0, 0)
    task.wait(0.15)
end

local function isInTable(value, tbl)
    for _, v in ipairs(tbl) do
        if v == value then
            return true
        end
    end
    return false
end

local Back = workspace.CollectHitbox
local AutoFarm = false
local Selected = {"_Ancient"}

Farmsection:CreateDropdown({
    Name = "Which Rarity",
    Options = {"_Ancient", "_OG", "_Divine", "Secret", "_Mythical", "_Legendary", "_Epic", "_Rare", "_Uncommon"}, "_Common",
    CurrentOption = "_Ancient",
    MultipleOptions = true,
    Flag = "WhichRarity",
    Save = true,
    Callback = function(value)
        print("Selected Rarity:", value)
        local Selected = {value}
    end,
})

Farmsection:CreateToggle({
    Name = "Auto Farm",
    CurrentValue = false,
    Flag = "MyFeature",
    Save = false,
    Callback = function(value)
        print("Auto Farm set to:", value)
        AutoFarm = value
    end,
})

task.spawn(function ()
    while task.wait(1) do 
        if AutoFarm then
            TeleportTo(Vector3.new(454, 333, -44))
            task.wait(1)
            for i, v in pairs(workspace.RarityParts:GetChildren()) do
                if isInTable(v.Name, Selected) then
                    local Items = v:FindFirstChild("Items")
                    if Items then
                        for q, w in pairs(Items:GetChildren()) do
                            local HandlePart = w:FindFirstChild("Handle")
                            if HandlePart then
                                local Prompt = HandlePart:FindFirstChildOfClass("ProximityPrompt")
                                
                                if Prompt then
                                    TeleportTo(HandlePart.Position)
                                    task.wait(0.1)
                                    fireproximityprompt(Prompt)
                                    task.wait(0.2)  -- etwas länger warten nach dem Sammeln
                                    TeleportTo(Back.Position)
                                    task.wait(0.5) 
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)
