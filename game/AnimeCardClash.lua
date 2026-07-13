local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Anime Crad Clash",
    Icon = 0,
    LoadingTitle = "Anime Crad Clash script",
    LoadingSubtitle = "by Datfeite",
    ShowText = "Anime Crad Clash",
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
local RollTab = Window:CreateTab("Rolling", 4483362458)
local DevTab = Window:CreateTab("Developer", 4483362458)

-- Variables
local AutoFight = false
local Arenaset = false
local AutoFightPlayer = nil
local AutoFightArena = workspace.places:GetChildren()[1].Name
local AutoFightArenaTeleportCheck = nil
local AutofightCharacter = nil
local CharacterOptions = {}
local DifficultyFights = "normal"
local AutoRoll = false

local BossIDs = {
    ["ultimate_warrior"] = 414,
    ["some_other_boss"] = 123,
    ["unstoppable_fist"] = 422
}

-- Function to get boss names from arena
local function GetBosses(arenaName)
    local place = workspace.places:WaitForChild(arenaName, 10)
    if not place then
        warn("Arena failed to load:", arenaName)
        return {}
    end

    local bossFolder = place:WaitForChild("boss", 10)
    if not bossFolder then
        warn("Boss folder failed to load")
        return {}
    end

    local names = {}
    for _, boss in ipairs(bossFolder:GetChildren()) do
        local bossName = boss:GetAttribute("bossId")
        local bossServerID = boss:GetAttribute("serverEntityId")
        table.insert(names, bossName)
        BossIDs[bossName] = bossServerID
    end
    return names
end

-- Character Dropdown (defined first so ArenaDropdown can reference it)
local CharacterDropdown = MainTab:CreateDropdown({
   Name = "Character to Fight",
   Options = GetBosses(AutoFightArena),
   CurrentOption = {nil},
   MultipleOptions = false,
   Flag = "CharactertoFightDropdown1",
   Callback = function(CharfigDrop)
      AutofightCharacter = CharfigDrop[1]
      print("Target set to:", AutofightCharacter)
   end,
})

-- Arena Dropdown
local ArenaDropdown = MainTab:CreateDropdown({
   Name = "Which Arena?",
   Options = {"ninja_village", "green_planet", "shibuya_station", "titans_city"},
   CurrentOption = {workspace.places:GetChildren()[1].Name},
   MultipleOptions = false,
   Flag = "ArenaDropdown1",
   Callback = function(Arendrop)
      AutoFightArena = Arendrop[1]
      if Arendrop then
         Arenaset = true
         game:GetService("ReplicatedStorage")
            :WaitForChild("../out/acc/shared/network@eventDefinitions")
            :WaitForChild("teleport")
            :FireServer(AutoFightArena)
         print("Teleported to:", AutoFightArena)
         task.wait(3)
         -- Refresh character dropdown with new arena's bosses
         CharacterOptions = GetBosses(AutoFightArena)
         CharacterDropdown:Refresh(CharacterOptions, true)
      end
   end,
})

local Dropdown = MainTab:CreateDropdown({
   Name = "difficulty",
   Options = {"normal", "medium", "hard", "extreme", "nightmare", "celestial"},
   CurrentOption = {"normal"},
   MultipleOptions = false,
   Flag = "difficultyDropdown1", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   Callback = function(diffight)
    DifficultyFights = diffight[1]
    print("set difficulty to:", DifficultyFights)
   end,
})

-- Auto Fight Toggle
local Toggle = MainTab:CreateToggle({
    Name = "Auto fight",
    CurrentValue = false,
    Flag = "AutofightToggle",
    Callback = function(state)
        AutoFightPlayer = state
    end
})

task.spawn(function()
    while true do
        if AutoFightPlayer then
            if not AutofightCharacter then
                warn("No character selected!")
            else
                local args = {
                    BossIDs[AutofightCharacter],
                    DifficultyFights
                }

                game:GetService("ReplicatedStorage")
                    :WaitForChild("../out/acc/shared/network@eventDefinitions")
                    :WaitForChild("fightStoryBoss")
                    :FireServer(unpack(args))

                print("Fighting:", AutofightCharacter, "| ID:", BossIDs[AutofightCharacter])
            end
        end
        task.wait(1)
    end
end)

local FightButton = DevTab:CreateButton({
    Name = "Fight",
    Callback = function()
        if not AutofightCharacter then
            warn("No character selected!")
            return
        end

        local args = {
            BossIDs[AutofightCharacter],
            DifficultyFights
        }

        game:GetService("ReplicatedStorage")
            :WaitForChild("../out/acc/shared/network@eventDefinitions")
            :WaitForChild("fightStoryBoss")
            :FireServer(unpack(args))

        print("Fighting:", AutofightCharacter, "| ID:", BossIDs[AutofightCharacter])
    end,
})

local Toggle = RollTab:CreateToggle({
   Name = "Auto Roll",
   CurrentValue = false,
   Flag = "AutoRollToggle", -- A flag is the identifier for the configuration file; make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   Callback = function(Auroltg)
    AutoRoll = Auroltg 
    print("Auto Rolling Active")
   end,
})

task.spawn(function()
    while true do 
        if AutoRoll then 
            game:GetService("ReplicatedStorage"):WaitForChild("../out/acc/shared/network@eventDefinitions"):WaitForChild("rollCard"):FireServer()
        end
    task.wait(3)
    end
end
)
