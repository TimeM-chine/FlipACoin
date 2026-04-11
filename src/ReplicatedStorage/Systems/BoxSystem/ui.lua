---- services ----
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")

---- requires ----
local SystemMgr = require(Replicated.Systems.SystemMgr)
local ClientData = require(Replicated.Systems.ClientData)
local Keys = require(Replicated.configs.Keys)
local Textures = require(Replicated.configs.Textures)
local BoxPresets = require(script.Parent.Presets)
local EcoPresets = require(Replicated.Systems.EcoSystem.Presets)
local Util = require(Replicated.modules.Util)
local Zone = require(Replicated.modules.Zone)
local GameConfig = require(Replicated.configs.GameConfig)

---- ui variables ----
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Main = PlayerGui:WaitForChild("Main")
local uiController = require(Main:WaitForChild("uiController"))

---- logic variables ----
local BoxesFolder = workspace:WaitForChild("Boxes")

local BoxUi = {}

function BoxUi.Init()
	-- InitGroupBox()
	-- InitStoreBox()
	-- InitPremiumBox()
	-- InitNPC()
	-- InitGolden()
	-- InitShiny()
	-- InitPetIndex()
	InitGamePassBox()
end

function BoxUi.ClaimGroupReward()
	local groupModel = BoxesFolder:WaitForChild("Group")
	local groupGui = groupModel:WaitForChild("BillboardGui")

	uiController.AddTimerLabel({
		textLabel = groupGui.Frame.timer,
		duration = BoxPresets.GroupGiftTime,
		callback = function()
			groupGui.Frame.timer.Text = "CLAIM!"
		end,
	})
end

function InitGroupBox()
	local groupModel = BoxesFolder:WaitForChild("Group")
	local groupBox = groupModel:WaitForChild("Container")
	local zone = Zone.new(groupBox)
	zone.localPlayerEntered:Connect(function()
		if LocalPlayer:IsInGroup(GameConfig.GroupId) then
			SystemMgr.systems.BoxSystem.Server:TryClaimGroupReward()
		else
			uiController.SetNotification({
				text = "👍Like game and join our group to get rewards!",
			})
		end
	end)

	local groupGui = groupModel:WaitForChild("BillboardGui")
	local groupClaim = ClientData:GetOneData(Keys.DataKey.groupClaim)
	local timeGap = os.time() - groupClaim + 3
	if timeGap > BoxPresets.GroupGiftTime then
		groupGui.Frame.timer.Text = "CLAIM!"
	else
		uiController.AddTimerLabel({
			textLabel = groupGui.Frame.timer,
			duration = BoxPresets.GroupGiftTime - timeGap,
			callback = function()
				groupGui.Frame.timer.Text = "CLAIM!"
			end,
		})
	end

	local rewardScroll = groupGui.Frame.ScrollingFrame
	local template = rewardScroll:WaitForChild("Template")
	template.Visible = false
	for _, reward in ipairs(BoxPresets.GroupRewardList) do
		Util.Clone(template, rewardScroll, function(unit)
			unit.Visible = true
			unit.icon.Image = Textures.GetIcon(reward)
			unit.count.Text = "??%"
		end)
	end
end

function InitPremiumBox()
	local premiumModel = BoxesFolder:WaitForChild("Premium")
	local premiumBox = premiumModel:WaitForChild("Container")
	local zone = Zone.new(premiumBox)
	zone.localPlayerEntered:Connect(function()
		uiController.SetNotification({
			text = "Premium members enjoy a 10% reward bonus!",
		})
		if not LocalPlayer.MembershipType == Enum.MembershipType.Premium then
			MarketplaceService:PromptPremiumPurchase(LocalPlayer)
		end
	end)
end

function InitNPC()
	local Kyoujurou = BoxesFolder:WaitForChild("Kyoujurou"):WaitForChild("Container")
	local kZone = Zone.new(Kyoujurou)
	kZone.localPlayerEntered:Connect(function()
		MarketplaceService:PromptProductPurchase(LocalPlayer, EcoPresets.Products.pet.Kyoujurou.productId)
	end)
end

function InitGolden()
	local Golden = BoxesFolder:WaitForChild("Golden"):WaitForChild("Container")
	local gZone = Zone.new(Golden)
	gZone.localPlayerEntered:Connect(function()
		uiController.OpenFrame("Golden")
	end)

	gZone.localPlayerExited:Connect(function()
		uiController.CloseFrame("Golden")
	end)
end

function InitShiny()
	local shiny = BoxesFolder:WaitForChild("Shiny"):WaitForChild("Container")
	local sZone = Zone.new(shiny)
	sZone.localPlayerEntered:Connect(function()
		uiController.OpenFrame("Shiny")
	end)

	sZone.localPlayerExited:Connect(function()
		uiController.CloseFrame("Shiny")
	end)
end

function InitPetIndex()
	local petIndex = BoxesFolder:WaitForChild("PetIndex"):WaitForChild("Container")
	local pZone = Zone.new(petIndex)
	pZone.localPlayerEntered:Connect(function()
		uiController.OpenFrame("PetIndex")
	end)

	pZone.localPlayerExited:Connect(function()
		uiController.CloseFrame("PetIndex")
	end)
end

function InitStoreBox()
	local storeModel = BoxesFolder:WaitForChild("Store")
	local storeBox = storeModel:WaitForChild("Container")
	local zone = Zone.new(storeBox)
	zone.localPlayerEntered:Connect(function()
		uiController.OpenFrame("Store")
	end)

	local gradient = storeModel
		:WaitForChild("PartSpec")
		:WaitForChild("BillboardGui")
		:WaitForChild("Frame")
		:WaitForChild("Text")
		:WaitForChild("Text")
		:WaitForChild("UIGradient")
	uiController.AddRotateGradient(gradient)
end

function InitGamePassBox()
	local onGamePasses = { "vip", "winsX2", "damageX2", "digLucky" }
	local gamePasses = ClientData:GetOneData(Keys.DataKey.gamePasses)
	for _, name in ipairs(onGamePasses) do
		local boxModel = BoxesFolder:WaitForChild(name)
		local iconPart = boxModel:WaitForChild("iconPart")
		iconPart:WaitForChild("BackSG"):WaitForChild("ImageLabel").Image = Textures.GamePasses[name].icon
		iconPart:WaitForChild("FrontSG"):WaitForChild("ImageLabel").Image = Textures.GamePasses[name].icon
		local prompt = boxModel:WaitForChild("Prompt")
		prompt:WaitForChild("info"):WaitForChild("TextLabel").Text = EcoPresets.GamePasses[name].description
		if gamePasses[name] then
			prompt:WaitForChild("price"):WaitForChild("TextLabel").Text = "Owned"
		else
			local proximityPrompt = Instance.new("ProximityPrompt")
			proximityPrompt.ActionText = "Buy"
			proximityPrompt.Parent = prompt
			proximityPrompt.Triggered:Connect(function()
				MarketplaceService:PromptGamePassPurchase(LocalPlayer, EcoPresets.GamePasses[name].gamePassId)
			end)

			prompt:WaitForChild("price"):WaitForChild("TextLabel").Text =
				Util.GetRobuxText(EcoPresets.GamePasses[name].price)
			prompt:WaitForChild("info"):WaitForChild("TextLabel").Text = EcoPresets.GamePasses[name].description
		end
	end
end

return BoxUi
