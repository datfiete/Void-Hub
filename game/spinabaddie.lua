local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Spin a Baddie",
   Icon = 0, -- Icon in Topbar. Can use Lucide Icons (string) or Roblox Image (number). 0 to use no icon (default).
   LoadingTitle = "Test 1",
   LoadingSubtitle = "by Fiete",
   ShowText = "Rayfield",
   Theme = "DarkBlue", -- Check https://docs.sirius.menu/rayfield/configuration/themes

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
local DropdownTab = Window:CreateTab("Shop", 1234567890)
local NewTab = Window:CreateTab("Testing", 4483362458)

local Toggle = MainTab:CreateToggle({
   Name = "auto place best baddie",
   CurrentValue = false,
   Flag = "Toggle1", 
   Callback = function(AutoBest)
      getgenv().AutoPlace = AutoBest
   end,
})

task.spawn(function()
   while true do
      if getgenv().AutoPlace then
         pcall(function()
            game:GetService("ReplicatedStorage")
               :WaitForChild("Events")
               :WaitForChild("PlaceBestBaddies")
               :InvokeServer()
               wait(0.5)
         end)
         task.wait(10)  -- passe an dein Spiel an
      end
      task.wait(0.1)
   end
end)

local Toggle = MainTab:CreateToggle({
   Name = "Auto Roll Dice",
   CurrentValue = false,
   Flag = "AutoRollDice", 
   Callback = function(RollDice)
      getgenv().AutoRoll = RollDice
   end,
})

task.spawn(function()
   while true do
      if getgenv().AutoRoll then
         -- Dein Würfel-Aufruf (genau wie du ihn geschrieben hast)
         game:GetService("Players").LocalPlayer
            :WaitForChild("PlayerGui")
            :WaitForChild("Main")
            :WaitForChild("Dice")
            :WaitForChild("RollState")
            :InvokeServer()
         
         task.wait(0.5)   -- Wartezeit zwischen Rolls – passe an (z. B. 1, 2, 3 Sekunden)
      end
      task.wait(0.1)    -- Kleiner Check-Loop, damit es nicht 100% CPU frisst
   end
end)

local Toggle = MainTab:CreateToggle({
   Name = "Auto Rebirth",
   CurrentValue = false,
   Flag = "AutoRebirthFlag", 
   Callback = function(Rebirth)
      getgenv().AutoRebirth = Rebirth
   end,
})

task.spawn(function()
   while true do
      if getgenv().AutoRebirth then
         pcall(function()  -- Sicherheitsnetz, falls Invoke mal fehlschlägt (z.B. Cooldown, kein Geld genug)
            game:GetService("ReplicatedStorage")
               :WaitForChild("Events")
               :WaitForChild("rebirth")
               :InvokeServer()
         end)
         
         task.wait(10)   -- ← Starte mit 5–10 Sekunden! Viele Rebirth-Systeme haben 5–30s Cooldown oder brauchen Zeit zum Farmen danach
      end
      task.wait(0.3)    -- Kleiner Loop-Check (nicht zu klein, sonst CPU-Last)
   end
end)

local Button = MainTab:CreateButton({
   Name = "collect all quests",
   Callback = function()
      for i = 1, 6 do
         pcall(function()
            local args = {"ClaimReward", i}
            game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("QuestRemote"):InvokeServer(unpack(args))
         end)
      end
   end,
})

local Button = MainTab:CreateButton({
   Name = "collect index",
   Callback = function()
   local args = {
      }
      game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("claimAll"):InvokeServer()
   end,
})




-- Globale Variablen initialisieren (einmal am Anfang des Scripts)
getgenv().SelectedDices = {}
getgenv().AutoBuyDices = false

-- Alle Dice-Namen (exakt so, wie das Remote sie erwartet – Groß-/Kleinschreibung beachten!)
local diceOptions = {
    "Basic Dice",
    "Celestial Dice",
    "Solar Dice",
    "Abyssal Dice",
    "Hell Dice",
    "Infinity Dice",
    "Blackhole Dice",
    "Death Dice",
    "Paradoxical Dice",
    "Soul Dice",
    "Joker Dice",
    "Reality Dice",
    "Kraken Dice",
    "Seraphic Dice",
    "Galactic Dice",
    "Eldritch Dice",
    "Emperor Dice",
    "Annihilation Dice",
    "Disaster Dice",
    "Impossible Dice",
    "Limbo Dice"
}

-- Dropdown mit Multi-Selection
local DiceDropdown = DropdownTab:CreateDropdown({
    Name = "Select Dices to Buy",
    Options = diceOptions,
    CurrentOption = {},                -- leer starten → Multi-Auswahl möglich
    MultipleOptions = true,
    Flag = "DiceDropdownMulti",        -- hilft beim Speichern der Auswahl (falls Library das unterstützt)
    Callback = function(Dicesel)
        getgenv().SelectedDices = Dicesel  -- Dicesel ist eine Tabelle mit den gewählten Strings
    end,
})

-- Toggle für Auto-Buy
local AutoBuyToggle = DropdownTab:CreateToggle({
    Name = "Auto Buy Selected Dices",
    CurrentValue = false,
    Flag = "AutoBuyToggle",
    Callback = function(BuyDice)
        getgenv().AutoBuyDices = BuyDice
    end,
})

-- Der Auto-Kauf-Loop (im Hintergrund)
task.spawn(function()
    while true do
        if getgenv().AutoBuyDices == true 
           and getgenv().SelectedDices 
           and #getgenv().SelectedDices > 0 then
            
            for _, diceName in ipairs(getgenv().SelectedDices) do
                pcall(function()
                    local args = {diceName, 1, "dice"}
                    game:GetService("ReplicatedStorage")
                        :WaitForChild("Events")
                        :WaitForChild("buy")
                        :InvokeServer(unpack(args))
                end)
                
                task.wait(10)   -- 30 Sekunden zwischen jedem Kauf – wichtig gegen Rate-Limit
            end
            
            task.wait(1)     -- 15 Sekunden Pause nach einem kompletten Durchlauf (anpassen!)
        end
        
        task.wait(0.3)        -- wenn aus, nur leicht warten
    end
end)



getgenv().SelectedPotions = {}
getgenv().AutoBuyPotions = false


local potionOptions = {
    "Luck Potion 1",
    "Luck Potion 2",
    "Luck Potion 3",
    "Money Potion 1",
    "Money Potion 2",
    "Money Potion 3",
}

-- Dropdown mit Multi-Selection für Potions
local PotionDropdown = DropdownTab:CreateDropdown({
    Name = "Select Potions to Buy",
    Options = potionOptions,
    CurrentOption = {},
    MultipleOptions = true,
    Flag = "PotionDropdownMulti",
    Callback = function(PotionSel)
        getgenv().SelectedPotions = PotionSel
    end,
})

-- Toggle für Auto-Buy Potions
local AutoBuyPotionToggle = DropdownTab:CreateToggle({
    Name = "Auto Buy Selected Potions",
    CurrentValue = false,
    Flag = "AutoBuyPotionsToggle",
    Callback = function(BuyPotions)
        getgenv().AutoBuyPotions = BuyPotions
    end,
})

task.spawn(function()
    while true do
        if getgenv().AutoBuyPotions == true 
           and getgenv().SelectedPotions 
           and #getgenv().SelectedPotions > 0 then
            
            for _, potionName in ipairs(getgenv().SelectedPotions) do
                pcall(function()
                    local args = {potionName, 1, "potion"}
                    game:GetService("ReplicatedStorage")
                        :WaitForChild("Events")
                        :WaitForChild("buy")
                        :InvokeServer(unpack(args))
                end)
                
                task.wait(10)   -- 10sek zwischen jedem Kauf
            end
            
            task.wait(15)     -- 15s Pause nach Zyklus
        end
        
        task.wait(0.3)
    end
end)







local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = ReplicatedStorage:WaitForChild("Events", 10)
local RegularPet = Events:WaitForChild("RegularPet", 5)

if not RegularPet then
    warn("[AutoEgg] RegularPet Remote nicht gefunden!")
    return
end

-- Globale Task-Steuerung (einmalig)
if _G.AutoEggRunningTask then
    task.cancel(_G.AutoEggRunningTask)  -- alten Thread killen, falls vorhanden
    _G.AutoEggRunningTask = nil
end

-- Dropdown
local EggDropdown = NewTab:CreateDropdown({
    Name = "Egg Option",
    Options = {"MartianEgg", "BackroomsEgg", "CatEgg"},
    CurrentOption = "MartianEgg",
    MultipleOptions = false,
    Flag = "DropdownforEgg",
})

-- Toggle
local AutoBuyToggle = NewTab:CreateToggle({
    Name = "Auto buy eggs",
    CurrentValue = false,
    Flag = "AutoEggBuy",

    Callback = function(Value)
        -- Alten Thread sofort killen, wenn er läuft
        if _G.AutoEggRunningTask then
            task.cancel(_G.AutoEggRunningTask)
            _G.AutoEggRunningTask = nil
            print("[AutoEgg] Alter Loop gekillt")
        end

        if Value then
            Rayfield:Notify({
                Title = "Auto Egg",
                Content = "Auto-Kauf **gestartet**",
                Duration = 3,
            })

            _G.AutoEggRunningTask = task.defer(function()  -- defer statt spawn (stabiler)
                while true do
                    task.wait(0.7)  -- etwas länger → weniger Lag/Spam

                    -- Doppel-Check: Flag + Toggle.CurrentValue
                    if not Rayfield.Flags.AutoEggBuy or not AutoBuyToggle.CurrentValue then
                        print("[AutoEgg] Stop-Condition getroffen → Loop Ende")
                        break
                    end

                    local egg = EggDropdown.CurrentOption
                    if type(egg) == "table" then
                        egg = egg[1] or ""
                    end

                    if type(egg) ~= "string" or egg == "" then
                        task.wait(2)
                        continue
                    end

                    local success, err = pcall(function()
                        RegularPet:InvokeServer(egg, 3)
                        -- print("Gekauft:", egg)   -- für Debug ein/aus
                    end)

                    if not success then
                        warn("[AutoEgg] Fehler: " .. tostring(err))
                    end
                end

                print("[AutoEgg] Loop vollständig beendet")
                _G.AutoEggRunningTask = nil
            end)

        else
            Rayfield:Notify({
                Title = "Auto Egg",
                Content = "Auto-Kauf **gestoppt**",
                Duration = 3,
            })
            -- task.cancel oben schon passiert → Loop bricht ab
        end
    end,
})

-- === Reset alles beim Skript-Start / Re-Execute ===
Rayfield.Flags.AutoEggBuy = false
AutoBuyToggle:Set(false)   -- visuell + intern force-aus
print("[AutoEgg] Initial Reset: Toggle + Flag auf false")
