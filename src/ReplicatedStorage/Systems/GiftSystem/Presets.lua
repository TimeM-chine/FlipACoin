local Replicated = game:GetService("ReplicatedStorage")
local GameConfig = require(Replicated.configs.GameConfig)
local Keys = require(Replicated.configs.Keys)
local Textures = require(Replicated.configs.Textures)

local GiftPresets = {}

-- GiftPresets.Gifts = {
-- 	[1] = {
-- 		timer = GameConfig.HalfMinute,
-- 		items = {
-- 			{
-- 				itemType = Keys.ItemType.wins,
-- 				count = 100,
-- 			},
-- 		},
-- 		gradient = "Gray",
-- 	},
-- 	[2] = {
-- 		timer = GameConfig.OneMinute,
-- 		items = {
-- 			{
-- 				itemType = Keys.ItemType.ores,
-- 				name = "Iron",
-- 				count = 100,
-- 			},
-- 		},
-- 		gradient = "Green",
-- 	},
-- 	[3] = {
-- 		timer = GameConfig.OneMinute * 5,
-- 		items = {
-- 			{
-- 				itemType = Keys.ItemType.wins,
-- 				count = 300,
-- 			},
-- 		},
-- 		gradient = "Green",
-- 	},
-- 	[4] = {
-- 		timer = GameConfig.OneMinute * 10,
-- 		items = {
-- 			{
-- 				itemType = Keys.ItemType.ores,
-- 				name = "Silver",
-- 				count = 3,
-- 			},
-- 		},
-- 		gradient = "Gold",
-- 	},
-- 	[5] = {
-- 		timer = GameConfig.OneMinute * 15,
-- 		items = {
-- 			{
-- 				itemType = Keys.ItemType.ores,
-- 				name = "Gold",
-- 				count = 5,
-- 			},
-- 		},
-- 		gradient = "Blue",
-- 	},
-- 	[6] = {
-- 		timer = GameConfig.OneMinute * 20,
-- 		items = {
-- 			{
-- 				itemType = Keys.ItemType.ores,
-- 				name = "Diamond",
-- 				count = 1,
-- 			},
-- 		},
-- 		gradient = "Blue",
-- 	},
-- 	[7] = {
-- 		timer = GameConfig.OneMinute * 25,
-- 		items = {
-- 			{
-- 				itemType = Keys.ItemType.ores,
-- 				name = "Emerald",
-- 				count = 2,
-- 			},
-- 		},
-- 		gradient = "Purple",
-- 	},
-- 	[8] = {
-- 		timer = GameConfig.OneMinute * 30,
-- 		items = {
-- 			{
-- 				itemType = Keys.ItemType.ores,
-- 				name = "Lapis Lazuli",
-- 				count = 1,
-- 			},
-- 		},
-- 		gradient = "Blue",
-- 	},
-- 	[9] = {
-- 		timer = GameConfig.OneMinute * 40,
-- 		items = {
-- 			{
-- 				itemType = Keys.ItemType.ores,
-- 				name = "Obsidian",
-- 				count = 800,
-- 			},
-- 		},
-- 		gradient = "Blue",
-- 	},
-- 	[10] = {
-- 		timer = GameConfig.OneMinute * 50,
-- 		items = {
-- 			{
-- 				itemType = Keys.ItemType.ores,
-- 				name = "Crimson",
-- 				count = 3,
-- 			},
-- 		},
-- 		gradient = "Purple",
-- 	},
-- 	[11] = {
-- 		timer = GameConfig.OneMinute * 60,
-- 		items = {
-- 			{
-- 				itemType = Keys.ItemType.ores,
-- 				name = "Ancient Relic Gold",
-- 				count = 2,
-- 			},
-- 		},
-- 		gradient = "Blue",
-- 	},
-- 	[12] = {
-- 		timer = GameConfig.OneMinute * 70,
-- 		items = {
-- 			{
-- 				itemType = Keys.ItemType.ores,
-- 				name = "Void Stone",
-- 				count = 1,
-- 			},
-- 		},
-- 		gradient = "Gold",
-- 	},
-- }
GiftPresets.Gifts = {}
local OnlineGifts = require(Replicated.ExcelConfig.OnlineGifts)
for _, gift in OnlineGifts do
	gift.timer = GameConfig.OneMinute * gift.timer
	GiftPresets.Gifts[gift.index] = gift
end

return GiftPresets
