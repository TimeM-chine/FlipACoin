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
	whiteList = {
		"GetRebirthState",
		"ApplyRunBaseline",
		"BuildRunBaseline",
	},
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
	RebirthUi = { pendingCalls = {} }
	setmetatable(RebirthUi, Types.mt)
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

		self.Client:PlayerAdded(player, {
			rebirthState = self:GetRebirthState(SENDER, player),
		})
	else
		local pendingCalls = RebirthUi.pendingCalls

		RebirthUi = require(script.ui)
		RebirthUi.Init()

		for _, call in ipairs(pendingCalls) do
			RebirthUi[call.functionName](table.unpack(call.args))
		end

		RebirthUi.SyncRebirthState(args)
	end
end

local function normalizeRebirthTree(playerIns)
	local rebirthTree = playerIns:GetOneData(dataKey.rebirthTree)
	local changed = false

	if typeof(rebirthTree) ~= "table" then
		rebirthTree = {
			polishedStart = 0,
			chainStart = 0,
			quickStart = 0,
			luckyStart = 0,
		}
		changed = true
	end

	for _, upgradeKey in ipairs(RebirthPresets.FlipACoin.UpgradeOrder) do
		if typeof(rebirthTree[upgradeKey]) ~= "number" then
			rebirthTree[upgradeKey] = 0
			changed = true
		end
	end

	if changed then
		playerIns:SetOneData(dataKey.rebirthTree, rebirthTree)
	end

	return rebirthTree
end

local function buildRebirthUpgrades(rebirthTree)
	local upgrades = {}

	for _, upgradeKey in ipairs(RebirthPresets.FlipACoin.UpgradeOrder) do
		local config = RebirthPresets.GetFlipACoinUpgradeConfig(upgradeKey)
		local level = rebirthTree[upgradeKey] or 0
		local cost = RebirthPresets.GetFlipACoinUpgradeCost(upgradeKey, level)
		if RebirthPresets.IsFlipACoinUpgradeMaxed(upgradeKey, level) then
			cost = nil
		end
		table.insert(upgrades, {
			key = upgradeKey,
			displayName = config.displayName,
			description = config.description,
			level = level,
			maxLevel = config.maxLevel,
			cost = cost,
		})
	end

	return upgrades
end

function RebirthSystem:TryRebirth(sender, player, args)
	if IsServer then
		self:RequestRebirth(sender, player, args)
	else
		--
	end
end

function RebirthSystem:Rebirth(sender, player, args)
	if IsServer then
		if sender ~= SENDER then
			return
		end

		self:RequestRebirth(SENDER, player, args)
	else
		RebirthUi.SyncRebirthState(args)
	end
end

function RebirthSystem:GetRebirthState(sender, player, args)
	if IsServer then
		if sender ~= SENDER then
			return nil
		end

		local playerIns = PlayerServerClass.GetIns(player)
		if not playerIns then
			return nil
		end

		local rebirthTree = normalizeRebirthTree(playerIns)
		local cash = playerIns:GetOneData(dataKey.wins)
		local rebirthPoints = playerIns:GetOneData(dataKey.fateShards)
		local pointGain = RebirthPresets.GetFlipACoinPointGain(cash)

		return {
			cash = cash,
			rebirth = playerIns:GetOneData(dataKey.rebirth),
			rebirthPoints = rebirthPoints,
			fateShards = rebirthPoints,
			pointGain = pointGain,
			canRebirth = pointGain > 0,
			rebirthMinCash = RebirthPresets.FlipACoin.Rebirth.MinCash,
			rebirthCashPerPoint = RebirthPresets.FlipACoin.Rebirth.CashPerPoint,
			rebirthCashAfterReset = RebirthPresets.FlipACoin.Rebirth.CashAfterReset,
			rebirthTree = table.clone(rebirthTree),
			rebirthUpgrades = buildRebirthUpgrades(rebirthTree),
			runDataAfterReset = RebirthPresets.BuildFlipACoinRunBaseline(rebirthTree),
		}
	else
		return ClientData:GetOneData("rebirthState")
	end
end

function RebirthSystem:BuildRunBaseline(sender, player, args)
	if IsServer then
		if sender ~= SENDER then
			return table.clone(RebirthPresets.RunDataDefaults)
		end

		local rebirthTree = args and args.rebirthTree
		if not rebirthTree and player then
			local playerIns = PlayerServerClass.GetIns(player)
			if playerIns then
				rebirthTree = normalizeRebirthTree(playerIns)
			end
		end

		return RebirthPresets.BuildFlipACoinRunBaseline(rebirthTree)
	else
		return RebirthPresets.BuildFlipACoinRunBaseline(args and args.rebirthTree)
	end
end

function RebirthSystem:ApplyRunBaseline(sender, player, args)
	if IsServer then
		if sender ~= SENDER then
			return false
		end

		local runData = args and args.runData
		local rebirthTree = args and args.rebirthTree
		if not rebirthTree and player then
			local playerIns = PlayerServerClass.GetIns(player)
			if playerIns then
				rebirthTree = normalizeRebirthTree(playerIns)
			end
		end

		return RebirthPresets.ApplyFlipACoinRunBaseline(runData, rebirthTree)
	else
		return false
	end
end

function RebirthSystem:RequestRebirth(sender, player)
	if IsServer then
		player = player or sender
		if sender ~= SENDER and sender ~= player then
			return
		end

		local playerIns = PlayerServerClass.GetIns(player)
		if not playerIns then
			return
		end

		local wins = playerIns:GetOneData(dataKey.wins)
		local pointGain = RebirthPresets.GetFlipACoinPointGain(wins)
		if pointGain <= 0 then
			SystemMgr.systems.GuiSystem:SetNotification(SENDER, player, {
				text = "Build more Cash before rebirth",
				lastTime = 2,
				soundName = "notification",
			})
			SystemMgr.systems.CoinFlipSystem:SyncPlayerState(SENDER, player)
			return
		end

		local rebirthTree = normalizeRebirthTree(playerIns)
		local resetRunData = RebirthPresets.BuildFlipACoinRunBaseline(rebirthTree)
		playerIns:SetOneData(dataKey.wins, RebirthPresets.FlipACoin.Rebirth.CashAfterReset)
		playerIns:SetOneData(dataKey.fateShards, playerIns:GetOneData(dataKey.fateShards) + pointGain)
		playerIns:SetOneData(dataKey.rebirth, playerIns:GetOneData(dataKey.rebirth) + 1)
		playerIns:SetOneData(dataKey.runData, resetRunData)

		AnalyticsService:LogCustomEvent(player, "rebirth")
		SystemMgr.systems.TableSeatSystem:RegisterActivity(SENDER, player)
		SystemMgr.systems.PlayerSystem:UpdateLeaderStats(player)
		SystemMgr.systems.PlayerSystem:UpdatePlayerHeadGui(player)
		SystemMgr.systems.TableSeatSystem:RefreshAudienceState(SENDER)
		SystemMgr.systems.CoinFlipSystem:SyncPlayerState(SENDER, player, {
			rebirthed = true,
			rebirthPointGain = pointGain,
		})
	else
		--
	end
end

function RebirthSystem:RequestRebirthUpgrade(sender, player, args)
	if IsServer then
		player = player or sender
		if sender ~= SENDER and sender ~= player then
			return
		end
		if typeof(args) ~= "table" or typeof(args.upgradeKey) ~= "string" then
			return
		end

		local config = RebirthPresets.GetFlipACoinUpgradeConfig(args.upgradeKey)
		if not config then
			return
		end

		local playerIns = PlayerServerClass.GetIns(player)
		if not playerIns then
			return
		end

		local rebirthTree = normalizeRebirthTree(playerIns)
		local currentLevel = rebirthTree[args.upgradeKey] or 0
		if RebirthPresets.IsFlipACoinUpgradeMaxed(args.upgradeKey, currentLevel) then
			return
		end

		local cost = RebirthPresets.GetFlipACoinUpgradeCost(args.upgradeKey, currentLevel)
		local rebirthPoints = playerIns:GetOneData(dataKey.fateShards)
		if rebirthPoints < cost then
			SystemMgr.systems.GuiSystem:SetNotification(SENDER, player, {
				text = "Not enough Rebirth Points",
				lastTime = 2,
				soundName = "notification",
			})
			SystemMgr.systems.CoinFlipSystem:SyncPlayerState(SENDER, player)
			return
		end

		rebirthTree[args.upgradeKey] = currentLevel + 1
		playerIns:SetOneData(dataKey.fateShards, rebirthPoints - cost)
		playerIns:SetOneData(dataKey.rebirthTree, rebirthTree)

		local runData = playerIns:GetOneData(dataKey.runData)
		if RebirthPresets.ApplyFlipACoinRunBaseline(runData, rebirthTree) then
			playerIns:SetOneData(dataKey.runData, runData)
		end

		SystemMgr.systems.PlayerSystem:UpdateLeaderStats(player)
		SystemMgr.systems.PlayerSystem:UpdatePlayerHeadGui(player)
		SystemMgr.systems.TableSeatSystem:RefreshAudienceState(SENDER)
		SystemMgr.systems.CoinFlipSystem:SyncPlayerState(SENDER, player, {
			rebirthUpgradePurchased = args.upgradeKey,
		})
	else
		--
	end
end

function RebirthSystem:SyncRebirthState(sender, player, args)
	if IsServer then
		return
	end

	local rebirthState = args and args.rebirthState
	if rebirthState then
		ClientData:SetOneData("rebirthState", rebirthState)
		ClientData:SetOneData(dataKey.rebirth, rebirthState.rebirth)
		ClientData:SetOneData(dataKey.fateShards, rebirthState.fateShards)
		ClientData:SetOneData(dataKey.rebirthTree, rebirthState.rebirthTree)
	end

	RebirthUi.SyncRebirthState(args)
end

---- [[ Server ]] ----
function RebirthSystem:GetRebirthBoost(player)
	local playerIns = PlayerServerClass.GetIns(player)
	local rebirth = playerIns:GetOneData(dataKey.rebirth)
	return RebirthPresets.RebirthConfig[rebirth].boost + 1
end

return RebirthSystem
