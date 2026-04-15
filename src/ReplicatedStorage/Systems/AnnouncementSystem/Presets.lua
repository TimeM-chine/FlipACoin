local Presets = {}

Presets.DebounceSeconds = 0.75

Presets.Thresholds = {
	[4] = {
		tier = "4",
		color = Color3.fromRGB(198, 235, 255),
		strokeColor = Color3.fromRGB(114, 190, 255),
		duration = 2.1,
		bannerText = "Warm Up",
		soundName = "streak3",
	},
	[6] = {
		tier = "6",
		color = Color3.fromRGB(170, 255, 190),
		strokeColor = Color3.fromRGB(70, 212, 122),
		duration = 2.35,
		bannerText = "Heating Up",
		soundName = "streak5",
	},
	[8] = {
		tier = "8",
		color = Color3.fromRGB(255, 225, 120),
		strokeColor = Color3.fromRGB(255, 195, 61),
		duration = 2.6,
		bannerText = "On Fire",
		soundName = "streak7",
	},
	[10] = {
		tier = "10",
		color = Color3.fromRGB(255, 117, 117),
		strokeColor = Color3.fromRGB(255, 73, 73),
		duration = 3.2,
		bannerText = "Ten Heads",
		soundName = "streak10",
		isJackpot = true,
	},
}

function Presets.BuildText(player, streak)
	return `{player.DisplayName} hit {streak} heads in a row!`
end

return Presets
