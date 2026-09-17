local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local RootPart = Character:WaitForChild("HumanoidRootPart")
local Executor = getexecutorname()

local Vaxorin = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/datfiete/Void-Hub/refs/heads/main/CyberUI%20-%20Kopie/load.lua"
))()

Vaxorin.Theme.Style = "Vaxorin"

local avatar = ""
pcall(function()
    avatar = Players:GetUserThumbnailAsync(
        LocalPlayer.UserId,
        Enum.ThumbnailType.HeadShot,
        Enum.ThumbnailSize.Size150x150
    )
end)

local window = Vaxorin:CreateWindow({
    Title = "Fish an Anime RNG",
    Subtitle = "by Fietewoozle",
    Logo = "rbxassetid://135320038058277",

    Badges = {
        { Text = "Vaxorin | v1.0" },
        { Text = "Executor : " .. Executor},
    },

    Footer = {
        Avatar = avatar,
        Username = LocalPlayer.Name,
        Status = "Player",
    },

    DiscordLink = "https://discord.gg/9jZTsy7Wtb",
    ShowSearch = true,
    ShowWindowControls = true,
    ToggleKey = Enum.KeyCode.RightControl,

    ConfigurationSaving = {
        Enabled = true,
        AutoSave = true,
    },
})

window:SetProfileStatus("Player")
window:SetWatermarkEnabled(true)

local Maintab = window:CreateTab("Main")
local Mainsection = Maintab:CreateSection({
    Name = "Main Section",
    Description = "General settings.",
})

local AutoCollectMoney = false

local Plot = ""
local PlotPath = nil

for i, v in pairs(workspace.PlayerPlots:GetChildren()) do
    if v:GetAttribute("OwnerName") == LocalPlayer.Name then
        Plot = v.Name
        PlotPath = v
    end
end

print("Plot: " .. Plot)

Mainsection:CreateToggle({
    Name = "Auto Collect Money",
    CurrentValue = false,
    Flag = "MyFeature",
    Save = false,
    Callback = function(value)
        AutoCollectMoney = value
    end,
})

task.spawn(function()
    while task.wait(1) do 
        if AutoCollectMoney then 
            if PlotPath:FindFirstChild("1") and PlotPath:FindFirstChild("2") and PlotPath:FindFirstChild("3") and PlotPath:FindFirstChild("Purchases", true) then 
                local plot1 = PlotPath:FindFirstChild("1")
                local plot2 = PlotPath:FindFirstChild("2")
                local plot3 = PlotPath:FindFirstChild("3")
                local RestPlot = PlotPath:FindFirstChild("Purchases", true)
                for i, v in pairs(RestPlot:GetChildren()) do 
                    if v:GetAttribute("HasCharacter") == true then 
                        local Touch = v:FindFirstChildOfClass("TouchTransmitter", true)
                        print(v.Name)
                        if Touch then 
                            print(v.Name .. " has a touch transmitter")
                            firetouchinterest(RootPart, Touch.Parent, 0)
                            task.wait(0.1)
                            firetouchinterest(RootPart, Touch.Parent, 1)
                        end
                    end
                end
            end
        end
    end
end
)