local Replicated = game:GetService("ReplicatedStorage")

local Textures = require(Replicated.configs.Textures)
local GameConfig = require(Replicated.configs.GameConfig)

local PotionPresets = {}

PotionPresets.Potions = {
	wins1Potion30 = {
		buffName = "wins1",
		duration = GameConfig.OneMinute * 30,
	},
	lucky1Potion15 = {
		buffName = "lucky1",
		duration = GameConfig.OneMinute * 15,
	},
	lucky2Potion15 = {
		buffName = "lucky2",
		duration = GameConfig.OneMinute * 15,
	},
}

PotionPresets.FakePotions = {
	vip = {
		icon = "rbxassetid://14526160119",
	},
}

return PotionPresets
