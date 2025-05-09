local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = require(ReplicatedStorage.Library.Client.Network)
local ItemLib = require(ReplicatedStorage.Library.Items.CatchItem)
local Message = require(ReplicatedStorage.Library.Client.Message)
local fishingModule = require(ReplicatedStorage.Library.Client.EventFishingCmds)
local FishGame = require(ReplicatedStorage.Library.Client.EventFishingCmds.Game)
local localPlayer = Players.LocalPlayer

if not FishGame.BeginOld then
    FishGame.BeginOld = FishGame.Begin
end
FishGame.Begin = function(arg1, arg2, arg3)
    arg2.BarSize = 1
    return FishGame.BeginOld(arg1, arg2, arg3)
end
local function getCastPosition()
    local character = localPlayer.Character
    if character then
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if hrp then
            return hrp.Position + Vector3.new(0, -2, -10)
        end
    end
    return nil
end
local function autoFish()
    local castPosition = getCastPosition()
    if castPosition then
        fishingModule.LocalCast(castPosition)
    end
end
local function autoSellIfNeeded()
    local allFish = {}
    for itemId in pairs(ItemLib:All()) do
        table.insert(allFish, itemId)
    end

    if #allFish >= 40 then
        local success, result = pcall(function()
            return Network.Invoke("FishingEvent_Sell", allFish)
        end)

        if success then
            print("["..os.date("%X").."] Sold fish. Earnings:", result)
            Message.Notify("Fish Sale", "All fish sold!\nEarnings: "..tostring(result), "rbxassetid://7191623276")
        else
            warn("["..os.date("%X").."] Sell error:", result)
            Message.Error(result)
        end
    end
end
while true do
    autoFish()
    autoSellIfNeeded()
    task.wait(1.5)
end
