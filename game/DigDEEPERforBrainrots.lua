local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Dig DEEPER for Brainrots",
    Icon = 0,
    LoadingTitle = "Dig DEEPER for Brainrots script",
    LoadingSubtitle = "by Datfeite",
    ShowText = "Dig DEEPER for Brainrots",
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

local player = game.Players.LocalPlayer

local Character
local rootPart

local function updateCharacter(char)
    Character = char
    rootPart = char:WaitForChild("HumanoidRootPart")
end

updateCharacter(player.Character or player.CharacterAdded:Wait())

player.CharacterAdded:Connect(function(char)
    updateCharacter(char)
end)

local AutoClaim = false
local AutoFarm = false 
local Map = "Eternal"

local ClaimEvent = game:GetService("ReplicatedStorage")
    .Packages._Index["sleitnick_knit@1.7.0"]
    .knit.Services.ButtonService.RF.Claim

local Dropdown = MainTab:CreateDropdown({
   Name = "Which Floor",
   Options = {"Eternal", "Brainrot God", "Celestial", "Common", "Divine", "Epic", "Legendary", "Mythic", "Rare", "Secret", "Uncommon"},
   CurrentOption = {"Eternal"},
   MultipleOptions = false,
   Flag = "WhichFloorDropdown1",
   Callback = function(WhichFloorDropdown1)
    Map = WhichFloorDropdown1[1]
   end,
})

local Toggle = MainTab:CreateToggle({
   Name = "Auto Farm",
   CurrentValue = false,
   Flag = "AutoFarmToggle1", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   Callback = function(AutoFarmToggle1)
    AutoFarm = AutoFarmToggle1 
   end,
})

task.spawn(function()
    while true do
        if AutoFarm then
            local floor = workspace.Zones.Visuals:FindFirstChild(Map)

            if floor and floor:FindFirstChild("Brainrots") and floor.Brainrots:FindFirstChild("Brainrots") then
                for _, v in ipairs(floor.Brainrots.Brainrots:GetChildren()) do
                    if not AutoFarm then
                        break
                    end

                    Character:MoveTo(v.Position)

                    local attachment = v:FindFirstChild("Attachment")
                    task.wait(0.5)

                    if attachment and attachment:IsA("Attachment") then
                        local prompt = attachment:FindFirstChild("ProximityPrompt")

                        if prompt and prompt:IsA("ProximityPrompt") then
                            fireproximityprompt(prompt)
                            Character:MoveTo(Vector3.new(-1023, 21909, -715))
                            task.wait(2)
                        end
                    end
                end
            end
        end

        task.wait(1)
    end
end)

local Toggle = DevTab:CreateToggle({
    Name = "Auto Claim Slots",
    CurrentValue = false,
    Flag = "AutoClaimSlots",
    Callback = function(Value)
        AutoClaim = Value
    end,
})


task.spawn(function()
    while true do
        if AutoClaim then
            local player = game.Players.LocalPlayer
            local myBase

            for _, base in ipairs(workspace.Bases:GetChildren()) do
                if base:GetAttribute("Owner") == player.UserId then
                    myBase = base
                    break
                end
            end

            if myBase and myBase:FindFirstChild("Buttons") then
                for _, slot in ipairs(myBase.Buttons:GetChildren()) do
                    if not AutoClaim then break end

                    if slot.Name:match("^Slot_%d+$") then
                        pcall(function()
                            Event:InvokeServer(slot) -- WICHTIG: Instance!
                        end)

                        task.wait(0.2)
                    end
                end
            end
        end

        task.wait(1)
    end
end)
