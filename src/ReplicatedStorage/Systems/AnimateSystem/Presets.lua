local AnimatePresets = {}

local jumpAnim = "http://www.roblox.com/asset/?id=507765000"
local walkAim = "http://www.roblox.com/asset/?id=913402848"
local runAnim = "http://www.roblox.com/asset/?id=913376220"
local emptyAnim = "rbxassetid://86413609132742"

AnimatePresets.EmptyAnim = emptyAnim

AnimatePresets.Animations = {
	player = {
		example = {
			id = "rbxassetid://116914633468956",
			priority = Enum.AnimationPriority.Action3,
			speed = 1,
			looped = false,
			weight = 1,
		},
		Skill1 = {
			id = "rbxassetid://113013136825098",
			priority = Enum.AnimationPriority.Action,
			speed = 1,
			looped = false,
			weight = 1,
		},
		DrillAttack = {
			id = "rbxassetid://101516753275552",
			priority = Enum.AnimationPriority.Action,
			speed = 1,
			looped = true,
			weight = 1,
		},
		DrillIdle = {
			id = "rbxassetid://80994068628302",
			priority = Enum.AnimationPriority.Idle,
			speed = 1,
			looped = true,
			weight = 1,
		},
		DrillMove = {
			id = "rbxassetid://112607695240044",
			priority = Enum.AnimationPriority.Movement,
			speed = 1,
			looped = true,
			weight = 1,
		},
		BombAttack = {
			id = "rbxassetid://123699941749563",
			priority = Enum.AnimationPriority.Action,
			speed = 1,
			looped = true,
			weight = 1,
		},
		BombIdle = {
			id = "rbxassetid://96115707721266",
			priority = Enum.AnimationPriority.Idle,
			speed = 1,
			looped = true,
			weight = 1,
		},
		BombMove = {
			id = "rbxassetid://87903783580005",
			priority = Enum.AnimationPriority.Movement,
			speed = 1,
			looped = true,
			weight = 1,
		},
		PickaxeAttack = {
			id = "rbxassetid://96564654182069",
			priority = Enum.AnimationPriority.Action,
			speed = 1,
			looped = true,
			weight = 1,
		},
		PickaxeIdle = {
			id = "rbxassetid://85251480991650",
			priority = Enum.AnimationPriority.Idle,
			speed = 1,
			looped = true,
			weight = 1,
		},
		PickaxeMove = {
			id = "rbxassetid://107098582766099",
			priority = Enum.AnimationPriority.Movement,
			speed = 1,
			looped = true,
			weight = 1,
		},
		OrbitingBoomerangAttack = {
			id = "rbxassetid://95301785707959",
			priority = Enum.AnimationPriority.Action,
			speed = 1,
			looped = true,
			weight = 1,
		},
		OrbitingBoomerangIdle = {
			id = "rbxassetid://119658300758973",
			priority = Enum.AnimationPriority.Idle,
			speed = 1,
			looped = true,
			weight = 1,
		},
		OrbitingBoomerangMove = {
			id = "rbxassetid://113831604724703",
			priority = Enum.AnimationPriority.Movement,
			speed = 1,
			looped = true,
			weight = 1,
		},
		LaserAttack = {
			id = "rbxassetid://77240379074119",
			priority = Enum.AnimationPriority.Action,
			speed = 1,
			looped = true,
			weight = 1,
		},
		LaserIdle = {
			id = "rbxassetid://80987952298507",
			priority = Enum.AnimationPriority.Idle,
			speed = 1,
			looped = true,
			weight = 1,
		},
		LaserMove = {
			id = "rbxassetid://117093638829528",
			priority = Enum.AnimationPriority.Movement,
			speed = 1,
			looped = true,
			weight = 1,
		},
		BouncingBombAttack = {
			id = "rbxassetid://123699941749563",
			priority = Enum.AnimationPriority.Action,
			speed = 1,
			looped = true,
			weight = 1,
		},
		BouncingBombIdle = {
			id = "rbxassetid://96115707721266",
			priority = Enum.AnimationPriority.Idle,
			speed = 1,
			looped = true,
			weight = 1,
		},
		BouncingBombMove = {
			id = "rbxassetid://87903783580005",
			priority = Enum.AnimationPriority.Movement,
			speed = 1,
			looped = true,
			weight = 1,
		},
	},
}

return AnimatePresets
