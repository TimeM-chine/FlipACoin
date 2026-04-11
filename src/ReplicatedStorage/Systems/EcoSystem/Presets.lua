local HttpService = game:GetService("HttpService")
local Replicated = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Keys = require(Replicated.configs.Keys)
local GameConfig = require(Replicated.configs.GameConfig)
local ItemType = Keys.ItemType

local EcoPresets = {}

EcoPresets.Products = {
	cardPacks = {
		cardPack1 = {
			name = "Skull Pack",
			buy1 = {
				productId = 3413787896,
				price = 79,
				count = 1,
			},
			buy2 = {
				productId = 3413788603,
				price = 349,
				count = 5,
			},
			buy3 = {
				productId = 3413788884,
				price = 599,
				count = 10,
			},
		},
		cardPack2 = {
			name = "Dark Orb Pack",
			buy1 = {
				productId = 3413789157,
				price = 199,
				count = 1,
			},
			buy2 = {
				productId = 3413789158,
				price = 899,
				count = 5,
			},
			buy3 = {
				productId = 3413790001,
				price = 1599,
				count = 10,
			},
			buy4 = {
				productId = 3413790222,
				price = 3999,
				count = 25,
			},
		},
	},
	spin = {
		spin1 = {
			productName = "Spin x1",
			productId = 2693437245,
			price = 29,
			count = 1,
		},
		spin3 = {
			productName = "Spin x3",
			productId = 2693437264,
			price = 79,
			count = 3,
		},
		spin10 = {
			productName = "Spin x10",
			productId = 2693437288,
			price = 249,
			count = 10,
		},
	},
	wins = {
		[1] = {
			productName = "Tiny Wins Pack",
			productId = 2693457711,
			price = 39,
			count = 5,
		},
		[2] = {
			productName = "Small Wins Pack",
			productId = 2693457728,
			price = 99,
			count = 25,
		},
		[3] = {
			productName = "Medium Wins Pack",
			productId = 2693457757,
			price = 299,
			count = 150,
		},
		[4] = {
			productName = "Large Wins Pack",
			productId = 2693457776,
			price = 499,
			count = 1000,
		},
	},
	skipRebirth = {
		productName = "Skip Rebirth",
		productId = 2693423536,
		price = 149,
		count = 1,
	},
	limitedPets = {
		["Aquatic Dragon"] = {
			productName = "Aquatic Dragon",
			order = 1,
			InWorkspace = true,
			productId = 2693457796,
			limit = 500,
			price = 99,
		},
		["Shout Bandit"] = {
			productName = "Shout Bandit",
			order = 2,
			InWorkspace = true,
			productId = 2693457813,
			limit = 250,
			price = 199,
		},
		["Terra Horizont"] = {
			productName = "Terra Horizont",
			InStore = true,
			InWorkspace = true,
			order = 3,
			productId = 2693457833,
			limit = 100,
			price = 299,
		},
		["Demon Agony"] = {
			productName = "Demon Agony",
			InStore = true,
			InWorkspace = true,
			order = 4,
			productId = 2693457858,
			limit = 50,
			price = 499,
		},
		["Alien Parasite"] = {
			productName = "Alien Parasite",
			InStore = true,
			InWorkspace = true,
			order = 5,
			productId = 2693457873,
			limit = 10,
			price = 799,
		},
	},
	pet = {
		["Watermelon Winner"] = {
			productName = "Watermelon Winner",
			productId = 2693433706,
			price = 349,
			count = 1,
		},
	},
	potions = {
		wins1Potion30 = {
			order = 1,
			potionName = "wins1Potion30",
			productName = "Cash Potion 30min",
			productId = 3413220957,
			price = 199,
			winsPrice = 20_000,
			count = 50,
			title = "Cash collect +100%",
			description = "Lasts 30min",
			gradientColor = "Yellow",
		},
		lucky1Potion15 = {
			order = 2,
			potionName = "lucky1Potion15",
			productName = "Luck Potion 15min",
			productId = 3413221811,
			price = 169,
			winsPrice = 16_000,
			count = 50,
			title = "Luck +75%",
			description = "Lasts 15min",
			gradientColor = "Green",
		},
		lucky2Potion15 = {
			order = 3,
			potionName = "lucky2Potion15",
			productName = "Super Luck Potion 15min",
			productId = 3413222618,
			price = 299,
			winsPrice = 40_000,
			count = 50,
			title = "Luck +200%",
			description = "Lasts 15min",
			gradientColor = "Purple",
		},
	},
	event = {
		[1] = {
			productName = "Event Egg x1",
			productId = 2693438782,
			price = 79,
			name = "FruitEgg",
			count = 12,
		},
		[2] = {
			productName = "Event Egg x200",
			productId = 2693440259,
			price = 899,
			name = "FruitEgg",
			count = 200,
		},
	},
	starterPack = {
		timeLimited = GameConfig.OneHour * 12,
		productName = "Starter Pack",
		productId = 2693453916,
		price = 99,
		items = {
			{
				itemType = ItemType.pet,
				count = 1,
				name = "Aqua Dragon",
			},
			{
				itemType = ItemType.potion,
				count = 5,
				name = "wins1Potion30",
				text = "Wins Potion",
			},
			{
				itemType = ItemType.potion,
				count = 5,
				name = "lucky1Potion30",
				text = "Lucky Potion",
			},
			{
				itemType = ItemType.potion,
				count = 5,
				name = "power1Potion30",
				text = "Power Potion",
			},
		},
	},
	strengthBoost = {
		{
			productId = 3235476107,
			boost = 2,
			price = 9,
			order = 1,
		},
		{
			productId = 3235476365,
			boost = 5,
			price = 19,
			order = 2,
		},
		{
			productId = 3235476603,
			boost = 10,
			price = 49,
			order = 3,
		},
		{
			productId = 3235476817,
			boost = 30,
			price = 99,
			order = 4,
		},
		{
			productId = 3235477058,
			boost = 50,
			price = 149,
			order = 5,
		},
		{
			productId = 3235477286,
			boost = 100,
			price = 249,
			order = 6,
		},
		{
			productId = 3235477513,
			boost = 200,
			price = 449,
			order = 7,
		},
		{
			productId = 3235477830,
			boost = 1000,
			price = 1999,
			order = 8,
		},
		{
			productId = 3235478439,
			boost = 2000,
			price = 2999,
			order = 9,
		},
		{
			productId = 3235478739,
			boost = 5000,
			price = 3999,
			order = 10,
		},
		{
			productId = 3235478933,
			boost = 10000,
			price = 5999,
			order = 11,
		},
	},
	seasonPremium = {
		productId = 3230276347,
		price = 299,
	},
	skipSeasonLevel = {
		productId = 3230284946,
		price = 39,
	},
	skipAllSeasonLevel = {
		productId = 3230285175,
		price = 349,
	},
	resetSeason = {
		productId = 3230285516,
		price = 99,
	},
	skipCraftTime = {
		productId = 3234356284,
		price = 149,
	},
	transitWeather = {
		productId = 3234356284,
		price = 29,
	},
	restock = {
		productId = 3424093701,
		price = 29,
	},
	shopCard1 = {
		productId = 3424471438,
		price = 9,
	},
	shopCard2 = {
		productId = 3424471650,
		price = 29,
	},
	upgradeTier = {
		productId = 3428130032,
		price = 49,
	},
	eventWins = {
		[1] = {
			productName = "Tiny Candy Pack",
			productId = 3446640700,
			price = 9,
			count = 100,
		},
		[2] = {
			productName = "Small Candy Pack",
			productId = 3446641009,
			price = 49,
			count = 750,
		},
		[3] = {
			productName = "Medium Candy Pack",
			productId = 3446642379,
			price = 199,
			count = 3_000,
		},
		[4] = {
			productName = "Big Candy Pack",
			productId = 3446642629,
			price = 399,
			count = 7_500,
		},
		[5] = {
			productName = "Large Candy Pack",
			productId = 3446642949,
			price = 1999,
			count = 70_000,
		},
	},
	eventChest = {
		[1] = {
			name = "Pentagram Gold Pack",
			productId = 3446643392,
			price = 199,
			count = 1,
		},
		[2] = {
			name = "Pentagram Gold Pack",
			productId = 3446643665,
			price = 799,
			count = 5,
		},
		[3] = {
			name = "Pentagram Gold Pack",
			productId = 3446643912,
			price = 1499,
			count = 10,
		},
	},
	eventWinsMultiplier = {
		[1] = {
			name = "Candy x2",
			productId = 3446644134,
			price = 79,
			multiplier = 2,
		},
		[2] = {
			name = "Candy x5",
			productId = 3446644434,
			price = 199,
			multiplier = 5,
		},
		[3] = {
			name = "Candy x10",
			productId = 3443526044,
			price = 299,
			multiplier = 10,
		},
	},
}

EcoPresets.GamePasses = {
	vip = {
		order = 1,
		gradient = "Shiny",
		title = "VIP",
		gamePassId = 1664464620,
		price = 199,
		description = "+20% forge quality!",
	},
	winsX2 = {
		order = 2,
		gradient = "Gold",
		title = "Coin X2",
		gamePassId = 1664528540,
		price = 299,
		description = "Get double coins when collecting!",
	},
	damageX2 = {
		order = 3,
		gradient = "Green",
		title = "Damage X2",
		gamePassId = 1663753943,
		price = 149,
		description = "Deal double damage.",
	},
	attackSpeedX2 = {
		order = 4,
		gradient = "Purple",
		title = "Attack Speed X2",
		gamePassId = 1664294722,
		price = 99,
		description = "Swing your weapon faster.",
	},
	digLucky = {
		hideInShop = true,
		order = 5,
		gradient = "Green",
		title = "Dig Lucky",
		gamePassId = 1663386197,
		price = 29,
		description = "Better loots when digging.",
	},
	enchantLucky = {
		hideInShop = true,
		order = 6,
		gradient = "Purple",
		title = "Enchant Lucky",
		gamePassId = 1664446641,
		price = 29,
		description = "Enchant lucky.",
	},
}

EcoPresets.GamePassEffects = {
	vip = {
		forgeQualityMult = 1.2,
		forgeQualityMax = 1.5,
	},
	winsX2 = {
		mult = 2,
	},
	damageX2 = {
		mult = 2,
	},
	attackSpeedX2 = {
		mult = 2,
	},
	digLucky = {
		rareTwoMultiplier = 2,
	},
	enchantLucky = {
		baseRollMin = 0.05,
		baseRollMax = 0.2,
		rollMinBonus = 0.2,
	},
}

local redeemCodes = {
	["Wrestling"] = {
		expireTime = 1745979374,
		rewards = {
			{
				itemType = ItemType.wins,
				count = 100,
			},
		},
	},
	["Season1"] = {
		expireTime = 1745979374,
		rewards = {
			{
				itemType = ItemType.egg,
				count = 1,
				name = "Season1Egg",
			},
		},
	},
	["Cave"] = {
		expireTime = 1745979374,
		rewards = {
			{
				itemType = ItemType.potion,
				count = 2,
				name = "power1Potion30",
			},
		},
	},
}

EcoPresets.redeemCodes = {}
for code, config in pairs(redeemCodes) do
	EcoPresets.redeemCodes[string.upper(code)] = config
end
redeemCodes = nil

return EcoPresets
