local Replicated = game:GetService("ReplicatedStorage")

local GameConfig = require(Replicated.configs.GameConfig)

local FlipConfig = GameConfig.FlipACoin

local Presets = {}

Presets.RunDataDefaults = table.freeze({
	valueLevel = 0,
	comboLevel = 0,
	speedLevel = 0,
	biasLevel = 0,
	coinCountLevel = 0,
	currentStreak = 0,
	bestStreakThisRun = 0,
	cashEarnedThisRun = 0,
	flipsThisRun = 0,
	headsThisRun = 0,
})

Presets.UpgradeOrder = table.freeze({
	"valueLevel",
	"comboLevel",
	"speedLevel",
	"biasLevel",
})

Presets.UpgradeAliases = table.freeze({
	value = "valueLevel",
	valuelevel = "valueLevel",
	combo = "comboLevel",
	combolevel = "comboLevel",
	speed = "speedLevel",
	speedlevel = "speedLevel",
	bias = "biasLevel",
	biaslevel = "biasLevel",
})

Presets.UiLayout = table.freeze({
	MobileMaxWidth = 980,
	MobileMaxAspect = 1.55,
	NarrowWidth = 1400,
	Hud = {
		DesktopSize = Vector2.new(1, 1),
		NarrowSize = Vector2.new(1, 1),
		MobileLandscapeSize = Vector2.new(0.72, 0.22),
		MobilePortraitSize = Vector2.new(0.9, 0.34),
		DesktopY = 1,
		MobileLandscapeY = 0.982,
		MobilePortraitY = 0.988,
		MinSize = Vector2.new(0, 0),
		MaxSize = Vector2.new(3840, 2160),
		MobileMinSize = Vector2.new(320, 128),
		MobileMaxSize = Vector2.new(560, 260),
	},
})

function Presets.ResolveUpgradeKey(upgradeType)
	if typeof(upgradeType) ~= "string" then
		return nil
	end

	return Presets.UpgradeAliases[string.lower(upgradeType)]
end

function Presets.GetUpgradeConfig(upgradeKey)
	return FlipConfig.UpgradeConfigs[upgradeKey]
end

function Presets.GetUpgradeDisplayName(upgradeKey)
	local config = Presets.GetUpgradeConfig(upgradeKey)
	return config and config.displayName or upgradeKey
end

function Presets.GetUpgradeCost(upgradeKey, currentLevel)
	local config = Presets.GetUpgradeConfig(upgradeKey)
	if not config then
		return nil
	end

	return math.round(config.costBase * (config.costGrowth ^ currentLevel))
end

function Presets.IsUpgradeMaxed(upgradeKey, currentLevel)
	local config = Presets.GetUpgradeConfig(upgradeKey)
	return config and currentLevel >= config.maxLevel
end

function Presets.GetHeadsChance(runData, bonusStats)
	local luckBonus = bonusStats and bonusStats.luckBonus or 0
	return math.min(
		FlipConfig.MaxHeadsChance,
		FlipConfig.BaseHeadsChance + FlipConfig.BiasStep * runData.biasLevel + luckBonus
	)
end

function Presets.GetFirstRebirthAssistBonus(cash, rebirthMinCash, consecutiveTails)
	local config = FlipConfig.FirstRebirthAssist
	if not config or cash >= rebirthMinCash then
		return 0
	end

	return (config.BaseBonus or 0) + (config.TailsBonusStep or 0) * math.max(consecutiveTails or 0, 0)
end

function Presets.GetFirstRebirthAssistMaxHeadsChance()
	local config = FlipConfig.FirstRebirthAssist
	return config and config.MaxHeadsChance or FlipConfig.MaxHeadsChance
end

function Presets.GetBadLuckPityBonus(consecutiveFailures)
	local config = FlipConfig.BadLuckPity
	if not config then
		return 0
	end

	local failureCount = math.max(consecutiveFailures or 0, 0)
	if failureCount < config.FailureThreshold then
		return 0
	end

	local bonusSteps = failureCount - config.FailureThreshold + 1
	return math.min(config.MaxChanceBonus, config.ChanceBonusStep * bonusSteps)
end

function Presets.GetBadLuckPityMaxHeadsChance()
	local config = FlipConfig.BadLuckPity
	return config and config.MaxHeadsChance or FlipConfig.MaxHeadsChance
end

function Presets.GetEdgeStandChance(outcome, pityActive, failureStreak, bonusStats)
	local config = FlipConfig.EdgeStand
	if not config or typeof(outcome) ~= "table" then
		return 0
	end
	if outcome.roundSuccess or (outcome.tailsCount or 0) <= 0 then
		return 0
	end
	if (failureStreak or 0) < (config.FailureStreakMinimum or 0) then
		return 0
	end

	local chance = (config.BaseChance or 0) + (bonusStats and bonusStats.edgeStandChanceBonus or 0)
	if pityActive then
		chance += config.PityChanceBonus or 0
	end

	return math.min(config.MaxChance or chance, math.max(0, chance))
end

function Presets.GetEdgeStandBonusReward()
	local config = FlipConfig.EdgeStand
	return math.max(0, math.round(config and config.BonusReward or 0))
end

function Presets.GetEdgeStandCoinIndex(outcome)
	if typeof(outcome) ~= "table" or typeof(outcome.coinResults) ~= "table" then
		return nil
	end

	for coinIndex, result in ipairs(outcome.coinResults) do
		if result == "Tails" then
			return coinIndex
		end
	end

	return nil
end

function Presets.GetLuckyCoinTailsRerollChance(bonusStats)
	return math.max(0, bonusStats and bonusStats.tailsRerollChance or 0)
end

function Presets.GetLuckyCoinTailsRerollIndex(coinResults)
	local tailsIndexes = {}
	for coinIndex, result in ipairs(coinResults) do
		if result == "Tails" then
			table.insert(tailsIndexes, coinIndex)
		end
	end

	if #tailsIndexes <= 0 then
		return nil
	end

	return tailsIndexes[math.random(1, #tailsIndexes)]
end

function Presets.ApplyLuckyCoinTailsReroll(roll, rollHeadsChance, bonusStats)
	local rerollChance = Presets.GetLuckyCoinTailsRerollChance(bonusStats)
	if rerollChance <= 0 or roll.tailsCount <= 0 or math.random() >= rerollChance then
		return nil
	end

	local coinIndex = Presets.GetLuckyCoinTailsRerollIndex(roll.coinResults)
	if not coinIndex then
		return nil
	end

	local result = if math.random() < rollHeadsChance then "Heads" else "Tails"
	roll.coinResults[coinIndex] = result
	if result == "Heads" then
		roll.headsCount += 1
		roll.tailsCount -= 1
	end

	return {
		chance = rerollChance,
		coinIndex = coinIndex,
		result = result,
	}
end

function Presets.GetRollHeadsChance(runData, bonusStats, hiddenChanceBonus, hiddenChanceMax)
	local visibleChance = Presets.GetHeadsChance(runData, bonusStats)
	if (hiddenChanceBonus or 0) <= 0 then
		return visibleChance
	end

	local maxHeadsChance = hiddenChanceMax or FlipConfig.MaxHeadsChance
	return math.min(
		FlipConfig.MaxHeadsChance,
		math.max(visibleChance, math.min(maxHeadsChance, visibleChance + hiddenChanceBonus))
	)
end

function Presets.GetCoinCount(runData, bonusStats)
	local coinCount = 1

	for _, config in ipairs(FlipConfig.CoinCountByLevel) do
		if runData.coinCountLevel >= config.minLevel then
			coinCount = config.count
		end
	end

	return coinCount
end

function Presets.GetRoundSuccessThreshold(coinCount)
	return FlipConfig.SuccessThresholdByCoinCount[coinCount]
end

function Presets.RollCoinResults(runData, bonusStats, hiddenChanceBonus, hiddenChanceMax)
	local coinCount = Presets.GetCoinCount(runData, bonusStats)
	local rollHeadsChance = Presets.GetRollHeadsChance(runData, bonusStats, hiddenChanceBonus, hiddenChanceMax)
	local coinResults = {}
	local headsCount = 0

	for coinIndex = 1, coinCount do
		local result = if math.random() < rollHeadsChance then "Heads" else "Tails"
		coinResults[coinIndex] = result
		if result == "Heads" then
			headsCount += 1
		end
	end

	local roll = {
		coinCount = coinCount,
		coinResults = coinResults,
		headsCount = headsCount,
		tailsCount = coinCount - headsCount,
	}
	local luckyCoinReroll = Presets.ApplyLuckyCoinTailsReroll(roll, rollHeadsChance, bonusStats)
	if luckyCoinReroll then
		roll.luckyCoinReroll = true
		roll.luckyCoinRerollChance = luckyCoinReroll.chance
		roll.luckyCoinRerollCoinIndex = luckyCoinReroll.coinIndex
		roll.luckyCoinRerollResult = luckyCoinReroll.result
	end

	return roll
end

function Presets.BuildRoundOutcome(runData, bonusStats, hiddenChanceBonus, hiddenChanceMax)
	local roll = Presets.RollCoinResults(runData, bonusStats, hiddenChanceBonus, hiddenChanceMax)
	local successThreshold = Presets.GetRoundSuccessThreshold(roll.coinCount)
	local roundSuccess = roll.headsCount >= successThreshold
	local perfect = roll.headsCount == roll.coinCount
	local comboKey = Presets.GetComboKey(roll.headsCount, roll.coinCount, perfect)

	return {
		coinCount = roll.coinCount,
		coinResults = roll.coinResults,
		headsCount = roll.headsCount,
		tailsCount = roll.tailsCount,
		roundSuccess = roundSuccess,
		successThreshold = successThreshold,
		perfect = perfect,
		comboKey = comboKey,
		comboTier = Presets.GetComboTier(comboKey),
		comboName = Presets.GetComboName(roll.headsCount, roll.coinCount, perfect),
		comboMultiplier = Presets.GetComboMultiplier(roll.headsCount),
		luckyCoinReroll = roll.luckyCoinReroll == true,
		luckyCoinRerollChance = roll.luckyCoinRerollChance or 0,
		luckyCoinRerollCoinIndex = roll.luckyCoinRerollCoinIndex,
		luckyCoinRerollResult = roll.luckyCoinRerollResult,
	}
end

function Presets.GetFlipInterval(runData, bonusStats)
	local flipIntervalMultiplier = bonusStats and bonusStats.flipIntervalMultiplier or 1
	return math.max(
		FlipConfig.MinFlipInterval,
		FlipConfig.BaseFlipInterval * (FlipConfig.SpeedDecay ^ runData.speedLevel) * flipIntervalMultiplier
	)
end

function Presets.GetComboStep(runData)
	return FlipConfig.ComboBaseStep + FlipConfig.ComboStepPerLevel * runData.comboLevel
end

function Presets.GetValueMultiplier(runData)
	return FlipConfig.ValueGrowth ^ runData.valueLevel
end

function Presets.GetComboMultiplier(headsCount)
	return FlipConfig.ComboMultiplierByHeadsCount[headsCount]
end

function Presets.GetComboName(headsCount, coinCount, perfect)
	local comboName = FlipConfig.ComboNamesByHeadsCount[headsCount]
	if headsCount >= 5 then
		return comboName
	end
	if perfect and coinCount >= 3 then
		return `Perfect {comboName}`
	end

	return comboName
end

function Presets.GetComboKey(headsCount, coinCount, perfect)
	if headsCount <= 0 then
		return "none"
	end
	if headsCount >= 5 then
		return "jackpot"
	end
	if perfect and coinCount >= 3 then
		return "perfect"
	end
	if headsCount >= 4 then
		return "fourHeads"
	end
	if headsCount >= 3 then
		return "triple"
	end
	if headsCount >= 2 then
		return "pair"
	end

	return "heads"
end

function Presets.GetComboTier(comboKey)
	if comboKey == "jackpot" then
		return 5
	end
	if comboKey == "perfect" then
		return 4
	end
	if comboKey == "fourHeads" then
		return 3
	end
	if comboKey == "triple" then
		return 2
	end
	if comboKey == "pair" then
		return 1
	end

	return 0
end

function Presets.GetHeadsReward(runData, bonusStats)
	local comboMultiplier = 1 + math.max(runData.currentStreak - 1, 0) * Presets.GetComboStep(runData)
	local coinMultiplier = bonusStats and bonusStats.coinMultiplier or 1
	return math.round(FlipConfig.BaseReward * Presets.GetValueMultiplier(runData) * comboMultiplier * coinMultiplier)
end

function Presets.GetTailsReward(bonusStats)
	local premiumCoinMultiplier = bonusStats and bonusStats.premiumCoinMultiplier or 1
	return math.round((FlipConfig.BaseTailsReward or 0) * premiumCoinMultiplier)
end

function Presets.GetRoundReward(runData, bonusStats, outcome)
	local coinMultiplier = bonusStats and bonusStats.coinMultiplier or 1
	local premiumCoinMultiplier = bonusStats and bonusStats.premiumCoinMultiplier or 1
	local perHeadReward = FlipConfig.BaseReward * Presets.GetValueMultiplier(runData) * coinMultiplier

	if outcome.headsCount > 0 then
		local headsReward = perHeadReward * outcome.headsCount
		if outcome.roundSuccess then
			local streakMultiplier = 1 + math.max(runData.currentStreak - 1, 0) * Presets.GetComboStep(runData)
			local perfectRewardMultiplier = 1
			if outcome.comboKey == "perfect" or outcome.comboKey == "jackpot" then
				perfectRewardMultiplier += bonusStats and bonusStats.perfectRewardMultiplierBonus or 0
			end

			return math.round(headsReward * streakMultiplier * outcome.comboMultiplier * perfectRewardMultiplier)
		end

		return math.round(headsReward)
	end

	return math.round((FlipConfig.BaseTailsReward or 0) * outcome.tailsCount * premiumCoinMultiplier)
end

function Presets.GetTableJackpotAudienceReward(outcome)
	local config = FlipConfig.TableJackpot
	if not config then
		return 0
	end
	if typeof(outcome) ~= "table" then
		return 0
	end
	if outcome.comboKey ~= "jackpot" then
		return 0
	end
	if outcome.coinCount ~= config.CoinCount or outcome.headsCount ~= config.HeadsCount then
		return 0
	end

	return math.max(0, math.round(config.AudienceReward or 0))
end

function Presets.GetTableJackpotNotificationDuration()
	local config = FlipConfig.TableJackpot
	return config and config.NotificationDuration or 2.8
end

function Presets.GetProfileXpReward(outcome)
	local config = FlipConfig.ProfileXp
	if not config then
		return 0
	end

	local xpReward = (config.BasePerFlip or 0) + (config.PerHead or 0) * (outcome.headsCount or 0)
	if outcome.roundSuccess then
		xpReward += config.RoundSuccessBonus or 0
	end
	if outcome.perfect then
		xpReward += config.PerfectBonus or 0
	end
	if outcome.comboKey == "jackpot" then
		xpReward += config.JackpotBonus or 0
	end

	return math.min(config.MaxPerFlip or xpReward, math.max(0, math.round(xpReward)))
end

function Presets.GetDailyGoalDay(now)
	return math.floor((now or os.time()) / GameConfig.OneDay)
end

function Presets.NormalizeDailyGoals(dailyClaim, currentDay)
	local changed = false
	local flipGoals = dailyClaim.flipACoinGoals

	if typeof(flipGoals) ~= "table" or flipGoals.day ~= currentDay then
		flipGoals = {
			day = currentDay,
			progress = {},
			claimed = {},
		}
		dailyClaim.flipACoinGoals = flipGoals
		changed = true
	end

	if typeof(flipGoals.progress) ~= "table" then
		flipGoals.progress = {}
		changed = true
	end
	if typeof(flipGoals.claimed) ~= "table" then
		flipGoals.claimed = {}
		changed = true
	end

	for _, goalConfig in ipairs(FlipConfig.DailyGoals or {}) do
		if typeof(flipGoals.progress[goalConfig.id]) ~= "number" then
			flipGoals.progress[goalConfig.id] = 0
			changed = true
		end
	end

	return flipGoals, changed
end

function Presets.ApplyDailyGoalProgress(dailyGoals, outcome, runData)
	local completedGoals = {}
	local changed = false

	for _, goalConfig in ipairs(FlipConfig.DailyGoals or {}) do
		local goalId = goalConfig.id
		if not dailyGoals.claimed[goalId] then
			local progress = dailyGoals.progress[goalId] or 0
			if goalConfig.metric == "flips" then
				progress += 1
			elseif goalConfig.metric == "heads" then
				progress += outcome.headsCount or 0
			elseif goalConfig.metric == "streak" then
				progress = math.max(progress, runData.currentStreak or 0)
			end

			progress = math.min(progress, goalConfig.target)
			if progress ~= dailyGoals.progress[goalId] then
				dailyGoals.progress[goalId] = progress
				changed = true
			end
			if progress >= goalConfig.target then
				dailyGoals.claimed[goalId] = true
				changed = true
				table.insert(completedGoals, {
					id = goalId,
					displayName = goalConfig.displayName,
					target = goalConfig.target,
					reward = goalConfig.reward,
				})
			end
		end
	end

	return completedGoals, changed
end

function Presets.GetNextCosts(runData)
	local costs = {}

	for _, upgradeKey in ipairs(Presets.UpgradeOrder) do
		local currentLevel = runData[upgradeKey] or 0
		if Presets.IsUpgradeMaxed(upgradeKey, currentLevel) then
			costs[upgradeKey] = nil
		else
			costs[upgradeKey] = Presets.GetUpgradeCost(upgradeKey, currentLevel)
		end
	end

	return costs
end

function Presets.BuildDerivedStats(runData, bonusStats)
	local coinCount = Presets.GetCoinCount(runData, bonusStats)

	return {
		headsChance = Presets.GetHeadsChance(runData, bonusStats),
		flipInterval = Presets.GetFlipInterval(runData, bonusStats),
		comboStep = Presets.GetComboStep(runData),
		valueMultiplier = Presets.GetValueMultiplier(runData),
		coinCount = coinCount,
		successThreshold = Presets.GetRoundSuccessThreshold(coinCount),
		coinMultiplier = bonusStats and bonusStats.coinMultiplier or 1,
		premiumCoinMultiplier = bonusStats and bonusStats.premiumCoinMultiplier or 1,
		luckBonus = bonusStats and bonusStats.luckBonus or 0,
		edgeStandChanceBonus = bonusStats and bonusStats.edgeStandChanceBonus or 0,
		perfectRewardMultiplierBonus = bonusStats and bonusStats.perfectRewardMultiplierBonus or 0,
		tailsRerollChance = bonusStats and bonusStats.tailsRerollChance or 0,
	}
end

return Presets
