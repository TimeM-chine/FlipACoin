local Replicated = game:GetService("ReplicatedStorage")
local Keys = require(Replicated.configs.Keys)
local WeaponAttributeEngine = require(Replicated.modules.WeaponAttributeEngine)

local WeaponPresets = {}
local Assets = script.Parent.Assets
local ToolsFolder = Assets:WaitForChild("Tools")
local ToolModels = Assets:WaitForChild("ToolModels")

local Weapons = require(Replicated.ExcelConfig.Weapons)
WeaponPresets.Weapons = {}
for _, weapon in Weapons do
	WeaponPresets.Weapons[weapon.weaponId] = weapon
end

WeaponPresets.DefaultWeaponData = {
	weaponId = 1,
	tier = "normal",
	mainOre = "Stone",
	size = 0.3, -- quality
	equipped = false,
	enhance = 0,
	color = "White",
	materials = "Plastic",
	enchants = {}, -- enchant Slot {[1] = {attrName = "Burn" }}
	attrs = {},
	damageBoost = 1,
}

WeaponPresets.EnhanceCost = {
	[0] = {
		statsMultiplier = 1,
		enchantSlot = 0,
	},
}
local Enhance = require(Replicated.ExcelConfig.Enhance)
for _, enhance in Enhance do
	WeaponPresets.EnhanceCost[enhance.level] = enhance
end

WeaponPresets.EnchantCost = 100
WeaponPresets.Enchants = {
	Tin = {
		name = "Tin",
		attrName = Keys.Enchants.Explosion,
		rollMin = 1.3,
		rollMax = 2.5,
	},
	Gold = {
		name = "Gold",
		attrName = Keys.Enchants.CoinBoost,
		rollMin = 1.03,
		rollMax = 1.3,
	},
	Emerald = {
		name = "Emerald",
		attrName = Keys.Enchants.CritRate,
		rollMin = 0.02,
		rollMax = 0.2,
	},
	["Ancient Relic Gold"] = {
		name = "Ancient Relic Gold",
		attrName = Keys.Enchants.AttackSpeed,
		rollMin = 1.03,
		rollMax = 1.3,
	},
	["Primordial Rock"] = {
		name = "Primordial Rock",
		attrName = Keys.Enchants.Attack,
		rollMin = 1.03,
		rollMax = 1.3,
	},
	["Nether Quartz"] = {
		name = "Nether Quartz",
		attrName = Keys.Enchants.EnchantLuck,
		rollMin = 1.03,
		rollMax = 1.3,
	},
}

-- 获取武器模型
function WeaponPresets.GetWeaponModel(weaponName)
	local model = ToolModels:FindFirstChild(weaponName)
	if model then
		return model:Clone()
	end
	return nil
end

function WeaponPresets.GetWeaponProperty(weaponData)
	local weaponId = weaponData
	local weaponState = nil
	if typeof(weaponData) == "table" then
		weaponState = weaponData
		weaponId = weaponData.weaponName or weaponData.name or weaponData.id or weaponData.weaponId
	end

	local preset = WeaponPresets.Weapons[weaponId]
	if not preset then
		return {}
	end

	local props = {}
	for key, value in pairs(preset) do
		if key ~= "weaponType" then
			props[key] = value
		end
	end
	props.baseDamage = props.baseDamage or preset.Damage or 0
	props.attackRange = props.attackRange or preset.Range or preset.RayLength
	props.coolDown = props.coolDown or preset.Cooldown or 1
	props.weaponId = weaponId
	props.size = (weaponState and weaponState.size) or props.size or 1
	props.tier = (weaponState and weaponState.tier) or props.tier or "normal"
	props.rarity = props.rarity or "Common"
	props.enhance = (weaponState and weaponState.enhance) or 0
	props.damageBoost = (weaponState and weaponState.damageBoost) or 1

	local enhanceCfg = WeaponPresets.EnhanceCost[props.enhance] or WeaponPresets.EnhanceCost[0]
	props.enhanceMultiplier = (enhanceCfg and enhanceCfg.statsMultiplier) or 1

	local damageMul = weaponState and WeaponAttributeEngine.ComputeDamageMul(weaponState) or 0
	props.damageMul = damageMul

	local attackSpeedMult = weaponState and WeaponAttributeEngine.ComputeAttackSpeedMult(weaponState) or 1
	if attackSpeedMult <= 0 then
		attackSpeedMult = 1
	end
	props.attackSpeedMult = attackSpeedMult
	props.coolDownFinal = props.coolDown / props.attackSpeedMult

	props.critChance = weaponState and WeaponAttributeEngine.ComputeCritChance(weaponState) or 0

	props.damageRaw = props.baseDamage
		* (1 + props.damageMul)
		* props.enhanceMultiplier
		* props.damageBoost
		* props.size
	props.damage = math.ceil(math.max(2, props.damageRaw))

	local mainOre = weaponState and weaponState.mainOre
	local BlockPresets = require(Replicated.Systems.BlockSystem.Presets)
	local orePreset = BlockPresets.Ores[mainOre]
	props.sellPrice = math.ceil(orePreset.sellPrice * preset.Sell1 * props.size * 1)

	return props
end

function WeaponPresets.CreateWeaponModelForUi(weaponData)
	local weaponProperty = WeaponPresets.GetWeaponProperty(weaponData)
	local weaponModel: Model = script.Parent.Assets.ToolModels:FindFirstChild(weaponProperty.weaponId):Clone()
	-- Apply color and material from weapon data
	local weaponColor = weaponData.color
	local weaponMaterial = weaponData.materials

	weaponModel.WorldPivot = CFrame.new(0, 0, 0)
	if weaponColor or weaponMaterial then
		for _, part in ipairs(weaponModel:GetDescendants()) do
			if part:IsA("BasePart") then
				-- Apply color
				if weaponColor and Keys.ForgeColors[weaponColor] then
					part.Color = Keys.ForgeColors[weaponColor]
				end

				-- Apply material
				if weaponMaterial and Keys.ForgeMaterials[weaponMaterial] then
					part.Material = Keys.ForgeMaterials[weaponMaterial]
				end
			end
		end
	end
	return weaponModel
end

return WeaponPresets
