local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Replicated = game:GetService("ReplicatedStorage")

local IsServer = RunService:IsServer()

local BaseWeapon = require(script.Parent.Parent.Libraries.BaseWeapon)
local SystemMgr = require(Replicated.Systems.SystemMgr)
local BlockPresets = require(Replicated.Systems.BlockSystem.Presets)
local RaycastFilters = require(Replicated.configs.RaycastFilters)

local SENDER = SystemMgr.SENDER
local BLOCK_SIZE = BlockPresets.BlockSize or 8
local HIT_TIME_AT_SPEED_ONE_DEFAULT = 0.3
local MAX_LATENCY_COMP_DEFAULT = 0.3

local Pickaxe = {}
Pickaxe.__index = Pickaxe
setmetatable(Pickaxe, BaseWeapon)

Pickaxe.CanHit = true
Pickaxe.CanBeFired = true

function Pickaxe.new(systemIns, weaponInstance, ownerCharacter)
	local self = setmetatable(BaseWeapon.new(systemIns, weaponInstance, ownerCharacter), Pickaxe)

	self.nextFireTime = 0
	self.curSlashTrack = nil
	self.animTracks = {}

	self:doInitialSetup()

	return self
end

function Pickaxe:onEquippedChanged()
	BaseWeapon.onEquippedChanged(self)
	if not IsServer then
		if Players.LocalPlayer ~= self.player then
			return
		end
		local character = self.player.Character
		if not character then
			return
		end
		if not character.Parent then
			return
		end
	end
end

local function createOverlapParams()
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	local filters = RaycastFilters.Blocks()
	params.FilterDescendantsInstances = filters
	return params
end

local function getAttackSpeedMult(player)
	local attackSpeedMult = player and player:GetAttribute("AttackSpeed") or 1
	if typeof(attackSpeedMult) ~= "number" or attackSpeedMult <= 0 then
		return 1
	end
	return attackSpeedMult
end

local function getServerNow()
	if workspace.GetServerTimeNow then
		return workspace:GetServerTimeNow()
	end
	return tick()
end

-- 收集玩家面前半球形范围内的方块
function Pickaxe:collectBlocksInHemisphere(playerPos, lookDir, radius)
	local blockIds = {}
	local seen = {}

	-- 获取水平方向的朝向
	local lookDir2D = Vector3.new(lookDir.X, 0, lookDir.Z)
	if lookDir2D.Magnitude > 0 then
		lookDir2D = lookDir2D.Unit
	else
		lookDir2D = Vector3.new(0, 0, -1)
	end

	-- 使用球形范围检测
	local searchRadius = radius * BLOCK_SIZE
	local parts = workspace:GetPartBoundsInRadius(playerPos, searchRadius, createOverlapParams())

	for _, part in ipairs(parts) do
		local model = part:FindFirstAncestorOfClass("Model")
		if model then
			local blockId = model.Name
			local primary = model.PrimaryPart
			if primary and blockId and not seen[blockId] then
				local blockPos = primary.Position
				local toBlock = blockPos - playerPos

				-- 检查是否在半球形范围内（前方）
				local toBlock2D = Vector3.new(toBlock.X, 0, toBlock.Z)
				if toBlock2D.Magnitude > 0.1 then
					local dotProduct = toBlock2D.Unit:Dot(lookDir2D)
					-- 点积 > 0 表示在玩家前方
					if dotProduct > 0 then
						seen[blockId] = true
						table.insert(blockIds, blockId)
					end
				else
					-- 方块在玩家正上方或正下方，也算在内
					seen[blockId] = true
					table.insert(blockIds, blockId)
				end
			end
		end
	end

	return blockIds
end

function Pickaxe:sendFire(fireInfo)
	fireInfo.id = fireInfo.id or self.nextShotId
	self.nextShotId += 1

	if not IsServer then
		self:onFired(self.player, fireInfo, false)
		SystemMgr.systems.WeaponSystem.Server:WeaponFired({
			instance = self.instance,
			fireInfo = fireInfo,
		})
	else
		self:onFired(self.player, fireInfo, false)
	end
end

function Pickaxe:onActivatedChanged()
	BaseWeapon.onActivatedChanged(self)

	if IsServer then
		return
	end

	if not self.activated then
		return
	end
	if self.player ~= Players.LocalPlayer then
		return
	end

	local now = tick()
	local cooldown = self:getConfigValue("coolDown") or self:getConfigValue("Cooldown", 0.5)
	local attackSpeedMult = getAttackSpeedMult(self.player)
	cooldown = cooldown / attackSpeedMult
	if now < self.nextFireTime then
		return
	end
	self.nextFireTime = now + cooldown

	SystemMgr.systems.MusicSystem:PlayMusic(
		nil,
		nil,
		{ musicName = "Swing1", part = self.player.Character.PrimaryPart }
	)

	local slashName = self:getConfigValue("SlashAnimation", "Slash")
	self.curSlashTrack = self:getAnimTrack(slashName) :: AnimationTrack
	self.curSlashTrack.Looped = false
	self.curSlashTrack:Play()
	self.curSlashTrack:AdjustSpeed(attackSpeedMult)

	local character = self.player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end

	local damageRange = self:getConfigValue("damageRange", 1)
	local attackRange = self:getConfigValue("attackRange", 30)

	-- 获取玩家位置和朝向
	local playerPos = hrp.Position
	local lookDir = hrp.CFrame.LookVector

	-- 收集半球形范围内的方块
	local blockIds = self:collectBlocksInHemisphere(playerPos, lookDir, damageRange)

	if #blockIds == 0 then
		return
	end

	local damage = self:getConfigValue("baseDamage") or self:getConfigValue("Damage", 5)
	local fireInfo = {
		blockIds = blockIds,
		center = playerPos,
		baseDamage = damage,
		damageRange = damageRange,
		attackRange = attackRange,
		origin = playerPos,
		dir = lookDir,
		charge = 1,
		serverTime = getServerNow(),
	}

	self:sendFire(fireInfo)
end

function Pickaxe:applyBlockDamage(firingPlayer, fireInfo)
	if not IsServer then
		return
	end

	local ids = fireInfo.blockIds
	if not ids or #ids == 0 then
		return
	end

	local baseDamage = fireInfo.baseDamage
		or fireInfo.damage
		or self:getConfigValue("baseDamage")
		or self:getConfigValue("Damage", 5)

	local damageRange = fireInfo.damageRange or self:getConfigValue("damageRange", 1)
	local hrp = firingPlayer and firingPlayer.Character and firingPlayer.Character:FindFirstChild("HumanoidRootPart")
	local maxDistance = (damageRange + 0.5) * BLOCK_SIZE

	local validIds = {}

	for _, blockId in ipairs(ids) do
		if hrp then
			local blockIns = SystemMgr.systems.BlockSystem:GetBlockInsById(blockId)
			if not blockIns then
				continue
			end
			if (hrp.Position - blockIns.position).Magnitude > maxDistance + BLOCK_SIZE then
				continue
			end
		end

		table.insert(validIds, blockId)
	end

	if #validIds > 0 then
		SystemMgr.systems.BlockSystem:HurtBlocksWithWeapon(SENDER, firingPlayer, {
			blockIds = validIds,
			baseDamage = baseDamage,
		})
	end
end

function Pickaxe:onFired(firingPlayer, fireInfo, fromNetwork)
	BaseWeapon.onFired(self, firingPlayer, fireInfo, fromNetwork)

	if IsServer then
		fireInfo = fireInfo or {}
		local attackSpeedMult = getAttackSpeedMult(firingPlayer)
		local hitTimeAtSpeedOne = self:getConfigValue("HitTime", HIT_TIME_AT_SPEED_ONE_DEFAULT)
		if typeof(hitTimeAtSpeedOne) ~= "number" or hitTimeAtSpeedOne < 0 then
			hitTimeAtSpeedOne = HIT_TIME_AT_SPEED_ONE_DEFAULT
		end

		local desiredHitDelay = hitTimeAtSpeedOne / attackSpeedMult
		local elapsed = 0
		if typeof(fireInfo.serverTime) == "number" then
			local maxLatencyComp = self:getConfigValue("MaxLatencyComp", MAX_LATENCY_COMP_DEFAULT)
			if typeof(maxLatencyComp) ~= "number" or maxLatencyComp <= 0 then
				maxLatencyComp = MAX_LATENCY_COMP_DEFAULT
			end
			elapsed = math.clamp(getServerNow() - fireInfo.serverTime, 0, maxLatencyComp)
		end

		local remainingDelay = desiredHitDelay - elapsed
		if remainingDelay <= 0 then
			self:applyBlockDamage(firingPlayer, fireInfo)
			return
		end

		task.delay(remainingDelay, function()
			self:applyBlockDamage(firingPlayer, fireInfo)
		end)
	end
end

function Pickaxe:simulateFire(_firingPlayer, _fireInfo, _ownerCharacter) end

function Pickaxe:stopAnimations()
	self.animTracks = {}
end

function Pickaxe:cancelReload() end

function Pickaxe:onDestroyed()
	BaseWeapon.onDestroyed(self)
end

return Pickaxe
