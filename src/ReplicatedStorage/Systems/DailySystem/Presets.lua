local Replicated = game:GetService("ReplicatedStorage")

local GameConfig = require(Replicated.configs.GameConfig)
local Keys = require(Replicated.configs.Keys)
local Textures = require(Replicated.configs.Textures)

local DailyPresets = {}

DailyPresets.GiftList = {
	[1] = {
		count = 150,
		itemType = Keys.ItemType.wins,
		gradient = "Gray",
	},
	[2] = {
		count = 1,
		name = "Diamond Pack",
		itemType = Keys.ItemType.cardPacks,
		gradient = "Gold",
	},
	[3] = {
		count = 1,
		name = "wins1Potion30",
		itemType = Keys.ItemType.potion,
		gradient = "Green",
	},
	[4] = {
		count = 500,
		itemType = Keys.ItemType.wins,
		gradient = "Green",
	},
	[5] = {
		count = 2,
		name = "Purple Symbol Pack",
		itemType = Keys.ItemType.cardPacks,
		gradient = "Blue",
	},
	[6] = {
		count = 1,
		name = "lucky2Potion15",
		itemType = Keys.ItemType.potion,
		gradient = "Blue",
	},
	[7] = {
		count = 1,
		name = "Red Apple Pack",
		itemType = Keys.ItemType.cardPacks,
		gradient = "Gold",
	},
}

return DailyPresets
