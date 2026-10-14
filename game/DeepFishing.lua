local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local VIM = game:GetService("VirtualInputManager")
local Workspace = game:GetService("Workspace")

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
    Title = "[PETS] Deep Fishing🎣",
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

    DiscordLink = "https://discord.gg/example",
    ShowSearch = true,
    ShowWindowControls = true,
    ToggleKey = Enum.KeyCode.RightControl,
    TopMost = true,

    ConfigurationSaving = {
        Enabled = true,
        AutoSave = true,
        FolderName = "Vaxorin",
        FileName = "Deep Fishing",
    },
})

window:SetProfileStatus("Ready")
window:SetWatermarkEnabled(true)

local Farmtab = window:CreateTab("Main")
local Farmsection = Farmtab:CreateSection({
    Name = "Main",
    Description = "General settings.",
})

Farmsection:CreateNotice({ Title = "IMPORTANT", Content = "The Code is still in development so it may not work as expected or just bad." })

local MultiLabel = LocalPlayer.PlayerGui.HUD.Fishing.Hook.TextLabel
local AutoFish = false
local AutoFishMode = "fast"

local FishOptions = game:GetService("ReplicatedStorage").Prefabs.Items.Fish["World 1"].Default:GetChildren()
local fishNames = {}
for _, fish in ipairs(FishOptions) do
    fishNames[fish.Name] = true
end

local function GetBait()
    for _, v in ipairs(Workspace:GetChildren()) do
        if v:IsA("BasePart") and v.Name == "Bait" and v:FindFirstChild("Bounce1") then
            return v
        end
    end
end

local function GetClosestFish()
    local bait = GetBait()
    local closest, closestDist = nil, math.huge
    local fishCount = 0

    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:IsA("Model") and fishNames[obj.Name] then
            local fishPos = obj:GetPivot().Position

            if bait and fishPos.Y > bait.Position.Y + 0.5 then
                fishCount += 1

                local dist = (fishPos - bait.Position).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closest = obj
                end
            end
        end
    end

    return closest, fishCount
end

local function GetBestFish()
    local bait = GetBait()
    local bestFish = nil
    local bestPrice = -1
    local bestDist = math.huge
    local fishCount = 0

    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:IsA("Model") and fishNames[obj.Name] then
            local fishPos = obj:GetPivot().Position

            if bait and fishPos.Y > bait.Position.Y + 0.5 then
                fishCount += 1

                local hitbox = obj:FindFirstChild("Hitbox")
                local rarityTag = hitbox and hitbox:FindFirstChild("RarityTag")
                local priceLabel = rarityTag and rarityTag:FindFirstChild("Price")

                local price = 0
                if priceLabel then
                    local priceText = priceLabel.Text
                    price = tonumber(priceText:match("[%d%.]+")) or 0
                end

                local dist = (fishPos - bait.Position).Magnitude

                if price > bestPrice or
                    (price == bestPrice and dist < bestDist) then
                    bestPrice = price
                    bestDist = dist
                    bestFish = obj
                end
            end
        end
    end

    return bestFish, fishCount
end


local function SetKeys(left, right)
    VIM:SendKeyEvent(left, Enum.KeyCode.Left, false, game)
    VIM:SendKeyEvent(right, Enum.KeyCode.Right, false, game)
    VIM:SendKeyEvent(left, Enum.KeyCode.A, false, game)
    VIM:SendKeyEvent(right, Enum.KeyCode.D, false, game)
end

Farmsection:CreateDropdown({
    Name = "Mode",
    Options = { "Highest Value", "fast" },
    CurrentOption = "fast",
    MultipleOptions = false,
    Flag = "Feature.Mode",
    Save = true,
    Callback = function(value)
        -- Some dropdown libraries return a table of selected options.
        if type(value) == "table" then
            value = value[1]
        end

        AutoFishMode = value or "fast"
    end,
})


Farmsection:CreateToggle({
    Name = "Auto Cast + Auto Reel",
    CurrentValue = false,
    Flag = "Feature.Enabled",
    Save = true,
    Callback = function(value)
        AutoFish = value

        if not value then
            SetKeys(false, false)
            VIM:SendMouseButtonEvent(0, 0, 0, false, game, 1)
            return
        end

        task.spawn(function()
            while AutoFish do
                -- Declare these outside the conditional.
                local fish, fishCount

                if AutoFishMode == "Highest Value" then
                    fish, fishCount = GetBestFish()
                else
                    fish, fishCount = GetClosestFish()
                end

                local bait = GetBait()

                if fishCount == 0 or not fish then
                    SetKeys(false, false)

                    VIM:SendMouseButtonEvent(
                        0, 0, 0, true, game, 1
                    )
                    task.wait(0.35)

                    VIM:SendMouseButtonEvent(
                        0, 0, 0, false, game, 1
                    )
                    task.wait(0.8)
                else
                    VIM:SendMouseButtonEvent(
                        0, 0, 0, true, game, 1
                    )

                    if MultiLabel.Text == "x2.0" then
                        VIM:SendMouseButtonEvent(
                            0, 0, 0, false, game, 1
                        )
                        task.wait(0.12)
                    end

                    if bait then
                        local diffZ =
                            fish:GetPivot().Position.Z - bait.Position.Z

                        if diffZ < -0.5 then
                            SetKeys(false, true)
                        elseif diffZ > 0.5 then
                            SetKeys(true, false)
                        else
                            SetKeys(false, false)
                        end
                    else
                        SetKeys(false, false)
                    end
                end

                task.wait(0.03)
            end

            SetKeys(false, false)
            VIM:SendMouseButtonEvent(0, 0, 0, false, game, 1)
        end)
    end,
})
