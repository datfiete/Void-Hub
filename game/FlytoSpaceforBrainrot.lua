local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Fly To Space For Brainrot",
    Icon = 0,
    LoadingTitle = "Fly To Space For Brainrot script",
    LoadingSubtitle = "by Datfeite",
    ShowText = "Fly To Space For Brainrot",
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

local AutoCollectBest = false

local Player = game.Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()

local TOP_POS = Vector3.new(-309, 24703, 272)
local BOTTOM_POS = Vector3.new(-40, -168, 136)

local Toggle = DevTab:CreateToggle({
   Name = "Auto Collect Best",
   CurrentValue = false,
   Flag = "AutoCollectBestToggle1", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   Callback = function(AutoCollectBestToggle1)
    AutoCollectBest = AutoCollectBestToggle1
   end,
})

task.spawn(function()
    while true do
        if AutoCollectBest then 
            Character:MoveTo(TOP_POS)
            task.wait(1.5)
            local Brainrot = workspace.ItemSpawns["10"]
            for _, v in ipairs(Brainrot:GetChildren()) do
                if v:GetAttribute("Rarity") == "Sacred" then
                local rootPart = v:FindFirstChild("RootPart")
                    if rootPart then
                        Character:PivotTo(rootPart.CFrame)
                        task.wait(0.2)
                        local prompt = rootPart:FindFirstChild("PickupPrompt")
                        if prompt then
                            fireproximityprompt(prompt)
                            print("Collected:", v.Name)
                        end
                        task.wait(0.2)
                        Character:MoveTo(BOTTOM_POS)
                        task.wait(0.5)
                    end
                end
            end
        end

        task.wait(1)
    end
end)
