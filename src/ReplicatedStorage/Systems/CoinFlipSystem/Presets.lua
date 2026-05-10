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

Presets.ShopCategoryAliases = table.freeze({
	coin = "coin",
	coins = "coin",
	desk = "desk",
	desks = "desk",
	desksetup = "desk",
	desksetups = "desk",
})

Presets.Growth = {
	Rebirth = {
		MinCash = 250,
		CashPerPoint = 250,
		MaxPointGain = 8,
		CashAfterReset = 30,
	},
	RebirthUpgrades = {
		polishedStart = {
			displayName = "Polished Start",
			description = "+1 Value level after each rebirth",
			runDataKey = "valueLevel",
			runDataStep = 1,
			costBase = 1,
			costGrowth = 2,
			maxLevel = 5,
		},
		chainStart = {
			displayName = "Chain Start",
			description = "+1 Combo level after each rebirth",
			runDataKey = "comboLevel",
			runDataStep = 1,
			costBase = 1,
			costGrowth = 2,
			maxLevel = 5,
		},
		quickStart = {
			displayName = "Quick Start",
			description = "+1 Speed level after each rebirth",
			runDataKey = "speedLevel",
			runDataStep = 1,
			costBase = 1,
			costGrowth = 2,
			maxLevel = 5,
		},
		luckyStart = {
			displayName = "Lucky Start",
			description = "+1 Bias level after each rebirth",
			runDataKey = "biasLevel",
			runDataStep = 1,
			costBase = 1,
			costGrowth = 2,
			maxLevel = 5,
		},
	},
	RebirthUpgradeOrder = table.freeze({
		"polishedStart",
		"chainStart",
		"quickStart",
		"luckyStart",
	}),
	ShopItems = {
		coin = table.freeze({
			{
				id = "Rusty Penny",
				displayName = "Rusty Penny",
				rarity = "Common",
				role = "Starter",
				cost = 0,
				stats = {
					coinMultiplier = 1,
					luckBonus = 0,
				},
			},
			{
				id = "Lucky Nickel",
				displayName = "Lucky Nickel",
				rarity = "Uncommon",
				role = "Luck",
				cost = 180,
				stats = {
					coinMultiplier = 1.05,
					luckBonus = 0.025,
				},
			},
			{
				id = "Combo Quarter",
				displayName = "Combo Quarter",
				rarity = "Rare",
				role = "Streak",
				cost = 520,
				stats = {
					coinMultiplier = 1.16,
					luckBonus = 0.01,
				},
			},
			{
				id = "Royal Doubloon",
				displayName = "Royal Doubloon",
				rarity = "Epic",
				role = "Cash",
				cost = 1400,
				stats = {
					coinMultiplier = 1.35,
					luckBonus = 0.018,
				},
			},
		}),
		desk = table.freeze({
			{
				id = "Folding Table",
				displayName = "Folding Table",
				rarity = "Common",
				role = "Starter",
				cost = 0,
				stats = {
					coinMultiplier = 1,
					luckBonus = 0,
				},
			},
			{
				id = "Green Felt",
				displayName = "Green Felt",
				rarity = "Uncommon",
				role = "Steady",
				cost = 260,
				stats = {
					coinMultiplier = 1.08,
					luckBonus = 0.008,
				},
			},
			{
				id = "Arcade Desk",
				displayName = "Arcade Desk",
				rarity = "Rare",
				role = "Fast Cash",
				cost = 760,
				stats = {
					coinMultiplier = 1.18,
					luckBonus = 0.012,
				},
			},
			{
				id = "Velvet Casino",
				displayName = "Velvet Casino",
				rarity = "Epic",
				role = "Premium",
				cost = 1800,
				stats = {
					coinMultiplier = 1.30,
					luckBonus = 0.02,
				},
			},
		}),
	},
}

Presets.Visuals = table.freeze({
	CoinSize = Vector3.new(0.14, 0.92, 0.92),
	CoinStartHeight = 0.35,
	CoinSurfaceGap = 0.01,
	ShadowHeight = 0.03,
	ShadowSurfaceGap = 0.003,
	ArcHeight = 2.85,
	ArcHeightTravelFactor = 0.35,
	LandingRadius = 4.4,
	TravelDuration = 0.72,
	LandingDuration = 0.18,
	ResultRevealDelay = 0.08,
	CleanupDelay = 0.85,
	SpinTurns = 7,
	BankAngle = math.rad(16),
	RimColor = Color3.fromRGB(223, 184, 72),
	RimMaterial = Enum.Material.Metal,
	RimReflectance = 0.1,
	HeadsColor = Color3.fromRGB(255, 236, 156),
	HeadsAccentColor = Color3.fromRGB(112, 77, 10),
	TailsColor = Color3.fromRGB(92, 57, 40),
	TailsAccentColor = Color3.fromRGB(255, 235, 204),
	HeadsPulseColor = Color3.fromRGB(255, 225, 109),
	TailsPulseColor = Color3.fromRGB(255, 151, 121),
	ResultHeadsColor = Color3.fromRGB(255, 225, 109),
	ResultTailsColor = Color3.fromRGB(255, 173, 156),
	ResultNeutralColor = Color3.fromRGB(232, 236, 242),
	ShadowColor = Color3.fromRGB(16, 10, 6),
	ShadowBaseTransparency = 0.58,
	ShadowMaxTransparency = 0.82,
	ShadowMinScale = 0.42,
	ShadowMaxScale = 1.1,
	PulseStartSize = 0.46,
	PulseEndSize = 2.8,
	PulseDuration = 0.26,
	StreakPulseMinimum = 2,
	StreakPulseColor = Color3.fromRGB(255, 241, 158),
	StreakPulseStartSize = 0.72,
	StreakPulseEndSize = 3.8,
	StreakPulseDuration = 0.38,
})

Presets.UiLayout = table.freeze({
	MobileMaxWidth = 980,
	MobileMaxAspect = 1.55,
	NarrowWidth = 1400,
	Hud = {
		DesktopSize = Vector2.new(0.58, 0.23),
		NarrowSize = Vector2.new(0.66, 0.245),
		MobileLandscapeSize = Vector2.new(0.72, 0.26),
		MobilePortraitSize = Vector2.new(0.9, 0.46),
		DesktopY = 0.965,
		MobileLandscapeY = 0.98,
		MobilePortraitY = 0.985,
		MinSize = Vector2.new(520, 210),
		MaxSize = Vector2.new(1120, 460),
		MobileMinSize = Vector2.new(320, 144),
		MobileMaxSize = Vector2.new(560, 320),
	},
})

function Presets.ResolveUpgradeKey(upgradeType)
	if typeof(upgradeType) ~= "string" then
		return nil
	end

	return Presets.UpgradeAliases[string.lower(upgradeType)]
end

function Presets.ResolveShopCategory(category)
	if typeof(category) ~= "string" then
		return nil
	end

	return Presets.ShopCategoryAliases[string.lower(category)]
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

function Presets.GetShopItem(category, itemId)
	local resolvedCategory = Presets.ResolveShopCategory(category)
	if not resolvedCategory or typeof(itemId) ~= "string" then
		return nil
	end

	for _, item in ipairs(Presets.Growth.ShopItems[resolvedCategory]) do
		if item.id == itemId then
			return item
		end
	end

	return nil
end

function Presets.GetRebirthUpgradeConfig(upgradeKey)
	return Presets.Growth.RebirthUpgrades[upgradeKey]
end

function Presets.GetRebirthUpgradeCost(upgradeKey, currentLevel)
	local config = Presets.GetRebirthUpgradeConfig(upgradeKey)
	if not config then
		return nil
	end

	return math.round(config.costBase * (config.costGrowth ^ currentLevel))
end

function Presets.IsRebirthUpgradeMaxed(upgradeKey, currentLevel)
	local config = Presets.GetRebirthUpgradeConfig(upgradeKey)
	return config and currentLevel >= config.maxLevel
end

function Presets.GetRebirthPointGain(cash)
	local config = Presets.Growth.Rebirth
	if cash < config.MinCash then
		return 0
	end

	return math.clamp(math.floor(cash / config.CashPerPoint), 1, config.MaxPointGain)
end

function Presets.BuildRunBaseline(rebirthTree)
	local baseline = table.clone(Presets.RunDataDefaults)
	rebirthTree = rebirthTree or {}

	for _, upgradeKey in ipairs(Presets.Growth.RebirthUpgradeOrder) do
		local config = Presets.GetRebirthUpgradeConfig(upgradeKey)
		local level = rebirthTree[upgradeKey] or 0
		if config and config.runDataKey then
			baseline[config.runDataKey] += level * config.runDataStep
		end
	end

	return baseline
end

function Presets.ApplyRunBaseline(runData, rebirthTree)
	local baseline = Presets.BuildRunBaseline(rebirthTree)
	local changed = false

	for _, upgradeKey in ipairs(Presets.UpgradeOrder) do
		if (runData[upgradeKey] or 0) < baseline[upgradeKey] then
			runData[upgradeKey] = baseline[upgradeKey]
			changed = true
		end
	end

	return changed
end

function Presets.BuildLoadoutBonuses(equippedCoin, equippedDeskSetup)
	local bonuses = {
		coinMultiplier = 1,
		luckBonus = 0,
	}
	local equippedItems = {
		Presets.GetShopItem("coin", equippedCoin),
		Presets.GetShopItem("desk", equippedDeskSetup),
	}

	for _, item in ipairs(equippedItems) do
		if item and item.stats then
			bonuses.coinMultiplier *= item.stats.coinMultiplier or 1
			bonuses.luckBonus += item.stats.luckBonus or 0
		end
	end

	return bonuses
end

function Presets.GetHeadsChance(runData, bonusStats)
	local luckBonus = bonusStats and bonusStats.luckBonus or 0
	return math.min(FlipConfig.MaxHeadsChance, FlipConfig.BaseHeadsChance + FlipConfig.BiasStep * runData.biasLevel + luckBonus)
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

function Presets.GetTailsReward()
	return FlipConfig.BaseTailsReward or 0
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
		luckBonus = bonusStats and bonusStats.luckBonus or 0,
	}
end

return Presets
