local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Speed Keyboard Brainrot Escape",
    Icon = 0,
    LoadingTitle = "Speed Keyboard Brainrot Escape script",
    LoadingSubtitle = "by Datfeite",
    ShowText = "Speed Keyboard Brainrot Escape",
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

local Player = game.Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()

local AutoFarm = false
local AutoWalk = false
local Brainrot = workspace.SpawnedBrainrots
local hrp = game.Players.LocalPlayer.Character.HumanoidRootPart
local target = workspace.Map.BrainrotCollectionPart
local VIM = game:GetService("VirtualInputManager")




local Toggle = FarmTab:CreateToggle({
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
             for i, v in pairs(Brainrot:GetChildren()) do 
                Character:MoveTo(Vector3.new(-2, 6, -3976))
                print(v)
                task.wait(0.5)
                if v:GetAttribute("AreaName") == "AncientArea"
                or v:GetAttribute("AreaName") == "AncientAreaPlus" then

                    local overhead = v:FindFirstChild("Overhead") or v:FindFirstChild("1Overhead")

                    if overhead then 
                        Character:MoveTo(overhead.Position)
                        fireproximityprompt(v.PickupHitbox.ProximityPrompt)
                        Character:MoveTo(Vector3.new(16, 6, -244))
                        firetouchinterest(hrp, target, 0)
                        wait(0.05)
                        firetouchinterest(hrp, target, 1)
                    else 
                        print("Despawned")
                    end
                else 
                    print("Too bad")
                end
            end
        end
        task.wait(0.1)
    end
end)

local Toggle = FarmTab:CreateToggle({
   Name = "Auto Walk",
   CurrentValue = false,
   Flag = "AutoWalkToggle1",
   Callback = function(Value)
      AutoWalk = Value
      
      if not Value then
         VIM:SendKeyEvent(false, Enum.KeyCode.W, false, game)
      end
   end,
})

task.spawn(function()
    while true do
        if AutoWalk then
            VIM:SendKeyEvent(true, Enum.KeyCode.W, false, game)
            task.wait(0.08)
        else
            task.wait(0.2)
        end
    end
end)

local Event = game:GetService("ReplicatedStorage").Remotes.PlaceBest
Event:FireServer()
