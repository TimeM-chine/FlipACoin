local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local Replicated = game:GetService("ReplicatedStorage")

local IsServer = RunService:IsServer()

local BaseWeapon = require(script.Parent.Parent.Libraries.BaseWeapon)
local SystemMgr = require(Replicated.Systems.SystemMgr)
local BlockPresets = require(Replicated.Systems.BlockSystem.Presets)
local RaycastFilters = require(Replicated.configs.RaycastFilters)

local SENDER = SystemMgr.SENDER
local BLOCK_SIZE = BlockPresets.BlockSize or 8

local Laser = {}
Laser.__index = Laser
setmetatable(Laser, BaseWeapon)

Laser.CanHit = true
Laser.CanBeFired = true

function Laser.new(systemIns, weaponInstance, ownerCharacter)
	local self = setmetatable(BaseWeapon.new(systemIns, weaponInstance, ownerCharacter), Laser)

	self.nextFireTime = 0
	self.curSlashTrack = nil
	self.animTracks = {}
	self.isFiring = false
	self.fireConnection = nil
	self.laserBeamContainer = nil
	self.laserStartAttachment = nil
	self.laserEndAttachment = nil

	self:doInitialSetup()

	return self
end

function Laser:onEquippedChanged()
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

		-- 当取消装备时，停止发射
		if not self.equipped then
			self:stopFiring()
		end
	end
end

local function getAimDirection(origin)
	local mouse = Players.LocalPlayer and Players.LocalPlayer:GetMouse()
	if mouse and mouse.Hit then
		local targetPos = mouse.Hit.Position
		local dir = (targetPos - origin)
		if dir.Magnitude > 0 then
			return dir.Unit, targetPos
		end
	end

	local camera = workspace.CurrentCamera
	if camera then
		return camera.CFrame.LookVector, origin + camera.CFrame.LookVector * 50
	end

	return Vector3.new(0, 0, -1), origin + Vector3.new(0, 0, -50)
end

-- 沿直线收集方块，限制最大穿透数量
function Laser:collectBlocksAlongLine(origin, dir, length, maxBlocks)
	local blockIds = {}
	local seen = {}
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	local filters = RaycastFilters.Blocks()
	params.FilterDescendantsInstances = filters

	local step = math.max(1, math.floor(BLOCK_SIZE * 0.5))
	local distanceCovered = 0
	maxBlocks = maxBlocks or 9

	local lastHitPos = origin + dir * length -- 默认终点

	while distanceCovered < length and #blockIds < maxBlocks do
		local stepLength = math.min(step, length - distanceCovered)
		local startPos = origin + dir * distanceCovered
		local result = workspace:Raycast(startPos, dir * stepLength, params)
		if result and result.Instance then
			local model = result.Instance:FindFirstAncestorOfClass("Model")
			if model then
				local blockId = model.Name
				if blockId and not seen[blockId] then
					seen[blockId] = true
					table.insert(blockIds, blockId)
					lastHitPos = result.Position

					if #blockIds >= maxBlocks then
						break
					end
				end
			end
		end

		distanceCovered += step
	end

	return blockIds, lastHitPos
end

-- 获取武器的Handle部件位置
function Laser:getHandlePosition()
	local tool = self.instance
	if tool then
		local handle = tool:FindFirstChild("Handle")
		if handle then
			return handle.Position
		end
	end

	-- 备用：使用玩家右手位置
	local character = self.player and self.player.Character
	if character then
		local rightHand = character:FindFirstChild("RightHand")
		if rightHand then
			return rightHand.Position
		end
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if hrp then
			return hrp.Position + hrp.CFrame.LookVector * 2
		end
	end

	return Vector3.new(0, 0, 0)
end

-- 获取枪口位置（优先使用ToolModel中的TipAttachment）
function Laser:getMuzzleWorldPosition()
	local character = self.player and self.player.Character
	if character then
		local weaponType = self:getConfigValue("weaponType")
		local weaponModelName = weaponType and `{weaponType}Model` or nil
		local weaponModel = weaponModelName and character:FindFirstChild(weaponModelName)
		if weaponModel and weaponModel:IsA("Model") then
			local tipAttachment = weaponModel:FindFirstChild("TipAttachment", true)
			if tipAttachment and tipAttachment:IsA("Attachment") then
				return tipAttachment.WorldPosition
			end
		end
	end

	return self:getHandlePosition()
end

-- 创建激光视觉效果
function Laser:createLaserBeam()
	self:destroyLaserBeam()

	local weaponId = self:getConfigValue("weaponId", "Laser1")
	local effectsFolder = script.Parent.Parent.Assets.Effects
	local shotsFolder = effectsFolder.Shots
	local template = shotsFolder:FindFirstChild(weaponId)
	local container = template:Clone()

	container.Anchored = true
	container.CanCollide = false
	container.CanQuery = false
	container.CanTouch = false
	container.Parent = workspace

	local startAttachment = container:FindFirstChild("StartAttachment", true)
	local endAttachment = container:FindFirstChild("EndAttachment", true)

	self.laserBeamContainer = container
	self.laserStartAttachment = startAttachment
	self.laserEndAttachment = endAttachment

	local coreBeam = container:FindFirstChild("CoreBeam", true)
	if coreBeam and coreBeam:IsA("Beam") and startAttachment and endAttachment then
		coreBeam.Attachment0 = startAttachment
		coreBeam.Attachment1 = endAttachment
	end

	local otherBeam = container:FindFirstChild("OtherBeam", true)
	if otherBeam and otherBeam:IsA("Beam") and startAttachment and endAttachment then
		otherBeam.Attachment0 = startAttachment
		otherBeam.Attachment1 = endAttachment
	end
end

-- 更新激光视觉效果位置
function Laser:updateLaserBeam(startPos, endPos)
	local container = self.laserBeamContainer
	if not container then
		return
	end

	local offset = endPos - startPos
	local distance = offset.Magnitude
	if distance == 0 then
		return
	end

	container.CFrame = CFrame.lookAt(startPos, endPos)

	local startAttachment = self.laserStartAttachment
	if startAttachment then
		startAttachment.Position = Vector3.new(0, 0, 0)
	end

	local endAttachment = self.laserEndAttachment
	if endAttachment then
		endAttachment.Position = Vector3.new(0, 0, -distance)
	end
end

-- 销毁激光视觉效果
function Laser:destroyLaserBeam()
	local container = self.laserBeamContainer
	if container then
		container:Destroy()
		self.laserBeamContainer = nil
		self.laserStartAttachment = nil
		self.laserEndAttachment = nil
	end
end

function Laser:sendFire(fireInfo)
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

-- 执行一次激光发射
function Laser:performFire()
	if not self.activated then
		self:stopFiring()
		return
	end

	local character = self.player and self.player.Character
	if not character then
		self:stopFiring()
		return
	end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		self:stopFiring()
		return
	end

	local now = tick()
	local cooldown = self:getConfigValue("coolDown") or self:getConfigValue("Cooldown", 0.4)
	local attackSpeedMult = self.player and self.player:GetAttribute("AttackSpeed") or 1
	if typeof(attackSpeedMult) == "number" and attackSpeedMult > 0 then
		cooldown = cooldown / attackSpeedMult
	end
	if now < self.nextFireTime then
		return
	end
	self.nextFireTime = now + cooldown

	local length = self:getConfigValue("RayLength", 50)
	local attackRange = self:getConfigValue("attackRange") or length
	local maxBlocks = self:getConfigValue("maxBlocks", 1)

	local origin = self:getMuzzleWorldPosition()
	local dir, targetPos = getAimDirection(origin)
	local blockIds, lastHitPos = self:collectBlocksAlongLine(origin, dir, length, maxBlocks)

	-- 更新激光视觉效果
	self:updateLaserBeam(origin, lastHitPos)

	if #blockIds == 0 then
		return
	end

	local damage = self:getConfigValue("baseDamage") or self:getConfigValue("Damage", 8)
	local fireInfo = {
		blockIds = blockIds,
		origin = origin,
		dir = dir,
		length = length,
		attackRange = attackRange,
		maxBlocks = maxBlocks,
		baseDamage = damage,
		charge = 1,
	}

	self:sendFire(fireInfo)
end

-- 开始持续发射
function Laser:startFiring()
	if self.isFiring then
		return
	end

	self.isFiring = true
	self:createLaserBeam()
	SystemMgr.systems.MusicSystem:Play2dMusic(nil, nil, { musicName = "laser" })

	-- 使用Heartbeat实现高频攻击
	self.fireConnection = RunService.Heartbeat:Connect(function()
		if self.activated and self.equipped then
			self:performFire()
		else
			self:stopFiring()
		end
	end)
end

-- 停止发射
function Laser:stopFiring()
	self.isFiring = false
	self:destroyLaserBeam()
	SystemMgr.systems.MusicSystem:Stop2dMusic(nil, nil, { musicName = "laser" })

	if self.fireConnection then
		self.fireConnection:Disconnect()
		self.fireConnection = nil
	end

	if self.curSlashTrack then
		self.curSlashTrack:Stop()
	end
end

function Laser:onActivatedChanged()
	BaseWeapon.onActivatedChanged(self)

	if IsServer then
		return
	end

	if self.player ~= Players.LocalPlayer then
		return
	end

	if self.activated then
		-- 开始发射

		local slashName = self:getConfigValue("SlashAnimation", "Slash")
		self.curSlashTrack = self:getAnimTrack(slashName) :: AnimationTrack
		self.curSlashTrack.Looped = true -- 循环播放动画
		self.curSlashTrack:Play()
		if self.player and self.player:GetAttribute("AttackSpeed") then
			self.curSlashTrack:AdjustSpeed(self.player:GetAttribute("AttackSpeed"))
		end

		self:startFiring()
	else
		-- 停止发射
		self:stopFiring()
	end
end

function Laser:applyBlockDamage(firingPlayer, fireInfo)
	if not IsServer then
		return
	end

	local ids = fireInfo.blockIds
	if not ids or #ids == 0 then
		return
	end

	local origin = fireInfo.origin
	local dir = fireInfo.dir
	local length = fireInfo.length or self:getConfigValue("RayLength", 50)
	local attackRange = fireInfo.attackRange or self:getConfigValue("attackRange") or length
	local maxBlocks = fireInfo.maxBlocks or self:getConfigValue("maxBlocks", 1)

	if not origin or not dir then
		return
	end

	local hrp = firingPlayer and firingPlayer.Character and firingPlayer.Character:FindFirstChild("HumanoidRootPart")
	if hrp and (origin - hrp.Position).Magnitude > attackRange + BLOCK_SIZE * 2 then
		return
	end

	local baseDamage = fireInfo.baseDamage
		or fireInfo.damage
		or self:getConfigValue("baseDamage")
		or self:getConfigValue("Damage", 8)

	-- 限制方块数量
	local validIds = {}
	for i, blockId in ipairs(ids) do
		if i > maxBlocks then
			break
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

function Laser:onFired(firingPlayer, fireInfo, fromNetwork)
	BaseWeapon.onFired(self, firingPlayer, fireInfo, fromNetwork)

	if IsServer then
		self:applyBlockDamage(firingPlayer, fireInfo)
	end
end

function Laser:simulateFire(_firingPlayer, _fireInfo, _ownerCharacter) end

function Laser:stopAnimations()
	self:stopFiring()
	self.animTracks = {}
end

function Laser:cancelReload() end

function Laser:onDestroyed()
	self:stopFiring()
	BaseWeapon.onDestroyed(self)
end

return Laser
