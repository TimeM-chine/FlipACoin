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
	return math.max(
		FlipConfig.MinFlipInterval,
		FlipConfig.BaseFlipInterval * (FlipConfig.SpeedDecay ^ runData.speedLevel)
	)
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

function Presets.BuildDerivedStats(runData)
	return {
		headsChance = Presets.GetHeadsChance(runData),
		flipInterval = Presets.GetFlipInterval(runData),
		comboStep = Presets.GetComboStep(runData),
		valueMultiplier = Presets.GetValueMultiplier(runData),
	}
end

return Presets
