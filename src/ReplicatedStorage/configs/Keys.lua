local Keys = {}

local errorOnNil = {
	__index = function(table, key)
		error("Attempt to access undefined key: " .. key)
	end,
}

Keys.DataKey = {
	---- user info ----
	playTime = "playTime",
	loginTime = "loginTime",
	startTimes = "startTimes",
	createTime = "createTime",
	buyStartPack = "buyStartPack",
	claimFreeReward = "claimFreeReward",
	favoritePrompt = "favoritePrompt",
	---- attributes ----
	robuxSpent = "robuxSpent",
	rebirth = "rebirth",
	fateShards = "fateShards",
	destroyBlock = "destroyBlock",
	forgeCount = "forgeCount",
	bestStreak = "bestStreak",
	lifetimeFlips = "lifetimeFlips",
	lifetimeHeads = "lifetimeHeads",
	lifetimeCashEarned = "lifetimeCashEarned",
	---- currency ---
	wins = "wins",
	gems = "gems",
	redeemCode = "redeemCode",
	donated = "donated",
	---- game ----
	badges = "badges",
	level = "level",
	exp = "exp",
	onboardingFunnelStep = "onboardingFunnelStep",
	blockCarried = "blockCarried",
	blockPackLevel = "blockPackLevel",
	levelUnlock = "levelUnlock",
	likeMe = "likeMe",
	maxZone = "maxZone",
	nowZone = "nowZone",
	trails = "trails",
	trailEquipped = "trailEquipped",
	spin = "spin",
	waitingSpinTime = "waitingSpinTime",
	settingsData = "settingsData",
	buffs = "buffs",
	guideData = "guideData",
	backpack = "backpack",
	potions = "potions",
	equippedBuff = "equippedBuff",
	dailyClaim = "dailyClaim",
	groupClaim = "groupClaim",
	season = "season",
	event = "event",
	calendar = "calendar",
	questPack = "questPack",
	quests = "quests",
	equippedCoin = "equippedCoin",
	ownedCoins = "ownedCoins",
	rebirthTree = "rebirthTree",
	autoFlipUnlocked = "autoFlipUnlocked",
	runData = "runData",
	---- game pass ----
	gamePasses = "gamePasses",
}

Keys.PetOperations = {
	AddNewPet = "AddNewPet",
	SellPet = "SellPet",
	EquipPet = "EquipPet",
	UnEquipPet = "UnEquipPet",
	EquipBest = "EquipBest",
	LockPet = "LockPet",
	UnlockPet = "UnlockPet",
}

Keys.BattleSates = {
	Waiting = "Waiting",
	Over = "Over",
	Battling = "Battling",
}

Keys.ItemType = {
	exp = "exp",
	wins = "wins",
	item = "item",
	spin = "spin",
	pet = "pet",
	power = "power",
	gamePass = "gamePass",
	potion = "potion",
	egg = "egg",
	eventEgg = "eventEgg",
	robux = "robux",
	petCarrySize = "petCarrySize",
	food = "food",
	equipment = "equipment",
	resource = "resource",
	character = "character",
	weapons = "weapons",
	ores = "ores",
}

Keys.CollisionGroup = {
	Player = "PlayerCollisionGroup",
	Demon = "DemonCollisionGroup",
	Bullet = "BulletCollisionGroup",
	Wall = "WallCollisionGroup",
	Pet = "PlayerCollisionGroup",
}

Keys.Tags = {
	Pet = "PetTag",
	Demon = "DemonTag",
	Weapon = "WeaponTag",
	AnimalCorpse = "AnimalCorpseTag",
	ToolTag = "ToolTag",
	VFX = "VFXTag",
}

Keys.PetStates = {
	Idle = "Idle",
	Dead = "Dead",
	Attacking = "Attacking",
}

Keys.QuestType = {
	online = "online",
	lifeTime = "lifeTime",
	getWins = "getWins",
	afterPeriod = "afterPeriod",
	useAnyPotion = "useAnyPotion",
	useNamedPotion = "useNamedPotion",
	collectAnyOre = "collectAnyOre",
	collectNamedOre = "collectNamedOre",
	digBlock = "digBlock",
	forge = "forge",
	enhance = "enhance",
	enchant = "enchant",
	equipWeapon = "equipWeapon",
}

Keys.Rarity = {
	Common = "Common",
	Uncommon = "Uncommon",
	Rare = "Rare",
	Epic = "Epic",
	Legendary = "Legendary",
	Mythic = "Mythic",
	Omega = "Omega",
}

Keys.Enchants = {
	Explosion = "Explosion",
	CoinBoost = "CoinBoost",
	CritRate = "CritRate",
	AttackSpeed = "AttackSpeed",
	Attack = "Attack",
	EnchantLuck = "EnchantLuck",
	Burn = "Burn",
	-- Legacy alias
	Speed = "AttackSpeed",
}
Keys.ForgeAttrs = {
	Attack = "Attack",
	AttackSpeed = "AttackSpeed",
	DamageRange = "DamageRange",
	CritRate = "CritRate",
	Explosion = "Explosion",
	Burn = "Burn",
	CoinBoost = "CoinBoost",
	EnchantLuck = "EnchantLuck",
}

Keys.WeaponTypes = {
	Pickaxe = "Pickaxe",
	Laser = "Laser",
	Bomb = "Bomb",
	BouncingBomb = "BouncingBomb",
	Drill = "Drill",
	OrbitingBoomerang = "OrbitingBoomerang",
}

Keys.ForgeColors = {
	-- Basic translated colors (used by ore presets)
	Gray = Color3.fromRGB(128, 128, 128),
	Black = Color3.fromRGB(0, 0, 0),
	OrangeRed = Color3.fromRGB(255, 100, 50),
	White = Color3.fromRGB(255, 255, 255),
	TranslucentWhite = Color3.fromRGB(200, 220, 255),
	Green = Color3.fromRGB(50, 205, 50),
	DeepBlue = Color3.fromRGB(25, 25, 112),
	BloodRed = Color3.fromRGB(139, 0, 0),
	DarkRed = Color3.fromRGB(100, 0, 0),
	PurpleBlack = Color3.fromRGB(40, 0, 60),
	Silver = Color3.fromRGB(220, 220, 220),
	BrightGold = Color3.fromRGB(255, 215, 0),

	GrayWhite = Color3.fromRGB(200, 200, 200),
	BlackMatte = Color3.fromRGB(30, 30, 30),
	OrangeRedMetallic = Color3.fromRGB(255, 100, 50),
	SilverGray = Color3.fromRGB(192, 192, 192),
	GrayWhiteRusty = Color3.fromRGB(180, 170, 160),
	BrightWhite = Color3.fromRGB(255, 255, 255),
	BrightYellow = Color3.fromRGB(255, 215, 0),
	SaltPepper = Color3.fromRGB(128, 128, 128),
	MilkyWhite = Color3.fromRGB(250, 250, 240),
	Transparent = Color3.fromRGB(200, 220, 255),
	EmeraldGreen = Color3.fromRGB(50, 205, 50),
	DeepBlueGoldStars = Color3.fromRGB(25, 25, 112),
	PureBlack = Color3.fromRGB(0, 0, 0),
	DeepRed = Color3.fromRGB(139, 0, 0),
	DarkGold = Color3.fromRGB(184, 134, 11),
	DarkRedPulsing = Color3.fromRGB(100, 0, 0),
	SilverStellar = Color3.fromRGB(220, 220, 220),
	FlowingMetalEnergy = Color3.fromRGB(138, 43, 226),
}

Keys.ForgeMaterials = {
	Plastic = Enum.Material.Plastic,
	Brick = Enum.Material.Brick,
	Neon = Enum.Material.Neon,
	Metal = Enum.Material.Metal,
	Foil = Enum.Material.Foil,
	Concrete = Enum.Material.Concrete,
	Wood = Enum.Material.Wood,
	Glass = Enum.Material.Glass,
	Fabric = Enum.Material.Fabric,
	Ice = Enum.Material.Ice,
	Glacier = Enum.Material.Glacier,
	Slate = Enum.Material.Slate,
	Granite = Enum.Material.Granite,
	Marble = Enum.Material.Marble,
	Basalt = Enum.Material.Basalt,
	Rock = Enum.Material.Rock,
	Sand = Enum.Material.Sand,
	Ground = Enum.Material.Ground,
	Snow = Enum.Material.Snow,
	Mud = Enum.Material.Mud,
	Grass = Enum.Material.Grass,
	Asphalt = Enum.Material.Asphalt,
	Salt = Enum.Material.Salt,
	Limestone = Enum.Material.Limestone,
	Pavement = Enum.Material.Pavement,
	Cobblestone = Enum.Material.Cobblestone,
	ForceField = Enum.Material.ForceField,
}

for _, t in pairs(Keys) do
	setmetatable(t, errorOnNil)
	table.freeze(t)
end

table.freeze(Keys)

return Keys
