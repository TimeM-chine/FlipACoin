local Presets = {}

Presets.DebounceSeconds = 0.75

Presets.NotificationDuration = 2.6
Presets.NotificationColor = Color3.fromRGB(255, 231, 163)
Presets.MinBestStreakAnnouncement = 5

Presets.StreakEffects = {
	[3] = {
		sfx = "streak3",
		vfx = "streak3",
		cameraShake = false,
	},
	[5] = {
		sfx = "streak5",
		vfx = "streak5",
		cameraShake = false,
	},
	[10] = {
		sfx = "streak10",
		vfx = "streak10",
		cameraShake = {
			duration = 0.42,
			amplitude = 0.18,
			frequency = 22,
			rotation = 1.2,
			fadeOut = true,
		},
	},
	[20] = {
		sfx = "streak20",
		vfx = "streak20",
		cameraShake = {
			duration = 0.5,
			amplitude = 0.22,
			frequency = 24,
			rotation = 1.5,
			fadeOut = true,
		},
	},
}

Presets.BestStreakEffect = {
	sfx = "bestStreak",
	vfx = "bestStreak",
	cameraShake = false,
}

Presets.ComboEffects = {
	triple = {
		sfx = "streak3",
		vfx = "streak3",
		cameraShake = false,
		announce = false,
	},
	fourHeads = {
		sfx = "streak5",
		vfx = "streak5",
		cameraShake = false,
		announce = false,
	},
	perfect = {
		sfx = "streak5",
		vfx = "streak5",
		cameraShake = {
			duration = 0.28,
			amplitude = 0.1,
			frequency = 18,
			rotation = 0.55,
			fadeOut = true,
		},
		announce = false,
	},
	jackpot = {
		sfx = "bestStreak",
		vfx = "bestStreak",
		cameraShake = {
			duration = 0.36,
			amplitude = 0.14,
			frequency = 20,
			rotation = 0.85,
			fadeOut = true,
		},
		announce = true,
	},
}

function Presets.BuildText(player, streak)
	return `{player.DisplayName} hit {streak} successful flips in a row!`
end

function Presets.BuildBestStreakText(player, streak)
	return `{player.DisplayName} set a new round streak: {streak}!`
end

function Presets.BuildComboText(player, args)
	return `{player.DisplayName} hit {args.comboName}: {args.headsCount}/{args.coinCount} Heads!`
end

return Presets
