local PlaceId = game.PlaceId
local GameName = game:GetService("MarketplaceService"):GetProductInfo(PlaceId).Name

print("🔍 Void Hub Loader | Detected PlaceId: " .. PlaceId)
print("🎮 Game Name: " .. GameName)

local GameScripts = {
    [109715918987082] = "baddiecardcollection.lua",
    [79305036070450] = "spinabaddie.lua",
    [93999763241813] = "SpinanAnime.lua",
    [77258312157727] = "SlotsRNG.lua",
    [102210353081918] = "SpinABaddieNew.lua",
    [85050171250159] = "Poopapoop.lua",
    [110829983956014] = "AnimeCardClash.lua",
    [110626257954132] = "DiceRollingIncremental.lua",
    [18408132742] = "MoneyClickerIncremental.lua",
    [116695563100438] = "KeyboardIncremental.lua",
    [91495931860400] = "PaperPlane.lua",
    [87671041872967] = "AnimeBaddieRNG.lua",
    [110626257954132] = "DiceRollingIncrementa.lua",
    [99573899253218] = "RollAnItem.lua",
    [137422980844414] = "CutGrassForAnime.lua",
    [127496889730779] = "SpeedKeyboardBrainrotEscape.lua",
    [88207898227053] = "BuildBridgeForBrainrot.lua",
    [76690673632533] = "FallDownAHoleForBrainrots.lua",
    [71472667201432] = "FlytoSpaceforBrainrot.lua",
    [16732694052] = "Fisch.lua",
    [131716211654599] = "Fisch.lua",
    [136919941417380] = "BikeObbyForBrainrots.lua",
    [84514721527976] = "DigDEEPERforBrainrots.lua",
    [92605157087535] = "CrabTycoon.lua",
    [78177131121429] = "DrillBlocksforBrainrots.lua",
    [113489516847696] = "MyFishingBrainrots.lua",
    [98916904742148] = "SurfforLuckyBlocks.lua",
    [115852335239914] = "1SkateforBrainrots.lua",
    [110334393584385] = "RollerforBrainrots.lua",
    [83569851223739] = "1SpeedEvolve.lua",
    [84332574190497] = "1WingsforBrainrots.lua",
    [116992225136973] = "[UPD]MineforBrainrot.lua",
    [103383275180202] = "HoverboardforBrainrots.lua",
    [79268393072444] = "SellLemons.lua",
    [138743684450520] = "1CrunchyWaxEscape.lua",
    [106832050389015] = "CollectAMeme.lua",
    [125039473548047] = "AnimeCardFarm.lua",
    [114640202062357] = "SwingObbyforBrainrots.lua",
    [130105672632037] = "AuraForBrainrots.lua",
    [101949297449238] = "BuildAnIsland.lua",
    [91679585668032] = "BuildAKeyboard.lua",
    [75034791252172] = "ParkourForBrainrots.lua",
    [74144293690546] = "EggCaseFarm.lua",
    [137233438285284] = "ChickenFarm.lua",
    [88891488197895] = "GrowaBeehive.lua",
}

local scriptName = GameScripts[PlaceId]

if scriptName then
    local rawUrl = "https://raw.githubusercontent.com/datfiete/Void-Hub/refs/heads/main/game/" .. scriptName
    
    print("✅ Game matched! Loading: " .. scriptName)
    
    local success, err = pcall(function()
        loadstring(game:HttpGet(rawUrl, true))()
    end)
    
    if success then
        print("🚀 Successfully loaded " .. scriptName)
    else
        warn("❌ Failed to load script: " .. tostring(err))
    end
else
    warn("⚠️ No script found for this game (PlaceId: " .. PlaceId .. ")")
    warn("Current game: " .. GameName)
    
    -- Optional: Load a default hub
    -- loadstring(game:HttpGet("https://raw.githubusercontent.com/fietewoozle-dot/MyHub/main/Hub.lua"))()
end
