--!strict

local Replicated = game:GetService("ReplicatedStorage")

local WeaponAttributes = require(Replicated.configs.WeaponAttributes)

type AttrInstance = {
	stacks: number?,
	perStack: number?,
	maxStacks: number?,

	-- Proc overrides (optional)
	baseChance: number?,
	radius: number?,
	duration: number?,
	tickInterval: number?,

	-- Legacy support
	legacyValue: number?,
}

export type WeaponDataLike = {
	attrs: { [string]: AttrInstance }?,
	buffs: { any }?, -- legacy forge data
	enchants: { any }?, -- future compatibility
}

export type HitStats = {
	baseDamage: number,
	damageRange: number?,
	attackSpeedMult: number, -- 1.0 means unchanged
}

export type ProcExplosionResult = {
	blockIds: { string },
	damage: number,
}

export type ProcBurnApplication = {
	blockId: string,
	dps: number,
	duration: number,
}

export type ProcResult = {
	explosion: ProcExplosionResult?,
	burn: { ProcBurnApplication }?,
}

local WeaponAttributeEngine = {}

local function clampStacks(stacks: number, maxStacks: number?): number
	if maxStacks == nil then
		return stacks
	end
	return math.clamp(stacks, 0, maxStacks)
end

local function getTotalAdd(attrs: { [string]: AttrInstance }, attrId: string): number
	local inst = attrs[attrId]
	if not inst then
		return 0
	end

	if inst.legacyValue ~= nil then
		return inst.legacyValue
	end

	local def = WeaponAttributes.Definitions[attrId]
	local stacks = inst.stacks or 0
	local maxStacks = inst.maxStacks or (def and def.defaultMaxStacks) or nil
	stacks = clampStacks(stacks, maxStacks)

	local perStack = inst.perStack or (def and def.defaultPerStack) or 0
	return stacks * perStack
end

local function getProcParam(attrs: { [string]: AttrInstance }, attrId: string, key: string): number?
	local inst = attrs[attrId]
	local def = WeaponAttributes.Definitions[attrId]
	if inst and inst[key] ~= nil then
		return inst[key]
	end
	if def and def[key] ~= nil then
		return def[key]
	end
	return nil
end

local function forEachEnchant(weaponData: WeaponDataLike, fn: (any) -> ()): ()
	if not weaponData or typeof(weaponData) ~= "table" then
		return
	end
	local enchants = weaponData.enchants
	if typeof(enchants) ~= "table" then
		return
	end
	for _, enchant in pairs(enchants :: { any }) do
		if typeof(enchant) == "table" then
			fn(enchant)
		end
	end
end

local function getEnchantAttrName(enchant: any): string?
	if typeof(enchant.attrName) == "string" then
		return enchant.attrName
	end
	if typeof(enchant.enchantType) == "string" then
		if enchant.enchantType == "Speed" then
			return "AttackSpeed"
		end
		return enchant.enchantType
	end
	return nil
end

local function getEnchantRollSum(weaponData: WeaponDataLike, attrName: string): number
	local total = 0
	forEachEnchant(weaponData, function(enchant)
		local name = getEnchantAttrName(enchant)
		if name == attrName and typeof(enchant.roll) == "number" then
			total += enchant.roll
		end
	end)
	return total
end

local function getEnchantMultiplierAdd(weaponData: WeaponDataLike, attrName: string): number
	local total = 0
	forEachEnchant(weaponData, function(enchant)
		local name = getEnchantAttrName(enchant)
		local roll = enchant.roll
		if name == attrName and typeof(roll) == "number" then
			total += math.max(0, roll - 1)
		end
	end)
	return total
end

local function getEnchantMultiplier(weaponData: WeaponDataLike, attrName: string): number
	return 1 + getEnchantMultiplierAdd(weaponData, attrName)
end

function WeaponAttributeEngine.NormalizeAttrs(weaponData: WeaponDataLike): { [string]: AttrInstance }
	local attrs = weaponData.attrs
	if not attrs then
		attrs = {}
		weaponData.attrs = attrs
	end

	-- Legacy forge: buffs = { { type = "Attack", value = 0.12 } / { type="Explosion", chance=0.1 } }
	-- We convert these to attrs so old crafted weapons still work.
	if weaponData.buffs and typeof(weaponData.buffs) == "table" then
		for _, buff in ipairs(weaponData.buffs :: { any }) do
			if typeof(buff) ~= "table" then
				continue
			end
			local attrId = buff.type
			if typeof(attrId) ~= "string" then
				continue
			end
			local inst = attrs[attrId]
			if not inst then
				inst = {}
				attrs[attrId] = inst
			end

			if typeof(buff.value) == "number" then
				-- Treat legacy value as a direct additive multiplier (already aggregated).
				inst.legacyValue = buff.value
				inst.stacks = 1
				inst.maxStacks = 1
			end

			if typeof(buff.chance) == "number" then
				inst.baseChance = buff.chance
				inst.stacks = inst.stacks or 1
				inst.maxStacks = inst.maxStacks or 1
			end
		end
	end

	return attrs
end

function WeaponAttributeEngine.ComputeHitStats(
	weaponData: WeaponDataLike,
	baseDamage: number,
	damageRange: number?
): HitStats
	local attrs = WeaponAttributeEngine.NormalizeAttrs(weaponData)

	local attackAdd = getTotalAdd(attrs, "Attack") + getEnchantMultiplierAdd(weaponData, "Attack")
	local rangeAdd = getTotalAdd(attrs, "DamageRange")
	local attackSpeedAdd = getTotalAdd(attrs, "AttackSpeed") + getEnchantMultiplierAdd(weaponData, "AttackSpeed")

	local out: HitStats = {
		baseDamage = baseDamage * (1 + attackAdd),
		damageRange = damageRange,
		attackSpeedMult = 1 + attackSpeedAdd,
	}

	if damageRange ~= nil then
		out.damageRange = damageRange * (1 + rangeAdd)
	end

	return out
end

function WeaponAttributeEngine.ComputeAttackSpeedMult(weaponData: WeaponDataLike): number
	local attrs = WeaponAttributeEngine.NormalizeAttrs(weaponData)
	return 1 + getTotalAdd(attrs, "AttackSpeed") + getEnchantMultiplierAdd(weaponData, "AttackSpeed")
end

function WeaponAttributeEngine.ComputeDamageAdd(_weaponData: WeaponDataLike): number
	return 0
end

function WeaponAttributeEngine.ComputeDamageMul(weaponData: WeaponDataLike): number
	local attrs = WeaponAttributeEngine.NormalizeAttrs(weaponData)
	return getTotalAdd(attrs, "Attack") + getEnchantMultiplierAdd(weaponData, "Attack")
end

function WeaponAttributeEngine.ComputeCritChance(weaponData: WeaponDataLike): number
	local attrs = WeaponAttributeEngine.NormalizeAttrs(weaponData)
	local crit = getTotalAdd(attrs, "CritRate") + getEnchantRollSum(weaponData, "CritRate")
	return math.clamp(crit, 0, 1)
end

function WeaponAttributeEngine.ComputeCoinBoostMult(weaponData: WeaponDataLike): number
	local attrs = WeaponAttributeEngine.NormalizeAttrs(weaponData)
	local mult = 1 + getTotalAdd(attrs, "CoinBoost") + getEnchantMultiplierAdd(weaponData, "CoinBoost")
	return math.max(1, mult)
end

local function parseBlockId(blockId: string): (number?, number?, number?, number?)
	-- Format generated by BlockSystem: `B_{zoneIndex}_{depth}_{x}_{z}`
	local zoneStr, depthStr, xStr, zStr = string.match(blockId, "^B_(%d+)_(%d+)_(%d+)_(%d+)$")
	if not zoneStr then
		return nil, nil, nil, nil
	end
	return tonumber(zoneStr), tonumber(depthStr), tonumber(xStr), tonumber(zStr)
end

export type BlockExistsFn = (blockId: string) -> boolean

function WeaponAttributeEngine.GetNeighborBlockIds(
	blockId: string,
	radius: number,
	blockExists: BlockExistsFn
): { string }
	local zone, depth, x, z = parseBlockId(blockId)
	if not zone or not depth or not x or not z then
		return {}
	end

	local out = {}
	local seen: { [string]: boolean } = {}
	for dy = -radius, radius do
		for dx = -radius, radius do
			for dz = -radius, radius do
				local cand = `B_{zone}_{depth + dy}_{x + dx}_{z + dz}`
				if not seen[cand] and blockExists(cand) then
					seen[cand] = true
					table.insert(out, cand)
				end
			end
		end
	end

	return out
end

function WeaponAttributeEngine.OnHitBlocks(
	weaponData: WeaponDataLike,
	hitBlockIds: { string },
	baseDamage: number,
	blockExists: BlockExistsFn
): ProcResult
	local attrs = WeaponAttributeEngine.NormalizeAttrs(weaponData)

	local result: ProcResult = {}

	-- Explosion
	local explosionInst = attrs.Explosion
	local enchantExplosionMult = getEnchantMultiplier(weaponData, "Explosion")
	local hasExplosion = explosionInst ~= nil or enchantExplosionMult > 1
	if hasExplosion then
		local def = WeaponAttributes.Definitions.Explosion
		local chance = getProcParam(attrs, "Explosion", "baseChance") or (def and def.baseChance) or 0
		chance = math.clamp(chance, 0, 1)
		local radius = getProcParam(attrs, "Explosion", "radius") or (def and def.radius) or 0

		local stacks = 0
		local perStackMul = 0
		if explosionInst then
			stacks = clampStacks(explosionInst.stacks or 0, explosionInst.maxStacks or (def and def.defaultMaxStacks))
			perStackMul = explosionInst.perStack or (def and def.defaultPerStack) or 0
		end

		local damageMul = 1 + stacks * perStackMul
		local extraDamage = baseDamage * damageMul * enchantExplosionMult

		local union: { [string]: boolean } = {}
		local unionList: { string } = {}

		for _, hitId in ipairs(hitBlockIds) do
			if math.random() < chance then
				local neighbors = WeaponAttributeEngine.GetNeighborBlockIds(hitId, radius, blockExists)
				for _, nid in ipairs(neighbors) do
					if not union[nid] then
						union[nid] = true
						table.insert(unionList, nid)
					end
				end
			end
		end

		if #unionList > 0 then
			result.explosion = {
				blockIds = unionList,
				damage = extraDamage,
			}
		end
	end

	-- Burn
	local burnInst = attrs.Burn
	if burnInst then
		local chance = getProcParam(attrs, "Burn", "baseChance") or 0
		local extraChance = getEnchantRollSum(weaponData, "Burn")
		chance = math.clamp(chance + extraChance, 0, 1)
		local duration = getProcParam(attrs, "Burn", "duration") or 0

		local stacks =
			clampStacks(burnInst.stacks or 0, burnInst.maxStacks or WeaponAttributes.Definitions.Burn.defaultMaxStacks)
		local perStackPct = burnInst.perStack or WeaponAttributes.Definitions.Burn.defaultPerStack or 0

		local dps = baseDamage * (stacks * perStackPct)
		if dps > 0 and duration > 0 then
			local apps: { ProcBurnApplication } = {}
			for _, hitId in ipairs(hitBlockIds) do
				if math.random() < chance then
					table.insert(apps, {
						blockId = hitId,
						dps = dps,
						duration = duration,
					})
				end
			end
			if #apps > 0 then
				result.burn = apps
			end
		end
	end

	return result
end

return WeaponAttributeEngine
