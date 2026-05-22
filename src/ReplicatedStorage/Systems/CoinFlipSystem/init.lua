---- services ----
local Players = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

---- requires ----
local Keys = require(Replicated.configs.Keys)
local Onboarding = require(script.Modules.Onboarding)
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
	whiteList = {
		"HandleGuideSit",
		"SyncPlayerState",
	},
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
	local rebirthTree = playerIns:GetOneData(dataKey.rebirthTree)
	local rebirthSystem = GetSystemMgr().systems.RebirthSystem
	local needsUpdate = false

	if typeof(runData) ~= "table" then
		runData = rebirthSystem:BuildRunBaseline(SENDER, nil, {
			rebirthTree = rebirthTree,
		})
		needsUpdate = true
	else
		for key, defaultValue in pairs(Presets.RunDataDefaults) do
			if typeof(runData[key]) ~= typeof(defaultValue) then
				runData[key] = defaultValue
				needsUpdate = true
			end
		end
		needsUpdate = rebirthSystem:ApplyRunBaseline(SENDER, nil, {
			runData = runData,
			rebirthTree = rebirthTree,
		}) or needsUpdate
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
	local ecoSystem = SystemMgr.systems.EcoSystem
	local rebirthSystem = SystemMgr.systems.RebirthSystem
	local loadoutState = ecoSystem:GetLoadoutState(SENDER, player)
	local rebirthState = rebirthSystem:GetRebirthState(SENDER, player)
	local bonusStats = ecoSystem:GetLoadoutBonuses(SENDER, player)
	local derivedStats = Presets.BuildDerivedStats(runData, bonusStats)

	return {
		cash = wins,
		wins = wins,
		runData = table.clone(runData),
		derivedStats = derivedStats,
		nextCosts = Presets.GetNextCosts(runData),
		seatState = getSeatState(player),
		onboarding = Onboarding.BuildState(playerIns),
		loadoutState = loadoutState,
		rebirthState = rebirthState,
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

	SystemMgr.systems.EcoSystem.Client:SyncLoadoutState(player, {
		cash = payload.cash,
		loadoutState = payload.loadoutState,
		derivedStats = payload.derivedStats,
		runData = payload.runData,
		purchasedItem = payload.purchasedItem,
		equippedItem = payload.equippedItem,
		equippedCategory = payload.equippedCategory,
	})
	SystemMgr.systems.RebirthSystem.Client:SyncRebirthState(player, {
		cash = payload.cash,
		rebirthState = payload.rebirthState,
		derivedStats = payload.derivedStats,
		runData = payload.runData,
		rebirthed = payload.rebirthed,
		rebirthPointGain = payload.rebirthPointGain,
		rebirthUpgradePurchased = payload.rebirthUpgradePurchased,
	})
end

local function refreshCashDisplays(player)
	SystemMgr.systems.PlayerSystem:UpdateLeaderStats(player)
	SystemMgr.systems.PlayerSystem:UpdatePlayerHeadGui(player)
end

local function pushOnboardingState(self, player)
	local playerIns = GetPlayerIns(player, false)
	if not playerIns then
		return
	end

	self.Client:UpdateOnboarding(player, {
		onboarding = Onboarding.BuildState(playerIns),
	})
end

local function applyOnboardingAction(self, player, action, context, shouldPushImmediately)
	local playerIns = GetPlayerIns(player, false)
	if not playerIns then
		return false
	end

	local changed, milestones = Onboarding.ApplyAction(playerIns, action, context)
	if not changed then
		return false
	end

	for _, milestone in ipairs(milestones) do
		playerIns:LogOnboarding(milestone.analyticsStep, milestone.analyticsName)
	end

	local latestMilestone = milestones[#milestones]
	if latestMilestone and latestMilestone.toastText then
		SystemMgr.systems.GuiSystem:SetNotification(SENDER, player, {
			text = latestMilestone.toastText,
			lastTime = 2.8,
			textColor = Color3.fromRGB(255, 231, 163),
		})
	end

	SystemMgr.systems.PlayerSystem:UpdatePlayerHeadGui(player)

	if shouldPushImmediately then
		pushOnboardingState(self, player)
	end

	return true
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
		for _, delaySeconds in ipairs({ 0.5, 1.5, 3 }) do
			task.delay(delaySeconds, function()
				if player:IsDescendantOf(Players) then
					syncPlayerState(self, player)
				end
			end)
		end
	else
		local pendingCalls = CoinFlipUi.pendingCalls

		CoinFlipUi = require(script.ui)
		CoinFlipUi.Init()

		for _, call in ipairs(pendingCalls) do
			CoinFlipUi[call.functionName](table.unpack(call.args))
		end

		if args and args.state then
			CoinFlipUi.SyncRunState(args.state)
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

function CoinFlipSystem:SyncPlayerState(sender, player, extraArgs, useFlipResolved)
	if IsServer then
		if sender ~= SENDER then
			return
		end

		syncPlayerState(self, player, extraArgs, useFlipResolved)
	else
		--
	end
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
	local bonusStats = SystemMgr.systems.EcoSystem:GetLoadoutBonuses(SENDER, player)
	local isHeads = math.random() < Presets.GetHeadsChance(runData, bonusStats)
	local reward = 0
	playerIns:SetOneData(dataKey.lifetimeFlips, playerIns:GetOneData(dataKey.lifetimeFlips) + 1)
	runData.flipsThisRun += 1

	if isHeads then
		runData.currentStreak += 1
		runData.headsThisRun += 1
		reward = Presets.GetHeadsReward(runData, bonusStats)
		runData.cashEarnedThisRun += reward
		runData.bestStreakThisRun = math.max(runData.bestStreakThisRun, runData.currentStreak)

		SystemMgr.systems.EcoSystem:AddResource(SENDER, player, {
			resourceType = dataKey.wins,
			count = reward,
			reason = "flip",
		})
		playerIns:SetOneData(dataKey.lifetimeHeads, playerIns:GetOneData(dataKey.lifetimeHeads) + 1)
		playerIns:SetOneData(dataKey.lifetimeCashEarned, playerIns:GetOneData(dataKey.lifetimeCashEarned) + reward)
		playerIns:SetOneData(
			dataKey.bestStreak,
			math.max(playerIns:GetOneData(dataKey.bestStreak), runData.bestStreakThisRun)
		)
	else
		reward = Presets.GetTailsReward(bonusStats)
		if reward > 0 then
			runData.cashEarnedThisRun += reward
			SystemMgr.systems.EcoSystem:AddResource(SENDER, player, {
				resourceType = dataKey.wins,
				count = reward,
				reason = "flip",
			})
			playerIns:SetOneData(dataKey.lifetimeCashEarned, playerIns:GetOneData(dataKey.lifetimeCashEarned) + reward)
		end
		runData.currentStreak = 0
	end

	playerState.nextFlipAt = now + Presets.GetFlipInterval(runData, bonusStats)
	playerIns:SetOneData(dataKey.runData, runData)
	applyOnboardingAction(self, player, "flip", {
		flipCount = runData.flipsThisRun,
	})
	applyOnboardingAction(self, player, "streak", {
		streak = runData.currentStreak,
	})

	seatSystem:RegisterActivity(SENDER, player)
	refreshCashDisplays(player)
	seatSystem:RefreshAudienceState(SENDER)

	local equippedCoin = playerIns:GetOneData(dataKey.equippedCoin)
	local observedPayload = {
		userId = player.UserId,
		seatId = seatId,
		result = isHeads and "Heads" or "Tails",
		reward = reward,
		streak = runData.currentStreak,
		bestStreakThisRun = runData.bestStreakThisRun,
		equippedCoin = equippedCoin,
	}
	local streakMilestone =
		SystemMgr.systems.AnnouncementSystem:BuildStreakMilestonePayload(SENDER, player, observedPayload)
	if streakMilestone then
		observedPayload.streakMilestone = streakMilestone
	end

	emitObservedFlip(self, player, observedPayload)
	SystemMgr.systems.AnnouncementSystem:HandleFlipResolved(SENDER, player, observedPayload)
	SystemMgr.systems.AnalyticsSystem:LogCoinFlipResolved(SENDER, player, observedPayload)

	syncPlayerState(self, player, {
		result = observedPayload.result,
		reward = reward,
		streak = runData.currentStreak,
		equippedCoin = equippedCoin,
		streakMilestone = streakMilestone,
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

	SystemMgr.systems.EcoSystem:AddResource(SENDER, player, {
		resourceType = dataKey.wins,
		count = -cost,
		reason = "runUpgrade",
	})
	runData[upgradeKey] += 1
	playerIns:SetOneData(dataKey.runData, runData)
	applyOnboardingAction(self, player, "buyUpgrade")
	SystemMgr.systems.AnalyticsSystem:LogRunUpgradePurchased(SENDER, player, {
		upgradeKey = upgradeKey,
		newLevel = runData[upgradeKey],
		cost = cost,
		cashAfterPurchase = playerIns:GetOneData(dataKey.wins),
	})

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

function CoinFlipSystem:ReportGuideAction(sender, player, args)
	if not IsServer then
		return
	end

	player = player or sender
	if sender ~= player then
		return
	end
	if typeof(args) ~= "table" or typeof(args.action) ~= "string" then
		return
	end

	if args.action ~= "autoSeat" and args.action ~= "approachSeat" then
		return
	end

	applyOnboardingAction(self, player, args.action, args, true)
end

function CoinFlipSystem:HandleGuideSit(sender, player)
	if not IsServer then
		return
	end
	if sender ~= SENDER then
		return
	end

	applyOnboardingAction(self, player, "autoSeat", nil, true)
end

function CoinFlipSystem:UpdateOnboarding(sender, player, args)
	if IsServer then
		return
	end

	CoinFlipUi.UpdateOnboarding(args and args.onboarding)
end

return CoinFlipSystem
