local Replicated = game:GetService("ReplicatedStorage")
local PlayerPresets = {}

PlayerPresets.Levels = {}
local PlayerLevel = require(Replicated.ExcelConfig.PlayerLevel)
for _, level in PlayerLevel do
	PlayerPresets.Levels[level.levelId] = level
end

return PlayerPresets
