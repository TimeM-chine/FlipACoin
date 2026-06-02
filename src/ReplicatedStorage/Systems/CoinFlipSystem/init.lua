---- services ----
local Players = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

---- requires ----
local Keys = require(Replicated.configs.Keys)
local EcoPresets = require(Replicated.Systems.EcoSystem.Presets)
local Onboarding = require(script.Modules.Onboarding)
local Presets = require(script.Presets)
local RebirthPresets = require(Replicated.Systems.RebirthSystem.Presets)
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
		"RequestFakeFlip",
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
			firstRebirthTailsStreak = 0,
			stateVersion = 0,
		}
		self.players[player.UserId] = playerState
	end

	return playerState
end

local function normalizeRunData(playerIns)
	local runData = playerIns:GetOneData(dataKey.runData)
	local rebirthTree = playerIns:GetOneData(dataKey.rebirthTree)
	local rebirthCount = playerIns:GetOneData(dataKey.rebirth)
	local rebirthSystem = GetSystemMgr().systems.RebirthSystem
	local needsUpdate = false

	if typeof(runData) ~= "table" then
		runData = rebirthSystem:BuildRunBaseline(SENDER, nil, {
			rebirthTree = rebirthTree,
			rebirthCount = rebirthCount,
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
			rebirthCount = rebirthCount,
		}) or needsUpdate
	end

	if needsUpdate then
		playerIns:SetOneData(dataKey.runData, runData)
	end

	return runData
end

local function normalizeFakeRunData(fakeActor)
	local runData = fakeActor.runData
	if typeof(runData) ~= "table" then
		runData = table.clone(Presets.RunDataDefaults)
		fakeActor.runData = runData
	else
		for key, defaultValue in pairs(Presets.RunDataDefaults) do
			if typeof(runData[key]) ~= typeof(defaultValue) then
				runData[key] = defaultValue
			end
		end
	end

	return runData
end

local function applyCashBuffBonuses(player, bonusStats)
	local buffSystem = GetSystemMgr().systems.BuffSystem
	local winsBoost = buffSystem:GetWinsBoost(player)
	if winsBoost <= 1 then
		return bonusStats
	end

	local boostedStats = table.clone(bonusStats)
	boostedStats.coinMultiplier = (boostedStats.coinMultiplier or 1) * winsBoost
	boostedStats.premiumCoinMultiplier = (boostedStats.premiumCoinMultiplier or 1) * winsBoost
	return boostedStats
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
	local bonusStats = applyCashBuffBonuses(player, ecoSystem:GetLoadoutBonuses(SENDER, player))
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

local function stampClientState(self, player, payload)
	local playerState = getPlayerState(self, player)
	playerState.stateVersion = (playerState.stateVersion or 0) + 1
	payload.stateVersion = playerState.stateVersion
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
	stampClientState(self, player, payload)

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

local function getFirstRebirthAssistBonus(playerIns, playerState)
	if playerIns:GetOneData(dataKey.rebirth) ~= 0 then
		playerState.firstRebirthTailsStreak = 0
		return 0
	end

	return Presets.GetFirstRebirthAssistBonus(
		playerIns:GetOneData(dataKey.wins),
		RebirthPresets.FlipACoin.Rebirth.MinCash,
		playerState.firstRebirthTailsStreak
	)
end

local function resolveActorFlip(self, actor)
	local runData = actor.isFake and normalizeFakeRunData(actor) or normalizeRunData(actor.playerIns)
	local bonusStats = actor.bonusStats
	local playerState = if actor.isFake then nil else getPlayerState(self, actor.player)
	local hiddenChanceBonus = playerState and getFirstRebirthAssistBonus(actor.playerIns, playerState) or 0
	local outcome = Presets.BuildRoundOutcome(runData, bonusStats, hiddenChanceBonus)
	local reward = 0
	local isBestStreak = false
	local bestStreak

	runData.flipsThisRun += 1
	if outcome.roundSuccess then
		if playerState then
			playerState.firstRebirthTailsStreak = 0
		end
		runData.currentStreak += 1
		runData.bestStreakThisRun = math.max(runData.bestStreakThisRun, runData.currentStreak)
		if actor.isFake then
			local previousBestStreak = if actor.fakeActor
				then actor.fakeActor.bestStreak or 0
				else actor.bestStreak or 0
			isBestStreak = runData.currentStreak > previousBestStreak
			bestStreak = math.max(previousBestStreak, runData.currentStreak)
			if actor.fakeActor then
				actor.fakeActor.bestStreak = bestStreak
			end
		else
			local previousBestStreak = actor.playerIns:GetOneData(dataKey.bestStreak)
			isBestStreak = runData.currentStreak > previousBestStreak
			bestStreak = math.max(previousBestStreak, runData.currentStreak)
		end
	else
		if playerState then
			if hiddenChanceBonus > 0 then
				playerState.firstRebirthTailsStreak += 1
			else
				playerState.firstRebirthTailsStreak = 0
			end
		end
		runData.currentStreak = 0
	end
	runData.headsThisRun += outcome.headsCount
	outcome.roundStreak = runData.currentStreak
	reward = Presets.GetRoundReward(runData, bonusStats, outcome)
	outcome.reward = reward
	if reward > 0 then
		runData.cashEarnedThisRun += reward
	end

	if not actor.isFake then
		local playerIns = actor.playerIns
		playerIns:SetOneData(dataKey.lifetimeFlips, playerIns:GetOneData(dataKey.lifetimeFlips) + 1)
		if reward > 0 then
			SystemMgr.systems.EcoSystem:AddResource(SENDER, actor.player, {
				resourceType = dataKey.wins,
				count = reward,
				reason = "flip",
			})
			playerIns:SetOneData(dataKey.lifetimeCashEarned, playerIns:GetOneData(dataKey.lifetimeCashEarned) + reward)
		end
		if outcome.headsCount > 0 then
			playerIns:SetOneData(dataKey.lifetimeHeads, playerIns:GetOneData(dataKey.lifetimeHeads) + outcome.headsCount)
		end
		if outcome.roundSuccess then
			playerIns:SetOneData(dataKey.bestStreak, bestStreak)
		end
		playerIns:SetOneData(dataKey.runData, runData)
	end

	local observedPayload = {
		userId = actor.userId,
		seatId = actor.seatId,
		result = outcome.roundSuccess and "Heads" or "Tails",
		reward = reward,
		streak = runData.currentStreak,
		coinCount = outcome.coinCount,
		coinResults = outcome.coinResults,
		headsCount = outcome.headsCount,
		tailsCount = outcome.tailsCount,
		roundSuccess = outcome.roundSuccess,
		successThreshold = outcome.successThreshold,
		roundStreak = outcome.roundStreak,
		perfect = outcome.perfect,
		comboName = outcome.comboName,
		comboMultiplier = outcome.comboMultiplier,
		isBestStreak = isBestStreak,
		bestStreak = bestStreak,
		bestStreakThisRun = runData.bestStreakThisRun,
		equippedCoin = actor.equippedCoin,
		isFake = actor.isFake == true,
		fakeId = actor.fakeId,
	}
	local streakMilestone = SystemMgr.systems.AnnouncementSystem:BuildBestStreakPayload(
		SENDER,
		actor.announcementActor,
		observedPayload
	) or SystemMgr.systems.AnnouncementSystem:BuildStreakMilestonePayload(
		SENDER,
		actor.announcementActor,
		observedPayload
	)
	if streakMilestone then
		observedPayload.streakMilestone = streakMilestone
	end

	emitObservedFlip(self, actor.player, observedPayload)
	SystemMgr.systems.AnnouncementSystem:HandleFlipResolved(SENDER, actor.announcementActor, observedPayload)

	return {
		runData = runData,
		reward = reward,
		streakMilestone = streakMilestone,
		observedPayload = observedPayload,
	}
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
		local state = buildClientState(player)
		if state then
			stampClientState(self, player, state)
		end
		self.Client:PlayerAdded(player, {
			state = state,
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

function CoinFlipSystem:RequestFlip(sender, player, args)
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
	local bonusStats = applyCashBuffBonuses(player, SystemMgr.systems.EcoSystem:GetLoadoutBonuses(SENDER, player))
	local equippedCoin = playerIns:GetOneData(dataKey.equippedCoin)
	local resolvedFlip = resolveActorFlip(self, {
		player = player,
		playerIns = playerIns,
		announcementActor = player,
		userId = player.UserId,
		seatId = seatId,
		equippedCoin = equippedCoin,
		bonusStats = bonusStats,
		isFake = false,
	})
	local runData = resolvedFlip.runData
	local observedPayload = resolvedFlip.observedPayload
	playerState.nextFlipAt = observedPayload and (now + Presets.GetFlipInterval(runData, bonusStats)) or playerState.nextFlipAt
	applyOnboardingAction(self, player, "flip", {
		flipCount = runData.flipsThisRun,
	})

	seatSystem:RegisterActivity(SENDER, player)
	refreshCashDisplays(player)
	seatSystem:RefreshAudienceState(SENDER)

	SystemMgr.systems.AnalyticsSystem:LogCoinFlipResolved(SENDER, player, observedPayload)
	if typeof(args) == "table" and args.inputSource then
		SystemMgr.systems.AnalyticsSystem:LogInputAction(SENDER, player, {
			action = "FlipCoin",
			source = args.inputSource,
			inputType = args.inputType,
		})
	end

	syncPlayerState(self, player, {
		result = observedPayload.result,
		reward = resolvedFlip.reward,
		streak = runData.currentStreak,
		coinCount = observedPayload.coinCount,
		coinResults = observedPayload.coinResults,
		headsCount = observedPayload.headsCount,
		tailsCount = observedPayload.tailsCount,
		roundSuccess = observedPayload.roundSuccess,
		successThreshold = observedPayload.successThreshold,
		roundStreak = observedPayload.roundStreak,
		perfect = observedPayload.perfect,
		comboName = observedPayload.comboName,
		comboMultiplier = observedPayload.comboMultiplier,
		isBestStreak = observedPayload.isBestStreak,
		bestStreak = observedPayload.bestStreak,
		equippedCoin = equippedCoin,
		streakMilestone = resolvedFlip.streakMilestone,
	}, true)
end

function CoinFlipSystem:ReportInputAction(sender, player, args)
	if not IsServer then
		return
	end

	player = player or sender
	if sender ~= player or not player:IsDescendantOf(Players) or typeof(args) ~= "table" then
		return
	end
	if args.action ~= "ToggleAutoFlip" then
		return
	end

	SystemMgr.systems.AnalyticsSystem:LogInputAction(SENDER, player, {
		action = args.action,
		source = typeof(args.source) == "string" and args.source or "unknown",
		inputType = typeof(args.inputType) == "string" and args.inputType or "unknown",
	})
end

function CoinFlipSystem:RequestFakeFlip(sender, fakeActor)
	if not IsServer then
		return nil
	end
	if sender ~= SENDER then
		return nil
	end
	if typeof(fakeActor) ~= "table" or fakeActor.isFake ~= true or not fakeActor.isActive then
		return nil
	end
	if typeof(fakeActor.seatId) ~= "string" then
		return nil
	end

	local now = os.clock()
	if typeof(fakeActor.nextFlipAt) == "number" and fakeActor.nextFlipAt > now then
		return nil
	end

	local bonusStats = EcoPresets.BuildLoadoutBonuses(
		fakeActor.equippedCoin,
		fakeActor.equippedDeskSetup,
		fakeActor.equippedChair,
		nil
	)
	local resolvedFlip = resolveActorFlip(self, {
		announcementActor = fakeActor,
		userId = fakeActor.userId,
		seatId = fakeActor.seatId,
		equippedCoin = fakeActor.equippedCoin,
		equippedDeskSetup = fakeActor.equippedDeskSetup,
		equippedChair = fakeActor.equippedChair,
		bestStreak = fakeActor.bestStreak,
		fakeActor = fakeActor,
		bonusStats = bonusStats,
		isFake = true,
		fakeId = fakeActor.fakeId,
		runData = fakeActor.runData,
		cash = fakeActor.cash,
	})

	fakeActor.runData = resolvedFlip.runData
	fakeActor.cash = (fakeActor.cash or 0) + resolvedFlip.reward
	fakeActor.nextFlipAt = now + Presets.GetFlipInterval(resolvedFlip.runData, bonusStats)
	SystemMgr.systems.TableSeatSystem:RefreshAudienceState(SENDER)

	return resolvedFlip
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
	SystemMgr.systems.AnalyticsSystem:LogRunUpgradePurchased(SENDER, player, {
		upgradeKey = upgradeKey,
		newLevel = runData[upgradeKey],
		cost = cost,
		cashAfterPurchase = playerIns:GetOneData(dataKey.wins),
	})
	applyOnboardingAction(self, player, "buyUpgrade", {
		upgradeKey = upgradeKey,
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

function CoinFlipSystem:HandleGuideRebirth(sender, player)
	if not IsServer then
		return
	end
	if sender ~= SENDER then
		return
	end

	applyOnboardingAction(self, player, "rebirth", nil, true)
end

function CoinFlipSystem:HandleGuideCoinPurchased(sender, player, args)
	if not IsServer then
		return
	end
	if sender ~= SENDER then
		return
	end
	if typeof(args) ~= "table" then
		return
	end

	applyOnboardingAction(self, player, "coinPurchase", {
		itemId = args.itemId,
	}, true)
end

function CoinFlipSystem:HandleGuideCoinEquipped(sender, player, args)
	if not IsServer then
		return
	end
	if sender ~= SENDER then
		return
	end
	if typeof(args) ~= "table" then
		return
	end

	applyOnboardingAction(self, player, "coinEquip", {
		itemId = args.itemId,
	}, true)
end

function CoinFlipSystem:UpdateOnboarding(sender, player, args)
	if IsServer then
		return
	end

	CoinFlipUi.UpdateOnboarding(args and args.onboarding)
end

return CoinFlipSystem
