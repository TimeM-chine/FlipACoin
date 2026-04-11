local CharacterPresets = {}

CharacterPresets.Characters = {
	["Angel"] = {
		skills = { "Skill1" },
		basePower = 50,
		attackType = "Punch",
		rarity = "Common", -- just for display
	},
	["Assassins"] = {
		skills = { "Skill1" },
		basePower = 50,
		attackType = "Punch",
	},
	["Atomic Samurai"] = {
		skills = { "Skill1" },
		basePower = 50,
		attackType = "Sword",
	},
	["Baryon"] = {
		skills = { "Skill1" },
		basePower = 50,
		attackType = "Punch",
	},
	["Beerus"] = {
		skills = { "Skill1" },
		basePower = 50,
		attackType = "Punch",
	},
	["Boros4"] = {
		skills = { "Skill1" },
		basePower = 50,
		attackType = "Punch",
	},
}

CharacterPresets.CharactersByRarity = {
	Common = {
		["Angel"] = 65,
	},
	Uncommon = {
		["Assassins"] = 10,
	},
	Rare = {
		["Atomic Samurai"] = 10,
	},
	Epic = {
		["Baryon"] = 10,
	},
	Legendary = {
		["Beerus"] = 10,
	},
	Mythic = {
		["Boros4"] = 10,
	},
}

for rarity, Characters in CharacterPresets.CharactersByRarity do
	for name, weight in Characters do
		CharacterPresets.Characters[name].rarity = rarity
	end
end

return CharacterPresets
