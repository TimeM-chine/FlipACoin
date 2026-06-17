local HttpService = game:GetService("HttpService")
local Replicated = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Keys = require(Replicated.configs.Keys)
local GameConfig = require(Replicated.configs.GameConfig)
local ItemType = Keys.ItemType

local EcoPresets = {}

EcoPresets.ShopCategoryAliases = table.freeze({
	coin = "coin",
	coins = "coin",
	desk = "desk",
	desks = "desk",
	desksetup = "desk",
	desksetups = "desk",
	chair = "chair",
	chairs = "chair",
	boost = "boost",
	boosts = "boost",
	robux = "boost",
})

EcoPresets.LoadoutDefaults = table.freeze({
	equippedCoin = "coin1",
	equippedDeskSetup = "1",
	equippedChair = "1",
})

EcoPresets.GrowthShopItems = {
	coin = table.freeze({
		{
			id = "coin1",
			displayName = "Copper R Coin",
			rarity = "Common",
			role = "Starter",
			cost = 0,
			stats = {
				coinMultiplier = 1,
				luckBonus = 0,
			},
		},
		{
			id = "coin2",
			displayName = "Steel R Coin",
			rarity = "Uncommon",
			role = "Luck",
			cost = 180,
			stats = {
				coinMultiplier = 1.05,
				luckBonus = 0.025,
			},
		},
		{
			id = "coin3",
			displayName = "Golden R Coin",
			rarity = "Rare",
			role = "Streak",
			cost = 520,
			stats = {
				coinMultiplier = 1.16,
				luckBonus = 0.01,
			},
		},
		{
			id = "coin4",
			displayName = "Crimson Ring Coin",
			rarity = "Epic",
			role = "Cash",
			cost = 1400,
			stats = {
				coinMultiplier = 1.35,
				luckBonus = 0.018,
			},
		},
		{
			id = "coin5",
			displayName = "Amethyst R Coin",
			rarity = "Epic",
			role = "Value",
			cost = 3200,
			stats = {
				coinMultiplier = 1.55,
				luckBonus = 0.025,
			},
		},
		{
			id = "coin6",
			displayName = "Rose Gear Coin",
			rarity = "Legendary",
			role = "Premium",
			cost = 6800,
			stats = {
				coinMultiplier = 1.82,
				luckBonus = 0.035,
			},
		},
		{
			id = "coin7",
			displayName = "Sunburst R Coin",
			rarity = "Legendary",
			role = "Perfect",
			cost = 12800,
			stats = {
				coinMultiplier = 2.15,
				luckBonus = 0.05,
				edgeStandChanceBonus = 0.005,
				perfectRewardMultiplierBonus = 0.04,
				tailsRerollChance = 0.015,
			},
		},
		{
			id = "coin8",
			displayName = "Emerald Cut Coin",
			rarity = "Mythic",
			role = "Fortune",
			cost = 24000,
			stats = {
				coinMultiplier = 2.6,
				luckBonus = 0.07,
				edgeStandChanceBonus = 0.01,
				perfectRewardMultiplierBonus = 0.07,
				tailsRerollChance = 0.025,
			},
		},
		{
			id = "coin9",
			displayName = "Sapphire Halo Coin",
			rarity = "Mythic",
			role = "Halo",
			cost = 50000,
			stats = {
				coinMultiplier = 3.2,
				luckBonus = 0.09,
				edgeStandChanceBonus = 0.015,
				perfectRewardMultiplierBonus = 0.1,
				tailsRerollChance = 0.035,
			},
		},
		{
			id = "coin10",
			displayName = "Ancient Ruby Coin",
			rarity = "Mythic",
			role = "Apex",
			cost = 90000,
			stats = {
				coinMultiplier = 3.8,
				luckBonus = 0.11,
				edgeStandChanceBonus = 0.02,
				perfectRewardMultiplierBonus = 0.14,
				tailsRerollChance = 0.05,
			},
		},
	}),
	desk = table.freeze({
		{
			id = "1",
			displayName = "Tall Candle",
			rarity = "Common",
			role = "Starter",
			cost = 0,
			stats = {
				coinMultiplier = 1,
				luckBonus = 0,
			},
		},
		{
			id = "2",
			displayName = "Barrel Stein",
			rarity = "Uncommon",
			role = "Steady",
			cost = 260,
			stats = {
				coinMultiplier = 1.08,
				luckBonus = 0.008,
			},
		},
		{
			id = "3",
			displayName = "Balance Scale",
			rarity = "Rare",
			role = "Fast Cash",
			cost = 760,
			stats = {
				coinMultiplier = 1.18,
				luckBonus = 0.012,
			},
		},
		{
			id = "4",
			displayName = "Quill Pot",
			rarity = "Epic",
			role = "Premium",
			cost = 1800,
			stats = {
				coinMultiplier = 1.30,
				luckBonus = 0.02,
			},
		},
		{
			id = "5",
			displayName = "Cosmic Globe",
			rarity = "Epic",
			role = "Fortune",
			cost = 4200,
			stats = {
				coinMultiplier = 1.42,
				luckBonus = 0.026,
			},
		},
		{
			id = "6",
			displayName = "Miner Trophy",
			rarity = "Legendary",
			role = "Perfect",
			cost = 8600,
			stats = {
				coinMultiplier = 1.56,
				luckBonus = 0.034,
			},
		},
		{
			id = "7",
			displayName = "Crimson Hourglass",
			rarity = "Legendary",
			role = "Momentum",
			cost = 15600,
			stats = {
				coinMultiplier = 1.72,
				luckBonus = 0.044,
			},
		},
		{
			id = "8",
			displayName = "Amethyst Hourglass",
			rarity = "Mythic",
			role = "Apex",
			cost = 30000,
			stats = {
				coinMultiplier = 1.90,
				luckBonus = 0.058,
			},
		},
	}),
	chair = table.freeze({
		{
			id = "1",
			displayName = "Round Stool",
			rarity = "Common",
			role = "Starter",
			cost = 0,
			stats = {
				coinMultiplier = 1,
				luckBonus = 0,
			},
		},
		{
			id = "2",
			displayName = "Wooden Dining Chair",
			rarity = "Common",
			role = "Comfort",
			cost = 420,
			stats = {
				coinMultiplier = 1.04,
				luckBonus = 0.004,
			},
		},
		{
			id = "3",
			displayName = "Folding Chair",
			rarity = "Uncommon",
			role = "Steady",
			cost = 900,
			stats = {
				coinMultiplier = 1.08,
				luckBonus = 0.008,
			},
		},
		{
			id = "4",
			displayName = "Glass Cube Chair",
			rarity = "Uncommon",
			role = "Focus",
			cost = 1800,
			stats = {
				coinMultiplier = 1.12,
				luckBonus = 0.012,
			},
		},
		{
			id = "5",
			displayName = "Blue Club Chair",
			rarity = "Rare",
			role = "Boost",
			cost = 3600,
			stats = {
				coinMultiplier = 1.16,
				luckBonus = 0.016,
			},
		},
		{
			id = "6",
			displayName = "Pink Scallop Chair",
			rarity = "Rare",
			role = "Value",
			cost = 6800,
			stats = {
				coinMultiplier = 1.20,
				luckBonus = 0.020,
			},
		},
		{
			id = "7",
			displayName = "Crown Stick Throne",
			rarity = "Epic",
			role = "Lucky",
			cost = 11000,
			stats = {
				coinMultiplier = 1.25,
				luckBonus = 0.025,
			},
		},
		{
			id = "8",
			displayName = "Heart Vanity Chair",
			rarity = "Epic",
			role = "Fortune",
			cost = 17000,
			stats = {
				coinMultiplier = 1.30,
				luckBonus = 0.030,
			},
		},
		{
			id = "9",
			displayName = "Creature Armchair",
			rarity = "Legendary",
			role = "Premium",
			cost = 26000,
			stats = {
				coinMultiplier = 1.36,
				luckBonus = 0.036,
			},
		},
		{
			id = "10",
			displayName = "Gothic Web Chair",
			rarity = "Legendary",
			role = "Perfect",
			cost = 38000,
			stats = {
				coinMultiplier = 1.43,
				luckBonus = 0.043,
			},
		},
		{
			id = "11",
			displayName = "Royal Chaise",
			rarity = "Mythic",
			role = "Apex",
			cost = 55000,
			stats = {
				coinMultiplier = 1.50,
				luckBonus = 0.050,
			},
		},
	}),
}

EcoPresets.Products = {
	flipACoin = {
		cashPackSmall = {
			order = 1,
			productName = "Cash Pouch",
			productId = 3596711650,
			price = 29,
			grantType = "cash",
			count = 2_500,
			description = "2,500 Cash",
		},
		cashPackMedium = {
			order = 2,
			productName = "Cash Stack",
			productId = 3596711733,
			price = 99,
			grantType = "cash",
			count = 15_000,
			description = "15,000 Cash",
		},
		cashPackLarge = {
			order = 3,
			productName = "Cash Vault",
			productId = 3596711820,
			price = 399,
			grantType = "cash",
			count = 80_000,
			description = "80,000 Cash",
		},
		rebirthShardSmall = {
			order = 4,
			productName = "Rebirth Points x10",
			productId = 3596711879,
			price = 99,
			grantType = "rebirthPoints",
			count = 10,
			description = "10 Rebirth Points",
		},
		rebirthShardLarge = {
			order = 5,
			productName = "Rebirth Points x60",
			productId = 3596711948,
			price = 399,
			grantType = "rebirthPoints",
			count = 60,
			description = "60 Rebirth Points",
		},
		apexLoadoutBundle = {
			order = 6,
			productName = "Apex Loadout Bundle",
			productId = 3596712138,
			price = 599,
			grantType = "loadoutBundle",
			description = "Unlock Ancient Ruby Coin, Amethyst Hourglass, and Royal Chaise",
			fallbackCash = 25_000,
			unlocks = {
				coin = { "coin10" },
				desk = { "8" },
				chair = { "11" },
			},
		},
		paidCash2x10m = {
			order = 7,
			productName = "2x Cash Boost 10m",
			productId = 3601874164,
			price = 99,
			grantType = "potion",
			potionName = "paidCash2x10m",
			description = "Use instantly for 2x Cash during the next 10 minutes",
		},
	},
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
		paidCash2x10m = {
			order = 1,
			potionName = "paidCash2x10m",
			productName = "2x Cash Boost 10m",
			price = 99,
			winsPrice = 20_000,
			count = 1,
			title = "2x Cash",
			description = "Lasts 10min",
			gradientColor = "Yellow",
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
				count = 1,
				name = "paidCash2x10m",
				text = "2x Cash Potion",
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
		gamePassId = 1854149220,
		price = 199,
		description = "+10% Cash, +1% Luck, and VIP loadout unlocks",
	},
	winsX2 = {
		order = 2,
		gradient = "Gold",
		title = "2x Cash",
		gamePassId = 1852463340,
		price = 299,
		description = "Double Cash from flip rewards",
	},
	luckyCharm = {
		order = 3,
		gradient = "Green",
		title = "Lucky Charm",
		gamePassId = 1852733314,
		price = 149,
		description = "+4% Heads chance",
	},
	quickFlip = {
		order = 4,
		gradient = "Purple",
		title = "Quick Flip",
		gamePassId = 1853909293,
		price = 99,
		description = "Flip 15% faster",
	},
}

EcoPresets.GamePassEffects = {
	vip = {
		coinMultiplier = 1.1,
		luckBonus = 0.01,
		unlocks = {
			coin = { "coin6" },
			desk = { "3" },
			chair = { "7" },
		},
	},
	winsX2 = {
		coinMultiplier = 2,
	},
	luckyCharm = {
		luckBonus = 0.04,
	},
	quickFlip = {
		flipIntervalMultiplier = 0.85,
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
				count = 1,
				name = "paidCash2x10m",
			},
		},
	},
}

EcoPresets.redeemCodes = {}
for code, config in pairs(redeemCodes) do
	EcoPresets.redeemCodes[string.upper(code)] = config
end
redeemCodes = nil

function EcoPresets.ResolveShopCategory(category)
	if typeof(category) ~= "string" then
		return nil
	end

	return EcoPresets.ShopCategoryAliases[string.lower(category)]
end

function EcoPresets.GetShopItem(category, itemId)
	local resolvedCategory = EcoPresets.ResolveShopCategory(category)
	if not resolvedCategory or typeof(itemId) ~= "string" then
		return nil
	end

	local categoryItems = EcoPresets.GrowthShopItems[resolvedCategory]
	if not categoryItems then
		return nil
	end

	for _, item in ipairs(categoryItems) do
		if item.id == itemId then
			return item
		end
	end

	return nil
end

function EcoPresets.GetShopItemDisplayName(category, itemId)
	local item = EcoPresets.GetShopItem(category, itemId)
	return (item and item.displayName) or itemId
end

function EcoPresets.BuildLoadoutBonuses(equippedCoin, equippedDeskSetup, equippedChair, gamePasses)
	local bonuses = {
		coinMultiplier = 1,
		premiumCoinMultiplier = 1,
		luckBonus = 0,
		edgeStandChanceBonus = 0,
		perfectRewardMultiplierBonus = 0,
		tailsRerollChance = 0,
		flipIntervalMultiplier = 1,
	}
	local equippedItems = {
		EcoPresets.GetShopItem("coin", equippedCoin),
		EcoPresets.GetShopItem("desk", equippedDeskSetup),
		EcoPresets.GetShopItem("chair", equippedChair),
	}

	for _, item in ipairs(equippedItems) do
		if item and item.stats then
			bonuses.coinMultiplier *= item.stats.coinMultiplier or 1
			bonuses.luckBonus += item.stats.luckBonus or 0
			bonuses.edgeStandChanceBonus += item.stats.edgeStandChanceBonus or 0
			bonuses.perfectRewardMultiplierBonus += item.stats.perfectRewardMultiplierBonus or 0
			bonuses.tailsRerollChance += item.stats.tailsRerollChance or 0
		end
	end

	if typeof(gamePasses) == "table" then
		for gamePassName, isOwned in pairs(gamePasses) do
			local effect = isOwned and EcoPresets.GamePassEffects[gamePassName]
			if effect then
				bonuses.coinMultiplier *= effect.coinMultiplier or 1
				bonuses.premiumCoinMultiplier *= effect.coinMultiplier or 1
				bonuses.luckBonus += effect.luckBonus or 0
				bonuses.flipIntervalMultiplier *= effect.flipIntervalMultiplier or 1
			end
		end
	end

	return bonuses
end

return EcoPresets
