local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Surf for Lucky Blocks",
    Icon = 0,
    LoadingTitle = "Surf for Lucky Blocks script",
    LoadingSubtitle = "by Datfeite",
    ShowText = "Surf for Lucky Blocks",
    Theme = "Default",

    ToggleUIKeybind = "K",

    DisableRayfieldPrompts = false,
    DisableBuildWarnings = false,

    ConfigurationSaving = {
        Enabled = false,
        FolderName = nil,
        FileName = "Big Hub"
    },

    Discord = {
        Enabled = false,
        Invite = "noinvitelink",
        RememberJoins = true
    },

    KeySystem = false,
    KeySettings = {
        Title = "Untitled",
        Subtitle = "Key System",
        Note = "No method of obtaining the key is provided",
        FileName = "Key",
        SaveKey = true,
        GrabKeyFromSite = false,
        Key = {"Hello"}
    }
})

local MainTab = Window:CreateTab("Main", 4483362458)
local DevTab = Window:CreateTab("Developer", 4483362458)

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HRP = Character:WaitForChild("HumanoidRootPart")

local AutoFarm = false
local SelectedRarities = {"Secret"}  -- Standardwert

local Dropdown = MainTab:CreateDropdown({
   Name = "Collect Rarity",
   Options = {"Transcendent", "Divine", "OG", "Brainrot God", "Secret", "Epic", "Lava", "Legendary", "Mythic", "Rare"},
   CurrentOption = {"Secret"},
   MultipleOptions = true,        -- ← Multiselect aktiviert
   Flag = "Dropdown1",
   Callback = function(Options)
        SelectedRarities = Options  -- Options ist jetzt eine Tabelle
   end,
})

local Toggle = MainTab:CreateToggle({
   Name = "Auto Farm",
   CurrentValue = false,
   Callback = function(Value)
        AutoFarm = Value
   end,
})

-- Hilfsfunktion zum Überprüfen, ob ein Wert in der Tabelle ist
local function isInTable(value, tbl)
    for _, v in ipairs(tbl) do
        if v == value then
            return true
        end
    end
    return false
end

task.spawn(function()
    while task.wait(1) do
        if AutoFarm then
            for _, v in pairs(workspace.Live.Friends:GetChildren()) do 
                Character:MoveTo(v.WorldPivot.Position)
                
                local Rarity = v:FindFirstChild("FriendBillboard") and 
                              v.FriendBillboard:FindFirstChild("Frame") and 
                              v.FriendBillboard.Frame:FindFirstChild("Rarity") and 
                              v.FriendBillboard.Frame.Rarity.ContentText
                
                local root = v:FindFirstChild("RootPart")
                local prompt = root and root:FindFirstChild("StealPrompt")

                if prompt and Rarity and isInTable(Rarity, SelectedRarities) then
                    task.wait(0.5)
                    fireproximityprompt(prompt)
                    print("Gestohlen:", Rarity)
                    task.wait(0.5)
                    Character:MoveTo(Vector3.new(-110, 4, 349))
                    task.wait(0.5)
                end
            end
        end
    end
end)