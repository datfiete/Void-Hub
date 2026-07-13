local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Baddie Collaction thing",
   Icon = 0, -- Icon in Topbar. Can use Lucide Icons (string) or Roblox Image (number). 0 to use no icon (default).
   LoadingTitle = "Baddie Collaction thing",
   LoadingSubtitle = "by Datfeite",
   ShowText = "Baddie Collect", -- for mobile users to unhide Rayfield, change if you'd like
   Theme = "Default", -- Check https://docs.sirius.menu/rayfield/configuration/themes

   ToggleUIKeybind = "K", -- The keybind to toggle the UI visibility (string like "K" or Enum.KeyCode)

   DisableRayfieldPrompts = false,
   DisableBuildWarnings = false, -- Prevents Rayfield from emitting warnings when the script has a version mismatch with the interface.

   -- ScriptID = "sid_xxxxxxxxxxxx", -- Your Script ID from developer.sirius.menu — enables analytics, managed keys, and script hosting

   ConfigurationSaving = {
      Enabled = true,
      FolderName = "Mis hud", -- Create a custom folder for your hub/game
      FileName = "Baddie Card Collection Card"
   },

   Discord = {
      Enabled = false, -- Prompt the user to join your Discord server if their executor supports it
      Invite = "noinvitelink", -- The Discord invite code, do not include Discord.gg/. E.g. Discord.gg/ABCD would be ABCD
      RememberJoins = true -- Set this to false to make them join the Discord every time they load it up
   },

   KeySystem = false, -- Set this to true to use our key system
   KeySettings = {
      Title = "Untitled",
      Subtitle = "Key System",
      Note = "No method of obtaining the key is provided", -- Use this to tell the user how to get a key
      FileName = "Key", -- It is recommended to use something unique, as other scripts using Rayfield may overwrite your key file
      SaveKey = true, -- The user's key will be saved, but if you change the key, they will be unable to use your script
      GrabKeyFromSite = false, -- If this is true, set Key below to the RAW site you would like Rayfield to get the key from
      Key = {"Hello"} -- List of keys that the system will accept, can be RAW file links (pastebin, github, etc.) or simple strings ("hello", "key22")
   }
})

local MainTab = Window:CreateTab("Main", 4483362458)
local SpinTab = Window:CreateTab("Spin", 4483362458)
local GradeTab = Window:CreateTab("Grade", 4483362458)
local PlaceTab = Window:CreateTab("Cards place", 4483362458)
local UpgradeTab = Window:CreateTab("Upgrade", 4483362458)
local DevTab = Window:CreateTab("Developer", 4483362458)

Rayfield:Notify({
   Title = "Baddie Collect",
   Content = "Made by DatFeite",
   Duration = 5,
   Image = 4483362458,
})

local Paragraph = MainTab:CreateParagraph({
    Title = "📊 Your Data",
    Content = "Loading..."
})

task.spawn(function()
    while true do
        local ok, err = pcall(function()
            local player = game.Players.LocalPlayer
            local lines = {}

            -- Cash
            local okCash, cash = pcall(function()
                return player.PlayerGui.CashGui.MainFrame.CashLabel.Text
            end)
            table.insert(lines, "💰 Cash: " .. (okCash and cash or "N/A"))

            -- Cash per second
            local okCps, cps = pcall(function()
                return player.PlayerGui:GetAttribute("ODS_CashPerSecond")
            end)
            local cpsFormatted = "N/A"
            if okCps and cps then
                if cps >= 1000000000 then cpsFormatted = string.format("%.2fB", cps / 1000000000)
                elseif cps >= 1000000 then cpsFormatted = string.format("%.2fM", cps / 1000000)
                elseif cps >= 1000 then cpsFormatted = string.format("%.2fK", cps / 1000)
                else cpsFormatted = tostring(cps) end
            end
            table.insert(lines, "📈 Cash/s: " .. cpsFormatted)

            -- Total cards
            local okTotal, total = pcall(function()
                return player.PlayerGui:GetAttribute("ODS_TotalCardsReceived")
            end)
            table.insert(lines, "🃏 Total Cards: " .. (okTotal and tostring(total) or "N/A"))

            -- Daily cards
            local okDaily, daily = pcall(function()
                return player.PlayerGui:GetAttribute("ODS_DailyTotalCardsReceived")
            end)
            table.insert(lines, "📅 Daily Cards: " .. (okDaily and tostring(daily) or "N/A"))

            -- Weekly tokens
            local okTokens, tokens = pcall(function()
                return player.PlayerGui:GetAttribute("ODS_WeeklyTokensCollected")
            end)
            table.insert(lines, "🪙 Weekly Tokens: " .. (okTokens and tostring(tokens) or "N/A"))

            -- Divider
            table.insert(lines, " ")
            table.insert(lines, "⚙️ ─── Upgrades ───")

            -- Upgrade levels
            local upgradeNames = {
                "RerollSpeed", "CraftingSlots", "PackTime",
                "PackLuck", "MaxPacks", "InventorySpace", "WalkSpeed", "VariantLuck"
            }
            local upgradeIcons = {
                RerollSpeed = "🔄",
                CraftingSlots = "🔨",
                PackTime = "⏱️",
                PackLuck = "🍀",
                MaxPacks = "📦",
                InventorySpace = "🎒",
                WalkSpeed = "👟",
                VariantLuck = "✨",
            }
            for _, upgradeName in ipairs(upgradeNames) do
                local okLvl, lvl = pcall(function()
                    local label = player.PlayerGui.UpgradesGui.MainFrame.ScrollingFrame[upgradeName]:FindFirstChild("LevelLabel", true)
                    return label and label.Text or "N/A"
                end)
                local icon = upgradeIcons[upgradeName] or "▸"
                table.insert(lines, icon .. " " .. upgradeName .. ": " .. (okLvl and tostring(lvl) or "N/A"))
            end

            Paragraph:Set({
                Title = "📊 Your Data",
                Content = table.concat(lines, "\n")
            })
        end)

        if not ok then
            print("Error: " .. tostring(err))
        end

        task.wait(1)
    end
end)

local running = true
local mainThread = coroutine.running()

local DestroyButton = MainTab:CreateButton({
    Name = "Destroy Script",
    Callback = function()
        running = false
        task.wait(0.2)
        Rayfield:Destroy()
    end,
})

local Button = SpinTab:CreateButton({
   Name = "Spin",
   Callback = function()
        game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("PackReroll"):FireServer()
   end,
})

local isSpinning = false
local isBuying = false
local selectedPackTypes = {}
local selectedVariants = {}

local packTypeOptions = {
    "ActivePack-Princess",
    "ActivePack-Queen",
    "ActivePack-Matriarch",
    "ActivePack-Empress",
    "ActivePack-Seraph",
    "ActivePack-Divine",
    "ActivePack-Celestial",
    "ActivePack-Goddess",
    "ActivePack-Valkyrie",
    "ActivePack-Aechon",
    "ActivePack-Eternal",
    "ActivePack-Radiant",
    "ActivePack-Beyond",
}

local variantOptions = {
    "Gold",
    "Platinum",
    "Emerald",
    "Diamond",
    "Rainbow",
    "Solaris",
    "Nebula",
    -- Add your actual variant names here
}

local function getActivePack(slotIndex)
    local player = game.Players.LocalPlayer
    local success, result = pcall(function()
        return workspace.Map.PlotModels[player.Name].Systems.ActivePackStation.Station.PackParts["Pack"..slotIndex]
    end)
    if not success or not result then return nil end
    for _, child in ipairs(result:GetChildren()) do
        if child.Name:sub(1, 11) == "ActivePack-" then
            return child.Name
        end
    end
    return nil
end

local function getActiveVariant(slotIndex, packName)
    local player = game.Players.LocalPlayer
    local success, result = pcall(function()
        return workspace.Map.PlotModels[player.Name].Systems.ActivePackStation.Station.PackParts["Pack"..slotIndex][packName].PackPriceBillboardGui.Frame.VariantLabel.Text
    end)
    if success and result then
        return result:match("^%s*(.-)%s*$") -- trim whitespace
    end
    return nil
end

local function isPackSelected(packName)
    for _, selected in ipairs(selectedPackTypes) do
        if selected == packName then
            return true
        end
    end
    return false
end

local function isVariantSelected(variant)
    if #selectedVariants == 0 then return true end -- if none selected, allow all
    for _, selected in ipairs(selectedVariants) do
        if selected == variant then
            return true
        end
    end
    return false
end

local function checkAndBuyAllSlots()
    for slot = 1, 4 do
        local activePack = getActivePack(slot)
        if activePack and isPackSelected(activePack) then
            local activeVariant = getActiveVariant(slot, activePack)
            print("Slot " .. slot .. " | Pack: " .. activePack .. " | Variant: " .. tostring(activeVariant))
            if isVariantSelected(activeVariant) then
                game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("PackPurchase"):FireServer(slot)
                task.wait(0.1)
            end
        end
    end
end

local Toggle = SpinTab:CreateToggle({
    Name = "Auto Spin",
    CurrentValue = false,
    Flag = "Spinning_auto",
    Callback = function(Spinning)
        isSpinning = Spinning
        if Spinning then
            task.spawn(function()
                while isSpinning and running do
                    game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("PackReroll"):FireServer()
                    task.wait(0.3)
                end
            end)
        end
    end,
})

local PackTypeDropdown = SpinTab:CreateDropdown({
    Name = "Buy When Pack Is",
    Options = packTypeOptions,
    CurrentOption = {},
    MultipleOptions = true,
    Flag = "SelectedPackTypes",
    Callback = function(selected)
        selectedPackTypes = selected
    end,
})

local VariantDropdown = SpinTab:CreateDropdown({
    Name = "Buy When Variant Is",
    Options = variantOptions,
    CurrentOption = {},
    MultipleOptions = true,
    Flag = "SelectedVariants",
    Callback = function(selected)
        selectedVariants = selected
    end,
})

local BuyToggle = SpinTab:CreateToggle({
    Name = "Auto Buy Pack",
    CurrentValue = false,
    Flag = "BuyPack_auto",
    Callback = function(Buying)
        isBuying = Buying
        if Buying then
            task.spawn(function()
                while isBuying and running do
                    checkAndBuyAllSlots()
                    task.wait(0.5)
                end
            end)
        end
    end,
})


local isCollect = false

local function getBinderCards(side)
    local player = game.Players.LocalPlayer
    local success, result = pcall(function()
        return workspace.Map.PlotModels[player.Name].Systems.Binder[side]
    end)
    if not success or not result then return {} end

    local cards = {}
    for _, slot in ipairs(result:GetChildren()) do
        local ok, cardAttr = pcall(function()
            return slot:GetAttribute("Card")
        end)
        if ok and cardAttr and cardAttr ~= "" then
            table.insert(cards, cardAttr)
        end
    end
    return cards
end

local function goToPage(pageNumber)
    game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("BinderPageProgress"):FireServer(pageNumber)
    task.wait(0.5)
end

local function collectAllCards()
    local page = 1

    while isCollect and running do
        goToPage(page)

        -- Collect from both sides on this page
        local foundAnyCard = false
        for _, side in ipairs({"Left", "Right"}) do
            local cards = getBinderCards(side)
            for _, cardName in ipairs(cards) do
                if not isCollect or not running then return end
                foundAnyCard = true
                print("Collecting: " .. cardName .. " (Page " .. page .. ")")
                game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("CollectCardCash"):FireServer(cardName)
                task.wait(0.3)
            end
        end

        -- If no cards found on this page we've reached the end
        if not foundAnyCard then
            print("No cards found on page " .. page .. " — going back to page 1")
            goToPage(1)
            break
        end

        page = page + 1
    end
end

local Toggle = MainTab:CreateToggle({
    Name = "Auto Collecting",
    CurrentValue = false,
    Flag = "Collecting_Auto",
    Callback = function(Collecting)
        isCollect = Collecting
        if Collecting then
            task.spawn(function()
                while isCollect and running do
                    collectAllCards()
                    task.wait(3)
                end
            end)
        end
    end,
})

local DebugButton = DevTab:CreateButton({
    Name = "Debug Binder",
    Callback = function()
        local player = game.Players.LocalPlayer
        local binder = workspace.Map.PlotModels[player.Name].Systems.Binder
        
        -- Print all attributes
        print("=== Binder Attributes ===")
        for k, v in pairs(binder:GetAttributes()) do
            print(k .. " = " .. tostring(v))
        end

        -- Check click detector path
        print("=== Checking ClickDetector ===")
        local success, cd = pcall(function()
            return workspace.Map.PlotModels[player.Name].Systems.Binder.Right.NextPageModel.RightButton.ClickDetector
        end)
        print("ClickDetector found: " .. tostring(success))
        if success then
            print("ClickDetector: " .. tostring(cd))
        end

        -- Print Right children
        print("=== Right children ===")
        for _, child in ipairs(binder.Right:GetChildren()) do
            print(child.Name .. " | Class: " .. child.ClassName)
        end

        -- Print all children of binder
        print("=== Binder children ===")
        for _, child in ipairs(binder:GetChildren()) do
            print(child.Name .. " | Class: " .. child.ClassName)
        end
    end,
})

local DebugButton2 = DevTab:CreateButton({
    Name = "Debug Binder 2",
    Callback = function()
        local player = game.Players.LocalPlayer
        local binder = workspace.Map.PlotModels[player.Name].Systems.Binder

        -- Check PagePart
        print("=== PagePart ===")
        local pagePart = binder:FindFirstChild("PagePart")
        if pagePart then
            print("PagePart found")
            for k, v in pairs(pagePart:GetAttributes()) do
                print("  Attr: " .. k .. " = " .. tostring(v))
            end
            for _, child in ipairs(pagePart:GetChildren()) do
                print("  Child: " .. child.Name .. " | Class: " .. child.ClassName)
                -- If it has a TextLabel or similar, print Text
                local ok, text = pcall(function() return child.Text end)
                if ok then print("    Text: " .. tostring(text)) end
            end
        end

        -- Check NextPageModel deeper
        print("=== NextPageModel children ===")
        local npm = binder.Right:FindFirstChild("NextPageModel")
        if npm then
            for _, child in ipairs(npm:GetDescendants()) do
                print("  " .. child.Name .. " | Class: " .. child.ClassName)
            end
        end

        -- Check Left for PrevPageModel
        print("=== Left children ===")
        for _, child in ipairs(binder.Left:GetChildren()) do
            print(child.Name .. " | Class: " .. child.ClassName)
        end
    end,
})

local DebugButton5 = DevTab:CreateButton({
    Name = "Debug Upgrades",
    Callback = function()
        local player = game.Players.LocalPlayer

        print("=== PlayerGui / leaderstats ===")
        -- Check leaderstats
        local ok, ls = pcall(function() return player.leaderstats end)
        if ok and ls then
            for _, stat in ipairs(ls:GetChildren()) do
                print("  " .. stat.Name .. " = " .. tostring(stat.Value))
            end
        else
            print("  No leaderstats found")
        end

        -- Check PlayerData or similar in player
        print("=== Player children ===")
        for _, child in ipairs(player:GetChildren()) do
            print(child.Name .. " | Class: " .. child.ClassName)
            for k, v in pairs(child:GetAttributes()) do
                print("  Attr: " .. k .. " = " .. tostring(v))
            end
        end

        -- Check Systems for upgrade/currency info
        print("=== Systems attributes ===")
        local sys = workspace.Map.PlotModels[player.Name].Systems
        for k, v in pairs(sys:GetAttributes()) do
            print("  " .. k .. " = " .. tostring(v))
        end

        -- Check for upgrade levels
        print("=== Systems children attributes ===")
        for _, child in ipairs(sys:GetChildren()) do
            local attrs = child:GetAttributes()
            local hasAttrs = false
            for k, v in pairs(attrs) do
                if not hasAttrs then
                    print("  [" .. child.Name .. "]")
                    hasAttrs = true
                end
                print("    " .. k .. " = " .. tostring(v))
            end
        end
    end,
})

local DebugButton6 = DevTab:CreateButton({
    Name = "Debug Upgrades 2",
    Callback = function()
        local player = game.Players.LocalPlayer

        -- Check leaderstats fully
        print("=== Leaderstats ===")
        for _, stat in ipairs(player.leaderstats:GetChildren()) do
            print("  " .. stat.Name .. " = " .. tostring(stat.Value))
        end

        -- Check PlayerGui for any cash display
        print("=== PlayerGui children ===")
        for _, gui in ipairs(player.PlayerGui:GetChildren()) do
            print(gui.Name .. " | Class: " .. gui.ClassName)
        end

        -- Check Backpack attributes
        print("=== Backpack attributes ===")
        for k, v in pairs(player.Backpack:GetAttributes()) do
            print("  " .. k .. " = " .. tostring(v))
        end

        -- Check StarterGear
        print("=== StarterGear attributes ===")
        local ok, sg = pcall(function() return player.StarterGear end)
        if ok and sg then
            for k, v in pairs(sg:GetAttributes()) do
                print("  " .. k .. " = " .. tostring(v))
            end
        end

        -- Look for upgrade info in Systems children deeper
        print("=== Systems deep search ===")
        local sys = workspace.Map.PlotModels[player.Name].Systems
        for _, child in ipairs(sys:GetChildren()) do
            print("[" .. child.Name .. "]")
            for _, desc in ipairs(child:GetDescendants()) do
                if desc:IsA("StringValue") or desc:IsA("IntValue") or desc:IsA("NumberValue") then
                    print("  " .. desc.Name .. " = " .. tostring(desc.Value))
                end
                local attrs = desc:GetAttributes()
                for k, v in pairs(attrs) do
                    print("  " .. desc.Name .. "." .. k .. " = " .. tostring(v))
                end
            end
        end
    end,
})

local DebugButton7 = DevTab:CreateButton({
    Name = "Debug Upgrade Cost Text",
    Callback = function()
        local player = game.Players.LocalPlayer
        local scrollFrame = player.PlayerGui.UpgradesGui.MainFrame.ScrollingFrame

        print("=== Raw upgrade cost texts ===")
        for _, upgrade in ipairs(scrollFrame:GetChildren()) do
            local ok, title = pcall(function()
                return upgrade.CashButton.Title.Text
            end)
            if ok then
                print(upgrade.Name .. ": '" .. tostring(title) .. "'")
            end
        end

        print("=== Raw cash text ===")
        local ok, cash = pcall(function()
            return player.PlayerGui.CashGui.MainFrame.CashLabel.Text
        end)
        if ok then
            print("Cash: '" .. tostring(cash) .. "'")
        end
    end,
})

local DebugButton8 = DevTab:CreateButton({
    Name = "Debug Upgrade Levels",
    Callback = function()
        local player = game.Players.LocalPlayer
        local scrollFrame = player.PlayerGui.UpgradesGui.MainFrame.ScrollingFrame

        print("=== Upgrade GUI children ===")
        for _, upgrade in ipairs(scrollFrame:GetChildren()) do
            print("[" .. upgrade.Name .. "]")
            for _, child in ipairs(upgrade:GetDescendants()) do
                -- Look for any level/text display
                local ok, text = pcall(function() return child.Text end)
                if ok and text ~= "" then
                    print("  " .. child.Name .. ": '" .. tostring(text) .. "'")
                end
                -- Check attributes
                for k, v in pairs(child:GetAttributes()) do
                    print("  Attr: " .. k .. " = " .. tostring(v))
                end
            end
        end
    end,
})

local isGradeRolling = false
local targetGrades = {}
local targetCardName = ""

local gradeOptions = {
    "F", "E", "D", "C", "B", "A", "S", "X", "SS"
}

local function isTargetGrade(grade)
    for _, g in ipairs(targetGrades) do
        if g == grade then
            return true
        end
    end
    return false
end

local function getBinderCards()
    local player = game.Players.LocalPlayer
    local binder = workspace.Map.PlotModels[player.Name].Systems.Binder
    local cards = {}

    for _, side in ipairs({binder.Left, binder.Right}) do
        for _, slot in ipairs(side:GetChildren()) do
            local success, cardAttr = pcall(function()
                return slot:GetAttribute("Card")
            end)
            if success and cardAttr and cardAttr ~= "" then
                table.insert(cards, cardAttr)
            end
        end
    end

    return cards
end

local function findCardSlot()
    local player = game.Players.LocalPlayer
    local binder = workspace.Map.PlotModels[player.Name].Systems.Binder

    for _, side in ipairs({binder.Left, binder.Right}) do
        for _, slot in ipairs(side:GetChildren()) do
            local success, cardAttr = pcall(function()
                return slot:GetAttribute("Card")
            end)
            if success and cardAttr then
                if cardAttr:lower() == targetCardName:lower() then
                    return slot
                end
            end
        end
    end

    return nil
end

local function getCardGrade()
    local slot = findCardSlot()
    if not slot then
        print("Card not found: " .. targetCardName)
        return nil
    end

    local success, grade = pcall(function()
        return slot.BaseSurfaceGui.BaseCardFrame.ImageLabel.GradeLabel.Text
    end)

    if success and grade then
        return grade:match("^%s*(.-)%s*$")
    end

    return nil
end

local GradeDropdown = GradeTab:CreateDropdown({
    Name = "Stop Rolling On Grade",
    Options = gradeOptions,
    CurrentOption = {},
    MultipleOptions = true,
    Flag = "TargetGrades",
    Callback = function(selected)
        targetGrades = selected
    end,
})

local cardList = getBinderCards()

local CardDropdown = GradeTab:CreateDropdown({
    Name = "Target Card",
    Options = cardList,
    CurrentOption = {},
    MultipleOptions = false,
    Flag = "TargetCardName",
    Callback = function(selected)
        targetCardName = selected[1] or ""
        print("Targeting card: " .. targetCardName)
    end,
})

local RefreshButton = GradeTab:CreateButton({
    Name = "Refresh Card List",
    Callback = function()
        local newCards = getBinderCards()
        CardDropdown:Refresh(newCards, {})
        print("Card list refreshed: " .. #newCards .. " cards found")
    end,
})

local CourencyGradeReroll = "GradeReroll"

local GradeRerollMethode = GradeTab:CreateDropdown({
   Name = "Which Currency",
   Options = {"Money", "Tokens"},
   CurrentOption = {"Money"},
   MultipleOptions = false,
   Flag = "GradeCourency",

   Callback = function(Courency2)

        print("changed Currency:", Courency2[1])

        if Courency2[1] == "Money" then
            CourencyGradeReroll = "GradeReroll"
        else
            CourencyGradeReroll = "GradeRerollToken"
        end
   end,
})


local Toggle = GradeTab:CreateToggle({
    Name = "Auto Grade Rolling",
    CurrentValue = false,
    Flag = "GradeRolling_Auto",
    Callback = function(Rolling)
        isGradeRolling = Rolling
        if Rolling then
            task.spawn(function()
                while isGradeRolling and running do
                    game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild(CourencyGradeReroll):FireServer(targetCardName)
                    task.wait(0.3)
                    local currentGrade = getCardGrade()
                    print("Current grade on " .. targetCardName .. ": " .. tostring(currentGrade))
                    if currentGrade and isTargetGrade(currentGrade) then
                        print("Target grade found: " .. tostring(currentGrade) .. " — stopping.")
                        isGradeRolling = false
                        break
                    end
                end
            end)
        end
    end,
})

local function debugCardSlot()
    local player = game.Players.LocalPlayer
    local binder = workspace.Map.PlotModels[player.Name].Systems.Binder

    for _, side in ipairs({binder.Left, binder.Right}) do
        for _, slot in ipairs(side:GetChildren()) do
            local success, cardAttr = pcall(function()
                return slot:GetAttribute("Card")
            end)
            print("Slot: " .. slot.Name .. " | Card attribute: " .. tostring(cardAttr))

            -- Try to find GradeLabel and print ALL its properties
            local gradeLabel = slot:FindFirstChild("BaseSurfaceGui", true)
            if gradeLabel then
                local gl = gradeLabel.Parent:FindFirstChild("BaseSurfaceGui")
                if gl then
                    local found = gl:FindFirstChild("GradeLabel", true)
                    if found then
                        print("  GradeLabel found!")
                        print("  Text: " .. tostring(found.Text))
                        print("  ContextText: " .. tostring(found.ContextText))
                        for _, prop in ipairs({"Text", "ContextText", "PlaceholderText"}) do
                            local ok, val = pcall(function() return found[prop] end)
                            if ok then
                                print("  " .. prop .. " = " .. tostring(val))
                            end
                        end
                    else
                        print("  No GradeLabel found in BaseSurfaceGui")
                    end
                end
            else
                print("  No BaseSurfaceGui found in slot")
            end
        end
    end
end

-- Add this button to trigger the debug scan
local DebugButton = DevTab:CreateButton({
    Name = "Debug Card Slots",
    Callback = function()
        debugCardSlot()
    end,
})




local DebugButton3 = DevTab:CreateButton({
    Name = "Debug Placed Packs",
    Callback = function()
        local player = game.Players.LocalPlayer
        
        print("=== PlacedPacks children ===")
        local success, placedPacks = pcall(function()
            return workspace.Map.PlotModels[player.Name].Systems.PlacedPacks
        end)
        
        if not success or not placedPacks then
            print("PlacedPacks not found!")
            return
        end

        for _, pack in ipairs(placedPacks:GetChildren()) do
            print("Pack: " .. pack.Name .. " | Class: " .. pack.ClassName)
            -- Print all attributes
            for k, v in pairs(pack:GetAttributes()) do
                print("  Attr: " .. k .. " = " .. tostring(v))
            end
            -- Print children
            for _, child in ipairs(pack:GetDescendants()) do
                if child:IsA("ClickDetector") then
                    print("  ClickDetector at: " .. child:GetFullName())
                end
            end
        end

        -- Also check what's currently held/equipped
        print("=== Checking EquippedPack ===")
        local sys = workspace.Map.PlotModels[player.Name].Systems
        for k, v in pairs(sys:GetAttributes()) do
            print("  Attr: " .. k .. " = " .. tostring(v))
        end
    end,
})


local isAutoPlacing = false
local selectedPlacePack = "Princess"
local selectedPlaceVariant = "Normal"
local selectedPlaceMutation = "None"

local placePackOptions = {
    "Princess", "Queen", "Matriarch", "Empress", "Seraph",
    "Divine", "Celestial", "Goddess", "Valkyrie", "Aechon",
    "Eternal", "Radiant", "Beyond"
}

local placeVariantOptions = {
    "Gold", "Platinum", "Emerald", "Diamond", "Rainbow", "Solaris", "Nebula"
}

local placeMutationOptions = {
    "None", "💰 Cheap", "🍀 Lucky", "⌛ Fast Unbox"
}

local function collectPlacedPacks()
    local player = game.Players.LocalPlayer
    local success, placedPacks = pcall(function()
        return workspace.Map.PlotModels[player.Name].Systems.PlacedPacks
    end)
    if not success or not placedPacks then return end

    for _, pack in ipairs(placedPacks:GetChildren()) do
        local okName, packName = pcall(function() return pack:GetAttribute("PackName") end)
        local okVariant, variant = pcall(function() return pack:GetAttribute("Variant") end)
        local okMutation, mutation = pcall(function() return pack:GetAttribute("Mutation") end)
        local okOwner, owner = pcall(function() return pack:GetAttribute("Owner") end)

        if okOwner and owner == player.Name then
            local nameMatch = not okName or packName == selectedPlacePack
            local variantMatch = not okVariant or variant == selectedPlaceVariant
            local mutationMatch = not okMutation or mutation == selectedPlaceMutation

            if nameMatch and variantMatch and mutationMatch then
                print("Collecting pack: " .. pack.Name .. " | " .. tostring(packName) .. " | " .. tostring(variant))
                game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("CollectHeldPack"):FireServer(pack.Name)
                task.wait(0.3)
            end
        end
    end
end

local function autoPlaceLoop()
    while isAutoPlacing and running do
        -- Equip the pack
        game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("EquipPackTool"):FireServer(
            selectedPlacePack,
            selectedPlaceVariant,
            selectedPlaceMutation
        )
        task.wait(0.5)

        -- Collect placed packs
        collectPlacedPacks()
        task.wait(0.3)

        -- Unequip after collecting
        game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("UnequipPackTool"):FireServer()
        task.wait(0.3)
    end
end

local PlacePackDropdown = PlaceTab:CreateDropdown({
    Name = "Pack To Place ",
    Options = placePackOptions,
    CurrentOption = {"Princess"},
    MultipleOptions = false,
    Flag = "PlacePackName",
    Callback = function(selected)
        selectedPlacePack = selected[1] or "Princess"
    end,
})

local PlaceVariantDropdown = PlaceTab:CreateDropdown({
    Name = "Pack Variant #Not Workin!",
    Options = placeVariantOptions,
    CurrentOption = {"Normal"},
    MultipleOptions = false,
    Flag = "PlacePackVariant",
    Callback = function(selected)
        selectedPlaceVariant = selected[1] or "Normal"
    end,
})

local PlaceMutationDropdown = PlaceTab:CreateDropdown({
    Name = "Pack Mutation #Not Workin!",
    Options = placeMutationOptions,
    CurrentOption = {"None"},
    MultipleOptions = false,
    Flag = "PlacePackMutation",
    Callback = function(selected)
        selectedPlaceMutation = selected[1] or "None"
    end,
})

local PlaceToggle = PlaceTab:CreateToggle({
    Name = "Auto Place Packs",
    CurrentValue = false,
    Flag = "AutoPlace_Toggle",
    Callback = function(Placing)
        isAutoPlacing = Placing
        if Placing then
            task.spawn(autoPlaceLoop)
        end
    end,
})

local DebugButton4 = DevTab:CreateButton({
    Name = "Debug Unequip",
    Callback = function()
        local player = game.Players.LocalPlayer
        local sys = workspace.Map.PlotModels[player.Name].Systems

        print("=== Systems children ===")
        for _, child in ipairs(sys:GetChildren()) do
            print(child.Name .. " | Class: " .. child.ClassName)
            for k, v in pairs(child:GetAttributes()) do
                print("  Attr: " .. k .. " = " .. tostring(v))
            end
        end

        print("=== Checking ActivePackStation ===")
        local success, station = pcall(function()
            return sys.ActivePackStation
        end)
        if success and station then
            for _, child in ipairs(station:GetDescendants()) do
                print(child.Name .. " | Class: " .. child.ClassName)
                for k, v in pairs(child:GetAttributes()) do
                    print("  Attr: " .. k .. " = " .. tostring(v))
                end
            end
        end

        print("=== Remotes ===")
        for _, remote in ipairs(game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):GetChildren()) do
            print(remote.Name .. " | Class: " .. remote.ClassName)
        end
    end,
})





local isAutoUpgrading = false

local upgradeOptions = {
    "RerollSpeed",
    "CraftingSlots",
    "PackTime",
    "PackLuck",
    "MaxPacks",
    "InventorySpace",
    "WalkSpeed",
    "VariantLuck",
}

local selectedUpgrades = {}

local upgradeLevelCaps = {} -- stores target level per upgrade

local function parseAmount(text)
    text = text:gsub("%$", ""):gsub("%s", "")
    local num, suffix = text:match("^([%d%.]+)([KMBkmb]?)$")
    num = tonumber(num) or 0
    suffix = suffix:upper()
    if suffix == "K" then return num * 1000
    elseif suffix == "M" then return num * 1000000
    elseif suffix == "B" then return num * 1000000000
    end
    return num
end

local function getCash()
    local success, result = pcall(function()
        return game:GetService("Players").LocalPlayer.PlayerGui.CashGui.MainFrame.CashLabel.Text
    end)
    if success and result then
        return parseAmount(result)
    end
    return 0
end

local function getUpgradeCost(upgradeName)
    local success, result = pcall(function()
        return game:GetService("Players").LocalPlayer.PlayerGui.UpgradesGui.MainFrame.ScrollingFrame[upgradeName].CashButton.Title.Text
    end)
    if success and result then
        return parseAmount(result)
    end
    return math.huge
end

local function getUpgradeLevel(upgradeName)
    local success, result = pcall(function()
        local upgrade = game:GetService("Players").LocalPlayer.PlayerGui.UpgradesGui.MainFrame.ScrollingFrame[upgradeName]
        -- Search all descendants for LevelLabel
        local label = upgrade:FindFirstChild("LevelLabel", true)
        if label then
            return label.Text
        end
        return nil
    end)
    if success and result then
        local level = result:match("Lv%.%s*(%d+)")
        return tonumber(level) or 0
    end
    return 0
end

local function autoUpgradeLoop()
    while isAutoUpgrading and running do
        local cash = getCash()
        local anyUpgradeLeft = false

        for _, upgradeName in ipairs(selectedUpgrades) do
            if not isAutoUpgrading or not running then break end

            local currentLevel = getUpgradeLevel(upgradeName)
            local targetLevel = upgradeLevelCaps[upgradeName] or math.huge
            local cost = getUpgradeCost(upgradeName)

            print(upgradeName .. " | Level: " .. currentLevel .. "/" .. tostring(targetLevel) .. " | Cost: " .. tostring(cost) .. " | Cash: " .. tostring(cash))

            if currentLevel >= targetLevel then
                print(upgradeName .. " already at target level " .. tostring(targetLevel) .. " — skipping")
            elseif cash >= cost then
                print("Purchasing upgrade: " .. upgradeName)
                game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("PurchaseUpgrade"):FireServer(upgradeName)
                task.wait(0.5)
                cash = getCash()
                anyUpgradeLeft = true
            else
                print("Not enough cash for " .. upgradeName)
                anyUpgradeLeft = true
            end
        end

        task.wait(1)
    end
end

local UpgradeDropdown = UpgradeTab:CreateDropdown({
    Name = "Auto Upgrade",
    Options = upgradeOptions,
    CurrentOption = {},
    MultipleOptions = true,
    Flag = "SelectedUpgrades",
    Callback = function(selected)
        selectedUpgrades = selected
    end,
})

-- One input per upgrade for target level
for _, upgradeName in ipairs(upgradeOptions) do
    UpgradeTab:CreateInput({
        Name = upgradeName .. " Target Level",
        PlaceholderText = "e.g. 10 (leave empty for no cap)",
        RemoveTextAfterFocusLost = false,
        Flag = "TargetLevel_" .. upgradeName,
        Callback = function(text)
            local level = tonumber(text:match("%d+"))
            if level then
                upgradeLevelCaps[upgradeName] = level
                print(upgradeName .. " target level set to: " .. level)
            else
                upgradeLevelCaps[upgradeName] = nil
                print(upgradeName .. " target level cleared (unlimited)")
            end
        end,
    })
end

local UpgradeToggle = UpgradeTab:CreateToggle({
    Name = "Auto Purchase Upgrades",
    CurrentValue = false,
    Flag = "AutoUpgrade_Toggle",
    Callback = function(Upgrading)
        isAutoUpgrading = Upgrading
        if Upgrading then
            task.spawn(autoUpgradeLoop)
        end
    end,
})
