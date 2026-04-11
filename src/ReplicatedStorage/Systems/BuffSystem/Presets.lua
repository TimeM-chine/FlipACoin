local BuffPresets = {}

BuffPresets.Buffs = {
	friend = {
		boostType = "wins",
		boost = 0.1,
	},
	premium = {
		boostType = "wins",
		boost = 0.2,
	},
	group = {
		boostType = "damage",
		boost = 0.1,
		tip = "Join group to get 10% damage boost",
	},
	lucky1 = {
		boostType = "lucky",
		boost = 0.75,
		tip = "Luck +75%",
	},
	lucky2 = {
		boostType = "lucky",
		boost = 2,
		tip = "Luck +200%",
	},
	wins1 = {
		boostType = "wins",
		boost = 1.5,
		tip = "Cash collect +150%",
	},
}

return BuffPresets
