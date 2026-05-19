local Replicated = game:GetService("ReplicatedStorage")
local PlayerPresets = {}

PlayerPresets.Levels = {}
local PlayerLevel = require(Replicated.ExcelConfig.PlayerLevel)
for _, level in PlayerLevel do
	PlayerPresets.Levels[level.levelId] = level
end

PlayerPresets.FakeUserIds = {
	4811108435,
	4126619853,
	1504566881,
	2264705988,
	2486328844,
	4569713631,
	4115108453,
	4112617557,
	3337104586,
	3523564575,
	4112556128,
	3685971753,
	4402877425,
	4402861743,
}

return PlayerPresets
