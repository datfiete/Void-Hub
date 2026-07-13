local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Fall sown a hole for Brainrots",
    Icon = 0,
    LoadingTitle = "Fall sown a hole for Brainrots script",
    LoadingSubtitle = "by Datfeite",
    ShowText = "Fall sown a hole for Brainrots",
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
local FarmTab = Window:CreateTab("Farm", 4483362458)
local DevTab = Window:CreateTab("Developer", 4483362458)

local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local AutoBR = false

local Toggle = MainTab:CreateToggle({
   Name = "Auto Collect Every Brainrot",
   CurrentValue = false,
   Flag = "AutoCollectEveryBrainrotToggle1", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   Callback = function(AutoCollectEveryBrainrotToggle1)
    AutoBR = AutoCollectEveryBrainrotToggle1
   end,
})

task.spawn(function()
    while true do
        if AutoBR then
            local character = player.Character or player.CharacterAdded:Wait()

            for _, spawn in ipairs(workspace.ItemSpawns:GetChildren()) do
                if spawn:IsA("Part") then
                    for _, model in ipairs(spawn:GetChildren()) do
                        if model:IsA("Model") then
                            character:PivotTo(model:GetPivot())
                            task.wait(0.5)

                            for _, obj in ipairs(model:GetDescendants()) do
                                if obj:IsA("ProximityPrompt") then
                                    fireproximityprompt(obj)

                                    character:PivotTo(
                                        CFrame.new(workspace.Zones.BikeSpawn.Position)
                                    )

                                    task.wait(0.5)
                                end
                            end
                        end
                    end
                end
            end
        end

        task.wait(0.1)
    end
end)
