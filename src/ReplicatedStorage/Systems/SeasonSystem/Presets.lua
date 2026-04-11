local Replicated = game:GetService("ReplicatedStorage")

local Keys = require(Replicated.configs.Keys)


local SeasonPresets = {}

SeasonPresets.SeasonNum = 1.1
SeasonPresets.startTime = os.time{year=2025, month=03, day=03, hour=02, min=0, sec=0}
SeasonPresets.endTime = os.time{year=2025, month=04, day=03, hour=0, min=0, sec=0}

SeasonPresets.DailyQuests = {
	{
		questType =  Keys.QuestType.hatchEgg,
		title = "Eggs Hatcher",
		target = 150,
		description = "Hatch 150 eggs",
		exp = 150
	},
	{
		questType = Keys.QuestType.defeatAnyBoss,
		title = "Pro Winner",
		target = 50,
		description = "Win battle 50 times",
		exp = 250
	},
	{
		questType = Keys.QuestType.hatchRarityPet,
		rarity = "Legendary",
		title = "Legendary Hatcher",
		target = 25,
		description = "Hatch 25 Legendary Pets",
		exp = 300
	},
}

SeasonPresets.WeeklyQuests = {
	{
		questType = Keys.QuestType.hatchEgg,
		title = "Eggs Hatcher",
		target = 6000,
		description = `Hatch 6000 eggs`,
		exp = 1300
	},
	{
		questType = Keys.QuestType.hatchRarityPet,
		rarity = "Epic",
		title = "Epic Hatcher",
		target = 750,
		description = "Hatch 750 Epic Pets",
		exp = 1700
	},
	{
		questType = Keys.QuestType.rebirth,
		title = "Rebirth",
		target = 10,
		description = "Rebirth 10 time",
		exp = 2000
	},
}

SeasonPresets.Pass = {
	-- level1
	{
		exp = 100,
		Free = {
			text = "x1",
			title = "Damage 30m",
			tier = "Gray",
			itemType = Keys.ItemType.potion,
			itemName = "power1Potion30",
			count = 1
		},
		Premium = {
			text = "x1",
			title = "Season Egg",
			tier = "Gold",
			itemType = Keys.ItemType.egg,
			itemName = "Season1Egg",
			count = 1
		},
	},
	-- level2
	{
		exp = 225,
		Free = {
			text = "x1",
			title = "Wins Potion",
			tier = "Gray",
			itemType = Keys.ItemType.potion,
			itemName = "wins1Potion30",
			count = 1
		},
		Premium = {
			text = "x2",
			title = "Wins Potion",
			tier = "Gold",
			itemType = Keys.ItemType.potion,
			itemName = "wins1Potion30",
			count = 2
		},
	},
	-- level3
	{
		exp = 295,
		Free = {
			text = "",
			title = "Season Egg",
			tier = "Blue",
			itemType = Keys.ItemType.egg,
			itemName = "Season1Egg",
			count = 1
		},
		Premium = {
			text = "x3",
			title = "Season Egg",
			tier = "Gold",
			itemType = Keys.ItemType.egg,
			itemName = "Season1Egg",
			count = 3
		}
	},
	-- level4
	{
		exp = 350,
		Free = {
			text = "x2",
			title = "Gems",
			tier = "Gold",
			itemType = Keys.ItemType.spin,
			count = 2
		},
		Premium = {
			text = "x4",
			title = "Luck Potion",
			tier = "Gold",
			itemType = Keys.ItemType.potion,
			itemName = "lucky1Potion30",
			count = 4
		},
	},
	-- level5
	{
		exp = 410,
		Free = {
			text = "x3",
			title = "Luck Potion",
			tier = "Gray",
			itemType = Keys.ItemType.potion,
			itemName = "lucky1Potion30",
			count = 3
		},
		Premium = {
			text = "x3",
			title = "Season Egg",
			tier = "Blue",
			itemType = Keys.ItemType.egg,
			itemName = "Season1Egg",
			hatchType = "Triple",
			count = 3
		},
	},
	-- level6
	{
		exp = 500,
		Free = {
			text = "x3",
			title = "Spin",
			tier = "Gold",
			itemType = Keys.ItemType.spin,
			count = 3
		},
		Premium = {
			text = "x3",
			title = "Season Egg",
			tier = "Gray",
			itemType = Keys.ItemType.egg,
			itemName = "Season1Egg",
			count = 3
		},
	},
	-- level7
	{
		exp = 620,
		Free = {
			text = "",
			title = "Season Egg",
			tier = "Gray",
			itemType = Keys.ItemType.egg,
			itemName = "Season1Egg",
			count = 1
		},
		Premium = {
			text = "x3",
			title = "Season Egg",
			tier = "Gold",
			itemType = Keys.ItemType.egg,
			itemName = "Season1Egg",
			count = 3
		},
	},
	-- level8
	{
		exp = 750,
		Free = {
			text = "x30M",
			title = "Wins",
			tier = "Gray",
			itemType = Keys.ItemType.wins,
			count = 30_000_000
		},
		Premium = {
			text = "x3",
			title = "Season Egg",
			tier = "Blue",
			itemType = Keys.ItemType.egg,
			itemName = "Season1Egg",
			count = 3
		},
	},
	-- level9
	{
		exp = 850,
		Free = {
			text = "x50M",
			title = "Wins",
			tier = "Gray",
			itemType = Keys.ItemType.wins,
			count = 50_000_000
		},
		Premium = {
			text = "x3",
			title = "Season Egg",
			tier = "Gold",
			itemType = Keys.ItemType.egg,
			itemName = "Season1Egg",
			count = 3
		},
	},
	-- level10
	{
		exp = 1000,
		Free = {
			text = "x1",
			title = "Luck Potion",
			tier = "Blue",
			itemType = Keys.ItemType.potion,
			itemName = "lucky1Potion30",
			count = 1
		},
		Premium = {
			text = "x2",
			title = "Luck Potion",
			tier = "Blue",
			itemType = Keys.ItemType.potion,
			itemName = "lucky1Potion30",
			count = 2
		},
	},

	-- level11
	{
		exp = 1300,
		Free = {
			text = "x3",
			title = "Season Egg",
			tier = "Gold",
			itemType = Keys.ItemType.egg,
			itemName = "Season1Egg",
			count = 3
		},
		Premium = {
			text = "x20",
			title = "Spin",
			tier = "Blue",
			itemType = Keys.ItemType.spin,
			count = 20
		},
	},

	-- level12
	{
		exp = 1600,
		Free = {
			text = "x2",
			title = "Power Potion",
			tier = "Gold",
			itemType = Keys.ItemType.potion,
			itemName = "power1Potion30",
			count = 2
		},
		Premium = {
			text = "x4",
			title = "Power Potion",
			tier = "Gold",
			itemType = Keys.ItemType.potion,
			itemName = "power1Potion30",
			count = 4
		},
	},
	-- level13
	{
		exp = 2000,
		Free = {
			text = "x3",
			title = "Season Egg",
			tier = "Gray",
			itemType = Keys.ItemType.egg,
			itemName = "Season1Egg",
			count = 3
		},
		Premium = {
			text = "x3",
			title = "Season Egg",
			tier = "Gold",
			itemType = Keys.ItemType.egg,
			itemName = "Season1Egg",
			count = 3
		},
	},
	-- level14
	{
		exp = 2400,
		Free = {
			text = "x50",
			title = "Spin",
			tier = "Blue",
			itemType = Keys.ItemType.spin,
			count = 50
		},
		Premium = {
			text = "x3",
			title = "Season Egg",
			tier = "Gray",
			itemType = Keys.ItemType.egg,
			itemName = "Season1Egg",
			count = 3
		},
	},
	-- level15
	{
		exp = 3000,
		Free = {
			text = "x2",
			title = "Wins Potion",
			tier = "Gold",
			itemType = Keys.ItemType.potion,
			itemName = "wins1Potion30",
			count = 2
		},
		Premium = {
			text = "x3",
			title = "Season Egg",
			tier = "Gold",
			itemType = Keys.ItemType.egg,
			itemName = "Season1Egg",
			count = 3
		},
	},
	-- level16
	{
		exp = 3200,
		Free = {
			text = "x250M",
			title = "Wins",
			tier = "Blue",
			itemType = Keys.ItemType.wins,
			count = 250_000_000
		},
		Premium = {
			text = "x3",
			title = "Season Egg",
			tier = "Gray",
			itemType = Keys.ItemType.egg,
			itemName = "Season1Egg",
			count = 3
		},
	},
	-- level17
	{
		exp =3500,
		Free = {
			text = "x3",
			title = "Season Egg",
			tier = "Gray",
			itemType = Keys.ItemType.egg,
			itemName = "Season1Egg",
			count = 3

		},
		Premium = {
			text = "x100",
			title = "Spin",
			tier = "Gold",
			itemType = Keys.ItemType.spin,
			count = 100
		},
	},
	-- level18
	{
		exp = 3900,
		Free = {
			text = "x3",
			title = "Season Egg",
			tier = "Gray",
			itemType = Keys.ItemType.egg,
			itemName = "Season1Egg",
			count = 3
		},
		Premium = {
			text = "x8",
			title = "Season Egg",
			tier = "Gray",
			itemType = Keys.ItemType.egg,
			itemName = "Season1Egg",
			count = 8
		},
	},
	-- level19
	{
		exp = 4100,
		Free = {
			text = "x3",
			title = "Wins Potion",
			tier = "Gold",
			itemType = Keys.ItemType.potion,
			itemName = "wins1Potion30",
			count = 3
		},
		Premium = {
			text = "x5",
			title = "Wins Potion",
			tier = "Gold",
			itemType = Keys.ItemType.potion,
			itemName = "wins1Potion30",
			count = 5
		},
	},
	-- level20
	{
		exp = 5000,
		Free = {
			text = "",
			title = "The Prophecy",
			tier = "Blue",
			itemType = Keys.ItemType.pet,
			itemName = "The Prophecy",
			count = 1
		},
		Premium = {
			text = "",
			title = "The Bolter",
			tier = "Gold",
			itemType = Keys.ItemType.pet,
			itemName = "The Bolter",
			count = 1
		},
	},
}

return SeasonPresets