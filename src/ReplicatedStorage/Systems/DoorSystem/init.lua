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
local DoorPresets = require(script.Presets)
local Types = require(Replicated.configs.Types)
local Keys = require(Replicated.configs.Keys)
local Util = require(Replicated.modules.Util)
local GameConfig = require(Replicated.configs.GameConfig)
local PlayerPresets = require(Replicated.Systems.PlayerSystem.Presets)

---- common variables ----
local IsServer = RunService:IsServer()
local SENDER, SystemMgr
local dataKey = Keys.DataKey
local spawnLocations = workspace:WaitForChild("SpawnLocations")

---- server variables ----
local PlayerServerClass, AnalyticsService

---- client variables ----
local LocalPlayer, ClientData, DoorUi

local DoorSystem: Types.System = {
	whiteList = {},
	players = {},
	tasks = {},
	IsLoaded = false,
}
DoorSystem.__index = DoorSystem

if IsServer then
	DoorSystem.Client = setmetatable({}, DoorSystem)
	-- Template.AllClients = setmetatable({}, Template)
	local ServerStorage = game:GetService("ServerStorage")
	PlayerServerClass = require(ServerStorage.classes.PlayerServerClass)
	AnalyticsService = game:GetService("AnalyticsService")
else
	DoorSystem.Server = setmetatable({}, DoorSystem)
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

function DoorSystem:Init()
	GetSystemMgr()
end

function DoorSystem:PlayerAdded(sender, player, args)
	if IsServer then
		if sender ~= SENDER then
			return
		end

		self.Client:PlayerAdded(player, args)
	else
		DoorUi = require(script.ui)
		DoorUi.Init()
	end
end

function DoorSystem:TouchDoor(sender, player, args)
	if IsServer then
		player = player or sender
		local zoneIndex = args.zoneIndex
		local playerIns = PlayerServerClass.GetIns(player)
		local maxZone = playerIns:GetOneData(dataKey.maxZone)
		if maxZone >= zoneIndex then
			TeleportToZone(player, zoneIndex)
		elseif maxZone + 1 == zoneIndex then
			TryUnlockZone(player, zoneIndex)
		end
	else
		ClientData:SetOneData(dataKey.maxZone, args.zoneIndex)
		DoorUi.UnlockZone(args.zoneIndex)
	end
end

function DoorSystem:TryTeleportToZone(sender, player, args)
	if IsServer then
		player = player or sender
		if player:GetAttribute("isBattle") then
			SystemMgr.systems.GuiSystem:SetNotification(SENDER, player, {
				text = "You can't teleport while in battle",
				textColor = Color3.fromRGB(255, 0, 0),
			})
			return
		end

		local zoneIndex = args.zoneIndex
		local playerIns = PlayerServerClass.GetIns(player)
		local maxZone = playerIns:GetOneData(dataKey.maxZone)
		if maxZone >= zoneIndex then
			TeleportToZone(player, zoneIndex)
		else
			SystemMgr.systems.GuiSystem:SetNotification(SENDER, player, {
				text = "You need to unlock this zone first",
			})
		end
	else
		ClientData:SetOneData(dataKey.nowZone, args.zoneIndex)
		DoorUi.TeleportDone()
	end
end

----- [[ Server ]] ----

function TeleportToZone(player, zoneIndex)
	DoorSystem.Client:TryTeleportToZone(player, { zoneIndex = zoneIndex })
	local playerIns = PlayerServerClass.GetIns(player)
	playerIns:SetOneData(dataKey.nowZone, zoneIndex)
	local spawnLocation = spawnLocations:FindFirstChild(zoneIndex)
	task.delay(1, function()
		player.Character:PivotTo(spawnLocation.CFrame + Vector3.new(0, 3, 0))
	end)
	if SystemMgr and SystemMgr.systems and SystemMgr.systems.BlockSystem then
		SystemMgr.systems.BlockSystem:SyncZoneToPlayer(SENDER, player, { zoneIndex = zoneIndex })
	end
	SystemMgr.systems.WeaponSystem:TeleportHandle(SENDER, player, { zoneIndex = zoneIndex })
	SystemMgr.systems.QuestSystem:AddProgress(SENDER, player, {
		questType = Keys.QuestType.goToZone,
		value = 1,
	})
	-- SystemMgr.systems.WildControlSystem.Client:TeleportHandle(player, { ZoneId = "Zone" .. zoneIndex })
	-- SystemMgr.systems.TrainSystem:TeleportTo(SENDER, player, { zoneIndex = zoneIndex })
	-- SystemMgr.systems.BattleSystem.Client:TeleportTo(player, { zoneIndex = zoneIndex })
end

function TryUnlockZone(player, zoneIndex)
	local playerIns = PlayerServerClass.GetIns(player)
	local itemType = DoorPresets.UnlockCondition[zoneIndex].itemType
	local cost = DoorPresets.UnlockCondition[zoneIndex].cost
	local ownItem = playerIns:GetOneData(itemType)
	if ownItem < cost then
		SystemMgr.systems.GuiSystem:SetNotification(SENDER, player, {
			text = `You don't have enough {itemType} to unlock this zone`,
			textColor = Color3.fromRGB(255, 0, 0),
		})
		return
	end

	local hunterLevel = DoorPresets.UnlockCondition[zoneIndex].hunterLevel
	local plrLevel = PlayerPresets.GetLevelByExp(playerIns:GetOneData(dataKey.hunterExp))
	if plrLevel < hunterLevel then
		SystemMgr.systems.GuiSystem:SetNotification(SENDER, player, {
			text = "You need to reach level " .. hunterLevel .. " to unlock this zone",
			textColor = Color3.fromRGB(255, 0, 0),
		})
		return
	end
	SystemMgr.systems.EcoSystem:AddResource(SENDER, player, {
		resourceType = itemType,
		count = -cost,
		reason = "UnlockZone",
	})

	-- Util.awardBadge(player, GameConfig.Zones[zoneIndex].badgeId)

	-- SystemMgr.systems.FreeRewardSystem:UnlockZone(SENDER, player, { zoneIndex = zoneIndex })

	playerIns:SetOneData(dataKey.maxZone, zoneIndex)
	-- TeleportToZone(player, zoneIndex)

	DoorSystem.Client:TouchDoor(player, { zoneIndex = zoneIndex })
end

return DoorSystem
