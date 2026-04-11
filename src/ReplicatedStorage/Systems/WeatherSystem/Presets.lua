local Replicated = game:GetService("ReplicatedStorage")
local GameConfig = require(Replicated.configs.GameConfig)
local Keys = require(Replicated.configs.Keys)

local WeatherPresets = {}

WeatherPresets.TRANSITION_SPEED = 5
WeatherPresets.PARTICLE_DELAY = 1
WeatherPresets.DefaultDuration = GameConfig.OneMinute * 5

WeatherPresets.WeatherList = {
	Normal = {
		duration = GameConfig.OneMinute * 3,
		color = Color3.fromRGB(169, 157, 157),
		name = "Normal",
		chance = 40,
		buffs = {},
	},
	-- Cloudy = {
	--     color = Color3.fromRGB(91, 198, 250),
	--     name = "Cloudy",
	--     chance = 28,
	--     boost = {
	--         {
	--             itemType = GameSetting.ItemType.RollLuck,
	--             boost = 5,
	--         },
	--         {
	--             itemType = GameSetting.ItemType.RollSpeed,
	--             boost = 0.1,
	--         },
	--     }
	-- },
	-- Hazy = {
	--     color = Color3.fromRGB(185, 118, 207),
	--     name = "Hazy",
	--     chance = 22,
	--     boost = {
	--         {
	--             itemType = GameSetting.ItemType.RollLuck,
	--             boost = 10,
	--         },
	--         {
	--             itemType = GameSetting.ItemType.RollSpeed,
	--             boost = 0.1,
	--         },
	--     }
	-- },
	Rainy = {
		duration = GameConfig.OneMinute * 3,
		color = Color3.fromRGB(128, 194, 205),
		name = "Rain",
		chance = 20,
		buffs = {},
	},
	Snowy = {
		duration = GameConfig.OneMinute * 3,
		color = Color3.fromRGB(252, 249, 249),
		name = "Snow",
		chance = 40,
		buffs = {},
		tags = {
			snow = 0.25,
		},
	},
	Desert = {
		duration = GameConfig.OneMinute * 3,
		color = Color3.fromRGB(255, 165, 0),
		name = "Sandstorm",
		chance = 5,
		buffs = {},
		tags = {
			Sandstorm = 0.25,
		},
	},
	Stormy = {
		duration = GameConfig.OneMinute * 3,
		color = Color3.fromRGB(151, 59, 36),
		name = "Tempest",
		chance = 20,
		buffs = {},
		tags = {
			Stormy = 0.25,
		},
	},

	Universe = {
		duration = GameConfig.OneMinute * 3,
		color = Color3.fromRGB(74, 52, 244),
		name = "Universe",
		chance = 5,
		buffs = {},
		tags = {
			Universe = 0.25,
		},
	},
	Meteor = {
		duration = GameConfig.OneMinute * 3,
		color = Color3.fromRGB(255, 0, 0),
		name = "Meteor",
		chance = 2,
		buffs = {},
		tags = {
			Meteor = 0.25,
		},
	},

	-- Green = {
	--     color = Color3.fromRGB(0, 255, 0),
	--     name = "Green",
	--     chance = 25,
	--     boost = {
	--         {
	--             itemType = GameSetting.ItemType.RollLuck,
	--             boost = 20,
	--         },
	--         {
	--             itemType = GameSetting.ItemType.RollSpeed,
	--             boost = 0.3,
	--         },
	--     }
	-- },
	-- Blue = {
	--     color = Color3.fromRGB(0, 0, 255),
	--     name = "Blue",
	--     chance = 25,
	--     boost = {
	--         {
	--             itemType = GameSetting.ItemType.RollLuck,
	--             boost = 20,
	--         },
	--         {
	--             itemType = GameSetting.ItemType.RollSpeed,
	--             boost = 0.3,
	--         },
	--     }
	-- },
}

for _, weather in pairs(WeatherPresets.WeatherList) do
	weather.duration = weather.duration or WeatherPresets.DefaultDuration
end

return WeatherPresets
