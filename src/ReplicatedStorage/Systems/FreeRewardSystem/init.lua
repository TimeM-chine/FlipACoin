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
local FreeRewardPresets = require(script.Presets)
local Types = require(Replicated.configs.Types)
local GameConfig = require(Replicated.configs.GameConfig)
local Keys = require(Replicated.configs.Keys)

---- common variables ----
local IsServer = RunService:IsServer()
local dataKey = Keys.DataKey
local SENDER, SystemMgr

---- server variables ----
local PlayerServerClass

---- client variables ----
local LocalPlayer, ClientData, FreeRewardUi

local FreeRewardSystem: Types.System = {
	whiteList = {},
	players = {},
	tasks = {},
	IsLoaded = false,
}
FreeRewardSystem.__index = FreeRewardSystem

if IsServer then
	FreeRewardSystem.Client = setmetatable({}, FreeRewardSystem)
	-- Template.AllClients = setmetatable({}, Template)
	local ServerStorage = game:GetService("ServerStorage")
	PlayerServerClass = require(ServerStorage.classes.PlayerServerClass)
else
	FreeRewardSystem.Server = setmetatable({}, FreeRewardSystem)
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

function FreeRewardSystem:Init()
	GetSystemMgr()
end

function FreeRewardSystem:PlayerAdded(sender, player, args)
	if IsServer then
		if sender ~= SENDER then
			return
		end
		self.players[player.UserId] = {
			online = os.time(),
			claimed = false,
		}

		local playerIns = PlayerServerClass.GetIns(player)
		for i, task in ipairs(FreeRewardPresets.Reward.quests) do
			if task.questType == Keys.QuestType.afterPeriod then
				local startTimes = playerIns:GetOneData(dataKey.startTimes)
				if not startTimes["FreeOPReward"] then
					startTimes["FreeOPReward"] = os.time()
				end
				break
			end
		end

		self.Client:PlayerAdded(player, {
			startTimes = playerIns:GetOneData(dataKey.startTimes),
		})
	else
		ClientData:SetOneData(Keys.DataKey.startTimes, args.startTimes)
		FreeRewardUi = require(script.ui)
		FreeRewardUi.Init()
	end
end

function FreeRewardSystem:TryClaim(sender, player, args)
	if IsServer then
		player = player or sender

		local playerCache = self.players[player.UserId]
		local target = FreeRewardPresets.Reward.quests[1].target
		if os.time() - playerCache.online < GameConfig.OneMinute * target then
			SystemMgr.systems.GuiSystem:SetNotification(SENDER, player, {
				text = "You need to play for " .. target .. " minutes!",
			})
			return
		end

		local playerIns = PlayerServerClass.GetIns(player)
		local startTimes = playerIns:GetOneData(dataKey.startTimes)
		local lastTime = startTimes["FreeOPReward"]
		if os.time() - lastTime < FreeRewardPresets.Reward.quests[2].target then
			SystemMgr.systems.GuiSystem:SetNotification(SENDER, player, {
				text = "You need to join game after 24 hours!",
			})
			return
		end

		self:ClaimReward(SENDER, player, args)
	end
end

function FreeRewardSystem:ClaimReward(sender, player, args)
	if IsServer then
		if sender ~= SENDER then
			return
		end

		local playerCache = self.players[player.UserId]
		if playerCache.claimed then
			return
		end
		playerCache.claimed = true

		local reward = FreeRewardPresets.Reward.reward
		reward.reason = "FreeReward"
		SystemMgr.systems.EcoSystem:GiveItem(SENDER, player, reward)
		self.Client:ClaimReward(player)
	else
		FreeRewardUi.ClaimReward()
	end
end

function FreeRewardSystem:UnlockZone(sender, player, args)
	if IsServer then
		if sender ~= SENDER then
			return
		end
		local zoneIndex = args.zoneIndex
		if zoneIndex ~= FreeRewardPresets.Reward.quests[2].zoneIndex then
			return
		end

		self.Client:UnlockZone(player, args)
	else
		FreeRewardUi.UnlockZone(args.zoneIndex)
	end
end

return FreeRewardSystem
