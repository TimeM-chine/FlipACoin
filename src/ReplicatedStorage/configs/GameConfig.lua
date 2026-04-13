local RunService = game:GetService("RunService")
local GameConfig = {}

GameConfig.Version = "1.0.0"
GameConfig.UpdateLog = {
	"🆕 Release",
	"🌈 Weather",
	"🦌 More Animals",
	"🐛 BUG FIXES",
}

local IsDebug = true
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
	AfkKickSeconds = 90,
	AnnouncementStreaks = { 3, 5, 7, 9, 10 },
	BaseHeadsChance = 0.20,
	MaxHeadsChance = 0.60,
	BaseReward = 5,
	BaseFlipInterval = 1.80,
	MinFlipInterval = 0.75,
	ValueGrowth = 1.22,
	ComboBaseStep = 0.20,
	ComboStepPerLevel = 0.05,
	SpeedDecay = 0.93,
	BiasStep = 0.025,
	UpgradeConfigs = {
		valueLevel = {
			displayName = "Value",
			costBase = 10,
			costGrowth = 1.55,
			maxLevel = 20,
		},
		comboLevel = {
			displayName = "Combo",
			costBase = 20,
			costGrowth = 1.60,
			maxLevel = 15,
		},
		speedLevel = {
			displayName = "Speed",
			costBase = 25,
			costGrowth = 1.65,
			maxLevel = 12,
		},
		biasLevel = {
			displayName = "Bias",
			costBase = 40,
			costGrowth = 1.70,
			maxLevel = 16,
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
