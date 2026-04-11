local Replicated = game:GetService("ReplicatedStorage")
local GameConfig = require(Replicated.configs.GameConfig)
local Keys = require(Replicated.configs.Keys)
local CardPresets = require(Replicated.Systems.CardSystem.Presets)

local EventPresets = {}

EventPresets.EventId = "2025Christmas"

EventPresets.ChestPrice = 500

EventPresets.CardPack1 = "Pentagram Black Pack"
EventPresets.CardPack2 = "Pentagram Gold Pack"

EventPresets.CandyShop = {
	[1] = {
		name = "Cash Potion",
		price = 100,
		item = {
			itemType = Keys.ItemType.potion,
			name = "wins1Potion30",
			count = 1,
		},
	},
	[2] = {
		name = "Luck Potion",
		price = 100,
		item = {
			itemType = Keys.ItemType.potion,
			name = "lucky1Potion15",
			count = 1,
		},
	},
	[3] = {
		name = "Big Luck Potion",
		price = 200,
		item = {
			itemType = Keys.ItemType.potion,
			name = "lucky2Potion15",
			count = 1,
		},
	},
	[4] = {
		name = "Pentagram Gold Pack",
		price = 150_000,
		item = {
			itemType = Keys.ItemType.cardPacks,
			name = "Pentagram Gold Pack",
			count = 1,
		},
	},
}

-- Santa相关配置
EventPresets.SantaArrivalInterval = GameConfig.OneMinute * 5
EventPresets.SantaStayDuration = GameConfig.OneMinute
EventPresets.SantaArrivalCandyMin = 10
EventPresets.SantaArrivalCandyMax = 20
EventPresets.SantaInteractionCandyMin = 1
EventPresets.SantaInteractionCandyMax = 5
EventPresets.SantaLaughChance = 0.1

return EventPresets
