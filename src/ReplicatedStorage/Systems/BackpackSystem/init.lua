--[[
--Author: TimeM_chine
--Created Date: Wed Feb 21 2024
--Description: init.lua
--Version: 1.0
--Last Modified: 2024-04-24 4:19:09
--]]

---- services ----
local Players = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

---- requires ----
local BackpackPresets = require(script.Presets)
local Types = require(Replicated.configs.Types)
local Keys = require(Replicated.configs.Keys)
local Util = require(Replicated.modules.Util)
local BlockPresets = require(Replicated.Systems.BlockSystem.Presets)

---- common variables ----
local IsServer = RunService:IsServer()
local SENDER, SystemMgr

---- server variables ----
local PlayerServerClass
local ServerToolHandler

---- client variables ----
local LocalPlayer, ClientData
local BackpackUi = { pendingCalls = {} }
setmetatable(BackpackUi, Types.mt)

local BackpackSystem: Types.System = {
	whiteList = {},
	players = {},
	tasks = {},
	IsLoaded = false,
}
BackpackSystem.__index = BackpackSystem

if IsServer then
	BackpackSystem.Client = setmetatable({}, BackpackSystem)
	-- Template.AllClients = setmetatable({}, Template)
	local ServerStorage = game:GetService("ServerStorage")
	PlayerServerClass = require(ServerStorage.classes.PlayerServerClass)
	ServerToolHandler = require(script.ServerToolHandler)
else
	BackpackSystem.Server = setmetatable({}, BackpackSystem)
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

function BackpackSystem:Init()
	GetSystemMgr()
end

function BackpackSystem:PlayerAdded(sender, player, args)
	if IsServer then
		if sender ~= SENDER then
			return
		end

		self.Client:PlayerAdded(player, args)
	else
		local pendingCalls = BackpackUi.pendingCalls

		BackpackUi = require(script.ui)
		BackpackUi.Init()

		for _, call in ipairs(pendingCalls) do
			BackpackUi[call.functionName](table.unpack(call.args))
		end
	end
end

function BackpackSystem:AddItems(sender, player, args)
	if IsServer then
		if sender ~= SENDER then
			return
		end
		local items = args.items
		local playerIns = PlayerServerClass.GetIns(player)
		local backpack = playerIns:GetOneData(Keys.DataKey.backpack)

		for _, item in ipairs(items) do
			local itemType = item.itemType
			local itemName = item.itemName
			local count = item.count

			if not backpack[itemType] then
				backpack[itemType] = {}
			end

			if itemType == Keys.ItemType.weapons then
				SystemMgr.systems.WeaponSystem:AddWeaponList(SENDER, player, {
					weaponList = {
						{
							weaponId = itemName,
							tier = "normal",
							size = 1,
							equipped = false,
						},
					},
				})
				return
			else
				if not backpack[itemType][itemName] then
					backpack[itemType][itemName] = 0
				end
				backpack[itemType][itemName] += count
			end
		end
		args = {
			backpack = backpack,
			items = items,
			operation = "add",
		}
		self.Client:AddItems(player, args)
	else
		ClientData:SetOneData(Keys.DataKey.backpack, args.backpack)
		BackpackUi.AddItems(args)
	end
end

function BackpackSystem:DeleteItems(sender, player, args)
	if IsServer then
		player = player or sender

		local items = args.items
		local playerIns = PlayerServerClass.GetIns(player)
		local backpack = playerIns:GetOneData(Keys.DataKey.backpack)

		for _, item in ipairs(items) do
			local itemType = item.itemType
			local itemName = item.itemName
			local count = item.count or 1

			if backpack[itemType] and backpack[itemType][itemName] then
				backpack[itemType][itemName] -= count
				if backpack[itemType][itemName] <= 0 then
					backpack[itemType][itemName] = nil
				end
			end
		end

		args = {
			backpack = backpack,
			deleted = items,
		}

		self.Client:DeleteItems(player, args)
	else
		ClientData:SetOneData(Keys.DataKey.backpack, args.backpack)
		BackpackUi.UpdateItem(args)
	end
end

function BackpackSystem:SellItems(sender, player, args)
	if IsServer then
		player = player or sender

		local items = args.items
		if not items or #items == 0 then
			return
		end

		local playerIns = PlayerServerClass.GetIns(player)
		local backpack = playerIns:GetOneData(Keys.DataKey.backpack)

		local totalValue = 0

		for _, item in ipairs(items) do
			local itemType = item.itemType
			local itemName = item.itemName

			if backpack[itemType] and backpack[itemType][itemName] then
				local count = item.count or 1

				local actualCount = math.min(backpack[itemType][itemName], count)
				backpack[itemType][itemName] -= actualCount
				if backpack[itemType][itemName] <= 0 then
					backpack[itemType][itemName] = nil
				end

				local itemValue = 10 -- default price
				if itemType == Keys.ItemType.ores and BlockPresets.Ores[itemName] then
					itemValue = BlockPresets.Ores[itemName].sellPrice
				end
				totalValue = totalValue + (itemValue * actualCount)
			end
		end

		if totalValue > 0 then
			SystemMgr.systems.EcoSystem:AddResource(SENDER, player, {
				resourceType = Keys.ItemType.wins,
				count = totalValue,
			})

			SystemMgr.systems.GuiSystem:SetNotification(SENDER, player, {
				text = "Sold items for " .. Util.FormatNumber(totalValue) .. " cash!",
				textColor = Color3.fromRGB(255, 215, 0),
			})
		end

		args = {
			backpack = backpack,
			totalValue = totalValue,
			deleted = items,
		}

		self.Client:SellItems(player, args)
	else
		ClientData:SetOneData(Keys.DataKey.backpack, args.backpack)
		BackpackUi.UpdateItem(args)
	end
end

function BackpackSystem:LockItem(sender, player, args)
	if IsServer then
		player = player or sender

		local itemType = args.itemType
		local itemId = args.itemId
		local locked = args.locked

		local playerIns = PlayerServerClass.GetIns(player)
		local backpack = playerIns:GetOneData(Keys.DataKey.backpack)

		if not backpack.lockedItems then
			backpack.lockedItems = {}
		end

		local lockKey = itemType .. "_" .. itemId

		if locked then
			backpack.lockedItems[lockKey] = true
		else
			backpack.lockedItems[lockKey] = nil
		end

		-- Save to data
		playerIns:SetOneData(Keys.DataKey.backpack, backpack)

		-- Update client
		self.Client:LockItem(player, {
			backpack = backpack,
			itemType = itemType,
			itemId = itemId,
			locked = locked,
		})
	else
		-- Client side - update Satchel
		ClientData:SetOneData(Keys.DataKey.backpack, args.backpack)
		BackpackUi.UpdateItem(args)
	end
end

function BackpackSystem:UnequipItem(sender, player, args)
	if IsServer then
		player = player or sender

		-- Remove tool model from player
		ServerToolHandler.UnequipTool(player)
	end
end

function BackpackSystem:UpdateBackpack(sender, player, args)
	if IsServer then
		if sender ~= SENDER then
			return
		end
	end
end

function BackpackSystem:EquipItem(sender, player, args)
	if IsServer then
		player = player or sender

		local itemType = args.itemType
		local itemName = args.itemName

		if not itemType or not itemName then
			warn("EquipItem: Missing itemType or itemName")
			return
		end

		-- Create and attach tool model to player's hand
		local success = ServerToolHandler.EquipTool(player, itemType, itemName)
		if not success then
			warn(`Failed to equip tool {itemName} for player {player.Name}`)
		end
	end
end

function BackpackSystem:PlayerRemoving(sender, player, args)
	if IsServer then
		if sender ~= SENDER then
			return
		end

		-- Clean up any equipped tools
		ServerToolHandler.PlayerRemoving(player)
	end
end

return BackpackSystem
