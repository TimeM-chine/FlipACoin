--[[
--Author: TimeM_chine
--Created Date: Mon Feb 26 2024
--Description: init.lua
--Version: 1.1
--Last Modified: 2024-05-17 7:59:06
--]]
---- services ----
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

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
local PlayerServerClass, purchaseHistoryStore, DataStoreService, GlobalDataModule, AnalyticsService
local productFunctions = {}
local gamePassFunctions = {}

---- client variables ----
local LocalPlayer, ClientData
local EcoUi = { pendingCalls = {} }
setmetatable(EcoUi, Types.mt)

local EcoSystem: Types.System = {
	whiteList = {},
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
else
	EcoSystem.Server = setmetatable({}, EcoSystem)
	LocalPlayer = Players.LocalPlayer
	ClientData = require(Replicated.Systems.ClientData)
end

---- [[ Handle ]] ----
function processReceipt(receiptInfo)
	print(`playerId {receiptInfo.PlayerId} is purchasing {receiptInfo.ProductId}.`)
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
		warn("Error occurred while processing a product purchase")
		print("\nProductId:", receiptInfo.ProductId)
		print("\nPlayer:", player)
		print("\nResult", result)
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
	print("buy gamePass ", player, purchasedPassID, purchaseSuccess)
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

function EcoSystem:Init()
	GetSystemMgr()
	if IsServer then
		MarketplaceService.ProcessReceipt = processReceipt
		MarketplaceService.PromptGamePassPurchaseFinished:Connect(gamePassPurchaseFinished)
		---- [[ product ]] ----
		for key, products in EcoPresets.Products do
			if key == ItemType.pet then
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
		---- [[ game pass ]] ----
		for gamePassName, gamePassConfig in EcoPresets.GamePasses do
			gamePassFunctions[gamePassConfig.gamePassId] = function(player)
				local playerIns = PlayerServerClass.GetIns(player)
				local passes = playerIns:GetOneData(dataKey.gamePasses)
				passes[gamePassName] = true
				self:BuyGamePass(SENDER, player, {
					gamePasses = passes,
					gamePassName = gamePassName,
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
			if gamePasses[gamePassName] then
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
			if resourceType == Keys.ItemType.wins and count > 0 then
				local gamePasses = playerIns:GetOneData(dataKey.gamePasses) or {}
				if gamePasses.winsX2 then
					local effectCfg = EcoPresets.GamePassEffects and EcoPresets.GamePassEffects.winsX2
					local mult = (effectCfg and effectCfg.mult) or 2
					count = count * mult
				end
			end
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

		self.Client:BuyGamePass(player, args)

		if gamePassName == "vip" then
			SystemMgr.systems.PlayerSystem:UpdatePlayerHeadGui(player)
		end
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
