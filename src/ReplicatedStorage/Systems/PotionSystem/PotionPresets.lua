local PotionPresets = {}

PotionPresets.Potions = {
	adCash2x5m = {
		displayName = "2x Cash Ad Boost",
		buffName = "cash2x",
		duration = 300,
		source = "ad",
	},
	paidCash2x10m = {
		displayName = "2x Cash Boost",
		buffName = "cash2x",
		duration = 600,
		source = "product",
	},
}

PotionPresets.FakePotions = {
	vip = {
		icon = "rbxassetid://14526160119",
	},
}

return PotionPresets
