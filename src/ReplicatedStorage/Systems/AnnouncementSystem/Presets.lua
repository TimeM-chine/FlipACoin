local Presets = {}

Presets.DebounceSeconds = 0.75

Presets.Thresholds = {
	[3] = {
		tier = "3",
		color = Color3.fromRGB(198, 235, 255),
	},
	[5] = {
		tier = "5",
		color = Color3.fromRGB(170, 255, 190),
	},
	[7] = {
		tier = "7",
		color = Color3.fromRGB(255, 225, 120),
	},
	[9] = {
		tier = "9",
		color = Color3.fromRGB(255, 179, 102),
	},
	[10] = {
		tier = "10",
		color = Color3.fromRGB(255, 117, 117),
	},
}

function Presets.BuildText(player, streak)
	return `{player.DisplayName} hit {streak} heads in a row!`
end

return Presets
