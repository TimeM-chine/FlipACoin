---- services ----
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
	local needsUpdate = false

	if typeof(runData) ~= "table" then
		runData = Presets.BuildRunBaseline(rebirthTree)
		needsUpdate = true
	else
		for key, defaultValue in pairs(Presets.RunDataDefaults) do
			if typeof(runData[key]) ~= typeof(defaultValue) then
				runData[key] = defaultValue
				needsUpdate = true
			end
		end
		needsUpdate = Presets.ApplyRunBaseline(runData, rebirthTree) or needsUpdate
	end

	if needsUpdate then
		playerIns:SetOneData(dataKey.runData, runData)
	end

	return runData
end

local function normalizeGrowthData(playerIns)
	local ownedCoins = playerIns:GetOneData(dataKey.ownedCoins)
	local equippedCoin = playerIns:GetOneData(dataKey.equippedCoin)
	local ownedDeskSetups = playerIns:GetOneData(dataKey.ownedDeskSetups)
	local equippedDeskSetup = playerIns:GetOneData(dataKey.equippedDeskSetup)
	local rebirthTree = playerIns:GetOneData(dataKey.rebirthTree)
	local needsRunUpdate = false

	if typeof(ownedCoins) ~= "table" then
		ownedCoins = {
			["Rusty Penny"] = true,
		}
		playerIns:SetOneData(dataKey.ownedCoins, ownedCoins)
	end
	if not Presets.GetShopItem("coin", equippedCoin) or not ownedCoins[equippedCoin] then
		equippedCoin = "Rusty Penny"
		ownedCoins[equippedCoin] = true
		playerIns:SetOneData(dataKey.equippedCoin, equippedCoin)
		playerIns:SetOneData(dataKey.ownedCoins, ownedCoins)
	end

	if typeof(ownedDeskSetups) ~= "table" then
		ownedDeskSetups = {
			["Folding Table"] = true,
		}
		playerIns:SetOneData(dataKey.ownedDeskSetups, ownedDeskSetups)
	end
	if not Presets.GetShopItem("desk", equippedDeskSetup) or not ownedDeskSetups[equippedDeskSetup] then
		equippedDeskSetup = "Folding Table"
		ownedDeskSetups[equippedDeskSetup] = true
		playerIns:SetOneData(dataKey.equippedDeskSetup, equippedDeskSetup)
		playerIns:SetOneData(dataKey.ownedDeskSetups, ownedDeskSetups)
	end

	if typeof(rebirthTree) ~= "table" then
		rebirthTree = {
			polishedStart = 0,
			chainStart = 0,
			quickStart = 0,
			luckyStart = 0,
		}
		playerIns:SetOneData(dataKey.rebirthTree, rebirthTree)
	end
	for _, upgradeKey in ipairs(Presets.Growth.RebirthUpgradeOrder) do
		if typeof(rebirthTree[upgradeKey]) ~= "number" then
			rebirthTree[upgradeKey] = 0
			needsRunUpdate = true
		end
	end
	if needsRunUpdate then
		playerIns:SetOneData(dataKey.rebirthTree, rebirthTree)
	end

	return {
		ownedCoins = ownedCoins,
		equippedCoin = equippedCoin,
		ownedDeskSetups = ownedDeskSetups,
		equippedDeskSetup = equippedDeskSetup,
		rebirthTree = rebirthTree,
	}
end

local function getOwnedKey(category)
	if category == "coin" then
		return dataKey.ownedCoins
	end
	if category == "desk" then
		return dataKey.ownedDeskSetups
	end

	return nil
end

local function getEquippedKey(category)
	if category == "coin" then
		return dataKey.equippedCoin
	end
	if category == "desk" then
		return dataKey.equippedDeskSetup
	end

	return nil
end

local function buildLoadoutBonuses(playerIns)
	local growthData = normalizeGrowthData(playerIns)
	return Presets.BuildLoadoutBonuses(growthData.equippedCoin, growthData.equippedDeskSetup)
end

local function buildRebirthUpgrades(rebirthTree)
	local upgrades = {}

	for _, upgradeKey in ipairs(Presets.Growth.RebirthUpgradeOrder) do
		local config = Presets.GetRebirthUpgradeConfig(upgradeKey)
		local level = rebirthTree[upgradeKey] or 0
		local cost = Presets.GetRebirthUpgradeCost(upgradeKey, level)
		if Presets.IsRebirthUpgradeMaxed(upgradeKey, level) then
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

local function buildGrowthState(playerIns, runData, derivedStats)
	local growthData = normalizeGrowthData(playerIns)
	local cash = playerIns:GetOneData(dataKey.wins)
	local rebirthPoints = playerIns:GetOneData(dataKey.fateShards)
	local pointGain = Presets.GetRebirthPointGain(cash)

	return {
		cash = cash,
		rebirth = playerIns:GetOneData(dataKey.rebirth),
		rebirthPoints = rebirthPoints,
		fateShards = rebirthPoints,
		pointGain = pointGain,
		canRebirth = pointGain > 0,
		rebirthMinCash = Presets.Growth.Rebirth.MinCash,
		rebirthCashPerPoint = Presets.Growth.Rebirth.CashPerPoint,
		rebirthCashAfterReset = Presets.Growth.Rebirth.CashAfterReset,
		loadout = {
			equippedCoin = growthData.equippedCoin,
			equippedDeskSetup = growthData.equippedDeskSetup,
			ownedCoins = table.clone(growthData.ownedCoins),
			ownedDeskSetups = table.clone(growthData.ownedDeskSetups),
		},
		rebirthTree = table.clone(growthData.rebirthTree),
		rebirthUpgrades = buildRebirthUpgrades(growthData.rebirthTree),
		shopItems = Presets.Growth.ShopItems,
		runDataAfterReset = Presets.BuildRunBaseline(growthData.rebirthTree),
		derivedStats = derivedStats,
		runData = table.clone(runData),
	}
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
	local bonusStats = buildLoadoutBonuses(playerIns)
	local derivedStats = Presets.BuildDerivedStats(runData, bonusStats)

	return {
		cash = wins,
		wins = wins,
		runData = table.clone(runData),
		derivedStats = derivedStats,
		nextCosts = Presets.GetNextCosts(runData),
		seatState = getSeatState(player),
		onboarding = Onboarding.BuildState(playerIns),
		growthState = buildGrowthState(playerIns, runData, derivedStats),
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
	local bonusStats = buildLoadoutBonuses(playerIns)
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

		playerIns:SetOneData(dataKey.wins, playerIns:GetOneData(dataKey.wins) + reward)
		playerIns:SetOneData(dataKey.lifetimeHeads, playerIns:GetOneData(dataKey.lifetimeHeads) + 1)
		playerIns:SetOneData(dataKey.lifetimeCashEarned, playerIns:GetOneData(dataKey.lifetimeCashEarned) + reward)
		playerIns:SetOneData(
			dataKey.bestStreak,
			math.max(playerIns:GetOneData(dataKey.bestStreak), runData.bestStreakThisRun)
		)
	else
		reward = Presets.GetTailsReward()
		if reward > 0 then
			runData.cashEarnedThisRun += reward
			playerIns:SetOneData(dataKey.wins, playerIns:GetOneData(dataKey.wins) + reward)
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
	applyOnboardingAction(self, player, "buyUpgrade")

	seatSystem:RegisterActivity(SENDER, player)
	refreshCashDisplays(player)
	seatSystem:RefreshAudienceState(SENDER)
	syncPlayerState(self, player, {
		upgradePurchased = upgradeKey,
	})
end

function CoinFlipSystem:RequestShopPurchase(sender, player, args)
	if not IsServer then
		return
	end

	player = player or sender
	if sender ~= SENDER and sender ~= player then
		return
	end
	if typeof(args) ~= "table" then
		return
	end

	local category = Presets.ResolveShopCategory(args.category)
	local item = Presets.GetShopItem(category, args.itemId)
	if not category or not item then
		return
	end

	local ownedKey = getOwnedKey(category)
	local equippedKey = getEquippedKey(category)
	local playerIns = GetPlayerIns(player, false)
	if not playerIns then
		return
	end

	normalizeGrowthData(playerIns)
	local ownedItems = playerIns:GetOneData(ownedKey)
	if ownedItems[item.id] then
		playerIns:SetOneData(equippedKey, item.id)
		refreshCashDisplays(player)
		SystemMgr.systems.TableSeatSystem:RefreshAudienceState(SENDER)
		syncPlayerState(self, player, {
			equippedItem = item.id,
			equippedCategory = category,
		})
		return
	end

	local wins = playerIns:GetOneData(dataKey.wins)
	if wins < item.cost then
		SystemMgr.systems.GuiSystem:SetNotification(SENDER, player, {
			text = "Not enough Cash",
			lastTime = 2,
		})
		syncPlayerState(self, player)
		return
	end

	playerIns:SetOneData(dataKey.wins, wins - item.cost)
	ownedItems[item.id] = true
	playerIns:SetOneData(ownedKey, ownedItems)
	playerIns:SetOneData(equippedKey, item.id)

	refreshCashDisplays(player)
	SystemMgr.systems.TableSeatSystem:RefreshAudienceState(SENDER)
	syncPlayerState(self, player, {
		purchasedItem = item.id,
		equippedItem = item.id,
		equippedCategory = category,
	})
end

function CoinFlipSystem:RequestEquipItem(sender, player, args)
	if not IsServer then
		return
	end

	player = player or sender
	if sender ~= SENDER and sender ~= player then
		return
	end
	if typeof(args) ~= "table" then
		return
	end

	local category = Presets.ResolveShopCategory(args.category)
	local item = Presets.GetShopItem(category, args.itemId)
	if not category or not item then
		return
	end

	local ownedKey = getOwnedKey(category)
	local equippedKey = getEquippedKey(category)
	local playerIns = GetPlayerIns(player, false)
	if not playerIns then
		return
	end

	normalizeGrowthData(playerIns)
	local ownedItems = playerIns:GetOneData(ownedKey)
	if not ownedItems[item.id] then
		return
	end

	playerIns:SetOneData(equippedKey, item.id)
	refreshCashDisplays(player)
	SystemMgr.systems.TableSeatSystem:RefreshAudienceState(SENDER)
	syncPlayerState(self, player, {
		equippedItem = item.id,
		equippedCategory = category,
	})
end

function CoinFlipSystem:RequestRebirth(sender, player)
	if not IsServer then
		return
	end

	player = player or sender
	if sender ~= SENDER and sender ~= player then
		return
	end

	local playerIns = GetPlayerIns(player, false)
	if not playerIns then
		return
	end

	local wins = playerIns:GetOneData(dataKey.wins)
	local pointGain = Presets.GetRebirthPointGain(wins)
	if pointGain <= 0 then
		SystemMgr.systems.GuiSystem:SetNotification(SENDER, player, {
			text = "Build more Cash before rebirth",
			lastTime = 2,
		})
		syncPlayerState(self, player)
		return
	end

	local growthData = normalizeGrowthData(playerIns)
	local resetRunData = Presets.BuildRunBaseline(growthData.rebirthTree)
	playerIns:SetOneData(dataKey.wins, Presets.Growth.Rebirth.CashAfterReset)
	playerIns:SetOneData(dataKey.fateShards, playerIns:GetOneData(dataKey.fateShards) + pointGain)
	playerIns:SetOneData(dataKey.rebirth, playerIns:GetOneData(dataKey.rebirth) + 1)
	playerIns:SetOneData(dataKey.runData, resetRunData)

	SystemMgr.systems.TableSeatSystem:RegisterActivity(SENDER, player)
	refreshCashDisplays(player)
	SystemMgr.systems.TableSeatSystem:RefreshAudienceState(SENDER)
	syncPlayerState(self, player, {
		rebirthed = true,
		rebirthPointGain = pointGain,
	})
end

function CoinFlipSystem:RequestRebirthUpgrade(sender, player, args)
	if not IsServer then
		return
	end

	player = player or sender
	if sender ~= SENDER and sender ~= player then
		return
	end
	if typeof(args) ~= "table" or typeof(args.upgradeKey) ~= "string" then
		return
	end

	local config = Presets.GetRebirthUpgradeConfig(args.upgradeKey)
	if not config then
		return
	end

	local playerIns = GetPlayerIns(player, false)
	if not playerIns then
		return
	end

	local growthData = normalizeGrowthData(playerIns)
	local currentLevel = growthData.rebirthTree[args.upgradeKey] or 0
	if Presets.IsRebirthUpgradeMaxed(args.upgradeKey, currentLevel) then
		return
	end

	local cost = Presets.GetRebirthUpgradeCost(args.upgradeKey, currentLevel)
	local rebirthPoints = playerIns:GetOneData(dataKey.fateShards)
	if rebirthPoints < cost then
		SystemMgr.systems.GuiSystem:SetNotification(SENDER, player, {
			text = "Not enough Rebirth Points",
			lastTime = 2,
		})
		syncPlayerState(self, player)
		return
	end

	growthData.rebirthTree[args.upgradeKey] = currentLevel + 1
	playerIns:SetOneData(dataKey.fateShards, rebirthPoints - cost)
	playerIns:SetOneData(dataKey.rebirthTree, growthData.rebirthTree)

	local runData = normalizeRunData(playerIns)
	if Presets.ApplyRunBaseline(runData, growthData.rebirthTree) then
		playerIns:SetOneData(dataKey.runData, runData)
	end

	refreshCashDisplays(player)
	SystemMgr.systems.TableSeatSystem:RefreshAudienceState(SENDER)
	syncPlayerState(self, player, {
		rebirthUpgradePurchased = args.upgradeKey,
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

	if args.action ~= "approachSeat" then
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

	applyOnboardingAction(self, player, "sitDown", nil, true)
end

function CoinFlipSystem:UpdateOnboarding(sender, player, args)
	if IsServer then
		return
	end

	CoinFlipUi.UpdateOnboarding(args and args.onboarding)
end

return CoinFlipSystem
