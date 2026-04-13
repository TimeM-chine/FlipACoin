local Replicated = game:GetService("ReplicatedStorage")

local DEFAULT_DATA = require(Replicated.configs.DefaultData)
local TableModule = require(Replicated.modules.TableModule)
local DebugData = table.clone(DEFAULT_DATA) -- just for auto completion
DebugData = TableModule.DeepCopy(DEFAULT_DATA)

DebugData.wins = 100000000000000000

-- DebugData.settingsData = {
-- 	bgm = 1,
-- 	sfx = 1,
-- 	trade = true,
-- }

-- DebugData.backpack.weapons = {
-- 	[1] = {
-- 		weaponId = "Laser1",
-- 		tier = "normal",
-- 		mainOre = "Stone",
-- 		size = 0.3, -- quality
-- 		equipped = true,
-- 		enhance = 0,
-- 		color = "White",
-- 		materials = "Plastic",
-- 		enchants = {}, -- enchant Slot {[1] = {attrName = "Burn" }}
-- 		attrs = {},
-- 		damageBoost = 1,
-- 	},
-- 	[2] = {
-- 		weaponId = "BouncingBomb1",
-- 		tier = "normal",
-- 		mainOre = "Stone",
-- 		size = 0.3, -- quality
-- 		equipped = true,
-- 		enhance = 0,
-- 		color = "White",
-- 		materials = "Plastic",
-- 		enchants = {}, -- enchant Slot {[1] = {attrName = "Burn" }}
-- 		attrs = {},
-- 		damageBoost = 1,
-- 	},
-- 	[3] = {
-- 		weaponId = "Laser3",
-- 		tier = "normal",
-- 		mainOre = "Stone",
-- 		size = 0.3, -- quality
-- 		equipped = true,
-- 		enhance = 0,
-- 		color = "White",
-- 		materials = "Plastic",
-- 		enchants = {}, -- enchant Slot {[1] = {attrName = "Burn" }}
-- 		attrs = {},
-- 		damageBoost = 1,
-- 	},
-- 	[4] = {
-- 		weaponId = "Bomb1",
-- 		tier = "normal",
-- 		mainOre = "Stone",
-- 		size = 0.3, -- quality
-- 		equipped = true,
-- 		enhance = 0,
-- 		color = "Green",
-- 		materials = "Snow",
-- 		enchants = {}, -- enchant Slot {[1] = {attrName = "Burn" }}
-- 		attrs = {},
-- 		damageBoost = 1,
-- 	},
-- }

-- DebugData.backpack.ores = {
-- 	Coal = 9,
-- 	Copper = 3,
-- 	Tin = 5,
-- 	Iron = 3,
-- 	Gold = 4,
-- 	Diamond = 3,
-- 	Emerald = 2,
-- 	["Nether Quartz"] = 2,
-- 	["Ancient Relic Gold"] = 1,
-- 	["Primordial Rock"] = 1,
-- }

-- DebugData.potions = {
-- 	["lucky1Potion15"] = 32,
-- 	["lucky2Potion15"] = 29,
-- 	["wins1Potion30"] = 10,
-- }

-- DebugData.quests = {
-- 	index = 15,
-- 	quests = {
-- 		[1] = {
-- 			["current"] = 0,
-- 			["isCompleted"] = false,
-- 			["questType"] = "getNamedCard",
-- 			["name"] = "Odin Din Din Dun_normal",
-- 			["target"] = 1,
-- 		},
-- 	},
-- }

-- DebugData.event = {
-- 	eventId = "2025Halloween",
-- 	wins = 10,
-- 	multiplierIndex = 1,
-- }

-- -- DebugData.wins = 99999

return DebugData
