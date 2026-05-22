local Replicated = game:GetService("ReplicatedStorage")

local GameConfig = require(Replicated.configs.GameConfig)

local FlipConfig = GameConfig.FlipACoin

local Presets = {}

Presets.RunDataDefaults = table.freeze({
	valueLevel = 0,
	comboLevel = 0,
	speedLevel = 0,
	biasLevel = 0,
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

function Presets.GetHeadsReward(runData, bonusStats)
	local comboMultiplier = 1 + math.max(runData.currentStreak - 1, 0) * Presets.GetComboStep(runData)
	local coinMultiplier = bonusStats and bonusStats.coinMultiplier or 1
	return math.round(FlipConfig.BaseReward * Presets.GetValueMultiplier(runData) * comboMultiplier * coinMultiplier)
end

function Presets.GetTailsReward(bonusStats)
	local premiumCoinMultiplier = bonusStats and bonusStats.premiumCoinMultiplier or 1
	return math.round((FlipConfig.BaseTailsReward or 0) * premiumCoinMultiplier)
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
	return {
		headsChance = Presets.GetHeadsChance(runData, bonusStats),
		flipInterval = Presets.GetFlipInterval(runData, bonusStats),
		comboStep = Presets.GetComboStep(runData),
		valueMultiplier = Presets.GetValueMultiplier(runData),
		coinMultiplier = bonusStats and bonusStats.coinMultiplier or 1,
		premiumCoinMultiplier = bonusStats and bonusStats.premiumCoinMultiplier or 1,
		luckBonus = bonusStats and bonusStats.luckBonus or 0,
	}
end

return Presets
