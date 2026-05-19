local Presets = {}

Presets.DebounceSeconds = 0.75

Presets.NotificationDuration = 2.6
Presets.NotificationColor = Color3.fromRGB(255, 231, 163)

Presets.StreakEffects = {
	[5] = {
		sfx = "streak1",
		vfx = "streak1",
		cameraShake = false,
	},
	[10] = {
		sfx = "streak2",
		vfx = "streak2",
		cameraShake = {
			duration = 0.42,
			amplitude = 0.18,
			frequency = 22,
			rotation = 1.2,
			fadeOut = true,
		},
	},
}

function Presets.BuildText(player, streak)
	return `{player.DisplayName} hit {streak} heads in a row!`
end

return Presets
