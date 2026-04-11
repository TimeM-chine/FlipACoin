local TrailPresets = {}

function TrailPresets.getAllTrails()

	local allTrailsInfo = {}

	for _, trail in pairs(TrailPresets.TrailList) do
		table.insert(allTrailsInfo, trail)
	end

	-- sort by cost
	table.sort(allTrailsInfo, function(a, b)
		return a.cost < b.cost
	end)

	return allTrailsInfo
end

TrailPresets.PremiumBoost = 2

TrailPresets.Trails = {
	White = {
		name = "White",
		cost = 10,
		size = 1,
		length = 15,
		speedBoost = 1,
        info = {
            "Speed Boost: 1%",
        }
	},
	Blue = {
		name = "Blue",
		cost = 150,
		size = 1,
		length = 20,
		speedBoost = 2.5,
        info = {
            "Speed Boost: 2.5%",
        }
	},
	Green = {
		name = "Green",
		cost = 500,
		size = 1,
		length = 25,
		speedBoost = 5,
        info = {
            "Speed Boost: 5%",
        }
	},
	Yellow = {
		name = "Yellow",
		cost = 1000,
		size = 1,
		length = 25,
		speedBoost = 6,
        info = {
            "Speed Boost: 6%",
        }
	},
	Red = {
		name = "Red",
		cost = 8000,
		size = 1,
		length = 25,
		speedBoost = 8,
        info = {
            "Speed Boost: 8%",
        }
	},
	Midnight = {
		name = "Midnight",
		cost = 20_000,
		size = 1,
		length = 25,
		speedBoost = 9.5,
        info = {
            "Speed Boost: 9.5%",
        }
	},
	Sunset = {
		name = "Sunset",
		cost = 75_000,
		size = 1,
		length = 25,
		speedBoost = 12.5,
        info = {
            "Speed Boost: 12.5%",
        }
	},
	Galaxy = {
		name = "Galaxy",
		cost = 200_000,
		size = 1,
		length = 25,
		speedBoost = 17.5,
        info = {
            "Speed Boost: 17.5%",
        }
	},
	Zebra = {
		name = "Zebra",
		cost = 500_000,
		size = 1,
		length = 25,
		speedBoost = 22.5,
        info = {
            "Speed Boost: 22.5%",
        }
	},
	Siren = {
		name = "Siren",
		cost = 1_200_000,
		size = 1,
		length = 25,
		speedBoost = 30,
        info = {
            "Speed Boost: 30%",
        }
	},
	Retro = {
		name = "Retro",
		cost = 5_000_000,
		size = 1,
		length = 25,
		speedBoost = 35,
        info = {
            "Speed Boost: 35%",
        }
	},
	Money = {
		name = "Money",
		cost = 20_000_000,
		size = 3,
		length = 25,
		speedBoost = 43,
        info = {
            "Speed Boost: 43%",
        }
	},
	Sky = {
		name = "Sky",
		cost = 50_000_000,
		size = 1,
		length = 25,
		speedBoost = 50,
        info = {
            "Speed Boost: 50%",
        }
	},
	Laser = {
		name = "Laser",
		cost =  100_000_000,
		size = 1,
		length = 25,
		speedBoost = 57,
        info = {
            "Speed Boost: 57%",
        }
	},
	Rainbow = {
		name = "Rainbow",
		cost = 300_000_000,
		size = 1,
		length = 25,
		speedBoost = 64,
        info = {
            "Speed Boost: 64%",
        }
	},
	Golden = {
		name = "Golden",
		cost = 800_000_000,
		size = 1,
		length = 25,
		speedBoost = 70,
        info = {
            "Speed Boost: 70%",
        }
	},
	Pink = {
		name = "Pink",
		cost = 1_750_000_000,
		size = 1,
		length = 25,
		speedBoost = 77,
        info = {
            "Speed Boost: 77%",
        }
	},
}

return TrailPresets