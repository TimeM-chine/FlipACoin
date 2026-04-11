local Replicated = game:GetService("ReplicatedStorage")
local Keys = require(Replicated.configs.Keys)
local GameConfig = require(Replicated.configs.GameConfig)

local FreeRewardPresets = {}

FreeRewardPresets.Reward = {
	reward = {
		itemType = Keys.ItemType.pet,
		name = "Watermelon Winner",
		count = 1,
	},
	quests = {
		[1] = {
			description = "Play for 20 minutes!",
			questType = Keys.QuestType.online,
			target = 20,
		},
		[2] = {
			description = "Join game after 24 hours!",
			questType = Keys.QuestType.afterPeriod,
			target = GameConfig.OneDay,
		},
	},
}

return FreeRewardPresets
