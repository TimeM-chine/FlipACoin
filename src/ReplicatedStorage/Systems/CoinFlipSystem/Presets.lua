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

function Presets.GetHeadsChance(runData)
	return math.min(FlipConfig.MaxHeadsChance, FlipConfig.BaseHeadsChance + FlipConfig.BiasStep * runData.biasLevel)
end

function Presets.GetFlipInterval(runData)
	return math.max(FlipConfig.MinFlipInterval, FlipConfig.BaseFlipInterval * (FlipConfig.SpeedDecay ^ runData.speedLevel))
end

function Presets.GetComboStep(runData)
	return FlipConfig.ComboBaseStep + FlipConfig.ComboStepPerLevel * runData.comboLevel
end

function Presets.GetValueMultiplier(runData)
	return FlipConfig.ValueGrowth ^ runData.valueLevel
end

function Presets.GetHeadsReward(runData)
	local comboMultiplier = 1 + math.max(runData.currentStreak - 1, 0) * Presets.GetComboStep(runData)
	return math.round(FlipConfig.BaseReward * Presets.GetValueMultiplier(runData) * comboMultiplier)
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

function Presets.BuildDerivedStats(runData)
	return {
		headsChance = Presets.GetHeadsChance(runData),
		flipInterval = Presets.GetFlipInterval(runData),
		comboStep = Presets.GetComboStep(runData),
		valueMultiplier = Presets.GetValueMultiplier(runData),
	}
end

return Presets
