local Replicated = game:GetService("ReplicatedStorage")
local Keys = require(Replicated.configs.Keys)
local Textures = require(Replicated.configs.Textures)

local DoorPresets = {}

DoorPresets.UnlockCondition = {
	[1] = {
		cost = 0,
		itemType = Keys.ItemType.wins,
		icon = nil,
		hunterLevel = 0,
	},
	[2] = {
		cost = 10000,
		itemType = Keys.ItemType.wins,
		hunterLevel = 2,
	},
	[3] = {
		cost = 28_125_000,
		itemType = Keys.ItemType.wins,
		hunterLevel = 3,
	},
}

for _, config in DoorPresets.UnlockCondition do
	config.icon = Textures.UnclassifiedIcons[config.itemType]
end

return DoorPresets
