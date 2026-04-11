--[[
--Author: TimeM_chine
--Created Date: Wed Feb 21 2024
--Description: init.lua
--Version: 1.2
--Last Modified: 2024-04-24 4:19:09
--]]

---- services ----
local Players = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

---- requires ----
local BuffPresets = require(script.Presets)
local Types = require(Replicated.configs.Types)
local Keys = require(Replicated.configs.Keys)
local GameConfig = require(Replicated.configs.GameConfig)
local Util = require(Replicated.modules.Util)

---- common variables ----
local IsServer = RunService:IsServer()
local SENDER, SystemMgr
local dataKey = Keys.DataKey

---- server variables ----
local PlayerServerClass

---- client variables ----
local LocalPlayer, ClientData
local BuffUi = { pendingCalls = {} }
setmetatable(BuffUi, Types.mt)

local BuffSystem: Types.System = {
	whiteList = {
		"GetWinsBoost",
		"GetLuckyBoost",
	},
	players = {},
	tasks = {},
	IsLoaded = false,
}
BuffSystem.__index = BuffSystem

if IsServer then
	BuffSystem.Client = setmetatable({}, BuffSystem)
	-- Template.AllClients = setmetatable({}, Template)
	local ServerStorage = game:GetService("ServerStorage")
	PlayerServerClass = require(ServerStorage.classes.PlayerServerClass)
else
	BuffSystem.Server = setmetatable({}, BuffSystem)
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

function BuffSystem:Init()
	GetSystemMgr()
end

function BuffSystem:PlayerAdded(sender, player, args)
	if IsServer then
		if sender ~= SENDER then
			return
		end

		local playerIns = PlayerServerClass.GetIns(player)
		if not playerIns then
			return
		end

		self.players[player.UserId] = {
			friendCount = 0,
			countDowns = {},
			joinTime = os.time(),
		}

		for _, plr in ipairs(Players:GetPlayers()) do
			if plr == player then
				continue
			end
			-- check if friend
			local isFriend
			local success, message = pcall(function()
				isFriend = player:IsFriendsWith(plr.UserId)
			end)

			if success and isFriend then
				-- if true then
				self.players[player.UserId].friendCount += 1
				self.players[plr.UserId].friendCount += 1
				self:UpdateFriendBuff(SENDER, plr)
			end
		end
		self:UpdateFriendBuff(SENDER, player)

		local equippedBuff = playerIns:GetOneData(dataKey.equippedBuff)
		for name, status in equippedBuff do
			if status.startTime + status.duration < os.time() then
				equippedBuff[name] = nil
			else
				self:AddBuff(SENDER, player, { buffName = name })
			end
		end

		self.Client:PlayerAdded(player, {
			friendCount = self.players[player.UserId].friendCount,
		})
	else
		local pendingCalls = BuffUi.pendingCalls

		BuffUi = require(script.ui)
		BuffUi.Init()

		for _, call in ipairs(pendingCalls) do
			BuffUi[call.functionName](table.unpack(call.args))
		end
	end
end

function BuffSystem:PlayerRemoving(sender, player, args)
	if IsServer then
		if sender ~= SENDER then
			return
		end

		if not self.players[player.UserId] then
			return
		end

		for _, countDown in pairs(self.players[player.UserId].countDowns) do
			task.cancel(countDown)
		end

		self.players[player.UserId] = nil

		for _, plr in ipairs(Players:GetPlayers()) do
			if plr == player then
				continue
			end
			-- check if friend
			local isFriend
			local success, message = pcall(function()
				isFriend = player:IsFriendsWith(plr.UserId)
			end)

			if success and isFriend then
				-- if true then
				if not self.players[plr.UserId] then
					continue
				end
				self.players[plr.UserId].friendCount -= 1
				self:UpdateFriendBuff(SENDER, plr)
			end
		end
	end
end

function BuffSystem:UpdateFriendBuff(sender, player, args)
	if IsServer then
		if sender ~= SENDER then
			return
		end
		self.Client:UpdateFriendBuff(player, {
			friendCount = self.players[player.UserId].friendCount,
		})
	else
		BuffUi.UpdateFriendBuff(args)
	end
end

function BuffSystem:AddBuff(sender, player, args)
	if IsServer then
		if sender ~= SENDER then
			return
		end

		local buffName = args.buffName
		local duration = args.duration or 0

		local playerIns = PlayerServerClass.GetIns(player)

		local equippedBuff = playerIns:GetOneData(dataKey.equippedBuff)
		if equippedBuff[buffName] then
			equippedBuff[buffName].duration += duration
		else
			equippedBuff[buffName] = {
				duration = duration,
				startTime = os.time(),
			}
		end

		local playerCache = self.players[player.UserId]
		if playerCache.countDowns[buffName] then
			task.cancel(playerCache.countDowns[buffName])
		end

		local delayTime = equippedBuff[buffName].startTime + equippedBuff[buffName].duration - os.time()
		playerCache.countDowns[buffName] = task.delay(delayTime, function()
			equippedBuff[buffName] = nil
			playerCache.countDowns[buffName] = nil
		end)

		self.Client:AddBuff(player, {
			buffName = buffName,
			startTime = equippedBuff[buffName].startTime,
			duration = equippedBuff[buffName].duration,
			equippedBuff = equippedBuff,
		})
	else
		ClientData:SetOneData(dataKey.equippedBuff, args.equippedBuff)
		BuffUi.AddBuff(args)
	end
end

---- [[ Server ]] ----
function BuffSystem:GetWinsBoost(player)
	local playerIns = PlayerServerClass.GetIns(player)
	local equippedBuff = playerIns:GetOneData(dataKey.equippedBuff)
	local boost = 1
	for name, status in equippedBuff do
		if BuffPresets.Buffs[name] and BuffPresets.Buffs[name].boostType == dataKey.wins then
			boost += BuffPresets.Buffs[name].boost
		end
	end

	-- local playerCache = self.players[player.UserId]
	-- if playerCache.friendCount > 0 then
	-- 	boost += BuffPresets.Buffs.friend.boost * playerCache.friendCount
	-- end

	return boost
end

function BuffSystem:GetLuckyBoost(player)
	local playerIns = PlayerServerClass.GetIns(player)
	local equippedBuff = playerIns:GetOneData(dataKey.equippedBuff)
	local boost = 1
	for name, status in equippedBuff do
		if BuffPresets.Buffs[name] and BuffPresets.Buffs[name].boostType == "lucky" then
			boost += BuffPresets.Buffs[name].boost
		end
	end

	-- Lucky GamePass bonus
	local gamePasses = playerIns:GetOneData(dataKey.gamePasses)
	if gamePasses.lucky then
		boost += 0.2
	end

	local playerCache = self.players[player.UserId]
	local playTime = os.time() - playerCache.joinTime
	boost += playTime / GameConfig.OneMinute * 0.01

	return boost
end

return BuffSystem
