local EffectPresets = {}

EffectPresets.CoinFlipVisuals = table.freeze({
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
	HeadsPulseColor = Color3.fromRGB(255, 225, 109),
	TailsPulseColor = Color3.fromRGB(255, 151, 121),
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
	-- 平铺落地：局部厚度轴与世界桌面法线。1 为 +Y 对 +法线；-1 为 +Y 对 -法线（常见导入硬币）
	FlatThicknessLocalSign = -1,
})

return EffectPresets
