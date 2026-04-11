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
local PlayerServerClass, AnalyticsService

---- client variables ----
local LocalPlayer, ClientData
local PotionUi = { pendingCalls = {} }
setmetatable(PotionUi, Types.mt)

local PotionSystem = {
	whiteList = {},
	players = {},
	tasks = {},
	IsLoaded = false,
}
PotionSystem.__index = PotionSystem

if IsServer then
	PotionSystem.Client = setmetatable({}, PotionSystem)
	local ServerStorage = game:GetService("ServerStorage")
	PlayerServerClass = require(ServerStorage.classes.PlayerServerClass)
	AnalyticsService = game:GetService("AnalyticsService")
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
		local potionId = args.potionId
		local playerIns = PlayerServerClass.GetIns(player)
		local potions = playerIns:GetOneData(dataKey.potions)

		if not potions[potionId] or potions[potionId] <= 0 then
			SystemMgr.systems.GuiSystem:SetNotification(SENDER, player, "You don't have enough potion.")
			return
		end

		potions[potionId] -= 1
		AnalyticsService:LogCustomEvent(player, "usePotion", 1, {
			[Enum.AnalyticsCustomFieldKeys.CustomField01.Name] = potionId,
		})

		SystemMgr.systems.QuestSystem:AddProgress(SENDER, player, {
			questType = Keys.QuestType.useAnyPotion,
			value = 1,
		})

		SystemMgr.systems.QuestSystem:AddProgress(SENDER, player, {
			questType = Keys.QuestType.useNamedPotion,
			name = potionId,
			value = 1,
		})

		SystemMgr.systems.BuffSystem:AddBuff(SENDER, player, {
			buffName = PotionPresets.Potions[potionId].buffName,
			duration = PotionPresets.Potions[potionId].duration,
		})
		self.Client:UsePotion(player, { potions = potions })
	else
		ClientData:SetOneData(dataKey.potions, args.potions)
		PotionUi.UpdatePotionCount()
	end
end

function PotionSystem:AddPotion(sender, player, args)
	if IsServer then
		if sender ~= SENDER then
			return
		end
		local potionId = args.potionName
		local count = args.count
		local playerIns = PlayerServerClass.GetIns(player)
		local potions = playerIns:GetOneData(dataKey.potions)
		if potions[potionId] then
			potions[potionId] += count
		else
			potions[potionId] = count
		end

		self.Client:AddPotion(player, {
			potions = potions,
		})
	else
		ClientData:SetOneData(dataKey.potions, args.potions)
		PotionUi.UpdatePotionCount()
	end
end

return PotionSystem
