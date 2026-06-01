---- services ----
local Replicated = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

---- requires ----
local PotionPresets = require(script.PotionPresets)
local Types = require(Replicated.configs.Types)
local Keys = require(Replicated.configs.Keys)
local dataKey = Keys.DataKey

---- common variables ----
local IsServer = RunService:IsServer()
local SENDER, SystemMgr

---- server variables ----
local PlayerServerClass

---- client variables ----
local LocalPlayer, ClientData
local PotionUi = { pendingCalls = {} }
setmetatable(PotionUi, Types.mt)

local PotionSystem = {
	whiteList = {
		"AddPotion",
		"GrantAndUsePotion",
	},
	players = {},
	tasks = {},
	IsLoaded = false,
}
PotionSystem.__index = PotionSystem

if IsServer then
	PotionSystem.Client = setmetatable({}, PotionSystem)
	local ServerStorage = game:GetService("ServerStorage")
	PlayerServerClass = require(ServerStorage.classes.PlayerServerClass)
else
	PotionSystem.Server = setmetatable({}, PotionSystem)
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

function PotionSystem:Init()
	GetSystemMgr()
end

function PotionSystem:PlayerAdded(sender, player, args)
	if IsServer then
		if sender ~= SENDER then
			return
		end

		self.Client:PlayerAdded(player)
	else
		local pendingCalls = PotionUi.pendingCalls

		PotionUi = require(script.ui)
		PotionUi.Init()

		for _, call in ipairs(pendingCalls) do
			PotionUi[call.functionName](table.unpack(call.args))
		end
	end
end

function PotionSystem:UsePotion(sender, player, args)
	if IsServer then
		player = player or sender
		if not player or not player:IsDescendantOf(Players) then
			return false
		end
		if typeof(args) ~= "table" or typeof(args.potionId) ~= "string" then
			return false
		end
		local potionId = args.potionId
		local potionConfig = PotionPresets.Potions[potionId]
		if not potionConfig then
			return false
		end
		local playerIns = PlayerServerClass.GetIns(player)
		if not playerIns then
			return false
		end
		local potions = playerIns:GetOneData(dataKey.potions)

		if not potions[potionId] or potions[potionId] <= 0 then
			SystemMgr.systems.GuiSystem:SetNotification(SENDER, player, {
				text = "You don't have enough potion.",
			})
			return false
		end

		local source = sender == SENDER and (args.source or potionConfig.source) or potionConfig.source
		potions[potionId] -= 1

		SystemMgr.systems.BuffSystem:AddBuff(SENDER, player, {
			buffName = potionConfig.buffName,
			duration = potionConfig.duration,
			source = source,
			potionId = potionId,
		})
		SystemMgr.systems.AnalyticsSystem:LogPotionUsed(SENDER, player, {
			potionId = potionId,
			buffName = potionConfig.buffName,
			duration = potionConfig.duration,
			source = source,
		})
		self.Client:UsePotion(player, { potions = potions })
		return true
	else
		ClientData:SetOneData(dataKey.potions, args.potions)
		PotionUi.UpdatePotionCount()
	end
end

function PotionSystem:AddPotion(sender, player, args)
	if IsServer then
		if sender ~= SENDER then
			return false
		end
		if not player or not player:IsDescendantOf(Players) then
			return false
		end
		if typeof(args) ~= "table" then
			return false
		end
		local potionId = args.potionName
		local count = args.count
		local potionConfig = PotionPresets.Potions[potionId]
		if not potionConfig or typeof(count) ~= "number" or count <= 0 then
			return false
		end
		local playerIns = PlayerServerClass.GetIns(player)
		if not playerIns then
			return false
		end
		local potions = playerIns:GetOneData(dataKey.potions)
		if potions[potionId] then
			potions[potionId] += count
		else
			potions[potionId] = count
		end
		SystemMgr.systems.AnalyticsSystem:LogPotionGranted(SENDER, player, {
			potionId = potionId,
			buffName = potionConfig.buffName,
			duration = potionConfig.duration,
			count = count,
			source = args.source or potionConfig.source,
		})

		self.Client:AddPotion(player, {
			potions = potions,
		})
		return true
	else
		ClientData:SetOneData(dataKey.potions, args.potions)
		PotionUi.UpdatePotionCount()
	end
end

function PotionSystem:GrantAndUsePotion(sender, player, args)
	if IsServer then
		if sender ~= SENDER then
			return false
		end
		if not player or not player:IsDescendantOf(Players) then
			return false
		end
		if typeof(args) ~= "table" or typeof(args.potionName) ~= "string" then
			return false
		end
		if not PotionPresets.Potions[args.potionName] then
			return false
		end

		local added = self:AddPotion(SENDER, player, {
			potionName = args.potionName,
			count = args.count or 1,
			source = args.source,
		})
		if not added then
			return false
		end
		return self:UsePotion(SENDER, player, {
			potionId = args.potionName,
			source = args.source,
		})
	else
		return false
	end
end

return PotionSystem
