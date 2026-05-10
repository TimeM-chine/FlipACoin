local config = {}

config.gameIcon = ""

config.ResourceList = {
	Animation = {},
	Sound = {},
	Decal = {},
}

local Replicated = game:GetService("ReplicatedStorage")
local animationPresets =
	require(Replicated:WaitForChild("Systems"):WaitForChild("AnimateSystem"):WaitForChild("Presets"))
for _, animConfig in animationPresets.Animations.player do
	table.insert(config.ResourceList.Animation, animConfig.id)
end

local Textures = require(Replicated.configs.Textures)
for _, gp in Textures.GamePasses do
	table.insert(config.ResourceList.Decal, gp.icon)
end

for _, id in Textures.UnclassifiedIcons do
	table.insert(config.ResourceList.Decal, id)
end

for _, pt in Textures.Potions do
	table.insert(config.ResourceList.Decal, pt.icon)
end

for _, buff in Textures.Buffs do
	table.insert(config.ResourceList.Decal, buff.icon)
end

for _, zone in Textures.Zones do
	table.insert(config.ResourceList.Decal, zone.icon)
end

return config
