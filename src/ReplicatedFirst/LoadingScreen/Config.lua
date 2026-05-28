local Replicated = game:GetService("ReplicatedStorage")

local Textures = require(Replicated:WaitForChild("configs"):WaitForChild("Textures"))

local config = {}

config.SkipUnlockProgress = 0.5
config.MinimumDuration = 5
config.MaximumDuration = 10
config.LoadingScreenImages = {
	"rbxassetid://87703843792466",
	"rbxassetid://5587865193",
}

config.ImageAssets = {}

local seenAssets = {}

local function addImageAsset(assetId)
	if assetId == nil or assetId == "" or seenAssets[assetId] then
		return
	end

	seenAssets[assetId] = true
	table.insert(config.ImageAssets, assetId)
end

for _, assetId in config.LoadingScreenImages do
	addImageAsset(assetId)
end

for _, fallbackConfig in Textures.FlipACoinItems.fallback do
	addImageAsset(fallbackConfig.icon)
end

for _, categoryConfig in Textures.FlipACoinItems.coin do
	addImageAsset(categoryConfig.icon)
end

for _, categoryConfig in Textures.FlipACoinItems.desk do
	addImageAsset(categoryConfig.icon)
end

for _, categoryConfig in Textures.FlipACoinItems.chair do
	addImageAsset(categoryConfig.icon)
end

for _, categoryConfig in Textures.FlipACoinItems.product do
	addImageAsset(categoryConfig.icon)
end

for _, categoryConfig in Textures.FlipACoinItems.gamePass do
	addImageAsset(categoryConfig.icon)
end

return config
