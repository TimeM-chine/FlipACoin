---- services ----
local Replicated = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

---- requires ----
local Keys = require(Replicated.configs.Keys)
local Presets = require(script.Presets)
local Types = require(Replicated.configs.Types)

---- common variables ----
local IsServer = RunService:IsServer()
local SENDER, SystemMgr
local dataKey = Keys.DataKey

---- server variables ----
local PlayerServerClass

---- client variables ----
local CoinFlipUi = { pendingCalls = {} }
setmetatable(CoinFlipUi, Types.mt)

local CoinFlipSystem: Types.System = {
	whiteList = {},
	players = {},
	tasks = {},
	IsLoaded = false,
}
CoinFlipSystem.__index = CoinFlipSystem

if IsServer then
	CoinFlipSystem.Client = setmetatable({}, CoinFlipSystem)
	local ServerStorage = game:GetService("ServerStorage")
	PlayerServerClass = require(ServerStorage.classes.PlayerServerClass)
else
	CoinFlipSystem.Server = setmetatable({}, CoinFlipSystem)
end

local function GetSystemMgr()
	if not SystemMgr then
		SystemMgr = require(Replicated.Systems.SystemMgr)
		SENDER = SystemMgr.SENDER
	end
	return SystemMgr
end

local function GetPlayerIns(player, createIfNil)
	if not IsServer then
		return nil
	end
	return PlayerServerClass.GetIns(player, createIfNil)
end

local function getPlayerState(self, player)
	local playerState = self.players[player.UserId]
	if not playerState then
		playerState = {
			nextFlipAt = 0,
		}
		self.players[player.UserId] = playerState
	end

	return playerState
end

local function normalizeRunData(playerIns)
	local runData = playerIns:GetOneData(dataKey.runData)
	local needsUpdate = false

	if typeof(runData) ~= "table" then
		runData = table.clone(Presets.RunDataDefaults)
		needsUpdate = true
	else
		for key, defaultValue in pairs(Presets.RunDataDefaults) do
			if typeof(runData[key]) ~= typeof(defaultValue) then
				runData[key] = defaultValue
				needsUpdate = true
			end
		end
	end

	if needsUpdate then
		playerIns:SetOneData(dataKey.runData, runData)
	end

	return runData
end

local function getSeatState(player)
	local seatState = SystemMgr.systems.TableSeatSystem:GetClientSeatState(player) or {}
	seatState.seatId = seatState.mySeatId
	seatState.isSeated = seatState.mySeatId ~= nil

	return seatState
end

local function buildClientState(player)
	local playerIns = GetPlayerIns(player, false)
	if not playerIns then
		return nil
	end

	local runData = normalizeRunData(playerIns)
	local wins = playerIns:GetOneData(dataKey.wins)

	return {
		cash = wins,
		wins = wins,
		runData = table.clone(runData),
		derivedStats = Presets.BuildDerivedStats(runData),
		nextCosts = Presets.GetNextCosts(runData),
		seatState = getSeatState(player),
	}
end

local function syncPlayerState(self, player, extraArgs, useFlipResolved)
	local payload = buildClientState(player)
	if not payload then
		return
	end

	if extraArgs then
		for key, value in pairs(extraArgs) do
			payload[key] = value
		end
	end

	if useFlipResolved then
		self.Client:FlipResolved(player, payload)
	else
		self.Client:SyncRunState(player, payload)
	end
end

local function refreshCashDisplays(player)
	SystemMgr.systems.PlayerSystem:UpdateLeaderStats(player)
	SystemMgr.systems.PlayerSystem:UpdatePlayerHeadGui(player)
end

local function emitObservedFlip(self, player, args)
	local audiencePlayers = SystemMgr.systems.TableSeatSystem:GetAudiencePlayers(args.seatId)

	for _, audiencePlayer in ipairs(audiencePlayers) do
		if audiencePlayer ~= player then
			self.Client:ObservedFlip(audiencePlayer, args)
		end
	end
end

function CoinFlipSystem:Init()
	GetSystemMgr()
end

function CoinFlipSystem:PlayerAdded(sender, player, args)
	if IsServer then
		if sender ~= SENDER then
			return
		end

		getPlayerState(self, player)
		self.Client:PlayerAdded(player, {
			state = buildClientState(player),
		})
	else
		local pendingCalls = CoinFlipUi.pendingCalls

		CoinFlipUi = require(script.ui)
		CoinFlipUi.Init()

		for _, call in ipairs(pendingCalls) do
			CoinFlipUi[call.functionName](table.unpack(call.args))
		end

		if args and args.state then
			CoinFlipUi.SyncRunState(args.state)
			CoinFlipUi.SeatStateChanged({
				seatState = args.state.seatState,
			})
		end
	end
end

function CoinFlipSystem:PlayerRemoving(sender, player)
	if not IsServer then
		return
	end
	if sender ~= SENDER then
		return
	end

	self.players[player.UserId] = nil
end

function CoinFlipSystem:RequestFlip(sender, player)
	if not IsServer then
		return
	end

	player = player or sender
	if sender ~= SENDER and sender ~= player then
		return
	end
	local seatSystem = SystemMgr.systems.TableSeatSystem
	if not seatSystem:IsPlayerSeated(player) then
		return
	end

	local playerState = getPlayerState(self, player)
	local now = os.clock()
	if playerState.nextFlipAt > now then
		return
	end

	local playerIns = GetPlayerIns(player, false)
	if not playerIns then
		return
	end

	local seatId = seatSystem:GetPlayerSeatId(player)
	local runData = normalizeRunData(playerIns)
	local isHeads = math.random() < Presets.GetHeadsChance(runData)
	local reward = 0
	playerIns:SetOneData(dataKey.lifetimeFlips, playerIns:GetOneData(dataKey.lifetimeFlips) + 1)
	runData.flipsThisRun += 1

	if isHeads then
		runData.currentStreak += 1
		runData.headsThisRun += 1
		reward = Presets.GetHeadsReward(runData)
		runData.cashEarnedThisRun += reward
		runData.bestStreakThisRun = math.max(runData.bestStreakThisRun, runData.currentStreak)

		playerIns:SetOneData(dataKey.wins, playerIns:GetOneData(dataKey.wins) + reward)
		playerIns:SetOneData(dataKey.lifetimeHeads, playerIns:GetOneData(dataKey.lifetimeHeads) + 1)
		playerIns:SetOneData(dataKey.lifetimeCashEarned, playerIns:GetOneData(dataKey.lifetimeCashEarned) + reward)
		playerIns:SetOneData(
			dataKey.bestStreak,
			math.max(playerIns:GetOneData(dataKey.bestStreak), runData.bestStreakThisRun)
		)
	else
		runData.currentStreak = 0
	end

	playerState.nextFlipAt = now + Presets.GetFlipInterval(runData)
	playerIns:SetOneData(dataKey.runData, runData)

	seatSystem:RegisterActivity(SENDER, player)
	refreshCashDisplays(player)
	seatSystem:RefreshAudienceState(SENDER)

	local observedPayload = {
		userId = player.UserId,
		seatId = seatId,
		result = isHeads and "Heads" or "Tails",
		reward = reward,
		streak = runData.currentStreak,
		bestStreakThisRun = runData.bestStreakThisRun,
	}

	emitObservedFlip(self, player, observedPayload)
	SystemMgr.systems.AnnouncementSystem:HandleFlipResolved(SENDER, player, observedPayload)

	syncPlayerState(self, player, {
		result = observedPayload.result,
		reward = reward,
		streak = runData.currentStreak,
	}, true)
end

function CoinFlipSystem:BuyUpgrade(sender, player, args)
	if not IsServer then
		return
	end

	player = player or sender
	if sender ~= SENDER and sender ~= player then
		return
	end

	local seatSystem = SystemMgr.systems.TableSeatSystem
	if not seatSystem:IsPlayerSeated(player) then
		return
	end

	local upgradeKey = Presets.ResolveUpgradeKey(args and args.upgradeType)
	if not upgradeKey then
		return
	end

	local playerIns = GetPlayerIns(player, false)
	if not playerIns then
		return
	end

	local runData = normalizeRunData(playerIns)
	local currentLevel = runData[upgradeKey]
	if Presets.IsUpgradeMaxed(upgradeKey, currentLevel) then
		return
	end

	local cost = Presets.GetUpgradeCost(upgradeKey, currentLevel)
	local wins = playerIns:GetOneData(dataKey.wins)
	if wins < cost then
		return
	end

	playerIns:SetOneData(dataKey.wins, wins - cost)
	runData[upgradeKey] += 1
	playerIns:SetOneData(dataKey.runData, runData)

	seatSystem:RegisterActivity(SENDER, player)
	refreshCashDisplays(player)
	seatSystem:RefreshAudienceState(SENDER)
	syncPlayerState(self, player, {
		upgradePurchased = upgradeKey,
	})
end

function CoinFlipSystem:SyncRunState(sender, player, args)
	if IsServer then
		return
	end

	CoinFlipUi.SyncRunState(args)
end

function CoinFlipSystem:FlipResolved(sender, player, args)
	if IsServer then
		return
	end

	CoinFlipUi.FlipResolved(args)
end

function CoinFlipSystem:SeatStateChanged(sender, player, args)
	if IsServer then
		return
	end

	CoinFlipUi.SeatStateChanged(args)
end

function CoinFlipSystem:ObservedFlip(sender, player, args)
	if IsServer then
		return
	end

	CoinFlipUi.ObservedFlip(args)
end

return CoinFlipSystem
