local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local PlayerId = Player.UserId
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
    Title = "[🌑] 🐝Grow a Beehive",
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

local YourPlot = nil 

for i, v in pairs(workspace.Plots:GetChildren()) do 
    if v:GetAttribute("OwnerUserId") == PlayerId then 
        YourPlot = v.Name
    end
end
print(YourPlot)

local HoneyJar = workspace.Plots[YourPlot].HoneyJar.Jar.Lid.PromptOffset.ProximityPrompt
local SellNPC = workspace.Plots[YourPlot].SellBooth.SellNPC.HumanoidRootPart.ProximityPrompt
local EqupiBestPrompt = workspace.Plots[YourPlot].EquipBest["Cube.002"].ProximityPrompt

local AutoBuy = false
local AutoCollect = false
local AutoCollectDelay = 5
local AutoSell = false
local AutoSellDelay = 5
local AutoBuySlots = false
local EquipBest = false
local EquipBestDelay = 5

local function isInTable(value, tbl)
    for _, v in ipairs(tbl) do
        if v == value then
            return true
        end
    end
    return false
end

Farmsection:CreateToggle({
    Name = "Auto Buy(Auto Roll Required)",
    CurrentValue = false,
    Flag = "MyFeature",
    Save = false,
    Callback = function(value)
        AutoBuy = value
    end,
})

task.spawn(function()
    while task.wait(0.5) do
        if not AutoBuy then continue end   -- oder AutoRoll, je nachdem wie deine Variable heißt
        
        for _, v in ipairs(workspace:GetChildren()) do
            if v:GetAttribute("Scaled") == 1 then
                
                local originalParent = v.Parent
                local prompt = v:FindFirstChild("ProximityPrompt", true)
                
                if prompt then
                    print("Gefunden:", v.Name, "- Warte paar Sekunden...")
                    
                    task.wait(3)  -- Wartezeit (z.B. 3 Sekunden)
                    
                    -- Jetzt prüfen ob es immer noch existiert
                    if v.Parent == originalParent and v:IsDescendantOf(workspace) then
                        print("✅ Immer noch da! → Claiming", v.Name)
                        fireproximityprompt(prompt)
                        task.wait(1)
                    else
                        print("❌ Verschwunden während Wartezeit:", v.Name)
                    end
                end
            end
        end
    end
end)

Farmsection:CreateSlider({
    Name = "Auto Collect Nectar Delay",
    Min = 1,
    Max = 100,
    CurrentValue = 5,
    Rounding = 1,
    Flag = "AutoCollectNectarDelay",
    Save = true,
    Callback = function(value)
        AutoCollectDelay = value
    end,
})

Farmsection:CreateToggle({
    Name = "Auto Collect Nectar",
    CurrentValue = false,
    Flag = "MyFeature",
    Save = false,
    Callback = function(value)
        AutoCollect = value
    end,
})

task.spawn(function ()
    while task.wait(AutoCollectDelay) do 
        if AutoCollect then 
            fireproximityprompt(HoneyJar)
        end
    end
end)

Farmsection:CreateSlider({
    Name = "Auto Sell Nectar Delay",
    Min = 1,
    Max = 100,
    CurrentValue = 5,
    Rounding = 1,
    Flag = "AutoSellNectarDelay",
    Save = true,
    Callback = function(value)
        AutoSellDelay = value
    end,
})

Farmsection:CreateToggle({
    Name = "Auto Sell Nectar",
    CurrentValue = false,
    Flag = "MyFeature",
    Save = false,
    Callback = function(value)
        AutoSell = value
    end,
})

task.spawn(function ()
    while task.wait(AutoSellDelay) do 
        if AutoSell then 
            fireproximityprompt(SellNPC)
        end
    end
end)

Farmsection:CreateToggle({
    Name = "Auto Buy Slots",
    CurrentValue = false,
    Flag = "MyFeature",
    Save = false,
    Callback = function(value)
        AutoBuySlots = value
    end,
})

task.spawn(function()
    while task.wait(0.5) do
        if not AutoBuySlots then continue end
        local plotFolder = workspace.Plots[YourPlot]
        for layerNum = 1, 3 do  -- Layer1, Layer2, Layer3
            local layer = plotFolder:FindFirstChild("Layer" .. layerNum)
            if not layer then continue end
                
            for _, plot in pairs(layer:GetChildren()) do
                local Prompt = plot:FindFirstChild("ProximityPrompt", true)
                if Prompt then 
                    print("Firing prompt on:", plot.Name, "(Plot"..L..", Layer"..layerNum..")")
                    fireproximityprompt(Prompt)
                        
                    task.wait(0.5) -- time for BuyHive GUI
                        
                    local playerGui = game:GetService("Players").LocalPlayer.PlayerGui
                    local buyHive = playerGui:FindFirstChild("BuyHive", true)
                        
                    if buyHive then
                    print("✓ BuyHive found!")
                    local background = buyHive:FindFirstChild("Background", true)
                    local buyButton = background and background:FindFirstChild("Buy")
                            
                    if buyButton then
                        print("✓ Clicking Buy button...")
                        firesignal(buyButton.Activated)
                            task.wait(0.5)
                         else
                            print("✗ Buy button not found")
                        end
                    else
                        print("✗ BuyHive GUI not found")
                    end
                        
                    task.wait(0.5)
                end
            end
        end
    end
end)

Farmsection:CreateSlider({
    Name = "Auto Equip Best Bees Delay",
    Min = 1,
    Max = 100,
    CurrentValue = 5,
    Rounding = 1,
    Flag = "AutoEquipBestBeesDelay",
    Save = true,
    Callback = function(value)
        EquipBestDelay = value
    end,
})

Farmsection:CreateToggle({
    Name = "Auto Equip Best Bees",
    CurrentValue = false,
    Flag = "MyFeature",
    Save = false,
    Callback = function(value)
        print("Toggle changed:", value)
        EquipBest = value
    end,
})

task.spawn(function ()
    while task.wait(EquipBestDelay) do 
        if EquipBest then 
            fireproximityprompt(EqupiBestPrompt)
        end
    end
end)