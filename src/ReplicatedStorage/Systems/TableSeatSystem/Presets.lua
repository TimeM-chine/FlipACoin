local Replicated = game:GetService("ReplicatedStorage")

local GameConfig = require(Replicated.configs.GameConfig)

local Presets = {
	TableModelName = "CoinFlipTable",
	SeatsFolderName = "Seats",
	AfkCheckInterval = 1,
}

Presets.AfkKickSeconds = GameConfig.FlipACoin.AfkKickSeconds

return Presets
