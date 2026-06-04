--[[
--Author: TimeM_chine
--Created Date: Mon Feb 26 2024
--Description: init.lua
--Version: 1.1
--Last Modified: 2024-05-17 7:59:06
--]]
---- services ----
local Players = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")

---- requires ----
local EcoPresets = require(script.Presets)
local GameConfig = require(Replicated.configs.GameConfig)
local Types = require(Replicated.configs.Types)
-- local GAModule = require(Replicated.modules.GAModule)
local Textures = require(Replicated.configs.Textures)
local Keys = require(Replicated.configs.Keys)
local dataKey = Keys.DataKey
local ItemType = Keys.ItemType

---- common variables ----
local IsServer = RunService:IsServer()
local SENDER, SystemMgr

---- server variables ----
local PlayerServerClass, purchaseHistoryStore, DataStoreService, GlobalDataModule, AnalyticsService, AdService
local productFunctions = {}
local gamePassFunctions = {}
local rewardedAdCooldowns = {}
local rewardedAdInFlight = {}
local rewardedAdAvailabilityReports = {}
local rewardedAdProductRegistered = false

---- client variables ----
local LocalPlayer, ClientData
local EcoUi = { pendingCalls = {} }
setmetatable(EcoUi, Types.mt)

local EcoSystem: Types.System = {
	whiteList = {
		"GetLoadoutState",
		"GetLoadoutBonuses",
		"GrantPotionProduct",
		"GetRewardedAdState",
	},
	players = {},
	tasks = {},
	IsLoaded = false,
}
EcoSystem.__index = EcoSystem
EcoSystem.OnBuySuccess = nil :: BindableEvent
EcoSystem.OnDataSyc = nil :: BindableEvent
EcoSystem.OnResourceSyc = nil :: BindableEvent
if IsServer then
	EcoSystem.Client = setmetatable({}, EcoSystem)
	-- Template.AllClients = setmetatable({}, Template)
	local ServerStorage = game:GetService("ServerStorage")
	PlayerServerClass = require(ServerStorage.classes.PlayerServerClass)
	DataStoreService = game:GetService("DataStoreService")
	purchaseHistoryStore = DataStoreService:GetDataStore("PurchaseHistory")
	GlobalDataModule = require(ServerStorage.modules.GlobalDataModule)
	AnalyticsService = game:GetService("AnalyticsService")
	AdService = game:GetService("AdService")
else
	EcoSystem.Server = setmetatable({}, EcoSystem)
	LocalPlayer = Players.LocalPlayer
	ClientData = require(Replicated.Systems.ClientData)
end

---- [[ Handle ]] ----
function processReceipt(receiptInfo)
	-- GAModule:ProcessReceiptCallback(receiptInfo)
	-- check whether player bought this product before
	local playerProductKey = receiptInfo.PlayerId .. "_" .. receiptInfo.PurchaseId
	local purchased = false
	local success, errorMessage = pcall(function()
		purchased = purchaseHistoryStore:GetAsync(playerProductKey)
	end)
	-- if there is a record, then this receipt is done
	if success and purchased then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	elseif not success then
		error("Data store error:" .. errorMessage)
	end

	-- get online player
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		-- player left game
		-- when player is back, the recall will call again
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- check handle
	if not productFunctions[receiptInfo.ProductId] then
		productFunctions[receiptInfo.ProductId] = emptyHandle
	end
	local handler = productFunctions[receiptInfo.ProductId]

	-- result check
	local result
	success, result = pcall(handler, receiptInfo, player)
	if not success or not result then
		warn(`[EcoSystem] Error processing product {receiptInfo.ProductId} for {player.Name}: {tostring(result)}`)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- 将购买操作记录在数据库中
	success, errorMessage = pcall(function()
		purchaseHistoryStore:SetAsync(playerProductKey, true)
	end)
	if not success then
		error("Cannot save purchase data: " .. errorMessage)
	end

	return Enum.ProductPurchaseDecision.PurchaseGranted
end

function gamePassPurchaseFinished(player, purchasedPassID, purchaseSuccess)
	if purchaseSuccess and purchasedPassID then
		local func = gamePassFunctions[purchasedPassID]
		if not func then
			warn(`player {player.Name} bought game pass {purchasedPassID}, but there is no handle.`)
			return
		end
		func(player)
		-- SystemMgr.systems.GuiSystem:SetNotification(SENDER, player, {
		--     content = "Thank you for your support!🎇",
		--     color = Color3.fromRGB(0, 255, 0)
		-- })
		-- passFunctions[purchasedPassID](player)
	end
end

function emptyHandle(receipt, player)
	warn(`player {player.Name} bought item {receipt.ProductId}, but there is no handle.`)
	return true
end

function GetSystemMgr()
	if not SystemMgr then
		SystemMgr = require(Replicated.Systems.SystemMgr)
		SENDER = SystemMgr.SENDER
	end
	return SystemMgr
end

local function getOwnedKey(category)
	if category == "coin" then
		return dataKey.ownedCoins
	end
	if category == "desk" then
		return dataKey.ownedDeskSetups
	end
	if category == "chair" then
		return dataKey.ownedChairs
	end

	return nil
end

local function getEquippedKey(category)
	if category == "coin" then
		return dataKey.equippedCoin
	end
	if category == "desk" then
		return dataKey.equippedDeskSetup
	end
	if category == "chair" then
		return dataKey.equippedChair
	end

	return nil
end

local function normalizeLoadoutData(playerIns)
	local ownedCoins = playerIns:GetOneData(dataKey.ownedCoins)
	local equippedCoin = playerIns:GetOneData(dataKey.equippedCoin)
	local ownedDeskSetups = playerIns:GetOneData(dataKey.ownedDeskSetups)
	local equippedDeskSetup = playerIns:GetOneData(dataKey.equippedDeskSetup)
	local ownedChairs = playerIns:GetOneData(dataKey.ownedChairs)
	local equippedChair = playerIns:GetOneData(dataKey.equippedChair)

	if typeof(ownedCoins) ~= "table" then
		ownedCoins = {
			[EcoPresets.LoadoutDefaults.equippedCoin] = true,
		}
		playerIns:SetOneData(dataKey.ownedCoins, ownedCoins)
	end
	if not EcoPresets.GetShopItem("coin", equippedCoin) or not ownedCoins[equippedCoin] then
		equippedCoin = EcoPresets.LoadoutDefaults.equippedCoin
		ownedCoins[equippedCoin] = true
		playerIns:SetOneData(dataKey.equippedCoin, equippedCoin)
		playerIns:SetOneData(dataKey.ownedCoins, ownedCoins)
	end

	if typeof(ownedDeskSetups) ~= "table" then
		ownedDeskSetups = {
			[EcoPresets.LoadoutDefaults.equippedDeskSetup] = true,
		}
		playerIns:SetOneData(dataKey.ownedDeskSetups, ownedDeskSetups)
	end
	if not EcoPresets.GetShopItem("desk", equippedDeskSetup) or not ownedDeskSetups[equippedDeskSetup] then
		equippedDeskSetup = EcoPresets.LoadoutDefaults.equippedDeskSetup
		ownedDeskSetups[equippedDeskSetup] = true
		playerIns:SetOneData(dataKey.equippedDeskSetup, equippedDeskSetup)
		playerIns:SetOneData(dataKey.ownedDeskSetups, ownedDeskSetups)
	end

	if typeof(ownedChairs) ~= "table" then
		ownedChairs = {
			[EcoPresets.LoadoutDefaults.equippedChair] = true,
		}
		playerIns:SetOneData(dataKey.ownedChairs, ownedChairs)
	end
	if not EcoPresets.GetShopItem("chair", equippedChair) or not ownedChairs[equippedChair] then
		equippedChair = EcoPresets.LoadoutDefaults.equippedChair
		ownedChairs[equippedChair] = true
		playerIns:SetOneData(dataKey.equippedChair, equippedChair)
		playerIns:SetOneData(dataKey.ownedChairs, ownedChairs)
	end

	return {
		ownedCoins = ownedCoins,
		equippedCoin = equippedCoin,
		ownedDeskSetups = ownedDeskSetups,
		equippedDeskSetup = equippedDeskSetup,
		ownedChairs = ownedChairs,
		equippedChair = equippedChair,
	}
end

local function refreshCashDisplays(player)
	SystemMgr.systems.PlayerSystem:UpdateLeaderStats(player)
	SystemMgr.systems.PlayerSystem:UpdatePlayerHeadGui(player)
end

local function refreshDecoration(player, category)
	if category == "desk" or category == "chair" then
		SystemMgr.systems.DecorationSystem:RefreshPlayerDecoration(SENDER, player)
	end
end

local function notifyLoadoutChanged(player, actionText, item)
	SystemMgr.systems.GuiSystem:SetNotification(SENDER, player, {
		text = `{actionText} {item.displayName}`,
		lastTime = 2.4,
		textColor = Color3.fromRGB(255, 224, 158),
	})
end

local function isStoreIdConfigured(id)
	return typeof(id) == "number" and id > 0
end

local function getRewardedAdReward()
	return AdService:CreateAdRewardFromDevProductId(EcoPresets.RewardedAds.DevProductId)
end

local function markRewardedAdCooldown(player)
	local now = os.time()
	if (rewardedAdCooldowns[player.UserId] or 0) <= now then
		rewardedAdCooldowns[player.UserId] = now + EcoPresets.RewardedAds.CooldownSeconds
	end
end

local function buildRewardedAdState(player)
	local now = os.time()
	local cooldownEndsAt = rewardedAdCooldowns[player.UserId] or 0
	local cooldownRemaining = math.max(cooldownEndsAt - now, 0)
	if not rewardedAdProductRegistered then
		return {
			available = false,
			reason = "rewardNotConfigured",
			cooldownEndsAt = cooldownEndsAt,
			cooldownRemaining = cooldownRemaining,
		}
	end
	if rewardedAdInFlight[player.UserId] then
		return {
			available = false,
			reason = "inFlight",
			cooldownEndsAt = cooldownEndsAt,
			cooldownRemaining = cooldownRemaining,
		}
	end
	if cooldownRemaining > 0 then
		return {
			available = false,
			reason = "cooldown",
			cooldownEndsAt = cooldownEndsAt,
			cooldownRemaining = cooldownRemaining,
		}
	end

	return {
		available = true,
		reason = "ready",
		cooldownEndsAt = cooldownEndsAt,
		cooldownRemaining = cooldownRemaining,
	}
end

local function applyLoadoutUnlocks(playerIns, unlocks)
	if typeof(unlocks) ~= "table" then
		return false
	end

	local unlocked = false
	normalizeLoadoutData(playerIns)
	for category, itemIds in pairs(unlocks) do
		local resolvedCategory = EcoPresets.ResolveShopCategory(category)
		local ownedKey = getOwnedKey(resolvedCategory)
		if not ownedKey or typeof(itemIds) ~= "table" then
			continue
		end

		local ownedItems = playerIns:GetOneData(ownedKey)
		for _, itemId in ipairs(itemIds) do
			local item = EcoPresets.GetShopItem(resolvedCategory, itemId)
			if item and not ownedItems[item.id] then
				ownedItems[item.id] = true
				unlocked = true
			end
		end
		playerIns:SetOneData(ownedKey, ownedItems)
	end

	return unlocked
end

local function refreshPlayerAfterPremiumChange(player, extraArgs)
	refreshCashDisplays(player)
	SystemMgr.systems.TableSeatSystem:RefreshAudienceState(SENDER)
	SystemMgr.systems.CoinFlipSystem:SyncPlayerState(SENDER, player, extraArgs)
end

function EcoSystem:Init()
	GetSystemMgr()
	if IsServer then
		MarketplaceService.ProcessReceipt = processReceipt
		MarketplaceService.PromptGamePassPurchaseFinished:Connect(gamePassPurchaseFinished)
		---- [[ product ]] ----
		for key, products in EcoPresets.Products do
			if key == "flipACoin" then
				for productKey, productInfo in pairs(products) do
					if not isStoreIdConfigured(productInfo.productId) then
						continue
					end
					productFunctions[productInfo.productId] = function(receiptInfo, player)
						return self:GrantFlipACoinProduct(SENDER, player, {
							productKey = productKey,
							productInfo = productInfo,
						})
					end
				end
			elseif key == ItemType.pet then
				for petName, productInfo in pairs(products) do
					productFunctions[productInfo.productId] = function(receiptInfo, player)
						for i = 1, productInfo.count do
							SystemMgr.systems.PetSystem:AddNewPet(SENDER, player, {
								petName = petName,
							})
						end
						return true
					end
				end
			elseif key == ItemType.egg then
				for eggName, productInfo in pairs(products) do
					productFunctions[productInfo.productId] = function(receiptInfo, player)
						SystemMgr.systems.PetSystem:HatchEgg(SENDER, player, {
							eggName = productInfo.name,
							count = productInfo.count,
						})
						return true
					end
				end
			elseif key == ItemType.spin then
				for spinName, productInfo in pairs(products) do
					productFunctions[productInfo.productId] = function(receiptInfo, player)
						SystemMgr.systems.SpinSystem:AddSpin(SENDER, player, {
							count = productInfo.count,
							reason = "buy",
						})
						return true
					end
				end
			elseif key == ItemType.wins then
				for i, productInfo in ipairs(products) do
					productFunctions[productInfo.productId] = function(receiptInfo, player)
						local playerIns = PlayerServerClass.GetIns(player)
						local rebirth = playerIns:GetOneData(dataKey.rebirth) + 1
						self:AddResource(SENDER, player, {
							resourceType = "wins",
							count = productInfo.count * rebirth * rebirth,
							reason = "Store",
						})
						return true
					end
				end
			elseif key == "skipRebirth" then
				productFunctions[products.productId] = function(receiptInfo, player)
					SystemMgr.systems.RebirthSystem:Rebirth(SENDER, player)
					return true
				end
			elseif key == "starterPack" then
				productFunctions[products.productId] = function(receiptInfo, player)
					self:BuyStarterPack(SENDER, player)
					return true
				end
			elseif key == "limitedPets" then
				for petName, productInfo in pairs(products) do
					productFunctions[productInfo.productId] = function(receiptInfo, player)
						SystemMgr.systems.PetSystem:AddNewPet(SENDER, player, {
							petName = petName,
						})
						self:BuyLimitedPet(SENDER, player, {
							petName = petName,
						})
						return true
					end
				end
			elseif key == "potions" then
				for pdName, productInfo in pairs(products) do
					if not isStoreIdConfigured(productInfo.productId) then
						continue
					end
					productFunctions[productInfo.productId] = function(receiptInfo, player)
						SystemMgr.systems.PotionSystem:AddPotion(SENDER, player, {
							potionName = productInfo.potionName,
							count = productInfo.count,
						})
						return true
					end
				end
			elseif key == "event" then
				for i, productInfo in ipairs(products) do
					productFunctions[productInfo.productId] = function(receiptInfo, player)
						SystemMgr.systems.EventSystem:AddCount(SENDER, player, {
							count = productInfo.count,
							reason = "buy",
						})
						return true
					end
				end
			elseif key == "seasonPremium" then
				productFunctions[products.productId] = function(receiptInfo, player)
					SystemMgr.systems.PetSystem:AddPlayerPetData(SENDER, player, {
						addType = "petCarrySize",
						count = 1,
					})

					SystemMgr.systems.SeasonSystem:BuySeasonPass(SENDER, player)
					return true
				end
			elseif key == "skipSeasonLevel" then
				productFunctions[products.productId] = function(receiptInfo, player)
					SystemMgr.systems.SeasonSystem:LevelUp(SENDER, player, {
						ifPay = true,
					})
					return true
				end
			elseif key == "skipAllSeasonLevel" then
				productFunctions[products.productId] = function(receiptInfo, player)
					SystemMgr.systems.SeasonSystem:LevelUp(SENDER, player, {
						ifPay = true,
						maxLevel = true,
					})
					return true
				end
			elseif key == "resetSeason" then
				productFunctions[products.productId] = function(receiptInfo, player)
					SystemMgr.systems.SeasonSystem:ResetSeason(SENDER, player)
					return true
				end
			elseif key == "strengthBoost" then
				for i, productInfo in ipairs(products) do
					productFunctions[productInfo.productId] = function(receiptInfo, player)
						self:BuyStrengthBoost(SENDER, player)
						return true
					end
				end
			elseif key == "cardPacks" then
				for _, productInfo in pairs(products) do
					for i = 1, 4 do
						if not productInfo["buy" .. i] then
							continue
						end
						productFunctions[productInfo["buy" .. i].productId] = function(receiptInfo, player)
							SystemMgr.systems.CardSystem:AddCardPack(SENDER, player, {
								cardPackName = productInfo.name,
								count = productInfo["buy" .. i].count,
							})
							return true
						end
					end
				end
			elseif key == "restock" then
				productFunctions[products.productId] = function(receiptInfo, player)
					SystemMgr.systems.CardSystem:Restock(SENDER, player)
					return true
				end
			elseif key == "shopCard1" then
				productFunctions[products.productId] = function(receiptInfo, player)
					SystemMgr.systems.CardSystem:BoughtCardPack(SENDER, player, {
						cardPackName = EcoPresets.Products.cardPacks.cardPack1.name,
						count = 1,
					})
					return true
				end
			elseif key == "shopCard2" then
				productFunctions[products.productId] = function(receiptInfo, player)
					SystemMgr.systems.CardSystem:BoughtCardPack(SENDER, player, {
						cardPackName = EcoPresets.Products.cardPacks.cardPack2.name,
						count = 1,
					})
					return true
				end
			elseif key == "upgradeTier" then
				productFunctions[products.productId] = function(receiptInfo, player)
					SystemMgr.systems.HouseSystem:UpgradeHouse(SENDER, player)
					return true
				end
			elseif key == "eventWins" then
				for i, productInfo in ipairs(products) do
					productFunctions[productInfo.productId] = function(receiptInfo, player)
						SystemMgr.systems.EventSystem:AddWins(SENDER, player, {
							count = productInfo.count,
						})
						return true
					end
				end
			elseif key == "eventChest" then
				for i, productInfo in ipairs(products) do
					productFunctions[productInfo.productId] = function(receiptInfo, player)
						local EventPresets = require(Replicated.Systems.EventSystem.Presets)
						self:GiveItem(SENDER, player, {
							itemType = Keys.ItemType.cardPacks,
							count = productInfo.count,
							name = EventPresets.CardPack2,
							reason = "event card pack",
						})
						return true
					end
				end
			elseif key == "eventWinsMultiplier" then
				for i, productInfo in ipairs(products) do
					productFunctions[productInfo.productId] = function(receiptInfo, player)
						SystemMgr.systems.EventSystem:BuyWinsMultiplier(SENDER, player, {
							multiplierIndex = i,
						})
						return true
					end
				end
			end
		end
		local rewardedAdProductId = EcoPresets.RewardedAds.DevProductId
		if isStoreIdConfigured(rewardedAdProductId) then
			if productFunctions[rewardedAdProductId] then
				warn("[EcoSystem] Rewarded ad DevProductId must be unique.")
			else
				rewardedAdProductRegistered = true
				productFunctions[rewardedAdProductId] = function(receiptInfo, player)
					markRewardedAdCooldown(player)
					rewardedAdInFlight[player.UserId] = nil
					local granted = SystemMgr.systems.PotionSystem:GrantAndUsePotion(SENDER, player, {
						potionName = EcoPresets.RewardedAds.AdPotionName,
						count = 1,
						source = "ad",
					})
					if granted then
						SystemMgr.systems.AnalyticsSystem:LogRewardedAd(SENDER, player, {
							stage = "complete",
							result = "granted",
							reason = EcoPresets.RewardedAds.AdPotionName,
						})
						refreshPlayerAfterPremiumChange(player, {
							purchasedItem = EcoPresets.RewardedAds.AdPotionName,
							equippedCategory = "boost",
						})
						self.Client:SyncRewardedAdState(player, buildRewardedAdState(player))
					end
					return granted
				end
			end
		end
		---- [[ game pass ]] ----
		for gamePassName, gamePassConfig in EcoPresets.GamePasses do
			if not isStoreIdConfigured(gamePassConfig.gamePassId) then
				continue
			end
			gamePassFunctions[gamePassConfig.gamePassId] = function(player)
				local playerIns = PlayerServerClass.GetIns(player)
				local passes = playerIns:GetOneData(dataKey.gamePasses)
				passes[gamePassName] = true
				self:BuyGamePass(SENDER, player, {
					gamePasses = passes,
					gamePassName = gamePassName,
					source = "purchase",
				})
			end
		end
	end
end

function EcoSystem:PlayerAdded(sender, player, args)
	if IsServer then
		local playerIns = PlayerServerClass.GetIns(player)
		if not playerIns then
			return
		end

		local gamePasses = playerIns:GetOneData(dataKey.gamePasses)
		for gamePassName, gamePassConfig in EcoPresets.GamePasses do
			if gamePasses[gamePassName] or not isStoreIdConfigured(gamePassConfig.gamePassId) then
				continue
			end
			local suc, result = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamePassConfig.gamePassId)
			end)
			if suc and result then
				local passes = playerIns:GetOneData(dataKey.gamePasses)
				passes[gamePassName] = true
				task.delay(1, function()
					if not player:IsDescendantOf(Players) then
						return
					end
					self:BuyGamePass(SENDER, player, {
						gamePasses = passes,
						gamePassName = gamePassName,
						source = "ownershipSync",
					})
				end)
			end
		end

		if not gamePasses.autoHatch then
			if player:IsInGroup(GameConfig.GroupId) then
				gamePasses.autoHatch = true
			end
		end

		args = {
			gamePasses = playerIns:GetOneData(dataKey.gamePasses),
			wins = playerIns:GetOneData(dataKey.wins),
			loadoutState = self:GetLoadoutState(SENDER, player),
			rewardedAdState = self:GetRewardedAdState(SENDER, player),
			limitedPets = GlobalDataModule.GetMemoryStore("LimitedPets"),
		}
		self.Client:PlayerAdded(player, args)
	else
		ClientData:SetDataTable(args)
		local pendingCalls = EcoUi.pendingCalls

		EcoUi = require(script.ui)
		EcoUi.Init()

		for _, call in ipairs(pendingCalls) do
			EcoUi[call.functionName](table.unpack(call.args))
		end

		EcoUi.SyncLoadoutState(args)
	end
end

function EcoSystem:PlayerRemoving(sender, player)
	if IsServer then
		if sender ~= SENDER then
			return
		end

		rewardedAdCooldowns[player.UserId] = nil
		rewardedAdInFlight[player.UserId] = nil
		rewardedAdAvailabilityReports[player.UserId] = nil
	end
end

function EcoSystem:AddResource(sender, player, args: { resourceType: string, count: number })
	if IsServer then
		if sender ~= SENDER then
			return
		end

		local resourceType = args.resourceType
		local count = args.count

		local total = 0
		local playerIns = PlayerServerClass.GetIns(player)
		if resourceType == "??" then
			-- special key and data structure
			-- total = playerIns:GetOneData(dataKey.wins)
		else
			playerIns:AddOneData(resourceType, count)

			if resourceType == "wins" then
				if count > 0 then
					-- SystemMgr.systems.QuestSystem:DoQuest(player, {
					-- 	questType = "getWins",
					-- 	value = count,
					-- })
				end

				SystemMgr.systems.PlayerSystem:UpdateLeaderStats(player)
				SystemMgr.systems.PlayerSystem:UpdatePlayerHeadGui(player)
			end

			---- analytics ----
			local followType = nil
			if count >= 0 then
				followType = Enum.AnalyticsEconomyFlowType.Source
			else
				followType = Enum.AnalyticsEconomyFlowType.Sink
			end
			AnalyticsService:LogEconomyEvent(
				player,
				followType,
				resourceType,
				math.abs(count),
				playerIns:GetOneData(resourceType),
				args.reason or "unknown"
			)

			total = playerIns:GetOneData(resourceType)
		end

		self.Client:AddResource(player, {
			resourceType = resourceType,
			total = total,
			count = count,
		})
	else
		local resourceType = args.resourceType
		local count = args.count
		local total = args.total
		if resourceType == "??" then
			-- special key and data structure
			-- total = playerIns:GetOneData(dataKey.wins)
		else
			ClientData:SetOneData(resourceType, total)
			if resourceType == "wins" then
				EcoUi.UpdateWins(args)
			end
		end
	end
end

function EcoSystem:GetLoadoutState(sender, player)
	if IsServer then
		if sender ~= SENDER then
			return nil
		end

		local playerIns = PlayerServerClass.GetIns(player)
		if not playerIns then
			return nil
		end

		local loadoutData = normalizeLoadoutData(playerIns)
		local gamePasses = playerIns:GetOneData(dataKey.gamePasses)
		return {
			equippedCoin = loadoutData.equippedCoin,
			equippedDeskSetup = loadoutData.equippedDeskSetup,
			equippedChair = loadoutData.equippedChair,
			ownedCoins = table.clone(loadoutData.ownedCoins),
			ownedDeskSetups = table.clone(loadoutData.ownedDeskSetups),
			ownedChairs = table.clone(loadoutData.ownedChairs),
			shopItems = EcoPresets.GrowthShopItems,
			derivedStats = EcoPresets.BuildLoadoutBonuses(
				loadoutData.equippedCoin,
				loadoutData.equippedDeskSetup,
				loadoutData.equippedChair,
				gamePasses
			),
		}
	else
		return ClientData:GetOneData("loadoutState")
	end
end

function EcoSystem:GetLoadoutBonuses(sender, player)
	if IsServer then
		if sender ~= SENDER then
			return {
				coinMultiplier = 1,
				premiumCoinMultiplier = 1,
				luckBonus = 0,
			}
		end

		local playerIns = PlayerServerClass.GetIns(player)
		if not playerIns then
			return {
				coinMultiplier = 1,
				premiumCoinMultiplier = 1,
				luckBonus = 0,
			}
		end

		local loadoutData = normalizeLoadoutData(playerIns)
		local gamePasses = playerIns:GetOneData(dataKey.gamePasses)
		return EcoPresets.BuildLoadoutBonuses(
			loadoutData.equippedCoin,
			loadoutData.equippedDeskSetup,
			loadoutData.equippedChair,
			gamePasses
		)
	else
		local loadoutState = ClientData:GetOneData("loadoutState") or {}
		return loadoutState.derivedStats
	end
end

function EcoSystem:ReportGrowthPanelOpened(sender, player, args)
	if not IsServer then
		return
	end

	player = player or sender
	if sender ~= player or not player:IsDescendantOf(Players) or typeof(args) ~= "table" then
		return
	end

	local panel = args.panel
	if panel ~= "Shop" and panel ~= "Inventory" then
		return
	end

	SystemMgr.systems.AnalyticsSystem:LogFirstGrowthPanelOpen(SENDER, player, {
		panel = panel,
		source = typeof(args.source) == "string" and args.source or "unknown",
		inputType = typeof(args.inputType) == "string" and args.inputType or "unknown",
	})
end

function EcoSystem:RequestShopPurchase(sender, player, args)
	if IsServer then
		player = player or sender
		if sender ~= SENDER and sender ~= player then
			return
		end
		if typeof(args) ~= "table" then
			return
		end

		local category = EcoPresets.ResolveShopCategory(args.category)
		local item = EcoPresets.GetShopItem(category, args.itemId)
		if not category or not item then
			return
		end

		local ownedKey = getOwnedKey(category)
		local playerIns = PlayerServerClass.GetIns(player)
		if not playerIns then
			return
		end

		normalizeLoadoutData(playerIns)
		local ownedItems = playerIns:GetOneData(ownedKey)
		if ownedItems[item.id] then
			refreshCashDisplays(player)
			SystemMgr.systems.CoinFlipSystem:SyncPlayerState(SENDER, player)
			return
		end

		local wins = playerIns:GetOneData(dataKey.wins)
		if wins < item.cost then
			SystemMgr.systems.GuiSystem:SetNotification(SENDER, player, {
				text = "Not enough Cash",
				lastTime = 2,
				soundName = "notification",
			})
			SystemMgr.systems.CoinFlipSystem:SyncPlayerState(SENDER, player)
			return
		end

		self:AddResource(SENDER, player, {
			resourceType = dataKey.wins,
			count = -item.cost,
			reason = "shop",
		})
		ownedItems[item.id] = true
		playerIns:SetOneData(ownedKey, ownedItems)

		SystemMgr.systems.AnalyticsSystem:LogShopItemPurchased(SENDER, player, {
			category = category,
			itemId = item.id,
			rarity = item.rarity,
			cost = item.cost,
		})
		notifyLoadoutChanged(player, "Purchased", item)
		if category == "coin" then
			SystemMgr.systems.CoinFlipSystem:HandleGuideCoinPurchased(SENDER, player, {
				itemId = item.id,
			})
		end
		SystemMgr.systems.CoinFlipSystem:SyncPlayerState(SENDER, player, {
			purchasedItem = item.id,
		})
	else
		--
	end
end

function EcoSystem:RequestEquipItem(sender, player, args)
	if IsServer then
		player = player or sender
		if sender ~= SENDER and sender ~= player then
			return
		end
		if typeof(args) ~= "table" then
			return
		end

		local category = EcoPresets.ResolveShopCategory(args.category)
		local item = EcoPresets.GetShopItem(category, args.itemId)
		if not category or not item then
			return
		end

		local ownedKey = getOwnedKey(category)
		local equippedKey = getEquippedKey(category)
		local playerIns = PlayerServerClass.GetIns(player)
		if not playerIns then
			return
		end

		normalizeLoadoutData(playerIns)
		local ownedItems = playerIns:GetOneData(ownedKey)
		if not ownedItems[item.id] then
			return
		end

		playerIns:SetOneData(equippedKey, item.id)
		refreshCashDisplays(player)
		refreshDecoration(player, category)
		notifyLoadoutChanged(player, "Equipped", item)
		SystemMgr.systems.AnalyticsSystem:LogItemEquipped(SENDER, player, {
			category = category,
			itemId = item.id,
			source = "inventory",
		})
		if category == "coin" then
			SystemMgr.systems.CoinFlipSystem:HandleGuideCoinEquipped(SENDER, player, {
				itemId = item.id,
			})
		end
		SystemMgr.systems.TableSeatSystem:RefreshAudienceState(SENDER)
		SystemMgr.systems.CoinFlipSystem:SyncPlayerState(SENDER, player, {
			equippedItem = item.id,
			equippedCategory = category,
		})
	else
		--
	end
end

function EcoSystem:SyncLoadoutState(sender, player, args)
	if IsServer then
		return
	end

	local loadoutState = args and args.loadoutState
	if loadoutState then
		ClientData:SetOneData("loadoutState", loadoutState)
		ClientData:SetOneData(dataKey.equippedCoin, loadoutState.equippedCoin)
		ClientData:SetOneData(dataKey.ownedCoins, loadoutState.ownedCoins)
		ClientData:SetOneData(dataKey.equippedDeskSetup, loadoutState.equippedDeskSetup)
		ClientData:SetOneData(dataKey.ownedDeskSetups, loadoutState.ownedDeskSetups)
		ClientData:SetOneData(dataKey.equippedChair, loadoutState.equippedChair)
		ClientData:SetOneData(dataKey.ownedChairs, loadoutState.ownedChairs)
	end

	EcoUi.SyncLoadoutState(args)
end

function EcoSystem:OpenGuideShopItem(args)
	if IsServer then
		return nil
	end

	return EcoUi.OpenGuideShopItem(args)
end

function EcoSystem:OpenGuideInventoryItem(args)
	if IsServer then
		return nil
	end

	return EcoUi.OpenGuideInventoryItem(args)
end

function EcoSystem:GrantFlipACoinProduct(sender, player, args)
	if not IsServer then
		return false
	end
	if sender ~= SENDER then
		return false
	end
	if typeof(args) ~= "table" or typeof(args.productInfo) ~= "table" then
		return false
	end

	local playerIns = PlayerServerClass.GetIns(player)
	if not playerIns then
		return false
	end

	local productInfo = args.productInfo
	local productKey = args.productKey
	local grantType = productInfo.grantType
	if grantType == "cash" then
		self:AddResource(SENDER, player, {
			resourceType = dataKey.wins,
			count = productInfo.count,
			reason = "robuxProduct",
		})
		refreshPlayerAfterPremiumChange(player, {
			purchasedItem = productKey,
			equippedCategory = "boost",
		})
		return true
	end

	if grantType == "rebirthPoints" then
		playerIns:AddOneData(dataKey.fateShards, productInfo.count)
		refreshPlayerAfterPremiumChange(player, {
			purchasedItem = productKey,
			equippedCategory = "boost",
		})
		return true
	end

	if grantType == "potion" then
		local granted = self:GrantPotionProduct(SENDER, player, {
			productKey = productKey,
			productInfo = productInfo,
			source = "product",
		})
		if granted then
			refreshPlayerAfterPremiumChange(player, {
				purchasedItem = productKey,
				equippedCategory = "boost",
			})
		end
		return granted
	end

	if grantType == "loadoutBundle" then
		local unlocked = applyLoadoutUnlocks(playerIns, productInfo.unlocks)
		if unlocked then
			refreshDecoration(player, "desk")
			refreshDecoration(player, "chair")
			SystemMgr.systems.AnalyticsSystem:LogShopItemPurchased(SENDER, player, {
				category = "boost",
				itemId = productKey,
				rarity = "Robux",
				cost = productInfo.price or 0,
			})
			refreshPlayerAfterPremiumChange(player, {
				purchasedItem = productKey,
				equippedCategory = "boost",
			})
		elseif (productInfo.fallbackCash or 0) > 0 then
			self:AddResource(SENDER, player, {
				resourceType = dataKey.wins,
				count = productInfo.fallbackCash,
				reason = "robuxDuplicateBundle",
			})
			refreshPlayerAfterPremiumChange(player, {
				purchasedItem = productKey,
				equippedCategory = "boost",
			})
		end
		return true
	end

	warn(`[EcoSystem] Unsupported FlipACoin product grant type: {tostring(grantType)}`)
	return false
end

function EcoSystem:GetRewardedAdState(sender, player)
	if not IsServer then
		return nil
	end
	if sender ~= SENDER then
		return nil
	end
	if not player or not player:IsDescendantOf(Players) then
		return nil
	end

	return buildRewardedAdState(player)
end

function EcoSystem:SyncRewardedAdState(sender, player, args)
	if IsServer then
		return
	end

	EcoUi.SyncRewardedAdState(args)
end

function EcoSystem:GrantPotionProduct(sender, player, args)
	if not IsServer then
		return false
	end
	if sender ~= SENDER then
		return false
	end
	if typeof(args) ~= "table" or typeof(args.productInfo) ~= "table" then
		return false
	end

	local potionName = args.productInfo.potionName
	if typeof(potionName) ~= "string" then
		return false
	end

	local granted = SystemMgr.systems.PotionSystem:GrantAndUsePotion(SENDER, player, {
		potionName = potionName,
		count = 1,
		source = args.source or "product",
	})
	if granted then
		SystemMgr.systems.AnalyticsSystem:LogShopItemPurchased(SENDER, player, {
			category = "boost",
			itemId = args.productKey or potionName,
			rarity = "Robux",
			cost = args.productInfo.price or 0,
		})
	end

	return granted
end

function EcoSystem:RequestRewardedCashPotionAd(sender, player)
	if not IsServer then
		return
	end

	player = player or sender
	if sender ~= player or not player:IsDescendantOf(Players) then
		return
	end

	local adState = buildRewardedAdState(player)
	self.Client:SyncRewardedAdState(player, adState)
	SystemMgr.systems.AnalyticsSystem:LogRewardedAd(SENDER, player, {
		stage = "availability",
		result = adState.available and "available" or "unavailable",
		reason = adState.reason,
	})
	if not adState.available then
		return
	end

	rewardedAdInFlight[player.UserId] = true
	self.Client:SyncRewardedAdState(player, buildRewardedAdState(player))
	SystemMgr.systems.AnalyticsSystem:LogRewardedAd(SENDER, player, {
		stage = "start",
		result = "requested",
		reason = "ready",
	})
	local success, result = pcall(function()
		local reward = getRewardedAdReward()
		return AdService:ShowRewardedVideoAdAsync(player, reward)
	end)
	if not player:IsDescendantOf(Players) then
		return
	end
	if not success then
		rewardedAdInFlight[player.UserId] = nil
		SystemMgr.systems.AnalyticsSystem:LogRewardedAd(SENDER, player, {
			stage = "failed",
			result = "showError",
			reason = "showError",
		})
		self.Client:SyncRewardedAdState(player, buildRewardedAdState(player))
		return
	end

	if result ~= Enum.ShowAdResult.ShowCompleted then
		rewardedAdInFlight[player.UserId] = nil
		SystemMgr.systems.AnalyticsSystem:LogRewardedAd(SENDER, player, {
			stage = "failed",
			result = result and result.Name or "unknown",
			reason = "notCompleted",
		})
		self.Client:SyncRewardedAdState(player, buildRewardedAdState(player))
		return
	end

	rewardedAdInFlight[player.UserId] = nil
	markRewardedAdCooldown(player)
	SystemMgr.systems.AnalyticsSystem:LogRewardedAd(SENDER, player, {
		stage = "completed",
		result = "awaitingReceipt",
		reason = "receipt",
	})
	self.Client:SyncRewardedAdState(player, buildRewardedAdState(player))
end

function EcoSystem:ReportRewardedAdAvailability(sender, player, args)
	if not IsServer then
		return
	end

	player = player or sender
	if sender ~= player or not player:IsDescendantOf(Players) or typeof(args) ~= "table" then
		return
	end
	local now = os.clock()
	if now - (rewardedAdAvailabilityReports[player.UserId] or 0) < 2 then
		return
	end
	rewardedAdAvailabilityReports[player.UserId] = now

	SystemMgr.systems.AnalyticsSystem:LogRewardedAd(SENDER, player, {
		stage = "availability",
		result = args.available == true and "available" or "unavailable",
		reason = typeof(args.reason) == "string" and args.reason or "unknown",
	})
end

function EcoSystem:RequestRewardedAdState(sender, player)
	if not IsServer then
		return
	end

	player = player or sender
	if sender ~= player or not player:IsDescendantOf(Players) then
		return
	end

	local adState = buildRewardedAdState(player)
	self.Client:SyncRewardedAdState(player, adState)
	SystemMgr.systems.AnalyticsSystem:LogRewardedAd(SENDER, player, {
		stage = "panelOpen",
		result = adState.available and "available" or "unavailable",
		reason = adState.reason,
	})
end

function EcoSystem:GiveItem(sender, player, args: { itemType: string, count: number, name: string, reason: string })
	if IsServer then
		if sender ~= SENDER then
			return
		end

		local itemType = args.itemType
		local count = args.count
		local name = args.name or args.itemName

		if itemType == ItemType.wins then
			self:AddResource(SENDER, player, {
				resourceType = "wins",
				count = count,
				isPercent = args.isPercent,
				reason = args.reason or "unknown",
			})
		elseif itemType == ItemType.pet then
			SystemMgr.systems.PetSystem:AddNewPet(SENDER, player, {
				petName = name,
			})
		elseif itemType == ItemType.spin then
			SystemMgr.systems.SpinSystem:AddSpin(SENDER, player, {
				count = count,
				reason = "gift",
			})
		elseif itemType == ItemType.power then
			SystemMgr.systems.PlayerSystem:AddPower(SENDER, player, {
				value = count,
				reason = "gift",
			})
		elseif itemType == ItemType.egg then
			SystemMgr.systems.PetSystem:HatchEgg(SENDER, player, {
				eggName = name,
				count = count,
			})
		elseif itemType == ItemType.potion then
			SystemMgr.systems.PotionSystem:AddPotion(SENDER, player, {
				potionName = name,
				count = count,
			})
		elseif itemType == ItemType.petCarrySize then
			SystemMgr.systems.PetSystem:AddPlayerPetData(SENDER, player, {
				addType = dataKey.petCarrySize,
				count = count,
			})
		elseif itemType == ItemType.resource then
			SystemMgr.systems.BackpackSystem:AddItems(SENDER, player, {
				items = {
					{
						itemType = itemType,
						itemName = name,
						count = count,
					},
				},
			})
		elseif itemType == ItemType.ores then
			local items = { {
				itemType = Keys.ItemType.ores,
				itemName = name,
				count = count,
			} }

			SystemMgr.systems.BackpackSystem:AddItems(SENDER, player, {
				items = items,
			})
		else
			warn("no gift type", itemType)
			return
		end

		self.Client:GiveItem(player, args)
	else
		EcoUi.GiveItem(args)
	end
end

function EcoSystem:RedeemCode(sender, player, args)
	if IsServer then
		player = player or sender
		local code = args.code
		code = string.upper(code)
		if not EcoPresets.redeemCodes[code] then
			SystemMgr.systems.GuiSystem:SetNotification(SENDER, player, {
				text = "Invalid code",
			})
			return
		end
		local playerIns = PlayerServerClass.GetIns(player)
		local redeemCode = playerIns:GetOneData(dataKey.redeemCode)
		if redeemCode[code] then
			SystemMgr.systems.GuiSystem:SetNotification(SENDER, player, {
				text = "Code already redeemed",
			})
			return
		end

		local expireTime = EcoPresets.redeemCodes[code].expireTime
		if os.time() > expireTime then
			SystemMgr.systems.GuiSystem:SetNotification(SENDER, player, {
				text = "Code expired",
			})
			return
		end

		redeemCode[code] = true
		-- GAModule:addDesignEvent(player.UserId, {
		-- 	eventId = `redeemCode:{code}`,
		-- 	value = 1,
		-- })
		local rewards = EcoPresets.redeemCodes[code].rewards
		for _, reward in rewards do
			self:GiveItem(SENDER, player, reward)
		end
	else
		--
	end
end

function EcoSystem:BuyGamePass(sender, player, args)
	if IsServer then
		if sender ~= SENDER then
			return
		end
		local gamePassName = args.gamePassName
		local gamePassConfig = EcoPresets.GamePasses[gamePassName]
		local effect = EcoPresets.GamePassEffects[gamePassName]
		local playerIns = PlayerServerClass.GetIns(player)
		if playerIns and effect and effect.unlocks then
			applyLoadoutUnlocks(playerIns, effect.unlocks)
		end

		self.Client:BuyGamePass(player, args)

		if gamePassName == "vip" then
			SystemMgr.systems.PlayerSystem:UpdatePlayerHeadGui(player)
		end
		refreshPlayerAfterPremiumChange(player, {
			gamePassPurchased = gamePassName,
			equippedCategory = "boost",
		})
		SystemMgr.systems.AnalyticsSystem:LogGamePassGranted(SENDER, player, {
			gamePassName = gamePassName,
			source = args.source or "unknown",
			effect = gamePassConfig.title,
			price = gamePassConfig.price,
		})
	else
		ClientData:SetOneData(dataKey.gamePasses, args.gamePasses)
		EcoUi.BuyGamePass(args)
	end
end

function EcoSystem:BuyLimitedPet(sender, player, args)
	if IsServer then
		if sender ~= SENDER then
			return
		end
		local petName = args.petName
		GlobalDataModule.BuyLimitedPet(petName, 1)
		local limitedPets = GlobalDataModule.GetMemoryStore("LimitedPets")
		self.Client:BuyLimitedPet(player, {
			limitedPets = limitedPets,
			petName = petName,
		})
	else
		ClientData:SetOneData("limitedPets", args.limitedPets)
		EcoUi.BuyLimitedPet(args)
	end
end

function EcoSystem:BuyStarterPack(sender, player, args)
	if IsServer then
		if sender ~= SENDER then
			return
		end

		local playerIns = PlayerServerClass.GetIns(player)
		playerIns:SetOneData(dataKey.buyStartPack, true)
		local config = EcoPresets.Products.starterPack
		for _, item in ipairs(config.items) do
			item.reason = "starterPack"
			SystemMgr.systems.EcoSystem:GiveItem(SENDER, player, item)
		end

		self.Client:BuyStarterPack(player, {
			buyStartPack = true,
		})
	else
		ClientData:SetOneData(dataKey.buyStartPack, args.buyStartPack)
		EcoUi.BuyStarterPack(args)
	end
end

function EcoSystem:BuyStrengthBoost(sender, player, args)
	if IsServer then
		if sender ~= SENDER then
			return
		end
		local playerIns = PlayerServerClass.GetIns(player)
		local strengthBoost = playerIns:GetOneData(dataKey.strengthBoost)
		local config = EcoPresets.Products.strengthBoost[strengthBoost + 1]
		if not config then
			return
		end

		playerIns:SetOneData(dataKey.strengthBoost, strengthBoost + 1)
		self.Client:BuyStrengthBoost(player, {
			strengthBoost = strengthBoost + 1,
		})
	else
		ClientData:SetOneData(dataKey.strengthBoost, args.strengthBoost)
		EcoUi.UpdateStrengthBoost()
	end
end

function EcoSystem:BuyPotionByWins(sender, player, args)
	if IsServer then
		player = player or sender

		local potionName = args.potionName
		local count = args.count

		local playerIns = PlayerServerClass.GetIns(player)
		local wins = playerIns:GetOneData(dataKey.wins)
		local price = EcoPresets.Products.potions[potionName].winsPrice
		if wins < price * count then
			SystemMgr.systems.GuiSystem:SetNotification(SENDER, player, {
				text = "Not enough wins",
			})
			return
		end
		self:AddResource(SENDER, player, {
			resourceType = "wins",
			count = -price * count,
			reason = "buyPotion",
		})

		SystemMgr.systems.PotionSystem:AddPotion(SENDER, player, {
			potionName = potionName,
			count = count,
		})
	end
end

-----[[ server ]] -----

return EcoSystem
