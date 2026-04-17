local Replicated = game:GetService("ReplicatedStorage")

local GameConfig = require(Replicated.configs.GameConfig)

local Presets = {
	TableModelName = "CoinFlipTable",
	SeatsFolderName = "Seats",
	AfkCheckInterval = 1,
}

Presets.AfkKickSeconds = GameConfig.FlipACoin.AfkKickSeconds
Presets.Billboard = table.freeze({
	MaxDistance = 56,
	FullSize = Vector2.new(168, 74),
	CompactSize = Vector2.new(132, 44),
	StudsOffset = Vector3.new(0, 3.7, 0),
	CompactStudsOffset = Vector3.new(0, 3.35, 0),
})

Presets.HotSeat = table.freeze({
	StreakWeight = 100,
	RecentActivityWindow = 12,
	RecentActivityWeight = 6,
	CashBonusDivisor = 500,
	MaxCashBonus = 12,
	RecentSeatWindow = 5,
})

return Presets
