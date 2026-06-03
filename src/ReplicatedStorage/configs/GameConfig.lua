local RunService = game:GetService("RunService")
local GameConfig = {}

GameConfig.Version = "1.0.0"
GameConfig.UpdateLog = {
	"🆕 Release",
	"🌈 Weather",
	"🦌 More Animals",
	"🐛 BUG FIXES",
}

local IsDebug = false
GameConfig.isAlphaTest = false
GameConfig.IsDebug = RunService:IsStudio() and IsDebug

GameConfig.GroupId = 679281254 -- Beginning-of-Autumn
-- GameConfig.PlaceId = 17741821256
GameConfig.UniverseId = 8561877500
GameConfig.DevIds = {
	4944693071, -- magical hailuo
	3623697024, -- M78zhaoritian,
	-- 4631902816, -- shiiroko3
	4631899833, -- WholivesinPineApple
	5094307463, -- tuomasi66,
	5082471624, -- Naive_330
	7123548993, -- jacz20202020
	-1,
	-2,
	-3,
}
if RunService:IsServer() then
	local HttpService = game:GetService("HttpService")
	GameConfig.SessionId = HttpService:GenerateGUID()
end

GameConfig.HalfMinute = 30
GameConfig.OneMinute = GameConfig.HalfMinute * 2
GameConfig.HalfHour = GameConfig.OneMinute * 30
GameConfig.OneHour = GameConfig.OneMinute * 60
GameConfig.OneDay = GameConfig.OneHour * 24
GameConfig.OneWeek = GameConfig.OneDay * 7

if GameConfig.IsDebug then
	GameConfig.HalfMinute = 30
	GameConfig.OneMinute = GameConfig.HalfMinute * 2
	GameConfig.HalfHour = GameConfig.OneMinute * 30
	GameConfig.OneHour = GameConfig.OneMinute * 60
	GameConfig.OneDay = GameConfig.OneHour * 24
	GameConfig.OneWeek = GameConfig.OneDay * 7
end

GameConfig.Badges = {
	-- badge_welcome.svg
	Welcome = 1293604984146103,

	-- badge_destroy_block_*.svg（销毁方块里程碑）
	DestroyBlock1 = 2353656779340565,
	DestroyBlock5 = 451081708764474,
	DestroyBlock20 = 33607853035585,
	DestroyBlock50 = 2420157130227766,
	DestroyBlock100 = 1468264698799823,
	DestroyBlock200 = 3273560348665284,
	DestroyBlock400 = 1023214468970097,
	DestroyBlock800 = 2845104107159379,
	DestroyBlock2000 = 320083438883218,
	DestroyBlock5000 = 3543704178962407,
	DestroyBlock10000 = 1251032300609184,

	-- badge_forge_*.svg（锻造次数里程碑）
	ForgeCount1 = 104493899705065,
	ForgeCount3 = 3787326171324080,
	ForgeCount10 = 743101415284290,
	ForgeCount30 = 826760989537673,
	ForgeCount70 = 392648984756506,
	ForgeCount150 = 1759769446169848,
	ForgeCount300 = 1358854449233637,
}

GameConfig.Zones = {
	-- [1] = {
	-- 	name = "Spawn",
	-- 	boxes = {
	-- 		"🐊 Croc",
	-- 		"🦓 Zebra",
	-- 		"🦌 Impala",
	-- 	},
	-- 	-- badgeId = 759452591988166,
	-- },
	-- [2] = {
	-- 	name = "Desert",
	-- 	boxes = {
	-- 		"🐦 Ostrich",
	-- 		"🐶 Wild Dog",
	-- 	},
	-- 	-- badgeId = 3323207466446988,
	-- },
	-- [3] = {
	-- 	name = "Cave",
	-- 	boxes = {
	-- 		"Shiny Machine",
	-- 	},
	-- 	-- badgeId = 3323207466446988,
	-- },
}

GameConfig.ZoneCount = #GameConfig.Zones

GameConfig.FlipACoin = {
	SeatCount = 8,
	AfkKickSeconds = 120,
	AnnouncementStreaks = { 4, 6, 8, 10 },
	BaseHeadsChance = 0.30,
	MaxHeadsChance = 0.60,
	BaseReward = 10,
	BaseTailsReward = 2,
	BaseFlipInterval = 1.60,
	MinFlipInterval = 0.85,
	ValueGrowth = 1.28,
	ComboBaseStep = 0.25,
	ComboStepPerLevel = 0.06,
	SpeedDecay = 0.95,
	BiasStep = 0.025,
	CoinCountByLevel = {
		{ minLevel = 0, count = 1 },
		{ minLevel = 1, count = 2 },
		{ minLevel = 2, count = 3 },
		{ minLevel = 3, count = 4 },
		{ minLevel = 4, count = 5 },
	},
	SuccessThresholdByCoinCount = {
		[1] = 1,
		[2] = 1,
		[3] = 2,
		[4] = 2,
		[5] = 3,
	},
	ComboMultiplierByHeadsCount = {
		[0] = 0,
		[1] = 1,
		[2] = 1.2,
		[3] = 1.75,
		[4] = 2.6,
		[5] = 4,
	},
	ComboNamesByHeadsCount = {
		[0] = "No Heads",
		[1] = "Heads",
		[2] = "Pair",
		[3] = "Triple",
		[4] = "Four Heads",
		[5] = "Jackpot",
	},
	FirstRebirthAssist = {
		BaseBonus = 0.07,
		TailsBonusStep = 0.04,
		MaxHeadsChance = 0.45,
	},
	BadLuckPity = {
		FailureThreshold = 3,
		ChanceBonusStep = 0.05,
		MaxChanceBonus = 0.18,
		MaxHeadsChance = 0.55,
	},
	EdgeStand = {
		FailureStreakMinimum = 2,
		BaseChance = 0.015,
		PityChanceBonus = 0.08,
		MaxChance = 0.12,
		BonusReward = 8,
	},
	TableJackpot = {
		CoinCount = 5,
		HeadsCount = 5,
		AudienceReward = 15,
		NotificationDuration = 2.8,
	},
	ProfileXp = {
		BasePerFlip = 2,
		PerHead = 2,
		RoundSuccessBonus = 3,
		PerfectBonus = 4,
		JackpotBonus = 6,
		MaxPerFlip = 24,
	},
	DailyGoals = {
		{
			id = "flip10",
			displayName = "Flip 10 times",
			metric = "flips",
			target = 10,
			reward = 30,
		},
		{
			id = "heads15",
			displayName = "Flip 15 Heads",
			metric = "heads",
			target = 15,
			reward = 60,
		},
		{
			id = "streak3",
			displayName = "Reach a 3 streak",
			metric = "streak",
			target = 3,
			reward = 75,
		},
	},
	UpgradeConfigs = {
		valueLevel = {
			displayName = "Value",
			costBase = 12,
			costGrowth = 1.48,
			maxLevel = 18,
		},
		comboLevel = {
			displayName = "Combo",
			costBase = 18,
			costGrowth = 1.52,
			maxLevel = 12,
		},
		speedLevel = {
			displayName = "Speed",
			costBase = 20,
			costGrowth = 1.55,
			maxLevel = 10,
		},
		biasLevel = {
			displayName = "Luck",
			costBase = 28,
			costGrowth = 1.58,
			maxLevel = 12,
		},
	},
}

GameConfig.RarityNames = {
	Common = "Common",
	Uncommon = "Uncommon",
	Rare = "Rare",
	Epic = "Epic",
	Legendary = "Legendary",
	Mythic = "Mythic",
	Omega = "Omega",

	Normal = "Normal",
	Shiny = "Shiny",
	Golden = "Golden",
	Void = "Void",

	Huge = "Huge",
	["Huge/Shiny"] = "Huge/Shiny",
	["Huge/Golden"] = "Huge/Golden",

	Giant = "Giant",
	["Giant/Shiny"] = "Giant/Shiny",
	["Giant/Golden"] = "Giant/Golden",
}

GameConfig.FakePlayer = {
	Character = {
		Humanoid = {
			WalkSpeed = 16,
		},
		HumanoidRootPart = "",
	},
	UserId = 0,
	Name = "FakePlayer",
}

return GameConfig
