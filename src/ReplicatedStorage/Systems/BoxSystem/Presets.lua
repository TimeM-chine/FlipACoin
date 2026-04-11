local Replicated = game:GetService("ReplicatedStorage")
local GameConfig = require(Replicated.configs.GameConfig)
local Keys = require(Replicated.configs.Keys)

local BoxPresets = {}

BoxPresets.GroupGiftTime = GameConfig.OneHour * 12

BoxPresets.GroupRewardList = {
	{
		itemType = Keys.ItemType.wins,
		count = 100,
	},
	{
		itemType = Keys.ItemType.potion,
		name = "wins1Potion30",
		count = 1,
	},
	{
		itemType = Keys.ItemType.potion,
		name = "lucky1Potion15",
		count = 1,
	},
	{
		itemType = Keys.ItemType.potion,
		name = "lucky2Potion15",
		count = 1,
	},
}

return BoxPresets
