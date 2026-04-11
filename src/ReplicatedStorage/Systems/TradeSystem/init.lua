--[[
--Author: TimeM_chine
--Created Date: Wed Feb 21 2024
--Description: init.lua
--Version: 1.1
--Last Modified: 2024-04-24 4:19:09
--]]

---- services ----
local Players = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

---- requires ----
local TradePresets = require(script.Presets)
local Types = require(Replicated.configs.Types)
local Keys = require(Replicated.configs.Keys)

---- common variables ----
local IsServer = RunService:IsServer()
local SENDER, SystemMgr

---- server variables ----
local PlayerServerClass
local tradings = {}

---- client variables ----
local LocalPlayer, ClientData, TradeUi

local TradeSystem: Types.System = {
	whiteList = {},
	players = {},
	tasks = {},
	IsLoaded = false,
}
TradeSystem.__index = TradeSystem

if IsServer then
	TradeSystem.Client = setmetatable({}, TradeSystem)
	-- Template.AllClients = setmetatable({}, Template)
	local ServerStorage = game:GetService("ServerStorage")
	PlayerServerClass = require(ServerStorage.classes.PlayerServerClass)
else
	TradeSystem.Server = setmetatable({}, TradeSystem)
	LocalPlayer = Players.LocalPlayer
	ClientData = require(Replicated.Systems.ClientData)
end

function GetSystemMgr()
	if not SystemMgr then
		SystemMgr = require(Replicated.Systems.SystemMgr)
		SENDER = SystemMgr.SENDER
	end
	return SystemMgr
end

function TradeSystem:Init()
	GetSystemMgr()
end

function TradeSystem:PlayerAdded(sender, player, args)
	if IsServer then
		if sender ~= SENDER then
			return
		end

		self.players[player.UserId] = {
			tradingTarget = nil,
			tradingInfo = nil,
			isTrading = false,
		}

		self.Client:PlayerAdded(player, args)
	else
		TradeUi = require(script.ui)
		TradeUi.Init()
	end
end

function TradeSystem:PlayerRemoving(sender, player, args)
	if IsServer then
		if sender ~= SENDER then
			return
		end

		local playerCache = self.players[player.UserId]

		if not playerCache then -- player never in game
			return
		end

		if playerCache.isTrading then
			self:CancelTrade(SENDER, player, {})
		end
		-- in trading
		self.players[player.UserId] = nil
	end
end

function TradeSystem:RequestTrade(sender, player, args)
	if IsServer then
		player = player or sender
		local targetPlr = args.targetPlr

		---- check player in game
		if (not targetPlr) or (not targetPlr:IsDescendantOf(Players)) then
			SystemMgr.systems.GuiSystem:SetNotification(SENDER, player, {
				text = `Player not found.`,
				textColor = Color3.fromRGB(255, 0, 0),
			})
			return
		end

		---- check rebirth
		local playerIns = PlayerServerClass.GetIns(player)
		local rebirth = playerIns:GetOneData(Keys.DataKey.rebirth)
		if rebirth < TradePresets.RebirthReq then
			SystemMgr.systems.GuiSystem:SetNotification(SENDER, player, {
				text = `You need to be rebirth {TradePresets.RebirthReq} to trade.`,
				textColor = Color3.fromRGB(255, 0, 0),
			})
			return
		end

		local targetIns = PlayerServerClass.GetIns(targetPlr)
		local targetRebirth = targetIns:GetOneData(Keys.DataKey.rebirth)
		if targetRebirth < TradePresets.RebirthReq then
			SystemMgr.systems.GuiSystem:SetNotification(SENDER, player, {
				text = `{targetPlr.DisplayName} doesn't meet the rebirth requirement.`,
				textColor = Color3.fromRGB(255, 0, 0),
			})
			return
		end

		---- check disabled trade
		if not targetPlr:GetAttribute("trade") then
			SystemMgr.systems.GuiSystem:SetNotification(SENDER, player, {
				text = `{targetPlr.DisplayName} disabled trade.`,
				textColor = Color3.fromRGB(255, 0, 0),
			})
			return
		end

		---- check is trading
		local playerCache = self.players[player.UserId]
		local targetPlrCache = self.players[targetPlr.UserId]
		if playerCache.isTrading then
			SystemMgr.systems.GuiSystem:SetNotification(SENDER, player, {
				text = `You are already trading with someone.`,
				textColor = Color3.fromRGB(255, 0, 0),
			})
			return
		end

		if targetPlrCache.isTrading then
			SystemMgr.systems.GuiSystem:SetNotification(SENDER, player, {
				text = `{targetPlr.DisplayName} is trading with someone.`,
				textColor = Color3.fromRGB(255, 0, 0),
			})
			return
		end

		playerCache.isTrading = true
		playerCache.tradingTarget = targetPlr
		targetPlrCache.isTrading = true
		targetPlrCache.tradingTarget = player
		SystemMgr.systems.GuiSystem:SetNotification(SENDER, player, {
			text = `Sending trade request to {targetPlr.DisplayName}.`,
			textColor = Color3.fromRGB(0, 255, 0),
		})

		self.Client:TradeComing(targetPlr, { from = player })
	end
end

function TradeSystem:TradeComing(sender, player, args)
	if IsServer then
		-- nothing
	else
		TradeUi.TradeComing(args)
	end
end

function TradeSystem:RespondTradeRequest(sender, player, args)
	if IsServer then
		player = player or sender
		local respond = args.respond

		local playerCache = self.players[player.UserId]
		local fromPlr = playerCache.tradingTarget
		if not fromPlr then
			playerCache.isTrading = false
			return
		end
		local fromPlrCache = self.players[fromPlr.UserId]
		if respond == "accept" then
			local tradingInfo = CreateTradingInfo(fromPlr, player)
			playerCache.tradingTarget = fromPlr
			fromPlrCache.tradingTarget = player
			playerCache.tradingInfo = tradingInfo
			fromPlrCache.tradingInfo = tradingInfo

			self.Client:StartTrading(player, { tradingInfo = tradingInfo })
			self.Client:StartTrading(fromPlr, { tradingInfo = tradingInfo })
		else
			SystemMgr.systems.GuiSystem:SetNotification(SENDER, fromPlr, {
				text = `{player.DisplayName} declined your trade request.`,
				textColor = Color3.fromRGB(255, 0, 0),
			})

			playerCache.isTrading = false
			fromPlrCache.isTrading = false
		end
	end
end

function TradeSystem:StartTrading(sender, player, args)
	if IsServer then
		-- nothing
	else
		TradeUi.StartTrading(args)
	end
end

function TradeSystem:PlayerReady(sender, player, args)
	if IsServer then
		player = player or sender

		local playerCache = self.players[player.UserId]
		if not playerCache.isTrading then
			warn("PlayerReady: not in trading", player)
			return
		end

		local tradingInfo = playerCache.tradingInfo
		if tradingInfo.from == player then
			tradingInfo.fromReady = true
		else
			tradingInfo.toReady = true
		end

		if tradingInfo.fromReady and tradingInfo.toReady then
			self:CountDown(SENDER, player)
		end

		local targetPlr = playerCache.tradingTarget
		self.Client:PlayerReady(targetPlr, tradingInfo)
	else
		TradeUi.PlayerReady(args)
	end
end

function TradeSystem:PlayerUnready(sender, player, args)
	if IsServer then
		player = player or sender

		local playerCache = self.players[player.UserId]
		if not playerCache.isTrading then
			warn("PlayerUnready: not in trading", player)
			return
		end

		local tradingInfo = playerCache.tradingInfo
		if tradingInfo.from == player then
			tradingInfo.fromReady = false
		else
			tradingInfo.toReady = false
		end

		if tradingInfo.countDown then
			task.cancel(tradingInfo.countDown)
		end

		local targetPlr = playerCache.tradingTarget
		self.Client:PlayerUnready(player, { unReadyPlayer = player })
		self.Client:PlayerUnready(targetPlr, { unReadyPlayer = player })
	else
		TradeUi.PlayerUnready(args)
	end
end

function TradeSystem:CancelTrade(sender, player, args)
	if IsServer then
		player = player or sender

		local playerCache = self.players[player.UserId]
		if not playerCache.isTrading then
			-- warn("CancelTrade: not in trading", player)
			return
		end

		local tradingInfo = playerCache.tradingInfo
		if tradingInfo.countDown then
			task.cancel(tradingInfo.countDown)
		end

		local targetPlr = playerCache.tradingTarget
		local targetPlrCache = self.players[targetPlr.UserId]
		targetPlrCache.isTrading = false
		targetPlrCache.tradingTarget = nil
		targetPlrCache.tradingInfo = nil

		playerCache.isTrading = false
		playerCache.tradingTarget = nil
		playerCache.tradingInfo = nil

		self.Client:CancelTrade(targetPlr, { cancelPlr = player })
	else
		TradeUi.CancelTrade(args)
	end
end

function TradeSystem:AddTradingItem(sender, player, args)
	if IsServer then
		player = player or sender
		local itemType = args.itemType
		local itemName = args.itemName

		local playerCache = self.players[player.UserId]
		if not playerCache.isTrading then
			warn("AddTradingItem: not in trading", player)
			return
		end
		local tradingInfo = playerCache.tradingInfo

		local playerIns = PlayerServerClass.GetIns(player)
		local item = { itemType = itemType, itemName = itemName }
		if itemType == Keys.ItemType.pet then
			local pets = playerIns:GetOneData(Keys.DataKey.pets)
			local pet = pets[tonumber(itemName)]
			item.pet = pet
		end
		local fromPlr = tradingInfo.from
		if player == fromPlr then
			table.insert(tradingInfo.fromItems, item)
		else
			table.insert(tradingInfo.toItems, item)
		end

		local targetPlr = playerCache.tradingTarget
		self.Client:AddTradingItem(targetPlr, item)
	else
		TradeUi.TargetAddItem(args)
	end
end

function TradeSystem:DeleteTradingItem(sender, player, args)
	if IsServer then
		player = player or sender

		local playerCache = self.players[player.UserId]
		if not playerCache.isTrading then
			warn("DeleteTradingItem: not in trading", player)
			return
		end
		local tradingInfo = playerCache.tradingInfo

		local fromPlr = tradingInfo.from
		if player == fromPlr then
			for i, item in ipairs(tradingInfo.fromItems) do
				if item.itemType == args.itemType and item.itemName == args.itemName then
					table.remove(tradingInfo.fromItems, i)
					break
				end
			end
		else
			for i, item in ipairs(tradingInfo.toItems) do
				if item.itemType == args.itemType and item.itemName == args.itemName then
					table.remove(tradingInfo.toItems, i)
					break
				end
			end
		end

		local targetPlr = playerCache.tradingTarget
		self.Client:DeleteTradingItem(targetPlr, args)
	else
		TradeUi.TargetDeleteItem(args)
	end
end

function TradeSystem:CountDown(sender, player, args)
	if IsServer then
		if sender ~= SENDER then
			return
		end
		local playerCache = self.players[player.UserId]
		local tradingInfo = playerCache.tradingInfo
		tradingInfo.countDown = task.delay(5, function()
			self:CompleteTrading(SENDER, player, { tradingInfo = tradingInfo })
		end)

		self.Client:CountDown(tradingInfo.from, { tradingInfo = tradingInfo })
		self.Client:CountDown(tradingInfo.to, { tradingInfo = tradingInfo })
	else
		TradeUi.CountDown(args)
	end
end

function TradeSystem:CompleteTrading(sender, player, args)
	if IsServer then
		if sender ~= SENDER then
			return
		end

		local playerCache = self.players[player.UserId]
		if not playerCache.isTrading then
			warn("CompleteTrading: not in trading", player)
			return
		end

		local tradingInfo = playerCache.tradingInfo

		print("complete", tradingInfo)
		local fromPlr = tradingInfo.from
		local toPlr = tradingInfo.to

		self.Client:CompleteTrading(fromPlr, { tradingInfo = tradingInfo })
		self.Client:CompleteTrading(toPlr, { tradingInfo = tradingInfo })

		---- delete items
		local petsList = {}
		for _, item in ipairs(tradingInfo.fromItems) do
			if item.itemType == Keys.ItemType.pet then
				table.insert(petsList, item.pet.index)
			end
		end
		SystemMgr.systems.PetSystem:DeletePet(SENDER, fromPlr, { petsList = petsList })

		petsList = {}
		for _, item in ipairs(tradingInfo.toItems) do
			if item.itemType == Keys.ItemType.pet then
				table.insert(petsList, item.pet.index)
			end
		end
		SystemMgr.systems.PetSystem:DeletePet(SENDER, toPlr, { petsList = petsList })

		---- add items
		for _, item in ipairs(tradingInfo.fromItems) do
			if item.itemType == Keys.ItemType.pet then
				SystemMgr.systems.PetSystem:AddNewPet(SENDER, toPlr, {
					petName = item.pet.name,
					star = item.pet.star,
					rank = item.pet.rank,
				})
			end
		end

		for _, item in ipairs(tradingInfo.toItems) do
			if item.itemType == Keys.ItemType.pet then
				SystemMgr.systems.PetSystem:AddNewPet(SENDER, fromPlr, {
					petName = item.pet.name,
					star = item.pet.star,
					rank = item.pet.rank,
				})
			end
		end

		---- clean up
		local fromPlrCache = self.players[fromPlr.UserId]
		local toPlrCache = self.players[toPlr.UserId]

		fromPlrCache.isTrading = false
		toPlrCache.isTrading = false
		fromPlrCache.tradingInfo = nil
		toPlrCache.tradingInfo = nil
	else
		TradeUi.CompleteTrading(args)
	end
end

---- [[ Server ]] ----
function CreateTradingInfo(from, to)
	return {
		from = from,
		to = to,
		fromItems = {},
		toItems = {},
		fromReady = false,
		toReady = false,
		countDown = nil,
	}
end

return TradeSystem
