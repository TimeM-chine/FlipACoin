local Replicated = game:GetService("ReplicatedStorage")
local GameConfig = require(Replicated.configs.GameConfig)
local Keys = require(Replicated.configs.Keys)
local Textures = require(Replicated.configs.Textures)

local SpinPresets = {}

SpinPresets.FreeSpinInterval = GameConfig.OneHour * 12

SpinPresets.Rewards = {
	[1] = {
		weight = 50,
		items = {
			{
				itemType = Keys.ItemType.wins,
				count = 100,
			},
		},
	},
	[2] = {
		weight = 30,
		items = {
			{
				itemType = Keys.ItemType.power,
				count = 200,
			},
		},
	},
	[3] = {
		weight = 10,
		items = {
			{
				itemType = Keys.ItemType.potion,
				name = "wins1Potion30",
				count = 2,
			},
		},
	},
	[4] = {
		weight = 10,
		items = {
			{
				itemType = Keys.ItemType.potion,
				name = "power1Potion30",
				count = 2,
			},
		},
	},
	[5] = {
		weight = 1,
		items = {
			{
				itemType = Keys.ItemType.pet,
				name = "Watermelon Winner",
				count = 1,
			},
		},
		icon = "rbxassetid://18363375309",
	},
}

local totalWeight = 0
for i = 1, 5 do
	totalWeight = totalWeight + SpinPresets.Rewards[i].weight
end
for i = 1, 5 do
	local config = SpinPresets.Rewards[i]
	config.weight = config.weight / totalWeight
	if not config.icon then
		config.icon = Textures.UnclassifiedIcons[config.items[1].itemType]
	end
end

return SpinPresets
