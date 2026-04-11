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
local RebirthPresets = require(script.Presets)
local Types = require(Replicated.configs.Types)
local Keys = require(Replicated.configs.Keys)

---- common variables ----
local IsServer = RunService:IsServer()
local SENDER, SystemMgr
local dataKey = Keys.DataKey

---- server variables ----
local PlayerServerClass, AnalyticsService

---- client variables ----
local LocalPlayer, ClientData, RebirthUi, EcoUi, DailyUi, SpinUi, GiftUi

local RebirthSystem: Types.System = {
	whiteList = {},
	players = {},
	tasks = {},
	IsLoaded = false,
}
RebirthSystem.__index = RebirthSystem

if IsServer then
	RebirthSystem.Client = setmetatable({}, RebirthSystem)
	-- Template.AllClients = setmetatable({}, Template)
	local ServerStorage = game:GetService("ServerStorage")
	PlayerServerClass = require(ServerStorage.classes.PlayerServerClass)
	AnalyticsService = game:GetService("AnalyticsService")
else
	RebirthSystem.Server = setmetatable({}, RebirthSystem)
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

function RebirthSystem:Init()
	GetSystemMgr()
end

function RebirthSystem:PlayerAdded(sender, player, args)
	if IsServer then
		if sender ~= SENDER then
			return
		end

		self.Client:PlayerAdded(player, args)
	else
		RebirthUi = require(script.ui)
		RebirthUi.Init()
	end
end

function RebirthSystem:TryRebirth(sender, player, args)
	if IsServer then
		player = player or sender
		local playerIns = PlayerServerClass.GetIns(player)
		local wins = playerIns:GetOneData(dataKey.wins)
		local rebirth = playerIns:GetOneData(dataKey.rebirth)
		if not RebirthPresets.RebirthConfig[rebirth + 1] then
			SystemMgr.systems.GuiSystem:SetNotification(SENDER, player, {
				text = "You have reached the maximum rebirth level!",
			})
			return
		end
		local cost = RebirthPresets.RebirthConfig[rebirth].cost
		if wins >= cost then
			SystemMgr.systems.EcoSystem:AddResource(SENDER, player, {
				resourceType = Keys.ItemType.wins,
				count = -cost,
				reason = "rebirth",
			})
			self:Rebirth(SENDER, player)
		else
			SystemMgr.systems.GuiSystem:SetNotification(SENDER, player, {
				text = "You don't have enough wins to rebirth!",
			})
			return
		end
	end
end

function RebirthSystem:Rebirth(sender, player, args)
	if IsServer then
		if sender ~= SENDER then
			return
		end
		local playerIns = PlayerServerClass.GetIns(player)
		playerIns:AddOneData(dataKey.rebirth, 1)
		args = {
			rebirth = playerIns:GetOneData(dataKey.rebirth),
			wins = playerIns:GetOneData(dataKey.wins),
		}

		SystemMgr.systems.QuestSystem:DoQuest(player, {
            questType = Keys.QuestType.rebirth,
            value = 1,
            name = "rebirth"
        })
		AnalyticsService:LogCustomEvent(player, "rebirth")
		SystemMgr.systems.PlayerSystem:Rebirth(SENDER, player)
		SystemMgr.systems.TrainSystem:StopTrain(SENDER, player)
        SystemMgr.systems.CharacterSystem:PowerCheck(player)
		self.Client:Rebirth(player, args)
	else
		ClientData:SetOneData(dataKey.rebirth, args.rebirth)
		RebirthUi.UpdateUi(args)

		if not EcoUi then
			EcoUi = require(Replicated.Systems.EcoSystem.ui)
		end
		EcoUi.UpdateWinsStore()

		if not DailyUi then
			DailyUi = require(Replicated.Systems.DailySystem.ui)
		end
		DailyUi.UpdateRewards()

		if not SpinUi then
			SpinUi = require(Replicated.Systems.SpinSystem.ui)
		end
		SpinUi.UpdateRewards()

		if not GiftUi then
			GiftUi = require(Replicated.Systems.GiftSystem.ui)
		end
		GiftUi.UpdateGiftRewards()
	end
end

---- [[ Server ]] ----
function RebirthSystem:GetRebirthBoost(player)
	local playerIns = PlayerServerClass.GetIns(player)
	local rebirth = playerIns:GetOneData(dataKey.rebirth)
	return RebirthPresets.RebirthConfig[rebirth].boost + 1
end

return RebirthSystem
