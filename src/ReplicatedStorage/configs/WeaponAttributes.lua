--!strict
-- Centralized weapon attribute definitions.
-- NOTE: Most balancing (perStack/maxStacks) is stored on the weapon instance data (attrs),
-- so we can rebalance by editing ore tables without migrating saves.

local WeaponAttributes = {}

export type AttrKind = "Stat" | "Proc"

export type AttrDef = {
	kind: AttrKind,
	-- Optional defaults (used when weaponData.attrs does not override)
	defaultPerStack: number?,
	defaultMaxStacks: number?,

	-- Proc defaults
	baseChance: number?,
	radius: number?, -- in blocks (Chebyshev cube radius)
	duration: number?, -- seconds
	tickInterval: number?, -- seconds
}

-- Supported attribute IDs (stringly-typed on purpose for flexibility)
WeaponAttributes.Definitions = {
	-- Stats
	Attack = { kind = "Stat" } :: AttrDef, -- damage multiplier add (baseDamage * (1 + total))
	AttackSpeed = { kind = "Stat" } :: AttrDef, -- attack speed multiplier add (cooldown / (1 + total))
	DamageRange = { kind = "Stat" } :: AttrDef, -- range multiplier add (range * (1 + total))
	CritRate = { kind = "Stat" } :: AttrDef,
	CritDamage = { kind = "Stat" } :: AttrDef,
	WalkSpeed = { kind = "Stat" } :: AttrDef,
	CoinBoost = { kind = "Stat" } :: AttrDef,
	EnchantLuck = { kind = "Stat" } :: AttrDef,

	-- Procs
	Explosion = {
		kind = "Proc",
		baseChance = 0.1,
		radius = 2,
		defaultMaxStacks = 5,
	} :: AttrDef,
	Burn = {
		kind = "Proc",
		baseChance = 1.0,
		duration = 5,
		tickInterval = 1,
		defaultMaxStacks = 5,
	} :: AttrDef,
}

return WeaponAttributes

