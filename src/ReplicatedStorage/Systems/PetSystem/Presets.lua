local Replicated = game:GetService("ReplicatedStorage")

local GameConfig = require(Replicated.configs.GameConfig)
local Keys = require(Replicated.configs.Keys)
local Textures = require(Replicated.configs.Textures)
local assetsPath = script.Parent.Assets

local PetPresets = {}

PetPresets.Shiny = {
	craftTime = GameConfig.OneHour * 5,
	maxSlots = 5,
}

PetPresets.Order = {
	Common = -1,
	Uncommon = -2,
	Rare = -3,
	Epic = -4,
	Legendary = -5,
	Mythic = -6,
	Omega = -7,
}

PetPresets.EggsList = {
	-- shop
	["shop egg 1"] = {
		displayName = "Elemental Egg",
		display = false,
		pets = {
			-- {
			-- 	name = "Solar Element Abus",
			-- 	weight = 38.46,
			-- 	rarity = "Epic",
			-- 	power = 28.6,
			-- },
			-- {
			-- 	name = "Aquatic Elemental Lugg",
			-- 	weight = 26.92,
			-- 	rarity = "Legendary",
			-- 	power = 84.4,
			-- },
			{
				name = "Iceblaster Element",
				weight = 42.01,
				rarity = "Legendary",
				power = 30,
			},
			{
				name = "DarkMatter Elemental Wolf",
				weight = 37.51,
				rarity = "Mythic",
				power = 80,
			},
			{
				name = "Nuclear Elemental Legend",
				weight = 20.15,
				rarity = "Omega",
				power = 150,
			},
			{
				name = "Fire Elemental Abysmal",
				weight = 0.33,
				rarity = "Omega",
				power = 350,
			},
		},
	},
	["shop egg 2"] = {
		displayName = "Dragon Egg",
		display = false,
		pets = {
			{
				name = "Aqua Dragon",
				weight = 49.75,
				rarity = "Epic",
				power = 100,
			},
			{
				name = "Neon Dragon",
				weight = 29.85,
				rarity = "Epic",
				power = 200,
			},
			{
				name = "Void Dragon",
				weight = 14.93,
				rarity = "Legendary",
				power = 350,
			},
			{
				name = "Element Dragon",
				weight = 4.98,
				rarity = "Mythic",
				power = 500,
			},
			-- {
			-- 	name = "Nezuko",
			-- 	weight = 0.5,
			-- 	rarity = "Omega",
			-- 	power = 500,
			-- },
		},
	},

	Season1Egg = {
		pets = {
			{
				name = "The Black Dog",
				weight = 75,
				rarity = "Common",
				power = 10,
			},
			{
				name = "The Albatross",
				weight = 24,
				rarity = "Uncommon",
				power = 25,
			},
			{
				name = "The Tortured Poet",
				weight = 1,
				rarity = "Epic",
				power = 50,
			},
			{
				name = "The Prophecy",
				weight = 0,
				rarity = "Legendary",
				power = 80,
			},
			{
				name = "The Bolter",
				weight = 0,
				rarity = "Mythic",
				power = 100,
			},
		},
	},

	-- event
	-- ["Event Egg"] = {
	-- 	display = false,
	-- 	cost = 1,
	-- 	costType = Keys.ItemType.eventEgg,
	-- 	pets = {
	-- 		{
	-- 			name = "Angel Crystal",
	-- 			weight = 62.95,
	-- 			rarity = "Epic",
	-- 			power = 700,
	-- 		},
	-- 		{
	-- 			name = "Angel Calcite",
	-- 			weight = 37,
	-- 			rarity = "Legendary",
	-- 			power = 3000,
	-- 		},
	-- 		{
	-- 			name = "Angel Star",
	-- 			weight = 1,
	-- 			rarity = "Mythic",
	-- 			power = 5000,
	-- 		},
	-- 		{
	-- 			name = "Angel Heart",
	-- 			weight = 0.05,
	-- 			rarity = "Omega",
	-- 			power = 7500,
	-- 		},
	-- 	},
	-- },

	-- -- 2024 Event
	-- ["Event2 Egg"] = {
	-- 	display = false,
	-- 	cost = 1,
	-- 	costType = Keys.ItemType.eventEgg,
	-- 	pets = {
	-- 		{
	-- 			name = "Starlight",
	-- 			weight = 62.95,
	-- 			rarity = "Epic",
	-- 			power = 700,
	-- 		},
	-- 		{
	-- 			name = "Midnight",
	-- 			weight = 37,
	-- 			rarity = "Legendary",
	-- 			power = 3000,
	-- 		},
	-- 		{
	-- 			name = "Amythest Dragon",
	-- 			weight = 1,
	-- 			rarity = "Mythic",
	-- 			power = 5000,
	-- 		},
	-- 		{
	-- 			name = "Angel",
	-- 			weight = 0.05,
	-- 			rarity = "Omega",
	-- 			power = 7500,
	-- 		},
	-- 	},
	-- },

	FruitEgg = {
		cost = 1,
		itemType = Keys.ItemType.eventEgg,
		display = false,
		pets = {
			-- {
			-- 	name = "Strawberry Dog",
			-- 	weight = 50,
			-- 	rarity = "Rare",
			-- 	power = 25
			-- },
			-- {
			-- 	name = "Apple Lizard",
			-- 	weight = 20,
			-- 	rarity = "Epic",
			-- 	power = 30
			-- },
			{
				name = "Banana Skewnet",
				weight = 42.01,
				rarity = "Epic",
				power = 32,
			},
			{
				name = "Strawberry",
				weight = 37.51,
				rarity = "Legendary",
				power = 40,
			},
			{
				name = "Banana Yatagarasu",
				weight = 20.15,
				rarity = "Mythic",
				power = 50,
			},
			{
				name = "Banana Lord",
				weight = 0.33,
				rarity = "Omega",
				power = 60,
			},
		},
	},

	-- zone1
	Zone1Egg1 = {
		displayName = "Wisteria Egg",
		cost = 5,
		costType = Keys.ItemType.wins,
		pets = {
			{
				name = "Cat",
				weight = 58,
				rarity = "Common",
				power = 1.4,
			},
			{
				name = "Dog",
				weight = 29,
				rarity = "Common",
				power = 1.9,
			},
			{
				name = "Chick",
				weight = 12,
				rarity = "Uncommon",
				power = 2.1,
			},
			{
				name = "Bat",
				weight = 1,
				rarity = "Epic",
				power = 3.4,
			},
		},
	},
	Zone1Egg2 = {
		displayName = "Pink Yeti Egg",
		cost = 25,
		costType = Keys.ItemType.wins,
		pets = {
			{
				name = "Cow",
				weight = 31,
				rarity = "Common",
				power = 1.9,
			},
			{
				name = "Rabbit",
				weight = 30,
				rarity = "Uncommon",
				power = 2.35,
			},
			{
				name = "Tiger",
				weight = 23,
				rarity = "Rare",
				power = 2.6,
			},
			{
				name = "Monkey",
				weight = 12,
				rarity = "Epic",
				power = 2.7,
			},
			{
				name = "Unicorn",
				weight = 4,
				rarity = "Epic",
				power = 2.8,
			},
		},
	},
	Zone1Egg3 = {
		displayName = "Lava Egg",
		cost = 125,
		costType = Keys.ItemType.wins,
		pets = {
			{
				name = "Raccoon",
				weight = 50,
				rarity = "Uncommon",
				power = 2.6,
			},
			{
				name = "Bear",
				weight = 30,
				rarity = "Epic",
				power = 3.1,
			},
			{
				name = "Fox",
				weight = 15,
				rarity = "Epic",
				power = 4,
			},
			{
				name = "Clover Monster",
				weight = 5,
				rarity = "Legendary",
				power = 5.9,
			},
		},
	},
	Zone1Egg4 = {
		displayName = "Healing Egg",
		cost = 700,
		costType = Keys.ItemType.wins,
		pets = {
			{
				name = "Slime",
				weight = 54,
				rarity = "Epic",
				power = 3.5,
			},
			{
				name = "Snow Man",
				weight = 27,
				rarity = "Legendary",
				power = 7.5,
			},
			{
				name = "Pink Yeti",
				weight = 16,
				rarity = "Mythic",
				power = 9.5,
			},
			{
				name = "Phoenix",
				weight = 3,
				rarity = "Omega",
				power = 12,
			},
		},
	},

	-- zone2
	Zone2Egg1 = {
		displayName = "Rainbow Egg",
		cost = 7500,
		costType = Keys.ItemType.wins,
		pets = {
			{
				name = "Sheep",
				weight = 53,
				rarity = "Rare",
				power = 8.6,
			},
			{
				name = "Piggy",
				weight = 31,
				rarity = "Rare",
				power = 9.6,
			},
			{
				name = "Chicken",
				weight = 10,
				rarity = "Legendary",
				power = 12.8,
			},
			{
				name = "Siberian Husky",
				weight = 5,
				rarity = "Legendary",
				power = 18.2,
			},
			{
				name = "Peacock",
				weight = 1,
				rarity = "Mythic",
				power = 31,
			},
		},
	},
	Zone2Egg2 = {
		displayName = "Devil Fruit Egg",
		cost = 22500,
		costType = Keys.ItemType.wins,
		pets = {
			{
				name = "White Devil",
				weight = 65,
				rarity = "Epic",
				power = 24.6,
			},
			{
				name = "Gold Devil",
				weight = 26,
				rarity = "Legendary",
				power = 32.8,
			},
			{
				name = "Spider Devil",
				weight = 10,
				rarity = "Mythic",
				power = 38.6,
			},
			{
				name = "Dracula Devil",
				weight = 1,
				rarity = "Omega",
				power = 44.8,
			},
		},
	},
	Zone2Egg3 = {
		displayName = "Lucifer Egg",
		cost = 75000,
		costType = Keys.ItemType.wins,
		pets = {
			{
				name = "Heteroon",
				weight = 53,
				rarity = "Epic",
				power = 54.8,
			},
			{
				name = "Monitor",
				weight = 26,
				rarity = "Legendary",
				power = 62.2,
			},
			{
				name = "Cyber Cat",
				weight = 16,
				rarity = "Mythic",
				power = 84.2,
			},
			{
				name = "Mad Scientist",
				weight = 5,
				rarity = "Omega",
				power = 119.6,
			},
		},
	},
	Zone2Egg4 = {
		displayName = "Sun Egg",
		cost = 225000,
		costType = Keys.ItemType.wins,
		pets = {
			{
				name = "White Ghost",
				weight = 63,
				rarity = "Legendary",
				power = 94.2,
			},
			{
				name = "Vampire Ghost",
				weight = 31,
				rarity = "Mythic",
				power = 109.4,
			},
			{
				name = "Death Ghost",
				weight = 6,
				rarity = "Omega",
				power = 129.8,
			},
		},
	},
	Zone2Egg5 = {
		displayName = "Neo Egg",
		cost = 650000,
		costType = Keys.ItemType.wins,
		pets = {
			{
				name = "Undead Tiger",
				weight = 63,
				rarity = "Epic",
				power = 115.8,
			},
			{
				name = "Undead Goat",
				weight = 31,
				rarity = "Legendary",
				power = 123.4,
			},
			{
				name = "Undead Bull",
				weight = 6,
				rarity = "Mythic",
				power = 137.2,
			},
		},
	},
	Zone2Egg6 = {
		displayName = "Space Egg",
		cost = 2000000,
		costType = Keys.ItemType.wins,
		pets = {
			{
				name = "Thunder Fox",
				weight = 62,
				rarity = "Epic",
				power = 127.8,
			},
			{
				name = "Lightning Fox",
				weight = 31,
				rarity = "Legendary",
				power = 149.4,
			},
			{
				name = "Thunder Demon",
				weight = 6,
				rarity = "Mythic",
				power = 163.2,
			},
			{
				name = "Lightning Crazy",
				weight = 1,
				rarity = "Omega",
				power = 211,
			},
		},
	},

	-- zone3
	Zone3Egg1 = {
		displayName = "Christmas Tree Egg",
		cost = 5000000,
		costType = Keys.ItemType.wins,
		pets = {
			{
				name = "Golden Naiad",
				weight = 49,
				rarity = "Rare",
				power = 134.4,
			},
			{
				name = "Angelic Naiad",
				weight = 28.9,
				rarity = "Epic",
				power = 151.6,
			},
			{
				name = "Water Fairy",
				weight = 15,
				rarity = "Legendary",
				power = 173.6,
			},
			{
				name = "Heavenly Phoenix",
				weight = 7,
				rarity = "Mythic",
				power = 216.6,
			},
			{
				name = "Lapis Lazuli",
				weight = 0.1,
				rarity = "Omega",
				power = 297,
			},
		},
	},
	Zone3Egg2 = {
		displayName = "Astronaut Egg",
		cost = 25000000,
		costType = Keys.ItemType.wins,
		pets = {
			{
				name = "Bat Demon",
				weight = 49,
				rarity = "Rare",
				power = 156.6,
			},
			{
				name = "Butterfly Demon",
				weight = 27.9,
				rarity = "Epic",
				power = 176.8,
			},
			{
				name = "Demon Elf",
				weight = 18,
				rarity = "Legendary",
				power = 197.8,
			},
			{
				name = "Moon Demon",
				weight = 5,
				rarity = "Mythic",
				power = 224.6,
			},
			{
				name = "Demon King",
				weight = 0.1,
				rarity = "Omega",
				power = 348.6,
			},
		},
	},
	Zone3Egg3 = {
		displayName = "Justice Egg",
		cost = 125000000,
		costType = Keys.ItemType.wins,
		pets = {
			{
				name = "Red Demon",
				weight = 59,
				rarity = "Epic",
				power = 221.6,
			},
			{
				name = "Neo",
				weight = 28.9,
				rarity = "Legendary",
				power = 227,
			},
			{
				name = "Green And Bluea",
				weight = 12,
				rarity = "Mythic",
				power = 247.8,
			},
			{
				name = "Holy Owl",
				weight = 0.1,
				rarity = "Omega",
				power = 385,
			},
		},
	},
	Zone3Egg4 = {
		displayName = "Reindeer Egg",
		cost = 625000000,
		costType = Keys.ItemType.wins,
		pets = {
			{
				name = "Pink Pada",
				weight = 55,
				rarity = "Epic",
				power = 287.4,
			},
			{
				name = "Blue Pada",
				weight = 33.9,
				rarity = "Legendary",
				power = 336.6,
			},
			{
				name = "Pada Queen",
				weight = 11,
				rarity = "Mythic",
				power = 487,
			},
			{
				name = "Pada Empire",
				weight = 0.1,
				rarity = "Omega",
				power = 684.8,
			},
		},
	},
	Zone3Egg5 = {
		displayName = "Sichuan Opera Egg",
		cost = 3000000000,
		costType = Keys.ItemType.wins,
		pets = {
			{
				name = "Gold Polyhedron",
				weight = 78,
				rarity = "Legendary",
				power = 541,
			},
			{
				name = "Dark Polyhedron",
				weight = 21.9,
				rarity = "Mythic",
				power = 621.4,
			},
			{
				name = "End Theme",
				weight = 0.1,
				rarity = "Omega",
				power = 760.6,
			},
		},
	},
	Zone3Egg6 = {
		displayName = "Guardian Angel Egg",
		cost = 15000000000,
		costType = Keys.ItemType.wins,
		pets = {
			{
				name = "Salamander",
				weight = 77,
				rarity = "Legendary",
				power = 580.4,
			},
			{
				name = "Blue Dinosaur",
				weight = 22.9,
				rarity = "Mythic",
				power = 630.8,
			},
			{
				name = "Lime",
				weight = 0.1,
				rarity = "Omega",
				power = 801.2,
			},
		},
	},

	-- -- zone4
	-- Zone4Egg1 = {
	--     displayName = "Rapper Egg",
	--     cost = 37500000000,
	--     costType = Keys.ItemType.wins,
	--     pets = {
	--         {
	--             name = "Baby Ququ",
	--             weight = 62,
	--             rarity = "Epic",
	--             power = 598.1
	--         },
	--         {
	--             name = "Stick Ququ",
	--             weight = 31,
	--             rarity = "Legendary",
	--             power = 700.5
	--         },
	--         {
	--             name = "Uper Ququ",
	--             weight = 6,
	--             rarity = "Mythic",
	--             power = 1013.5
	--         },
	--         {
	--             name = "Ququ",
	--             weight = 1,
	--             rarity = "Omega",
	--             power = 1425.1
	--         }
	--     }
	-- },
	-- Zone4Egg2 = {
	--     displayName = "Trapper Egg",
	--     cost = 187500000000,
	--     costType = Keys.ItemType.wins,
	--     pets = {
	--         {
	--             name = "Gold Eagle",
	--             weight = 77,
	--             rarity = "Legendary",
	--             power = 1087.5
	--         },
	--         {
	--             name = "X-Gold Eagle",
	--             weight = 22.9,
	--             rarity = "Mythic",
	--             power = 1247.2
	--         },
	--         {
	--             name = "V-Gold Eagle",
	--             weight = 0.1,
	--             rarity = "Omega",
	--             power = 1747.7
	--         },
	--     }
	-- },
	-- Zone4Egg3 = {
	--     displayName = "Jack-o'-lantern Egg",
	--     cost = 937500000000,
	--     costType = Keys.ItemType.wins,
	--     pets = {
	--         {
	--             name = "Baby Dark Ling",
	--             weight = 77,
	--             rarity = "Legendary",
	--             power = 1333.7
	--         },
	--         {
	--             name = "Flow Dark Ling",
	--             weight = 22.9,
	--             rarity = "Mythic",
	--             power = 1502.8
	--         },
	--         {
	--             name = "Bit Dark Ling",
	--             weight = 0.1,
	--             rarity = "Omega",
	--             power = 2105.9
	--         },
	--     }
	-- },
	-- Zone4Egg4 = {
	--     displayName = "Hellboy Egg",
	--     cost = 4687500000000,
	--     costType = Keys.ItemType.wins,
	--     pets = {
	--         {
	--             name = "Red Ghost",
	--             weight = 62,
	--             rarity = "Epic",
	--             power = 1572.1
	--         },
	--         {
	--             name = "Wings Red Ghost",
	--             weight = 31,
	--             rarity = "Legendary",
	--             power = 1841.2
	--         },
	--         {
	--             name = "Red Pumpkin Head",
	--             weight = 6,
	--             rarity = "Mythic",
	--             power = 2663.8
	--         },
	--         {
	--             name = "Red Pumpkin Demon",
	--             weight = 1,
	--             rarity = "Omega",
	--             power = 3745.8
	--         }
	--     }
	-- },
	-- Zone4Egg5 = {
	--     displayName = "Mummy Egg",
	--     cost = 22500000000000,
	--     costType = Keys.ItemType.wins,
	--     pets = {
	--         {
	--             name = "Soul Scorpion",
	--             weight = 77,
	--             rarity = "Legendary",
	--             power = 2858.3
	--         },
	--         {
	--             name = "Soul Wins Scorpion",
	--             weight = 22.9,
	--             rarity = "Mythic",
	--             power = 3106.5
	--         },
	--         {
	--             name = "Double Tail Scorpion",
	--             weight = 0.1,
	--             rarity = "Omega",
	--             power = 3945.7
	--         },
	--     }
	-- },
	-- Zone4Egg6 = {
	--     displayName = "Angel Knight Egg",
	--     cost = 112500000000000,
	--     costType = Keys.ItemType.wins,
	--     pets = {
	--         {
	--             name = "Green Two Wings",
	--             weight = 77,
	--             rarity = "Legendary",
	--             power = 3010.8
	--         },
	--         {
	--             name = "Green Three Wings",
	--             weight = 22.9,
	--             rarity = "Mythic",
	--             power = 3272.3
	--         },
	--         {
	--             name = "Green Wings demon",
	--             weight = 0.1,
	--             rarity = "Omega",
	--             power = 4156.3
	--         },
	--     }
	-- },

	-- -- halloween
	-- ["Halloween Egg"] = {
	--     cost = 0,
	--     costType = Keys.ItemType.wins,
	--     pets = {
	--         {
	--             name = "Spiritual",
	--             weight = 77,
	--             rarity = "Omega",
	--             power = 600
	--         },
	--         {
	--             name = "Komori",
	--             weight = 22.9,
	--             rarity = "Omega",
	--             power = 1200
	--         },
	--         {
	--             name = "Green Screen",
	--             weight = 0.1,
	--             rarity = "Omega",
	--             power = 5000
	--         },
	--         {
	--             name = "Blue Imp",
	--             weight = 0.1,
	--             rarity = "Omega",
	--             power = 7500
	--         },
	--         {
	--             name = "Green Order",
	--             weight = 0.1,
	--             rarity = "Omega",
	--             power = 7500
	--         },
	--     }
	-- }
}

PetPresets.LimitedPets = {
	-----[[ 1 ]]-----
	["Aquatic Dragon"] = {
		rarity = "Omega",
		power = 100,
	},
	["Shout Bandit"] = {
		rarity = "Omega",
		power = 300,
	},
	["Terra Horizont"] = {
		rarity = "Omega",
		power = 500,
	},
	["Demon Agony"] = {
		rarity = "Omega",
		power = 1000,
	},
	["Alien Parasite"] = {
		rarity = "Omega",
		power = 2500,
	},
}

PetPresets.SpecialPets = {
	["Watermelon Winner"] = {
		rarity = "Omega",
		power = 299,
	},
}

PetPresets.PetsList = {}

local function GeneratePetsList()
	-- from EggsList
	for eggName, eggConfig in PetPresets.EggsList do
		local pets = eggConfig.pets
		for _, petConfig in pets do
			PetPresets.PetsList[petConfig.name] = {
				name = petConfig.name,
				mesh = assetsPath.Pets[eggName][petConfig.name],
				rarity = petConfig.rarity,
				power = petConfig.power,
			}
		end
	end

	-- from SpecialPets
	for petName, config in PetPresets.SpecialPets do
		PetPresets.PetsList[petName] = {
			name = petName,
			mesh = assetsPath.Pets.SpecialPets[petName],
			rarity = config.rarity,
			power = config.power,
		}
	end

	-- for limited pets
	for petName, config in pairs(PetPresets.LimitedPets) do
		PetPresets.PetsList[petName] = {
			name = petName,
			mesh = assetsPath.Pets.LimitedPets[petName],
			rarity = config.rarity,
			power = config.power,
		}
	end
end

GeneratePetsList()

return PetPresets
