local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local RootPart = Character:WaitForChild("HumanoidRootPart")

local function isInTable(value, tbl)
    for _, v in ipairs(tbl) do
        if v == value then
            return true
        end
    end
    return false
end

fireproximityprompt(Prompt)

firetouchinterest(RootPart, CollectPart, 0)
task.wait(0.08)
firetouchinterest(RootPart, CollectPart, 1)

firesignal(Path.Activated)

Character:MoveTo(v.WorldPivot.Position + Vector3.new(0, 3, 0))

RootPart.CFrame = CFrame.new(v.Position + Vector3.new(0, 3, 0))

