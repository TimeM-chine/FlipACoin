local MessagingService = game:GetService("MessagingService")
local Replicated = game:GetService("ReplicatedStorage")
local GameConfig = require(Replicated.configs.GameConfig)
local Keys = require(Replicated.configs.Keys)

local Textures = {}

Textures.Robux = "rbxassetid://11560341132"
Textures.Empty = "rbxassetid://15916240144"
Textures.DogPet = "rbxassetid://13068056439"

Textures.ButtonColors = {
	green = Color3.fromRGB(0, 255, 0),
	red = Color3.fromRGB(255, 38, 0),
	gray = Color3.fromRGB(128, 128, 128),
	golden = Color3.fromRGB(255, 215, 0),
	white = Color3.fromRGB(255, 255, 255),
	blue = Color3.fromRGB(12, 153, 245),
}

Textures.ItemTypes = {
	[Keys.ItemType.food] = "rbxassetid://17445487650",
	[Keys.ItemType.equipment] = "rbxassetid://17445487334",
	[Keys.ItemType.resource] = "rbxassetid://17445488063",
}

Textures.UnclassifiedIcons = {
	-- wins = "rbxassetid://17742088026",
	wins = "rbxassetid://119503428482490",
	exp = "rbxassetid://17553657803",
	spin = "rbxassetid://14526274898",
	power = "rbxassetid://17742084993",
	potionPack = "rbxassetid://17592340841",
	rebirth = "rbxassetid://12062624806",
	maxHp = "rbxassetid://16983636337",
	cash = "rbxassetid://119503428482490",
}

Textures.QuestTypeIcon = {
	-- [Keys.QuestType.hatchEgg] = {
	-- 	icon = "rbxassetid://13048949293",
	-- },
	-- [Keys.QuestType.battle] = {
	-- 	icon = "rbxassetid://17715965658",
	-- },
	-- [Keys.QuestType.hatchRarityPet] = {
	-- 	icon = "rbxassetid://14153408555",
	-- },
	-- [Keys.QuestType.rebirth] = {
	-- 	icon = "rbxassetid://13031264904",
	-- },
	-- [Keys.QuestType.defeatAnyBoss] = {
	-- 	icon = "rbxassetid://17715965658",
	-- },
}

Textures.GamePasses = {
	vip = {
		icon = "rbxassetid://13267287237",
	},
	winsX2 = {
		-- icon = "rbxassetid://13049234947",
		icon = "rbxassetid://104575988697906",
	},
	damageX2 = {
		icon = "rbxassetid://18664292092",
	},
	attackSpeedX2 = {
		icon = "rbxassetid://98819933823596",
	},
	digLucky = {
		icon = "rbxassetid://13104245207",
	},
	enchantLucky = {
		icon = "rbxassetid://13049291356",
	},
	-------
	trainPowerX2 = {
		icon = "rbxassetid://18664292092",
	},
	petCarry2 = {
		icon = "rbxassetid://18862379274",
	},
	petStorage100 = {
		icon = "rbxassetid://17269494828",
	},
	egg3 = {
		icon = "rbxassetid://13049324242",
	},
	egg8 = {
		icon = "rbxassetid://14603499811",
	},
	autoHatch = {
		icon = "rbxassetid://18862209251",
	},
	lucky1 = {
		icon = "rbxassetid://13104245207",
	},
	lucky2 = {
		icon = "rbxassetid://13049291356",
	},
	lucky3 = {
		icon = "rbxassetid://13778015091",
	},
	autoBattle = {
		icon = "rbxassetid://18664292488",
	},
	instantShinyMachine = {
		icon = "rbxassetid://107389423020483",
	},
	halfShinyMachine = {
		icon = "rbxassetid://86451755804919",
	},
	opClicker = {
		icon = "rbxassetid://98819933823596",
	},
	cashX2 = {
		icon = "rbxassetid://104575988697906",
	},
	lucky = {
		icon = "rbxassetid://13104245207",
	},
	fastRestock = {
		icon = "rbxassetid://86451755804919",
	},
}

Textures.RarityColor = {
	Default = Color3.fromRGB(234, 234, 234),
	DefaultBG = "rbxassetid://17222966646",
	DefaultGradient = "Gray",

	Common = Color3.fromRGB(234, 234, 234),
	CommonBG = "rbxassetid://17222966646",
	CommonGradient = "Gray",
	Uncommon = Color3.fromRGB(125, 229, 93),
	UncommonBG = "rbxassetid://17222966646", -- white
	UncommonGradient = "DarkGray",
	Rare = Color3.fromRGB(91, 198, 250),
	RareBG = "rbxassetid://17222967980", -- green
	RareGradient = "Green",
	Epic = Color3.fromRGB(185, 118, 207),
	EpicBG = "rbxassetid://17222968284", -- blue
	EpicGradient = "Blue",
	Legendary = Color3.fromRGB(255, 204, 0),
	LegendaryBG = "rbxassetid://17222968791", -- yellow
	LegendaryGradient = "Gold",
	Mythic = Color3.fromRGB(255, 51, 0),
	MythicBG = "rbxassetid://17222967649", -- red
	MythicGradient = "Red",
	-- ExcelConfig.Ores uses "Mythical"
	Mythical = Color3.fromRGB(255, 51, 0),
	MythicalBG = "rbxassetid://17222967649",
	MythicalGradient = "Red",
	Omega = Color3.fromRGB(31, 31, 31),
	OmegaBG = "rbxassetid://17222967108", -- purple
	OmegaGradient = "Purple",
	Exclusive = Color3.fromRGB(62, 72, 214),
	ExclusiveBG = "rbxassetid://17261388741", -- rainbow
	ExclusiveGradient = "Rainbow",

	Normal = Color3.fromRGB(216, 254, 255),

	Shiny = Color3.fromRGB(255, 152, 112),

	Golden = Color3.fromRGB(255, 209, 17),

	Void = Color3.fromRGB(9, 9, 9),

	Huge = Color3.fromRGB(194, 179, 66),

	["Huge/Shiny"] = Color3.fromRGB(194, 179, 66),
	["Huge/Golden"] = Color3.fromRGB(194, 179, 66),

	Giant = Color3.fromRGB(123, 0, 123),

	["Giant/Shiny"] = Color3.fromRGB(123, 0, 123),
	["Giant/Golden"] = Color3.fromRGB(123, 0, 123),
}

Textures.Cards = {
	-- Diamond Pack
	["Chimpanzini Spiderini"] = {
		icon = "rbxassetid://134612449273598",
	},
	["Odin Din Din Dun"] = {
		icon = "rbxassetid://89764279334240",
	},
	["Orcalero Orcala"] = {
		icon = "rbxassetid://97675796110521",
	},
	["Pipi Avocado"] = {
		icon = "rbxassetid://120928163483619",
	},
	["Rhino Toasterino"] = {
		icon = "rbxassetid://139697777733324",
	},

	-- Star Pack
	["Brr Brr Patapim"] = {
		icon = "rbxassetid://118795098758876",
	},
	["Chef Crabracadabra"] = {
		icon = "rbxassetid://98608320475548",
	},
	["Las Vaquitas Saturnitas"] = {
		icon = "rbxassetid://137339828917787",
	},
	["Los Pot Hotspotsitos dicen HOTSPOTT"] = {
		icon = "rbxassetid://124000329552417",
	},

	-- Peach Pack
	["Frigo Camelo"] = {
		icon = "rbxassetid://90913823475805",
	},
	["Girafa Celestre"] = {
		icon = "rbxassetid://118099616545989",
	},
	["Lionel Cactuseli"] = {
		icon = "rbxassetid://122989523839370",
	},
	["Pipi Kiwi"] = {
		icon = "rbxassetid://125267849488721",
	},

	-- Rose Pack
	["Bambini Crostini"] = {
		icon = "rbxassetid://136921957021389",
	},
	["Bananita Dolphinita"] = {
		icon = "rbxassetid://105818360144667",
	},
	["Los Tungtungtungcitos"] = {
		icon = "rbxassetid://121789815570678",
	},
	["Trippi Troppi Troppa Trippa"] = {
		icon = "rbxassetid://115436049530503",
	},

	-- Blue Gem Pack
	["Chimpanzini Bananini"] = {
		icon = "rbxassetid://118153641974433",
	},
	["Gangster Footera"] = {
		icon = "rbxassetid://121774288778416",
	},
	["Garama and Madundung"] = {
		icon = "rbxassetid://140581449206923",
	},
	["Graipuss Medussi"] = {
		icon = "rbxassetid://95967871244642",
	},

	-- Purple Symbol Pack
	["Pipi Corni"] = {
		icon = "rbxassetid://88777123274610",
	},
	["Salamino Penguino"] = {
		icon = "rbxassetid://82057221088162",
	},
	["Statutino Libertino"] = {
		icon = "rbxassetid://134218120499773",
	},
	["Unclito Samito"] = {
		icon = "rbxassetid://82672325459949",
	},

	-- Red Apple Pack
	["Ballerino Lololo"] = {
		icon = "rbxassetid://114736423763917",
	},
	["La Grande Combinasion"] = {
		icon = "rbxassetid://138719178731623",
	},
	["Penguino Cocosino"] = {
		icon = "rbxassetid://132791137744264",
	},
	["Tric Trac Baraboom"] = {
		icon = "rbxassetid://134284245475892",
	},

	-- Frosty Pattern Pack
	["Ballerina Cappuccina"] = {
		icon = "rbxassetid://138647829190347",
	},
	["Ganganzelli Trulala"] = {
		icon = "rbxassetid://130190914978206",
	},
	["Spioniro Golubiro"] = {
		icon = "rbxassetid://103880464171159",
	},
	["Tung Tung Tung Sahur"] = {
		icon = "rbxassetid://114991150824792",
	},

	-- Funky Face Pack
	["Cappuccino Assassino"] = {
		icon = "rbxassetid://91711991965611",
	},
	["Dragon Cannelloni"] = {
		icon = "rbxassetid://136419500215407",
	},
	["Los Crocodillitos"] = {
		icon = "rbxassetid://89355218176461",
	},
	["Trippi Troppi"] = {
		icon = "rbxassetid://122485071841352",
	},

	-- Crown Pack
	["Los Ta ta Tasitos dicen Sahur"] = {
		icon = "rbxassetid://76178898843013",
	},
	["Tigrilini Watermelini"] = {
		icon = "rbxassetid://119364723650703",
	},
	["Torrtuginni Dragonfrutini"] = {
		icon = "rbxassetid://89880895600008",
	},
	["Zibra Zubra Zibralini"] = {
		icon = "rbxassetid://107617082465723",
	},

	-- Skull Pack
	["Cocosini Mama"] = {
		icon = "rbxassetid://87025643686787",
	},
	["La Vacca Saturno Saturnita"] = {
		icon = "rbxassetid://106864906304946",
	},
	["Los Mateositos dicen MATEOO"] = {
		icon = "rbxassetid://86741924837607",
	},
	["Orangutini Ananassini"] = {
		icon = "rbxassetid://109961091262653",
	},

	-- Dark Orb Pack
	["Pandaccini Bananini"] = {
		icon = "rbxassetid://122588903245475",
	},
	["Piccione Macchina"] = {
		icon = "rbxassetid://127282325337981",
	},
	["Pot Hotspot"] = {
		icon = "rbxassetid://90134983023728",
	},
	["Trenostruzzo Turbo 3000"] = {
		icon = "rbxassetid://71717893538516",
	},

	-- Pentagram Black Pack
	["Brri Brri Bicus Dicus Bombicus"] = {
		icon = "rbxassetid://125900305804604",
	},
	["Ta Ta Ta Ta Sahur"] = {
		icon = "rbxassetid://90523845064004",
	},
	["Ti Ti Ti Sahur"] = {
		icon = "rbxassetid://104061813532733",
	},
	["Tralalero Tralala"] = {
		icon = "rbxassetid://108255414500487",
	},

	-- Pentagram Gold Pack
	["Bombardiro Crocodilo"] = {
		icon = "rbxassetid://109816725749995",
	},
	["Burbaloni Loliloli"] = {
		icon = "rbxassetid://95015093750666",
	},
	["Espresso Signora"] = {
		icon = "rbxassetid://115933528597501",
	},
	["Las Tralaleritas"] = {
		icon = "rbxassetid://132656270921840",
	},

	-- Ice Crystal Pack
	["Bombombini Gusini"] = {
		icon = "rbxassetid://118216932156431",
	},
	["Lirilì Larilà"] = {
		icon = "rbxassetid://110162337485142",
	},
	["Sigma Boy"] = {
		icon = "rbxassetid://99164325925123",
	},
	["Tigroligre Frutonni"] = {
		icon = "rbxassetid://109267846409542",
	},

	-- Blue Sphere Pack
	["Gorillo Watermelondrillo"] = {
		icon = "rbxassetid://80369405698830",
	},
	["Los Garama And Madungdu...tos dicen GARAM AND MADU"] = {
		icon = "rbxassetid://99662744262334",
	},
	["Strawberrelli Flamingelli"] = {
		icon = "rbxassetid://135300797027395",
	},
	["Tukanno Bananno"] = {
		icon = "rbxassetid://130067294608984",
	},

	-- Orange Flame Pack
	["Boneca Ambalabu"] = {
		icon = "rbxassetid://122159368103989",
	},
	["Chicleteira Bicicleteira"] = {
		icon = "rbxassetid://114216515771422",
	},
	["Los Boneca Ambalabusitos dicen AMBALABUU"] = {
		icon = "rbxassetid://93403032308356",
	},
	["Talpa Di Fero"] = {
		icon = "rbxassetid://75638525447500",
	},

	-- Heart Pack
	["Avocadini Guffo"] = {
		icon = "rbxassetid://114147522748416",
	},
	["Glorbo Fruttodrillo"] = {
		icon = "rbxassetid://138315002202088",
	},
	["Nuclearo Dinossauro"] = {
		icon = "rbxassetid://70985334400155",
	},
	["Tim Cheese"] = {
		icon = "rbxassetid://118999108122013",
	},

	-- Green Sprout Pack
	["Gattatino Neonino"] = {
		icon = "rbxassetid://128539641626646",
	},
	["Gattatino Nyanino"] = {
		icon = "rbxassetid://113934206994909",
	},
	["Los orcaleritos dicen"] = {
		icon = "rbxassetid://137390343646486",
	},
	["Perochello Lemonchello"] = {
		icon = "rbxassetid://108746928786094",
	},

	-- Lightning Pack
	["Avocadorilla"] = {
		icon = "rbxassetid://84696010378967",
	},
	["Cavallo Virtuoso"] = {
		icon = "rbxassetid://135550988750445",
	},
	["Cocofanto Elefanto"] = {
		icon = "rbxassetid://98804835735078",
	},
	["Pi Pi Watermelon"] = {
		icon = "rbxassetid://77720276593348",
	},

	-- Cloud Pack
	["Agarrini la Palini"] = {
		icon = "rbxassetid://90101513864637",
	},
	["Bandito Bobritto"] = {
		icon = "rbxassetid://117830883572086",
	},
	["Los Combinasionas"] = {
		icon = "rbxassetid://73259602554790",
	},
	["Los Tralaleritos"] = {
		icon = "rbxassetid://113884161376114",
	},

	-- Fire Pack
	["Blueberrinni Octopusini"] = {
		icon = "rbxassetid://89438888677521",
	},
	["Cacto Hipopotamo"] = {
		icon = "rbxassetid://79125841400545",
	},
	["Mat teo"] = {
		icon = "rbxassetid://90749181064353",
	},
	["Trulimero Trulicina"] = {
		icon = "rbxassetid://95952667644459",
	},
}

Textures.CardPacks = {
	["Diamond Pack"] = {
		icon = "rbxassetid://88199101470892",
	},
	["Star Pack"] = {
		icon = "rbxassetid://77479189713395",
	},
	["Peach Pack"] = {
		icon = "rbxassetid://80012926832246",
	},
	["Rose Pack"] = {
		icon = "rbxassetid://123529845811544",
	},
	["Blue Gem Pack"] = {
		icon = "rbxassetid://113954407708384",
	},
	["Purple Symbol Pack"] = {
		icon = "rbxassetid://132132745286127",
	},
	["Red Apple Pack"] = {
		icon = "rbxassetid://74201433786740",
	},
	["Frosty Pattern Pack"] = {
		icon = "rbxassetid://127459214843564",
	},
	["Funky Face Pack"] = {
		icon = "rbxassetid://98198409138714",
	},
	["Crown Pack"] = {
		icon = "rbxassetid://80143058155458",
	},
	["Skull Pack"] = {
		icon = "rbxassetid://91506051846691",
	},
	["Dark Orb Pack"] = {
		icon = "rbxassetid://78615593243250",
	},
	["Pentagram Black Pack"] = {
		icon = "rbxassetid://110290430954693",
	},
	["Pentagram Gold Pack"] = {
		icon = "rbxassetid://128463253615779",
	},
	["Ice Crystal Pack"] = {
		icon = "rbxassetid://86722356430179",
	},
	["Blue Sphere Pack"] = {
		icon = "rbxassetid://98771537173794",
	},
	["Orange Flame Pack"] = {
		icon = "rbxassetid://106949138561722",
	},
	["Heart Pack"] = {
		icon = "rbxassetid://129646232302170",
	},
	["Green Sprout Pack"] = {
		icon = "rbxassetid://127827775321795",
	},
	["Lightning Pack"] = {
		icon = "rbxassetid://93789659263476",
	},
	["Cloud Pack"] = {
		icon = "rbxassetid://138704605589323",
	},
	["Fire Pack"] = {
		icon = "rbxassetid://74141091471172",
	},
}

Textures.Environments = {
	[1] = {
		icon = "rbxassetid://99215999843277",
	},
	[2] = {
		icon = "rbxassetid://140575455765974",
	},
	[3] = {
		icon = "rbxassetid://133914302027561",
	},
	[4] = {
		icon = "rbxassetid://131347323663587",
	},
	[5] = {
		icon = "rbxassetid://125993966783912",
	},
	[6] = {
		icon = "rbxassetid://98266496300605",
	},
	[7] = {
		icon = "rbxassetid://96659573900301",
	},
}

Textures.Tools = {
	["Cash Register"] = {
		icon = "rbxassetid://108602081750475",
	},
	["Hammer"] = {
		icon = "rbxassetid://105745491746742",
	},
	["Vacuum"] = {
		icon = "rbxassetid://108122366971653",
	},
	["Magnet"] = {
		icon = "rbxassetid://70916969451838",
	},
	["Magnifying Glass"] = {
		icon = "rbxassetid://136383242414467",
	},
}

Textures.Eggs = {
	ToiletEgg = {
		icon = "rbxassetid://17279895869",
	},
	DragonEgg = {
		icon = "rbxassetid://17279895976",
	},
	Season1Egg = {
		icon = "rbxassetid://18681125695",
	},
	Advent2024Egg = {
		icon = "rbxassetid://74285428946631",
	},
}

Textures.Potions = {
	wins1Potion30 = {
		icon = "rbxassetid://13431112028",
	},
	lucky1Potion15 = {
		icon = "rbxassetid://13071277569",
	},
	lucky2Potion15 = {
		icon = "rbxassetid://135982778748036",
	},
}

Textures.Buffs = {
	friend = {
		icon = "rbxassetid://18143163907",
	},
	premium = {
		icon = "rbxassetid://18143163907",
	},
	group = {
		icon = "rbxassetid://13062775196",
	},
	wins1 = {
		icon = "rbxassetid://13431112028",
	},
	lucky1 = {
		-- icon = "rbxassetid://13071144888",
		icon = "rbxassetid://13071277569",
	},
	lucky2 = {
		icon = "rbxassetid://135982778748036",
	},
	power1 = {
		icon = "rbxassetid://13062775196",
	},
}

Textures.Gifts = {
	box = {
		unclaimed = "rbxassetid://17260681802",
		claimed = "rbxassetid://17260694781",
	},
	testBox = {
		unclaimed = "rbxassetid://17260860203",
		claimed = "rbxassetid://17260860283",
	},
}

Textures.Zones = {
	[1] = {
		icon = "rbxassetid://140139372333313",
	},
	[2] = {
		icon = "rbxassetid://102291036393612",
	},
	[3] = {
		icon = "rbxassetid://139693083880688",
	},
	[4] = {
		icon = "rbxassetid://18217970678",
	},
	[5] = {
		icon = "rbxassetid://18217967971",
	},
}

Textures.Chests = {
	[1] = {
		icon = "rbxassetid://77210412936839",
	},
	[2] = {
		icon = "rbxassetid://89745458469973",
	},
	[3] = {
		icon = "rbxassetid://103425946493645",
	},
	[4] = {
		icon = "rbxassetid://90018027473412",
	},
	[5] = {
		icon = "rbxassetid://105710453077662",
	},
	[6] = {
		icon = "rbxassetid://73812655068543",
	},
}

Textures.Characters = {
	["Angel"] = {
		icon = "rbxassetid://17260681802",
	},
	["Assassins"] = {
		icon = "rbxassetid://17260681802",
	},
	["Atomic Samurai"] = {
		icon = "rbxassetid://17260681802",
	},
	["Baryon"] = {
		icon = "rbxassetid://17260681802",
	},
	["Beerus"] = {
		icon = "rbxassetid://17260681802",
	},
	["Boros4"] = {
		icon = "rbxassetid://17260681802",
	},
}

Textures.Weapons = {
	Pickaxe1 = {
		icon = "rbxassetid://107523304177344",
	},
	Pickaxe2 = {
		icon = "rbxassetid://74871378019020",
	},
	Pickaxe3 = {
		icon = "rbxassetid://100312953137035",
	},
	Bomb1 = {
		icon = "rbxassetid://74612917328808",
	},
	Bomb2 = {
		icon = "rbxassetid://109341552755467",
	},
	Bomb3 = {
		icon = "rbxassetid://121073959237409",
	},
	Laser1 = {
		icon = "rbxassetid://132294935325082",
	},
	Laser2 = {
		icon = "rbxassetid://87201092133707",
	},
	Laser3 = {
		icon = "rbxassetid://124046289494207",
	},
	Drill1 = {
		icon = "rbxassetid://86613542866585",
	},
	Drill2 = {
		icon = "rbxassetid://113420571636005",
	},
	Drill3 = {
		icon = "rbxassetid://103306029534439",
	},
	OrbitingBoomerang1 = {
		icon = "rbxassetid://133913758539248",
	},
	OrbitingBoomerang2 = {
		icon = "rbxassetid://129150506513238",
	},
	OrbitingBoomerang3 = {
		icon = "rbxassetid://134268091603575",
	},
	BouncingBomb1 = {
		icon = "rbxassetid://94267403945445",
	},
	BouncingBomb2 = {
		icon = "rbxassetid://125792795159181",
	},
	BouncingBomb3 = {
		icon = "rbxassetid://106944499082433",
	},
}

Textures.Ores = {
	-- Shallow layer ores
	Stone = {
		icon = "rbxassetid://103486111908934", -- Using CoalOre icon as placeholder
	},
	Coal = {
		icon = "rbxassetid://131647901567206",
	},
	Copper = {
		icon = "rbxassetid://134283071238568",
	},
	Tin = {
		icon = "rbxassetid://133599414477257", -- Using CopperOre icon as placeholder
	},
	Iron = {
		icon = "rbxassetid://77562916641239",
	},
	Silver = {
		icon = "rbxassetid://117997854685337", -- Using IronOre icon as placeholder
	},
	Gold = {
		icon = "rbxassetid://118675794646585", -- Using IronOre icon as placeholder
	},
	-- Middle layer ores
	Diorite = {
		icon = "rbxassetid://109512896606667", -- Using CoalOre icon as placeholder
	},
	["Nether Quartz"] = {
		icon = "rbxassetid://128957114751771", -- Using DiamondOre icon as placeholder
	},
	Diamond = {
		icon = "rbxassetid://106945737928249",
	},
	Emerald = {
		icon = "rbxassetid://110585968896647", -- Using DiamondOre icon as placeholder
	},
	-- Deep layer ores
	["Lapis Lazuli"] = {
		icon = "rbxassetid://83535985472919", -- Using DiamondOre icon as placeholder
	},
	Obsidian = {
		icon = "rbxassetid://70578484572020", -- Using DiamondOre icon as placeholder
	},
	Crimson = {
		icon = "rbxassetid://77797816762916", -- Using DiamondOre icon as placeholder
	},
	["Ancient Relic Gold"] = {
		icon = "rbxassetid://90824447341688", -- Using DiamondOre icon as placeholder
	},
	-- Volcanic layer ores
	Redstone = {
		icon = "rbxassetid://132649565299231", -- Using DiamondOre icon as placeholder
	},
	["Void Stone"] = {
		icon = "rbxassetid://93605567863689", -- Using DiamondOre icon as placeholder
	},
	["Stellar Ore"] = {
		icon = "rbxassetid://102393432000919", -- Using DiamondOre icon as placeholder
	},
	["Primordial Rock"] = {
		icon = "rbxassetid://140362163458799", -- Using DiamondOre icon as placeholder
	},
}

Textures.Enchants = {
	[Keys.Enchants.Explosion] = { icon = "rbxassetid://88462938186802" },
	[Keys.Enchants.CoinBoost] = { icon = "rbxassetid://82661974544350" },
	[Keys.Enchants.CritRate] = { icon = "rbxassetid://81297502367668" },
	[Keys.Enchants.AttackSpeed] = { icon = "rbxassetid://132690758420783" },
	[Keys.Enchants.Attack] = { icon = "rbxassetid://108678905784512" },
	[Keys.Enchants.EnchantLuck] = { icon = "rbxassetid://129249834077304" },
	[Keys.Enchants.Burn] = { icon = "rbxassetid://90416740482974" },
}
Textures.Attrs = {
	[Keys.ForgeAttrs.Attack] = { icon = "rbxassetid://108678905784512" },
	[Keys.ForgeAttrs.AttackSpeed] = { icon = "rbxassetid://132690758420783" },
	[Keys.ForgeAttrs.DamageRange] = { icon = Textures.Empty },
	[Keys.ForgeAttrs.CritRate] = { icon = "rbxassetid://81297502367668" },
	[Keys.ForgeAttrs.Explosion] = { icon = "rbxassetid://88462938186802" },
	[Keys.ForgeAttrs.Burn] = { icon = "rbxassetid://90416740482974" },
	[Keys.ForgeAttrs.CoinBoost] = { icon = "rbxassetid://82661974544350" },
	[Keys.ForgeAttrs.EnchantLuck] = { icon = "rbxassetid://129249834077304" },
}

function Textures.GetIcon(args)
	local itemType = args.itemType
	local itemName = args.name or args.itemName
	if itemType == Keys.ItemType.potion then
		local potion = Textures.Potions[itemName]
		return potion and potion.icon or ""
	elseif itemType == "quest" then
		local quest = Textures.QuestTypeIcon[itemName]
		return quest and quest.icon or ""
	elseif itemType == Keys.ItemType.egg then
		local egg = Textures.Eggs[itemName]
		return egg and egg.icon or ""
	elseif itemType == Keys.ItemType.resource then
		local resource = Textures.Resources[itemName]
		return resource and resource.icon or ""
	elseif itemType == Keys.ItemType.ores then
		local ore = Textures.Ores[itemName]
		return ore and ore.icon or ""
	elseif itemType == Keys.ItemType.weapons then
		local weapon = Textures.Weapons[itemName]
		return weapon and weapon.icon or ""
	else
		return Textures.UnclassifiedIcons[itemType] or ""
	end
end

return Textures
