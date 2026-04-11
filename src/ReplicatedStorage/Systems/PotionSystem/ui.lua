---- services ----
local Players = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

---- requires ----
local SystemMgr = require(Replicated.Systems.SystemMgr)
local ClientData = require(Replicated.Systems.ClientData)
local Keys = require(Replicated.configs.Keys)
local dataKey = Keys.DataKey
local PotionPresets = require(script.Parent.PotionPresets)
local Util = require(Replicated.modules.Util)

---- ui variables ----
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Main = PlayerGui:WaitForChild("Main")
local uiController = require(Main:WaitForChild("uiController"))
local Frames = Main:WaitForChild("Frames")
local StoreFrame = Frames:WaitForChild("Store")
local storeScroll = StoreFrame:WaitForChild("ScrollingFrame")

---- logic variables ----
local PotionUi = {}

function PotionUi.Init() end

function PotionUi.UpdatePotionCount()
	local potions = ClientData:GetOneData(dataKey.potions)
	local potionsFrame = storeScroll:WaitForChild("Potions")

	for potionName, count in potions do
		local card = potionsFrame:FindFirstChild(potionName)
		local own = potions[potionName] or 0
		card.use.TextLabel.Text = `Use({own})`
	end
end

return PotionUi
