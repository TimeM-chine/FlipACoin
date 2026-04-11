local RebirthPresets = {}

RebirthPresets.RebirthConfig = {
    [0] = {
        cost = 200,
        boost = 0,
    },
    [1] = {
		cost = 300,
        boost = 0.25,
    },
    [2] = {
		cost = 450,
        boost = 0.50,
    }
}


RebirthPresets.LevelColor = {
    [0] = Color3.new(0.760784, 0.760784, 0.760784),
	[10] = Color3.new(1, 1, 1),
	[20] = Color3.new(0.666667, 1, 1),
	[30] = Color3.new(0, 1, 0),
	[40] = Color3.new(0, 1, 1),
	[50] = Color3.new(0, 0, 1),
	[60] = Color3.new(1, 1, 0.498039),
	[70] = Color3.new(1, 1, 0),
	[80] = Color3.new(1, 0.333333, 0),
	[90] = Color3.new(0.666667, 0.333333, 0),
	[100] = Color3.new(1, 0.666667, 1),
	[110] = Color3.new(1, 0, 1),
	[120] = Color3.new(0.666667, 0, 1),
	[130] = Color3.new(1, 0, 0),
	[140] = Color3.new(0.666667, 0, 0),
	[150] = Color3.new(0, 0, 0)
}

RebirthPresets.ColorIndexes = {}
for index, _ in pairs(RebirthPresets.LevelColor) do
    table.insert(RebirthPresets.ColorIndexes, index)
end

local tiers = {
	{
		name = "🥋Beginner", 
		rebirths = 0, 
		boost = 0, 
		cost = 0,
		gems = 0,
		level = 5,
		resetLevel = 1,
	},
	{
		name = "🔰Newbie", 
		rebirths = 1, 
		boost = 0.1, 
		cost = 500,
		gems = 10,
		level = 5,
		resetLevel = 1,
	},
	{
		name = "🤙Apprentice", 
		rebirths = 2, 
		boost = 0.2, 
		cost = 1000,
		gems = 30,
		level = 10,
		resetLevel = 5,
	},
	{
		name = "✨Expert", 
		rebirths = 3, 
		boost = 0.3, 
		cost = 2000,
		gems = 50,
		level = 15,
		resetLevel = 6,
	},
	{
		name = "😎Super Expert", 
		rebirths = 4, 
		boost = 0.4, 
		cost = 5000,
		gems = 100,
		level = 20,
		resetLevel = 10,
	},
	{
		name = "🥸Master", 
		rebirths = 5, 
		boost = 0.5, 
		cost = 5000,
		gems = 200,
		level = 25,
		resetLevel = 15,
	},
	{
		name = "✨Grand Master", 
		rebirths = 6, 
		boost = 0.6, 
		cost = 10000,
		gems = 400,
		level = 30,
		resetLevel = 20,
	},
	{
		name = "👍Giant Master", 
		rebirths = 7, 
		boost = 0.7, 
		cost = 15000,
		gems = 800,
		level = 35,
		resetLevel = 25,
	},
	{
		name = "🔥Overlord", 
		rebirths = 8, 
		boost = 0.8, 
		cost = 30000,
		gems = 1000,
		level = 40,
		resetLevel = 25,
	},
	{
		name = "😊Farmer", 
		rebirths = 9, 
		boost = 0.9, 
		cost = 60000,
		gems = 1300,
		level = 42,
		resetLevel = 30,
	},
	{
		name = "✨Blacksmith", 
		rebirths = 10, 
		boost = 1, 
		cost = 100_000,
		gems = 1500,
		level = 44,
		resetLevel = 30,
	},
	{
		name = "💫Knight", 
		rebirths = 11, 
		boost = 1.1, 
		cost = 500_000,
		gems = 2000,
		level = 45,
		resetLevel = 33,
	},
	{
		name = "🤙Emperor", 
		rebirths = 12, 
		boost = 1.2, 
		cost = 1_000_000,
		gems = 2800,
		level = 47,
		resetLevel = 35,
	},
	{
		name = "🟦Rare Emperor", 
		rebirths = 13, 
		boost = 1.3, 
		cost = 2_000_000,
		gems = 3200,
		level = 48,
		resetLevel = 33,
	},
	{
		name = "🟨Legendary Emperor", 
		rebirths = 14, 
		boost = 1.4, 
		cost = 4_000_000,
		gems = 4000,
		level = 50,
		resetLevel = 35,
	},
	{
		name = "😎Supreme", 
		rebirths = 15, 
		boost = 1.5, 
		cost = 10_000_000,
		gems = 5000,
		level = 52,
		resetLevel = 37,
	},
	{
		name = "👍Epic Supreme", 
		rebirths = 16, 
		boost = 1.6, 
		cost = 20000000,
		gems = 6000,
		level = 54,
		resetLevel = 39,
	},
	{
		name = "🔻Mythical Supreme", 
		rebirths = 17, 
		boost = 1.7, 
		cost = 70000000,
		gems = 7000,
		level = 55,
		resetLevel = 40,
	},
	{
		name = "💫Paragon", 
		rebirths = 18, 
		boost = 1.8, 
		cost = 100000000,
		gems = 8000,
		level = 56,
		resetLevel = 40,
	},
	{
		name = "👑Odyssey Paragon", 
		rebirths = 19, 
		boost = 1.9, 
		cost = 120000000,
		gems = 9000,
		level = 58,
		resetLevel = 40,
	},
	{
		name = "🌛Primordial", 
		rebirths = 20, 
		boost = 2, 
		cost = 140000000,
		gems = 10000,
		level = 60,
		resetLevel = 40,
	},
	{
		name = "🌞God", 
		rebirths = 21, 
		boost = 2.1, 
		cost = 160000000,
		gems = 12000,
		level = 62,
		resetLevel = 45,
	},
	{
		name = "✨Insane", 
		rebirths = 22, 
		boost = 2.2, 
		cost = 200000000,
		gems = 14000,
		level = 64,
		resetLevel = 45,
	},
	{
		name = "😎Grand Insane", 
		rebirths = 23, 
		boost = 2.3, 
		cost = 250000000,
		gems = 16000,
		level = 67,
		resetLevel = 45,
	},
	{
		name = "🔺Mega Emperor", 
		rebirths = 24, 
		boost = 2.4, 
		cost = 325000000,
		gems = 18000,
		level = 68,
		resetLevel = 45,
	},
	{
		name = "😚Beast", 
		rebirths = 25, 
		boost = 2.5, 
		cost = 400000000,
		gems = 20000,
		level = 70,
		resetLevel = 48,
	},
	{
		name = "🦕Elite", 
		rebirths = 26, 
		boost = 2.6, 
		cost = 600000000,
		gems = 22000,
		level = 72,
		resetLevel = 48,
	},
	{
		name = "⭐Master Legend", 
		rebirths = 27, 
		boost = 2.7, 
		cost = 800000000,
		gems = 24000,
		level = 74,
		resetLevel = 48,
	},
	{
		name = "🔭Soul Master", 
		rebirths = 28, 
		boost = 2.8, 
		cost = 1000000000,
		gems = 26000,
		level = 75,
		resetLevel = 50,
	},
	{
		name = "💤Awakened", 
		rebirths = 29, 
		boost = 2.9, 
		cost = 1500000000,
		gems = 28000,
		level = 77,
		resetLevel = 50,
	},
	{
		name = "🖐️Sky Storm", 
		rebirths = 30, 
		boost = 3, 
		cost = 1900000000,
		gems = 30000,	
		level = 79,
		resetLevel = 50,
	},
	{
		name = "🎇Q Strike", 
		rebirths = 31, 
		boost = 3.1, 
		cost = 2300000000,
		gems = 32000,
		level = 80,
		resetLevel = 50,
	},
	{
		name = "🔥Rising Hero", 
		rebirths = 32, 
		boost = 3.2, 
		cost = 4000000000,
		gems = 34000,
		level = 81,
		resetLevel = 50,
	},
	{
		name = "🕉️Omega King", 
		rebirths = 33, 
		boost = 3.3, 
		cost = 6000000000,
		gems = 36000,
		level = 81,
		resetLevel = 50,
	},
	{
		name = "💫Infinity", 
		rebirths = 34, 
		boost = 3.4, 
		cost = 10000000000,
		gems = 38000,
		level = 81,
		resetLevel = 50,
	},
	{
		name = "⭐God", 
		rebirths = 35, 
		boost = 3.5, 
		cost = 12000000000,
		gems = 40000,
		level = 81,
		resetLevel = 50,
	},
	{
		name = "👽Alien", 
		rebirths = 36, 
		boost = 3.6, 
		cost = 15000000000,
		gems = 42000,
		level = 81,
		resetLevel = 50,
	},
	{
		name = "🔫Gun God", 
		rebirths = 37, 
		boost = 3.7, 
		cost = 17000000000,
		gems = 44000,
		level = 81,
		resetLevel = 50,
	},
	{
		name = "🍀Lucky Boss", 
		rebirths = 38, 
		boost = 3.8, 
		cost = 19000000000,
		gems = 46000,
		level = 81,
		resetLevel = 50,
	},
	{
		name = "⚫Unknown King", 
		rebirths = 39, 
		boost = 3.9, 
		cost = 22000000000,
		gems = 48000,
		level = 81,
		resetLevel = 50,
	},
	{
		name = "🤖Mega Robot", 
		rebirths = 40, 
		boost = 4, 
		cost = 24000000000,
		gems = 50000,
		level = 85,
		resetLevel = 55,
	},
	{
		name = "😶‍🌫️Aether", 
		rebirths = 41, 
		boost = 4.1, 
		cost = 27000000000,
		gems = 52000,
		level = 85,
		resetLevel = 55,
	},
	{
		name = "🎁Seraphina",
		rebirths = 42, 
		boost = 4.2, 
		cost = 32000000000,
		gems = 54000,
		level = 85,
		resetLevel = 55,
	},
	{
		name = "🔥Zephyrus",
		rebirths = 43, 
		boost = 4.3, 
		cost = 35000000000,
		gems = 56000,
		level = 85,
		resetLevel = 55,
	},
	{
		name = "👑Tyrian",
		rebirths = 44, 
		boost = 4.4, 
		cost = 40000000000,
		gems = 58000,
		level = 85,
		resetLevel = 55,
	},
	{
		name = "🌚Lunastra",
		rebirths = 45, 
		boost = 4.5, 
		cost = 42000000000,
		gems = 60000,
		level = 85,
		resetLevel = 55,
	},
	{
		name = "✨Astraeus",
		rebirths = 46, 
		boost = 4.6, 
		cost = 44000000000,
		gems = 62000,
		level = 85,
		resetLevel = 55,
	},
	{
		name = "🎄Orpheus",
		rebirths = 47, 
		boost = 4.7, 
		cost = 48000000000,
		gems = 64000,
		level = 85,
		resetLevel = 55,
	},
	{
		name = "🎗️Selene",
		rebirths = 48, 
		boost = 4.8, 
		cost = 52000000000,
		gems = 66000,
		level = 85,
		resetLevel = 55,
	},
	{
		name = "🎊Amara",
		rebirths = 49, 
		boost = 4.9, 
		cost = 60000000000,
		gems = 68000,
		level = 85,
		resetLevel = 55,
	},
	{
		name = "🎀Azrael",
		rebirths = 50, 
		boost = 5, 
		cost = 65000000000,
		gems = 70000,
		level = 90,
		resetLevel = 60,
	},
	{
		name = "🎃Nyx",
		rebirths = 51, 
		boost = 5.1, 
		cost = 70000000000,
		gems = 72000,
		level = 90,
		resetLevel = 60,
	},
	{
		name = "🌞Solara",
		rebirths = 52, 
		boost = 5.2, 
		cost = 73000000000,
		gems = 74000,
		level = 90,
		resetLevel = 60,
	},
	{
		name = "🪓Valkyria",
		rebirths = 53, 
		boost = 5.3, 
		cost = 80000000000,
		gems = 76000,
		level = 90,
		resetLevel = 60,
	},
	{
		name = "🧨Morpheus",
		rebirths = 54, 
		boost = 5.4, 
		cost = 87000000000,
		gems = 78000,
		level = 90,
		resetLevel = 60,
	},
	{
		name = "🎭Artemis",
		rebirths = 55, 
		boost = 5.5, 
		cost = 94000000000,
		gems = 80000,
		level = 90,
		resetLevel = 60,
	},
	{
		name = "🛰️Ignis",
		rebirths = 56, 
		boost = 5.6, 
		cost = 105000000000,
		gems = 82000,
		level = 90,
		resetLevel = 60,
	},
	{
		name = "💢Odin",
		rebirths = 57, 
		boost = 5.7, 
		cost = 115000000000,
		gems = 84000,
		level = 90,
		resetLevel = 60,
	},
	{
		name = "😎Thalia",
		rebirths = 58, 
		boost = 5.8, 
		cost = 125000000000,
		gems = 86000,
		level = 90,
		resetLevel = 60,
	},
	{
		name = "🥯Aria",
		rebirths = 59, 
		boost = 5.9, 
		cost = 150000000000,
		gems = 88000,
		level = 90,
		resetLevel = 60,
	},
	{
		name = "🪢Helios",
		rebirths = 60, 
		boost = 6, 
		cost = 180000000000,
		gems = 90000,
		level = 95,
		resetLevel = 65,
	},
	{
		name = "🖼️Maelstrom",
		rebirths = 61, 
		boost = 6.1, 
		cost = 200000000000,
		gems = 92000,
		level = 95,
		resetLevel = 65,
	},
	{
		name = "🎪Freya",
		rebirths = 62, 
		boost = 6.2, 
		cost = 230000000000,
		gems = 94000,
		level = 95,
		resetLevel = 65,
	},
	{
		name = "🧣Sylph",
		rebirths = 63, 
		boost = 6.3, 
		cost = 250000000000,
		gems = 96000,
		level = 95,
		resetLevel = 65,
	},
	{
		name = "🎓Atlas",
		rebirths = 64, 
		boost = 6.4, 
		cost = 280000000000,
		gems = 98000,
		level = 95,
		resetLevel = 65,
	},
	{
		name = "🕶️Elysia",
		rebirths = 65, 
		boost = 6.5, 
		cost = 300000000000,
		gems = 100000,
		level = 95,
		resetLevel = 65,
	},
	{
		name = "🕳️Nemesis",
		rebirths = 66, 
		boost = 6.6, 
		cost = 350000000000,
		gems = 105000,
		level = 95,
		resetLevel = 65,
	},
	{
		name = "🫓Kairos",
		rebirths = 67, 
		boost = 6.7, 
		cost = 400000000000,
		gems = 110000,
		level = 95,
		resetLevel = 65,
	},
	{
		name = "🧤Avalon",
		rebirths = 68, 
		boost = 6.8, 
		cost = 450000000000,
		gems = 115000,
		level = 95,
		resetLevel = 65,
	},
	{
		name = "🧧Ishtar",
		rebirths = 69, 
		boost = 6.9, 
		cost = 500000000000,
		gems = 120000,
		level = 95,
		resetLevel = 65,
	},
	{
		name = "🥳Kratos",
		rebirths = 70, 
		boost = 7, 
		cost = 605000000000,
		gems = 125000,
		level = 100,
		resetLevel = 70,
	},
	{
		name = "👻Nephthys",
		rebirths = 71, 
		boost = 7.1, 
		cost = 705000000000,
		gems = 130000,
		level = 100,
		resetLevel = 70,
	},
	{
		name = "😈Prometheus",
		rebirths = 72, 
		boost = 7.2, 
		cost = 805000000000,
		gems = 135000,
		level = 100,
		resetLevel = 70,
	},
	{
		name = "💖Aurora",
		rebirths = 73, 
		boost = 7.3, 
		cost = 905000000000,
		gems = 140000,
		level = 100,
		resetLevel = 70,
	},
	{
		name = "😶‍🌫️Erebos",
		rebirths = 74, 
		boost = 7.4, 
		cost = 1105000000000,
		gems = 145000,
		level = 100,
		resetLevel = 70,
	},
	{
		name = "😇Kali",
		rebirths = 75, 
		boost = 7.5, 
		cost = 1305000000000,
		gems = 150000,	
		level = 100,
		resetLevel = 70,
	},
	{
		name = "🤓Chronos",
		rebirths = 76, 
		boost = 7.6, 
		cost = 1505000000000,
		gems = 155000,
		level = 100,
		resetLevel = 70,
	},
	{
		name = "🎈Morrigan",
		rebirths = 77, 
		boost = 7.7, 
		cost = 1705000000000,
		gems = 160000,
		level = 100,
		resetLevel = 70,
	},
	{
		name = "🎬Neith",
		rebirths = 78, 
		boost = 7.8, 
		cost = 1905000000000,
		gems = 165000,
		level = 100,
		resetLevel = 70,
	},
	{
		name = "🌋Volcan",
		rebirths = 79, 
		boost = 7.9, 
		cost = 2105000000000,
		gems = 170000,
		level = 100,
		resetLevel = 70,
	},
	{
		name = "🦠Hecate",
		rebirths = 80, 
		boost = 8, 
		cost = 2405000000000,
		gems = 175000,
		level = 105,
		resetLevel = 75,
	},
	{
		name = "🖐️Oberon",
		rebirths = 81, 
		boost = 8.1, 
		cost = 2705000000000,
		gems = 180000,
		level = 105,
		resetLevel = 75,
	},
	{
		name = "👽Nyssa",
		rebirths = 82, 
		boost = 8.2, 
		cost = 3005000000000,
		gems = 185000,
		level = 105,
		resetLevel = 75,
	},
	{
		name = "🤩Hephaestus",
		rebirths = 83, 
		boost = 8.3, 
		cost = 3005000000000,
		gems = 190000,
		level = 105,
		resetLevel = 75,
	},
	{
		name = "💫Freyja",
		rebirths = 84, 
		boost = 8.4, 
		cost = 3305000000000,
		gems = 195000,
		level = 105,
		resetLevel = 75,
	},
	{
		name = "⭐Pandora",
		rebirths = 85, 
		boost = 8.5, 
		cost = 3605000000000,
		gems = 200000,
		level = 105,
		resetLevel = 75,
	},
	{
		name = "🌟Moros",
		rebirths = 86, 
		boost = 8.6, 
		cost = 3905000000000,
		gems = 205000,
		level = 105,
		resetLevel = 75,
	},
	{
		name = "🩺Bastet",
		rebirths = 87, 
		boost = 8.7, 
		cost = 4005000000000,
		gems = 210000,
		level = 105,
		resetLevel = 75,
	},
	{
		name = "💷Thanatos",
		rebirths = 88, 
		boost = 8.8, 
		cost = 4105000000000,
		gems = 215000,
		level = 105,
		resetLevel = 75,
	},
	{
		name = "🧤Thanos",
		rebirths = 89, 
		boost = 8.9, 
		cost = 4205000000000,
		gems = 220000,
		level = 105,
		resetLevel = 75,
	},
	{
		name = "👨‍🎓🔰Thief Newbie",
		rebirths = 90, 
		boost = 9, 
		cost = 4405000000000,
		gems = 225000,
		level = 110,
		resetLevel = 80,
	},
	{
		name = "👨‍🎓Thief",
		rebirths = 91, 
		boost = 9.1, 
		cost = 4505000000000,
		gems = 230000,
		level = 110,
		resetLevel = 80,
	},
	{
		name = "👨‍🎓💫Thief King",
		rebirths = 92, 
		boost = 9.2, 
		cost = 4605000000000,
		gems = 235000,
		level = 110,
		resetLevel = 80,
	},
	{
		name = "🔫Boss",
		rebirths = 93, 
		boost = 9.3, 
		cost = 4705000000000,
		gems = 240000,
		level = 110,
		resetLevel = 80,
	},
	{
		name = "👑King Emperor",
		rebirths = 94, 
		boost = 9.4, 
		cost = 4805000000000,
		gems = 245000,
		level = 110,
		resetLevel = 80,
	},
	{
		name = "👍Selene",
		rebirths = 95, 
		boost = 9.5, 
		cost = 4905000000000,
		gems = 250000,
		level = 110,
		resetLevel = 80,
	},
	{
		name = "🫓Ares",
		rebirths = 96, 
		boost = 9.6, 
		cost = 5005000000000,
		gems = 255000,
		level = 110,
		resetLevel = 80,
	},
	{
		name = "👼Anubis",
		rebirths = 97, 
		boost = 9.7, 
		cost = 5205000000000,
		gems = 260000,
		level = 110,
		resetLevel = 80,
	},
	{
		name = "🫰Gaia",
		rebirths = 98, 
		boost = 9.8, 
		cost = 5405000000000,
		gems = 265000,
		level = 110,
		resetLevel = 80,
	},
	{
		name = "🌑Chill Moon",
		rebirths = 99, 
		boost = 9.9, 
		cost = 5605000000000,
		gems = 270000,
		level = 110,
		resetLevel = 80,
	},
	{
		name = "🌒Cool Moon",
		rebirths = 100, 
		boost = 10, 
		cost = 5805000000000,
		gems = 280000,
		level = 115,
		resetLevel = 85,
	},
	{
		name = "🌓Half Moon",
		rebirths = 101, 
		boost = 10.1, 
		cost = 6005000000000,
		gems = 290000,
		level = 115,
		resetLevel = 85,
	},
	{
		name = "🌔OP Moon",
		rebirths = 102, 
		boost = 10.2, 
		cost = 7005000000000,
		gems = 300000,
		level = 115,
		resetLevel = 85,
	},
	{
		name = "🌕Real Moon",
		rebirths = 103, 
		boost = 10.3, 
		cost = 8000000000000,
		gems = 310000,
		level = 115,
		resetLevel = 85,
	},
	{
		name = "🛰️Space",
		rebirths = 104, 
		boost = 10.4, 
		cost = 9000000000000,
		gems = 320000,
		level = 115,
		resetLevel = 85,
	},
	{
		name = "🌞Happy Sun",
		rebirths = 105, 
		boost = 10.5, 
		cost = 10000000000000,
		level = 115,
		resetLevel = 85,
	},
	{
		name = "🧜🏽‍Aphrodite",
		rebirths = 106, 
		boost = 10.6, 
		cost = 50000000000000
	},
	{
		name = "🍃Demeter",
		rebirths = 107, 
		boost = 10.7, 
		cost = 11000000000000
	},
	{
		name = "🐍Hermes",
		rebirths = 108, 
		boost = 10.8, 
		cost = 12000000000000
	},
	{
		name = "⚔️Loki",
		rebirths = 109, 
		boost = 10.9, 
		cost = 13000000000000
	},
	{
		name = "🪃Osiris",
		rebirths = 110, 
		boost = 11, 
		cost = 14000000000000
	},
	{
		name = "🔱Poseidon",
		rebirths = 111, 
		boost = 11.1, 
		cost = 15000000000000
	},
	{
		name = "🎸Triton",
		rebirths = 112, 
		boost = 11.2, 
		cost = 16000000000000
	},
	{
		name = "⚕️Persephone",
		rebirths = 113, 
		boost = 11.3, 
		cost = 17000000000000
	},
	{
		name = "🏴󠁧󠁢󠁳󠁣󠁴󠁿Brigid",
		rebirths = 114, 
		boost = 11.4, 
		cost = 18000000000000
	},
	{
		name = "🧿God Eye",
		rebirths = 115, 
		boost = 11.5, 
		cost = 19000000000000
	},
	{
		name = "🚩Shiva",
		rebirths = 116, 
		boost = 11.6, 
		cost = 20000000000000
	},
	{
		name = "🦗Cernunnos",
		rebirths = 117, 
		boost = 11.7, 
		cost = 22000000000000
	},	{
		name = "🪨Rock",
		rebirths = 118, 
		boost = 11.8, 
		cost = 24000000000000
	},
	{
		name = "🎉Eos",
		rebirths = 119, 
		boost = 11.9, 
		cost = 26000000000000
	},
	{
		name = "🤠Epona",
		rebirths = 120, 
		boost = 12, 
		cost = 28000000000000
	},
	{
		name = "🎭Janus",
		rebirths = 121, 
		boost = 12.1, 
		cost = 30000000000000
	},
	{
		name = "🐲Green Dragon",
		rebirths = 122, 
		boost = 12.2, 
		cost = 33000000000000
	},
	{
		name = "🌍Earth",
		rebirths = 123, 
		boost = 12.3, 
		cost = 36000000000000
	},
	{
		name = "🏉Tiamat",
		rebirths = 124, 
		boost = 12.4, 
		cost = 39000000000000
	},
	{
		name = "🌯Quetzalcoatl",
		rebirths = 125, 
		boost = 12.5, 
		cost = 43000000000000
	},
	{
		name = "🪷Saraswati",
		rebirths = 126, 
		boost = 12.6, 
		cost = 53000000000000
	},
	{
		name = "🔨Thor",
		rebirths = 127, 
		boost = 12.7, 
		cost = 63000000000000
	},
	{
		name = "⚡Flash",
		rebirths = 128, 
		boost = 12.8, 
		cost = 73000000000000
	},

	{
		name = "🚀Epic Rocket",
		rebirths = 129, 
		boost = 12.9, 
		cost = 83000000000000
	},
	{
		name = "🎯Archer",
		rebirths = 130, 
		boost = 13, 
		cost = 93000000000000
	},	{
		name = "🔥Fire Man",
		rebirths = 131, 
		boost = 13.1, 
		cost = 100000000000000
	},	{
		name = "🧑🏻‍🚀Astronaut",
		rebirths = 132, 
		boost = 13.2, 
		cost = 110000000000000
	},
	{
		name = "🔋Battery",
		rebirths = 133, 
		boost = 13.3, 
		cost = 120000000000000
	},
	{
		name = "💪Strong Man",
		rebirths = 134, 
		boost = 13.4, 
		cost = 130000000000000
	},
	{
		name = "🤟Gangster",
		rebirths = 135, 
		boost = 13.5, 
		cost = 140000000000000
	},
	{
		name = "🏋🏽Gym Bro",
		rebirths = 136, 
		boost = 13.6, 
		cost = 150000000000000
	},
	{
		name = "🎲Dice",
		rebirths = 137, 
		boost = 13.7, 
		cost = 160000000000000
	},
	{
		name = "💎Gem Mine",
		rebirths = 138, 
		boost = 13.8, 
		cost = 170000000000000
	},
	{
		name = "🏆Trophy",
		rebirths = 139, 
		boost = 13.9, 
		cost = 180000000000000
	},
	{
		name = "🤜🏻Fist",
		rebirths = 140, 
		boost = 14, 
		cost = 190000000000000
	},	{
		name = "🎮Xolotl",
		rebirths = 141, 
		boost = 14.1, 
		cost = 200000000000000
	},
	{
		name = "👾Inanna",
		rebirths = 142, 
		boost = 14.2, 
		cost = 220000000000000
	},

	{
		name = "🦣Mammoth",
		rebirths = 143, 
		boost = 14.3, 
		cost = 240000000000000
	},
	{
		name = "🕹️Sekhmet",
		rebirths = 144, 
		boost = 14.4, 
		cost = 260000000000000
	},
	{
		name = "🌊Tsunami",
		rebirths = 145, 
		boost = 14.5, 
		cost = 280000000000000
	},
	{
		name = "👸🏻Queen",
		rebirths = 146, 
		boost = 14.6, 
		cost = 300000000000000
	},
	{
		name = "🦎Lizard",
		rebirths = 147, 
		boost = 14.7, 
		cost = 330000000000000
	},
	{
		name = "🍀Lucky Man",
		rebirths = 148, 
		boost = 14.8, 
		cost = 360000000000000
	},
	{
		name = "🦜Yggdrasil",
		rebirths = 149, 
		boost = 14.9, 
		cost = 400000000000000
	},

	{
		name = "⚫Unknown Supreme",
		rebirths = 150, 
		boost = 15, 
		cost = 450000000000000
	},

    {
        name = "🎓God Master",
        rebirths = 151, 
        boost = 15.1, 
        cost = 470000000000000
    },
    {
        name = "💥Insane King",
        rebirths = 152, 
        boost = 15.2,
        cost = 490000000000000
    },
    {
        name = " 🙈Yamcha",
        rebirths = 153, 
        boost = 15.3, 
        cost = 530000000000000
    },
    {
        name = "🧧Chiaotzu",
        rebirths = 154, 
        boost = 15.4, 
        cost = 550000000000000
    },
    {
        name = " 🐱Puar",
        rebirths = 155, 
        boost = 15.5, 
        cost = 600000000000000
    },
    {
        name = " 😶Mr. Popo",
        rebirths = 156, 
        boost = 15.6, 
        cost = 650000000000000
    },
    {
        name = "⚔️Krillin",
        rebirths = 157, 
        boost = 15.7, 
        cost = 750000000000000
    },
    {
        name = "🔥Tien Shinhan",
        rebirths = 158, 
        boost = 15.8, 
        cost = 850000000000000
    },
    {
        name = "🐉Piccolo",
        rebirths = 159, 
        boost = 15.9, 
        cost = 900000000000000
    },
    {
        name = "👑Vegeta",
        rebirths = 160, 
        boost = 16, 
        cost = 950000000000000
    },
    {
        name = "🐵Goku",
        rebirths = 161, 
        boost = 16.1, 
        cost = 1000000000000000
    },
    {
        name = "🌟Gohan",
        rebirths = 162, 
        boost = 16.2, 
        cost = 1100000000000000
    },
    {
        name = "💡Bulma",
        rebirths = 163, 
        boost = 16.3, 
        cost = 1200000000000000
    },
    {
        name = "🐢Master Roshi",
        rebirths = 164, 
        boost = 16.4, 
        cost = 1300000000000000
    },
    {
        name = "🤖Android 18",
        rebirths = 165, 
        boost = 16.5, 
        cost = 1400000000000000
    },
    {
        name = "🐉Frieza",
        rebirths = 166, 
        boost = 16.6, 
        cost = 1500000000000000
    },
    {
        name = "🧬Cell",
        rebirths = 167, 
        boost = 16.7, 
        cost = 1600000000000000
    },
    {
        name = "👹Majin Buu",
        rebirths = 168, 
        boost = 16.8, 
        cost = 1700000000000000
    },
    {
        name = "🐱‍👤Beerus",
        rebirths = 169, 
        boost = 16.9, 
        cost = 2000000000000000
    },
    {
        name = "⏳Whis",
        rebirths = 170, 
        boost = 17, 
        cost = 2200000000000000
    },
    {
        name = "🍗Goten",
        rebirths = 171, 
        boost = 17.1, 
        cost = 2400000000000000
    },
    {
        name = "🗡️Trunks",
        rebirths = 172, 
        boost = 17.2, 
        cost = 2600000000000000
    },
    {
        name = "🕶️Gotenks",
        rebirths = 173, 
        boost = 17.3, 
        cost = 2800000000000000
    },
    {
        name = "🥕Vegito",
        rebirths = 174, 
        boost = 17.4, 
        cost = 3000000000000000
    },
    {
        name = "⚔️Future Trunks",
        rebirths = 175, 
        boost = 17.5, 
        cost = 3300000000000000
    },
    {
        name = "👧Krillin Daughter",
        rebirths = 176, 
        boost = 17.6, 
        cost = 3600000000000000
    },
    {
        name = "🤖Android 17",
        rebirths = 177, 
        boost = 17.7, 
        cost = 3900000000000000
    },
    {
        name = "🐺Yamcha's Wolf",
        rebirths = 178, 
        boost = 17.8, 
        cost = 4400000000000000
    },
    {
        name = "🐉Master Shen",
        rebirths = 179, 
        boost = 17.9, 
        cost = 4800000000000000
    },
    {
        name = "🌟Supreme Kai",
        rebirths = 180, 
        boost = 18, 
        cost = 5500000000000000
    },
	{
        name = "🕵️Mystic",
        rebirths = 181, 
        boost = 18.1, 
        cost = 7000000000000000
    },
    {
        name = "🌞 SolarFlare",
        rebirths = 182, 
        boost = 18.2, 
        cost = 10000000000000000
    },
    {
        name = "👾 TechNinja",
        rebirths = 183, 
        boost = 18.3, 
        cost = 12500000000000000
    },
    {
        name = "🏙️ NeonNomad",
        rebirths = 184, 
        boost = 18.4, 
        cost = 16000000000000000
    },
    {
        name = "🏴‍☠️ Pirate",
        rebirths = 185, 
        boost = 18.5, 
        cost = 20000000000000000
    },
    {
        name = "🎹 SynthWave",
        rebirths = 186, 
        boost = 18.6, 
        cost = 23000000000000000
    },
    {
        name = "🤖 RoboWhiz",
        rebirths = 187, 
        boost = 18.7, 
        cost = 26500000000000000
    },
    {
        name = "🧬 BioHacker",
        rebirths = 188, 
        boost = 18.8, 
        cost = 29500000000000000
    },
    {
        name = "🔮 Quantum",
        rebirths = 189, 
        boost = 18.9, 
        cost = 32900000000000000
    },
    {
        name = "🌌 CosmicExplorer",
        rebirths = 190, 
        boost = 19, 
        cost = 37900000000000000
    },
	{
        name = "🤯Mind-Boggling",
        rebirths = 191, 
        boost = 19.1, 
        cost = 50900000000000000
    },
	{
		name = "🍙Sushi Pioneer",
		rebirths = 192, 
		boost = 19.2, 
		cost = 70900000000000000
	},
	{	name = "🤯Awe-Struck",
		rebirths = 193, 
		boost = 19.3, 
		cost = 90900000000000000
	},
	{	
		name = "🚀Nebula Navigator",
		rebirths = 194, 
		boost = 19.4, 
		cost = 120900000000000000
	},
	{	
		name = "✨Stardust",
		rebirths = 195, 
		boost = 19.5, 
		cost = 150900000000000000
	},
	{		
		name = "🧩Stardust Enigma",
		rebirths = 196, 
		boost = 19.6, 
		cost = 200900000000000000
	},
	{		
		name = "💣Dynamite Stardust",
		rebirths = 197, 
		boost = 19.7, 
		cost = 250900000000000000
	},
	{		
		name = "✨Stardust Connoisseur",
		rebirths = 198, 
		boost = 19.8, 
		cost = 350900000000000000
	},
	{		
		name = "💣Bombastic Explorer",
		rebirths = 199, 
		boost = 19.9, 
		cost = 500900000000000000
	},
	{		
		name = "🌌Dreamweaver",
		rebirths = 200, 
		boost = 20.0, 
		cost = 650900000000000000
	},
	{		
		name = "🚀Galactic Rocketeer",
		rebirths = 201, 
		boost = 20.1, 
		cost = 800900000000000000		
	},
	{
        name = "🛩️Astral Aviator",
        rebirths = 202, 
        boost = 20.2, 
        cost = 900900000000000000
    },
	{
        name = "😡Raging Nebula",
        rebirths = 203, 
        boost = 20.3, 
        cost = 1050900000000000000
    },
	{
        name = "🔥Nebula Trailblazer",
        rebirths = 204, 
        boost = 20.4, 
        cost = 1200900000000000000
    },
	{
        name = "🍫Chocolate Warp",
        rebirths = 205, 
        boost = 20.5, 
        cost = 1200900000000000000
    },
	{
        name = "🎩Stardust Magician ",
        rebirths = 206, 
        boost = 20.6, 
        cost = 1390000000000000000
    },
	{
        name = "👌Perfect Astral",
        rebirths = 205, 
        boost = 20.5, 
        cost = 1500000000000000000
    },
		{
        name = "😐Unmoved Galactic",
        rebirths = 206, 
        boost = 20.6, 
        cost = 1610900000000000000
    },
	{
        name = "🌌Galactic Observer",
        rebirths = 207, 
        boost = 20.7, 
        cost = 1720900000000000000
    },
	{
        name = "🐥Elysian Stardust",
        rebirths = 208, 
        boost = 20.8, 
        cost = 1830900000000000000
    },
	{
        name = "💫Stardust Observer",
        rebirths = 209, 
        boost = 20.9, 
        cost = 1940900000000000000
    },
	{
        name = "🌠Stardust Trailblazer",
        rebirths = 210, 
        boost = 21.0, 
        cost = 2000900000000000000
    },
		{
        name = "✨Celestial Wayfarer ",
        rebirths = 211, 
        boost = 21.1, 
        cost = 2100900000000000000
    },
	{
        name = "🎶Serenader",
        rebirths = 212, 
        boost = 21.2, 
        cost = 2200900000000000000
    },
	{
        name = "🛸UFO Explorerr",
        rebirths = 213, 
        boost = 21.3, 
        cost = 2300900000000000000
    },
	{
        name = "🌌Rainbow Chaser",
        rebirths = 214, 
        boost = 21.4, 
        cost = 2400900000000000000
    },
	{
        name = "🌌Rainbow Chaser",
        rebirths = 214, 
        boost = 21.4, 
        cost = 2520900000000000000

    },
	{
        name = "🌌✨Chromaticist",
        rebirths = 215, 
        boost = 21.5, 
        cost = 2590900000000000000
    },
	{
        name = "🌈Cosmic Chromaticist ",
        rebirths = 216, 
        boost = 21.6, 
        cost = 2690900000000000000
    },
	{
        name = "🚤Interplanetary Mariner",
        rebirths = 217, 
        boost = 21.7, 
        cost = 2900900000000000000
    },
	{
        name = " 🎨✨Astral Artisan",
        rebirths = 218, 
        boost = 21.8, 
        cost = 3000900000000000000
    },
	{
        name = "🚂Locomotion Master",
        rebirths = 219, 
        boost = 21.9, 
        cost = 3100900000000000000
    },
	{
        name = "👻Spooky Master",
        rebirths = 220, 
        boost = 22.0, 
        cost =3200900000000000000
	},
	{
        name = "🚂Spooky Locomotion",
        rebirths = 221, 
        boost = 22.1, 
        cost =3300900000000000000
    },
	{
        name = "🎨✨Astral Locomotion",
        rebirths = 222, 
        boost = 22.2, 
        cost =3450900000000000000
    },
	{
        name = "🌈Cosmic Artisan",
        rebirths = 223, 
        boost = 22.3, 
        cost =3650900000000000000
    },
	{
        name = "🌈Cosmic Interplanetary",
        rebirths = 224, 
        boost = 22.4, 
        cost =3850900000000000000
    },
	{
        name = "🌈Chromaticist Interplanetary",
        rebirths = 225, 
        boost = 22.5, 
        cost =4050900000000000000
    },
	{
        name = "🏆Trident Hermit",
        rebirths = 226, 
        boost = 22.6, 
        cost =4250900000000000000
    },
	{
        name = "🌈Chromaticist Hermit",
        rebirths = 227, 
        boost = 22.7, 
        cost =4450900000000000000
    },
	{
        name = "👾Interplanetary Hermit",
        rebirths = 228, 
        boost = 22.8, 
        cost =4750900000000000000
    },
	{
        name = "👽Cosmic Hermit",
        rebirths = 229, 
        boost = 22.9, 
        cost =5550900000000000000
    },
	{
        name = "👽Alien Hermit",
        rebirths = 230, 
        boost = 23.0, 
        cost =6050900000000000000
    },
	{
        name = "🧊Ice Hermit",
        rebirths = 231, 
        boost = 23.1, 
        cost =6550900000000000000
    },
	{
        name = "🎣Atlantic",
        rebirths = 232, 
        boost = 23.2, 
        cost =7050900000000000000
    },
	{
        name = "🎣🧊Atlantic Icer",
        rebirths = 233, 
        boost = 23.3, 
        cost =7550900000000000000
    },
	{
        name = "🧸🧊Teddy Icer",
        rebirths = 234, 
        boost = 23.4, 
        cost =8050900000000000000
    },
	{
        name = "🧊Chromaticist Icer",
        rebirths = 235, 
        boost = 23.5, 
        cost =8550900000000000000
	},
	{
        name = "🎣Chromaticist Polar",
        rebirths = 236, 
        boost = 23.6, 
        cost =9050900000000000000
    },
	{
        name = "🧊Atlantict Polar",
        rebirths = 237, 
        boost = 23.7, 
        cost =9550900000000000000
    },
	{
        name = "🧸Susht Polar",
        rebirths = 238, 
        boost = 23.8, 
        cost =10000000000000000000
    },
	{
        name = "🧸🧊Teddy Polar",
        rebirths = 239, 
        boost = 23.9, 
        cost =11000000000000000000
    },
	{
        name = "✨Polar Yeti",
        rebirths = 240, 
        boost = 24.0, 
        cost =12000000000000000000 
	},

}

RebirthPresets.Tier = {
	[0] = "🥋Beginner",
	[10] = "🔰Newbie",
	[20] = "🤙Apprentice",
	[30] = "✨Expert",
	[40] = "😎Super Expert",
	[50] = "🥸Master",
	[60] = "✨Grand Master",
	[70] = "👍Giant Master",
	[80] = "🔥Overlord",
	[90] = "😊Farmer",
	[100] = "✨Blacksmith",
	[110] = "💫Knight",
	[120] = "🤙Emperor",
	[130] = "🟦Rare Emperor",
	[140] = "🟨Legendary Emperor",
	[150] = "😎Supreme"
}

for i = 1, 180 do
	RebirthPresets.Tier[i-1] = tiers[i].name
    if not RebirthPresets.RebirthConfig[i] then
        RebirthPresets.RebirthConfig[i] = {
            cost = math.ceil(RebirthPresets.RebirthConfig[i-1].cost * 1.5),
            -- cost = 1,
            boost = 0.25 * i,
        }
    end
end

return RebirthPresets